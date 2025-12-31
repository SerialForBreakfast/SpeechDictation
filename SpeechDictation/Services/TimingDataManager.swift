//
//  TimingDataManager.swift
//  SpeechDictation
//
//  Created by AI Assistant on 12/19/24.
//

import Foundation
import Speech

/// Service responsible for managing timing data for audio recordings and transcriptions
/// Handles storage, retrieval, and export of timing metadata with millisecond precision
class TimingDataManager: ObservableObject {
    static let shared = TimingDataManager()
    
    @Published private(set) var currentSession: AudioRecordingSession?
    @Published private(set) var segments: [TranscriptionSegment] = []
    @Published private(set) var isRecording = false
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let sessionsDirectory: URL
    private let timingDataQueue = DispatchQueue(label: "timingDataQueue", qos: .userInitiated)
    
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        sessionsDirectory = documentsDirectory.appendingPathComponent("Sessions")
        createSessionsDirectoryIfNeeded()
    }
    
    // MARK: - Session Management
    
    /// Starts a new recording session
    /// - Parameter sessionId: Optional custom session ID, generates one if not provided
    /// - Returns: The created session ID
    @MainActor
    func startSession(sessionId: String? = nil) -> String {
        let id = sessionId ?? generateSessionId()
        let session = AudioRecordingSession(
            sessionId: id,
            startTime: Date(),
            endTime: nil,
            audioFileURL: nil,
            segments: [],
            totalDuration: 0,
            wordCount: 0
        )
        
        currentSession = session
        segments = []
        isRecording = true
        
        print("Started recording session: \(id)")
        return id
    }
    
    /// Stops the current recording session
    /// - Parameter audioFileURL: URL to the recorded audio file
    @MainActor
    func stopSession(audioFileURL: URL? = nil) {
        guard var session = currentSession else {
            print("No active session to stop")
            return
        }
        
        session = AudioRecordingSession(
            sessionId: session.sessionId,
            startTime: session.startTime,
            endTime: Date(),
            audioFileURL: audioFileURL,
            segments: segments,
            totalDuration: session.sessionDuration,
            wordCount: segments.reduce(0) { $0 + $1.text.components(separatedBy: " ").count }
        )
        
        currentSession = session
        isRecording = false
        
        // Save session data
        saveSession(session)
        
        print("Stopped recording session: \(session.sessionId)")
    }
    
    // MARK: - Segment Management
    
    /// Replaces all segments with the provided list
    /// - Parameter newSegments: The new list of segments
    @MainActor
    func updateSegments(_ newSegments: [TranscriptionSegment]) {
        segments = newSegments
        
        // Update current session
        if var session = currentSession {
            session = AudioRecordingSession(
                sessionId: session.sessionId,
                startTime: session.startTime,
                endTime: session.endTime,
                audioFileURL: session.audioFileURL,
                segments: segments,
                totalDuration: session.sessionDuration,
                wordCount: segments.reduce(0) { $0 + $1.text.components(separatedBy: " ").count }
            )
            currentSession = session
        }
        
        print("Updated segments: count=\(segments.count)")
    }

    /// Merges segments into the current list without deleting previously-seen content.
    ///
    /// This is designed for live speech recognition where partial results may intermittently
    /// omit earlier segments. We upsert by (rounded) `startTime` to keep a stable timeline while
    /// still allowing the recognizer to revise previously emitted words.
    ///
    /// Concurrency: `@MainActor` because `segments` and `currentSession` are published and consumed by SwiftUI.
    /// - Parameter newSegments: Latest set of segments from the speech recognizer.
    @MainActor
    func mergeSegments(_ newSegments: [TranscriptionSegment]) {
        guard !newSegments.isEmpty else { return }

        // Filter invalid segments (negative times or NaNs)
        let validNewSegments = newSegments.filter {
            $0.startTime >= 0 && $0.endTime >= 0 && !$0.startTime.isNaN && !$0.endTime.isNaN
        }
        guard !validNewSegments.isEmpty else { return }

        func key(for segment: TranscriptionSegment) -> Int {
            Int((segment.startTime * 1000).rounded())
        }

        var mergedByStartTime: [Int: TranscriptionSegment] = Dictionary(
            uniqueKeysWithValues: segments.map { (key(for: $0), $0) }
        )

        for segment in validNewSegments {
            // Deduplication: if we already have this exact segment (text + times), skip it.
            // But if times match and text differs, we overwrite (it's a correction).
            let k = key(for: segment)
            if let existing = mergedByStartTime[k] {
                // If it's effectively a duplicate, keep the existing one (or overwrite if identical - same result)
                // But we want to allow *correction* (same time, new text).
                // The tricky case is if we receive the *same* text again. We shouldn't duplicate it.
                // Our map logic handles "same time replaces old", which is correct for corrections.
                //
                // What about *duplicates*? If we just assign, we replace.
                // The only problem is if we have multiple segments mapping to the same key *in the input*.
                // But `validNewSegments` is a list.
                
                // If it's an exact duplicate (text + start + end match), we don't need to do anything.
                // If it's a correction (text differs, confidence higher/differs), we update.
                mergedByStartTime[k] = segment
            } else {
                mergedByStartTime[k] = segment
            }
        }

        let mergedSegments = mergedByStartTime.values.sorted { $0.startTime < $1.startTime }
        updateSegments(mergedSegments)
    }
    
    /// Gets the segment at a specific time position
    /// - Parameter time: Time in seconds from session start
    /// - Returns: The segment at that time, or nil if not found
    func getSegmentAtTime(_ time: TimeInterval) -> TranscriptionSegment? {
        return segments.first { segment in
            time >= segment.startTime && time <= segment.endTime
        }
    }
    
    /// Clears all segments (for testing)
    /// - Note: This is primarily for unit tests to reset state
    @MainActor
    func clearSegments() {
        updateSegments([])
    }
    
    /// Gets all segments within a time range
    /// - Parameters:
    ///   - startTime: Start time in seconds
    ///   - endTime: End time in seconds
    /// - Returns: Array of segments within the time range
    func getSegmentsInRange(startTime: TimeInterval, endTime: TimeInterval) -> [TranscriptionSegment] {
        return segments.filter { segment in
            segment.startTime <= endTime && segment.endTime >= startTime
        }
    }
    
    // MARK: - Session Storage
    
    /// Saves a session to persistent storage
    /// - Parameter session: The session to save
    private func saveSession(_ session: AudioRecordingSession) {
        timingDataQueue.async {
            let sessionURL = self.sessionsDirectory.appendingPathComponent("\(session.sessionId).json")
            
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(session)
                try data.write(to: sessionURL)
                print("Saved session: \(session.sessionId)")
            } catch {
                print("Error saving session: \(error)")
            }
        }
    }
    
    /// Loads a session from persistent storage
    /// - Parameter sessionId: The session ID to load
    /// - Returns: The loaded session, or nil if not found
    func loadSession(sessionId: String) -> AudioRecordingSession? {
        let sessionURL = sessionsDirectory.appendingPathComponent("\(sessionId).json")
        
        guard fileManager.fileExists(atPath: sessionURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: sessionURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let session = try decoder.decode(AudioRecordingSession.self, from: data)
            print("Loaded session: \(sessionId)")
            return session
        } catch {
            print("Error loading session: \(error)")
            return nil
        }
    }
    
    /// Gets all saved sessions
    /// - Returns: Array of all saved sessions
    func getAllSessions() -> [AudioRecordingSession] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: sessionsDirectory, includingPropertiesForKeys: nil)
            let jsonURLs = fileURLs.filter { $0.pathExtension == "json" }
            
            return jsonURLs.compactMap { url in
                loadSession(sessionId: url.deletingPathExtension().lastPathComponent)
            }.sorted { $0.startTime > $1.startTime }
        } catch {
            print("Error loading sessions: \(error)")
            return []
        }
    }
    
    /// Deletes a session
    /// - Parameter sessionId: The session ID to delete
    /// - Returns: True if deletion was successful
    func deleteSession(sessionId: String) -> Bool {
        let sessionURL = sessionsDirectory.appendingPathComponent("\(sessionId).json")
        
        do {
            try fileManager.removeItem(at: sessionURL)
            print("Deleted session: \(sessionId)")
            return true
        } catch {
            print("Error deleting session: \(error)")
            return false
        }
    }
    
    // MARK: - Export Functions
    
    /// Exports timing data in the specified format
    /// - Parameters:
    ///   - session: The session to export
    ///   - format: The export format
    /// - Returns: The exported content as a string
    func exportTimingData(session: AudioRecordingSession, format: ExportManager.TimingExportFormat) -> String {
        switch format {
        case .srt:
            return exportToSRT(session: session)
        case .vtt:
            return exportToVTT(session: session)
        case .ttml:
            return exportToTTML(session: session)
        case .json:
            return exportToJSON(session: session)
        }
    }
    
    // MARK: - Private Methods
    
    private func createSessionsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: sessionsDirectory.path) {
            do {
                try fileManager.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
                print("Created sessions directory")
            } catch {
                print("Error creating sessions directory: \(error)")
            }
        }
    }
    
    private func generateSessionId() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "session_\(timestamp)"
    }
    
    private func exportToSRT(session: AudioRecordingSession) -> String {
        var srtContent = ""
        
        for (index, segment) in session.segments.enumerated() {
            srtContent += "\(index + 1)\n"
            srtContent += "\(segment.formattedStartTime) --> \(segment.formattedEndTime)\n"
            srtContent += "\(segment.text)\n\n"
        }
        
        return srtContent
    }
    
    private func exportToVTT(session: AudioRecordingSession) -> String {
        var vttContent = "WEBVTT\n\n"
        
        for segment in session.segments {
            vttContent += "\(segment.formattedStartTime) --> \(segment.formattedEndTime)\n"
            vttContent += "\(segment.text)\n\n"
        }
        
        return vttContent
    }
    
    private func exportToTTML(session: AudioRecordingSession) -> String {
        var ttmlContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tt xmlns="http://www.w3.org/ns/ttml">
        <body>
        <div>
        """
        
        for segment in session.segments {
            let startTime = formatTimeForTTML(segment.startTime)
            let endTime = formatTimeForTTML(segment.endTime)
            
            ttmlContent += """
            
            <p begin="\(startTime)" end="\(endTime)">\(segment.text)</p>
            """
        }
        
        ttmlContent += """
        
        </div>
        </body>
        </tt>
        """
        
        return ttmlContent
    }
    
    private func exportToJSON(session: AudioRecordingSession) -> String {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(session)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            print("Error encoding session to JSON: \(error)")
            return ""
        }
    }
    
    private func formatTimeForTTML(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 1000)
        
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }
} 