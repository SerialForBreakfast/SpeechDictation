# SpeechRecognizer Integration Plan

## Current State Analysis

### Existing Architecture
- `SpeechRecognizer` directly uses `SFSpeechRecognizer` and manages:
  - Recognition task lifecycle
  - Transcript accumulation across restarts
  - Audio engine setup
  - Published properties for UI binding
- `SpeechRecognizer+Timing` extends with timing data capture
- Both use similar patterns for auto-restart on isFinal/error

### New Architecture (Engines)
- `TranscriptionEngine` protocol with event streaming
- `LegacyTranscriptionEngine` (iOS < 26) with RMS silence detection
- `ModernTranscriptionEngine` (iOS 26+) with SpeechAnalyzer
- Factory pattern for platform selection

## Integration Strategy

### Phase 1: Wire Legacy Engine (CURRENT)
Replace `SpeechRecognizer`'s direct `SFSpeechRecognizer` usage with `LegacyTranscriptionEngine`:

1. **Add Engine Property**
   ```swift
   private var transcriptionEngine: (any TranscriptionEngine)?
   private var engineEventTask: Task<Void, Never>?
   ```

2. **startTranscribing() Changes**
   - Create engine via factory
   - Subscribe to event stream
   - Map events to published properties
   - Remove direct SFSpeechRecognizer setup

3. **Event Stream Handling**
   ```swift
   for await event in engine.eventStream() {
       switch event {
       case .partial(text, segments):
           // Update transcribedText
       case .final(text, segments):
           // Update transcribedText, maybe merge segments
       case .audioLevel(level):
           // Update currentLevel
       case .error:
           // Handle error
       case .stateChange:
           // Optional: track state
       }
   }
   ```

4. **stopTranscribing() Changes**
   - Cancel event task
   - Stop engine
   - Clean up

### Phase 2: Wire Timing Extension
Update `SpeechRecognizer+Timing` to use engines:

1. **startTranscribingWithTiming() Changes**
   - Similar to startTranscribing() but with timing session
   - Subscribe to same event stream
   - Pass segments to TimingDataManager

2. **processTimingData() Integration**
   - Events already contain segments
   - Just forward to TimingDataManager.mergeSegments()

### Phase 3: Remove Redundant Code
After both paths use engines:
- Remove old auto-restart logic (engines handle it)
- Remove accumulatedTranscript management (engines handle it)
- Keep only UI-specific logic in SpeechRecognizer

## Implementation Steps

### Step 1: Add Engine Infrastructure
- [ ] Add engine property and event task
- [ ] Add helper to start engine and subscribe to events
- [ ] Add helper to stop engine and cleanup

### Step 2: Update startTranscribing()
- [ ] Create engine via factory
- [ ] Subscribe to event stream
- [ ] Map events to UI updates
- [ ] Test basic transcription works

### Step 3: Update startTranscribingWithTiming()
- [ ] Similar changes for timing path
- [ ] Wire segments to TimingDataManager
- [ ] Test timing data is captured

### Step 4: Cleanup
- [ ] Remove unused code
- [ ] Update comments
- [ ] Run tests

## Key Considerations

### Concurrency
- Engine is actor-isolated
- Event stream is nonisolated (can be called from any context)
- UI updates must happen on @MainActor
- Use DispatchQueue.main.async or Task { @MainActor in }

### Backward Compatibility
- Keep same public API for SpeechRecognizer
- Maintain same published properties
- Ensure existing UI code doesn't break

### Error Handling
- Engine errors come via event stream
- Still need to handle audio engine failures
- Maintain same error behavior for UI

### Testing
- Existing tests should pass
- Engine handles pause scenarios
- Timing data flows correctly

## Success Criteria
- [ ] Build succeeds
- [ ] All unit tests pass
- [ ] Transcription works with natural pauses
- [ ] Timing data is captured correctly
- [ ] No regressions in existing functionality
