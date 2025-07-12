# SpeechDictation iOS - Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Build & Test Automation System** - Comprehensive development workflow automation
  - `utility/build_and_test.sh` - Full project validation with detailed reporting
  - `utility/quick_iterate.sh` - Fast iteration script for rapid development cycles
  - `utility/README.md` - Comprehensive documentation and usage guide
  - Timestamped reports in `build/reports/` with performance metrics
  - Error handling with system information capture for debugging
  - Support for both simulator and device testing
  - Integration with development workflow for iterative improvement
- **Enhanced Export Functionality** - Professional timing format support
  - Added SRT, VTT, TTML, and JSON export formats for timing data
  - Enhanced NativeStyleShareView with format selection interface
  - Audio + timing data export for professional workflows
  - Improved UI/UX for easy format selection between text and timing formats
- **Project Expansion: Live Camera Feed with Audio Descriptions** - Major new feature direction
  - Updated README.md with comprehensive camera feed and accessibility goals
  - Added TASK-018: Live Camera Feed with Audio Descriptions (12-16 hours estimated)
  - Added TASK-019: Enhanced Audio Descriptions & Accessibility (8-12 hours estimated)
  - Expanded project scope from speech dictation to accessibility platform
  - Planned components: CameraManager, AudioDescriptionGenerator, VisualAccessibilityProcessor
  - Target completion: January 2025 for camera feed functionality
- **Updated Project Documentation** - Comprehensive memlog updates
  - Updated tasks.md with new camera feed priorities and project evolution section
  - Updated directory_tree.md with planned camera components and accessibility features
  - Updated changelog.md with latest project expansion details
  - Combined README information with existing task structure
- Comprehensive task list with 19 major feature tasks identified (3 new camera-related tasks)
- Project structure documentation in memlog/directory_tree.md  
- This changelog for tracking project evolution
- **TASK-001: Export & Share Functionality** - Complete implementation
  - Export button in main UI (positioned left of settings button with 10px padding)
  - ExportManager service with support for plain text, RTF, and markdown formats
  - iOS share sheet integration for sharing to other apps
  - Copy to clipboard functionality
  - Save to Files app integration
  - Timestamp formatting and metadata support
- **Intelligent Autoscroll System** - Complete implementation
  - Auto-scroll when user is at bottom and new text arrives
  - Stop auto-scroll when user manually scrolls up
  - "Jump to Live" button appears when user scrolls away from bottom
  - Resume auto-scroll when user returns to bottom
  - Smooth animations for scroll movements and button transitions
- **TASK-017: Audio Recording with Timing Data** - Complete implementation
  - High-quality audio recording with configurable quality settings
  - Precise timing data capture with millisecond precision
  - Multiple export formats (SRT, VTT, TTML, JSON) for video editing workflows
  - Synchronized audio/text playback with seek-to-text functionality
  - Playback speed controls (0.5x, 1x, 1.5x, 2x)
  - Session persistence and management
  - Simulator compatibility with graceful fallbacks and error handling

### Changed
- **Project Scope Evolution**: Transformed from speech dictation app to comprehensive accessibility platform
- **Priority Matrix**: Updated to include new camera feed tasks as critical priorities
- **README.md**: Completely updated with camera feed goals and accessibility features
- **Task Organization**: Reorganized tasks to reflect expanded project scope and new priorities
- **ExportManager.swift** - Enhanced with comprehensive timing format support
  - Added `TimingExportFormat` enum with SRT, VTT, TTML, JSON options
  - Implemented format-specific generation methods with proper timing handling
  - Added audio + timing export functionality for professional workflows
  - Enhanced error handling and validation for export operations
- **NativeStyleShareView.swift** - Improved UI/UX for format selection
  - Added support for both basic text formats and professional timing formats
  - Implemented adaptive interface based on available data (text vs timing)
  - Enhanced user experience with clear format descriptions and icons
  - Added audio export option when recording is available
- **SpeechRecognitionViewModel.swift** - Updated export methods for new API
  - Modified export functions to use new ExportManager timing format API
  - Updated ContentView integration to pass timing session data
  - Enhanced error handling for export operations

### Fixed
- Added missing AVFoundation import to SpeechRecognizer.swift to resolve linter errors
- Added ExportManager.swift to Xcode project target membership
- Replaced broken CustomShareView with NativeStyleShareView for better iOS compatibility
- **Simulator Compatibility**: Fixed audio hardware configuration issues in iOS Simulator
  - Added simulator-specific audio format handling with fallback options
  - Implemented proper error handling for audio session configuration
  - Added graceful degradation when audio engine fails to start in simulator
  - Fixed "Input HW format is invalid" crashes with compatible audio formats
- **Audio Session Configuration Tests** - Corrected test implementation
  - Fixed `isOtherAudioPlaying` usage (was checking wrong property)
  - Updated tests to properly validate audio session activation
  - Added proper error handling for session configuration
  - Enhanced interruption handling tests with realistic scenarios
- **Export Format Generation Tests** - Improved test coverage and compatibility
  - Replaced iOS 16+ Regex API with NSRegularExpression for iOS 15+ compatibility
  - Enhanced test validation for SRT, VTT, TTML, and JSON formats
  - Added comprehensive format metadata testing
  - Improved error handling for invalid timing data scenarios

### Technical Debt
- Identified missing requestAuthorization() and configureAudioSession() scope issues
- Need to implement proper dependency injection throughout codebase
- Require async/await pattern adoption across components
- **New Technical Requirements**: Camera permission handling and AVFoundation camera integration
- **Accessibility Compliance**: Need to implement VoiceOver support and accessibility features

## [1.2.0] - Accessibility Platform Foundation

### Added
- **Project Evolution Documentation**: Comprehensive updates to reflect accessibility platform goals
- **Camera Feed Planning**: Detailed task breakdown for live camera feed implementation
- **Audio Description System**: Planned accessibility features for visual content
- **Enhanced Export Capabilities**: Professional formats for content creation workflows
- **TimingData.swift**: Comprehensive timing data models for audio synchronization
- **TimingDataManager.swift**: Service for timing data management and persistence
- **AudioRecordingManager.swift**: High-quality audio recording with native format detection
- **AudioPlaybackManager.swift**: Synchronized audio/text playback with seek functionality
- **SpeechRecognizer+Timing.swift**: Extension for precise timing data capture
- **Enhanced ExportManager**: Extended with timing export formats (SRT, VTT, TTML, JSON)

### Features Working
- Live speech-to-text transcription from microphone with millisecond precision
- Real-time audio buffer processing and waveform display
- High-quality audio recording with native format detection
- Multiple export formats (SRT, VTT, TTML, JSON) for video editing workflows
- Synchronized audio/text playback with seek-to-text functionality
- Theme switching (Light, Dark, High Contrast)
- Adjustable transcription text size
- Audio volume control
- Permission handling for microphone and speech recognition
- Audio session configuration for recording
- **Export and sharing functionality** with multiple format support
- **Intelligent autoscroll system** with user interaction detection
- **Custom sharing interface** to avoid unwanted third-party extensions
- **Simulator compatibility** with graceful fallbacks and error handling

### Known Issues
- No text editing capabilities for transcription correction
- Lack of recording session management (pause/resume)
- Limited error handling and recovery mechanisms
- Missing background recording capability
- Basic waveform needs enhancement
- **Camera feed functionality not yet implemented** (planned for TASK-018)
- **Audio descriptions not yet implemented** (planned for TASK-019)

### Architecture
- Modular extension-based design for SpeechRecognizer
- Clean separation of UI, Services, Models, and Speech recognition layers
- Singleton pattern for shared services (CacheManager, DownloadManager, AlertManager, ExportManager, TimingDataManager, AudioRecordingManager, AudioPlaybackManager)
- Protocol-ready structure for future dependency injection
- **Prepared for camera integration** with planned CameraManager service

### Testing
- Basic unit test framework in place
- Some test cases implemented for core functionality
- UI test structure available but minimal implementation
- **Camera testing framework needed** for upcoming camera functionality

---

## [1.1.0] - Audio Recording with Timing Data

### Added
- **Models Directory**: Added for better data model organization
- **Enhanced UI Components**: 
  - TextSizeSettingView for text size configuration
  - ThemeSettingView for theme selection interface
  - MicSensitivityView for microphone sensitivity controls
  - VUMeterView for volume unit meter visualization
  - NativeStyleShareView for custom sharing interface
- **ExportManager Service**: Complete export and sharing functionality
- **Intelligent Autoscroll**: Smart scroll behavior with "Jump to Live" functionality
- Real-time speech recognition using Apple's Speech framework
- Basic SwiftUI interface with start/stop recording functionality
- Audio waveform visualization component
- Settings panel with font size and theme customization
- Audio session management and permission handling
- MP3 to M4A audio conversion capability
- Cache management for audio files
- Download manager for remote audio files
- Alert manager for sharing functionality
- Basic unit test structure
- MVVM architecture with ObservableObject pattern

### Features Working
- Live speech-to-text transcription from microphone
- Real-time audio buffer processing and waveform display
- Theme switching (Light, Dark, High Contrast)
- Adjustable transcription text size
- Audio volume control
- Permission handling for microphone and speech recognition
- Audio session configuration for recording
- **Export and sharing functionality** with multiple format support
- **Intelligent autoscroll system** with user interaction detection
- **Custom sharing interface** to avoid unwanted third-party extensions

### Known Issues
- No text editing capabilities for transcription correction
- Lack of recording session management (pause/resume)
- No audio playback for recorded content
- Limited error handling and recovery mechanisms
- Missing background recording capability
- Basic waveform needs enhancement

### Architecture
- Modular extension-based design for SpeechRecognizer
- Clean separation of UI, Services, Models, and Speech recognition layers
- Singleton pattern for shared services (CacheManager, DownloadManager, AlertManager, ExportManager)
- Protocol-ready structure for future dependency injection

### Testing
- Basic unit test framework in place
- Some test cases implemented for core functionality
- UI test structure available but minimal implementation

---

## Priority Implementation Schedule

### Phase 1 (Weeks 1-2) - Critical Features
- [x] ~~TASK-001: Export & Share Functionality~~ **COMPLETED**
- [x] ~~TASK-001A: Intelligent Autoscroll System~~ **COMPLETED**
- [x] ~~TASK-017: Audio Recording with Timing Data~~ **COMPLETED**
- [ ] **TASK-018: Live Camera Feed with Audio Descriptions** - NEW PRIORITY
- [ ] **TASK-019: Enhanced Audio Descriptions & Accessibility** - NEW PRIORITY
- [ ] TASK-002: Text Editing & Correction  
- [ ] TASK-011: Error Handling & Recovery

### Phase 2 (Weeks 3-4) - Core User Experience
- [ ] TASK-003: Recording Session Management
- [ ] TASK-004: Audio Playback & Review
- [ ] TASK-008: Background Recording & App State Management

### Phase 3 (Month 2) - Enhanced Features
- [ ] TASK-005: Enhanced Waveform Visualization
- [ ] TASK-006: Advanced Settings & Preferences
- [ ] TASK-009: Enhanced UI/UX Design

### Future Phases (Month 3+) - Advanced Features
- [ ] TASK-014: AI-Powered Features
- [ ] TASK-015: Collaboration Features
- [ ] TASK-016: Usage Analytics & Insights

---

*Changelog maintained according to Swift-specific requirements and project guidelines*
*Last Updated: December 19, 2024*

## Phase 6: Project Expansion - Accessibility Platform

### 2024-12-19 - Camera Feed & Accessibility Planning
- **EXPANDED** project scope from speech dictation to comprehensive accessibility platform
- **ADDED** TASK-018: Live Camera Feed with Audio Descriptions (12-16 hours estimated)
- **ADDED** TASK-019: Enhanced Audio Descriptions & Accessibility (8-12 hours estimated)
- **UPDATED** README.md with comprehensive camera feed goals and accessibility features
- **REORGANIZED** task priorities to reflect new camera feed functionality
- **PLANNED** new components: CameraManager, AudioDescriptionGenerator, VisualAccessibilityProcessor
- **TARGETED** January 2025 completion for camera feed functionality

**Project Evolution:**
- From simple speech dictation to accessibility and content creation platform
- Combines real-time speech recognition, live camera feed processing, and audio descriptions
- Positions app for content creators, accessibility users, educators, and professionals
- Maintains privacy-first approach with all processing on-device

**Status**: Planning phase complete, ready for camera feed implementation
**Next Steps**: Begin TASK-018 implementation with CameraManager service

---

## Phase 5: Audio Recording with Timing Data Implementation

### 2024-12-19 - TASK-017: Audio Recording with Timing Data - Core Implementation
- **IMPLEMENTED** comprehensive timing data system with millisecond precision
- **CREATED** TimingData.swift with TranscriptionSegment, AudioRecordingSession, and AudioQualitySettings models
- **ADDED** TimingDataManager service for session management and timing data persistence
- **BUILT** AudioRecordingManager for high-quality audio capture with configurable quality settings
- **DEVELOPED** AudioPlaybackManager for synchronized audio/text playback with seek-to-text functionality
- **EXTENDED** SpeechRecognizer with timing data capture capabilities via SpeechRecognizer+Timing.swift
- **ENHANCED** ExportManager with SRT, VTT, TTML, and JSON export formats for timing data
- **UPDATED** SpeechRecognitionViewModel with full timing data integration and audio playback controls

**Technical Achievements:**
- Precise timing data capture with millisecond precision
- High-quality audio recording with configurable settings (sample rate, bit depth, compression)
- Synchronized audio/text playback with real-time segment highlighting
- Professional export formats (SRT, VTT, TTML, JSON) for video editing workflows
- Seek-to-text functionality for easy navigation
- Playback speed controls (0.5x, 1x, 1.5x, 2x)
- Session persistence and management
- Audio buffer optimization and storage management

**Status**: Core implementation complete, UI integration pending
**Next Steps**: UI components for timing display, audio playback controls, session management interface

---

## Phase 4: Memlog Maintenance & Documentation (Latest)

### 2024-12-19 - Project Documentation Update
- **UPDATED** directory_tree.md to reflect current project structure
- **ADDED** Models directory documentation with Theme.swift
- **DOCUMENTED** new UI components: TextSizeSettingView, ThemeSettingView, MicSensitivityView, VUMeterView, NativeStyleShareView
- **UPDATED** Services section to include ExportManager.swift
- **MAINTAINED** comprehensive changelog with current feature status
- **VERIFIED** all memlog files are current and accurate

### Current Status: Documentation Complete
- All memlog files updated with current project state
- Directory structure accurately reflects current codebase
- Task list and changelog maintained according to project guidelines
- Ready for next development phase

---

## Phase 3: Enhanced User Interface & Custom Sharing

### 2024-06-30 - Custom Share Sheet Implementation
- **REPLACED** broken CustomShareView with NativeStyleShareView
- **IMPLEMENTED** iOS share sheet-style interface with proper grid layout
- **FIXED** clipboard functionality using iOS-compatible UIPasteboard
- **RESOLVED** "Move" vs "Save" terminology confusion with proper file export
- **ENHANCED** visual design with circular icon backgrounds and proper spacing
- **OPTIMIZED** for iOS 15.0+ compatibility (removed iOS 16+ APIs)
- **MAINTAINED** intelligent autoscroll functionality from previous implementation

### Current Status: Building Successfully
- Custom sharing interface eliminates unwanted Amazon extensions
- Native iOS appearance with 3-column grid layout
- Proper file export functionality with "Save" terminology
- Full clipboard integration working
- iOS 15.0+ compatible codebase

---

## Phase 2: Core Architecture Implementation

### 2024-06-29 - Export System & Intelligent Autoscroll
- **COMPLETED** TASK-001: Export functionality with export button
- **IMPLEMENTED** ExportManager service with .txt/.rtf/.md support
- **ADDED** CustomShareView with iOS share sheet integration
- **ENHANCED** ContentView with intelligent autoscroll system
- **FEATURES**: Auto-scroll detection, "Jump to Live" button, smooth animations
- **RESOLVED** Amazon share extension issue through custom UI approach

### 2024-06-28 - Project Structure & Documentation
- **CREATED** comprehensive memlog system with tasks.md and directory_tree.md
- **DOCUMENTED** 16 prioritized feature tasks with acceptance criteria
- **ESTABLISHED** professional coding standards (no emojis, proper comments)
- **FIXED** missing AVFoundation import in SpeechRecognizer.swift

---

## Phase 1: Foundation & Core Features

### 2024-06-27 - Initial Implementation
- **CORE FEATURES**: Real-time speech recognition, audio waveform visualization
- **ARCHITECTURE**: MVVM pattern with SwiftUI, modular service architecture
- **COMPONENTS**: SpeechRecognizer, WaveformView, ContentView, SettingsView
- **SERVICES**: AlertManager, CacheManager, DownloadManager
- **FRAMEWORKS**: Speech, AVFoundation, SwiftUI integration 

## [2025-07-10] - Audio Quality Settings Conflict Resolution & iPhone Crash Fix

### Fixed
- **Critical Bug**: Resolved duplicate `AudioQualitySettings` struct definitions causing compilation errors
  - Removed duplicate struct from `AudioRecordingManager.swift`
  - Updated code to use existing `AudioQualitySettings` from `TimingData.swift`
  - Fixed type ambiguity issues with explicit type annotations
- **Critical Bug**: Fixed iPhone crash due to invalid audio hardware format
  - Added robust validation of native audio format before proceeding
  - Enhanced error messages to identify hardware configuration issues
  - Improved audio session setup with better fallback handling
  - Added critical error reporting for device-specific audio engine failures

### Technical Details
- **AudioQualitySettings Conflict**: The struct was defined in both `TimingData.swift` and `AudioRecordingManager.swift`
  - Kept the more complete version in `TimingData.swift` (includes `compressionQuality`)
  - Updated `AudioRecordingManager.swift` to use the existing definition
  - Added explicit type annotations to resolve compiler ambiguity
- **iPhone Audio Crash**: The crash was caused by invalid audio hardware format (0 channels, 0 Hz)
  - Added validation before audio engine setup to catch invalid formats early
  - Enhanced error reporting to distinguish between simulator and device issues
  - Improved audio session configuration with better error handling

### Files Modified
- `SpeechDictation/Services/AudioRecordingManager.swift` - Removed duplicate struct, enhanced validation
- `SpeechDictation/Models/TimingData.swift` - Kept as the single source of truth for AudioQualitySettings

### Impact
- Resolves compilation errors and type ambiguity issues
- Prevents iPhone crashes due to invalid audio hardware configuration
- Improves error reporting for debugging audio issues on real devices
- Maintains backward compatibility with existing audio quality settings usage

## [2025-07-10] - Audio Quality Settings Compilation Fix & Format Mismatch Resolution

### Fixed
- **Critical Bug**: Resolved `AudioQualitySettings` compilation issues by consolidating definition
  - Moved `AudioQualitySettings` struct definition to `AudioRecordingManager.swift`
  - Removed duplicate definition from `TimingData.swift` to prevent redeclaration errors
  - Fixed "Cannot find type 'AudioQualitySettings' in scope" compilation errors
- **Critical Bug**: Fixed audio format mismatch crash on iPhone
  - Changed from forcing specific sample rate (22050 Hz) to using native hardware format (24000 Hz)
  - Eliminated "Input HW format and tap format not matching" crash
  - Improved audio session error handling with better fallback mechanisms

### Technical Details
- **Compilation Issue**: The compiler couldn't resolve `AudioQualitySettings` type due to module import issues
  - Temporarily moved struct definition to `AudioRecordingManager.swift` where it's used
  - Removed duplicate from `TimingData.swift` to prevent redeclaration conflicts
  - This resolves the "Cannot find type" compilation errors
- **Format Mismatch Crash**: The crash occurred because we were forcing a 22050 Hz format when hardware supports 24000 Hz
  - Changed to use `nativeFormat` instead of creating a desired format
  - This ensures the tap format matches the hardware format exactly
  - Added better error handling for audio session configuration failures

### Files Modified
- `SpeechDictation/Services/AudioRecordingManager.swift` - Added AudioQualitySettings definition, fixed format handling
- `SpeechDictation/Models/TimingData.swift` - Removed duplicate AudioQualitySettings definition

### Impact
- Resolves all compilation errors related to AudioQualitySettings
- Prevents iPhone crashes due to audio format mismatches
- Improves audio recording reliability on real devices
- Maintains all existing functionality while fixing critical issues 