import SwiftUI
import AVFoundation
import Vision

/// View that displays a live camera feed with object detection and scene description overlays.
struct CameraSceneDescriptionView: View {
    @StateObject private var viewModel: CameraSceneDescriptionViewModel
    private let cameraManager = LiveCameraView()

    init(objectDetector: ObjectDetectionModel, sceneDescriber: SceneDescribingModel) {
        _viewModel = StateObject(wrappedValue: CameraSceneDescriptionViewModel(
            objectDetector: objectDetector,
            sceneDescriber: sceneDescriber
        ))
    }

    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    cameraManager.setSampleBufferHandler(viewModel.processSampleBuffer)
                    cameraManager.startSession()
                }
                .onDisappear {
                    cameraManager.stopSession()
                }

            if let scene = viewModel.sceneLabel {
                VStack {
                    Text(scene)
                        .font(.headline)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                }
            }

            ForEach(viewModel.detectedObjects, id: \.uuid) { object in
                if let topLabel = object.labels.first {
                    ObjectBoundingBoxView(boundingBox: object.boundingBox, label: topLabel.identifier, confidence: topLabel.confidence)
                }
            }

            if let error = viewModel.errorMessage {
                VStack {
                    Text("⚠️ \(error)")
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                }
            }
        }
    }
}

struct ObjectBoundingBoxView: View {
    let boundingBox: CGRect
    let label: String
    let confidence: VNConfidence

    var body: some View {
        GeometryReader { geometry in
            let rect = CGRect(
                x: boundingBox.origin.x * geometry.size.width,
                y: (1 - boundingBox.origin.y - boundingBox.size.height) * geometry.size.height,
                width: boundingBox.size.width * geometry.size.width,
                height: boundingBox.size.height * geometry.size.height
            )
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

                Text("\(label) \(String(format: "%.0f", confidence * 100))%")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .position(x: rect.minX + 4, y: rect.minY + 4)
            }
        }
    }
}

#Preview {
    CameraSceneDescriptionView(
        objectDetector: YOLOv3Model()!,
        sceneDescriber: Places365SceneDescriber()
    )
}
