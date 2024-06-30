SpeechDictation

SpeechDictation is an iOS application that demonstrates the use of speech recognition and audio processing. It transcribes speech from the microphone or audio files into text, visualizes the audio waveform, and handles audio playback.

Features

	•	Real-time Speech Recognition: Transcribe speech from the microphone.
	•	Audio File Transcription: Transcribe speech from audio files (MP3 to M4A conversion included).
	•	Waveform Visualization: Display the audio waveform in real-time.
	•	Caching: Efficiently cache and retrieve audio files.

Components

	•	AudioSessionManager: Manages audio session configuration and permissions.
	•	AudioRecorder: Handles audio recording and provides audio samples.
	•	SpeechTranscriber: Uses SFSpeechRecognizer to transcribe audio.
	•	AudioPlayer: Manages audio playback and waveform updates.
	•	WaveformGenerator: Processes audio samples to generate waveform data.
	•	CacheManager: Handles caching of downloaded and converted audio files.
