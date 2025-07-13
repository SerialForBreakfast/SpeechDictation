import SwiftUI
import Vision

/// A SwiftUI view that overlays bounding boxes and labels for object detection results with dark/light mode support
struct ObjectDetectionOverlayView: View {
    let observations: [VNRecognizedObjectObservation]
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ForEach(observations, id: \.uuid) { observation in
                if let topLabel = observation.labels.first {
                    let rect = CGRect(
                        x: observation.boundingBox.origin.x * geometry.size.width,
                        y: (1 - observation.boundingBox.origin.y - observation.boundingBox.size.height) * geometry.size.height,
                        width: observation.boundingBox.size.width * geometry.size.width,
                        height: observation.boundingBox.size.height * geometry.size.height
                    )

                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .stroke(boundingBoxStrokeColor, lineWidth: 2)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)

                        Text("\(topLabel.identifier) \(Int(topLabel.confidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(labelTextColor)
                            .padding(4)
                            .background(labelBackgroundColor)
                            .cornerRadius(4)
                            .position(x: rect.minX + 4, y: rect.minY + 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Dark/Light Mode Color Helpers
    
    /// Bounding box stroke color that adapts to dark/light mode
    private var boundingBoxStrokeColor: Color {
        switch colorScheme {
        case .dark:
            return Color.green.opacity(0.9)
        case .light:
            return Color.green.opacity(0.8)
        @unknown default:
            return Color.green.opacity(0.8)
        }
    }
    
    /// Label background color that adapts to dark/light mode
    private var labelBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.black.opacity(0.8)
        case .light:
            return Color.black.opacity(0.7)
        @unknown default:
            return Color.black.opacity(0.7)
        }
    }
    
    /// Label text color that adapts to dark/light mode
    private var labelTextColor: Color {
        return .white // White text works well on dark backgrounds in both modes
    }
}

#Preview {
    ObjectDetectionOverlayView(observations: [])
}
