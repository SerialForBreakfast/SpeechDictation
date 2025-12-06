//
//  SecurePlaybackView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 12/06/25.
//
//  Secure playback interface for private recordings.
//  Presents authenticated media controls with transcript highlighting tied to timing data.
//

import SwiftUI
import Combine

/// View model that coordinates secure playback using the shared audio engine while keeping secure data isolated.
@MainActor
final class SecurePlaybackViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var playbackState: PlaybackState = .stopped
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var highlightedSegmentID: UUID?
    @Published private(set) var segments: [TranscriptionSegment] = []
    
    let session: SecureRecordingSession
    let sessionTitle: String
    let sessionDateDescription: String
    
    private let playbackManager: AudioPlaybackManager
    private let secureRecordingManager: SecureRecordingManager
    private var cancellables = Set<AnyCancellable>()
    private var hasPreparedResources = false
    
    init(
        session: SecureRecordingSession,
        playbackManager: AudioPlaybackManager = .shared,
        secureRecordingManager: SecureRecordingManager = .shared
    ) {
        self.session = session
        self.playbackManager = playbackManager
        self.secureRecordingManager = secureRecordingManager
        self.sessionTitle = session.displayTitle
        self.sessionDateDescription = session.startTime.formatted(.dateTime.day().month().hour().minute())
        bindPlaybackManager()
    }
    
    /// Binds published values from the shared playback manager.
    private func bindPlaybackManager() {
        playbackManager.$playbackState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.playbackState = state
            }
            .store(in: &cancellables)
        
        playbackManager.$currentTime
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                self?.currentTime = time
            }
            .store(in: &cancellables)
        
        playbackManager.$duration
            .receive(on: RunLoop.main)
            .sink { [weak self] duration in
                self?.duration = duration
            }
            .store(in: &cancellables)
        
        playbackManager.$currentSegment
            .receive(on: RunLoop.main)
            .sink { [weak self] segment in
                self?.highlightedSegmentID = segment?.id
            }
            .store(in: &cancellables)
    }
    
    /// Loads secure resources if needed and primes the playback manager.
    func preparePlaybackIfNeeded() {
        guard !hasPreparedResources else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            let resources = secureRecordingManager.loadPlaybackResources(for: session)
            guard let resources = resources else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Secure playback resources are unavailable for this recording."
                }
                return
            }
            
            await MainActor.run {
                self.apply(resources: resources)
            }
        }
    }
    
    /// Applies secure resources to the playback manager and local state.
    private func apply(resources: SecurePlaybackResources) {
        hasPreparedResources = true
        segments = resources.segments
        
        print("SecurePlayback: Preparing with \(resources.segments.count) segments")
        print("SecurePlayback: Audio URL: \(resources.audioURL)")
        print("SecurePlayback: Transcript length: \(resources.transcript.count) chars")
        print("SecurePlayback: First 3 segments: \(resources.segments.prefix(3).map { $0.text })")
        
        // Build full transcript from segments for display
        let fullTranscript = resources.segments.map { $0.text }.joined(separator: " ")
        print("SecurePlayback: Built full transcript: \(fullTranscript.count) chars")
        print("SecurePlayback: Transcript preview: \(fullTranscript.prefix(200))...")
        
        let normalizedWordCount = fullTranscript
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count
        
        let playbackSession = AudioRecordingSession(
            sessionId: session.id,
            startTime: session.startTime,
            endTime: session.endTime,
            audioFileURL: resources.audioURL,
            segments: resources.segments,
            totalDuration: session.duration,
            wordCount: normalizedWordCount
        )
        
        print("SecurePlayback: Loading audio for playback...")
        playbackManager.loadAudioForPlayback(
            audioURL: resources.audioURL,
            session: playbackSession
        )
        
        print("SecurePlayback: Playback duration: \(playbackManager.duration)s")
        
        isLoading = false
    }
    
    /// Toggles between play and pause states.
    func togglePlayback() {
        switch playbackState {
        case .playing:
            playbackManager.pause()
        default:
            playbackManager.play()
        }
    }
    
    /// Seeks to a specific timeline position.
    func seek(to time: TimeInterval) {
        playbackManager.seekToTime(time)
    }
    
    /// Jumps backward by 30 seconds.
    func skipBackward() {
        seek(to: currentTime - 30)
    }
    
    /// Jumps forward by 30 seconds.
    func skipForward() {
        seek(to: currentTime + 30)
    }
    
    /// Stops playback and clears buffers.
    func teardown() {
        playbackManager.stop()
        secureRecordingManager.stopSecurePlayback()
    }
    
    /// Formats the elapsed playback time.
    var formattedElapsed: String {
        format(time: currentTime)
    }
    
    /// Formats the remaining playback time.
    var formattedRemaining: String {
        let remaining = max(0, duration - currentTime)
        return format(time: remaining)
    }
    
    private func format(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Secure playback modal displaying media controls and transcript highlighting.
struct SecurePlaybackView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SecurePlaybackViewModel
    @State private var infoAlertPresented = false
    
    init(session: SecureRecordingSession) {
        _viewModel = StateObject(
            wrappedValue: SecurePlaybackViewModel(session: session)
        )
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle(viewModel.sessionTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            closeModal()
                        }
                        .font(.headline)
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            viewModel.preparePlaybackIfNeeded()
        }
        .onDisappear {
            viewModel.teardown()
        }
    }
    
    private var content: some View {
        VStack(spacing: 24) {
            header
            mediaControls
            transcriptList
        }
        .padding()
        .overlay {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
            } else if viewModel.isLoading {
                ProgressView("Preparing secure playback…")
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.sessionDateDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                Text("Secure Playback")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button {
                    // Show inline info using alert/tooltip
                    infoAlertPresented = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.footnote)
                        .accessibilityLabel("Secure playback information")
                }
                .buttonStyle(.borderless)
                .accessibilityAddTraits(.isButton)
                .alert("Secure Playback", isPresented: $infoAlertPresented) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Secure playback keeps audio and transcripts on-device. Transcript highlighting follows the spoken audio.")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var mediaControls: some View {
        VStack(spacing: 16) {
            Slider(
                value: Binding(
                    get: { viewModel.currentTime },
                    set: { viewModel.seek(to: $0) }
                ),
                in: 0...max(viewModel.duration, 0.1)
            )
            .disabled(viewModel.duration == 0)
            
            HStack {
                Text(viewModel.formattedElapsed)
                    .font(.caption)
                Spacer()
                Text("-\(viewModel.formattedRemaining)")
                    .font(.caption)
            }
            
            HStack(spacing: 32) {
                Button(action: viewModel.skipBackward) {
                    Image(systemName: "gobackward.30")
                        .font(.title2)
                }
                .disabled(viewModel.duration == 0)
                
                Button(action: viewModel.togglePlayback) {
                    Image(
                        systemName: viewModel.playbackState == .playing
                        ? "pause.circle.fill"
                        : "play.circle.fill"
                    )
                    .font(.system(size: 56))
                }
                .disabled(viewModel.duration == 0)
                
                Button(action: viewModel.skipForward) {
                    Image(systemName: "goforward.30")
                        .font(.title2)
                }
                .disabled(viewModel.duration == 0)
            }
        }
    }
    
    private var transcriptList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcript")
                .font(.headline)
            
            if viewModel.segments.isEmpty {
                Text("Transcript will appear here once playback is ready.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Build a cleaned transcript: remove empty segment texts and trim whitespace
                let cleanedTranscript = viewModel.segments
                    .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                
                TranscriptScrollView(
                    segments: viewModel.segments,
                    highlightedID: viewModel.highlightedSegmentID,
                    fullTranscript: cleanedTranscript
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 280)
            }
        }
    }
    
    private func closeModal() {
        dismiss()
    }
}

/// Transcript view that displays text as flowing paragraphs with word-level highlighting
private struct TranscriptScrollView: View {
    let segments: [TranscriptionSegment]
    let highlightedID: UUID?
    let fullTranscript: String
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Display full transcript as flowing text with inline highlighting
                    Text(attributedTranscript)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    
                    // Hidden anchors for scroll-to functionality
                    ForEach(segments, id: \.id) { segment in
                        Color.clear
                            .frame(height: 0)
                            .id(segment.id)
                    }
                }
                .padding(.vertical, 4)
            }
            .onChange(of: highlightedID) { newValue in
                guard let id = newValue else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(id, anchor: .top)
                }
            }
        }
    }
    
    /// Creates an attributed string with the currently spoken word highlighted
    private var attributedTranscript: AttributedString {
        guard !fullTranscript.isEmpty else {
            print("TranscriptScrollView: fullTranscript is EMPTY!")
            return AttributedString("No transcript available")
        }
        
        print("TranscriptScrollView: Building attributed string from \(fullTranscript.count) chars")
        var result = AttributedString(fullTranscript)
        
        // Find and highlight the current segment's text
        if let highlightedID = highlightedID,
           let currentSegment = segments.first(where: { $0.id == highlightedID }) {
            
            print("TranscriptScrollView: Highlighting segment: '\(currentSegment.text)'")
            
            // Find the range of the current segment's text in the full transcript
            if let range = result.range(of: currentSegment.text) {
                result[range].font = .body.bold()
                result[range].backgroundColor = Color.accentColor.opacity(0.2)
                print("TranscriptScrollView: Applied highlighting to range")
            } else {
                print("TranscriptScrollView: WARNING - Could not find '\(currentSegment.text)' in transcript")
            }
        }
        
        return result
    }
}

