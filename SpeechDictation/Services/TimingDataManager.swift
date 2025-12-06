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
    
    /// Adds a new transcription segment with timing data
    /// - Parameters:
    ///   - text: Transcribed text
    ///   - startTime: Start time in seconds from session start
    ///   - endTime: End time in seconds from session start
    ///   - confidence: Speech recognition confidence (0.0 - 1.0)
    @MainActor
    func addSegment(text: String, startTime: TimeInterval, endTime: TimeInterval, confidence: Float) {
        let segment = TranscriptionSegment(
            text: text,
            startTime: startTime,
            endTime: endTime,
            confidence: confidence
        )
        
        segments.append(segment)
        updateCurrentSession()
        
        print("Added segment: \(text) (\(startTime)s - \(endTime)s)")
    }
    
    /// Replaces all segments for the current session.
    /// Useful for synching with speech recognizers that update partial results.
    /// - Parameter newSegments: The new list of segments.
    @MainActor
    func setSegments(_ newSegments: [TranscriptionSegment]) {
        segments = newSegments
        updateCurrentSession()
    }
    
    private func updateCurrentSession() {
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
    }
    
    /// Gets the segment at a specific time position
    /// - Parameter time: Time in seconds from session start
    /// - Returns: The segment at that time, or nil if not found
    func getSegmentAtTime(_ time: TimeInterval) -> TranscriptionSegment? {
        return segments.first { segment in
            time >= segment.startTime && time <= segment.endTime
        }
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