//
//  TranscriptComposition.swift
//  SpeechDictation
//
//  Shared logic for composing accumulated and partial transcript text.
//  Reduces duplication when the speech model re-emits prior text as it gains context.
//

import Foundation

/// Composes accumulated (finalized) and partial (in-progress) transcript text with overlap stripping
/// and consecutive-word deduplication to avoid duplication as the model revises its hypothesis.
///
/// - **Overlap stripping**: When a new task's partial includes the tail of the previous utterance
///   (e.g. accumulated "the cat sat", partial "the cat sat on the mat"), we strip the overlapping
///   prefix of partial so we append only "on the mat".
/// - **Consecutive-word deduplication**: Removes immediate duplicate words (e.g. "hello hello" -> "hello").
///
/// Concurrency: Thread-safe; pure functions with no shared state.
enum TranscriptComposition {

    /// Combines accumulated and partial transcript, stripping overlap and deduplicating.
    ///
    /// - Parameters:
    ///   - accumulated: Finalized transcript from previous segments.
    ///   - partial: Current hypothesis from the active recognition task.
    /// - Returns: Composed transcript suitable for display.
    static func compose(accumulated: String, partial: String) -> String {
        guard !accumulated.isEmpty else {
            return deduplicateConsecutiveWords(partial)
        }
        guard !partial.isEmpty else {
            return accumulated
        }
        let trimmedPartial = stripOverlap(accumulated: accumulated, partial: partial)
        guard !trimmedPartial.isEmpty else {
            return accumulated
        }
        let composed = accumulated + " " + trimmedPartial
        return deduplicateConsecutiveWords(composed)
    }

    /// Strips the longest overlapping prefix of `partial` that matches a suffix of `accumulated`.
    /// Prevents duplication when the model re-emits prior text at task boundaries.
    ///
    /// - Parameters:
    ///   - accumulated: Finalized transcript.
    ///   - partial: Current hypothesis (may overlap with accumulated).
    /// - Returns: Only the new content from partial (overlap removed).
    static func stripOverlap(accumulated: String, partial: String) -> String {
        guard !accumulated.isEmpty, !partial.isEmpty else { return partial }

        let accWords = accumulated.split(separator: " ", omittingEmptySubsequences: true)
        let partWords = partial.split(separator: " ", omittingEmptySubsequences: true)
        guard !accWords.isEmpty, !partWords.isEmpty else { return partial }

        var overlapCount = 0
        for i in 1...min(accWords.count, partWords.count) {
            if accWords.suffix(i).elementsEqual(partWords.prefix(i)) {
                overlapCount = i
            }
        }
        if overlapCount > 0 {
            return partWords.dropFirst(overlapCount).joined(separator: " ")
        }
        return partial
    }

    /// Removes immediate consecutive duplicate words.
    ///
    /// - Parameter text: Raw transcript text.
    /// - Returns: Text with consecutive duplicates removed.
    static func deduplicateConsecutiveWords(_ text: String) -> String {
        let words = text.split(separator: " ", omittingEmptySubsequences: true)
        var result: [Substring] = []
        for word in words {
            if result.last != word {
                result.append(word)
            }
        }
        return result.joined(separator: " ")
    }
}
