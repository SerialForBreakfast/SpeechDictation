//
//  UITestTranscriptAssertions.swift
//  SpeechDictationUITests
//
//  Robust transcript assertions to avoid brittle exact-string comparisons.
//  This follows the ADR guidance: normalize text and assert key phrases in order.
//

import XCTest

enum UITestTranscriptAssertions {

    static func normalized(_ text: String) -> String {
        // Normalize for OS/locale punctuation variability.
        let lower: String = text.lowercased()
        let collapsedWhitespace: String = lower.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let strippedPunctuation: String = collapsedWhitespace
            .replacingOccurrences(of: "[\\p{P}“”‘’]", with: "", options: .regularExpression)
        return strippedPunctuation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Waits until a transcript-like element has grown or changed meaningfully.
    static func waitForTranscriptToChange(
        transcriptElement: XCUIElement,
        timeout: TimeInterval,
        minimumNewCharacters: Int = 20
    ) -> String {
        let start: Date = Date()
        let initial: String = transcriptElement.exists ? transcriptElement.label : ""
        UITestLogger.log("Initial transcript length=\(initial.count)")

        while Date().timeIntervalSince(start) < timeout {
            let current: String = transcriptElement.label
            if current.count >= initial.count + minimumNewCharacters {
                UITestLogger.log("Transcript changed. newLength=\(current.count)")
                return current
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        XCTFail("Transcript did not change by at least \(minimumNewCharacters) chars within \(timeout)s. initial=\(initial.count) current=\(transcriptElement.label.count)")
        return transcriptElement.label
    }

    /// Assert that the transcript contains phrases in order (tolerant to extra words).
    static func assertContainsPhrasesInOrder(
        transcript: String,
        phrases: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let normalizedTranscript: String = normalized(transcript)
        var searchStartIndex: String.Index = normalizedTranscript.startIndex

        for phrase: String in phrases {
            let normalizedPhrase: String = normalized(phrase)
            guard let range: Range<String.Index> = normalizedTranscript.range(of: normalizedPhrase, range: searchStartIndex..<normalizedTranscript.endIndex) else {
                XCTFail("Expected phrase not found in order: \(phrase)\nTranscript (normalized):\n\(normalizedTranscript)", file: file, line: line)
                return
            }
            searchStartIndex = range.upperBound
        }
    }
}
