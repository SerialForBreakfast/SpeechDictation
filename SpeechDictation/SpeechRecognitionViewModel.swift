//
//  SpeechRecognitionViewModel.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 7/17/24.
//

import Foundation
import Combine
import SwiftUI

class SpeechRecognizerViewModel: ObservableObject {
    @Published var transcribedText: String = "Tap a button to begin"
    @Published var fontSize: CGFloat = 24
    @Published var theme: Theme = .light
    @Published var isRecording: Bool = false
    @Published var volume: Float = 10.0
    @Published var showSettings: Bool = false

    private var speechRecognizer: SpeechRecognizer
    private var cancellables = Set<AnyCancellable>()

    init(speechRecognizer: SpeechRecognizer = SpeechRecognizer()) {
        self.speechRecognizer = speechRecognizer

        self.speechRecognizer.$transcribedText
            .assign(to: \.transcribedText, on: self)
            .store(in: &cancellables)

        self.speechRecognizer.$volume
            .assign(to: \.volume, on: self)
            .store(in: &cancellables)
    }

    func startTranscribing() {
        speechRecognizer.startTranscribing()
        isRecording = true
    }

    func stopTranscribing() {
        speechRecognizer.stopTranscribing()
        isRecording = false
    }

    func adjustVolume() {
        speechRecognizer.volume = volume
    }
}
