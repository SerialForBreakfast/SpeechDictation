//
//  ScrollbackAutoscrollTests.swift
//  SpeechDictationUITests
//
//  Validates "1-hour style scrollback" behaviors at the UI level:
//  - transcript grows
//  - user scrolls up disables autoscroll
//  - Jump-to-live affordance appears
//  - returning to bottom resumes autoscroll
//

import XCTest

final class ScrollbackAutoscrollTests: XCTestCase {

    private var app: XCUIApplication!
    private var driver: UITestAppDriver!
    private let permissions: UITestPermissionHelper = UITestPermissionHelper()

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication(bundleIdentifier: UITestConstants.appBundleId)
        driver = UITestAppDriver(app: app)
        permissions.installInterruptionMonitor(on: self)
    }

    override func tearDownWithError() throws {
        if let app {
            app.terminate()
        }
        permissions.removeMonitors(from: self)
        app = nil
        driver = nil
        try super.tearDownWithError()
    }

    @MainActor
    func testAutoscroll_DisablesWhenUserScrollsUp_AndJumpToLiveAppears() throws {
        driver.configureForFixtureMode(
            fixtureName: UITestConstants.Fixtures.stressLongTranscript,
            resetState: true
        )

        driver.launch()
        driver.navigateToAudioTranscriptionExperienceIfNeeded()
        driver.tapStartListening()
        permissions.triggerInterruptionIfNeeded(app: app)

        let transcriptEl: XCUIElement = driver.transcriptElement()
        XCTAssertTrue(transcriptEl.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds))

        _ = UITestTranscriptAssertions.waitForTranscriptToChange(
            transcriptElement: transcriptEl,
            timeout: UITestConstants.longTimeoutSeconds,
            minimumNewCharacters: 200
        )

        // Scroll up - exact mechanics depend on how ContentView is structured.
        // If transcript is in a scroll view, swipeUp usually moves content down; we want to move away from the bottom.
        UITestLogger.log("Scrolling away from live (swipeDown to move view toward earlier content)")
        app.swipeDown()
        app.swipeDown()

        // Jump-to-live should appear.
        let jumpById: XCUIElement = app.buttons[UITestConstants.A11yId.jumpToLiveButton]
        let jumpFallback: XCUIElement = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Jump")).firstMatch

        XCTAssertTrue(
            jumpById.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds) ||
            jumpFallback.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds),
            "Expected Jump-to-live to appear after user scrolls away."
        )

        let jumpButton: XCUIElement = jumpById.exists ? jumpById : jumpFallback
        UITestLogger.log("Tapping Jump-to-live")
        jumpButton.tap()

        // After jumping, transcript should still be updating (autoscroll resumed).
        _ = UITestTranscriptAssertions.waitForTranscriptToChange(
            transcriptElement: transcriptEl,
            timeout: UITestConstants.longTimeoutSeconds,
            minimumNewCharacters: 40
        )

        driver.tapStopListening()
    }
}
