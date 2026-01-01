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
        // Concurrency: SpeechRecognizer.init is synchronous, so we must block until the session
        // finishes configuring to avoid race conditions before transcription starts.
        let success = AudioSessionManager.shared.configureForSpeechRecognitionSync()
        guard success else {
            AppLog.notice(.audioSession, "Audio session configuration for speech recognition failed via manager")
            // Final fallback with minimal configuration
            do {
                let audioSession = AVAudioSession.sharedInstance()
                // Don't try to deactivate again if it failed before
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                AppLog.info(.audioSession, "Audio session configured with minimal settings")
            } catch {
                AppLog.fault(.audioSession, "Unable to configure audio session for speech recognition: \(error.localizedDescription)")
            }
            return
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
            AppLog.error(
                .recording,
                "Invalid mixer format: sampleRate=\(format.sampleRate), channels=\(format.channelCount)"
            )
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
            AppLog.error(.recording, "Audio engine failed to start: \(error.localizedDescription)")
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
