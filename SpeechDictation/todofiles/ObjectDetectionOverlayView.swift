import SwiftUI
import Vision

/// A SwiftUI view that overlays bounding boxes and labels for object detection results.
struct ObjectDetectionOverlayView: View {
    let observations: [VNRecognizedObjectObservation]

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
                            .stroke(Color.green, lineWidth: 2)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)

                        Text("\(topLabel.identifier) \(Int(topLabel.confidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                            .position(x: rect.minX + 4, y: rect.minY + 4)
                    }
                }
            }
        }
    }
}

#Preview {
    ObjectDetectionOverlayView(observations: [])
}
