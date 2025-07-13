import SwiftUI

/// A SwiftUI view that displays the scene description overlay with dark/light mode support
struct SceneDetectionOverlayView: View {
    let label: String?
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            if let label = label {
                Text(label)
                    .font(.headline)
                    .padding(8)
                    .background(overlayBackgroundColor)
                    .cornerRadius(8)
                    .foregroundColor(overlayTextColor)
                    .padding()
            }
            Spacer()
        }
    }
    
    // MARK: - Dark/Light Mode Color Helpers
    
    /// Overlay background color that adapts to dark/light mode
    private var overlayBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.black.opacity(0.8)
        case .light:
            return Color.black.opacity(0.6)
        @unknown default:
            return Color.black.opacity(0.6)
        }
    }
    
    /// Overlay text color that adapts to dark/light mode
    private var overlayTextColor: Color {
        return .white // White text works well on dark backgrounds in both modes
    }
}

#Preview {
    SceneDetectionOverlayView(label: "Indoor Living Room")
}
