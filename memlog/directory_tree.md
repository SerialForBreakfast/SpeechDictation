# SpeechDictation iOS - Directory Structure

```
SpeechDictation-iOS/
├── .git/                           # Git repository metadata
├── .gitignore                      # Git ignore patterns
├── LICENSE                         # MIT License file
├── README.md                       # Project documentation
├── memlog/                         # Project management and documentation
│   ├── tasks.md                    # Feature tasks and requirements
│   ├── directory_tree.md           # This file - project structure
│   └── changelog.md                # Project change history
├── build/                          # Build artifacts (temporary)
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
│   │   └── Theme.swift            # Theme configuration model
│   ├── Services/                  # Business logic services
│   │   ├── AlertManager.swift     # Share sheet and alert handling
│   │   ├── CacheManager.swift     # File caching and storage
│   │   ├── DownloadManager.swift  # Remote file downloading
│   │   └── ExportManager.swift    # Export and sharing functionality
│   ├── Speech/                    # Speech recognition core
│   │   ├── SpeechRecognizer.swift              # Main recognizer class
│   │   ├── SpeechRecognizer+Authorization.swift # Permission handling
│   │   ├── SpeechRecognizer+config.swift       # Audio session setup
│   │   └── SpeechRecognizer+Convert.swift      # Audio format conversion
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
```

## Key Components Overview

### Core Architecture
- **MVVM Pattern**: Clear separation between View (SwiftUI), ViewModel, and Model layers
- **Extension-based Organization**: SpeechRecognizer functionality split into focused extensions
- **Service Layer**: Dedicated services for caching, downloading, alerts, and export functionality
- **Protocol-ready**: Structure prepared for dependency injection and testability

### Technology Stack
- **SwiftUI**: Modern declarative UI framework
- **Speech Framework**: Apple's speech recognition APIs
- **AVFoundation**: Audio recording, processing, and playback
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
- **Models Directory**: Added for data model organization
- **ExportManager**: New service for export and sharing functionality
- **NativeStyleShareView**: Custom sharing interface to replace system share sheet
- **Enhanced UI Components**: Added specialized views for settings, VU meter, and microphone sensitivity

---

*Last Updated: December 19, 2024*
*Next Review: December 26, 2024* 