import SwiftUI

/// SwiftUI view for configuring depth-based distance estimation settings
/// Provides toggle control and information about device capabilities
struct DepthSettingView: View {
    @ObservedObject private var cameraSettings = CameraSettingsManager.shared
    @State private var availableDepthSources: [DepthEstimationService.DepthSource] = []
    @State private var depthService: DepthEstimationService?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "camera.metering.matrix")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                
                Text("Depth-Based Distance")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Toggle("", isOn: $cameraSettings.enableDepthBasedDistance)
                    .labelsHidden()
                    .scaleEffect(0.8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Description
            Text("Use hardware sensors and ML models to measure actual distances to objects for more accurate spatial descriptions.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            
            // Depth Sources Info
            if !availableDepthSources.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Depth Sources:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(availableDepthSources, id: \.self) { source in
                            DepthSourceBadge(source: source)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Performance Note
            if cameraSettings.enableDepthBasedDistance {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("Depth estimation may slightly impact performance on older devices.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .onAppear {
            loadDepthCapabilities()
        }
    }
    
    /// Load available depth sources from the depth service
    private func loadDepthCapabilities() {
        Task {
            let service = DepthEstimationService()
            self.depthService = service
            
            let sources = await service.getAvailableDepthSources()
            await MainActor.run {
                self.availableDepthSources = sources
            }
        }
    }
}

/// Badge view for displaying depth source capabilities
struct DepthSourceBadge: View {
    let source: DepthEstimationService.DepthSource
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
                .foregroundColor(badgeColor)
            
            Text(displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(badgeColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(badgeColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var iconName: String {
        switch source {
        case .lidar:
            return "laser.burst"
        case .arkit:
            return "arkit"
        case .mlModel:
            return "brain.head.profile"
        case .fallback:
            return "rectangle.badge.minus"
        }
    }
    
    private var displayName: String {
        switch source {
        case .lidar:
            return "LiDAR"
        case .arkit:
            return "ARKit"
        case .mlModel:
            return "ML Model"
        case .fallback:
            return "Fallback"
        }
    }
    
    private var badgeColor: Color {
        switch source {
        case .lidar:
            return .blue
        case .arkit:
            return .green
        case .mlModel:
            return .purple
        case .fallback:
            return .gray
        }
    }
}

/// Preview for development
struct DepthSettingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DepthSettingView()
                .padding()
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
        .previewLayout(.sizeThatFits)
    }
} 