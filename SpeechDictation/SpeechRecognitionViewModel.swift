//
//  SpeechRecognitionViewModel.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 7/17/24.
//

import Foundation
import Combine
import SwiftUI

private enum SettingsKey {
    static let fontSize = "fontSize"
    static let theme = "theme"
    static let volume = "volume"
}

class SpeechRecognizerViewModel: ObservableObject {
    @Published var transcribedText: String = "Tap a button to begin"
    @Published var fontSize: CGFloat = 24
    @Published var theme: Theme = .light
    @Published var isRecording: Bool = false
    @Published var volume: Float = 10.0
    @Published var currentLevel: Float = 0.0
    @Published var showSettings: Bool = false

    private var speechRecognizer: SpeechRecognizer
    private var cancellables = Set<AnyCancellable>()
    private var persistenceCancellables = Set<AnyCancellable>()

    init(speechRecognizer: SpeechRecognizer = SpeechRecognizer()) {
        self.speechRecognizer = speechRecognizer

        // 1️⃣ --- LOAD PERSISTED VALUES ---
        let defaults = UserDefaults.standard
        if let storedFont = defaults.object(forKey: SettingsKey.fontSize) as? Double {
            self.fontSize = CGFloat(storedFont)
        }
        if let storedTheme = defaults.string(forKey: SettingsKey.theme),
           let themeEnum = Theme(rawValue: storedTheme) {
            self.theme = themeEnum
        }
        if defaults.object(forKey: SettingsKey.volume) != nil {
            self.volume = defaults.float(forKey: SettingsKey.volume)
        }

        // 2️⃣ --- LINK SPEECH RECOGNIZER PUBLISHERS ---
        self.speechRecognizer.$transcribedText
            .assign(to: \.transcribedText, on: self)
            .store(in: &cancellables)

        self.speechRecognizer.$volume
            .assign(to: \.volume, on: self)
            .store(in: &cancellables)

        self.speechRecognizer.$currentLevel
            .assign(to: \.currentLevel, on: self)
            .store(in: &cancellables)

        // 3️⃣ --- PERSIST SETTINGS WHEN THEY CHANGE ---
        $fontSize
            .dropFirst() // skip the initial value load
            .sink { value in
                UserDefaults.standard.set(Double(value), forKey: SettingsKey.fontSize)
            }
            .store(in: &persistenceCancellables)

        $theme
            .dropFirst()
            .sink { value in
                UserDefaults.standard.set(value.rawValue, forKey: SettingsKey.theme)
            }
            .store(in: &persistenceCancellables)

        $volume
            .dropFirst()
            .sink { value in
                UserDefaults.standard.set(value, forKey: SettingsKey.volume)
            }
            .store(in: &persistenceCancellables)
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
