//
//  SpeechRecognizer.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/25/24.
//

import Foundation
import AVFoundation
import Speech
import AudioToolbox


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
    
    func convertMP3ToM4A(mp3URL: URL, completion: @escaping (URL?) -> Void) {
        let outputURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
        
        var inputFile: ExtAudioFileRef? = nil
        var outputFile: ExtAudioFileRef? = nil
        
        var inputDesc = AudioStreamBasicDescription()
        var outputDesc = AudioStreamBasicDescription()
        
        // Open the input file
        var status: OSStatus = ExtAudioFileOpenURL(mp3URL as CFURL, &inputFile)
        if status != noErr {
            print("Error opening input file: \(status)")
            completion(nil)
            return
        }
        
        // Get the input file's format
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        status = ExtAudioFileGetProperty(inputFile!, kExtAudioFileProperty_FileDataFormat, &size, &inputDesc)
        if status != noErr {
            print("Error getting input file format: \(status)")
            ExtAudioFileDispose(inputFile!)
            completion(nil)
            return
        }
        
        // Set the output file's format
        outputDesc.mSampleRate = 44100
        outputDesc.mFormatID = kAudioFormatMPEG4AAC
        outputDesc.mChannelsPerFrame = 2
        outputDesc.mFramesPerPacket = 1024
        outputDesc.mBytesPerPacket = 0
        outputDesc.mBytesPerFrame = 0
        outputDesc.mBitsPerChannel = 0
        outputDesc.mReserved = 0
        
        // Create the output file
        status = ExtAudioFileCreateWithURL(outputURL as CFURL, kAudioFileM4AType, &outputDesc, nil, AudioFileFlags.eraseFile.rawValue, &outputFile)
        if status != noErr {
            print("Error creating output file: (status)")
            ExtAudioFileDispose(inputFile!)
            completion(nil)
            return
        }
        
        // Set the output file's client format to PCM
        var clientFormat = AudioStreamBasicDescription()
        clientFormat.mSampleRate = 44100
        clientFormat.mFormatID = kAudioFormatLinearPCM
        clientFormat.mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger
        clientFormat.mFramesPerPacket = 1
        clientFormat.mChannelsPerFrame = 2
        clientFormat.mBitsPerChannel = 16
        clientFormat.mBytesPerFrame = clientFormat.mBitsPerChannel / 8 * clientFormat.mChannelsPerFrame
        clientFormat.mBytesPerPacket = clientFormat.mBytesPerFrame * clientFormat.mFramesPerPacket
        clientFormat.mReserved = 0
        
        // Set the client format for input and output files
        status = ExtAudioFileSetProperty(inputFile!, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat)
        if status != noErr {
            print("Error setting input file client format: \(status)")
            ExtAudioFileDispose(inputFile!)
            ExtAudioFileDispose(outputFile!)
            completion(nil)
            return
        }
        
        status = ExtAudioFileSetProperty(outputFile!, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat)
        if status != noErr {
            print("Error setting output file client format: \(status)")
            ExtAudioFileDispose(inputFile!)
            ExtAudioFileDispose(outputFile!)
            completion(nil)
            return
        }
        
        // Create a buffer and read the data
        let bufferByteSize: UInt32 = 32768
        var buffer = [UInt8](repeating: 0, count: Int(bufferByteSize))
        var convertedData = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(
                mNumberChannels: clientFormat.mChannelsPerFrame,
                mDataByteSize: bufferByteSize,
                mData: &buffer
            )
        )
        
        var totalFrames: UInt64 = 0
        var completedFrames: UInt64 = 0
        
        while true {
            var frameCount: UInt32 = bufferByteSize / clientFormat.mBytesPerFrame
            status = ExtAudioFileRead(inputFile!, &frameCount, &convertedData)
            if status != noErr || frameCount == 0 {
                break
            }
            status = ExtAudioFileWrite(outputFile!, frameCount, &convertedData)
            if status != noErr {
                print("Error writing to output file: \(status)")
                ExtAudioFileDispose(inputFile!)
                ExtAudioFileDispose(outputFile!)
                completion(nil)
                return
            }
            completedFrames += UInt64(frameCount)
            totalFrames = UInt64(inputDesc.mSampleRate) * UInt64(inputDesc.mFramesPerPacket)
            if totalFrames > 0 {
                let progress = Double(completedFrames) / Double(totalFrames)
                if Int(progress * 100) % 10 == 0 {
                    print("Conversion progress: \(Int(progress * 100))%")
                }
            }
        }
        
        ExtAudioFileDispose(inputFile!)
        ExtAudioFileDispose(outputFile!)
        
        if status == noErr {
            print("Successfully converted MP3 to M4A: \(outputURL)")
            completion(outputURL)
        } else {
            print("Error during conversion: \(status)")
            completion(nil)
        }
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
    
    private func transcribeLocalAudioFile(from url: URL) {
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
