# UX/UI Flow Documentation - SpeechDictation iOS

## Overview
This document describes the current UX flow and screen responsibilities. Mermaid diagrams are not included yet; add them here when the flow changes or when a visual diagram is needed.

## Primary User Flows

### 1. Entry and Experience Selection
- EntryView presents two paths: Audio Transcription (primary) and Live Camera Input (experimental).
- Selecting a path navigates to the respective experience.

### 2. Audio Transcription
- ContentView provides start/stop transcription, secure recording, and export actions.
- SettingsView exposes theme, text size, mic sensitivity, and camera settings.
- NativeStyleShareView handles export format selection and iOS share sheet.

### 3. Camera Experience (Experimental)
- CameraExperienceView checks permissions and gates the camera flow.
- CameraPermissionsView handles permission states and user guidance.
- CameraSceneDescriptionView displays the camera feed with detection overlays.
- CameraSettingsView provides toggles for detection and accessibility options.

### 4. Model Management
- CurrentModelsView shows loaded models and active selections.
- ModelManagementView provides model browsing and download actions.

## Key States and Transitions
- Recording vs idle states in ContentView.
- Secure recording state (separate control path from live transcription).
- Camera permission states: authorized, denied, restricted, not determined.

## Notes and Follow-ups
- Camera sharing is not implemented yet (TODO in CameraExperienceView).
- Model retry logic for camera errors is still TODO.
- Add Mermaid diagrams when the flow changes significantly.

## Related Documentation
- `README.md`
- `memlog/tasks.md`
- `memlog/Requirements.txt`
- `memlog/directory_tree.md`
