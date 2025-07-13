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
    private var isConfiguring = false
    private var currentConfiguration: AudioConfiguration = .none
    
    private init() {}
    
    // MARK: - Audio Configuration Types
    
    enum AudioConfiguration {
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
    
    /// Configures audio session for recording with priority handling
    /// - Returns: True if configuration was successful
    func configureForRecording() async -> Bool {
        return await configureSession(for: .recording)
    }
    
    /// Configures audio session for level monitoring with priority handling
    /// - Returns: True if configuration was successful
    func configureForLevelMonitoring() async -> Bool {
        return await configureSession(for: .levelMonitoring)
    }
    
    /// Resets audio session to default state
    func resetSession() async {
        await sessionQueue.async {
            #if os(iOS)
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setActive(false, options: .notifyOthersOnDeactivation)
                self.currentConfiguration = .none
                print("🔇 Audio session reset")
            } catch {
                print("⚠️ Error resetting audio session: \(error)")
            }
            #else
            print("🔇 Audio session reset (macOS - no-op)")
            #endif
        }
    }
    
    // MARK: - Private Configuration Logic
    
    /// Centralized audio session configuration with conflict resolution
    /// - Parameter configuration: The desired audio configuration
    /// - Returns: True if configuration was successful
    private func configureSession(for configuration: AudioConfiguration) async -> Bool {
        return await sessionQueue.async {
            #if os(iOS)
            // Prevent concurrent configuration attempts
            guard !self.isConfiguring else {
                print("⚠️ Audio session configuration already in progress, skipping")
                return false
            }
            
            self.isConfiguring = true
            defer { self.isConfiguring = false }
            
            do {
                let session = AVAudioSession.sharedInstance()
                
                // Only reconfigure if the configuration has changed
                guard self.currentConfiguration != configuration else {
                    print("ℹ️ Audio session already configured for \(configuration)")
                    return true
                }
                
                // Deactivate current session if needed
                if session.category != .playAndRecord {
                    try session.setActive(false, options: .notifyOthersOnDeactivation)
                }
                
                // Configure based on the requested configuration
                switch configuration {
                case .speechRecognition:
                    try self.configureForSpeechRecognition(session)
                case .recording:
                    try self.configureForRecording(session)
                case .levelMonitoring:
                    try self.configureForLevelMonitoring(session)
                case .playback:
                    try self.configureForPlayback(session)
                case .none:
                    break
                }
                
                // Activate the session
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                
                self.currentConfiguration = configuration
                print("✅ Audio session configured for \(configuration)")
                return true
                
            } catch {
                print("❌ Audio session configuration failed for \(configuration): \(error)")
                
                // Try fallback configuration
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playAndRecord, mode: .default, options: [])
                    try session.setActive(true, options: .notifyOthersOnDeactivation)
                    self.currentConfiguration = configuration
                    print("✅ Audio session configured with fallback settings")
                    return true
                } catch {
                    print("❌ Audio session fallback configuration also failed: \(error)")
                    return false
                }
            }
            #else
            // macOS fallback
            print("ℹ️ Audio session configuration not available on macOS")
            return true
            #endif
        }
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
            print("🎤 Audio session configured for speech recognition with measurement mode")
        } catch {
            print("⚠️ Measurement mode failed, trying default mode: \(error)")
            try session.setCategory(.playAndRecord, mode: .default, options: options)
            print("🎤 Audio session configured for speech recognition with default mode")
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
            print("🎙️ Audio session configured for recording with measurement mode")
        } catch {
            print("⚠️ Measurement mode failed, trying default mode: \(error)")
            try session.setCategory(.playAndRecord, mode: .default, options: options)
            print("🎙️ Audio session configured for recording with default mode")
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
        print("📊 Audio session configured for level monitoring")
        #endif
    }
    
    /// Configures audio session for playback
    private func configureForPlayback(_ session: AVAudioSession) throws {
        try session.setCategory(.playback, mode: .default, options: [])
        print("🔊 Audio session configured for playback")
    }
    #endif
} 