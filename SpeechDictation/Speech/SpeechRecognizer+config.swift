//
//  SpeechRecognizer+config.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/29/24.
//

import Foundation
import AVFoundation

extension SpeechRecognizer {
    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            #if targetEnvironment(simulator)
            // Use simpler configuration for simulator
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            #else
            // Use `.measurement` mode which turns off system-level voice processing (AGC, NR) and gives
            // us the raw mic signal – better for speech recognizer + manual gain control.
            try audioSession.setCategory(.playAndRecord,
                                         mode: .measurement,
                                         options: [.allowBluetoothA2DP,
                                                   .allowBluetooth,
                                                   .defaultToSpeaker])
            #endif
            try audioSession.setActive(true)
            print("Audio session configured")
        } catch {
            print("Failed to configure audio session: \(error)")
            // Try a simpler configuration as fallback
            do {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
                try audioSession.setActive(true)
                print("Audio session configured with fallback settings")
            } catch {
                print("Failed to configure audio session even with fallback: \(error)")
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
