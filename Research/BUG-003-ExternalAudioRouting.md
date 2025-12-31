# BUG-003: External Audio Source Not Routing to TranscriptionEngine

**Date**: 2025-12-13  
**Status**: ✅ FIXED  
**Priority**: CRITICAL  
**Affects**: Secure recording mode, any external audio source

## Problem

When using secure recording mode (or any external audio source), no transcription was happening. The UI showed no text, and logs showed no `[partial]` or `[FINAL]` events from the engine.

## Root Cause

After the TranscriptionEngine refactor, the `SpeechRecognizer.appendAudioBuffer()` method was still trying to append to the old `request` property:

```swift
func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
    processAudioBuffer(buffer: buffer)
    request?.append(buffer)  // ← WRONG: request is nil, engine never receives audio
}
```

The `request` property no longer exists in the new architecture. Audio buffers were being processed for the VU meter but never forwarded to the `TranscriptionEngine`.

## Symptoms

**Console Output:**
```
Starting transcription with timing data via engine... (external source: true)
[LegacyTranscriptionEngine] Recognition task started
[LegacyTranscriptionEngine] Started successfully
```

**Then nothing** - no `[partial]`, no `[FINAL]`, no transcription events.

**User Experience:**
- Recording works (audio file saved)
- VU meter works (audio levels updating)
- **Transcription doesn't work** (no text appears)

## Solution

Forward audio buffers to the `TranscriptionEngine`:

```swift
func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
    processAudioBuffer(buffer: buffer)
    
    // Forward buffer to transcription engine (for external audio source mode)
    Task {
        await transcriptionEngine?.appendAudioBuffer(buffer)
    }
}
```

## Files Changed

- `SpeechDictation/Speech/SpeechRecognizer.swift` - Fixed `appendAudioBuffer()` method

## How It Works

### Secure Recording Flow

1. `SecureRecordingManager.startSecureRecording()` starts:
   - Audio recording via `AudioRecordingManager`
   - Transcription via `speechRecognizer.startTranscribingWithTiming(isExternalAudioSource: true)`

2. `AudioRecordingManager` sets up buffer handler:
   ```swift
   audioRecordingManager.audioBufferHandler = { [weak self] buffer in
       self?.speechRecognizer.appendAudioBuffer(buffer)
   }
   ```

3. `SpeechRecognizer.appendAudioBuffer()` now:
   - Processes buffer for VU meter (RMS level calculation)
   - **Forwards buffer to engine** → `transcriptionEngine?.appendAudioBuffer(buffer)`

4. `LegacyTranscriptionEngine.appendAudioBuffer()`:
   - Appends to recognition request
   - Processes for silence detection
   - Emits transcription events

## Testing

### Before Fix
- ❌ Secure recording: No transcription text
- ❌ External audio source mode: Silent failure

### After Fix
- ✅ Build: Successful
- ⏳ Device test: Pending (should now show transcription text in secure mode)

## Expected Behavior Now

When you start a secure recording and speak:
```
[LegacyTranscriptionEngine] Recognition task started
[LegacyTranscriptionEngine] Started successfully
[partial] text=5ch accum=0ch offset=0.0s segs=1    ← Should appear now!
[partial] text=12ch accum=0ch offset=0.0s segs=2   ← Should appear now!
[SILENCE] 1.6s, will commit on next result
[FINAL] text=12ch accum=0ch ...
[COMMIT] accum: 0ch → 12ch (+12)
```

And the UI should show the transcription text updating in real-time.

## Related Bugs

This bug was introduced during the TranscriptionEngine refactor:
- **BUG-001**: Audio engine lifecycle (fixed 2025-12-13)
- **BUG-002**: Segment timestamp monotonicity (fixed 2025-12-12)
- **BUG-003**: External audio routing (fixed 2025-12-13) ← This fix

## Why This Wasn't Caught Earlier

1. **Unit tests** don't test external audio source mode (they test engine lifecycle in isolation)
2. **Standard recording mode** worked because it uses the engine's internal audio engine
3. **Secure recording mode** is the primary user of external audio source, and wasn't device-tested after refactor

## Prevention

Add integration test:
```swift
func testExternalAudioSource_ReceivesBuffers() async {
    let engine = // create engine with external source
    let buffer = // create test buffer
    
    await engine.appendAudioBuffer(buffer)
    
    // Assert: engine emits transcription event
}
```

## Acceptance Criteria

- [x] Build succeeds
- [x] Code change applied
- [ ] Device test: Secure recording shows transcription text
- [ ] Device test: VU meter + transcription both work simultaneously



