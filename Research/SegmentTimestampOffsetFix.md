# Critical Fix: Segment Timestamp Offset Across Task Restarts

## Issue
REQ-001 REGRESSION: Transcription segments were being replaced instead of accumulated after pauses.

## Root Cause
`LegacyTranscriptionEngine` was sending segments with timestamps relative to the CURRENT recognition task (which resets to 0 on each restart), not the overall session. This caused:
1. Segments from different utterances to have overlapping timestamps (0-5s, 0-3s, 0-4s)
2. TimingDataManager.mergeSegments() to deduplicate by start time, keeping only the LATEST segment
3. Result: Only the most recent utterance's segments survived, all previous ones deleted

## The Fix
Added session timeline offset calculation in `LegacyTranscriptionEngine.handleRecognitionResult()`:

```swift
// Calculate time offset for this task relative to overall session
// This ensures timestamps are monotonic across task restarts
let taskOffset: TimeInterval
if let taskStart = taskStartTime {
    taskOffset = taskStart.timeIntervalSince(sessionStartTime)
} else {
    taskOffset = 0
}

// Convert segments with offset adjustment
let segments = result.bestTranscription.segments.map { segment in
    TranscriptionSegment(
        text: segment.substring,
        startTime: taskOffset + segment.timestamp,
        endTime: taskOffset + segment.timestamp + segment.duration,
        confidence: segment.confidence
    )
}
```

## Timeline Example

### Before Fix (BROKEN)
```
Task 1 (0-5s):   segments: [0.0-1.5s "Hello", 1.5-3.0s "world"]
  → pause + restart
Task 2 (5-8s):   segments: [0.0-1.0s "How", 1.0-2.5s "are you"]  ← OVERWRITES!
  → mergeSegments keeps only Task 2 (same startTime keys)
```

### After Fix (CORRECT)
```
Task 1 (0-5s):   segments: [0.0-1.5s "Hello", 1.5-3.0s "world"]
  → pause + restart (taskStartTime = 5s)
Task 2 (5-8s):   segments: [5.0-6.0s "How", 6.0-7.5s "are you"]  ← APPENDS!
  → mergeSegments keeps both (different startTime keys)
```

## Properties Used
- `sessionStartTime: Date` - Set once in start(), marks overall recording start
- `taskStartTime: Date?` - Updated each time startRecognitionTask() is called
- `taskOffset = taskStartTime.timeIntervalSince(sessionStartTime)` - Offset for current task

## Files Changed
- `SpeechDictation/Speech/LegacyTranscriptionEngine.swift` - Added offset calculation in handleRecognitionResult()
- `memlog/Requirements.txt` - Created comprehensive requirements document
- `SpeechDictationTests/TranscriptAccumulationTests.swift` - Created test suite for REQ-001

## Testing
**Build**: SUCCESS
**Expected Behavior**: 
- Segments from first utterance: startTime 0-5s
- Segments from second utterance: startTime 5-10s (not 0-5s again)
- TimingDataManager segments count increases across utterances
- UI transcribedText accumulates across utterances

## Verification Steps
1. Start recording
2. Speak "Hello world"
3. Pause 2+ seconds (watch for "Silence detected")
4. Speak "How are you"
5. Check console: "Updated segments: count=X" should INCREASE from first utterance count
6. Check UI: Should show "Hello world How are you" (accumulated)
7. Export JSON: Verify timestamps are monotonically increasing, no overlaps

## Related
- This is the SAME pattern that existed in old SpeechRecognizer+Timing.swift (lines 183-185)
- The old code had `timingRecognitionTimeOffset` for exactly this purpose
- When migrating to engines, this offset logic was accidentally omitted

## Date
December 13, 2025
