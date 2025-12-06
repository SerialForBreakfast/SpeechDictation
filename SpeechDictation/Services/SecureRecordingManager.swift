//
//  SecureRecordingManager.swift
//  SpeechDictation
//
//  Created by AI Assistant on 1/27/25.
//
//  Secure recording manager for private conversations and meetings.
//  Provides complete file protection, on-device transcription, and secure storage.
//  Coordinates AudioRecordingManager, SpeechRecognizer, and TimingDataManager for secure workflows.
//

import Foundation
import AVFoundation
import Combine

/// Metadata for a secure recording session
struct SecureRecordingSession: Codable, Identifiable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval
    let audioFileName: String
    let transcriptFileName: String
    let isCompleted: Bool
    let hasConsent: Bool
    
    /// Human-readable description of the session
    var displayTitle: String {
        return title.isEmpty ? "Recording \(startTime.formatted(.dateTime.hour().minute()))" : title
    }
    
    /// Size of audio file in bytes
    var audioFileSize: Int64 {
        let url = CacheManager.shared.getSecureFileURL(fileName: audioFileName, sessionId: id)
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[FileAttributeKey.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}

/// Service for managing secure private recordings with complete file protection
/// Integrates audio recording, on-device transcription, and secure storage
/// Uses proper concurrency patterns and provides authentication controls
@MainActor
final class SecureRecordingManager: ObservableObject {
    static let shared = SecureRecordingManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var isRecording = false
    @Published private(set) var currentSession: SecureRecordingSession?
    @Published private(set) var allSessions: [SecureRecordingSession] = []
    @Published private(set) var recordingDuration: TimeInterval = 0
    @Published private(set) var hasValidConsent = false
    /// Live transcription text surfaced to the UI while secure recording is active.
    /// Keeps the secure workflow in sync with the standard transcription experience.
    @Published private(set) var liveTranscript: AttributedString = AttributedString("")
    
    // MARK: - Private Properties
    
    private let audioRecordingManager = AudioRecordingManager.shared
    private let speechRecognizer = SpeechRecognizer()
    private let cacheManager = CacheManager.shared
    private let timingDataManager = TimingDataManager.shared
    private let audioPlaybackManager = AudioPlaybackManager.shared
    
    private var recordingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var transcriptCancellable: AnyCancellable?
    private var currentAudioURL: URL?
    /// Track previous segments to determine "stable" vs "changing" text
    private var previousSegments: [TranscriptionSegment] = []
    
    /// Deduplicate timing segments:
    /// - trims whitespace
    /// - drops empty texts
    /// - skips consecutive segments with identical text and (nearly) identical start times
    private func deduplicateSegments(_ segments: [TranscriptionSegment]) -> [TranscriptionSegment] {
        var result: [TranscriptionSegment] = []
        let epsilon: TimeInterval = 0.0005 // tolerance for floating point startTime equality
        
        for seg in segments {
            let text = seg.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            
            if let last = result.last {
                let sameText = last.text == text
                let sameStart = abs(last.startTime - seg.startTime) < epsilon
                if sameText && sameStart {
                    // skip duplicate segment
                    continue
                }
            }
            
            // Keep segment but with trimmed text
            let cleaned = TranscriptionSegment(
                text: text,
                startTime: seg.startTime,
                endTime: seg.endTime,
                confidence: seg.confidence
            )
            result.append(cleaned)
        }
        return result
    }
    
    // MARK: - Initialization
    
    private init() {
        setupBindings()
        loadExistingSessions()
    }
    
    // MARK: - Public Interface
    
    /// Starts a new secure recording session with user consent
    /// - Parameters:
    ///   - title: Optional title for the recording
    ///   - hasConsent: Whether user has provided explicit consent
    /// - Returns: Session ID if started successfully, nil otherwise
    func startSecureRecording(title: String = "", hasConsent: Bool = true) async -> String? {
        guard !isRecording else {
            print("Secure recording already in progress")
            return nil
        }
        
        guard hasConsent else {
            print("Cannot start secure recording without user consent")
            return nil
        }
        
        // Validate storage space
        guard validateStorageSpace() else {
            print("Insufficient storage space for secure recording")
            return nil
        }
        
        let sessionId = UUID().uuidString
        let startTime = Date()
        
        // Create session metadata
        currentSession = SecureRecordingSession(
            id: sessionId,
            title: title,
            startTime: startTime,
            endTime: nil,
            duration: 0,
            audioFileName: "audio_\(sessionId).m4a",
            transcriptFileName: "transcript_\(sessionId).json",
            isCompleted: false,
            hasConsent: hasConsent
        )
        
        // Start secure audio recording
        currentAudioURL = audioRecordingManager.startSecureRecording(
            quality: AudioQualitySettings.standardQuality,
            sessionId: sessionId
        )
        
        guard currentAudioURL != nil else {
            print("Failed to start secure audio recording")
            currentSession = nil
            return nil
        }
        
        // Subscribe to timing segments and build transcript with styling
        transcriptCancellable?.cancel()
        liveTranscript = AttributedString("")
        previousSegments = []
        
        transcriptCancellable = timingDataManager.$segments
            .receive(on: RunLoop.main)
            .sink { [weak self] segments in
                guard let self = self else { return }
                
                // 1. Deduplicate/clean the new segments
                let deduped = self.deduplicateSegments(segments)
                
                // 2. Build AttributedString with stability logic
                // If a segment matches (text & relative position) what we saw last time, it's "stable".
                // If it's new or changed, it's "processing" (italic).
                let styled = self.buildStyledTranscript(from: deduped, previous: self.previousSegments)
                
                self.liveTranscript = styled
                self.previousSegments = deduped
            }
        
        // Start on-device transcription with timing
        speechRecognizer.startTranscribingWithTiming(sessionId: sessionId)
        
        // Update state
        isRecording = true
        hasValidConsent = hasConsent
        recordingDuration = 0
        
        // Start duration timer
        startRecordingTimer()
        
        print("Started secure recording session: \(sessionId)")
        return sessionId
    }
    
    /// Stops the current secure recording session
    /// - Returns: The completed session metadata, or nil if no active session
    func stopSecureRecording() async -> SecureRecordingSession? {
        guard isRecording, var session = currentSession else {
            print("No active secure recording to stop")
            return nil
        }
        
        // Stop recording timer
        stopRecordingTimer()
        
        // Stop audio recording
        let finalAudioURL = audioRecordingManager.stopRecording()
        
        // Move audio file to secure storage
        if let audioURL = finalAudioURL, FileManager.default.fileExists(atPath: audioURL.path) {
            do {
                let audioData = try Data(contentsOf: audioURL)
                let secureAudioURL = cacheManager.saveSecurely(
                    data: audioData,
                    forKey: session.audioFileName,
                    subdirectory: session.id
                )
                if secureAudioURL != nil {
                    // Delete temporary audio file
                    try? FileManager.default.removeItem(at: audioURL)
                    print("Moved audio file to secure storage: \(session.audioFileName)")
                } else {
                    print("Failed to save audio file to secure storage")
                }
            } catch {
                print("Error moving audio file to secure storage: \(error)")
            }
        }
        
        // Stop transcription
        speechRecognizer.stopTranscribingWithTiming(audioFileURL: finalAudioURL)
        
        // Save transcript data securely
        await saveTranscriptSecurely(sessionId: session.id)
        
        // Update session metadata
        session = SecureRecordingSession(
            id: session.id,
            title: session.title,
            startTime: session.startTime,
            endTime: Date(),
            duration: recordingDuration,
            audioFileName: session.audioFileName,
            transcriptFileName: session.transcriptFileName,
            isCompleted: true,
            hasConsent: session.hasConsent
        )
        
        // Save session metadata securely
        await saveSessionMetadata(session)
        
        // Update state
        isRecording = false
        currentSession = nil
        currentAudioURL = nil
        recordingDuration = 0
        
        // Reload sessions list
        loadExistingSessions()
        transcriptCancellable?.cancel()
        transcriptCancellable = nil
        
        print("Completed secure recording session: \(session.id)")
        return session
    }
    
    /// Gets all secure recording sessions
    /// - Returns: Array of all recorded sessions
    func getAllSessions() -> [SecureRecordingSession] {
        return allSessions.sorted { $0.startTime > $1.startTime }
    }
    
    /// Deletes a secure recording session and all associated files
    /// - Parameter sessionId: ID of the session to delete
    /// - Returns: True if deletion was successful
    func deleteSession(_ sessionId: String) async -> Bool {
        guard let session = allSessions.first(where: { $0.id == sessionId }) else {
            print("Session not found: \(sessionId)")
            return false
        }
        
        // Delete audio file
        let audioDeleted = cacheManager.deleteSecureData(
            forKey: session.audioFileName,
            subdirectory: sessionId
        )
        
        // Delete transcript file
        let transcriptDeleted = cacheManager.deleteSecureData(
            forKey: session.transcriptFileName,
            subdirectory: sessionId
        )
        
        // Delete session metadata
        let metadataDeleted = cacheManager.deleteSecureData(
            forKey: "metadata.json",
            subdirectory: sessionId
        )
        
        // Delete session directory
        let sessionDirectoryURL = cacheManager.getSecureFileURL(fileName: "", sessionId: sessionId)
        do {
            try FileManager.default.removeItem(at: sessionDirectoryURL)
        } catch {
            print("Error deleting session directory: \(error)")
        }
        
        // Update sessions list
        allSessions.removeAll { $0.id == sessionId }
        
        let success = audioDeleted && transcriptDeleted && metadataDeleted
        print("Deleted secure recording session: \(sessionId) - success: \(success)")
        return success
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        audioRecordingManager.$recordingDuration
            .receive(on: DispatchQueue.main)
            .assign(to: &$recordingDuration)
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRecordingDuration()
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateRecordingDuration() {
        guard let session = currentSession else { return }
        recordingDuration = Date().timeIntervalSince(session.startTime)
    }
    
    private func validateStorageSpace() -> Bool {
        guard let availableSpace = cacheManager.getAvailableStorageSpace() else {
            return false
        }
        
        // Require at least 100MB free space for secure recordings
        let minimumSpace: Int64 = 100 * 1024 * 1024
        return availableSpace > minimumSpace
    }
    
    private func saveTranscriptSecurely(sessionId: String) async {
        // Final cleanup: rebuild transcript from deduplicated timing segments to remove duplicates/empties
        let rawSegments = timingDataManager.currentSession?.segments ?? []
        let dedupedSegments = deduplicateSegments(rawSegments)
        let transcript = buildNormalizedTranscript(from: dedupedSegments)
        let currentSession = timingDataManager.currentSession
        
        print("Saving transcript: \(transcript.count) chars, \(currentSession?.segments.count ?? 0) segments")
        
        let payload = SecureTranscriptPayload(
            transcript: transcript,
            segments: dedupedSegments,
            savedAt: Date()
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(payload)
            let fileName = "transcript_\(sessionId).json"
            
            let savedURL = cacheManager.saveSecurely(
                data: jsonData,
                forKey: fileName,
                subdirectory: sessionId
            )
            
            if savedURL != nil {
                print("Saved secure transcript for session: \(sessionId)")
            } else {
                print("Failed to save secure transcript for session: \(sessionId)")
            }
        } catch {
            print("Error serializing transcript data: \(error)")
        }
    }

    /// Builds an AttributedString with visual cues for stable vs processing text.
    /// - Parameters:
    ///   - segments: The current list of cleaned/deduplicated segments.
    ///   - previous: The previous list of segments.
    /// - Returns: AttributedString with stable text in normal font and changing text in italic.
    private func buildStyledTranscript(from segments: [TranscriptionSegment], previous: [TranscriptionSegment]) -> AttributedString {
        var fullString = AttributedString("")
        
        // Find the "common prefix" index where segments match exactly
        var mismatchIndex = 0
        let minCount = min(segments.count, previous.count)
        
        while mismatchIndex < minCount {
            let current = segments[mismatchIndex]
            let prev = previous[mismatchIndex]
            
            // Check for equality (text, start, end)
            // Using small epsilon for time comparison
            let sameText = current.text == prev.text
            let sameStart = abs(current.startTime - prev.startTime) < 0.001
            let sameEnd = abs(current.endTime - prev.endTime) < 0.001
            
            if sameText && sameStart && sameEnd {
                mismatchIndex += 1
            } else {
                break
            }
        }
        
        // Build the string
        for (index, segment) in segments.enumerated() {
            let cleanText = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanText.isEmpty else { continue }
            
            var attrSegment = AttributedString(cleanText)
            
            // Apply styling
            if index < mismatchIndex {
                // Stable -> Normal (Black/Primary)
                // No specific font attribute needed, defaults to body/primary
            } else {
                // Changing/New -> Italic (Gray/Secondary)
                attrSegment.font = .body.italic()
                attrSegment.foregroundColor = .secondary
            }
            
            // Add space if not first
            if !fullString.characters.isEmpty {
                fullString.append(AttributedString(" "))
            }
            fullString.append(attrSegment)
        }
        
        return fullString
    }

    /// Builds a normalized transcript string from timing segments:
    /// - trims whitespace/newlines per segment
    /// - filters out empty segments
    /// - joins with single spaces
    private func buildNormalizedTranscript(from segments: [TranscriptionSegment]) -> String {
        return segments
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func saveSessionMetadata(_ session: SecureRecordingSession) async {
        do {
            let jsonData = try JSONEncoder().encode(session)
            
            let savedURL = cacheManager.saveSecurely(
                data: jsonData,
                forKey: "metadata.json",
                subdirectory: session.id
            )
            
            if savedURL != nil {
                print("Saved secure metadata for session: \(session.id)")
            } else {
                print("Failed to save secure metadata for session: \(session.id)")
            }
        } catch {
            print("Error encoding session metadata: \(error)")
        }
    }
    
    private func loadExistingSessions() {
        let sessionFiles = cacheManager.listSecureFiles()
        var sessions: [SecureRecordingSession] = []
        
        for sessionFile in sessionFiles {
            let sessionId = sessionFile.lastPathComponent
            let metadataURL = cacheManager.getSecureFileURL(fileName: "metadata.json", sessionId: sessionId)
            
            if let metadataData = cacheManager.retrieveSecureData(forKey: "metadata.json", subdirectory: sessionId),
               let session = try? JSONDecoder().decode(SecureRecordingSession.self, from: metadataData) {
                sessions.append(session)
            }
        }
        
        allSessions = sessions.sorted { $0.startTime > $1.startTime }
        print("Loaded \(allSessions.count) secure recording sessions")
    }
    
    /// Loads secure playback resources for a completed session.
    /// - Parameter session: Secure session to load.
    /// - Returns: Audio URL + transcript payload if available.
    func loadPlaybackResources(for session: SecureRecordingSession) -> SecurePlaybackResources? {
        guard session.isCompleted else {
            print("Secure playback unavailable for incomplete session: \(session.id)")
            return nil
        }
        
        let audioURL = cacheManager.getSecureFileURL(
            fileName: session.audioFileName,
            sessionId: session.id
        )
        
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            print("Audio file missing for secure session: \(session.id)")
            return nil
        }
        
        do {
            try cacheManager.validateFileProtection(at: audioURL)
        } catch {
            print("Audio file missing complete protection for session \(session.id): \(error)")
            return nil
        }
        
        guard let transcriptData = cacheManager.retrieveSecureData(
            forKey: session.transcriptFileName,
            subdirectory: session.id
        ) else {
            print("Transcript missing for secure session: \(session.id)")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(SecureTranscriptPayload.self, from: transcriptData)
            
            // Deduplicate and clean transcript for playback
            let dedupedSegments = deduplicateSegments(payload.segments)
            let cleanedTranscript = buildNormalizedTranscript(from: dedupedSegments)
            return SecurePlaybackResources(
                audioURL: audioURL,
                transcript: cleanedTranscript,
                segments: dedupedSegments
            )
        } catch {
            print("Failed to decode secure transcript for session \(session.id): \(error)")
            return nil
        }
    }
    
    /// Stops any in-progress secure playback to clear audio buffers.
    func stopSecurePlayback() {
        audioPlaybackManager.stop()
    }
}

// MARK: - Extensions

extension Date {
    var ISO8601String: String {
        return ISO8601DateFormatter().string(from: self)
    }
} 

private struct SecureTranscriptPayload: Codable {
    let transcript: String
    let segments: [TranscriptionSegment]
    let savedAt: Date
}

/// Bundle of secure playback resources needed by the modal player.
struct SecurePlaybackResources {
    let audioURL: URL
    let transcript: String
    let segments: [TranscriptionSegment]
}