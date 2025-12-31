//
//  UITestAppDriver.swift
//  SpeechDictationUITests
//
//  A small "driver" layer that encapsulates navigation and common UI actions.
//
//  Design goal:
//  - Keep tests readable and centralized around stable accessibility identifiers.
//  - Include fallback selectors for current UI labels to reduce churn while identifiers are added.
//

import XCTest

final class UITestAppDriver {

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Launch

    func configureForFixtureMode(
        fixtureName: String,
        locale: String = "en_US",
        requiresOnDeviceRecognition: Bool = true,
        resetState: Bool = true,
        disableAnimations: Bool = true
    ) {
        app.launchEnvironment[UITestConstants.LaunchEnv.uiTestMode] = "1"
        app.launchEnvironment[UITestConstants.LaunchEnv.uiTestLogging] = "1"
        app.launchEnvironment[UITestConstants.LaunchEnv.audioFixture] = fixtureName
        app.launchEnvironment[UITestConstants.LaunchEnv.locale] = locale
        app.launchEnvironment[UITestConstants.LaunchEnv.requiresOnDeviceRecognition] = requiresOnDeviceRecognition ? "1" : "0"
        app.launchEnvironment[UITestConstants.LaunchEnv.resetAppState] = resetState ? "1" : "0"
        app.launchEnvironment[UITestConstants.LaunchEnv.disableAnimations] = disableAnimations ? "1" : "0"
    }

    func launch() {
        UITestLogger.log("Launching app")
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds))
    }

    // MARK: - Navigation

    func navigateToAudioTranscriptionExperienceIfNeeded() {
        // Prefer stable accessibility identifiers (recommended).
        let cardById: XCUIElement = app.buttons[UITestConstants.A11yId.entryAudioTranscriptionCard]
        if cardById.exists {
            UITestLogger.log("Entry: tapping audio transcription card by id")
            cardById.tap()
            return
        }

        // Fallback: label contains "Audio" and "Transcription"
        let predicate: NSPredicate = NSPredicate(format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@", "Audio", "Transcription")
        let button: XCUIElement = app.buttons.matching(predicate).firstMatch
        if button.exists {
            UITestLogger.log("Entry: tapping audio transcription button by label: \(button.label)")
            button.tap()
            return
        }

        let staticText: XCUIElement = app.staticTexts.matching(predicate).firstMatch
        if staticText.exists {
            UITestLogger.log("Entry: tapping audio transcription staticText by label: \(staticText.label)")
            staticText.tap()
            return
        }

        UITestLogger.log("Entry: no entry UI found; assuming already on transcription screen")
    }

    // MARK: - Controls

    func tapStartListening() {
        let byId: XCUIElement = app.buttons[UITestConstants.A11yId.startListeningButton]
        if byId.exists {
            UITestLogger.log("Tapping start listening by id")
            byId.tap()
            return
        }

        let start: XCUIElement = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Start")).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds))
        UITestLogger.log("Tapping start by label: \(start.label)")
        start.tap()
    }

    func tapStopListening() {
        let byId: XCUIElement = app.buttons[UITestConstants.A11yId.stopListeningButton]
        if byId.exists {
            UITestLogger.log("Tapping stop listening by id")
            byId.tap()
            return
        }

        let stop: XCUIElement = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Stop")).firstMatch
        XCTAssertTrue(stop.waitForExistence(timeout: UITestConstants.longTimeoutSeconds))
        UITestLogger.log("Tapping stop by label: \(stop.label)")
        stop.tap()
    }

    func tapResetIfPresent() {
        let byId: XCUIElement = app.buttons[UITestConstants.A11yId.resetButton]
        if byId.exists {
            UITestLogger.log("Tapping reset by id")
            byId.tap()
            return
        }

        let reset: XCUIElement = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Reset")).firstMatch
        if reset.exists {
            UITestLogger.log("Tapping reset by label: \(reset.label)")
            reset.tap()
        }
    }

    func openSettingsIfPresent() {
        let byId: XCUIElement = app.buttons[UITestConstants.A11yId.settingsButton]
        if byId.exists {
            UITestLogger.log("Opening settings by id")
            byId.tap()
            return
        }

        let settings: XCUIElement = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Settings")).firstMatch
        if settings.exists {
            UITestLogger.log("Opening settings by label: \(settings.label)")
            settings.tap()
        }
    }

    func openExportIfPresent() {
        let byId: XCUIElement = app.buttons[UITestConstants.A11yId.exportButton]
        if byId.exists {
            UITestLogger.log("Opening export by id")
            byId.tap()
            return
        }

        let export: XCUIElement = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Export")).firstMatch
        if export.exists {
            UITestLogger.log("Opening export by label: \(export.label)")
            export.tap()
            return
        }

        let share: XCUIElement = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Share")).firstMatch
        if share.exists {
            UITestLogger.log("Opening share by label: \(share.label)")
            share.tap()
        }
    }

    // MARK: - Transcript element

    func transcriptElement() -> XCUIElement {
        let byId: XCUIElement = app.staticTexts[UITestConstants.A11yId.transcriptTextView]
        if byId.exists {
            return byId
        }

        // Fallback: look for the placeholder label used in changelog.
        let placeholder: XCUIElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Tap a button to begin")).firstMatch
        if placeholder.exists {
            return placeholder
        }

        // Final fallback: first large static text.
        return app.staticTexts.firstMatch
    }

    // MARK: - Playback

    func playPauseIfPresent() {
        let byId: XCUIElement = app.buttons[UITestConstants.A11yId.playbackPlayPauseButton]
        if byId.exists {
            UITestLogger.log("Playback: toggling play/pause by id")
            byId.tap()
            return
        }

        let play: XCUIElement = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Play")).firstMatch
        if play.exists {
            UITestLogger.log("Playback: tapping Play by label")
            play.tap()
            return
        }

        let pause: XCUIElement = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Pause")).firstMatch
        if pause.exists {
            UITestLogger.log("Playback: tapping Pause by label")
            pause.tap()
        }
    }

    func seekSliderIfPresent() -> XCUIElement? {
        let byId: XCUIElement = app.sliders[UITestConstants.A11yId.playbackSeekSlider]
        if byId.exists { return byId }

        let anySlider: XCUIElement = app.sliders.firstMatch
        return anySlider.exists ? anySlider : nil
    }
}
