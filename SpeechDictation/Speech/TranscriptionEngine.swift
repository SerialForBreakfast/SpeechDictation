//
//  TranscriptionEngine.swift
//  SpeechDictation
//
//  Created by AI Assistant on 2025-12-13.
//
//  Protocol abstraction for speech transcription engines.
//  Supports both modern (iOS 26+) and legacy transcription backends.
//

import Foundation
import AVFoundation

/// Events emitted by a transcription engine during recognition
enum TranscriptionEvent: Sendable {
    /// Partial (in-progress) transcription result
    /// - Parameters:
    ///   - text: Current partial transcript text
    ///   - segments: Word-level segments with timing (if available)
    case partial(text: String, segments: [TranscriptionSegment])
    
    /// Final transcription result for a segment
    /// - Parameters:
    ///   - text: Finalized transcript text for this segment
    ///   - segments: Word-level segments with timing
    case final(text: String, segments: [TranscriptionSegment])
    
    /// Audio level measurement (for VU meter and silence detection)
    /// - Parameter level: Normalized audio level (0.0 to 1.0)
    case audioLevel(level: Float)
    
    /// Error occurred during transcription
    /// - Parameter error: The error that occurred
    case error(error: Error)
    
    /// Engine state changed (e.g., restarted task for pause handling)
    /// - Parameter state: New engine state
    case stateChange(state: TranscriptionEngineState)
}

/// State of a transcription engine
enum TranscriptionEngineState: Sendable, Equatable {
    case idle
    case starting
    case running
    case restarting // Handling pause/silence
    case stopping
    case stopped
    case error(Error)
    
    static func == (lhs: TranscriptionEngineState, rhs: TranscriptionEngineState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.starting, .starting),
             (.running, .running),
             (.restarting, .restarting),
             (.stopping, .stopping),
             (.stopped, .stopped):
            return true
        case (.error, .error):
            return true // Simplified: consider all errors equal
        default:
            return false
        }
    }
}

/// Configuration for transcription engines
struct TranscriptionEngineConfiguration: Sendable {
    /// Whether to require on-device recognition (privacy)
    let requiresOnDeviceRecognition: Bool
    
    /// RMS threshold for silence detection (0.0 to 1.0)
    /// Lower values = more sensitive to silence
    let silenceThreshold: Float
    
    /// Duration of silence before committing a segment (seconds)
    let silenceDuration: TimeInterval
    
    /// Maximum duration for a single recognition task (seconds)
    /// Used as safety net for legacy engines
    let maxTaskDuration: TimeInterval
    
    /// Default configuration optimized for conversation
    static let `default` = TranscriptionEngineConfiguration(
        requiresOnDeviceRecognition: true,
        silenceThreshold: 0.15,
        silenceDuration: 1.5,
        maxTaskDuration: 55.0
    )
}

/// Protocol for speech transcription engines
///
/// Concurrency: All methods must be called from the same actor/isolation context.
/// Implementations should use actors for internal state management.
protocol TranscriptionEngine: Sendable {
    /// Configuration for this engine
    var configuration: TranscriptionEngineConfiguration { get }
    
    /// Current engine state
    var state: TranscriptionEngineState { get async }
    
    /// Stream of transcription events
    /// - Returns: AsyncStream that emits events until engine is stopped
    func eventStream() -> AsyncStream<TranscriptionEvent>
    
    /// Start transcription
    /// - Parameter audioBufferHandler: Optional closure to receive raw audio buffers for external processing
    /// - Throws: If engine cannot start (e.g., permissions denied, hardware unavailable)
    func start(audioBufferHandler: (@Sendable (AVAudioPCMBuffer) -> Void)?) async throws
    
    /// Stop transcription and finalize any pending segments
    func stop() async
    
    /// Append an external audio buffer (for external audio source mode)
    /// - Parameter buffer: Audio buffer to process
    /// - Note: Only used when engine is configured for external audio source
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) async
}

/// Errors specific to transcription engines
enum TranscriptionEngineError: Error, LocalizedError {
    case notAvailable
    case permissionDenied
    case audioEngineFailure
    case recognizerNotAvailable
    case invalidConfiguration
    case alreadyRunning
    case notRunning
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Transcription engine is not available on this device"
        case .permissionDenied:
            return "Speech recognition or microphone permission denied"
        case .audioEngineFailure:
            return "Audio engine failed to start"
        case .recognizerNotAvailable:
            return "Speech recognizer is not available"
        case .invalidConfiguration:
            return "Invalid transcription engine configuration"
        case .alreadyRunning:
            return "Transcription engine is already running"
        case .notRunning:
            return "Transcription engine is not running"
        }
    }
}

/// Factory for creating the appropriate transcription engine based on OS version and capabilities
enum TranscriptionEngineFactory {
    /// Creates the best available transcription engine for the current platform
    /// - Parameters:
    ///   - configuration: Engine configuration
    ///   - isExternalAudioSource: Whether audio will be provided externally
    /// - Returns: Appropriate engine implementation
    static func createEngine(
        configuration: TranscriptionEngineConfiguration = .default,
        isExternalAudioSource: Bool = false
    ) -> any TranscriptionEngine {
        // TODO: iOS 26+ path disabled until SpeechAnalyzer APIs are confirmed available
        // The types exist in iOS 26 SDK but actual implementation may not be ready yet.
        // Uncomment when APIs are verified functional:
        //
        // if #available(iOS 26.0, *), isModernEngineAvailable() {
        //     print("[TranscriptionEngine] Using ModernTranscriptionEngine (iOS 26+)")
        //     return ModernTranscriptionEngine(
        //         configuration: configuration,
        //         isExternalAudioSource: isExternalAudioSource
        //     )
        // }
        
        // Current path: Enhanced SFSpeechRecognizer with RMS-based silence detection
        // This works on all iOS versions and handles long-form conversation with pauses
        print("[TranscriptionEngine] Using LegacyTranscriptionEngine (production-ready)")
        return LegacyTranscriptionEngine(
            configuration: configuration,
            isExternalAudioSource: isExternalAudioSource
        )
    }
    
    /// Check if modern engine APIs are actually available
    /// - Returns: true if SpeechAnalyzer APIs are functional
    private static func isModernEngineAvailable() -> Bool {
        if #available(iOS 26.0, *) {
            // TODO: Add runtime check for SpeechAnalyzer availability
            // For now, return false until APIs are confirmed
            return false
        }
        return false
    }
}
