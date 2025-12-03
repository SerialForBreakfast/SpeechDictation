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

struct ContentView: View {
    @ObservedObject var viewModel = SpeechRecognizerViewModel()
    @State private var showingCustomShare = false
    @State private var showingSecureRecordings = false
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

                HStack {
                    Button(action: {
                        if self.viewModel.isRecording {
                            self.viewModel.stopTranscribing()
                        } else {
                            self.viewModel.startTranscribing()
                        }
                    }) {
                        Text(viewModel.isRecording ? "Stop Listening" : "Start Listening")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                            .background(primaryActionButtonColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: shadowColor, radius: 2, x: 0, y: 0)
                    }

                    // Reset button - clears text without stopping recording
                    Button(action: {
                        self.viewModel.resetTranscribedText()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .padding()
                            .background(resetButtonBackgroundColor)
                            .foregroundColor(resetButtonForegroundColor)
                            .clipShape(Circle())
                            .shadow(color: shadowColor, radius: 2, x: 0, y: 0)
                    }
                    .disabled(viewModel.transcribedText.isEmpty)
                    .opacity(viewModel.transcribedText.isEmpty ? 0.5 : 1.0)

                    Spacer()

                    // Secure Recordings button
                    Button(action: {
                        showingSecureRecordings = true
                    }) {
                        Image(systemName: "lock.shield")
                            .font(.title2)
                            .padding()
                            .background(secureRecordingsButtonBackgroundColor)
                            .foregroundColor(secureRecordingsButtonForegroundColor)
                            .clipShape(Circle())
                            .shadow(color: shadowColor, radius: 2, x: 0, y: 0)
                    }
                    .accessibilityLabel("Secure Recordings")
                    .accessibilityHint("Access private recordings with authentication")

                    Button(action: {
                        showingCustomShare = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .padding()
                            .background(shareButtonBackgroundColor)
                            .foregroundColor(shareButtonForegroundColor)
                            .clipShape(Circle())
                            .shadow(color: shadowColor, radius: 2, x: 0, y: 0)
                    }
                    .disabled(!canExport)
                    .opacity(canExport ? 1.0 : 0.5)
                    .padding(.trailing, 10)

                    Button(action: {
                        self.viewModel.showSettings.toggle()
                    }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .padding()
                            .background(settingsButtonBackgroundColor)
                            .foregroundColor(settingsButtonForegroundColor)
                            .clipShape(Circle())
                            .shadow(color: shadowColor, radius: 2, x: 0, y: 0)
                    }
                }
                .padding()
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
                    .animation(.easeInOut)
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
        }
        .sheet(isPresented: $showingSecureRecordings) {
            SecureRecordingsView(isPresented: $showingSecureRecordings)
        }
    }

    // MARK: - Color Helpers
    
    private var transcriptBackgroundColor: Color {
        switch viewModel.theme {
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
        case .light, .highContrast:
            return Color.black
        case .dark:
            return Color.white
        }
    }
    
    private var primaryActionButtonColor: Color {
        Color.accentColor
    }
    
    private var resetButtonBackgroundColor: Color {
        Color.orange.opacity(colorScheme == .dark ? 0.3 : 0.2)
    }
    
    private var resetButtonForegroundColor: Color {
        Color.orange
    }
    
    /// Secure recordings button styling following existing patterns
    private var secureRecordingsButtonBackgroundColor: Color {
        Color.blue.opacity(colorScheme == .dark ? 0.3 : 0.2)
    }
    
    /// Secure recordings button styling following existing patterns  
    private var secureRecordingsButtonForegroundColor: Color {
        Color.blue
    }
    
    private var shareButtonBackgroundColor: Color {
        Color.green.opacity(colorScheme == .dark ? 0.3 : 0.2)
    }
    
    private var shareButtonForegroundColor: Color {
        Color.green
    }
    
    private var settingsButtonBackgroundColor: Color {
        Color(UIColor.tertiarySystemFill)
    }
    
    private var settingsButtonForegroundColor: Color {
        Color.primary
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
