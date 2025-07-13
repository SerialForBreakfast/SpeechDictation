# SpeechDictation iOS

A professional iOS application for real-time speech recognition with advanced audio processing, timing data capture, and comprehensive export capabilities. Built with Swift and SwiftUI, this app provides high-quality transcription services with professional-grade timing formats suitable for video editing and accessibility workflows.

## Features

### Core Speech Recognition
- **Real-time Speech Recognition**: High-quality transcription using Apple's Speech framework with millisecond precision
- **Audio Recording**: Configurable audio quality settings with native hardware format detection
- **Timing Data Capture**: Precise timing information for each transcription segment
- **Session Management**: Save and manage multiple recording sessions with metadata

### Export & Sharing
- **Multiple Text Formats**: Export as Plain Text, RTF, or Markdown
- **Professional Timing Formats**: Export timing data in SRT, VTT, TTML, and JSON formats
- **Audio + Timing Export**: Combined audio and timing data export for professional workflows
- **Native Sharing**: iOS share sheet integration and Files app support

### User Experience
- **Intelligent Autoscroll**: Automatically follows new text with manual override capability
- **Customizable Interface**: Adjustable themes (Light, Dark, High Contrast) and text sizes
- **Audio Visualization**: Real-time waveform display and VU meter
- **Accessibility**: VoiceOver support and accessibility-focused design

### Build & Development
- **Automated Build System**: Comprehensive build and test automation scripts
- **Quality Assurance**: Unit tests and UI tests with detailed reporting
- **Development Tools**: Quick iteration scripts for rapid development cycles

## Technical Architecture

### Audio Processing Pipeline
```
Microphone Input → Native Format Detection → Audio Recording → Speech Recognition → Timing Data Capture
```

### Core Components
- **SpeechRecognizer**: Core speech recognition with Apple's Speech framework
- **AudioRecordingManager**: High-quality audio recording with configurable settings
- **TimingDataManager**: Precise timing data capture and session management
- **ExportManager**: Multiple export formats with background processing
- **AudioPlaybackManager**: Synchronized audio playback with text highlighting

### Data Management
- **Session Storage**: Local storage of recording sessions with timing metadata
- **Export System**: Professional format support for video editing workflows
- **Cache Management**: Efficient caching of audio files and processed data

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 15.0 or later (supports 99%+ of active iOS devices)
- iPhone 6s or newer / iPad Air 2 or newer

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/SerialForBreakfast/SpeechDictation.git
   ```
2. Open the project in Xcode:
   ```bash
   open SpeechDictation.xcodeproj
   ```

### Build & Test
Use the included automation scripts for development:

```bash
# Build only (default)
./utility/build_and_test.sh

# Build with unit tests
./utility/build_and_test.sh --enableUnitTests

# Target specific simulator
./utility/build_and_test.sh --simulator-id <UUID>

# Quick iteration for development
./utility/quick_iterate.sh
```

### Running the App
1. Select your target device or simulator
2. Build and run the project
3. Grant microphone and speech recognition permissions when prompted

## Usage

### Basic Operation
1. **Start Recording**: Tap "Start Listening" to begin real-time transcription
2. **View Transcript**: Watch as speech is converted to text in real-time
3. **Export Results**: Use the export button to save in various formats
4. **Manage Sessions**: Access previous recordings and timing data

### Export Options
- **Text Export**: Plain text, RTF, or Markdown formats
- **Timing Export**: SRT subtitles, VTT captions, TTML, or JSON data
- **Audio Export**: Combined audio and timing data for video editing

### Settings & Customization
- **Themes**: Light, Dark, and High Contrast modes
- **Text Size**: Adjustable for better readability
- **Audio Quality**: Configure recording quality settings

## Project Structure

```
SpeechDictation-iOS/
├── SpeechDictation/           # Main application
│   ├── Services/             # Audio recording, playback, timing management
│   ├── Speech/               # Speech recognition and audio processing
│   ├── UI/                   # SwiftUI views and components
│   ├── Models/               # Data models and structures
│   └── SpeechDictationApp.swift # App entry point
├── SpeechDictationTests/     # Unit tests
├── SpeechDictationUITests/   # UI automation tests
├── utility/                  # Build and development automation
│   ├── build_and_test.sh     # Comprehensive build automation
│   ├── quick_iterate.sh      # Fast development iteration
│   └── README.md             # Utility documentation
└── memlog/                   # Project documentation
    ├── tasks.md              # Comprehensive task management
    ├── changelog.md          # Project change history
    └── directory_tree.md     # Project structure documentation
```

## Device Compatibility

### iOS Version Support
- **Minimum**: iOS 15.0 (covers 99%+ of active devices)
- **Current**: Tested through iOS 18.x

### Device Coverage
- **iPhone**: iPhone 6s and newer
- **iPad**: iPad Air 2 and newer
- **Audio Hardware**: Native format detection ensures compatibility with all configurations

## Development

### Build System
The project includes comprehensive build automation:
- **Prerequisite validation**: Checks Xcode, simulators, project structure
- **Build automation**: Clean builds with error handling
- **Test execution**: Unit and UI tests with detailed reporting
- **Performance metrics**: Build time, test counts, project size tracking

### Quality Assurance
- All features must pass unit tests
- Code follows Swift concurrency best practices
- UI is accessible and follows iOS design guidelines
- Performance meets established benchmarks

## Roadmap

### Completed Features
- Core speech recognition with timing data
- Export and sharing system with professional formats
- Intelligent autoscroll system
- Build automation and quality assurance tools

### Planned Features
- Text editing and correction capabilities
- Recording session management (pause/resume)
- Enhanced audio playback and review
- Advanced waveform visualization
- File management system

## Contributing

We welcome contributions! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes with appropriate tests
4. Use the build automation scripts to validate
5. Submit a pull request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions, suggestions, or support:
- **Email**: joe.mccraw+github@gmail.com
- **Issues**: [GitHub Issues](https://github.com/SerialForBreakfast/SpeechDictation/issues)
- **Discussions**: [GitHub Discussions](https://github.com/SerialForBreakfast/SpeechDictation/discussions)

---

*Professional speech recognition for iOS with timing data precision*
