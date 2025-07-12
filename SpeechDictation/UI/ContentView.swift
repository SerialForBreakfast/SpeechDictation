//
//  ContentView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/25/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = SpeechRecognizerViewModel()
    @State private var showingCustomShare = false
    @State private var isUserScrolling = false
    @State private var showJumpToLiveButton = false
    @State private var lastTranscriptLength = 0
    
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
                        .background(backgroundColor)
                        .cornerRadius(10)
                        .shadow(radius: 5)
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
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(radius: 4)
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
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Spacer()

                    Button(action: {
                        showingCustomShare = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .clipShape(Circle())
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
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
            .padding()

            if viewModel.showSettings {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.viewModel.showSettings.toggle()
                    }

                SettingsView(viewModel: viewModel)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .padding()
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut)
            }
            

        }
        .onAppear {
            applyTheme()
            lastTranscriptLength = viewModel.transcribedText.count
        }
        .onChange(of: viewModel.theme) { _ in
            applyTheme()
        }
        .sheet(isPresented: $showingCustomShare) {
            NativeStyleShareView(
                text: viewModel.transcribedText,
                timingSession: viewModel.currentSession,
                isPresented: $showingCustomShare
            )
        }
    }

    private var backgroundColor: Color {
        switch viewModel.theme {
        case .light:
            return Color.white
        case .dark:
            return Color.black
        case .highContrast:
            return Color.yellow
        }
    }

    private func applyTheme() {
        switch viewModel.theme {
        case .light:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
        case .dark:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
        case .highContrast:
            // For high contrast, you might want to set a specific override, if necessary.
            break
        }
    }
    
    // MARK: - Export Functionality
    
    /// Checks if export functionality is available (text is not empty)
    private var canExport: Bool {
        !viewModel.transcribedText.isEmpty && viewModel.transcribedText != "Tap a button to begin"
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
