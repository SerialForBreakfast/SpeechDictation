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
    static let audioQuality = "audioQuality"
}

/// Root view model for live transcription and secure recording workflows.
/// Annotated with @MainActor because its published properties drive SwiftUI views
/// and it coordinates MainActor services such as `SecureRecordingManager`.
@MainActor
class SpeechRecognizerViewModel: ObservableObject {
    @Published var transcribedText: String = ""
    @Published var fontSize: CGFloat = 24
    @Published var theme: Theme = .light
    @Published var isRecording: Bool = false
    @Published var isSecureRecordingActive: Bool = false
    @Published var volume: Float = 60.0
    @Published var currentLevel: Float = 0.0
    @Published var showSettings: Bool = false
    
    var effectiveLevel: Float {
        let gain = max(0, min(volume / 100.0, 1.0))
        return normalizedLevelWithGain(rawLevel: currentLevel, gain: gain)
    }
    
    // Timing data properties
    @Published var currentSession: AudioRecordingSession?
    @Published var segments: [TranscriptionSegment] = []
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentAudioFileURL: URL?
    
    // Audio quality settings
    @Published var audioQuality: AudioQualitySettings = .standardQuality
    
    // Playback properties
    @Published var playbackState: PlaybackState = .stopped
    @Published var currentPlaybackTime: TimeInterval = 0
    @Published var currentSegment: TranscriptionSegment?

    private var speechRecognizer: SpeechRecognizer
    private var audioRecordingManager: AudioRecordingManager
    private var timingDataManager: TimingDataManager
    private var audioPlaybackManager: AudioPlaybackManager
    private var secureRecordingManager: SecureRecordingManager
    private var cancellables = Set<AnyCancellable>()
    private var persistenceCancellables = Set<AnyCancellable>()

    init(
        speechRecognizer: SpeechRecognizer = SpeechRecognizer(),
        secureRecordingManager: SecureRecordingManager = SecureRecordingManager.shared
    ) {
        self.speechRecognizer = speechRecognizer
        self.audioRecordingManager = AudioRecordingManager.shared
        self.timingDataManager = TimingDataManager.shared
        self.audioPlaybackManager = AudioPlaybackManager.shared
        self.secureRecordingManager = secureRecordingManager

        // 1 --- LOAD PERSISTED VALUES ---
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
        
        // Load audio quality setting
        if let qualityData = defaults.data(forKey: SettingsKey.audioQuality),
           let quality = try? JSONDecoder().decode(AudioQualitySettings.self, from: qualityData) {
            self.audioQuality = quality
        }

        // 2 --- LINK SPEECH RECOGNIZER PUBLISHERS ---
        self.speechRecognizer.$transcribedText
            .assign(to: \.transcribedText, on: self)
            .store(in: &cancellables)

        self.speechRecognizer.$volume
            .assign(to: \.volume, on: self)
            .store(in: &cancellables)

        self.speechRecognizer.$currentLevel
            .assign(to: \.currentLevel, on: self)
            .store(in: &cancellables)
        
        // Link timing data managers
        self.timingDataManager.$currentSession
            .assign(to: \.currentSession, on: self)
            .store(in: &cancellables)
        
        self.timingDataManager.$segments
            .assign(to: \.segments, on: self)
            .store(in: &cancellables)
        
        // Link audio recording manager
        self.audioRecordingManager.$recordingDuration
            .assign(to: \.recordingDuration, on: self)
            .store(in: &cancellables)
        
        self.audioRecordingManager.$currentAudioFileURL
            .assign(to: \.currentAudioFileURL, on: self)
            .store(in: &cancellables)
        
        // Link audio playback manager
        self.audioPlaybackManager.$playbackState
            .assign(to: \.playbackState, on: self)
            .store(in: &cancellables)
        
        self.audioPlaybackManager.$currentTime
            .assign(to: \.currentPlaybackTime, on: self)
            .store(in: &cancellables)
        
        self.audioPlaybackManager.$currentSegment
            .assign(to: \.currentSegment, on: self)
            .store(in: &cancellables)
        
        // Mirror secure recording state and transcript output
        self.secureRecordingManager.$isRecording
            .receive(on: RunLoop.main)
            .sink { [weak self] isRecording in
                self?.isSecureRecordingActive = isRecording
            }
            .store(in: &cancellables)
        
        self.secureRecordingManager.$liveTranscript
            .receive(on: RunLoop.main)
            .sink { [weak self] secureText in
                guard let self = self else { return }
                guard self.secureRecordingManager.isRecording else { return }
                self.transcribedText = secureText
            }
            .store(in: &cancellables)

        // 3 --- PERSIST SETTINGS WHEN THEY CHANGE ---
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
        
        $audioQuality
            .dropFirst()
            .sink { value in
                if let data = try? JSONEncoder().encode(value) {
                    UserDefaults.standard.set(data, forKey: SettingsKey.audioQuality)
                }
            }
            .store(in: &persistenceCancellables)
    }

    // MARK: - Recording Control
    
    func startTranscribing() {
        // Start audio recording first
        let audioURL = audioRecordingManager.startRecording(quality: audioQuality)
        
        // Start transcription with timing data
        speechRecognizer.startTranscribingWithTiming()
        isRecording = true
        
        print("Started transcription with timing data and audio recording")
    }

    func stopTranscribing() {
        // Stop audio recording
        let audioURL = audioRecordingManager.stopRecording()
        
        // Stop transcription with timing data
        speechRecognizer.stopTranscribingWithTiming(audioFileURL: audioURL)
        isRecording = false
        
        print("Stopped transcription with timing data and audio recording")
    }
    
    func pauseTranscribing() {
        audioRecordingManager.pauseRecording()
        speechRecognizer.stopTranscribing()
        isRecording = false
    }
    
    func resumeTranscribing() {
        audioRecordingManager.resumeRecording()
        speechRecognizer.startTranscribingWithTiming()
        isRecording = true
    }

    /// Ensures the input-level monitor is active so UI meters can update while idle.
    ///
    /// Concurrency: Safe to call on the main actor; the underlying audio engine work is internal.
    func ensureLevelMonitoringActive() {
        speechRecognizer.startLevelMonitoring()
    }
    
    private func normalizedLevelWithGain(rawLevel: Float, gain: Float) -> Float {
        guard rawLevel > 0, gain > 0 else { return 0 }
        let rawDb = Double(rawLevel) * 60.0 - 60.0
        let adjustedDb = rawDb + 20.0 * log10(Double(gain))
        let normalized = (adjustedDb + 60.0) / 60.0
        return Float(max(0.0, min(1.0, normalized)))
    }

    /// Toggles secure recording workflow that captures audio + transcription with protection.
    func toggleSecureRecording() {
        Task { @MainActor in
            if isSecureRecordingActive {
                await stopSecureRecordingWorkflow()
            } else {
                await startSecureRecordingWorkflow()
            }
        }
    }

    private func startSecureRecordingWorkflow() async {
        guard !isRecording else {
            print("Cannot start secure recording while live transcription is active")
            return
        }

        let result = await secureRecordingManager.startSecureRecording(
            title: "",
            hasConsent: true
        )
        
        guard result != nil else {
            print("Secure recording failed to start")
            return
        }

        transcribedText = ""
        segments.removeAll()
        currentSession = nil
        recordingDuration = 0
        print("Started secure recording workflow")
    }

    private func stopSecureRecordingWorkflow() async {
        _ = await secureRecordingManager.stopSecureRecording()
        print("Stopped secure recording workflow")
    }

    func adjustVolume() {
        speechRecognizer.volume = volume
    }
    
    /// Resets the transcribed text to an empty string without stopping recording
    /// This allows users to clear the current text while maintaining the recording session
    func resetTranscribedText() {
        transcribedText = ""
        // Clear timing data for current session
        segments.removeAll()
        currentSession = nil
        recordingDuration = 0
        currentAudioFileURL = nil
    }
    
    // MARK: - Timing Data Management
    
    func getCurrentSession() -> AudioRecordingSession? {
        return speechRecognizer.getCurrentSession()
    }
    
    func getAllSessions() -> [AudioRecordingSession] {
        return speechRecognizer.getAllSessions()
    }
    
    func loadSession(sessionId: String) -> AudioRecordingSession? {
        return speechRecognizer.loadSession(sessionId: sessionId)
    }
    
    func deleteSession(sessionId: String) -> Bool {
        return speechRecognizer.deleteSession(sessionId: sessionId)
    }
    
    func exportTimingData(session: AudioRecordingSession, format: ExportManager.TimingExportFormat) -> String {
        return speechRecognizer.exportTimingData(session: session, format: format)
    }
    
    // MARK: - Audio Playback
    
    func loadAudioForPlayback(audioURL: URL, session: AudioRecordingSession) {
        audioPlaybackManager.loadAudioForPlayback(audioURL: audioURL, session: session)
    }
    
    func playAudio() {
        audioPlaybackManager.play()
    }
    
    func pauseAudio() {
        audioPlaybackManager.pause()
    }
    
    func stopAudio() {
        audioPlaybackManager.stop()
    }
    
    func seekToTime(_ time: TimeInterval) {
        audioPlaybackManager.seekToTime(time)
    }
    
    func seekToSegment(_ segment: TranscriptionSegment) {
        audioPlaybackManager.seekToSegment(segment)
    }
    
    func seekToText(_ text: String) -> Bool {
        return audioPlaybackManager.seekToText(text)
    }
    
    func setPlaybackSpeed(_ speed: PlaybackSpeed) {
        audioPlaybackManager.setPlaybackSpeed(speed)
    }
    
    func nextSegment() {
        audioPlaybackManager.nextSegment()
    }
    
    func previousSegment() {
        audioPlaybackManager.previousSegment()
    }
    
    // MARK: - Export Functions
    
    func exportTimingDataToFiles(session: AudioRecordingSession, format: ExportManager.TimingExportFormat, completion: @escaping (Bool) -> Void) {
        ExportManager.shared.saveTimingDataToFiles(session: session, format: format, completion: completion)
    }
    
    func exportAudioWithTimingData(session: AudioRecordingSession, format: ExportManager.TimingExportFormat, completion: @escaping (Bool) -> Void) {
        ExportManager.shared.exportAudioWithTimingData(session: session, timingFormat: format, completion: completion)
    }
    
    func presentTimingDataShareSheet(session: AudioRecordingSession, format: ExportManager.TimingExportFormat, from sourceView: UIView?) {
        ExportManager.shared.presentTimingDataShareSheet(session: session, format: format, from: sourceView)
    }
    
    func presentAudioWithTimingDataShareSheet(session: AudioRecordingSession, format: ExportManager.TimingExportFormat, from sourceView: UIView?) {
        ExportManager.shared.presentAudioWithTimingDataShareSheet(session: session, timingFormat: format, from: sourceView)
    }
    
    // MARK: - Utility Functions
    
    func getFormattedRecordingDuration() -> String {
        return audioRecordingManager.formatDuration(recordingDuration)
    }
    
    func getFormattedPlaybackTime() -> String {
        return audioPlaybackManager.getFormattedCurrentTime()
    }
    
    func getFormattedPlaybackDuration() -> String {
        return audioPlaybackManager.getFormattedDuration()
    }

}
