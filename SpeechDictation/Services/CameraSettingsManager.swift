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
    
    @Published var enableDepthBasedDistance: Bool {
        didSet {
            UserDefaults.standard.set(enableDepthBasedDistance, forKey: Keys.enableDepthBasedDistance)
        }
    }
    
    @Published var enableAudioDescriptions: Bool {
        didSet {
            UserDefaults.standard.set(enableAudioDescriptions, forKey: Keys.enableAudioDescriptions)
        }
    }
    
    @Published var enableAutofocus: Bool {
        didSet {
            UserDefaults.standard.set(enableAutofocus, forKey: Keys.enableAutofocus)
            // Notify camera manager to reconfigure focus settings
            NotificationCenter.default.post(name: .autofocusSettingChanged, object: nil)
        }
    }
    
    // MARK: - Private Keys
    private enum Keys {
        static let sceneUpdateFrequency = "camera.sceneUpdateFrequency"
        static let enableObjectDetection = "camera.enableObjectDetection"
        static let enableSceneDescription = "camera.enableSceneDescription"
        static let detectionSensitivity = "camera.detectionSensitivity"
        static let enableDepthBasedDistance = "camera.enableDepthBasedDistance"
        static let enableAudioDescriptions = "camera.enableAudioDescriptions"
        static let enableAutofocus = "camera.enableAutofocus"
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
        self.enableDepthBasedDistance = UserDefaults.standard.bool(forKey: Keys.enableDepthBasedDistance)
        self.enableAudioDescriptions = UserDefaults.standard.bool(forKey: Keys.enableAudioDescriptions)
        self.enableAutofocus = UserDefaults.standard.bool(forKey: Keys.enableAutofocus)
        
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
        if UserDefaults.standard.object(forKey: Keys.enableDepthBasedDistance) == nil {
            enableDepthBasedDistance = false // Default to false since it requires additional processing
        }
        if UserDefaults.standard.object(forKey: Keys.enableAudioDescriptions) == nil {
            enableAudioDescriptions = false // Default to false to avoid unexpected speech
        }
        if UserDefaults.standard.object(forKey: Keys.enableAutofocus) == nil {
            enableAutofocus = true // Default to true for automatic focus
        }
    }
    
    // MARK: - Reset Functionality
    
    /// Resets all camera settings to their default values
    /// - Note: This will trigger all published property observers to update UI
    func resetToDefaults() {
        AppLog.info(.camera, "Resetting camera settings to defaults...")
        
        // Reset all settings to their default values
        self.sceneUpdateFrequency = 1.0
        self.enableObjectDetection = true
        self.enableSceneDescription = true
        self.detectionSensitivity = 0.5
        self.enableDepthBasedDistance = false
        self.enableAudioDescriptions = false
        self.enableAutofocus = true
        
        AppLog.info(.camera, "Camera settings reset to defaults")
    }
    
    // MARK: - Default Values
    
    /// Default values for camera settings
    enum DefaultValues {
        static let sceneUpdateFrequency: Double = 1.0
        static let enableObjectDetection: Bool = true
        static let enableSceneDescription: Bool = true
        static let detectionSensitivity: Double = 0.5
        static let enableDepthBasedDistance: Bool = false
        static let enableAudioDescriptions: Bool = false
        static let enableAutofocus: Bool = true
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let autofocusSettingChanged = Notification.Name("autofocusSettingChanged")
} 
