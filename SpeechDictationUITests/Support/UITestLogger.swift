//
//  UITestLogger.swift
//  SpeechDictationUITests
//
//  Lightweight logging utilities for UI tests with timestamps.
//

import Foundation

enum UITestLogger {
    private static let formatter: ISO8601DateFormatter = {
        let formatter: ISO8601DateFormatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func log(_ message: String, file: StaticString = #file, line: UInt = #line) {
        let timestamp: String = formatter.string(from: Date())
        print("[UITest][\(timestamp)] \(message)  (\(file):\(line))")
    }
}
