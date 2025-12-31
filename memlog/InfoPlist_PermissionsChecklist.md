# Info.plist Permissions Checklist - Speech Dictation

## Required Keys

- `NSMicrophoneUsageDescription`
  - Value: "Speech Dictation uses the microphone to convert your speech to text with real-time transcription and secure private recording."

- `NSCameraUsageDescription`
  - Value: "Speech Dictation uses the camera to provide live object detection and scene description for accessibility and content creation features."

- `NSFaceIDUsageDescription` (optional but enabled in the project)
  - Value: "Speech Dictation uses Face ID to protect your private recordings and ensure only you can access sensitive transcribed content."

- `UIBackgroundModes`
  - Include `audio` if background recording is supported.

## Networking and ATS

- `NSAppTransportSecurity` currently allows arbitrary loads. Tighten this before release if model downloads or external requests can be restricted to HTTPS domains.

## App Store Metadata Recommendations

- Provide a hosted Privacy Policy URL.
- Clearly state on-device speech recognition and local storage in the app description.
- If camera features are optional, describe them as experimental and permission-gated.
