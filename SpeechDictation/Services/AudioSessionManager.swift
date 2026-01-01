//
//  AudioSessionManager.swift
//  SpeechDictation
//
//  Created by AI Assistant on 7/13/25.
//

import Foundation
#if os(iOS)
import AVFoundation
#endif

/// Centralized audio session manager to prevent conflicts between different components
/// Coordinates audio session configuration across SpeechRecognizer, AudioRecordingManager, and other audio components
final class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()
    
    private let sessionQueue = DispatchQueue(label: "AudioSessionManager.queue", qos: .userInitiated)
    private let sessionQueueKey = DispatchSpecificKey<Void>()
    private var isConfiguring = false
    private var currentConfiguration: AudioConfiguration = .none
    
    private init() {
        sessionQueue.setSpecific(key: sessionQueueKey, value: ())
    }
    
    // MARK: - Audio Configuration Types
    
    enum AudioConfiguration: Equatable { // Added Equatable for comparison
        case none
        case speechRecognition
        case recording
        case playback
        case levelMonitoring
    }
    
    // MARK: - Public Configuration Methods
    
    /// Configures audio session for speech recognition with priority handling
    /// - Returns: True if configuration was successful
    func configureForSpeechRecognition() async -> Bool {
        return await configureSession(for: .speechRecognition)
    }

    /// Synchronous variant for speech recognition setup when async/await is not available (e.g., initializers)
    /// - Returns: True if the configuration succeeded before returning
    func configureForSpeechRecognitionSync() -> Bool {
        return configureSessionSync(for: .speechRecognition)
    }
    
    /// Configures audio session for recording with priority handling
    /// - Returns: True if configuration was successful
    func configureForRecording() async -> Bool {
        return await configureSession(for: .recording)
    }

    /// Synchronous variant for recording setup when async/await is not available (e.g., singletons inits)
    /// - Returns: True if the configuration succeeded before returning
    func configureForRecordingSync() -> Bool {
        return configureSessionSync(for: .recording)
    }
    
    /// Configures audio session for level monitoring with priority handling
    /// - Returns: True if configuration was successful
    func configureForLevelMonitoring() async -> Bool {
        return await configureSession(for: .levelMonitoring)
    }
    
    /// Synchronous variant for level monitoring setup in contexts where async cannot be used
    /// - Returns: True if configuration succeeded
    func configureForLevelMonitoringSync() -> Bool {
        return configureSessionSync(for: .levelMonitoring)
    }

    /// Configures audio session for playback with priority handling
    /// - Returns: True if configuration was successful
    func configureForPlayback() async -> Bool {
        return await configureSession(for: .playback)
    }

    /// Synchronous variant for playback setup in contexts where async cannot be used
    /// - Returns: True if configuration succeeded
    func configureForPlaybackSync() -> Bool {
        return configureSessionSync(for: .playback)
    }
    
    /// Resets audio session to default state
    func resetAudioSession() async {
        await withCheckedContinuation { continuation in
            sessionQueue.async {
                #if os(iOS)
                do {
                    let session = AVAudioSession.sharedInstance()
                    if session.category != .ambient { // Only deactivate if not already ambient
                        try session.setActive(false, options: .notifyOthersOnDeactivation)
                    }
                    self.currentConfiguration = .none
                    AppLog.info(.audioSession, "Reset audio session to default state")
                } catch {
                    AppLog.error(.audioSession, "Failed to reset audio session: \(error.localizedDescription)")
                }
                #endif
                continuation.resume()
            }
        }
    }
    
    /// Internal method to handle actual audio session configuration on a dedicated queue
    /// Ensures only one configuration attempt is active at a time
    private func configureSession(for configuration: AudioConfiguration) async -> Bool {
        return await withCheckedContinuation { continuation in
            sessionQueue.async {
                continuation.resume(returning: self.performConfiguration(for: configuration))
            }
        }
    }

    private func configureSessionSync(for configuration: AudioConfiguration) -> Bool {
        if DispatchQueue.getSpecific(key: sessionQueueKey) != nil {
            return performConfiguration(for: configuration)
        } else {
            return sessionQueue.sync {
                performConfiguration(for: configuration)
            }
        }
    }

    private func performConfiguration(for configuration: AudioConfiguration) -> Bool {
        #if os(iOS)
        // Prevent concurrent configuration attempts
        guard !isConfiguring else {
            AppLog.debug(.audioSession, "Configuration already in progress; skipping", dedupeInterval: 2)
            return false
        }
        
        isConfiguring = true
        defer { isConfiguring = false }
        
        do {
            let session = AVAudioSession.sharedInstance()
            
            // Only reconfigure if the configuration has changed
            guard currentConfiguration != configuration else {
                AppLog.debug(.audioSession, "Already configured for \(configuration)", dedupeInterval: 2)
                return true
            }
            
            // Deactivate the current session when switching to playback, or when we're not already in playAndRecord.
            // Some devices/OS versions refuse category changes while active, yielding `!pri` / OSStatus failures.
            let shouldDeactivate = (configuration == .playback) || (session.category != .playAndRecord)
            if shouldDeactivate {
                do {
                    try session.setActive(false, options: .notifyOthersOnDeactivation)
                    AppLog.info(.audioSession, "Deactivated current audio session for reconfiguration")
                } catch {
                    AppLog.notice(.audioSession, "Failed to deactivate audio session before reconfiguration: \(error.localizedDescription)")
                }
            } else {
                AppLog.debug(.audioSession, "Session already playAndRecord; skipping deactivation", dedupeInterval: 2)
            }
            
            // Configure based on the requested configuration
            switch configuration {
            case .speechRecognition:
                try configureForSpeechRecognition(session)
            case .recording:
                try configureForRecording(session)
            case .levelMonitoring:
                try configureForLevelMonitoring(session)
            case .playback:
                try configureForPlayback(session)
            case .none:
                break // No specific configuration for .none
            }
            
            // Activate the session
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            currentConfiguration = configuration
            AppLog.info(.audioSession, "Configured session for \(configuration)")
            return true
        } catch {
            AppLog.error(.audioSession, "Failed to configure session for \(configuration): \(error.localizedDescription)")
            currentConfiguration = .none // Reset on error
            return false
        }
        #else
        AppLog.debug(.audioSession, "Audio session configuration skipped on this platform")
        return true
        #endif
    }
    
    #if os(iOS)
    /// Configures audio session specifically for speech recognition
    private func configureForSpeechRecognition(_ session: AVAudioSession) throws {
        #if targetEnvironment(simulator)
        try session.setCategory(.playAndRecord, mode: .default, options: [])
        #else
        let options: AVAudioSession.CategoryOptions = [.allowBluetooth, .defaultToSpeaker]
        
        // Try measurement mode first for better speech recognition
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: options)
            AppLog.info(.audioSession, "Configured speech recognition (measurement mode)")
        } catch {
            AppLog.notice(.audioSession, "Measurement mode failed; falling back to default: \(error.localizedDescription)")
            // Fallback to default mode if measurement fails
            try session.setCategory(.playAndRecord, mode: .default, options: options)
            AppLog.info(.audioSession, "Configured speech recognition (default mode)")
        }
        #endif
    }
    
    /// Configures audio session specifically for recording
    private func configureForRecording(_ session: AVAudioSession) throws {
        #if targetEnvironment(simulator)
        try session.setCategory(.playAndRecord, mode: .default, options: [])
        #else
        let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker, .allowBluetooth]
        
        // Try measurement mode first for better quality
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: options)
            AppLog.info(.audioSession, "Configured recording (measurement mode)")
        } catch {
            AppLog.notice(.audioSession, "Measurement mode failed; falling back to default: \(error.localizedDescription)")
            try session.setCategory(.playAndRecord, mode: .default, options: options)
            AppLog.info(.audioSession, "Configured recording (default mode)")
        }
        #endif
    }
    
    /// Configures audio session for level monitoring
    private func configureForLevelMonitoring(_ session: AVAudioSession) throws {
        #if targetEnvironment(simulator)
        try session.setCategory(.playAndRecord, mode: .default, options: [])
        #else
        let options: AVAudioSession.CategoryOptions = [.allowBluetooth, .defaultToSpeaker]
        try session.setCategory(.playAndRecord, mode: .default, options: options)
        AppLog.info(.audioSession, "Configured level monitoring")
        #endif
    }
    
    /// Configures audio session for playback
    private func configureForPlayback(_ session: AVAudioSession) throws {
        try session.setCategory(.playback, mode: .default, options: [])
        AppLog.info(.audioSession, "Configured playback")
    }
    #endif
} 
