//
//  UITestConstants.swift
//  SpeechDictationUITests
//
//  Defines stable identifiers, launch arguments, and timeouts for UI tests.
//
//  IMPORTANT:
//  For CI-stable end-to-end tests (per ADR-IntegrationEndToEndTesting),
//  the app should support a deterministic "fixture audio mode" driven by:
//   - Launch arguments (ProcessInfo.arguments) OR
//   - Launch environment (ProcessInfo.environment)
//
//  The test suite uses these keys:
//   - UITEST_MODE=1
//   - UITEST_AUDIO_FIXTURE=<fixture filename in bundle>
//   - UITEST_LOCALE=<e.g., en_US>
//   - UITEST_REQUIRES_ON_DEVICE_RECOGNITION=1
//
//  If those hooks are not implemented yet, some tests will intentionally fail,
//  because they represent the desired ADR-compliant coverage.
//

import Foundation

enum UITestConstants {
    /// The app-under-test bundle identifier from directory_tree.md.
    static let appBundleId: String = "com.ShowBlender.SpeechDictation"

    /// Default per-step UI wait.
    static let defaultTimeoutSeconds: TimeInterval = 12.0

    /// Long-running operations (fixture transcription, export).
    static let longTimeoutSeconds: TimeInterval = 60.0

    /// Stress scenarios (long transcript / scrollback).
    static let stressTimeoutSeconds: TimeInterval = 180.0

    enum LaunchEnv {
        static let uiTestMode: String = "UITEST_MODE"
        static let uiTestLogging: String = "UITEST_LOGGING"
        static let audioFixture: String = "UITEST_AUDIO_FIXTURE"
        static let locale: String = "UITEST_LOCALE"
        static let requiresOnDeviceRecognition: String = "UITEST_REQUIRES_ON_DEVICE_RECOGNITION"
        static let disableAnimations: String = "UITEST_DISABLE_ANIMATIONS"
        static let resetAppState: String = "UITEST_RESET_STATE"
    }

    enum Fixtures {
        /// Suggested fixture file name for long pauses / intermittent dialog.
        /// Add these to the app bundle (or a test bundle the app can read).
        static let longPauseConversation: String = "long_pause_01.m4a"
        static let intermittentDialog: String = "intermittent_dialog_01.m4a"
        static let multiSpeaker: String = "multi_speaker_01.m4a"
        static let stressLongTranscript: String = "stress_long_transcript_01.m4a"
    }

    /// Accessibility identifiers you should set in-app for CI stability.
    /// The tests include some fallback "label contains" queries, but identifiers are preferred.
    enum A11yId {
        // Entry view
        static let entryAudioTranscriptionCard: String = "entry.audioTranscription"
        static let entryLiveCameraCard: String = "entry.liveCamera"

        // Main transcription screen
        static let startListeningButton: String = "transcription.startListening"
        static let stopListeningButton: String = "transcription.stopListening"
        static let resetButton: String = "transcription.reset"
        static let transcriptTextView: String = "transcription.transcriptText"
        static let jumpToLiveButton: String = "transcription.jumpToLive"

        // Playback
        static let playbackPlayPauseButton: String = "playback.playPause"
        static let playbackSeekSlider: String = "playback.seekSlider"
        static let playbackTimeLabel: String = "playback.timeLabel"

        // Settings
        static let settingsButton: String = "nav.settings"
        static let settingsRoot: String = "settings.root"
        static let settingsTextSize: String = "settings.textSize"
        static let settingsTheme: String = "settings.theme"
        static let settingsMicSensitivity: String = "settings.micSensitivity"

        // Export
        static let exportButton: String = "export.button"
        static let exportSheet: String = "export.sheet"
    }
}
