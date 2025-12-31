//
//  TranscriptPersistenceTests.swift
//  SpeechDictationTests
//
//  Created: 2025-12-13
//
//  Purpose:
//  Define the persistence contract needed for 1-hour, real-world recordings:
//
//  - Incremental persistence of committed transcript data.
//  - Atomic writes to avoid corruption.
//  - Resume merges loaded transcript with new segments without duplication.
//
//  NOTE:
//  This file provides a TDD contract using a reference persistence implementation.
//  Once the production TranscriptRepository / persistence layer exists,
//  replace TranscriptPersistenceReference with the real component and keep the tests.
//

import Foundation
import XCTest
@testable import SpeechDictation

@MainActor
final class TranscriptPersistenceTests: XCTestCase {

    private var tempDir: URL?

    override func setUp() async throws {
        try await super.setUp()
        let dir: URL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        tempDir = dir
    }

    override func tearDown() async throws {
        if let dir: URL = tempDir {
            try? FileManager.default.removeItem(at: dir)
        }
        tempDir = nil
        try await super.tearDown()
    }

    func testPersistence_atomicWriteAndReadBack_roundTripsSegments() throws {
        guard let dir: URL = tempDir else { XCTFail("Missing temp dir"); return }

        let store: TranscriptPersistenceReference = TranscriptPersistenceReference(baseDirectory: dir)

        let segments: [TranscriptionSegment] = [
            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9),
            TranscriptionSegment(text: "world", startTime: 1.0, endTime: 2.0, confidence: 0.9)
        ]

        try store.writeCommittedSegments(segments, sessionID: "session-1")

        let loaded: [TranscriptionSegment] = try store.readCommittedSegments(sessionID: "session-1")

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded.map(\.text), ["Hello", "world"])
    }

    func testPersistence_incrementalAppend_doesNotDuplicateOnReload() throws {
        guard let dir: URL = tempDir else { XCTFail("Missing temp dir"); return }

        let store: TranscriptPersistenceReference = TranscriptPersistenceReference(baseDirectory: dir)

        let first: [TranscriptionSegment] = [
            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9)
        ]
        try store.writeCommittedSegments(first, sessionID: "session-2")

        let second: [TranscriptionSegment] = [
            TranscriptionSegment(text: "world", startTime: 1.0, endTime: 2.0, confidence: 0.9)
        ]
        try store.appendCommittedSegments(second, sessionID: "session-2")

        let loaded: [TranscriptionSegment] = try store.readCommittedSegments(sessionID: "session-2")

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded.map(\.text), ["Hello", "world"])
    }

    func testPersistence_resumeMerge_prefersExistingForSameTimeRange() throws {
        // Business rule:
        // When resuming, previously persisted segments are the source of truth for committed data.
        // New incoming segments that collide should be treated as corrections ONLY if they match a correction policy.
        //
        // This reference store uses “existing wins” for exact time overlap, which is conservative.
        // If you choose “new wins within correction window,” update this test accordingly.
        guard let dir: URL = tempDir else { XCTFail("Missing temp dir"); return }

        let store: TranscriptPersistenceReference = TranscriptPersistenceReference(baseDirectory: dir)

        let persisted: [TranscriptionSegment] = [
            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9)
        ]
        try store.writeCommittedSegments(persisted, sessionID: "session-3")

        let incomingOnResume: [TranscriptionSegment] = [
            TranscriptionSegment(text: "Hi", startTime: 0.0, endTime: 1.0, confidence: 0.95),
            TranscriptionSegment(text: "world", startTime: 1.0, endTime: 2.0, confidence: 0.9)
        ]

        let merged: [TranscriptionSegment] = try store.mergeOnResume(incomingOnResume, sessionID: "session-3")

        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(merged[0].text, "Hello", "Existing persisted committed segment should win for exact time overlap.")
        XCTAssertEqual(merged[1].text, "world")
    }
}

// MARK: - Test-only reference persistence layer

/// A minimal JSON-based persistence implementation:
/// - Writes committed segments atomically by writing to a temp file then replacing.
/// - Supports append by reading existing, merging, then rewriting atomically.
///
/// Replace with the app’s secure/persistent storage implementation when ready.
struct TranscriptPersistenceReference {

    private let baseDirectory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func writeCommittedSegments(_ segments: [TranscriptionSegment], sessionID: String) throws {
        let url: URL = fileURL(sessionID: sessionID)
        let data: Data = try encoder.encode(segments)
        try atomicWrite(data, to: url)
    }

    func appendCommittedSegments(_ newSegments: [TranscriptionSegment], sessionID: String) throws {
        let existing: [TranscriptionSegment] = (try? readCommittedSegments(sessionID: sessionID)) ?? []
        let merged: [TranscriptionSegment] = merge(existing: existing, incoming: newSegments)
        try writeCommittedSegments(merged, sessionID: sessionID)
    }

    func readCommittedSegments(sessionID: String) throws -> [TranscriptionSegment] {
        let url: URL = fileURL(sessionID: sessionID)
        let data: Data = try Data(contentsOf: url)
        let segments: [TranscriptionSegment] = try decoder.decode([TranscriptionSegment].self, from: data)
        return segments.sorted { a, b in
            if a.startTime != b.startTime { return a.startTime < b.startTime }
            return a.endTime < b.endTime
        }
    }

    func mergeOnResume(_ incoming: [TranscriptionSegment], sessionID: String) throws -> [TranscriptionSegment] {
        let existing: [TranscriptionSegment] = (try? readCommittedSegments(sessionID: sessionID)) ?? []
        return merge(existing: existing, incoming: incoming)
    }

    // MARK: - Internals

    private func fileURL(sessionID: String) -> URL {
        return baseDirectory.appendingPathComponent("\(sessionID).json")
    }

    private func atomicWrite(_ data: Data, to url: URL) throws {
        let tempURL: URL = url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString + ".tmp")

        try data.write(to: tempURL, options: [.atomic])

        // Ensure final location exists by replace/move.
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
        } else {
            try FileManager.default.moveItem(at: tempURL, to: url)
        }
    }

    private func merge(existing: [TranscriptionSegment], incoming: [TranscriptionSegment]) -> [TranscriptionSegment] {
        // Conservative merge: existing wins for exact (start,end) overlap.
        var map: [SegmentKey: TranscriptionSegment] = [:]
        for seg: TranscriptionSegment in existing {
            let key: SegmentKey = SegmentKey(start: seg.startTime, end: seg.endTime)
            map[key] = seg
        }
        for seg: TranscriptionSegment in incoming {
            let key: SegmentKey = SegmentKey(start: seg.startTime, end: seg.endTime)
            if map[key] == nil {
                map[key] = seg
            }
        }
        let merged: [TranscriptionSegment] = Array(map.values).sorted { a, b in
            if a.startTime != b.startTime { return a.startTime < b.startTime }
            return a.endTime < b.endTime
        }
        return merged
    }

    private struct SegmentKey: Hashable {
        let start: TimeInterval
        let end: TimeInterval
    }
}
