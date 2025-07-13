# SpeechDictation iOS - Directory Structure

```
SpeechDictation-iOS/
├── .git/                           # Git repository metadata
├── .gitignore                      # Git ignore patterns
├── LICENSE                         # MIT License file
├── README.md                       # Project documentation (Updated with camera feed goals)
├── memlog/                         # Project management and documentation
│   ├── tasks.md                    # Comprehensive task management (consolidated from multiple files)
│   ├── directory_tree.md           # This file - project structure
│   └── changelog.md                # Project change history (updated with latest improvements)
├── build/                          # Build artifacts (temporary)
│   └── reports/                    # Build and test reports (timestamped)
├── AIEars/                         # Legacy/alternate project (unused)
├── AIEars.xcodeproj/              # Legacy Xcode project
├── AIEarsTests/                   # Legacy test files
├── AIEarsUITests/                 # Legacy UI test files
├── SpeechDictation/               # Main application source code
│   ├── Assets.xcassets/           # App icons and colors
│   │   ├── AccentColor.colorset/
│   │   ├── AppIcon.appiconset/
│   │   └── Contents.json
│   ├── Info.plist                 # App configuration and permissions
│   ├── Preview Content/           # SwiftUI preview assets
│   │   └── Preview Assets.xcassets/
│   ├── Models/                    # Data models and types
│   │   ├── Theme.swift            # Theme configuration model
│   │   └── TimingData.swift       # Audio timing and transcription data models
│   ├── Services/                  # Business logic services
│   │   ├── AlertManager.swift     # Share sheet and alert handling
│   │   ├── CacheManager.swift     # File caching and storage
│   │   ├── DownloadManager.swift  # Remote file downloading
│   │   ├── ExportManager.swift    # Export and sharing functionality
│   │   ├── TimingDataManager.swift # Timing data management and persistence
│   │   ├── AudioRecordingManager.swift # High-quality audio recording
│   │   └── AudioPlaybackManager.swift # Synchronized audio/text playback
│   ├── Speech/                    # Speech recognition core
│   │   ├── SpeechRecognizer.swift              # Main recognizer class
│   │   ├── SpeechRecognizer+Authorization.swift # Permission handling
│   │   ├── SpeechRecognizer+config.swift       # Audio session setup
│   │   ├── SpeechRecognizer+Convert.swift      # Audio format conversion
│   │   └── SpeechRecognizer+Timing.swift       # Timing data capture
│   ├── UI/                        # User interface components
│   │   ├── ContentView.swift      # Main app interface with autoscroll
│   │   ├── SettingsView.swift     # Settings panel
│   │   ├── TextSizeSettingView.swift # Text size configuration
│   │   ├── ThemeSettingView.swift # Theme selection interface
│   │   ├── MicSensitivityView.swift # Microphone sensitivity controls
│   │   ├── VUMeterView.swift      # Volume unit meter visualization
│   │   ├── WaveformView.swift     # Audio waveform visualization
│   │   └── NativeStyleShareView.swift # Custom sharing interface
│   ├── SpeechDictationApp.swift   # App entry point
│   └── SpeechRecognitionViewModel.swift # MVVM coordinator
├── SpeechDictation.xcodeproj/     # Main Xcode project
│   ├── project.pbxproj            # Xcode project configuration
│   ├── project.xcworkspace/       # Workspace settings
│   └── xcuserdata/                # User-specific settings (gitignored)
├── SpeechDictationTests/          # Unit tests
│   └── SpeechDictationTests.swift # Test cases for core functionality
└── SpeechDictationUITests/        # UI automation tests
    ├── SpeechDictationUITests.swift           # UI test cases
    └── SpeechDictationUITestsLaunchTests.swift # Launch performance tests
└── utility/                       # Development automation tools
    ├── build_and_test.sh          # Comprehensive build and test automation
    ├── quick_iterate.sh            # Fast development iteration script
    └── README.md                   # Utility documentation and usage guide
```

## Key Components Overview

### Core Architecture
- **MVVM Pattern**: Clear separation between View (SwiftUI), ViewModel, and Model layers
- **Extension-based Organization**: SpeechRecognizer functionality split into focused extensions
- **Service Layer**: Dedicated services for caching, downloading, alerts, export, timing data, and audio recording
- **Protocol-ready**: Structure prepared for dependency injection and testability

### Technology Stack
- **SwiftUI**: Modern declarative UI framework
- **Speech Framework**: Apple's speech recognition APIs
- **AVFoundation**: Audio recording, processing, playback, and camera functionality
- **Combine**: Reactive programming for data binding
- **XCTest**: Testing framework for unit and UI tests

### Project Targets
1. **SpeechDictation**: Main iOS application
2. **SpeechDictationTests**: Unit test suite
3. **SpeechDictationUITests**: UI automation test suite

### Build Configuration
- **Minimum iOS Version**: 15.0
- **Development Team**: RWZ25NGH8K
- **Bundle Identifier**: com.ShowBlender.SpeechDictation
- **Swift Version**: 5.0

### Dependencies
- **No external dependencies**: Uses only Apple's native frameworks
- **SPM Ready**: Prepared for Swift Package Manager integration if needed

### Recent Additions
- **Utility Directory**: Development automation tools for build and test workflows
- **Build Automation**: Comprehensive build_and_test.sh script with detailed reporting
- **Quick Iteration**: Fast development cycle script for rapid testing
- **Memlog Consolidation**: Unified task management system in single tasks.md file
- **Export System Enhancements**: Improved reliability with background processing and proper delegate management
- **SRT Format Improvements**: Intelligent segment grouping for better subtitle readability
- **Build Script Enhancements**: Simulator targeting and optional unit test execution

### Planned Additions (TASK-018 & TASK-019)
- **CameraManager.swift**: Camera feed capture and management
- **AudioDescriptionGenerator.swift**: Visual content analysis and description generation
- **VisualAccessibilityProcessor.swift**: Accessibility features for visual content
- **CameraPreviewView.swift**: Live camera display with accessibility overlays
- **CameraControlsView.swift**: Camera controls (focus, exposure, zoom, flash)
- **CameraSettingsView.swift**: Camera quality and accessibility settings

---

## Project Evolution: Accessibility Platform

The project has evolved from a simple speech dictation app to a comprehensive **accessibility and content creation platform** that combines:

1. **Real-time Speech Recognition** - High-quality transcription with timing data
2. **Live Camera Feed Processing** - Visual content capture and analysis (planned)
3. **Audio Descriptions** - Accessibility features for users with visual impairments (planned)
4. **Integrated Audio-Visual Processing** - Combined camera and audio functionality
5. **Professional Export Capabilities** - Multiple formats for content creation workflows

This expansion positions SpeechDictation as a powerful tool for:
- **Content Creators** - Professional transcription and video editing workflows
- **Accessibility Users** - Audio descriptions and visual content accessibility
- **Educators** - Lecture capture with synchronized transcriptions
- **Professionals** - Meeting recording with precise timing data

---

*Last Updated: July 12, 2025*
*Next Review: August 1, 2025* 