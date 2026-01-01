import Foundation
import Speech
import AVFoundation

/// Main speech recognition coordinator using pluggable transcription engines.
///
/// Concurrency:
/// - Published properties must be updated on the main thread
/// - Engine event stream runs on background tasks
/// - Uses DispatchQueue.main.async for UI updates from engine events
class SpeechRecognizer: ObservableObject {
    @Published var transcribedText: String = ""
    @Published private(set) var audioSamples: [Float] = []
    /// Live peak audio level (0.0 – 1.0) updated for each incoming buffer. Used for VU meter.
    ///
    /// Concurrency: Must be set on main thread (published property)
    @Published var currentLevel: Float = 0.0
    @Published var volume: Float = 60.0 {
        didSet {
            adjustVolume()
        }
    }
    
    var audioEngine: AVAudioEngine?
    var speechRecognizer: SFSpeechRecognizer?
    var request: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    var audioPlayer: AVAudioPlayer?
    private let audioSamplesQueue: DispatchQueue = DispatchQueue(label: "audioSamplesQueue", qos: .userInitiated)
    private let volumeQueue: DispatchQueue = DispatchQueue(label: "volumeQueue", qos: .userInitiated)
    var displayLink: CADisplayLink?
    var playerNode: AVAudioPlayerNode?
    var mixerNode: AVAudioMixerNode?

    // MARK: - Transcription Engine Integration
    
    /// Current transcription engine (LegacyTranscriptionEngine or ModernTranscriptionEngine)
    ///
    /// Concurrency: Actor-isolated engine, accessed via async methods
    /// Note: Accessible to extensions for timing workflows
    var transcriptionEngine: (any TranscriptionEngine)?
    
    /// Task that consumes the engine's event stream and updates UI
    ///
    /// Concurrency: Background task that marshals updates to main thread
    /// Note: Accessible to extensions for timing workflows
    var engineEventTask: Task<Void, Never>?

    // MARK: - Live transcription accumulation (kept for backward compatibility)

    /// Accumulates **finalized** transcript text across recognition-task restarts.
    ///
    /// Speech recognition tasks may end after silence; we restart them to support natural gaps
    /// in dialogue while keeping a single logical transcript for the UI and persistence layers.
    private var accumulatedTranscript: String = ""

    /// Last partial transcript emitted by the current recognition task.
    ///
    /// Used to prevent regressions where `bestTranscription` temporarily shortens while the recognizer
    /// revises its hypothesis.
    private var lastPartialTranscript: String = ""

    /// Indicates we are intentionally stopping recognition, so auto-restart should not occur.
    private var isStoppingRecognition: Bool = false

    /// Whether the current transcription session is driven by an external audio source.
    private var isUsingExternalAudioSourceForTranscription: Bool = false

    /// Records the start date for the current timing session (used by the timing extension).
    var timingSessionStartDate: Date?

    /// Offset in seconds applied to timing segments when the recognizer is restarted (used by the timing extension).
    var timingRecognitionTimeOffset: TimeInterval = 0

    // MARK: - Cross-file helpers (used by extensions)

    /// Resets transcript accumulation for a brand-new recording/transcription session.
    ///
    /// Concurrency: Must be called on the main thread because it mutates published state (`transcribedText`).
    func resetTranscriptAccumulationForNewSession(isExternalAudioSource: Bool) {
        accumulatedTranscript = ""
        lastPartialTranscript = ""
        transcribedText = ""
        isStoppingRecognition = false
        isUsingExternalAudioSourceForTranscription = isExternalAudioSource
    }

    /// Updates the current partial transcript and re-composes `transcribedText` for display.
    ///
    /// Concurrency: Must be called on the main thread because it updates `transcribedText`.
    func applyPartialTranscriptUpdate(_ newText: String, isFinal: Bool) {
        guard !newText.isEmpty else { return }

        if newText.count >= lastPartialTranscript.count || isFinal {
            lastPartialTranscript = newText
        }

        transcribedText = composeTranscript(accumulated: accumulatedTranscript, partial: lastPartialTranscript)
    }

    /// Marks the recognizer as stopping to prevent auto-restart loops.
    func markRecognitionStopping() {
        isStoppingRecognition = true
        lastPartialTranscript = ""
    }

    /// Indicates whether recognition is in the process of stopping (used by timing auto-restart logic).
    var isRecognitionStopping: Bool {
        return isStoppingRecognition
    }
    
    init() {
        requestAuthorization()
        configureAudioSession()
        startLevelMonitoring()
    }
    
    func startTranscribing(isExternalAudioSource: Bool = false) {
        AppLog.info(.transcription, "Start transcription (external source: \(isExternalAudioSource))")

        // Reset per-session accumulation so each new transcription starts clean.
        resetTranscriptAccumulationForNewSession(isExternalAudioSource: isExternalAudioSource)

        // Stop any existing engine and event stream (awaited inside the new task to avoid overlap).
        let previousEngine = transcriptionEngine
        let previousTask = engineEventTask

        // Create appropriate engine via factory
        let configuration = TranscriptionEngineConfiguration.default
        let engine = TranscriptionEngineFactory.createEngine(
            configuration: configuration,
            isExternalAudioSource: isExternalAudioSource
        )
        transcriptionEngine = engine

        // Start engine and subscribe to its event stream
        engineEventTask = Task { [weak self] in
            do {
                // Ensure any prior engine has fully stopped before starting a new one.
                await previousEngine?.stop()
                if let previousTask {
                    await previousTask.value
                }

                // CRITICAL: Subscribe to event stream FIRST so continuation is set before start() yields events
                // Otherwise, events emitted during start() are lost (continuation is nil).
                let eventStream = engine.eventStream()
                
                // Start the engine (now continuation is ready to receive events)
                try await engine.start(audioBufferHandler: { [weak self] buffer in
                    // Forward audio buffers to level monitoring if needed
                    self?.processAudioForLevelMonitoring(buffer)
                })

                // Process events from the stream
                for await event in eventStream {
                    await self?.handleEngineEvent(event)
                }
            } catch {
                AppLog.error(.transcription, "Engine start failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.transcribedText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Handles events from the transcription engine
    ///
    /// Concurrency: Called from background task, marshals UI updates to main thread
    private func handleEngineEvent(_ event: TranscriptionEvent) async {
        switch event {
        case .partial(let text, _):
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !text.isEmpty else { return }
                self.transcribedText = text
            }
            
        case .final(let text, _):
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !text.isEmpty else { return }
                self.transcribedText = text
                AppLog.debug(.transcription, "Final transcription result length: \(text.count)", verboseOnly: true)
            }
            
        case .audioLevel(let level):
            DispatchQueue.main.async { [weak self] in
                self?.currentLevel = level
            }
            
        case .error(let error):
            AppLog.error(.transcription, "Engine error: \(error.localizedDescription)")
            
        case .stateChange(let state):
            AppLog.debug(.transcription, "Engine state: \(state)", dedupeInterval: 1)
        }
    }
    
    /// Processes audio buffer for level monitoring
    ///
    /// Concurrency: Called from engine's audio tap, can run on any thread
    /// Note: Accessible to extensions for timing workflows
    func processAudioForLevelMonitoring(_ buffer: AVAudioPCMBuffer) {
        // Level monitoring is handled by the engine itself via audioLevel events
        // This is just a hook for any additional audio processing if needed
    }
    
    /// Stops the transcription engine and cleans up resources
    ///
    /// Concurrency: Can be called from any thread, coordinates cleanup
    /// Note: Accessible to extensions for timing and other specialized workflows
    func stopTranscriptionEngine() {
        // Default behavior: stop quickly and release resources.
        // For flows that must drain final events for persistence (e.g., secure recordings),
        // use `stopTranscribingWithTimingAndWait(...)` which awaits shutdown.
        engineEventTask?.cancel()
        engineEventTask = nil

        let engine = transcriptionEngine
        transcriptionEngine = nil

        Task {
            await engine?.stop()
        }
    }
    
    /// Appends an external audio buffer to the recognition request
    /// - Parameter buffer: The audio buffer to process
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        processAudioBuffer(buffer: buffer)
        
        // Forward buffer to transcription engine (for external audio source mode)
        Task {
            await transcriptionEngine?.appendAudioBuffer(buffer)
        }
    }
    
    /// Processes a PCM buffer to store samples for waveform visualisation **and** update `currentLevel`.
    /// - Parameter buffer: Incoming audio buffer from the input node.
    ///
    /// Concurrency: Called on the audio engine's render thread. We avoid heavy work; calculating the
    /// *peak* amplitude is O(n) but cheap. We dispatch UI updates back to the main queue.
    func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        let frameLength = Int(buffer.frameLength)
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))

        // ---------------------------------------------------------------
        // CALCULATE NORMALISED INPUT LEVEL FOR VU-METER
        // ---------------------------------------------------------------
        // Use **root-mean-square** (RMS) → dBFS mapping which is similar to
        // how human ears perceive loudness.  Then convert a –60 dB … 0 dB
        // window into the 0…1 range expected by `VUMeterView`.
        let rms: Float = {
            let meanSquare = samples.reduce(into: Float(0)) { $0 += $1 * $1 } / Float(samples.count)
            return sqrtf(meanSquare)
        }()

        // Guard against log(0)
        let rmsDB = rms == 0 ? -100 : 20.0 * log10f(rms)
        let normalisedLevel = max(0, min(1, (rmsDB + 60) / 60)) // –60 dB → 0, 0 dB → 1

        DispatchQueue.main.async {
            self.currentLevel = normalisedLevel
        }

        audioSamplesQueue.async {
            var newSamples = self.audioSamples
            newSamples.append(contentsOf: samples)
            if newSamples.count > 1000 {
                newSamples.removeFirst(newSamples.count - 1000)
            }
            DispatchQueue.main.async {
                self.audioSamples = newSamples
            }
        }
    }
    
    /// Adjusts microphone sensitivity.
    ///
    /// The method first tries to set hardware input-gain via `AVAudioSession.setInputGain(_:)` (only
    /// available on devices that expose a software-controllable pre-amp).
    /// If the hardware gain is *not* settable it falls back to a software gain by scaling the
    /// `AVAudioInputNode.volume` (0.0 – 1.0).
    ///
    /// Concurrency: Runs on a dedicated `volumeQueue` to avoid blocking the main/UI thread while the
    /// audio engine is active. All AVAudioSession calls are *non-blocking* but may throw, so they are
    /// wrapped in a `do/try` inside the async block.
    internal func adjustVolume() {
        let gain = max(0, min(volume / 100.0, 1.0)) // Normalise 0 → 1

        volumeQueue.async {
            #if canImport(AVFoundation) && !os(macOS)
            let session = AVAudioSession.sharedInstance()

            // 1 Try hardware input-gain if the device supports it.
            if session.isInputGainSettable {
                do {
                    try session.setInputGain(gain)
                    AppLog.info(.recording, "Hardware mic gain set to \(gain)", dedupeInterval: 2)
                    return
                } catch {
                    AppLog.notice(.recording, "Failed to set hardware mic gain: \(error.localizedDescription). Falling back to software gain.", dedupeInterval: 2)
                }
            }
            #endif

            // 2 Software gain fallback via inputNode.volume
            if let inputNode = self.audioEngine?.inputNode {
                inputNode.volume = gain
                AppLog.info(.recording, "Software mic gain set to \(gain)", dedupeInterval: 2)
            }
        }
    }
    
    func stopTranscribing() {
        AppLog.info(.transcription, "Stop transcription")

        markRecognitionStopping()
        
        // Stop the transcription engine
        stopTranscriptionEngine()
        
        // Stop audio engine if it was started for level monitoring
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        startLevelMonitoring()

        // Preserve transcript for the UI until the next start.
    }

    // MARK: - Transcript composition & restart helpers

    /// Combines accumulated finalized transcript with the current partial transcript.
    func composeTranscript(accumulated: String, partial: String) -> String {
        guard !accumulated.isEmpty else { return partial }
        guard !partial.isEmpty else { return accumulated }
        return accumulated + " " + partial
    }

    /// Appends the current partial transcript to the accumulated transcript and clears the partial buffer.
    func finalizePartialTranscriptForAccumulation() {
        let finalized = lastPartialTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalized.isEmpty else { return }

        if accumulatedTranscript.isEmpty {
            accumulatedTranscript = finalized
        } else {
            accumulatedTranscript += " " + finalized
        }

        lastPartialTranscript = ""
        transcribedText = accumulatedTranscript
    }

    /// Restarts the recognition task to support gaps in dialogue (silence can end tasks).
    ///
    /// Concurrency: Must be called from the main thread because it mutates recognition state
    /// (`request`, `recognitionTask`) that is used by the audio render callback.
    private func restartTranscriptionTaskIfNeeded() {
        guard !isStoppingRecognition else { return }
        guard let speechRecognizer else { return }

        // Cancel the old task; keep the audio engine and tap running.
        recognitionTask?.cancel()
        recognitionTask = nil

        let newRequest = SFSpeechAudioBufferRecognitionRequest()
        newRequest.shouldReportPartialResults = true
        newRequest.requiresOnDeviceRecognition = true
        request = newRequest

        recognitionTask = speechRecognizer.recognitionTask(with: newRequest) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    guard let self else { return }
                    let newText = result.bestTranscription.formattedString
                    guard !newText.isEmpty else { return }

                    if newText.count >= self.lastPartialTranscript.count || result.isFinal {
                        self.lastPartialTranscript = newText
                    }

                    self.transcribedText = self.composeTranscript(accumulated: self.accumulatedTranscript, partial: self.lastPartialTranscript)

                    if result.isFinal {
                        self.finalizePartialTranscriptForAccumulation()
                        // Delay slightly to avoid rapid restart loops in long silences.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            self.restartTranscriptionTaskIfNeeded()
                        }
                    }
                }
            }

            if let error = error {
                guard let self else { return }
                let nsError = error as NSError
                if nsError.code == 301 || nsError.localizedDescription.localizedCaseInsensitiveContains("canceled") {
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.restartTranscriptionTaskIfNeeded()
                }
            }
        }

        if isUsingExternalAudioSourceForTranscription {
            AppLog.debug(.transcription, "Restarted recognition task (external audio source)", dedupeInterval: 1)
        } else {
            AppLog.debug(.transcription, "Restarted recognition task", dedupeInterval: 1)
        }
    }
    
    // MARK: - Input-level monitoring (always-on)

    /// Starts an `AVAudioEngine` solely for measuring input levels so the VU meter
    /// is responsive even when speech recognition is **not** running.
    ///
    /// If the engine is already active (e.g. due to transcription) this method is
    /// a no-op.
    func startLevelMonitoring() {
        guard audioEngine == nil else { return }

        audioEngine = AVAudioEngine()

        guard let inputNode = audioEngine?.inputNode else {
            AppLog.error(.recording, "Audio engine has no input node for level monitoring")
            return
        }

        // Use the native format from the input node for better compatibility
        let format = inputNode.outputFormat(forBus: 0)
        AppLog.debug(.recording, "Native input format for level monitoring: \(format)", verboseOnly: true)
        
        #if targetEnvironment(simulator)
        if format.sampleRate <= 0 || format.channelCount <= 0 {
            AppLog.notice(
                .recording,
                "Simulator invalid input format for level monitoring: sampleRate=\(format.sampleRate), channels=\(format.channelCount)",
                dedupeInterval: 5
            )
            return
        }
        #endif
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.processAudioBuffer(buffer: buffer)
        }

        audioEngine?.prepare()

        do {
            try audioEngine?.start()
            AppLog.info(.recording, "Audio engine started (level monitoring)")
        } catch {
            AppLog.error(.recording, "Audio engine failed to start (level monitoring): \(error.localizedDescription)")
            #if targetEnvironment(simulator)
            AppLog.notice(.recording, "Audio engine failure in simulator is expected for level monitoring", dedupeInterval: 5)
            #endif
        }

        adjustVolume()
    }
}
