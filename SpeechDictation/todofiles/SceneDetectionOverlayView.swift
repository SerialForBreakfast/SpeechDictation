import SwiftUI

/// A SwiftUI view that displays the scene description overlay.
struct SceneDetectionOverlayView: View {
    let label: String?

    var body: some View {
        VStack {
            if let label = label {
                Text(label)
                    .font(.headline)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .padding()
            }
            Spacer()
        }
    }
}

#Preview {
    SceneDetectionOverlayView(label: "Indoor Living Room")
}
