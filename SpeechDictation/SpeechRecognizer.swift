//
//  SpeechRecognizer.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/25/24.
//

import Foundation
import AVFoundation
import Speech

class SpeechRecognizer: ObservableObject {
    @Published var transcribedText: String = "Listening..."
    @Published private(set) var audioSamples: [Float] = []
    @Published var volume: Float = 10.0 { // Start at 10
        didSet {
            adjustVolume()
        }
    }

    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioSamplesQueue: DispatchQueue = DispatchQueue(label: "audioSamplesQueue", qos: .userInitiated)
    private let volumeQueue: DispatchQueue = DispatchQueue(label: "volumeQueue", qos: .userInitiated)

    init() {
        requestAuthorization()
    }

    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    self.transcribedText = "Speech recognition authorization denied"
                case .restricted:
                    self.transcribedText = "Speech recognition restricted on this device"
                case .notDetermined:
                    self.transcribedText = "Speech recognition not authorized"
                @unknown default:
                    fatalError("Unknown authorization status")
                }
            }
        }

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Microphone access granted")
                } else {
                    self.transcribedText = "Microphone access denied"
                }
            }
        }
    }

    func startTranscribing() {
        audioEngine = AVAudioEngine()

        speechRecognizer = SFSpeechRecognizer()
        request = SFSpeechAudioBufferRecognitionRequest()

        guard let request = request else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }

        guard let inputNode: AVAudioInputNode = audioEngine?.inputNode else {
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

        let recordingFormat: AVAudioFormat = inputNode.outputFormat(forBus: 0)
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

        adjustVolume() // Apply initial volume
    }

    private func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        let frameLength: Int = Int(buffer.frameLength)
        guard let channelData: UnsafeMutablePointer<Float> = buffer.floatChannelData?[0] else { return }

        let samples: [Float] = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        audioSamplesQueue.async {
            var newSamples: [Float] = self.audioSamples
            newSamples.append(contentsOf: samples)
            if newSamples.count > 1000 {
                newSamples.removeFirst(newSamples.count - 1000)
            }
            DispatchQueue.main.async {
                self.audioSamples = newSamples
            }
        }
    }

    private func adjustVolume() {
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
}
