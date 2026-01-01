//
//  SpeechRecognizer+Timing.swift
//  SpeechDictation
//
//  Created by AI Assistant on 12/19/24.
//

import Foundation
import Speech
import AVFoundation

/// Extension to SpeechRecognizer for capturing timing data with millisecond precision
/// Integrates with TimingDataManager to store transcription segments with precise timing information
extension SpeechRecognizer {
    
    /// Starts transcription with timing data capture using transcription engine
    /// - Parameters:
    ///   - sessionId: Optional session ID for timing data management
    ///   - isExternalAudioSource: Whether audio is provided externally (e.g. from recording manager)
    ///
    /// Concurrency: Engine handles async/await, this method coordinates timing session and event stream
    func startTranscribingWithTiming(sessionId: String? = nil, isExternalAudioSource: Bool = false) {
        AppLog.info(.transcription, "Start transcription with timing (external source: \(isExternalAudioSource))")

        // Reset per-session accumulation so each new timing transcription starts clean.
        resetTranscriptAccumulationForNewSession(isExternalAudioSource: isExternalAudioSource)
        timingSessionStartDate = Date()
        timingRecognitionTimeOffset = 0
        
        // Start timing data session on main queue since TimingDataManager is @MainActor
        DispatchQueue.main.async {
            _ = TimingDataManager.shared.startSession(sessionId: sessionId)
        }
        
        // Stop any existing engine and event stream (awaited inside the new task to avoid overlap).
        let previousEngine = transcriptionEngine
        let previousTask = engineEventTask

        // Create appropriate engine via factory
        let configuration = TranscriptionEngineConfiguration.default
        let engine = TranscriptionEngineFactory.createEngine(
            configuration: configuration,
            isExternalAudioSource: isExternalAudioSource
        )
        transcriptionEngine = engine

        // Start engine and subscribe to its event stream with timing support
        engineEventTask = Task { [weak self] in
            do {
                // Ensure any prior engine has fully stopped before starting a new one.
                await previousEngine?.stop()
                if let previousTask {
                    await previousTask.value
                }

                // CRITICAL: Subscribe to event stream FIRST so continuation is set before start() yields events
                // Otherwise, events emitted during start() are lost (continuation is nil).
                let eventStream = engine.eventStream()
                
                // Start the engine (now continuation is ready to receive events)
                try await engine.start(audioBufferHandler: { [weak self] buffer in
                    // Forward audio buffers to level monitoring if needed
                    self?.processAudioForLevelMonitoring(buffer)
                })

                // Process events from the stream
                for await event in eventStream {
                    await self?.handleEngineEventWithTiming(event)
                }
            } catch {
                AppLog.error(.transcription, "Engine start failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.transcribedText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Handles events from the transcription engine with timing data support
    ///
    /// Concurrency: Called from background task, marshals UI updates to main thread
    private func handleEngineEventWithTiming(_ event: TranscriptionEvent) async {
        switch event {
        case .partial(let text, let segments):
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !text.isEmpty else { return }
                self.transcribedText = text

                let storedBefore = TimingDataManager.shared.segments.count
                if !segments.isEmpty {
                    TimingDataManager.shared.mergeSegments(segments)
                }
                let storedAfter = TimingDataManager.shared.segments.count

                TimingDataManager.shared.recordAudit(
                    event: .partial,
                    text: text,
                    incomingSegmentCount: segments.count,
                    storedSegmentCount: storedAfter,
                    storedSegmentDelta: storedAfter - storedBefore,
                    note: nil
                )
            }
            
        case .final(let text, let segments):
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !text.isEmpty else { return }

                AppLog.debug(.timing, "UI final: text=\(text.count)ch, merging \(segments.count) segments", verboseOnly: true)
                self.transcribedText = text

                let storedBefore = TimingDataManager.shared.segments.count
                if !segments.isEmpty {
                    TimingDataManager.shared.mergeSegments(segments)
                }
                let storedAfter = TimingDataManager.shared.segments.count
                AppLog.debug(.timing, "UI final: segments \(storedBefore) -> \(storedAfter) (delta \(storedAfter - storedBefore))", verboseOnly: true)

                TimingDataManager.shared.recordAudit(
                    event: .final,
                    text: text,
                    incomingSegmentCount: segments.count,
                    storedSegmentCount: storedAfter,
                    storedSegmentDelta: storedAfter - storedBefore,
                    note: nil
                )
            }
            
        case .audioLevel(let level):
            DispatchQueue.main.async { [weak self] in
                self?.currentLevel = level
            }
            
        case .error(let error):
            AppLog.error(.transcription, "Engine error: \(error.localizedDescription)")
            await MainActor.run {
                let storedCount = TimingDataManager.shared.segments.count
                TimingDataManager.shared.recordAudit(
                    event: .error,
                    text: self.transcribedText.isEmpty ? nil : self.transcribedText,
                    incomingSegmentCount: 0,
                    storedSegmentCount: storedCount,
                    storedSegmentDelta: 0,
                    note: error.localizedDescription
                )
            }
            
        case .stateChange(let state):
            if state == .restarting || state == .running {
                AppLog.debug(.transcription, "Engine state: \(state)", dedupeInterval: 1)
            }
            await MainActor.run {
                let storedCount = TimingDataManager.shared.segments.count
                TimingDataManager.shared.recordAudit(
                    event: .stateChange,
                    text: nil,
                    incomingSegmentCount: 0,
                    storedSegmentCount: storedCount,
                    storedSegmentDelta: 0,
                    note: "\(state)"
                )
            }
        }
    }
    
    /// Stops transcription and saves timing data
    /// - Parameter audioFileURL: URL to the recorded audio file (optional)
    ///
    /// Concurrency: Coordinates async engine stop with sync timing data finalization
    func stopTranscribingWithTiming(audioFileURL: URL? = nil) {
        Task {
            await stopTranscribingWithTimingAndWait(audioFileURL: audioFileURL)
        }
    }

    /// Stops transcription with timing and awaits engine shutdown before returning.
    ///
    /// Concurrency: This must await `engine.stop()` so final transcript/segments are delivered
    /// through the event stream before we persist them.
    func stopTranscribingWithTimingAndWait(audioFileURL: URL? = nil) async {
        AppLog.info(.transcription, "Stop transcription with timing")

        markRecognitionStopping()

        // Stop the engine first so the event task can drain the final events.
        let engine = transcriptionEngine
        await engine?.stop()

        // Wait for the event task to finish consuming final events.
        if let task = engineEventTask {
            await task.value
        }

        await MainActor.run {
            self.engineEventTask = nil
            self.transcriptionEngine = nil
            TimingDataManager.shared.stopSession(audioFileURL: audioFileURL)
        }
    }
    
    /// Gets the current session from timing data manager
    /// - Returns: Current audio recording session, or nil if none active
    func getCurrentSession() -> AudioRecordingSession? {
        return TimingDataManager.shared.currentSession
    }
    
    /// Gets all segments for the current session
    /// - Returns: Array of transcription segments with timing data
    func getCurrentSegments() -> [TranscriptionSegment] {
        return TimingDataManager.shared.segments
    }
    
    /// Gets the segment at a specific time position
    /// - Parameter time: Time in seconds from session start
    /// - Returns: The segment at that time, or nil if not found
    func getSegmentAtTime(_ time: TimeInterval) -> TranscriptionSegment? {
        return TimingDataManager.shared.getSegmentAtTime(time)
    }
    
    /// Gets all segments within a time range
    /// - Parameters:
    ///   - startTime: Start time in seconds
    ///   - endTime: End time in seconds
    /// - Returns: Array of segments within the time range
    func getSegmentsInRange(startTime: TimeInterval, endTime: TimeInterval) -> [TranscriptionSegment] {
        return TimingDataManager.shared.getSegmentsInRange(startTime: startTime, endTime: endTime)
    }
    
    /// Exports timing data in the specified format
    /// - Parameters:
    ///   - session: The session to export
    ///   - format: The export format
    /// - Returns: The exported content as a string
    func exportTimingData(session: AudioRecordingSession, format: ExportManager.TimingExportFormat) -> String {
        return TimingDataManager.shared.exportTimingData(session: session, format: format)
    }
    
    /// Gets all saved sessions
    /// - Returns: Array of all saved sessions
    func getAllSessions() -> [AudioRecordingSession] {
        return TimingDataManager.shared.getAllSessions()
    }
    
    /// Loads a session from persistent storage
    /// - Parameter sessionId: The session ID to load
    /// - Returns: The loaded session, or nil if not found
    func loadSession(sessionId: String) -> AudioRecordingSession? {
        return TimingDataManager.shared.loadSession(sessionId: sessionId)
    }
    
    /// Deletes a session
    /// - Parameter sessionId: The session ID to delete
    /// - Returns: True if deletion was successful
    func deleteSession(sessionId: String) -> Bool {
        return TimingDataManager.shared.deleteSession(sessionId: sessionId)
    }
} 
