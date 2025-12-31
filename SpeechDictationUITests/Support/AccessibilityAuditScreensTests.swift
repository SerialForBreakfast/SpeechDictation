//
//  AccessibilityAuditScreensTests.swift
//  SpeechDictationUITests
//
//  Runs Xcode automated accessibility audits on key screens.
//  These audits can catch missing labels, clipped text, contrast issues, hit target size, and more.
//

//import XCTest
//
//final class AccessibilityAuditScreensTests: XCTestCase {
//
//    private var app: XCUIApplication!
//    private var driver: UITestAppDriver!
//    private let permissions: UITestPermissionHelper = UITestPermissionHelper()
//
//    override func setUpWithError() throws {
//        try super.setUpWithError()
//        continueAfterFailure = false
//
//        app = XCUIApplication(bundleIdentifier: UITestConstants.appBundleId)
//        driver = UITestAppDriver(app: app)
//        permissions.installInterruptionMonitor(on: self)
//    }
//
//    override func tearDownWithError() throws {
//        if let app {
//            app.terminate()
//        }
//        permissions.removeMonitors(from: self)
//        app = nil
//        driver = nil
//        try super.tearDownWithError()
//    }
//
//    @MainActor
//    func testAccessibilityAudit_EntryScreen() throws {
//        driver.configureForFixtureMode(
//            fixtureName: UITestConstants.Fixtures.longPauseConversation,
//            resetState: true
//        )
//        driver.launch()
//
//        UITestLogger.log("Running accessibility audit on Entry screen")
//        try app.performAccessibilityAudit()
//    }
//
//    @MainActor
//    func testAccessibilityAudit_TranscriptionScreen() throws {
//        driver.configureForFixtureMode(
//            fixtureName: UITestConstants.Fixtures.longPauseConversation,
//            resetState: true
//        )
//        driver.launch()
//        driver.navigateToAudioTranscriptionExperienceIfNeeded()
//
//        UITestLogger.log("Running accessibility audit on Transcription screen")
//        try app.performAccessibilityAudit()
//    }
//
//    @MainActor
//    func testAccessibilityAudit_SettingsScreen_IfPresent() throws {
//        driver.configureForFixtureMode(
//            fixtureName: UITestConstants.Fixtures.longPauseConversation,
//            resetState: true
//        )
//        driver.launch()
//        driver.navigateToAudioTranscriptionExperienceIfNeeded()
//
//        driver.openSettingsIfPresent()
//
//        UITestLogger.log("Running accessibility audit on Settings screen (if visible)")
//        try app.performAccessibilityAudit()
//    }
//}
