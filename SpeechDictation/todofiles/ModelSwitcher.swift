import Foundation
import Combine

/// Protocol for any model that supports switching in the scene analysis pipeline.
protocol SwitchableModel {
    var modelName: String { get }
}

/// Enum to define available scene description models.
enum SceneModelType: String, CaseIterable {
    case places365 = "Places365"
    case none = "None"
}

/// Enum to define available object detection models.
enum ObjectModelType: String, CaseIterable {
    case yolov3 = "YOLOv3"
    case none = "None"
}

/// A ViewModel responsible for switching between object and scene models.
final class ModelSwitcher: ObservableObject {
    @Published var selectedSceneModel: SceneModelType = .places365 {
        didSet {
            updateSceneModel()
        }
    }

    @Published var selectedObjectModel: ObjectModelType = .yolov3 {
        didSet {
            updateObjectModel()
        }
    }

    @Published private(set) var currentSceneModel: SceneDescribingModel?
    @Published private(set) var currentObjectModel: ObjectDetectionModel?

    init() {
        updateSceneModel()
        updateObjectModel()
    }

    private func updateSceneModel() {
        switch selectedSceneModel {
        case .places365:
            currentSceneModel = Places365SceneDescriber()
        case .none:
            currentSceneModel = nil
        }
    }

    private func updateObjectModel() {
        switch selectedObjectModel {
        case .yolov3:
            currentObjectModel = YOLOv3Model()
        case .none:
            currentObjectModel = nil
        }
    }
}
