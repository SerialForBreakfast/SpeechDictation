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
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            print("Audio session configured")
        } catch {
            print("Failed to configure audio session: \(error)")
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
}
