//
//  LegacyTranscriptionEngine.swift
//  SpeechDictation
//
//  Created by AI Assistant on 2025-12-13.
//
//  Legacy transcription engine using SFSpeechRecognizer with RMS-based silence detection.
//  Implements rolling session pattern to handle long-form conversation on iOS < 26.
//  Inspired by Compiler-Inc/Transcriber approach.
//

import Foundation
import Speech
import AVFoundation

/// Transcription engine using SFSpeechRecognizer with enhanced pause handling
///
/// Concurrency: Actor-isolated to ensure thread-safe state management.
actor LegacyTranscriptionEngine: TranscriptionEngine {
    let configuration: TranscriptionEngineConfiguration
    private let isExternalAudioSource: Bool
    
    private(set) var state: TranscriptionEngineState = .idle
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var eventContinuation: AsyncStream<TranscriptionEvent>.Continuation?
    
    /// Buffer for accumulated transcript across restarts
    private var accumulatedTranscript: String = ""
    
    /// Current partial transcript from active task
    private var currentPartialTranscript: String = ""
    
    /// Last partial transcript to prevent regressions
    private var lastPartialTranscript: String = ""
    
    /// External audio buffer handler (for routing to other consumers)
    private var externalAudioBufferHandler: (@Sendable (AVAudioPCMBuffer) -> Void)?
    
    /// Silence detection state
    private var silenceStartTime: Date?
    private var lastAudioLevelAboveThreshold: Date = Date()
    private var isInSilence: Bool = false
    private var lastSegmentsForCurrentTask: [TranscriptionSegment] = []
    
    /// Recognition task start throttling (prevents per-buffer start attempts)
    private var lastTaskStartAttemptTime: Date?
    
    /// Task restart management
    private var taskStartTime: Date?
    private var isRestarting: Bool = false
    private var restartTimer: Task<Void, Never>?
    
    /// Session start time for timing offset calculations
    private var sessionStartTime: Date = Date()
    
    init(configuration: TranscriptionEngineConfiguration, isExternalAudioSource: Bool) {
        self.configuration = configuration
        self.isExternalAudioSource = isExternalAudioSource
    }
    
    nonisolated func eventStream() -> AsyncStream<TranscriptionEvent> {
        return AsyncStream { [weak self] continuation in
            Task {
                await self?.setEventContinuation(continuation)
            }
            
            continuation.onTermination = { @Sendable [weak self] _ in
                Task {
                    await self?.handleStreamTermination()
                }
            }
        }
    }
    
    private func setEventContinuation(_ continuation: AsyncStream<TranscriptionEvent>.Continuation) {
        self.eventContinuation = continuation
    }
    
    func start(audioBufferHandler: (@Sendable (AVAudioPCMBuffer) -> Void)?) async throws {
        guard state == .idle || state == .stopped else {
            throw TranscriptionEngineError.alreadyRunning
        }
        
        state = .starting
        eventContinuation?.yield(.stateChange(state: .starting))
        
        externalAudioBufferHandler = audioBufferHandler
        accumulatedTranscript = ""
        currentPartialTranscript = ""
        lastPartialTranscript = ""
        lastSegmentsForCurrentTask = []
        sessionStartTime = Date()
        silenceStartTime = nil
        isInSilence = false
        lastAudioLevelAboveThreshold = Date()
        lastTaskStartAttemptTime = nil
        
        // Check permissions
        let speechStatus: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            state = .error(TranscriptionEngineError.permissionDenied)
            throw TranscriptionEngineError.permissionDenied
        }
        
        // Start audio capture if needed.
        if !isExternalAudioSource {
            try await startAudioEngine()
        }

        // Start a recognition task immediately. If no audio arrives or the user is silent,
        // SFSpeech can error with "No speech detected". We treat that case as an idle condition
        // and wait for the next buffers/speech, rather than thrashing restarts.
        try await startRecognitionTask()
        
        // Start safety timer for task rotation (only rotates when a task is active).
        startTaskRotationTimer()
        
        state = .running
        eventContinuation?.yield(.stateChange(state: .running))
        
        print("[LegacyTranscriptionEngine] Started (external=\(isExternalAudioSource))")
    }
    
    func stop() async {
        guard state == .running || state == .restarting else { return }
        
        state = .stopping
        eventContinuation?.yield(.stateChange(state: .stopping))
        
        // Cancel timers
        restartTimer?.cancel()
        restartTimer = nil
        
        // Finalize any pending partial transcript
        if !currentPartialTranscript.isEmpty {
            let finalText = composeTranscript(accumulated: accumulatedTranscript, partial: currentPartialTranscript)
            accumulatedTranscript = finalText
            currentPartialTranscript = ""
            lastPartialTranscript = ""
            eventContinuation?.yield(.final(text: finalText, segments: lastSegmentsForCurrentTask))
        }
        
        // Stop recognition
        await stopRecognitionTask()
        
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        state = .stopped
        eventContinuation?.yield(.stateChange(state: .stopped))
        eventContinuation?.finish()
        
        print("[LegacyTranscriptionEngine] Stopped")
    }
    
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
        // Forward to external handler if configured
        externalAudioBufferHandler?(buffer)

        // If we don't currently have an active request/task (common after we stop on silence or
        // after a "No speech detected" idle transition), create a new task when buffers arrive.
        if state == .running, recognitionRequest == nil, !isRestarting {
            let now = Date()
            let shouldAttemptStart: Bool
            if let lastAttempt = lastTaskStartAttemptTime {
                shouldAttemptStart = now.timeIntervalSince(lastAttempt) >= 0.5
            } else {
                shouldAttemptStart = true
            }
            
            if shouldAttemptStart {
                lastTaskStartAttemptTime = now
                do {
                    try await startRecognitionTask()
                    print("[TASK] start (accum=\(accumulatedTranscript.count)ch)")
                } catch {
                    eventContinuation?.yield(.error(error: error))
                    print("[TASK] start failed: \(error.localizedDescription)")
                }
            }
        }
        
        // Append to recognition request
        recognitionRequest?.append(buffer)
        
        // Process for silence detection and audio level
        await processAudioBuffer(buffer)
    }
    
    // MARK: - Private Methods
    
    private func startRecognitionTask() async throws {
        // Stop any existing task (but NOT the audio engine)
        await stopRecognitionTask()
        
        // Create speech recognizer if needed
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer()
        }
        
        guard let recognizer = speechRecognizer else {
            throw TranscriptionEngineError.recognizerNotAvailable
        }
        
        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = configuration.requiresOnDeviceRecognition
        
        recognitionRequest = request
        taskStartTime = Date()
        
        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task {
                await self?.handleRecognitionResult(result: result, error: error)
            }
        }
        
        print("[LegacyTranscriptionEngine] Recognition task started")
    }
    
    private func startAudioEngine() async throws {
        audioEngine = AVAudioEngine()
        
        guard let engine = audioEngine,
              let inputNode = engine.inputNode as? AVAudioInputNode else {
            throw TranscriptionEngineError.audioEngineFailure
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("[LegacyTranscriptionEngine] Using native format: \(recordingFormat)")
        
        // Validate format
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw TranscriptionEngineError.audioEngineFailure
        }
        
        // Install tap
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            Task {
                await self?.appendAudioBuffer(buffer)
            }
        }
        
        engine.prepare()
        try engine.start()
        
        print("[LegacyTranscriptionEngine] Audio engine started")
    }
    
    private func stopRecognitionTask() async {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        taskStartTime = nil
        lastSegmentsForCurrentTask = []
    }
    
    // MARK: - Diagnostic State (minimal logging)
    private var lastLoggedTextLength: Int = 0
    private var recognitionResultCount: Int = 0
    
    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) async {
        if let result = result {
            recognitionResultCount += 1
            let newText = result.bestTranscription.formattedString
            
            guard !newText.isEmpty else { return }
            
            // Avoid regressions: only accept if text grew or result is final
            if newText.count >= lastPartialTranscript.count || result.isFinal {
                lastPartialTranscript = newText
                currentPartialTranscript = newText
            }
            
            let composedText = composeTranscript(accumulated: accumulatedTranscript, partial: currentPartialTranscript)
            
            // Calculate time offset for this task relative to overall session
            let taskOffset: TimeInterval
            if let taskStart = taskStartTime {
                taskOffset = taskStart.timeIntervalSince(sessionStartTime)
            } else {
                taskOffset = 0
            }
            
            // Convert segments with offset adjustment
            let segments = result.bestTranscription.segments.map { segment in
                TranscriptionSegment(
                    text: segment.substring,
                    startTime: taskOffset + segment.timestamp,
                    endTime: taskOffset + segment.timestamp + segment.duration,
                    confidence: segment.confidence
                )
            }
            lastSegmentsForCurrentTask = segments
            
            let shouldFinalize = result.isFinal
            
            // CRITICAL: Log only significant events
            let textLengthChanged = composedText.count != lastLoggedTextLength
            if textLengthChanged || shouldFinalize {
                let prefix = shouldFinalize ? "FINAL" : "partial"
                print("[\(prefix)] text=\(composedText.count)ch accum=\(accumulatedTranscript.count)ch offset=\(String(format: "%.1f", taskOffset))s segs=\(segments.count)")
                lastLoggedTextLength = composedText.count
            }
            
            if shouldFinalize {
                // Commit this segment
                let beforeLen = accumulatedTranscript.count
                accumulatedTranscript = composedText
                currentPartialTranscript = ""
                lastPartialTranscript = ""
                
                print("[COMMIT] accum: \(beforeLen)ch → \(accumulatedTranscript.count)ch (+\(accumulatedTranscript.count - beforeLen))")
                
                eventContinuation?.yield(.final(text: composedText, segments: segments))
                // Stop the task and wait for the next speech onset (VAD-gated).
                await stopRecognitionTask()
            } else {
                eventContinuation?.yield(.partial(text: composedText, segments: segments))
            }
        }
        
        if let error = error {
            let nsError = error as NSError
            
            // Ignore cancellation errors from our own stop flow
            if nsError.code == 301 || nsError.localizedDescription.localizedCaseInsensitiveContains("canceled") {
                return
            }
            
            // "No speech detected" is expected during long pauses. Do NOT restart in a tight loop.
            if nsError.localizedDescription.localizedCaseInsensitiveContains("no speech detected") {
                print("[IDLE] no-speech, waiting (accum=\(accumulatedTranscript.count)ch)")
                await stopRecognitionTask()
                isInSilence = true
                return
            }
            
            // For other errors, stop the task and wait for speech to resume. This avoids thrash
            // and keeps the session alive for long-form recordings.
            print("[ERROR] \(error.localizedDescription) (accum=\(accumulatedTranscript.count)ch)")
            eventContinuation?.yield(.error(error: error))
            await stopRecognitionTask()
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        let samples = UnsafeBufferPointer(start: channelData, count: frameLength)
        
        // Calculate RMS
        let rms: Float = {
            let meanSquare = samples.reduce(Float(0)) { $0 + $1 * $1 } / Float(samples.count)
            return sqrtf(meanSquare)
        }()
        
        // Convert to dBFS and normalize
        let rmsDB = rms == 0 ? -100 : 20.0 * log10f(rms)
        let normalizedLevel = max(0, min(1, (rmsDB + 60) / 60))
        
        eventContinuation?.yield(.audioLevel(level: normalizedLevel))
        
        // Silence detection
        let now = Date()
        let isAboveThreshold = normalizedLevel > configuration.silenceThreshold
        
        if isAboveThreshold {
            lastAudioLevelAboveThreshold = now
            silenceStartTime = nil
            isInSilence = false
        } else {
            if silenceStartTime == nil {
                silenceStartTime = now
            }
            
            let silenceDuration = now.timeIntervalSince(silenceStartTime!)
            if silenceDuration >= configuration.silenceDuration && !isInSilence {
                isInSilence = true
                
                // Commit the current utterance and stop the recognition task. We do NOT restart
                // during silence; we wait for the next speech onset to start a new task.
                if recognitionTask != nil, !currentPartialTranscript.isEmpty {
                    let beforeLen = accumulatedTranscript.count
                    let finalText = composeTranscript(accumulated: accumulatedTranscript, partial: currentPartialTranscript)
                    accumulatedTranscript = finalText
                    currentPartialTranscript = ""
                    lastPartialTranscript = ""
                    
                    print("[VAD] commit+stop \(String(format: "%.1f", silenceDuration))s (accum: \(beforeLen)ch → \(accumulatedTranscript.count)ch)")
                    eventContinuation?.yield(.final(text: accumulatedTranscript, segments: lastSegmentsForCurrentTask))
                } else if recognitionTask != nil {
                    print("[VAD] stop-task \(String(format: "%.1f", silenceDuration))s (no-new-text)")
                }
                
                await stopRecognitionTask()
            }
        }
    }
    
    private func restartRecognitionTask() async {
        // Only restart when a task is active (e.g., safety rotation while speaking).
        guard state == .running, !isRestarting, recognitionTask != nil else { return }
        
        isRestarting = true
        state = .restarting
        eventContinuation?.yield(.stateChange(state: .restarting))
        
        print("[RESTART] accum=\(accumulatedTranscript.count)ch, waiting 350ms...")
        
        // Brief delay to avoid tight restart loops
        try? await Task.sleep(nanoseconds: 350_000_000) // 0.35 seconds
        
        guard state == .restarting else {
            isRestarting = false
            return
        }
        
        do {
            try await startRecognitionTask()
            state = .running
            eventContinuation?.yield(.stateChange(state: .running))
            print("[RESTART] SUCCESS, accum still=\(accumulatedTranscript.count)ch")
        } catch {
            // Don't poison the whole engine. Emit error and fall back to idle.
            eventContinuation?.yield(.error(error: error))
            print("[RESTART] FAILED: \(error.localizedDescription)")
            await stopRecognitionTask()
        }
        
        isRestarting = false
    }
    
    private func startTaskRotationTimer() {
        restartTimer?.cancel()
        
        restartTimer = Task {
            while !Task.isCancelled {
                // Wait for max task duration
                try? await Task.sleep(nanoseconds: UInt64(configuration.maxTaskDuration * 1_000_000_000))
                
                guard !Task.isCancelled else { break }
                
                // Check if we should restart (safety net)
                if await self.recognitionTask != nil, let taskStart = await self.taskStartTime {
                    let elapsed = Date().timeIntervalSince(taskStart)
                    if elapsed >= configuration.maxTaskDuration {
                        print("[LegacyTranscriptionEngine] Safety timer: rotating task after \(elapsed)s")
                        await self.restartRecognitionTask()
                    }
                }
            }
        }
    }
    
    private func handleStreamTermination() async {
        await stop()
    }
    
    private func composeTranscript(accumulated: String, partial: String) -> String {
        if accumulated.isEmpty {
            return partial
        } else if partial.isEmpty {
            return accumulated
        } else {
            return accumulated + " " + partial
        }
    }
}
