import SwiftUI

/// A SwiftUI view that displays the scene description overlay with dark/light mode support
/// Always shows blue color with proper undetected state
struct SceneDetectionOverlayView: View {
    let label: String?
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scene Environment")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(overlayTextColor)
                
                Text(label ?? "Analyzing scene...")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(overlayTextColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(overlayBackgroundColor)
            .cornerRadius(12)
            .padding()
            
            Spacer()
        }
    }
    
    // MARK: - Dark/Light Mode Color Helpers
    
    /// Overlay background color that adapts to dark/light mode - Always blue
    private var overlayBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.blue.opacity(0.9)
        case .light:
            return Color.blue.opacity(0.8)
        @unknown default:
            return Color.blue.opacity(0.8)
        }
    }
    
    /// Overlay text color that adapts to dark/light mode
    private var overlayTextColor: Color {
        return .white // White text works well on blue backgrounds in both modes
    }
}

#Preview {
    SceneDetectionOverlayView(label: "Indoor Living Room")
}

#Preview {
    SceneDetectionOverlayView(label: nil)
        .previewDisplayName("Undetected State")
}
