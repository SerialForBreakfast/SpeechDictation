//
//  TranscriptionFixtureFlowTests.swift
//  SpeechDictationUITests
//
//  ADR-compliant end-to-end UI tests using deterministic fixture audio mode.
//
//  Coverage:
//  - Fixture-driven transcription starts, updates incrementally, then stops
//  - Long pauses do not end the session prematurely (app-dependent, but transcript should continue)
//  - Transcript contains expected phrases in order (tolerant assertions)
//

import XCTest

final class TranscriptionFixtureFlowTests: XCTestCase {

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
    func testFixture_LongPause_TranscribesAndDoesNotTruncate() throws {
        driver.configureForFixtureMode(
            fixtureName: UITestConstants.Fixtures.longPauseConversation,
            resetState: true
        )

        // Reset permissions to exercise the permission flow.
        permissions.resetSpeechAndMicrophonePermissions(for: app)

        driver.launch()
        driver.navigateToAudioTranscriptionExperienceIfNeeded()

        driver.tapStartListening()
        permissions.triggerInterruptionIfNeeded(app: app)

        let transcriptEl: XCUIElement = driver.transcriptElement()
        XCTAssertTrue(transcriptEl.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds))

        let updatedTranscript: String = UITestTranscriptAssertions.waitForTranscriptToChange(
            transcriptElement: transcriptEl,
            timeout: UITestConstants.longTimeoutSeconds,
            minimumNewCharacters: 80
        )

        // Replace these phrases with the actual script/ground-truth for your fixture.
        UITestTranscriptAssertions.assertContainsPhrasesInOrder(
            transcript: updatedTranscript,
            phrases: [
                "this is a test",
                "long pause",
                "continuing after the pause"
            ]
        )

        driver.tapStopListening()
    }

    @MainActor
    func testFixture_IntermittentDialog_ContinuesAcrossSilence() throws {
        driver.configureForFixtureMode(
            fixtureName: UITestConstants.Fixtures.intermittentDialog,
            resetState: true
        )

        driver.launch()
        driver.navigateToAudioTranscriptionExperienceIfNeeded()

        driver.tapStartListening()
        permissions.triggerInterruptionIfNeeded(app: app)

        let transcriptEl: XCUIElement = driver.transcriptElement()
        XCTAssertTrue(transcriptEl.waitForExistence(timeout: UITestConstants.defaultTimeoutSeconds))

        let updatedTranscript: String = UITestTranscriptAssertions.waitForTranscriptToChange(
            transcriptElement: transcriptEl,
            timeout: UITestConstants.longTimeoutSeconds,
            minimumNewCharacters: 120
        )

        UITestTranscriptAssertions.assertContainsPhrasesInOrder(
            transcript: updatedTranscript,
            phrases: [
                "speaker one",
                "speaker two",
                "back again"
            ]
        )

        driver.tapStopListening()
    }
}
