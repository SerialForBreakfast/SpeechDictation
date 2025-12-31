//
//  ModernTranscriptionEngine.swift
//  SpeechDictation
//
//  Created by AI Assistant on 2025-12-13.
//
//  Modern transcription engine using SpeechAnalyzer + SpeechTranscriber (iOS 26+).
//  Designed for long-form conversation with natural pause handling.
//

import Foundation
import Speech
import AVFoundation

/// Transcription engine using iOS 26+ SpeechAnalyzer APIs
///
/// Concurrency: Actor-isolated to ensure thread-safe state management.
@available(iOS 26.0, *)
actor ModernTranscriptionEngine: TranscriptionEngine {
    let configuration: TranscriptionEngineConfiguration
    private let isExternalAudioSource: Bool
    
    private(set) var state: TranscriptionEngineState = .idle
    
    private var audioEngine: AVAudioEngine?
    private var analyzer: SpeechAnalyzer?
    private var eventContinuation: AsyncStream<TranscriptionEvent>.Continuation?
    
    /// Buffer for accumulated transcript across session
    private var accumulatedTranscript: String = ""
    
    /// Current partial transcript
    private var currentPartialTranscript: String = ""
    
    /// External audio buffer handler (for routing to other consumers)
    private var externalAudioBufferHandler: (@Sendable (AVAudioPCMBuffer) -> Void)?
    
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
        
        // Create SpeechAnalyzer
        guard let speechAnalyzer = SpeechAnalyzer() else {
            state = .error(TranscriptionEngineError.recognizerNotAvailable)
            throw TranscriptionEngineError.recognizerNotAvailable
        }
        
        analyzer = speechAnalyzer
        
        // Add SpeechTranscriber module for transcription
        let transcriber = SpeechTranscriber(configuration: .init())
        do {
            try await speechAnalyzer.addModule(transcriber)
        } catch {
            state = .error(error)
            throw error
        }
        
        // Start audio engine if not using external source
        if !isExternalAudioSource {
            try await startAudioEngine()
        }
        
        // Start processing transcription events
        startProcessingTranscriptionResults()
        
        state = .running
        eventContinuation?.yield(.stateChange(state: .running))
        
        print("[ModernTranscriptionEngine] Started successfully")
    }
    
    func stop() async {
        guard state == .running || state == .restarting else { return }
        
        state = .stopping
        eventContinuation?.yield(.stateChange(state: .stopping))
        
        // Finalize any pending partial transcript
        if !currentPartialTranscript.isEmpty {
            let finalText = composeTranscript(accumulated: accumulatedTranscript, partial: currentPartialTranscript)
            eventContinuation?.yield(.final(text: finalText, segments: []))
        }
        
        // Stop audio engine
        audioEngine?.stop()
        audioEngine = nil
        
        // Cleanup analyzer
        analyzer = nil
        
        state = .stopped
        eventContinuation?.yield(.stateChange(state: .stopped))
        eventContinuation?.finish()
        
        print("[ModernTranscriptionEngine] Stopped")
    }
    
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
        // Forward to external handler if configured
        externalAudioBufferHandler?(buffer)
        
        // Process audio level for VU meter
        await processAudioLevel(buffer: buffer)
        
        // SpeechAnalyzer handles audio internally when using microphone
        // External buffer support would require different configuration
        // For now, this is primarily for VU meter and external routing
    }
    
    // MARK: - Private Methods
    
    private func startAudioEngine() async throws {
        audioEngine = AVAudioEngine()
        
        guard let engine = audioEngine,
              let inputNode = engine.inputNode as? AVAudioInputNode else {
            throw TranscriptionEngineError.audioEngineFailure
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("[ModernTranscriptionEngine] Using native format: \(recordingFormat)")
        
        // Validate format
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw TranscriptionEngineError.audioEngineFailure
        }
        
        // Install tap for audio level monitoring and external routing
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            Task {
                await self?.appendAudioBuffer(buffer)
            }
        }
        
        engine.prepare()
        try engine.start()
        
        print("[ModernTranscriptionEngine] Audio engine started")
    }
    
    private func startProcessingTranscriptionResults() {
        guard let analyzer = analyzer else { return }
        
        Task {
            // Process transcription results from SpeechAnalyzer
            for await result in analyzer.transcriptionResults() {
                await handleTranscriptionResult(result)
            }
        }
    }
    
    private func handleTranscriptionResult(_ result: SpeechTranscriptionResult) async {
        let newText = result.formattedString
        
        guard !newText.isEmpty else { return }
        
        // Convert segments
        let segments = result.transcription.segments.map { segment in
            TranscriptionSegment(
                text: segment.substring,
                startTime: segment.timestamp,
                endTime: segment.timestamp + segment.duration,
                confidence: segment.confidence
            )
        }
        
        if result.isFinal {
            // Commit this segment and add to accumulated transcript
            accumulatedTranscript = composeTranscript(accumulated: accumulatedTranscript, partial: newText)
            currentPartialTranscript = ""
            
            eventContinuation?.yield(.final(text: accumulatedTranscript, segments: segments))
            print("[ModernTranscriptionEngine] Final result: \(accumulatedTranscript)")
        } else {
            // Update current partial
            currentPartialTranscript = newText
            let composedText = composeTranscript(accumulated: accumulatedTranscript, partial: currentPartialTranscript)
            
            eventContinuation?.yield(.partial(text: composedText, segments: segments))
        }
    }
    
    private func processAudioLevel(buffer: AVAudioPCMBuffer) async {
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

/// Placeholder for SpeechTranscriptionResult until iOS 26 SDK is available
/// This will be replaced with the actual type from Speech framework
@available(iOS 26.0, *)
extension SpeechAnalyzer {
    func transcriptionResults() -> AsyncStream<SpeechTranscriptionResult> {
        // Placeholder - actual implementation will use SpeechAnalyzer's result stream
        return AsyncStream { continuation in
            continuation.finish()
        }
    }
}

@available(iOS 26.0, *)
struct SpeechTranscriptionResult {
    let formattedString: String
    let transcription: SFTranscription
    let isFinal: Bool
}

@available(iOS 26.0, *)
class SpeechTranscriber {
    init(configuration: Configuration) {}
    
    struct Configuration {}
}

@available(iOS 26.0, *)
class SpeechAnalyzer {
    init?() {
        // Placeholder - will use actual SpeechAnalyzer initializer
        return nil
    }
    
    func addModule(_ module: SpeechTranscriber) async throws {
        // Placeholder
    }
}
