import SwiftUI

/// Entry view that allows users to choose between audio transcription and camera-based experiences
/// This view serves as the main entry point for the application
struct EntryView: View {
    @State private var selectedExperience: ExperienceType?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Speech Dictation")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Choose your experience")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    
                    // Experience options
                    VStack(spacing: 24) {
                        // Audio Transcription Experience
                        NavigationLink(
                            destination: ContentView(),
                            tag: ExperienceType.audioTranscription,
                            selection: $selectedExperience
                        ) {
                            ExperienceCard(
                                title: "Audio Transcription",
                                description: "Convert speech to text with real-time transcription",
                                systemImage: "mic.fill",
                                color: .blue,
                                isRecommended: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onTapGesture {
                            selectedExperience = .audioTranscription
                        }
                        
                        // Camera Experience
                        NavigationLink(
                            destination: createCameraView(),
                            tag: ExperienceType.cameraInput,
                            selection: $selectedExperience
                        ) {
                            ExperienceCard(
                                title: "Live Camera Input",
                                description: "Experimental: Object detection and scene description",
                                systemImage: "camera.fill",
                                color: .purple,
                                isRecommended: false
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onTapGesture {
                            selectedExperience = .cameraInput
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Footer
                    Text("Select an experience to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 40)
                }
            }

        }
    }
    
    /// Creates the camera view with the required models
    /// - Returns: A configured view for camera experience
    private func createCameraView() -> some View {
        // TODO: Implement camera view when models are properly imported
        Text("Camera Experience Coming Soon")
            .font(.title)
            .foregroundColor(.secondary)
    }
}

/// Represents the different experience types available in the app
enum ExperienceType {
    case audioTranscription
    case cameraInput
}

/// A card component that displays information about each experience option
struct ExperienceCard: View {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    let isRecommended: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if isRecommended {
                        Text("RECOMMENDED")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct EntryView_Previews: PreviewProvider {
    static var previews: some View {
        EntryView()
    }
} 