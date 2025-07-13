//
//  SpeechRecognizer+config.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/29/24.
//

import Foundation
import AVFoundation

extension SpeechRecognizer {
    /// Configures the audio session for speech recognition with iPad-specific optimizations
    /// Coordinates with other audio components to prevent session conflicts
    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Check if session is already active before trying to deactivate
            if audioSession.isOtherAudioPlaying {
                print("Other audio is playing, will configure without deactivation")
            } else {
                // Only deactivate if not already inactive
                if audioSession.category != .playAndRecord {
                    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                }
            }
            
            #if targetEnvironment(simulator)
            // Use simpler configuration for simulator
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            #else
            // Device-specific configuration with iPad optimizations
            let options: AVAudioSession.CategoryOptions = [.allowBluetooth, .defaultToSpeaker]
            
            // Try measurement mode first for better speech recognition
            do {
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: options)
                print("Audio session configured for speech recognition with measurement mode")
            } catch {
                print("Measurement mode failed, trying default mode: \(error)")
                // Fallback to default mode if measurement fails
                try audioSession.setCategory(.playAndRecord, mode: .default, options: options)
                print("Audio session configured for speech recognition with default mode")
            }
            #endif
            
            // Activate session with proper options
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session configured for speech recognition")
            
        } catch {
            print("Error setting up audio session for speech recognition: \(error)")
            // Final fallback with minimal configuration
            do {
                // Don't try to deactivate again if it failed before
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                print("Audio session configured with minimal settings")
            } catch {
                print("Critical error: Unable to configure audio session for speech recognition: \(error)")
            }
        }
    }
    
    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAudioSamples))
        displayLink?.preferredFramesPerSecond = 30
        displayLink?.add(to: .current, forMode: .default)
    }
    
    func setupTapForAudioPlayer() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        mixerNode = AVAudioMixerNode()
        
        guard let audioPlayer = audioPlayer,
              let audioEngine = audioEngine,
              let playerNode = playerNode,
              let mixerNode = mixerNode else { return }
        
        audioEngine.attach(playerNode)
        audioEngine.attach(mixerNode)
        audioEngine.connect(playerNode, to: mixerNode, format: nil)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: nil)
        
        let format = mixerNode.outputFormat(forBus: 0)
        
        // Validate the format is supported before installing tap
        guard format.sampleRate > 0 && format.channelCount > 0 else {
            print("Invalid mixer format detected: sampleRate=\(format.sampleRate), channels=\(format.channelCount)")
            print("Skipping audio tap installation due to invalid format")
            return
        }
        
        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
            self.processAudioBuffer(buffer: buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            playerNode.scheduleFile(try AVAudioFile(forReading: audioPlayer.url!), at: nil, completionHandler: nil)
            playerNode.play()
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
    
    @objc func updateAudioSamples() {
        guard let player = audioPlayer else { return }
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: player.format.sampleRate, channels: 1, interleaved: false) else { return }
        let frameCount = AVAudioFrameCount(player.format.sampleRate / 30) // Assuming 30 fps
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        // Simulate reading samples from the audio player's output
        processAudioBuffer(buffer: buffer)
    }
}
