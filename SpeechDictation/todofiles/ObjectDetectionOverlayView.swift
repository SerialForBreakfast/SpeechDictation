import SwiftUI
import Vision

/// A SwiftUI view that overlays bounding boxes and labels for object detection results with spatial context
/// Always shows green color with proper undetected state and enhanced spatial descriptions
struct ObjectDetectionOverlayView: View {
    let observations: [VNRecognizedObjectObservation]
    let spatialDescriptions: [SpatialDescriptor.SpatialObjectDescription]
    let spatialSummary: String
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Always show the object detection info overlay with spatial context
            VStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detected Objects")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(overlayTextColor)
                    
                    Text(formatDetectedObjectsWithSpatialContext())
                        .font(adaptiveFont)
                        .fontWeight(.medium)
                        .foregroundColor(overlayTextColor)
                        .lineLimit(adaptiveLineLimit)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, adaptivePadding)
                .background(overlayBackgroundColor)
                .cornerRadius(12)
                .padding()
                
                Spacer()
            }
            
            // Enhanced bounding boxes for detected objects with spatial labels
            GeometryReader { geometry in
                ForEach(Array(observations.enumerated()), id: \.element.uuid) { index, observation in
                    if let topLabel = observation.labels.first,
                       index < spatialDescriptions.count {
                        let spatialDescription = spatialDescriptions[index]
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

                            Text("\(spatialDescription.compactDescription)")
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
    }
    
    // MARK: - Helper Methods
    
    /// Formats detected objects with spatial context into a readable string
    /// - Returns: Formatted string of detected objects with spatial positioning
    private func formatDetectedObjectsWithSpatialContext() -> String {
        guard !spatialDescriptions.isEmpty else {
            return spatialSummary.isEmpty ? "No objects detected" : spatialSummary
        }
        
        // Use the compact list format for UI display
        return SpatialDescriptor.formatCompactList(spatialDescriptions)
    }
    
    /// Formats detected objects into a readable string with proper undetected state (legacy method)
    /// - Returns: Formatted string of detected objects with confidence or undetected message
    private func formatDetectedObjects() -> String {
        guard !observations.isEmpty else {
            return "No objects detected"
        }
        
        let objectStrings = observations.compactMap { observation -> String? in
            guard let topLabel = observation.labels.first else { return nil }
            let confidence = Int(topLabel.confidence * 100)
            return "\(topLabel.identifier.capitalized) (\(confidence)%)"
        }
        
        // Show more objects for high-confidence detection (up to 6 objects)
        // This supports the user's request for multiple high-confidence object detection
        let maxObjects = min(objectStrings.count, 6)
        let displayedObjects = Array(objectStrings.prefix(maxObjects))
        
        // Format with line breaks for better readability when showing multiple objects
        if displayedObjects.count > 3 {
            return displayedObjects.joined(separator: "\n")
        } else {
            return displayedObjects.joined(separator: ", ")
        }
    }
    
    // MARK: - Dark/Light Mode Color Helpers
    
    /// Adaptive font size based on number of objects
    private var adaptiveFont: Font {
        return observations.count > 3 ? .caption : .subheadline
    }
    
    /// Adaptive line limit based on number of objects
    private var adaptiveLineLimit: Int {
        return observations.count > 3 ? 6 : 3
    }
    
    /// Adaptive padding based on number of objects
    private var adaptivePadding: CGFloat {
        return observations.count > 3 ? 16 : 12
    }
    
    /// Overlay background color that adapts to dark/light mode - Always green
    private var overlayBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.green.opacity(0.9)
        case .light:
            return Color.green.opacity(0.8)
        @unknown default:
            return Color.green.opacity(0.8)
        }
    }
    
    /// Overlay text color that adapts to dark/light mode
    private var overlayTextColor: Color {
        return .white // White text works well on green backgrounds in both modes
    }
    
    /// Bounding box stroke color that adapts to dark/light mode - Always green
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
            return Color.green.opacity(0.95)
        case .light:
            return Color.green.opacity(0.9)
        @unknown default:
            return Color.green.opacity(0.9)
        }
    }
    
    /// Label text color that adapts to dark/light mode
    private var labelTextColor: Color {
        return .white // White text works well on green backgrounds in both modes
    }
}

#Preview {
    ObjectDetectionOverlayView(observations: [], spatialDescriptions: [], spatialSummary: "")
        .previewDisplayName("No Objects")
}
