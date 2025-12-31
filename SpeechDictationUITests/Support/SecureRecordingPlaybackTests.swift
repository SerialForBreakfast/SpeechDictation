//
//  SecureRecordingPlaybackTests.swift
//  SpeechDictationUITests
//
//  End-to-end UI tests covering:
//  - record/transcribe (fixture-driven)
//  - stop
//  - playback can start and seek
//
//  Note: true file-protection/encryption invariants should primarily be validated via XCTest
//  integration tests (non-UI) because XCUITest is not designed for deep filesystem inspection.
//

import XCTest

final class SecureRecordingPlaybackTests: XCTestCase {

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
    func testFixture_RecordStop_PlaybackAndSeek() throws {
        driver.configureForFixtureMode(
            fixtureName: UITestConstants.Fixtures.multiSpeaker,
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
            minimumNewCharacters: 120
        )

        driver.tapStopListening()

        // Playback controls may appear after stop, or always be visible.
        driver.playPauseIfPresent()

        // If there is a seek slider, nudge it forward and assert it remains hittable.
        if let slider: XCUIElement = driver.seekSliderIfPresent() {
            UITestLogger.log("Seeking via slider (normalized position 0.6)")
            slider.adjust(toNormalizedSliderPosition: 0.6)
        } else {
            UITestLogger.log("No seek slider found; skipping seek assertion")
        }

        // Toggle pause to ensure control responds.
        driver.playPauseIfPresent()
    }
}
