# SpeechDictation

SpeechDictation is an iOS application that demonstrates the use of speech recognition and audio processing. It transcribes speech from the microphone or audio files into text, visualizes the audio waveform, and handles audio playback.

## Features

- **Real-time Speech Recognition**: Transcribe speech from the microphone.
- **Audio File Transcription**: Transcribe speech from audio files (MP3 to M4A conversion included).
- **Waveform Visualization**: Display the audio waveform in real-time.
- **Caching**: Efficiently cache and retrieve audio files.

## Components

- **AudioSessionManager**: Manages audio session configuration and permissions.
- **AudioRecorder**: Handles audio recording and provides audio samples.
- **SpeechTranscriber**: Uses SFSpeechRecognizer to transcribe audio.
- **AudioPlayer**: Manages audio playback and waveform updates.
- **WaveformGenerator**: Processes audio samples to generate waveform data.
- **CacheManager**: Handles caching of downloaded and converted audio files.

## Getting Started

### Prerequisites

- Xcode 12.0 or later
- iOS 14.0 or later

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

1. Select your target device or simulator.
2. Build and run the project.

## Usage

- **Start Transcription**: Tap the "Start" button to begin transcribing speech from the microphone.
- **Stop Transcription**: Tap the "Stop" button to end transcription.
- **Transcribe Audio File**: Tap the "Transcribe File" button and select an audio file to transcribe.

## Project Structure

- **SpeechDictation**: Main application code.
- **SpeechDictationTests**: Unit tests for the application.
- **SpeechDictationUITests**: UI tests for the application.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributions

Contributions are welcome! Please open an issue or submit a pull request for any improvements or fixes.

## Contact

For any questions or suggestions, please contact [joe.mccraw+github@gmail.com].
