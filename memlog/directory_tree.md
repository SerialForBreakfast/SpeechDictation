# SpeechDictation iOS - Directory Structure

```
SpeechDictation-iOS/
├── .github/                       # GitHub workflows and automation
├── .swiftlint.yml                 # SwiftLint configuration
├── README.md                      # Project overview and usage
├── LICENSE                        # MIT License
├── build/                         # Build artifacts (generated)
├── memlog/                        # Project logs and planning docs
├── Research/                      # Architecture decision records and notes
├── resources/                     # Static resources (images, docs)
├── SpeechDictation/               # Main application source
│   ├── Assets.xcassets/           # App icons and colors
│   ├── Info.plist                 # App configuration and permissions
│   ├── Models/                    # Data models (timing, models, ML catalog)
│   ├── Services/                  # Core services (export, audio, model loading)
│   ├── Speech/                    # Speech recognition engines and helpers
│   ├── UI/                        # SwiftUI views and components
│   ├── todofiles/                 # Experimental camera/ML components
│   ├── SpeechDictationApp.swift   # App entry point
│   └── SpeechRecognizerViewModel.swift
├── SpeechDictationTests/          # Unit tests
├── SpeechDictationUITests/        # UI automation tests
├── SpeechDictation.xcodeproj/     # Xcode project
├── utility/                       # Build and test automation scripts
└── Archive 2.zip                  # Legacy archive (do not rely on)
```

## Key Modules

### Speech
- `Speech/` contains the transcription engine protocol plus Legacy and Modern implementations.
- `SpeechRecognizer` coordinates engine events and UI updates.

### Camera (Experimental)
- EntryView exposes a camera experience with permission gating.
- `todofiles/` contains camera ML view models and views used by the camera flow.

### Export and Timing
- `Services/ExportManager.swift` supports text and timing exports (SRT, VTT, TTML, JSON).
- `Models/TimingData.swift` defines timing segment structures.

### Build and Testing
- `utility/` scripts provide build and test automation with logs in `build/`.
