//
//  ContentView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/25/24.
//
//  Main content view with proper dark/light mode support and secure recordings integration.
//  Provides both standard transcription and secure private recording workflows.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var viewModel = SpeechRecognizerViewModel()
    @State private var showingCustomShare = false
    @State private var showingSecureRecordings = false
    @State private var showingTranscriptAudit = false
    @State private var isUserScrolling = false
    @State private var showJumpToLiveButton = false
    @State private var lastTranscriptLength = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            VStack {
                // Transcript area with intelligent autoscroll
                ZStack(alignment: .bottomTrailing) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack {
                                Text(viewModel.transcribedText)
                                    .font(.system(size: viewModel.fontSize))
                                    .foregroundColor(transcriptTextColor)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id("transcriptText")
                                
                                // Invisible marker at the bottom for scrolling
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(transcriptBackgroundColor)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(transcriptBorderColor, lineWidth: 1)
                        )
                        .shadow(color: shadowColor, radius: 5, x: 0, y: 0)
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { _ in
                                    // User started scrolling manually
                                    isUserScrolling = true
                                }
                        )
                        .onChange(of: viewModel.transcribedText) { newText in
                            handleTranscriptChange(newText: newText) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    
                    // Jump to Live button
                    if showJumpToLiveButton {
                        Button(action: {
                            jumpToLive()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 14))
                                Text("Jump to Live")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: shadowColor, radius: 4, x: 0, y: 0)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showJumpToLiveButton)
                    }
                }

                VStack(spacing: 12) {
                    startControls
                    utilityControls
                }
                .padding(.horizontal)
            }
            .padding()

            if viewModel.showSettings {
                overlayBackgroundColor
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.viewModel.showSettings.toggle()
                    }

                SettingsView(viewModel: viewModel)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: viewModel.showSettings)
            }
        }
        .onAppear {
            lastTranscriptLength = viewModel.transcribedText.count
        }
        .sheet(isPresented: $showingCustomShare) {
            NativeStyleShareView(
                text: viewModel.transcribedText,
                timingSession: viewModel.currentSession,
                isPresented: $showingCustomShare
            )
            .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showingSecureRecordings) {
            SecureRecordingsView(isPresented: $showingSecureRecordings)
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showingTranscriptAudit) {
            TranscriptAuditView()
                .preferredColorScheme(preferredColorScheme)
        }
        .preferredColorScheme(preferredColorScheme)
    }

    // MARK: - Color Helpers
    
    private var transcriptBackgroundColor: Color {
        switch viewModel.theme {
        case .system:
            #if canImport(UIKit)
            return Color(UIColor.systemBackground)
            #else
            return Color.gray.opacity(0.1)
            #endif
        case .light:
            return Color.white
        case .dark:
            return Color.black
        case .highContrast:
            return Color.yellow
        }
    }
    
    /// Color used for transcript text to ensure readability regardless of system-wide color scheme.
    private var transcriptTextColor: Color {
        switch viewModel.theme {
        case .system:
            return Color.primary
        case .light, .highContrast:
            return Color.black
        case .dark:
            return Color.white
        }
    }

    private var transcriptBorderColor: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.4 : 0.25)
    }

    private var preferredColorScheme: ColorScheme? {
        switch viewModel.theme {
        case .system:
            return nil
        case .light, .highContrast:
            return .light
        case .dark:
            return .dark
        }
    }
    
    private var startControls: some View {
        HStack(spacing: 12) {
            startListeningButton
            startRecordingButton
        }
    }
    
    private var utilityControls: some View {
        ViewThatFits {
            HStack(spacing: 12) {
                utilityButtons
            }
            VStack(spacing: 12) {
                utilityButtons
            }
        }
    }
    
    @ViewBuilder
    private var utilityButtons: some View {
        utilityButton(
            title: "Reset Text",
            systemImage: "arrow.clockwise",
            action: viewModel.resetTranscribedText,
            isDisabled: viewModel.transcribedText.isEmpty
        )
        
        utilityButton(
            title: "Secure Recordings",
            systemImage: "lock.shield",
            action: { showingSecureRecordings = true }
        )
        
        utilityButton(
            title: "Share",
            systemImage: "square.and.arrow.up",
            action: { showingCustomShare = true },
            isDisabled: !canExport
        )

        utilityButton(
            title: "Audit",
            systemImage: "doc.text.magnifyingglass",
            action: { showingTranscriptAudit = true }
        )
        
        utilityButton(
            title: "Settings",
            systemImage: "gearshape",
            action: { viewModel.showSettings.toggle() }
        )
    }
    
    private var startListeningButton: some View {
        actionButton(
            title: viewModel.isRecording ? "Stop" : "Transcribe",
            systemImage: viewModel.isRecording ? "pause.circle.fill" : "waveform",
            background: Color.accentColor,
            action: {
                if viewModel.isRecording {
                    viewModel.stopTranscribing()
                } else {
                    viewModel.startTranscribing()
                }
            }
        )
        .disabled(viewModel.isSecureRecordingActive)
        .opacity(viewModel.isSecureRecordingActive ? 0.6 : 1.0)
    }
    
    private var startRecordingButton: some View {
        actionButton(
            title: viewModel.isSecureRecordingActive ? "Stop" : "Record",
            systemImage: viewModel.isSecureRecordingActive ? "stop.circle.fill" : "mic.fill.badge.plus",
            background: Color.orange,
            action: {
                viewModel.toggleSecureRecording()
            }
        )
        .disabled(viewModel.isRecording)
        .opacity(viewModel.isRecording ? 0.6 : 1.0)
    }
    
    private func actionButton(
        title: String,
        systemImage: String,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(.title3, design: .default).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundColor(.white)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(background)
        )
        .shadow(color: shadowColor.opacity(0.5), radius: 4, x: 0, y: 2)
    }
    
    private func utilityButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void,
        isDisabled: Bool = false
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(.subheadline, design: .default).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(secondaryButtonBackgroundColor)
        )
        .shadow(color: shadowColor.opacity(0.25), radius: 2, x: 0, y: 1)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    private var secondaryButtonBackgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }
    
    private var resetButtonBackgroundColor: Color {
        Color.orange.opacity(colorScheme == .dark ? 0.3 : 0.2)
    }
    
    private var resetButtonForegroundColor: Color {
        Color.orange
    }
    
    private var overlayBackgroundColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.6 : 0.4)
    }
    
    private var shadowColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1)
    }

    /// Applies the current theme to the user interface
    /// Note: Modern iOS apps should use the system appearance settings
    /// rather than programmatically overriding the interface style
    private func applyTheme() {
        // Theme changes are now handled through the system appearance settings
        // and the view's color scheme environment
    }
    
    // MARK: - Export Functionality
    
    /// Checks if export functionality is available (text is not empty)
    private var canExport: Bool {
        !viewModel.transcribedText.isEmpty
    }
    
    // MARK: - Intelligent Autoscroll Functionality
    
    /// Handles transcript text changes for intelligent scrolling
    /// - Parameters:
    ///   - newText: The updated transcript text
    ///   - scrollToBottom: Closure to scroll to bottom
    private func handleTranscriptChange(newText: String, scrollToBottom: @escaping () -> Void) {
        let hasNewContent = newText.count > lastTranscriptLength
        lastTranscriptLength = newText.count
        
        // Only auto-scroll if:
        // 1. There's new content (transcript is growing)
        // 2. User is not currently scrolling manually
        // 3. Jump to live button is not showing (user is at bottom)
        if hasNewContent && !isUserScrolling && !showJumpToLiveButton {
            withAnimation(.easeOut(duration: 0.3)) {
                scrollToBottom()
            }
        }
        
        // Reset user scrolling flag after a delay
        if isUserScrolling {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isUserScrolling = false
                checkScrollPosition()
            }
        }
    }
    
    /// Checks the current scroll position and shows/hides the jump to live button
    private func checkScrollPosition() {
        // This is a simplified approach - in a real implementation you might want
        // to use more sophisticated scroll position detection
        
        // For now, we'll show the button when user has scrolled and hide it when at bottom
        // This can be enhanced with actual scroll position calculations
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if isUserScrolling {
                // User has scrolled away from bottom
                withAnimation(.easeInOut(duration: 0.3)) {
                    showJumpToLiveButton = true
                }
            }
        }
    }
    
    /// Jumps to the live transcript and resumes auto-scrolling
    private func jumpToLive() {
        withAnimation(.easeOut(duration: 0.5)) {
            showJumpToLiveButton = false
            isUserScrolling = false
        }
        
        // Force scroll to bottom after hiding button
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                // This will be handled by the ScrollViewReader in the next transcript update
                if viewModel.isRecording {
                    // Trigger a small change to force scroll
                    lastTranscriptLength = viewModel.transcribedText.count - 1
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
