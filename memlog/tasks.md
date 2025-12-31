# SpeechDictation - Task Management

Last updated: 2025-12-31

## Current Focus
- Validate long-form transcription continuity on device (pause and resume).
- Verify secure recording flow and playback accuracy.
- Validate export formats on real sessions.

## In Progress
- ModernTranscriptionEngine availability gating (TODO in TranscriptionEngine.swift).
- Camera sharing action (TODO in CameraExperienceView.swift).
- Camera model retry flow for load failures (TODO in CameraErrorView).

## Backlog
- Deterministic audio fixture test harness for transcription.
- Incremental transcript persistence for long sessions.
- Model download UX for the camera experience.

## Stable / Implemented
- Hybrid transcription engine scaffolding (Legacy and Modern engines).
- Export manager for text and timing formats.
- Build and test automation in `utility/`.
