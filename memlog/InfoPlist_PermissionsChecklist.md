# InfoPlist_PermissionsChecklist.md

## Required Keys for App Store Submission (AI Ears)

Ensure the following keys are added to your `Info.plist`:

- `NSMicrophoneUsageDescription`
  - **Value**: “AI Ears requires access to the microphone to record and transcribe conversations.”

- `NSFaceIDUsageDescription` (if using Face ID for secure access)
  - **Value**: “Used to secure your private recordings from unauthorized access.”

- `NSAppleMusicUsageDescription` (optional, only if you plan to analyze media)
  - **Value**: “Used for analyzing or transcribing media content on-device.”

- `UIBackgroundModes`
  - **Value**: Include `audio` if supporting background recording.

- `NSUserTrackingUsageDescription` — Should **not** be included unless advertising/tracking (we recommend avoiding this).

## App Store Metadata Recommendations

- **Privacy Policy URL**: Host your `PrivacyPolicy.md` as an HTTPS-accessible page.
- **App Description**: State “AI Ears records and transcribes conversations privately on-device with full user control and local storage.”
- **Keywords**: Accessibility, Transcription, Private Recording, Deaf and Hard of Hearing, Speech to Text
