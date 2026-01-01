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
    @Published private(set) var liveTranscript: String = ""
    
    // MARK: - Private Properties
    
    private let audioRecordingManager = AudioRecordingManager.shared
    private let speechRecognizer = SpeechRecognizer()
    private let cacheManager = CacheManager.shared
    private let timingDataManager = TimingDataManager.shared
    
    private var recordingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var transcriptCancellable: AnyCancellable?
    private var currentAudioURL: URL?
    
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
            AppLog.notice(.secureRecording, "Secure recording already in progress", dedupeInterval: 2)
            return nil
        }
        
        guard hasConsent else {
            AppLog.notice(.secureRecording, "Cannot start secure recording without user consent")
            return nil
        }
        
        // Validate storage space
        guard validateStorageSpace() else {
            AppLog.error(.secureRecording, "Insufficient storage space for secure recording")
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
        
        guard let currentAudioURL else {
            AppLog.error(.secureRecording, "Failed to start secure audio recording")
            currentSession = nil
            return nil
        }

        // Persist the actual recorded filename so playback resolves the correct secure URL.
        if let session = currentSession {
            currentSession = SecureRecordingSession(
                id: session.id,
                title: session.title,
                startTime: session.startTime,
                endTime: session.endTime,
                duration: session.duration,
                audioFileName: currentAudioURL.lastPathComponent,
                transcriptFileName: session.transcriptFileName,
                isCompleted: session.isCompleted,
                hasConsent: session.hasConsent
            )
        }
        
        // Connect audio buffer stream to speech recognizer
        audioRecordingManager.audioBufferHandler = { [weak self] buffer in
            self?.speechRecognizer.appendAudioBuffer(buffer)
        }
        
        // Initialize live transcript as plain text (String) for consistency with storage and SRT export
        // Note: SRT files require plain text, and we maintain String throughout the pipeline
        liveTranscript = ""
        transcriptCancellable?.cancel()
        transcriptCancellable = speechRecognizer.$transcribedText
            .receive(on: RunLoop.main)
            .sink { [weak self] latestText in
                // Use plain text directly - speechRecognizer.transcribedText is already a String
                // This ensures consistency with SRT export which requires plain text
                self?.liveTranscript = latestText
            }
        
        // Start on-device transcription with timing using external audio source
        speechRecognizer.startTranscribingWithTiming(sessionId: sessionId, isExternalAudioSource: true)
        
        // Update state
        isRecording = true
        hasValidConsent = hasConsent
        recordingDuration = 0
        
        // Start duration timer
        startRecordingTimer()
        
        AppLog.info(.secureRecording, "Started secure recording session: \(sessionId)")
        return sessionId
    }
    
    /// Stops the current secure recording session
    /// - Returns: The completed session metadata, or nil if no active session
    func stopSecureRecording() async -> SecureRecordingSession? {
        guard isRecording, var session = currentSession else {
            AppLog.notice(.secureRecording, "No active secure recording to stop", dedupeInterval: 2)
            return nil
        }
        
        // Stop recording timer
        stopRecordingTimer()
        
        // Clear audio buffer handler
        audioRecordingManager.audioBufferHandler = nil
        
        // Stop audio recording
        let finalAudioURL = audioRecordingManager.stopRecording()
        
        // Stop transcription
        await speechRecognizer.stopTranscribingWithTimingAndWait(audioFileURL: finalAudioURL)
        
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
        
        AppLog.info(.secureRecording, "Completed secure recording session: \(session.id)")
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
            AppLog.notice(.secureRecording, "Session not found: \(sessionId)")
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
            AppLog.error(.secureRecording, "Error deleting session directory: \(error)")
        }
        
        // Update sessions list
        allSessions.removeAll { $0.id == sessionId }
        
        let success = audioDeleted && transcriptDeleted && metadataDeleted
        AppLog.info(.secureRecording, "Deleted secure recording session: \(sessionId) - success: \(success)")
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
        let transcript = speechRecognizer.transcribedText
        let currentSession = timingDataManager.currentSession
        let payload = SecureTranscriptPayload(
            transcript: transcript,
            segments: currentSession?.segments ?? [],
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
                AppLog.info(.secureRecording, "Saved secure transcript for session: \(sessionId)")
            } else {
                AppLog.error(.secureRecording, "Failed to save secure transcript for session: \(sessionId)")
            }
        } catch {
            AppLog.error(.secureRecording, "Error serializing transcript data: \(error)")
        }
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
                AppLog.info(.secureRecording, "Saved secure metadata for session: \(session.id)")
            } else {
                AppLog.error(.secureRecording, "Failed to save secure metadata for session: \(session.id)")
            }
        } catch {
            AppLog.error(.secureRecording, "Error encoding session metadata: \(error)")
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
        AppLog.info(.secureRecording, "Loaded \(allSessions.count) secure recording sessions", dedupeInterval: 2)
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
