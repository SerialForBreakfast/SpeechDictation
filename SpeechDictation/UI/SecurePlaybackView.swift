//
//  SecurePlaybackView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 12/06/25.
//

import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

/// View for playing back secure recordings with synchronized transcript
struct SecurePlaybackView: View {
    let session: SecureRecordingSession
    @StateObject private var playbackManager = AudioPlaybackManager.shared
    // Removed StateObject wrapper since CacheManager is not ObservableObject
    private var cacheManager = CacheManager.shared
    @State private var segments: [TranscriptionSegment] = []
    @State private var audioURL: URL?
    @State private var isSliderEditing = false
    
    init(session: SecureRecordingSession) {
        self.session = session
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Transcript View
            ScrollViewReader { proxy in
                ScrollView {
                    if segments.isEmpty {
                        Text("No transcript available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        FlowLayout(lineSpacing: 8, itemSpacing: 4) {
                            ForEach(segments) { segment in
                                wordView(for: segment)
                                    .id(segment.id)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .onChange(of: playbackManager.currentSegment?.id) { newId in
                    if let newId, !isSliderEditing {
                        withAnimation {
                            proxy.scrollTo(newId, anchor: .center)
                        }
                    }
                }
            }
            
            Divider()
            
            // Playback Controls
            VStack(spacing: 16) {
                // Scrubber
                HStack {
                    Text(playbackManager.getFormattedCurrentTime())
                        .font(.caption)
                        .monospacedDigit()
                    
                    Slider(
                        value: Binding(
                            get: { playbackManager.currentTime },
                            set: { newValue in
                                isSliderEditing = true
                                playbackManager.seekToTime(newValue)
                            }
                        ),
                        in: 0...playbackManager.duration,
                        onEditingChanged: { editing in
                            isSliderEditing = editing
                        }
                    )
                    
                    Text(playbackManager.getFormattedDuration())
                        .font(.caption)
                        .monospacedDigit()
                }
                
                // Buttons
                HStack(spacing: 40) {
                    Button(action: { playbackManager.seekToTime(playbackManager.currentTime - 15) }) {
                        Image(systemName: "gobackward.15")
                            .font(.title2)
                    }
                    
                    Button(action: {
                        if playbackManager.playbackState == .playing {
                            playbackManager.pause()
                        } else {
                            playbackManager.play()
                        }
                    }) {
                        Image(systemName: playbackManager.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 56))
                    }
                    
                    Button(action: { playbackManager.seekToTime(playbackManager.currentTime + 15) }) {
                        Image(systemName: "goforward.15")
                            .font(.title2)
                    }
                }
                .padding(.vertical, 8)
                
                // Speed Control
                Picker("Speed", selection: Binding(
                    get: { playbackManager.playbackSpeed },
                    set: { playbackManager.setPlaybackSpeed($0) }
                )) {
                    ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                        Text(speed.displayName).tag(speed)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
        .navigationTitle(session.title.isEmpty ? session.displayTitle : session.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSessionData()
        }
        .onDisappear {
            playbackManager.stop()
        }
    }
    
    private func loadSessionData() {
        // Load Audio
        var resolvedAudioURL = cacheManager.getSecureFileURL(fileName: session.audioFileName, sessionId: session.id)

        // If metadata is stale (older builds wrote a placeholder filename), fall back to scanning the session directory.
        if !FileManager.default.fileExists(atPath: resolvedAudioURL.path) {
            let candidates = cacheManager
                .listSecureFiles(inSubdirectory: session.id)
                .filter { ["caf", "m4a"].contains($0.pathExtension.lowercased()) }

            if let candidate = candidates.first {
                resolvedAudioURL = candidate
            }
        }

        self.audioURL = resolvedAudioURL
        
        // Load Transcript Segments
        if let transcriptData = cacheManager.retrieveSecureData(forKey: session.transcriptFileName, subdirectory: session.id) {
            
            // Mirroring the struct from SecureRecordingManager
            struct SecureTranscriptPayload: Codable {
                let transcript: String
                let segments: [TranscriptionSegment]
                let savedAt: Date
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let payload = try? decoder.decode(SecureTranscriptPayload.self, from: transcriptData) {
                self.segments = payload.segments
                
                // Create a temporary AudioRecordingSession for the PlaybackManager
                let audioSession = AudioRecordingSession(
                    sessionId: session.id,
                    startTime: session.startTime,
                    endTime: session.endTime,
                    audioFileURL: resolvedAudioURL,
                    segments: payload.segments,
                    totalDuration: session.duration,
                    wordCount: payload.segments.reduce(0) { $0 + $1.text.components(separatedBy: " ").count }
                )
                
                playbackManager.loadAudioForPlayback(audioURL: resolvedAudioURL, session: audioSession)
            } else {
                AppLog.error(.secureRecording, "Failed to decode transcript payload")
            }
        } else {
            AppLog.error(.secureRecording, "Failed to retrieve transcript data")
        }
    }
    
    private func isCurrentSegment(_ segment: TranscriptionSegment) -> Bool {
        return playbackManager.currentSegment?.id == segment.id
    }
    
    private func wordView(for segment: TranscriptionSegment) -> some View {
        let isCurrent = isCurrentSegment(segment)
        let fontSize = baseFontSize + (isCurrent ? 2 : 0)
        let weight: Font.Weight = isCurrent ? .bold : .regular
        return Text(segment.text + " ")
            .font(.system(size: fontSize, weight: weight))
            .foregroundColor(.primary)
            .onTapGesture {
                playbackManager.seekToSegment(segment)
            }
            .accessibilityLabel(segment.text)
    }
    
    private var baseFontSize: CGFloat {
        #if canImport(UIKit)
        return UIFont.preferredFont(forTextStyle: .body).pointSize
        #else
        return 16
        #endif
    }
}

/// A simple flow layout that wraps child views across lines.
struct FlowLayout: Layout {
    let lineSpacing: CGFloat
    let itemSpacing: CGFloat

    init(lineSpacing: CGFloat = 8, itemSpacing: CGFloat = 4) {
        self.lineSpacing = lineSpacing
        self.itemSpacing = itemSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var currentLineWidth: CGFloat = 0
        var currentLineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let requiredWidth = currentLineWidth == 0 ? size.width : currentLineWidth + itemSpacing + size.width

            if maxWidth > 0 && requiredWidth > maxWidth {
                totalHeight += currentLineHeight + lineSpacing
                maxLineWidth = max(maxLineWidth, currentLineWidth)
                currentLineWidth = size.width
                currentLineHeight = size.height
            } else {
                currentLineWidth = requiredWidth
                currentLineHeight = max(currentLineHeight, size.height)
            }
        }

        totalHeight += currentLineHeight
        maxLineWidth = max(maxLineWidth, currentLineWidth)

        return CGSize(width: maxWidth > 0 ? maxWidth : maxLineWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x != bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + itemSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
