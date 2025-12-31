# Hybrid Transcription Engine Implementation

## Status: IN PROGRESS

**Created:** 2025-12-13  
**Updated:** 2025-12-13

## Overview

Implementing a hybrid transcription architecture that supports long-form conversation with natural pauses across iOS versions:
- **iOS 26+**: Modern `SpeechAnalyzer` + `SpeechTranscriber` API
- **iOS < 26**: Enhanced `SFSpeechRecognizer` with RMS-based silence detection

## Architecture

### Core Components

#### 1. TranscriptionEngine Protocol (`TranscriptionEngine.swift`)
- ✅ Protocol abstraction for transcription backends
- ✅ Event-based streaming API (`AsyncStream<TranscriptionEvent>`)
- ✅ Sendable-conforming for Swift 6 concurrency
- ✅ Configuration with silence detection parameters
- ✅ Factory pattern for platform-appropriate engine selection

#### 2. ModernTranscriptionEngine (`ModernTranscriptionEngine.swift`)
- ✅ Actor-isolated for thread safety
- ✅ Uses iOS 26+ `SpeechAnalyzer` + `SpeechTranscriber`
- ✅ Built-in pause handling via `SpeechDetector`
- ✅ Accumulates transcript across session
- 🚧 **TODO**: Actual `SpeechAnalyzer` API integration (placeholder types for now)
- 🚧 **TODO**: Model download UX handling

#### 3. LegacyTranscriptionEngine (`LegacyTranscriptionEngine.swift`)
- ✅ Actor-isolated for thread safety
- ✅ RMS-based silence detection (configurable threshold/duration)
- ✅ Auto-restart on silence, isFinal, or 55-second safety timer
- ✅ Prevents regression in partial results
- ✅ Accumulates transcript across task restarts
- ✅ Proper error handling with restart recovery

### Event Stream Design

```swift
enum TranscriptionEvent {
    case partial(text: String, segments: [TranscriptionSegment])
    case final(text: String, segments: [TranscriptionSegment])
    case audioLevel(level: Float)  // For VU meter
    case error(error: Error)
    case stateChange(state: TranscriptionEngineState)
}
```

## Integration Plan

### Phase 1: Core Integration (IN PROGRESS)
- ✅ Create protocol and engine implementations
- 🚧 Add files to Xcode project
- 🚧 Wire `LegacyTranscriptionEngine` into existing `SpeechRecognizer`
- 🚧 Update `SpeechRecognizer+Timing` to use new engine
- 🚧 Ensure `TimingDataManager` receives segments correctly

### Phase 2: Testing & Validation
- Test legacy engine on current iOS with long pauses
- Verify transcript accumulation across restarts
- Validate timing data continuity
- Test audio level/VU meter integration
- Test secure recording with new engine

### Phase 3: iOS 26+ Path (Future)
- Integrate actual `SpeechAnalyzer` APIs when SDK available
- Test on iOS 26 beta/release
- Validate modern engine behavior
- Document platform differences

### Phase 4: Polish & Documentation
- Update ADR documents
- Add comprehensive inline documentation
- Create migration guide
- Performance optimization

## Key Design Decisions

### 1. Actor Isolation
Both engines use Swift actors for state management:
- **Benefits**: Thread-safe by default, modern Swift concurrency
- **Trade-off**: All calls must be async, requires Task context

### 2. Accumulation Strategy
```swift
accumulatedTranscript + " " + currentPartialTranscript = displayText
```
- Partials replace (not append) within current task
- Finals commit to accumulated buffer
- Restarts continue accumulation seamlessly

### 3. Silence Detection (Legacy Engine)
```swift
Configuration:
- silenceThreshold: 0.15 (normalized 0.0-1.0)
- silenceDuration: 1.5 seconds
- maxTaskDuration: 55 seconds (Apple's guidance)
```

RMS calculation:
```swift
rms = sqrt(mean(samples^2))
rmsDB = 20 * log10(rms)
normalized = clamp((rmsDB + 60) / 60, 0, 1)
```

### 4. Restart Strategy (Legacy Engine)
Restarts triggered by:
1. `result.isFinal` (end of utterance)
2. Recognition errors (except cancellation)
3. Safety timer at 55 seconds
4. *(Future: Explicit silence detection after N seconds)*

Restart includes 350ms delay to prevent tight loops.

### 5. Error Handling
- Ignore cancellation errors (code 301) to prevent re-entrant teardown
- Auto-restart on recoverable errors
- Expose errors via event stream for UI notification

## Testing Strategy

### Unit Tests
- [ ] Engine lifecycle (start/stop/restart)
- [ ] Transcript accumulation correctness
- [ ] Silence detection thresholds
- [ ] Error recovery paths
- [ ] State machine transitions

### Integration Tests
- [ ] End-to-end transcription with pauses
- [ ] Timing data continuity across restarts
- [ ] VU meter updates
- [ ] Secure recording compatibility

### Manual Tests
- [ ] 1-hour conversation with multiple pauses
- [ ] Background/foreground transitions
- [ ] Microphone permission flows
- [ ] Audio interruptions (calls, notifications)

## Known Limitations & Future Work

### Current Limitations
1. **iOS 26 implementation is placeholder** - needs actual SDK when available
2. **No model download UX** - will be needed for SpeechAnalyzer path
3. **Silence detection not yet triggering restarts** - logic in place but needs wiring
4. **No speaker diarization** - out of scope for MVP

### Future Enhancements
1. Expose configuration via UI (silence threshold tuning)
2. Add "ambient noise calibration" for adaptive thresholds
3. Implement buffered overlap for smoother segment boundaries
4. Add quality metrics (confidence scores, stability indicators)
5. Support external STT engines (Whisper fallback)

## Files Created

```
SpeechDictation/Speech/
├── TranscriptionEngine.swift           ✅ Protocol + types
├── ModernTranscriptionEngine.swift     ✅ iOS 26+ implementation
└── LegacyTranscriptionEngine.swift     ✅ iOS < 26 implementation
```

## Next Steps

1. **Add new files to Xcode project** (via project.pbxproj or Xcode GUI)
2. **Create SpeechRecognizer adapter** to consume engine events
3. **Wire into existing recording flows** (standard + secure)
4. **Test with real pauses** on device
5. **Document ADR updates**

## References

- **ADR**: `Research/SpeechADR.txt` (Option C - Hybrid approach)
- **Inspiration**: [Compiler-Inc/Transcriber](https://github.com/Compiler-Inc/Transcriber)
- **Apple Docs**: [SpeechTranscriber](https://developer.apple.com/documentation/speech/speechtranscriber)
- **WWDC Session**: [WWDC25-277](https://developer.apple.com/wwdc25/277)
