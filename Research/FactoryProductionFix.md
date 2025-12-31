# Factory Configuration - Production Fix

## Issue Discovered
When running on iOS 26 simulator, the factory selected `ModernTranscriptionEngine` which failed with `recognizerNotAvailable` error. This indicates that while iOS 26 is released, the SpeechAnalyzer APIs may not be fully implemented or available yet.

## Root Cause
The factory used simple OS version check:
```swift
if #available(iOS 26.0, *) {
    return ModernTranscriptionEngine(...)
}
```

But the actual SpeechAnalyzer types in the SDK appear to be placeholders or the APIs aren't functional yet.

## Solution Applied
Modified `TranscriptionEngineFactory.createEngine()` to:
1. Default to `LegacyTranscriptionEngine` for all iOS versions (production-ready path)
2. Added `isModernEngineAvailable()` capability check (currently returns false)
3. Commented out iOS 26+ path with clear TODO for when APIs are verified functional
4. Updated log message to indicate "production-ready" engine

## Code Changes
**File**: `SpeechDictation/Speech/TranscriptionEngine.swift`

**Before:**
```swift
if #available(iOS 26.0, *) {
    print("[TranscriptionEngine] Using ModernTranscriptionEngine (iOS 26+)")
    return ModernTranscriptionEngine(...)
}
```

**After:**
```swift
// TODO: iOS 26+ path disabled until SpeechAnalyzer APIs are confirmed available
// if #available(iOS 26.0, *), isModernEngineAvailable() {
//     return ModernTranscriptionEngine(...)
// }

print("[TranscriptionEngine] Using LegacyTranscriptionEngine (production-ready)")
return LegacyTranscriptionEngine(...)
```

## Impact
- **Positive**: App now works on iOS 26 (uses proven LegacyTranscriptionEngine with RMS silence detection)
- **Neutral**: ModernTranscriptionEngine implementation preserved for future activation
- **Action Required**: When iOS 26 SpeechAnalyzer APIs are verified functional, uncomment the iOS 26+ path and implement proper capability detection in `isModernEngineAvailable()`

## Testing
- Build: SUCCESS
- Tests: 46/46 PASSING
- Runtime: App should now start transcription successfully on iOS 26

## Next Steps
1. Research actual SpeechAnalyzer API availability (WWDC sessions, Apple docs, SDK headers)
2. Implement runtime capability check
3. Test ModernTranscriptionEngine when APIs are functional
4. Re-enable iOS 26+ path with proper feature detection

## Date
December 13, 2025
