import SwiftUI

/// View for managing currently loaded models and switching between them
/// Shows active models, memory usage, and performance metrics
struct CurrentModelsView: View {
    @StateObject private var modelLoader = DynamicModelLoader.shared
    @StateObject private var modelCatalog = ModelCatalog.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Memory usage summary
                    memoryUsageSection
                    
                    // Current active models
                    activeModelsSection
                    
                    // Object detection models
                    loadedModelsSection(type: .objectDetection, title: "Object Detection Models")
                    
                    // Scene classification models
                    loadedModelsSection(type: .sceneClassification, title: "Scene Classification Models")
                    
                    // Actions
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Current Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Clear All Models", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    modelLoader.clearAllModels()
                }
            } message: {
                Text("This will unload all models from memory. Embedded models will be reloaded automatically.")
            }
        }
    }
    
    // MARK: - View Components
    
    private var memoryUsageSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "memorychip")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memory Usage")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(modelLoader.totalMemoryUsage()) MB used by \(totalLoadedModels) models")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var activeModelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Models")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                // Current object detection model
                if let currentObjectModel = modelLoader.currentObjectModel {
                    ActiveModelRow(
                        title: "Object Detection",
                        modelName: modelName(for: currentObjectModel),
                        icon: "viewfinder.rectangular",
                        color: .green
                    )
                } else {
                    InactiveModelRow(
                        title: "Object Detection",
                        icon: "viewfinder.rectangular",
                        color: .green
                    )
                }
                
                // Current scene classification model
                if let currentSceneModel = modelLoader.currentSceneModel {
                    ActiveModelRow(
                        title: "Scene Classification",
                        modelName: modelName(for: currentSceneModel),
                        icon: "camera.aperture",
                        color: .blue
                    )
                } else {
                    InactiveModelRow(
                        title: "Scene Classification",
                        icon: "camera.aperture",
                        color: .blue
                    )
                }
            }
        }
    }
    
    private func loadedModelsSection(type: ModelType, title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            let loadedModelIds = modelLoader.loadedModels(ofType: type)
            
            if loadedModelIds.isEmpty {
                EmptyModelSection(type: type)
            } else {
                VStack(spacing: 8) {
                    ForEach(loadedModelIds, id: \.self) { modelId in
                        LoadedModelRow(
                            modelId: modelId,
                            type: type,
                            isActive: isActiveModel(modelId, type: type)
                        )
                    }
                }
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            if totalLoadedModels > 0 {
                Button("Clear All Models") {
                    showingClearAlert = true
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            NavigationLink("Browse Model Store") {
                ModelManagementView()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var totalLoadedModels: Int {
        modelLoader.loadedModels(ofType: .objectDetection).count +
        modelLoader.loadedModels(ofType: .sceneClassification).count
    }
    
    private func modelName(for model: Any) -> String {
        if let yoloModel = model as? YOLOv3Model {
            return "YOLOv3Tiny (Embedded)"
        } else if let placesModel = model as? Places365SceneDescriber {
            return "Places365 (Enhanced)"
        } else if let downloadableObject = model as? DownloadableObjectDetectionModel {
            return modelCatalog.model(withId: downloadableObject.modelId)?.name ?? "Unknown Model"
        } else if let downloadableScene = model as? DownloadableSceneDescriber {
            return modelCatalog.model(withId: downloadableScene.modelId)?.name ?? "Unknown Model"
        } else {
            return "Unknown Model"
        }
    }
    
    private func isActiveModel(_ modelId: String, type: ModelType) -> Bool {
        switch type {
        case .objectDetection:
            if let currentModel = modelLoader.currentObjectModel as? DownloadableObjectDetectionModel {
                return currentModel.modelId == modelId
            }
            return modelId == "embedded_yolo3" && modelLoader.currentObjectModel is YOLOv3Model
            
        case .sceneClassification:
            if let currentModel = modelLoader.currentSceneModel as? DownloadableSceneDescriber {
                return currentModel.modelId == modelId
            }
            return modelId == "embedded_places365" && modelLoader.currentSceneModel is Places365SceneDescriber
            
        default:
            return false
        }
    }
}

// MARK: - Supporting Views

struct ActiveModelRow: View {
    let title: String
    let modelName: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(modelName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text("Active")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct InactiveModelRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("No model active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Inactive")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

struct LoadedModelRow: View {
    let modelId: String
    let type: ModelType
    let isActive: Bool
    
    @StateObject private var modelLoader = DynamicModelLoader.shared
    @StateObject private var modelCatalog = ModelCatalog.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(modelDisplayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    if let performance = modelPerformance {
                        Text("Load time: \(String(format: "%.2f", performance.loadTime ?? 0))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let memory = performance.memoryMB {
                            Text("• \(memory) MB")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                } else {
                    Button("Set Active") {
                        Task {
                            await modelLoader.setCurrentModel(modelId)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                
                Button("Unload") {
                    modelLoader.unloadModel(modelId)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
        )
    }
    
    private var modelDisplayName: String {
        if modelId == "embedded_yolo3" {
            return "YOLOv3Tiny (Embedded)"
        } else if modelId == "embedded_places365" {
            return "Places365 (Enhanced)"
        } else {
            return modelCatalog.model(withId: modelId)?.name ?? "Unknown Model"
        }
    }
    
    private var modelPerformance: (loadTime: TimeInterval?, memoryMB: Int64?)? {
        return modelLoader.modelPerformance(modelId)
    }
}

struct EmptyModelSection: View {
    let type: ModelType
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            
            Text("No \(type.displayName) Models Loaded")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Browse the model store to download and load additional models")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    CurrentModelsView()
} 