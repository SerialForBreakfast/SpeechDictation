//
//  UITestPermissionHelper.swift
//  SpeechDictationUITests
//
//  Centralized permission control and UI interruption handling.
//
//  References:
//  - XCUIApplication.resetAuthorizationStatus(for:)
//  - Handling UI interruptions / addUIInterruptionMonitor(...)
//

import XCTest

final class UITestPermissionHelper {

    private(set) var monitorTokens: [NSObjectProtocol] = []

    func installInterruptionMonitor(on testCase: XCTestCase) {
        let token: NSObjectProtocol = testCase.addUIInterruptionMonitor(withDescription: "System Permissions") { alert -> Bool in
            let allowTitles: [String] = [
                "Allow",
                "OK",
                "Continue",
                "Allow While Using App",
                "Allow Once",
                "Always Allow"
            ]

            let denyTitles: [String] = [
                "Don’t Allow",
                "Don't Allow",
                "Not Now"
            ]

            // Prefer allowing for end-to-end tests; if you want deny-path tests, add a dedicated monitor.
            for title: String in allowTitles {
                let button: XCUIElement = alert.buttons[title]
                if button.exists {
                    UITestLogger.log("Permission alert: tapping \(title)")
                    button.tap()
                    return true
                }
            }

            // If no allow button, try to dismiss to avoid blocking the test run.
            for title: String in denyTitles {
                let button: XCUIElement = alert.buttons[title]
                if button.exists {
                    UITestLogger.log("Permission alert: tapping \(title) (fallback dismiss)")
                    button.tap()
                    return true
                }
            }

            UITestLogger.log("Permission alert: unhandled alert visible: \(alert)")
            return false
        }

        monitorTokens.append(token)
    }

    func removeMonitors(from testCase: XCTestCase) {
        for token: NSObjectProtocol in monitorTokens {
            testCase.removeUIInterruptionMonitor(token)
        }
        monitorTokens.removeAll()
    }

    /// Resets permissions so the "first run" permission flow can be tested reliably.
    ///
    /// - Note: This only affects UI test state; Simulator/device behaviors still vary by OS.
    /// - Note: Speech recognition cannot be reset programmatically, only microphone
    func resetSpeechAndMicrophonePermissions(for app: XCUIApplication) {
        // These APIs require iOS 13.4+.
        // Speech recognition permission cannot be reset via XCUIProtectedResource
        UITestLogger.log("Resetting authorization status for microphone")
        app.resetAuthorizationStatus(for: .microphone)
        UITestLogger.log("Note: Speech recognition permission cannot be reset programmatically")  ///Users/josephmccraw/Dropbox/My Mac (MacBook-Air)/Documents/GitHub/SpeechDictation-iOS/SpeechDictationUITests/Support/UITestPermissionHelper.swift:77:44 Type 'XCUIProtectedResource' has no member 'speechRecognition'
    }

    /// Triggers interruption monitors when an alert appears.
    ///
    /// Apple’s docs note you often need an extra tap after the interruption monitor is installed.
    func triggerInterruptionIfNeeded(app: XCUIApplication) {
        // A generic tap helps XCTest process the interruption.
        app.tap()
    }
}
