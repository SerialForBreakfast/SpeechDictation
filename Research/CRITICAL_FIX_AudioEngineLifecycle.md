# CRITICAL FIX: Audio Engine Lifecycle

**Date**: 2025-12-13  
**Issue**: Infinite "No speech detected" restart loop after silence detection  
**Root Cause**: Audio engine was being recreated on every recognition task restart

## The Problem

Previous implementation:
```swift
private func startRecognitionTask() async throws {
    // ... recognition task setup ...
    
    // BUG: Audio engine was started INSIDE task restart
    if !isExternalAudioSource {
        try await startAudioEngine()  // ← WRONG
    }
}
```

**What was happening:**
1. First utterance: Audio engine starts, recognition works
2. Silence detected → restart recognition task
3. **Audio engine recreated** → breaks audio pipeline
4. No audio reaches recognizer → "No speech detected" error
5. Error triggers another restart → infinite loop

## The Fix

Audio engine must run **continuously** for the entire session. Only the recognition task/request should restart.

### Before
```
Session Start
  ├─ Start Recognition Task
  │   ├─ Create Request
  │   ├─ Create Task
  │   └─ Start Audio Engine  ← WRONG (restarts on every task restart)
  └─ On Silence
      └─ Restart Recognition Task
          └─ Recreate Audio Engine  ← Pipeline breaks here
```

### After
```
Session Start
  ├─ Start Audio Engine ONCE  ← Stays running entire session
  └─ Start Recognition Task
      ├─ Create Request
      └─ Create Task

On Silence
  └─ Restart Recognition Task ONLY
      ├─ Stop old task
      ├─ Create new request
      └─ Create new task
      (Audio engine keeps running, continues feeding buffers)
```

## Code Changes

### 1. Start audio engine at session start
```swift
func start() async throws {
    state = .starting
    sessionStartTime = Date()
    
    // Start audio engine ONCE for the entire session
    if !isExternalAudioSource {
        try await startAudioEngine()
    }
    
    // Start the recognition task
    try await startRecognitionTask()
    
    state = .running
}
```

### 2. Remove audio engine start from task restart
```swift
private func startRecognitionTask() async throws {
    // Stop any existing task (but NOT the audio engine)
    await stopRecognitionTask()
    
    // ... recognizer setup ...
    
    // Create recognition request
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    
    // Start recognition task
    recognitionTask = recognizer.recognitionTask(with: request) { ... }
    
    // Audio engine already running - don't restart it!
}
```

### 3. Stop audio engine only at session stop
```swift
func stop() async {
    state = .stopping
    
    // Stop recognition
    await stopRecognitionTask()
    
    // Stop audio engine
    audioEngine?.stop()
    audioEngine?.inputNode.removeTap(onBus: 0)
    audioEngine = nil
    
    state = .stopped
}
```

## Reference

This fix aligns with best practices from Apple's Speech API reference implementations:

**From GitReferences.txt (lines 238-239):**
> **"Keep audio engine alive" vs "restart on silence":**
> - Restarting can be dangerous if your accumulation store uses startTime-relative merges.

**From GitReferences.txt (line 259):**
> **"ensure your audio engine is still running"**

**From AuralKit and other reference repos:**
- Audio capture layer stays alive for entire session
- Only the recognizer task/request restarts on silence or errors
- This is the standard pattern for long-form transcription

## Testing

All unit tests pass after this fix:
- `TranscriptAccumulationTests` - validates segment merging logic
- `SpeechDictationTests` - validates engine lifecycle

**Manual testing should show:**
```
[LegacyTranscriptionEngine] Audio engine started      ← Once at session start
[LegacyTranscriptionEngine] Recognition task started
[SILENCE] 1.5s, will commit on next result
[COMMIT] accum: 0ch → 50ch (+50)
[RESTART] accum=50ch, waiting 350ms...
[LegacyTranscriptionEngine] Recognition task started  ← Task restarts (not audio!)
[partial] text=75ch accum=50ch ...                    ← New speech works!
```

**No more:**
- "No speech detected" infinite loops
- Audio pipeline failures after restart
- Lost transcription after pauses

## Next Steps

1. Test on physical device with real speech and pauses
2. Verify 60-minute sessions work without errors
3. Monitor for any audio engine resource leaks (unlikely but worth checking)

## Related Files
- `SpeechDictation/Speech/LegacyTranscriptionEngine.swift`
- `Research/GitReferences.txt` (reference patterns)
- `Research/ADR-GitExamplesForImprovement.txt` (architectural guidance)
