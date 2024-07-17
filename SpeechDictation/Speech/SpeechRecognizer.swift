//
//  SpeechRecognizer.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/25/24.
//

import Foundation
import Speech

class SpeechRecognizer: ObservableObject {
    @Published var transcribedText: String = "Tap a button to begin"
    @Published private(set) var audioSamples: [Float] = []
    @Published var volume: Float = 10.0 {
        didSet {
            adjustVolume()
        }
    }
    
    var audioEngine: AVAudioEngine?
    var speechRecognizer: SFSpeechRecognizer?
    var request: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    var audioPlayer: AVAudioPlayer?
    private let audioSamplesQueue: DispatchQueue = DispatchQueue(label: "audioSamplesQueue", qos: .userInitiated)
    private let volumeQueue: DispatchQueue = DispatchQueue(label: "volumeQueue", qos: .userInitiated)
    var displayLink: CADisplayLink?
    var playerNode: AVAudioPlayerNode?
    var mixerNode: AVAudioMixerNode?
    
    init() {
        requestAuthorization()
        configureAudioSession()
    }
    
    func startTranscribing() {
        audioEngine = AVAudioEngine()
        
        speechRecognizer = SFSpeechRecognizer()
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let request = request else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        
        guard let inputNode = audioEngine?.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        request.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }
            
            if let error = error {
                print("Recognition error: \(error)")
                self.stopTranscribing()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, time in
            self.processAudioBuffer(buffer: buffer)
            self.request?.append(buffer)
        }
        
        audioEngine?.prepare()
        
        do {
            try audioEngine?.start()
        } catch {
            print("Audio engine failed to start: \(error)")
        }
        
        adjustVolume()
    }
    
    func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        let frameLength = Int(buffer.frameLength)
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        audioSamplesQueue.async {
            var newSamples = self.audioSamples
            newSamples.append(contentsOf: samples)
            if newSamples.count > 1000 {
                newSamples.removeFirst(newSamples.count - 1000)
            }
            DispatchQueue.main.async {
                self.audioSamples = newSamples
            }
        }
    }
    
    func adjustVolume() {
        volumeQueue.async {
            if let inputNode: AVAudioInputNode = self.audioEngine?.inputNode {
                inputNode.volume = self.volume / 100.0
            }
        }
    }
    
    func stopTranscribing() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        request?.endAudio()
        recognitionTask?.cancel()
        
        request = nil
        recognitionTask = nil
        audioEngine = nil
    }
    
    
    func transcribeAudioFile(from url: URL) {
        let cacheKey = url.lastPathComponent
        if let cachedData = CacheManager.shared.retrieveData(forKey: cacheKey) {
            let cachedURL = CacheManager.shared.save(data: cachedData, forKey: cacheKey)
            self.playAndTranscribeAudioFile(from: cachedURL!)
            return
        }
        
        DownloadManager.shared.downloadAudioFile(from: url) { localURL in
            guard let localURL = localURL else {
                DispatchQueue.main.async {
                    self.transcribedText = "Failed to download audio file"
                }
                return
            }
            CacheManager.shared.save(data: try! Data(contentsOf: localURL), forKey: cacheKey)
            print("Starting conversion from MP3 to M4A")
            self.convertMP3ToM4A(mp3URL: localURL) { m4aURL in
                guard let m4aURL = m4aURL else {
                    DispatchQueue.main.async {
                        self.transcribedText = "Failed to convert audio file to M4A"
                    }
                    return
                }
                let m4aCacheKey = m4aURL.lastPathComponent
                CacheManager.shared.save(data: try! Data(contentsOf: m4aURL), forKey: m4aCacheKey)
                print("Starting transcription of M4A file")
                self.playAndTranscribeAudioFile(from: m4aURL)
            }
        }
    }
    
    func playAndTranscribeAudioFile(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            setupTapForAudioPlayer()
        } catch {
            print("Error initializing AVAudioPlayer: \(error)")
            return
        }
        
        let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
        let request: SFSpeechURLRecognitionRequest = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                    print("Transcription result: \(result.bestTranscription.formattedString)")
                }
            }
            
            if let error = error {
                print("Recognition error: \(error)")
                DispatchQueue.main.async {
                    self.transcribedText = "Recognition error: \(error.localizedDescription)"
                }
            }
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
