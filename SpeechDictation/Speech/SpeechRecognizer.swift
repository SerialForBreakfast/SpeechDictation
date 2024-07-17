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
        print("Starting transcription...")
        audioEngine = AVAudioEngine()
        
        speechRecognizer = SFSpeechRecognizer()
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let request = request else {
            print("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
            return
        }
        
        guard let inputNode = audioEngine?.inputNode else {
            print("Audio engine has no input node")
            return
        }
        
        request.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                    print("Transcription result: \(result.bestTranscription.formattedString)")
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
            print("Audio engine started")
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
                print("Volume adjusted to \(self.volume)")
            }
        }
    }
    
    func stopTranscribing() {
        print("Stopping transcription...")
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        request?.endAudio()
        recognitionTask?.cancel()
        
        request = nil
        recognitionTask = nil
        audioEngine = nil
    }
    
    // Other methods remain unchanged
}
