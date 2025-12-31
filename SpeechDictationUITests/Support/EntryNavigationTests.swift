//
//  EntryNavigationTests.swift
//  SpeechDictationUITests
//
//  Verifies entry experience selection routes to the transcription screen.
//

import XCTest

final class EntryNavigationTests: XCTestCase {

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
    func testEntry_SelectAudioTranscription_RoutesToContent() throws {
        driver.configureForFixtureMode(
            fixtureName: UITestConstants.Fixtures.longPauseConversation,
            resetState: true
        )
        driver.launch()
        driver.navigateToAudioTranscriptionExperienceIfNeeded()

        // Ensure we can find the main "Start" control on the transcription screen.
        let startById: XCUIElement = app.buttons[UITestConstants.A11yId.startListeningButton]
        let startFallback: XCUIElement = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Start")).firstMatch

        XCTAssertTrue(
            startById.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds) ||
            startFallback.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds),
            "Expected Start Listening control to exist after entering transcription experience."
        )
    }
}
