# SpeechDictation

SpeechDictation is an iOS application that provides real-time speech recognition and audio processing capabilities. The app transcribes speech from the microphone or audio files into text, visualizes audio waveforms, and now includes **live camera feed input with audio descriptions** for enhanced accessibility and content creation.

## Features

### Core Speech Recognition
- **Real-time Speech Recognition**: Transcribe speech from the microphone with millisecond precision
- **Audio File Transcription**: Transcribe speech from audio files (MP3 to M4A conversion included)
- **High-Quality Audio Recording**: Configurable audio quality settings with native hardware format detection
- **Timing Data Capture**: Precise timing information for transcription segments with export capabilities

### Audio Visualization & Playback
- **Waveform Visualization**: Display the audio waveform in real-time during recording
- **Volume Unit (VU) Meter**: Real-time audio level monitoring with visual feedback
- **Synchronized Audio Playback**: Play recorded audio with text highlighting and seek-to-text functionality
- **Multiple Export Formats**: Export timing data in SRT, VTT, JSON, and CSV formats

### Live Camera Feed with Audio Descriptions
- **Real-time Camera Input**: Capture live video feed from device camera
- **Audio Descriptions**: Generate spoken descriptions of visual content for accessibility
- **Integrated Audio-Visual Processing**: Combine camera feed with audio transcription for comprehensive content capture
- **Accessibility Features**: Provide audio descriptions for users with visual impairments

### Advanced Features
- **Caching System**: Efficiently cache and retrieve audio files and recordings
- **Session Management**: Save and manage multiple recording sessions with metadata
- **Customizable Settings**: Adjust font size, themes, microphone sensitivity, and audio quality
- **Background Processing**: Continue recording during app backgrounding (where supported)

## Components

### Audio Processing
- **AudioRecordingManager**: High-quality audio recording with configurable settings and native format detection
- **AudioPlaybackManager**: Synchronized audio playback with timing data and text highlighting
- **TimingDataManager**: Precise timing data capture and session management
- **ExportManager**: Multiple export formats for timing data and transcriptions

### Speech Recognition
- **SpeechRecognizer**: Core speech recognition using Apple's Speech framework
- **SpeechRecognitionViewModel**: MVVM architecture for speech recognition and UI coordination
- **Audio Session Management**: Proper audio session configuration for all iOS devices

### Camera & Visual Processing
- **CameraManager**: Live camera feed capture and processing
- **AudioDescriptionGenerator**: Generate spoken descriptions of visual content
- **VisualAccessibilityProcessor**: Process visual content for accessibility features

### UI & Visualization
- **WaveformView**: Real-time audio waveform visualization
- **VUMeterView**: Volume unit meter for audio level monitoring
- **SettingsView**: Comprehensive settings for audio quality, themes, and accessibility
- **NativeStyleShareView**: Custom sharing interface for transcriptions and recordings

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

### Running the App

1. Select your target device or simulator
2. Build and run the project
3. Grant microphone and camera permissions when prompted

## Usage

### Speech Dictation
- **Start Transcription**: Tap the "Start" button to begin real-time speech transcription
- **Stop Transcription**: Tap the "Stop" button to end transcription and save the session
- **Pause/Resume**: Use pause and resume controls for session management
- **Export Data**: Export timing data in multiple formats for further processing

### Camera Feed with Audio Descriptions
- **Enable Camera**: Grant camera permissions to access live video feed
- **Audio Descriptions**: The app will automatically generate spoken descriptions of visual content
- **Accessibility Mode**: Enhanced audio descriptions for users with visual impairments
- **Content Capture**: Record both audio and visual content simultaneously

### Settings & Customization
- **Audio Quality**: Choose between low, standard, and high quality recording settings
- **Theme Selection**: Light, dark, and high contrast themes for accessibility
- **Font Size**: Adjustable text size for better readability
- **Microphone Sensitivity**: Fine-tune microphone gain for optimal recording

## Technical Architecture

### Audio Processing Pipeline
```
Microphone Input → Native Format Detection → Audio Recording → Speech Recognition → Timing Data Capture
```

### Camera Processing Pipeline
```
Camera Feed → Visual Processing → Audio Description Generation → Accessibility Output
```

### Data Management
- **Session Storage**: Local storage of recording sessions with timing metadata
- **Export System**: Multiple format support for timing data and transcriptions
- **Cache Management**: Efficient caching of audio files and processed data

## Device Compatibility

### iOS Version Support
- **Minimum**: iOS 15.0 (covers 99%+ of active devices)
- **Maximum**: Latest iOS 18.0+ (future-proof)

### Device Coverage
- **iPhone**: iPhone 6s and newer (iOS 15+ support)
- **iPad**: iPad Air 2 and newer
- **Audio Hardware**: Native format detection ensures compatibility with all audio configurations
- **Camera Hardware**: Supports all iOS device cameras with proper permission handling

## Project Structure

```
SpeechDictation/
├── SpeechDictation/           # Main application
│   ├── Services/             # Audio recording, playback, timing data management
│   ├── Speech/               # Speech recognition and audio processing
│   ├── UI/                   # SwiftUI views and components
│   ├── Models/               # Data models and structures
│   └── Preview Content/      # SwiftUI preview assets
├── SpeechDictationTests/     # Unit tests
├── SpeechDictationUITests/   # UI tests
└── memlog/                   # Project documentation and changelog
```

## Performance & Optimization

### Audio Processing
- **Native Format Detection**: Automatically adapts to device audio capabilities
- **Efficient Buffering**: Optimized buffer sizes for real-time processing
- **Memory Management**: Proper cleanup and resource management

### Camera Processing
- **Real-time Processing**: Efficient visual content analysis
- **Accessibility Optimization**: Optimized audio descriptions for accessibility users
- **Battery Management**: Efficient power usage for extended recording sessions

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions, suggestions, or support:
- **Email**: [joe.mccraw+github@gmail.com]
- **Issues**: [GitHub Issues](https://github.com/SerialForBreakfast/SpeechDictation/issues)
- **Discussions**: [GitHub Discussions](https://github.com/SerialForBreakfast/SpeechDictation/discussions)

## Roadmap

### Upcoming Features
- **Enhanced Audio Descriptions**: More detailed and contextual visual descriptions
- **Multi-language Support**: Support for additional languages in speech recognition
- **Cloud Integration**: Optional cloud storage and sharing capabilities
- **Advanced Accessibility**: Additional accessibility features for users with disabilities

### Performance Improvements
- **Background Processing**: Enhanced background recording capabilities
- **Real-time Optimization**: Further optimization of real-time audio and video processing
- **Battery Optimization**: Improved battery efficiency for extended use

---

*Built with ❤️ for accessibility and content creation*
