import Foundation
import Combine

/// Manager for camera-related settings using UserDefaults for persistence
/// Provides reactive updates for settings changes across the app
final class CameraSettingsManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CameraSettingsManager()
    
    // MARK: - Published Properties
    @Published var sceneUpdateFrequency: Double {
        didSet {
            UserDefaults.standard.set(sceneUpdateFrequency, forKey: Keys.sceneUpdateFrequency)
        }
    }
    
    @Published var enableObjectDetection: Bool {
        didSet {
            UserDefaults.standard.set(enableObjectDetection, forKey: Keys.enableObjectDetection)
        }
    }
    
    @Published var enableSceneDescription: Bool {
        didSet {
            UserDefaults.standard.set(enableSceneDescription, forKey: Keys.enableSceneDescription)
        }
    }
    
    @Published var detectionSensitivity: Double {
        didSet {
            UserDefaults.standard.set(detectionSensitivity, forKey: Keys.detectionSensitivity)
        }
    }
    
    // MARK: - Private Keys
    private enum Keys {
        static let sceneUpdateFrequency = "camera.sceneUpdateFrequency"
        static let enableObjectDetection = "camera.enableObjectDetection"
        static let enableSceneDescription = "camera.enableSceneDescription"
        static let detectionSensitivity = "camera.detectionSensitivity"
    }
    
    // MARK: - Initialization
    
    /// Initialize the settings manager and load saved values from UserDefaults
    /// - Note: This is a singleton - use CameraSettingsManager.shared
    private init() {
        // Load saved values or use defaults
        self.sceneUpdateFrequency = UserDefaults.standard.double(forKey: Keys.sceneUpdateFrequency) 
        self.enableObjectDetection = UserDefaults.standard.bool(forKey: Keys.enableObjectDetection)
        self.enableSceneDescription = UserDefaults.standard.bool(forKey: Keys.enableSceneDescription)
        self.detectionSensitivity = UserDefaults.standard.double(forKey: Keys.detectionSensitivity)
        
        // Set defaults if no values are stored
        if sceneUpdateFrequency == 0 {
            sceneUpdateFrequency = 1.0
        }
        if detectionSensitivity == 0 {
            detectionSensitivity = 0.5
        }
        if UserDefaults.standard.object(forKey: Keys.enableObjectDetection) == nil {
            enableObjectDetection = true
        }
        if UserDefaults.standard.object(forKey: Keys.enableSceneDescription) == nil {
            enableSceneDescription = true
        }
    }
} 