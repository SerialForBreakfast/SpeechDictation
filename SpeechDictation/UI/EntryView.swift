import SwiftUI

/// Entry view that allows users to choose between audio transcription and camera-based experiences
/// This view serves as the main entry point for the application with comprehensive accessibility support
struct EntryView: View {
    @State private var selectedExperience: ExperienceType?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityInvertColors) private var invertColors
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient with high contrast support
                backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                    .accessibilityHidden(true) // Hide decorative background from VoiceOver
                
                ScrollView {
                    VStack(spacing: adaptiveSpacing) {
                        // Header section
                        headerSection
                            .padding(.top, adaptiveTopPadding)
                        
                        // Experience options
                        experienceOptionsSection
                            .padding(.horizontal, 24)
                        
                        // Footer
                        footerSection
                            .padding(.bottom, 40)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Experience Selection")
                .accessibilityHint("Choose between audio transcription and camera experiences")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accessibilityAction(named: "Select Audio Transcription") {
            selectedExperience = .audioTranscription
        }
        .accessibilityAction(named: "Select Camera Experience") {
            selectedExperience = .cameraInput
        }
    }
    
    // MARK: - View Components
    
    /// Header section with app title and subtitle
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Speech Dictation")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text("Choose your experience")
                .font(.title2)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)
                .minimumScaleFactor(0.9)
                .lineLimit(2)
        }
        .multilineTextAlignment(.center)
    }
    
    /// Experience options section with accessible cards
    private var experienceOptionsSection: some View {
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
                    isRecommended: true,
                    differentiateWithoutColor: differentiateWithoutColor
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Audio Transcription, recommended")
            .accessibilityHint("Converts your speech to text with real-time transcription. Double tap to select.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Select") {
                selectedExperience = .audioTranscription
            }
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
                    isRecommended: false,
                    differentiateWithoutColor: differentiateWithoutColor
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Live Camera Input, experimental")
            .accessibilityHint("Experimental feature for object detection and scene description using camera. Double tap to select.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Select") {
                selectedExperience = .cameraInput
            }
            .onTapGesture {
                selectedExperience = .cameraInput
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Experience Options")
    }
    
    /// Footer section with instructional text
    private var footerSection: some View {
        Text("Select an experience to get started")
            .font(.caption)
            .foregroundColor(.secondary)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityLabel("Instructions: Select an experience to get started")
    }
    
    // MARK: - Accessibility Helpers
    
    /// Background gradient with high contrast support
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Adaptive gradient colors based on accessibility settings
    private var gradientColors: [Color] {
        if invertColors {
            return [Color.primary.opacity(0.1), Color.secondary.opacity(0.1)]
        } else {
            return [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]
        }
    }
    
    /// Adaptive spacing based on dynamic type size
    private var adaptiveSpacing: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 40
        case .large, .xLarge, .xxLarge:
            return 50
        case .xxxLarge:
            return 60
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return 70
        @unknown default:
            return 40
        }
    }
    
    /// Adaptive top padding based on dynamic type size
    private var adaptiveTopPadding: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 60
        case .large, .xLarge, .xxLarge:
            return 40
        case .xxxLarge:
            return 30
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return 20
        @unknown default:
            return 60
        }
    }
    
    /// Creates the camera view with the required models
    /// - Returns: A configured view for camera experience
    private func createCameraView() -> some View {
        // TODO: Implement camera view when models are properly imported
        Text("Camera Experience Coming Soon")
            .font(.title)
            .foregroundColor(.secondary)
            .accessibilityLabel("Camera Experience Coming Soon")
            .accessibilityHint("This feature is under development and will be available soon")
    }
}

/// Represents the different experience types available in the app
enum ExperienceType {
    case audioTranscription
    case cameraInput
}

/// A card component that displays information about each experience option with accessibility support
struct ExperienceCard: View {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    let isRecommended: Bool
    let differentiateWithoutColor: Bool
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        HStack(spacing: adaptiveSpacing) {
            // Icon with accessibility support
            iconView
            
            // Content section
            contentSection
            
            Spacer()
            
            // Chevron indicator
            chevronView
        }
        .padding(adaptivePadding)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
    
    // MARK: - View Components
    
    /// Icon view with proper accessibility traits
    private var iconView: some View {
        Image(systemName: systemImage)
            .font(.system(size: iconSize))
            .foregroundColor(color)
            .frame(width: iconFrameSize, height: iconFrameSize)
            .background(color.opacity(0.1))
            .clipShape(Circle())
            .accessibilityHidden(true) // Icon is decorative, label provides context
    }
    
    /// Content section with title and description
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if isRecommended {
                    recommendedBadge
                }
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    /// Recommended badge with accessibility support
    private var recommendedBadge: some View {
        Text("RECOMMENDED")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(recommendedBadgeColor)
            .cornerRadius(8)
            .accessibilityLabel("Recommended option")
    }
    
    /// Chevron navigation indicator
    private var chevronView: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.secondary)
            .accessibilityHidden(true) // Decorative element
    }
    
    // MARK: - Accessibility Helpers
    
    /// Comprehensive accessibility label
    private var accessibilityLabel: String {
        let baseLabel = "\(title). \(description)"
        return isRecommended ? "\(baseLabel). Recommended option." : baseLabel
    }
    
    /// Accessibility hint for interaction
    private var accessibilityHint: String {
        "Double tap to select this experience"
    }
    
    /// Card background with high contrast support
    private var cardBackground: Color {
        if differentiateWithoutColor {
            return Color.primary.opacity(0.05)
        } else {
            return Color.white
        }
    }
    
    /// Recommended badge color with contrast support
    private var recommendedBadgeColor: Color {
        if differentiateWithoutColor {
            return Color.primary
        } else {
            return Color.green
        }
    }
    
    /// Shadow color with accessibility considerations
    private var shadowColor: Color {
        if differentiateWithoutColor {
            return Color.primary.opacity(0.2)
        } else {
            return Color.black.opacity(0.1)
        }
    }
    
    /// Adaptive spacing based on dynamic type
    private var adaptiveSpacing: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 20
        case .large, .xLarge, .xxLarge:
            return 16
        case .xxxLarge:
            return 12
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return 10
        @unknown default:
            return 20
        }
    }
    
    /// Adaptive padding based on dynamic type
    private var adaptivePadding: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 20
        case .large, .xLarge, .xxLarge:
            return 24
        case .xxxLarge:
            return 28
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return 32
        @unknown default:
            return 20
        }
    }
    
    /// Adaptive icon size based on dynamic type
    private var iconSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 32
        case .large, .xLarge, .xxLarge:
            return 36
        case .xxxLarge:
            return 40
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return 44
        @unknown default:
            return 32
        }
    }
    
    /// Adaptive icon frame size
    private var iconFrameSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 60
        case .large, .xLarge, .xxLarge:
            return 64
        case .xxxLarge:
            return 68
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return 72
        @unknown default:
            return 60
        }
    }
    
    /// Adaptive shadow radius
    private var shadowRadius: CGFloat {
        reduceMotion ? 4 : 8
    }
    
    /// Adaptive shadow offset
    private var shadowOffset: CGFloat {
        reduceMotion ? 2 : 4
    }
}

struct EntryView_Previews: PreviewProvider {
    static var previews: some View {
        EntryView()
            .previewDisplayName("Default")
    }
} 