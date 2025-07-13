import SwiftUI

/// Comprehensive model management interface for browsing, downloading, and managing ML models
/// Features model catalog browsing, download progress, and model switching capabilities
struct ModelManagementView: View {
    @StateObject private var modelCatalog = ModelCatalog.shared
    @StateObject private var downloadManager = ModelDownloadManager.shared
    @StateObject private var modelLoader = DynamicModelLoader.shared
    @State private var selectedTab: ModelType = .objectDetection
    @State private var showingModelDetails: ModelMetadata?
    @State private var searchText = ""
    @State private var selectedPerformance: ModelPerformance?
    @State private var showingSettings = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with refresh and settings
                headerSection
                
                // Model type tabs
                modelTypeTabs
                
                // Search and filters
                searchAndFilters
                
                // Model list
                modelListSection
            }
            .navigationTitle("Model Store")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .refreshable {
                await refreshCatalog()
            }
            .sheet(item: $showingModelDetails) { model in
                ModelDetailView(model: model)
            }
            .sheet(isPresented: $showingSettings) {
                ModelStorageSettingsView()
            }
        }
        .task {
            await loadInitialData()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Model Store")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let lastUpdate = modelCatalog.lastUpdateTime {
                    Text("Updated \(lastUpdate, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if modelCatalog.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var modelTypeTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ModelType.allCases, id: \.self) { type in
                    ModelTypeTab(
                        type: type,
                        isSelected: selectedTab == type,
                        modelCount: modelCatalog.models(ofType: type).count
                    ) {
                        selectedTab = type
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            // Search bar
            SearchBar(text: $searchText)
            
            // Performance filter
            if !ModelPerformance.allCases.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ModelPerformance.allCases, id: \.self) { performance in
                            PerformanceFilterChip(
                                performance: performance,
                                isSelected: selectedPerformance == performance
                            ) {
                                selectedPerformance = selectedPerformance == performance ? nil : performance
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var modelListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredModels, id: \.id) { model in
                    ModelCard(model: model) {
                        showingModelDetails = model
                    }
                }
                
                if filteredModels.isEmpty && !modelCatalog.isLoading {
                    EmptyModelListView(selectedTab: selectedTab, searchText: searchText)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredModels: [ModelMetadata] {
        var models = modelCatalog.models(ofType: selectedTab)
        
        // Apply search filter
        if !searchText.isEmpty {
            models = models.filter { model in
                model.name.localizedCaseInsensitiveContains(searchText) ||
                model.description.localizedCaseInsensitiveContains(searchText) ||
                model.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply performance filter
        if let performance = selectedPerformance {
            models = models.filter { $0.performance == performance }
        }
        
        return models.sorted { model1, model2 in
            // Sort by installation status first, then by name
            let state1 = modelCatalog.installationState(for: model1.id)
            let state2 = modelCatalog.installationState(for: model2.id)
            
            if state1.isInstalled && !state2.isInstalled {
                return true
            } else if !state1.isInstalled && state2.isInstalled {
                return false
            } else {
                return model1.name < model2.name
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadInitialData() async {
        await modelCatalog.refreshCatalog()
    }
    
    private func refreshCatalog() async {
        await modelCatalog.refreshCatalog(force: true)
    }
}

// MARK: - Supporting Views

struct ModelTypeTab: View {
    let type: ModelType
    let isSelected: Bool
    let modelCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: type.icon)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if modelCount > 0 {
                        Text("\(modelCount)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                if isSelected {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 2)
                        .cornerRadius(1)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        }
        .foregroundColor(isSelected ? .accentColor : .secondary)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search models...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct PerformanceFilterChip: View {
    let performance: ModelPerformance
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(performance.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ModelCard: View {
    let model: ModelMetadata
    let action: () -> Void
    
    @StateObject private var modelCatalog = ModelCatalog.shared
    @StateObject private var downloadManager = ModelDownloadManager.shared
    @StateObject private var modelLoader = DynamicModelLoader.shared
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(model.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Model icon and performance badge
                    VStack(spacing: 4) {
                        Image(systemName: model.type.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                        
                        Text(model.performance.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(performanceColor.opacity(0.2))
                            .foregroundColor(performanceColor)
                            .cornerRadius(4)
                    }
                }
                
                // Metadata
                HStack {
                    Label(model.formattedFileSize, systemImage: "externaldrive")
                    
                    Spacer()
                    
                    if let accuracy = model.accuracy {
                        Label("\(Int(accuracy * 100))%", systemImage: "target")
                    }
                    
                    if let inferenceTime = model.inferenceTimeMS {
                        Label("\(Int(inferenceTime))ms", systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Status and action
                HStack {
                    statusIndicator
                    
                    Spacer()
                    
                    actionButton
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(installationState.displayText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
    }
    
    private var actionButton: some View {
        Group {
            switch installationState {
            case .notInstalled:
                Button("Download") {
                    Task {
                        _ = await downloadManager.downloadModel(model.id)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
            case .downloading(let progress):
                VStack(spacing: 2) {
                    ProgressView(value: progress)
                        .frame(width: 60)
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                }
                
            case .installed, .updateAvailable:
                HStack(spacing: 8) {
                    if modelLoader.isModelLoaded(model.id) {
                        Button("Unload") {
                            modelLoader.unloadModel(model.id)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Button("Load") {
                            Task {
                                _ = await modelLoader.loadModel(model.id)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    if case .updateAvailable = installationState {
                        Button("Update") {
                            Task {
                                _ = await downloadManager.downloadModel(model.id)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                
            case .failed:
                Button("Retry") {
                    Task {
                        _ = await downloadManager.downloadModel(model.id)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
            case .installing:
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }
    
    private var installationState: ModelInstallationState {
        modelCatalog.installationState(for: model.id)
    }
    
    private var statusColor: Color {
        switch installationState {
        case .installed: return .green
        case .downloading, .installing: return .blue
        case .updateAvailable: return .orange
        case .failed: return .red
        case .notInstalled: return .gray
        }
    }
    
    private var performanceColor: Color {
        switch model.performance {
        case .ultraLight: return .green
        case .light: return .mint
        case .balanced: return .blue
        case .performance: return .orange
        case .maxQuality: return .purple
        }
    }
}

struct EmptyModelListView: View {
    let selectedTab: ModelType
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "cube.box" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No \(selectedTab.displayName) Models" : "No Results")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(searchText.isEmpty ? 
                 "No \(selectedTab.displayName.lowercased()) models are available yet." :
                 "Try adjusting your search or filters.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Model Detail View

struct ModelDetailView: View {
    let model: ModelMetadata
    @Environment(\.dismiss) private var dismiss
    @StateObject private var modelCatalog = ModelCatalog.shared
    @StateObject private var downloadManager = ModelDownloadManager.shared
    @StateObject private var modelLoader = DynamicModelLoader.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    modelHeader
                    
                    // Description
                    modelDescription
                    
                    // Specifications
                    modelSpecs
                    
                    // Performance metrics
                    performanceSection
                    
                    // Compatibility
                    compatibilitySection
                    
                    // Actions
                    actionSection
                }
                .padding()
            }
            .navigationTitle(model.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var modelHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(model.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(model.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(model.type.displayName, systemImage: model.type.icon)
                    
                    Label(model.performance.displayName, systemImage: "speedometer")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var modelDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(model.description)
                .font(.body)
        }
    }
    
    private var modelSpecs: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Specifications")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                SpecRow(label: "Version", value: model.version)
                SpecRow(label: "File Size", value: model.formattedFileSize)
                SpecRow(label: "Memory Required", value: "\(model.requiredMemoryMB) MB")
                SpecRow(label: "Author", value: model.author)
                SpecRow(label: "License", value: model.license)
            }
        }
    }
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                if let accuracy = model.accuracy {
                    SpecRow(label: "Accuracy", value: "\(Int(accuracy * 100))%")
                }
                
                if let inferenceTime = model.inferenceTimeMS {
                    SpecRow(label: "Inference Time", value: "\(Int(inferenceTime)) ms")
                }
                
                SpecRow(label: "Performance Tier", value: model.performance.displayName)
            }
        }
    }
    
    private var compatibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compatibility")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: model.isCompatible ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(model.isCompatible ? .green : .red)
                
                Text(model.isCompatible ? "Compatible with this device" : "Not compatible with this device")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            if !model.supportedDevices.isEmpty {
                Text("Supported Devices: \(model.supportedDevices.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            // Primary action button
            switch modelCatalog.installationState(for: model.id) {
            case .notInstalled:
                Button("Download Model") {
                    Task {
                        _ = await downloadManager.downloadModel(model.id)
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!model.isCompatible)
                
            case .downloading(let progress):
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                    Text("Downloading... \(Int(progress * 100))%")
                        .font(.caption)
                }
                
            case .installing:
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Installing...")
                        .font(.caption)
                }
                
            case .installed:
                HStack(spacing: 12) {
                    if modelLoader.isModelLoaded(model.id) {
                        Button("Unload Model") {
                            modelLoader.unloadModel(model.id)
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("Set as Current") {
                            Task {
                                await modelLoader.setCurrentModel(model.id)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    } else {
                        Button("Load Model") {
                            Task {
                                _ = await modelLoader.loadModel(model.id)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                }
                
            case .updateAvailable:
                Button("Update Model") {
                    Task {
                        _ = await downloadManager.downloadModel(model.id)
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
            case .failed(let error):
                VStack(spacing: 8) {
                    Text("Download failed: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Button("Retry Download") {
                        Task {
                            _ = await downloadManager.downloadModel(model.id)
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct SpecRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Model Storage Settings

struct ModelStorageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var modelLoader = DynamicModelLoader.shared
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Storage Usage") {
                    HStack {
                        Text("Total Memory Used")
                        Spacer()
                        Text("\(modelLoader.totalMemoryUsage()) MB")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Loaded Models")
                        Spacer()
                        Text("\(modelLoader.loadedModels(ofType: .objectDetection).count + modelLoader.loadedModels(ofType: .sceneClassification).count)")
                            .fontWeight(.medium)
                    }
                }
                
                Section("Actions") {
                    Button("Clear All Loaded Models") {
                        showingClearAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Model Storage")
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
                Text("This will unload all models from memory. You can reload them later.")
            }
        }
    }
}

#Preview {
    ModelManagementView()
} 