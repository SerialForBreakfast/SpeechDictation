import Foundation
import Speech
import AVFoundation

class SpeechRecognizer: ObservableObject {
    @Published var transcribedText: String = ""
    @Published private(set) var audioSamples: [Float] = []
    /// Live peak audio level (0.0 – 1.0) updated for each incoming buffer. Used for VU meter.
    @Published private(set) var currentLevel: Float = 0.0
    @Published var volume: Float = 80.0 {
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
        startLevelMonitoring()
    }
    
    func startTranscribing() {
        print("Starting transcription...")
        // If a monitoring engine is already running, stop and reset it before starting a
        // fresh engine configured for speech recognition.
        if let engine = audioEngine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }

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
        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
        }
        // SECURITY: Enforce on-device recognition for privacy and security
        // This ensures all speech processing happens locally on the device
        request.requiresOnDeviceRecognition = true
        
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
        
        // Use the native format from the input node for better compatibility
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("Using native input format for transcription: \(recordingFormat)")
        
        #if targetEnvironment(simulator)
        if recordingFormat.sampleRate <= 0 || recordingFormat.channelCount <= 0 {
            print("[Simulator] Invalid input format for transcription: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount). Skipping audio tap.")
            return
        }
        #endif
        
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
            #if targetEnvironment(simulator)
            print("Audio engine failure in simulator is expected - continuing for testing")
            #endif
        }
        
        adjustVolume()
    }
    
    /// Processes a PCM buffer to store samples for waveform visualisation **and** update `currentLevel`.
    /// - Parameter buffer: Incoming audio buffer from the input node.
    ///
    /// Concurrency: Called on the audio engine's render thread. We avoid heavy work; calculating the
    /// *peak* amplitude is O(n) but cheap. We dispatch UI updates back to the main queue.
    func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        let frameLength = Int(buffer.frameLength)
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))

        // ---------------------------------------------------------------
        // CALCULATE NORMALISED INPUT LEVEL FOR VU-METER
        // ---------------------------------------------------------------
        // Use **root-mean-square** (RMS) → dBFS mapping which is similar to
        // how human ears perceive loudness.  Then convert a –60 dB … 0 dB
        // window into the 0…1 range expected by `VUMeterView`.
        let rms: Float = {
            let meanSquare = samples.reduce(into: Float(0)) { $0 += $1 * $1 } / Float(samples.count)
            return sqrtf(meanSquare)
        }()

        // Guard against log(0)
        let rmsDB = rms == 0 ? -100 : 20.0 * log10f(rms)
        let normalisedLevel = max(0, min(1, (rmsDB + 60) / 60)) // –60 dB → 0, 0 dB → 1

        DispatchQueue.main.async {
            self.currentLevel = normalisedLevel
        }

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
    
    /// Adjusts microphone sensitivity.
    ///
    /// The method first tries to set hardware input-gain via `AVAudioSession.setInputGain(_:)` (only
    /// available on devices that expose a software-controllable pre-amp).
    /// If the hardware gain is *not* settable it falls back to a software gain by scaling the
    /// `AVAudioInputNode.volume` (0.0 – 1.0).
    ///
    /// Concurrency: Runs on a dedicated `volumeQueue` to avoid blocking the main/UI thread while the
    /// audio engine is active. All AVAudioSession calls are *non-blocking* but may throw, so they are
    /// wrapped in a `do/try` inside the async block.
    internal func adjustVolume() {
        let gain = max(0, min(volume / 100.0, 1.0)) // Normalise 0 → 1

        volumeQueue.async {
            #if canImport(AVFoundation) && !os(macOS)
            let session = AVAudioSession.sharedInstance()

            // 1 Try hardware input-gain if the device supports it.
            if session.isInputGainSettable {
                do {
                    try session.setInputGain(gain)
                    print("Hardware mic gain set to \(gain)")
                    return
                } catch {
                    print("Failed to set hardware mic gain: \(error). Falling back to software gain.")
                }
            }
            #endif

            // 2 Software gain fallback via inputNode.volume
            if let inputNode = self.audioEngine?.inputNode {
                inputNode.volume = gain
                print("Software mic gain set to \(gain)")
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
    
    // MARK: - Input-level monitoring (always-on)

    /// Starts an `AVAudioEngine` solely for measuring input levels so the VU meter
    /// is responsive even when speech recognition is **not** running.
    ///
    /// If the engine is already active (e.g. due to transcription) this method is
    /// a no-op.
    func startLevelMonitoring() {
        guard audioEngine == nil else { return }

        audioEngine = AVAudioEngine()

        guard let inputNode = audioEngine?.inputNode else {
            print("Audio engine has no input node (level monitoring)")
            return
        }

        // Use the native format from the input node for better compatibility
        let format = inputNode.outputFormat(forBus: 0)
        print("Using native input format for level monitoring: \(format)")
        
        #if targetEnvironment(simulator)
        if format.sampleRate <= 0 || format.channelCount <= 0 {
            print("[Simulator] Invalid input format for level monitoring: sampleRate=\(format.sampleRate), channels=\(format.channelCount). Skipping audio tap.")
            return
        }
        #endif
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.processAudioBuffer(buffer: buffer)
        }

        audioEngine?.prepare()

        do {
            try audioEngine?.start()
            print("Audio engine started (level monitoring)")
        } catch {
            print("Audio engine failed to start (level monitoring): \(error)")
            #if targetEnvironment(simulator)
            print("Audio engine failure in simulator is expected for level monitoring")
            #endif
        }

        adjustVolume()
    }
}