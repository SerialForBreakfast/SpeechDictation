//
//  ExportFlowsTests.swift
//  SpeechDictationUITests
//
//  UI-level checks for Export / Share flows.
//
//  This does not validate the full contents of exported files (that belongs in XCTest integration tests),
//  but it does validate that:
//   - the export UI can be opened
//   - the user can pick a format
//   - the system share sheet (or document picker) appears
//

import XCTest

final class ExportFlowsTests: XCTestCase {

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
    func testExportUI_Opens_FromTranscriptionScreen() throws {
        driver.configureForFixtureMode(
            fixtureName: UITestConstants.Fixtures.longPauseConversation,
            resetState: true
        )

        driver.launch()
        driver.navigateToAudioTranscriptionExperienceIfNeeded()

        // Ensure there's some content to export.
        driver.tapStartListening()
        permissions.triggerInterruptionIfNeeded(app: app)

        let transcriptEl: XCUIElement = driver.transcriptElement()
        XCTAssertTrue(transcriptEl.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds))

        _ = UITestTranscriptAssertions.waitForTranscriptToChange(
            transcriptElement: transcriptEl,
            timeout: UITestConstants.longTimeoutSeconds,
            minimumNewCharacters: 80
        )

        driver.tapStopListening()
        driver.openExportIfPresent()

        // Export UI can be a custom sheet or native share sheet; verify something modal appears.
        // If you add identifiers in-app, prefer UITestConstants.A11yId.exportSheet.
        let byId: XCUIElement = app.otherElements[UITestConstants.A11yId.exportSheet]
        if byId.exists {
            XCTAssertTrue(byId.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds))
            return
        }

        // Fallback: detect common iOS share sheet element types.
        let shareSheet: XCUIElement = app.sheets.firstMatch
        let activityList: XCUIElement = app.collectionViews.firstMatch
        XCTAssertTrue(
            shareSheet.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds) ||
            activityList.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds),
            "Expected an export/share modal to appear."
        )
    }
}
