# ADR-001: Live Transcription Strategy & Visual Feedback for Addition of Secure Recording + Playback Feature

**Date:** 2025-12-06

## 1. Strengths of the ADR as Written

The ADR correctly outlines a clean, minimal mental model for handling SFSpeechRecognizer streaming updates:

*   Treat the recognizer’s result as authoritative.
*   Do not append or merge partials — replace them.
*   Maintain two buffers: `committedTranscript` (stable) and `currentPartialTranscript` (processing).
*   UI displays “committed + partial” with styling applied at render time.

These choices directly avoid the most common failure modes in live transcription pipelines:

*   Duplicate phrases when partials revise themselves
*   Stale segments when relying on append-only storage
*   TimingData pollution due to incremental partial additions
*   Flicker or disappearance caused by ambiguous “partial vs final” rules

The ADR’s framing of the recognizer as the single source of truth is correct and should remain the core invariant.

## 2. Gaps, Missing Details, and Areas to Strengthen

Although the ADR is solid for *live UI transcription*, several aspects must be clarified or expanded before adding the “secure on‑device recording + playback” feature.

### 2.1 Clarify “latest transcript”

The ADR says:
*   If `isFinal == false` → replace partial with latest `bestTranscription`
*   If `isFinal == true` → append latest transcript to `committedTranscript`

However, “latest transcript” is ambiguous. You must specify:
*   For live UI use → `bestTranscription.formattedString`
*   For persistence → reconstruct a normalized transcript from segments (`bestTranscription.segments`), because `formattedString` alone loses timing fidelity necessary for playback highlighting.

**Recommendation:**
Explicitly distinguish:
*   UI-only string (`formattedString`)
*   Persisted string + persisted segments derived from `segments[]`

### 2.2 Segment Model Not Fully Specified

For secure playback, you need at minimum:

```swift
struct TranscriptSegment: Codable {
    let index: Int
    let text: String
    let startTime: TimeInterval
    let duration: TimeInterval
}
```

The ADR should explicitly specify:
*   Segments come from the *final* `bestTranscription`
*   `startTime`/`duration` tied to audio recording start
*   Transcript reconstructed at save-time, not incrementally

### 2.3 Edge Cases Around Restart, Stop, Timeout

SFSpeechRecognizer restarts approximately every 60 seconds.
Rule that should be added:

At ANY terminal event — stop, timeout, error, background transition —
1.  Commit partial to `committedTranscript`
2.  Create final transcript + segments snapshot
3.  Persist them atomically
4.  Then tear down recognition session

### 2.4 Missing Concurrency / Threading Guarantees

Recommended addition:
All transcript state (`committedTranscript`, `currentPartialTranscript`, `segments`) is owned by a `TranscriptionSession` actor.
The UI receives immutable snapshots on `MainActor`.

### 2.5 Persistence Model and Versioning Not Defined

To support secure playback, define a `RecordingSessionRecord`:

```swift
struct RecordingSessionRecord: Codable {
    let id: UUID
    let createdAt: Date
    let audioFilePath: String
    let finalTranscript: String
    let segments: [TranscriptSegment]
    let schemaVersion: Int
}
```

## 3. Required ADR Extension: Secure Recording + Playback

### 3.1 Audio Capture + Transcript Linkage

*   Each recording session produces:
    *   one audio file (e.g., `<session-id>.m4a`)
    *   one `RecordingSessionRecord` with transcript + segments
*   File naming: `audioFile = "<UUID>.m4a"` under `Application Support/Recordings/`
*   Transcript and segments are generated ONLY once: at stopRecording → final snapshot, immutable thereafter.
*   Playback *never* re-runs speech recognition.

### 3.2 Secure Storage Requirements

*   All audio files and transcript/segment metadata stored in app-private directory.
*   Enable Data Protection: `NSFileProtectionCompleteUnlessOpen` (or `NSFileProtectionComplete`).
*   No cloud sync by default.
*   All persistent files must be written atomically.

### 3.3 Deletion + Lifecycle

*   Deleting a recording deletes:
    *   audio file
    *   transcript JSON
    *   segment metadata
*   No soft-delete staging
*   No orphaned files allowed

### 3.4 Playback Rules

Playback uses ONLY the immutable final snapshot:
*   Display `finalTranscript` verbatim
*   No italics, no partials
*   For highlighting per-word:
    ```swift
    currentSegment = segments.last(where: startTime <= currentTime < startTime + duration)
    ```
*   Playback never involves partial buffers or live TimingData.

## 4. Architecture Implementation Plan

### 4.1 Core Rules

For live UI:
*   Use `result.bestTranscription.formattedString` directly.

For persistence:
*   Reconstruct a normalized final transcript string from `result.bestTranscription.segments`.
*   Persist segments with text, startTime, duration relative to the start of the audio session.

### 4.2 Concurrency Model

All transcript state is owned by a `TranscriptionSession` actor (or isolated manager).
UI observes value snapshots delivered on `MainActor`.

### 4.3 Recording & Playback Integration

On stop:
*   Commit partial
*   Generate `finalTranscript` + `segments` from final recognizer result
*   Persist the `RecordingSessionRecord` atomically

Playback uses only these persisted values.

### 4.4 Security & Privacy

*   All audio and transcript data remain fully on-device.
*   Files are stored under `Application Support/Recordings/` with `NSFileProtectionCompleteUnlessOpen`.
*   Record deletions remove audio + transcript data atomically.
