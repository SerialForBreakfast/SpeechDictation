# SpeechDictation iOS - Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- SecurePlaybackView exposes an explicit public initializer for external construction.

### Fixed
- Fixed StateObject misuse in SecurePlaybackView.
- Resolved concurrent engine conflicts during secure recording.
- Fixed undefined recordingFormat reference in SpeechRecognizer+Timing.
- Corrected UUID regeneration behavior when decoding Codable models.
