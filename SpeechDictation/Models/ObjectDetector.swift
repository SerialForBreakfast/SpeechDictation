import Foundation
import Vision
import CoreML
import UIKit

/// A detected object with a label, confidence, and bounding box in normalized coordinates.
struct DetectedObject {
    let label: String
    let confidence: Float
    let boundingBox: CGRect
}

/// A model-specific object detector for bounding boxes.
actor ObjectDetector {
    private let visionModel: VNCoreMLModel

    init(model: MLModel) {
        self.visionModel = try! VNCoreMLModel(for: model)
    }

    func detectObjects(in pixelBuffer: CVPixelBuffer) async -> [DetectedObject] {
        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        do {
            try handler.perform([request])
            guard let results = request.results as? [VNRecognizedObjectObservation] else { return [] }

            return results.map {
                let label = $0.labels.first?.identifier ?? "Unknown"
                let confidence = $0.labels.first?.confidence ?? 0
                return DetectedObject(label: label, confidence: confidence, boundingBox: $0.boundingBox)
            }
        } catch {
            print("Object detection failed: \(error)")
            return []
        }
    }
}
