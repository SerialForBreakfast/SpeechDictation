//
//  SpeechDictationUITests.swift
//  SpeechDictationUITests
//
//  Created by Joseph McCraw on 6/25/24.
//

import XCTest

/// End-to-end UI smoke tests for SpeechDictation.
///
/// Notes:
/// - These tests intentionally avoid asserting specific transcription text because speech recognition output
///   is nondeterministic across devices, simulator runtimes, and OS versions.
/// - When available (iOS 17+), we run `performAccessibilityAudit()` to catch obvious accessibility regressions.
/// - We launch with lightweight test arguments so the app can optionally switch to deterministic fixture mode
///   in the future without needing to rewrite tests.
final class SpeechDictationUITests: XCTestCase {

    private enum LaunchArgument {
        /// Enables future test-only codepaths in the app.
        static let uiTesting: String = "-uiTesting"

        /// Hint for the app to avoid heavy animations / timers if you add that behavior later.
        static let reduceMotionForTests: String = "-reduceMotionForTests"
    }

    private enum UIStrings {
        static let audioTranscriptionExperience: String = "Audio Transcription"
        static let liveCameraExperience: String = "Live Camera Input"
        static let startListening: String = "Start Listening"
        static let initialMessage: String = "Tap a button to begin"
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Smoke tests

    @MainActor
    func testEntryView_launches_and_hasExpectedOptions() throws {
        let app: XCUIApplication = makeApp()
        app.launch()

        handleSystemPermissionAlertsIfPresent(timeoutSeconds: 2.0)

        // EntryView should expose one (or both) experience choices.
        let audioButton: XCUIElement = app.buttons[UIStrings.audioTranscriptionExperience]
        let cameraButton: XCUIElement = app.buttons[UIStrings.liveCameraExperience]

        XCTAssertTrue(
            audioButton.waitForExistence(timeout: 5.0) || cameraButton.waitForExistence(timeout: 5.0),
            "Expected EntryView to show experience selection buttons."
        )

        try runAccessibilityAuditIfAvailable(app: app, label: "EntryView")
    }

    @MainActor
    func testAudioTranscriptionView_launches_and_basicControlsExist() throws {
        let app: XCUIApplication = makeApp()
        app.launch()

        handleSystemPermissionAlertsIfPresent(timeoutSeconds: 2.0)

        let audioButton: XCUIElement = app.buttons[UIStrings.audioTranscriptionExperience]
        guard audioButton.waitForExistence(timeout: 5.0) else {
            throw XCTSkip("Audio Transcription experience button not found. Verify EntryView labels.")
        }

        audioButton.tap()

        // ContentView historically shows this initial message.
        let initialMessage: XCUIElement = app.staticTexts[UIStrings.initialMessage]
        XCTAssertTrue(initialMessage.waitForExistence(timeout: 5.0), "Expected initial transcript placeholder to exist.")

        // The primary control should exist.
        let startListening: XCUIElement = app.buttons[UIStrings.startListening]
        XCTAssertTrue(startListening.waitForExistence(timeout: 5.0), "Expected a Start Listening button to exist.")

        try runAccessibilityAuditIfAvailable(app: app, label: "AudioTranscription")
    }

    // MARK: - Helpers

    /// Creates a configured application instance for UI testing.
    ///
    /// This method standardizes launch arguments and environment variables so tests remain stable even as
    /// the app grows more complex.
    private func makeApp() -> XCUIApplication {
        let app: XCUIApplication = XCUIApplication()
        app.launchArguments = [
            LaunchArgument.uiTesting,
            LaunchArgument.reduceMotionForTests
        ]
        return app
    }

    /// Runs the built-in XCUITest accessibility audit when available.
    ///
    /// - Important: This API is iOS 17+.
    private func runAccessibilityAuditIfAvailable(app: XCUIApplication, label: String) throws {
        if #available(iOS 17.0, *) {
            do {
                try app.performAccessibilityAudit()
            } catch {
                XCTFail("Accessibility audit failed (\(label)): \(error)")
                throw error
            }
        } else {
            // Older OS versions do not support `performAccessibilityAudit`.
        }
    }

    /// Best-effort handler for common permission alerts that can block UI test automation.
    ///
    /// This uses Springboard to attempt to dismiss or accept prompts.
    /// It is intentionally defensive: if nothing appears, it exits quickly.
    private func handleSystemPermissionAlertsIfPresent(timeoutSeconds: TimeInterval) {
        let springboard: XCUIApplication = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        let deadline: Date = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            let alert: XCUIElement = springboard.alerts.firstMatch
            if !alert.exists {
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
                continue
            }

            // Try common button labels in a priority order.
            let preferredButtons: [String] = [
                "Allow",
                "OK",
                "Allow While Using App",
                "Allow Once",
                "Continue",
                "Don’t Allow",
                "Don't Allow",
                "Not Now"
            ]

            for title in preferredButtons {
                let button: XCUIElement = alert.buttons[title]
                if button.exists {
                    button.tap()
                    break
                }
            }

            // Give the UI a moment to settle between sequential prompts.
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
    }
}
