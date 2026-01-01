//
//  TimingDataManager.swift
//  SpeechDictation
//
//  Created by AI Assistant on 12/19/24.
//

import Foundation
import Speech

enum TranscriptAuditEvent: String, Codable {
    case sessionStart
    case sessionStop
    case partial
    case final
    case error
    case stateChange
}

struct TranscriptAuditEntry: Identifiable, Codable {
    let id: UUID
    let sequence: Int
    let timestamp: Date
    let sessionId: String?
    let event: TranscriptAuditEvent
    let textLength: Int
    let textDelta: Int
    let incomingSegmentCount: Int
    let storedSegmentCount: Int
    let storedSegmentDelta: Int
    let firstSegmentStart: TimeInterval?
    let lastSegmentEnd: TimeInterval?
    let replacedPriorText: Bool
    let text: String?
    let wasTruncated: Bool
    let note: String?
}

/// Service responsible for managing timing data for audio recordings and transcriptions
/// Handles storage, retrieval, and export of timing metadata with millisecond precision
class TimingDataManager: ObservableObject {
    static let shared = TimingDataManager()
    
    @Published private(set) var currentSession: AudioRecordingSession?
    @Published private(set) var segments: [TranscriptionSegment] = []
    @Published private(set) var isRecording = false
    @Published private(set) var auditEntries: [TranscriptAuditEntry] = []
    @Published private(set) var auditLogPath: String = ""
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let sessionsDirectory: URL
    private let auditLogsDirectory: URL
    private let timingDataQueue = DispatchQueue(label: "timingDataQueue", qos: .userInitiated)
    private let auditQueue = DispatchQueue(label: "timingAuditQueue", qos: .utility)
    private var auditSequence = 0
    private var lastAuditTextLength = 0
    private var lastAuditSegmentCount = 0
    private var auditLogURL: URL?
    private let maxAuditEntries = 300
    private let maxAuditTextLength = 500
    
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        sessionsDirectory = documentsDirectory.appendingPathComponent("Sessions")
        auditLogsDirectory = documentsDirectory.appendingPathComponent("AuditLogs")
        createSessionsDirectoryIfNeeded()
        createAuditLogsDirectoryIfNeeded()
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
        resetAuditState(sessionId: id)
        recordAudit(
            event: .sessionStart,
            text: nil,
            incomingSegmentCount: 0,
            storedSegmentCount: 0,
            storedSegmentDelta: 0,
            note: nil
        )
        
        AppLog.info(.timing, "Started recording session: \(id)")
        return id
    }
    
    /// Stops the current recording session
    /// - Parameter audioFileURL: URL to the recorded audio file
    @MainActor
    func stopSession(audioFileURL: URL? = nil) {
        guard var session = currentSession else {
            AppLog.notice(.timing, "Stop ignored; no active timing session")
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
        
        recordAudit(
            event: .sessionStop,
            text: nil,
            incomingSegmentCount: 0,
            storedSegmentCount: segments.count,
            storedSegmentDelta: 0,
            note: nil
        )

        // Save session data
        saveSession(session)
        
        AppLog.info(.timing, "Stopped recording session: \(session.sessionId)")
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
        
        AppLog.debug(.timing, "Updated segments count=\(segments.count)", verboseOnly: true)
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

    // MARK: - Transcript Audit

    @MainActor
    func recordAudit(
        event: TranscriptAuditEvent,
        text: String?,
        incomingSegmentCount: Int,
        storedSegmentCount: Int,
        storedSegmentDelta: Int,
        note: String?
    ) {
        let effectiveTextLength = text?.count ?? lastAuditTextLength
        let textDelta = text == nil ? 0 : effectiveTextLength - lastAuditTextLength
        let replacedPriorText = textDelta < 0

        let trimmedText: String?
        let wasTruncated: Bool
        if let text = text, text.count > maxAuditTextLength {
            trimmedText = String(text.prefix(maxAuditTextLength)) + "..."
            wasTruncated = true
        } else {
            trimmedText = text
            wasTruncated = false
        }

        let entry = TranscriptAuditEntry(
            id: UUID(),
            sequence: auditSequence + 1,
            timestamp: Date(),
            sessionId: currentSession?.sessionId,
            event: event,
            textLength: effectiveTextLength,
            textDelta: textDelta,
            incomingSegmentCount: incomingSegmentCount,
            storedSegmentCount: storedSegmentCount,
            storedSegmentDelta: storedSegmentDelta,
            firstSegmentStart: segments.first?.startTime,
            lastSegmentEnd: segments.last?.endTime,
            replacedPriorText: replacedPriorText,
            text: trimmedText,
            wasTruncated: wasTruncated,
            note: note
        )

        auditSequence += 1
        lastAuditTextLength = effectiveTextLength
        lastAuditSegmentCount = storedSegmentCount

        auditEntries.append(entry)
        if auditEntries.count > maxAuditEntries {
            auditEntries.removeFirst(auditEntries.count - maxAuditEntries)
        }

        appendAuditLog(entry)
    }

    @MainActor
    func clearAudit() {
        auditEntries.removeAll()
        auditSequence = 0
        lastAuditTextLength = 0
        lastAuditSegmentCount = 0

        if let auditLogURL {
            let url = auditLogURL
            auditQueue.async {
                try? self.fileManager.removeItem(at: url)
            }
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
                AppLog.info(.storage, "Saved session: \(session.sessionId)")
            } catch {
                AppLog.error(.storage, "Failed to save session: \(error.localizedDescription)")
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
            AppLog.info(.storage, "Loaded session: \(sessionId)")
            return session
        } catch {
            AppLog.error(.storage, "Failed to load session: \(error.localizedDescription)")
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
            AppLog.error(.storage, "Failed to load sessions: \(error.localizedDescription)")
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
            AppLog.info(.storage, "Deleted session: \(sessionId)")
            return true
        } catch {
            AppLog.error(.storage, "Failed to delete session: \(error.localizedDescription)")
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
                AppLog.info(.storage, "Created sessions directory")
            } catch {
                AppLog.error(.storage, "Failed to create sessions directory: \(error.localizedDescription)")
            }
        }
    }

    private func createAuditLogsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: auditLogsDirectory.path) {
            do {
                try fileManager.createDirectory(at: auditLogsDirectory, withIntermediateDirectories: true)
                AppLog.info(.storage, "Created audit logs directory")
            } catch {
                AppLog.error(.storage, "Failed to create audit logs directory: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func resetAuditState(sessionId: String) {
        auditEntries.removeAll()
        auditSequence = 0
        lastAuditTextLength = 0
        lastAuditSegmentCount = 0
        auditLogURL = auditLogsDirectory.appendingPathComponent("audit_\(sessionId).jsonl")
        auditLogPath = auditLogURL?.path ?? ""
    }

    private func appendAuditLog(_ entry: TranscriptAuditEntry) {
        guard let url = auditLogURL else { return }

        auditQueue.async {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(entry)
                var line = data
                line.append(0x0A)

                if self.fileManager.fileExists(atPath: url.path) {
                    let handle = try FileHandle(forWritingTo: url)
                    try handle.seekToEnd()
                    try handle.write(contentsOf: line)
                    try handle.close()
                } else {
                    try line.write(to: url)
                }
            } catch {
                AppLog.error(.storage, "Failed to append audit log: \(error.localizedDescription)")
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
            AppLog.error(.export, "Failed to encode session to JSON: \(error.localizedDescription)")
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
