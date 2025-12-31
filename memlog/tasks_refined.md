# SpeechDictation - Task Management (Refined)

Last updated: 2025-12-31

## Immediate Validation
- Long-form transcription device test with multiple pauses.
- Verify secure recording: live transcript, stop, and playback.
- Export validation: SRT, VTT, TTML, JSON on real sessions.

## Engineering TODOs (Tracked in Code)
- Add runtime availability check for SpeechAnalyzer and gate ModernTranscriptionEngine.
- Implement camera share action in CameraExperienceView.
- Implement model retry logic in CameraErrorView.

## Quality and Tests
- Add deterministic audio fixture tests for the transcription pipeline.
- Extend TimingDataManager coverage for large transcripts.
- Add a UI test that navigates EntryView to both experiences.

## Backlog
- Incremental persistence for long sessions.
- Model download UX (progress, retry, failure states).
- Camera experience polish (error copy, fallback states).
