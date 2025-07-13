import AVFoundation
import UIKit
import SwiftUI

/// A class that manages the live camera feed and delivers sample buffers.
/// Now supports dynamic orientation changes for proper camera display across device orientations.
/// Includes comprehensive frame monitoring and performance logging.
final class LiveCameraView: NSObject, ObservableObject {
    private let sessionQueue = DispatchQueue(label: "LiveCameraView.sessionQueue")
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var sampleBufferHandler: ((CMSampleBuffer) -> Void)?
    private var videoConnection: AVCaptureConnection?
    
    /// Current device orientation for Vision framework processing
    @Published var currentOrientation: UIDeviceOrientation = .portrait
    
    // MARK: - Frame Monitoring Properties
    private var frameCount: Int = 0
    private var droppedFrameCount: Int = 0
    private var lastFrameTime: Date = Date()
    private var frameRateMonitor: Timer?
    private let frameMonitoringQueue = DispatchQueue(label: "FrameMonitoringQueue", qos: .utility)
    
    // MARK: - Performance Metrics
    @Published var currentFrameRate: Double = 0.0
    @Published var averageFrameRate: Double = 0.0
    @Published var droppedFramePercentage: Double = 0.0
    @Published var isFrameDropping: Bool = false

    override init() {
        super.init()
        configureSession()
        startOrientationMonitoring()
        startFrameMonitoring()
    }
    
    deinit {
        stopOrientationMonitoring()
        stopFrameMonitoring()
    }

    /// Set a handler to process CMSampleBuffer frames.
    func setSampleBufferHandler(_ handler: @escaping (CMSampleBuffer) -> Void) {
        sampleBufferHandler = handler
    }

    /// Starts the camera capture session.
    func startSession() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
                print("📹 Camera session started")
            }
        }
    }

    /// Stops the camera capture session.
    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                print("📹 Camera session stopped")
            }
        }
    }
    
    // MARK: - Frame Monitoring
    
    /// Starts frame rate monitoring
    private func startFrameMonitoring() {
        frameRateMonitor = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateFrameRateMetrics()
        }
    }
    
    /// Stops frame rate monitoring
    private func stopFrameMonitoring() {
        frameRateMonitor?.invalidate()
        frameRateMonitor = nil
    }
    
    /// Updates frame rate metrics and logs performance
    private func updateFrameRateMetrics() {
        let currentTime = Date()
        let timeInterval = currentTime.timeIntervalSince(lastFrameTime)
        
        if timeInterval > 0 {
            currentFrameRate = Double(frameCount) / timeInterval
            averageFrameRate = currentFrameRate * 0.7 + averageFrameRate * 0.3 // Exponential moving average
            
            let totalFrames = frameCount + droppedFrameCount
            droppedFramePercentage = totalFrames > 0 ? (Double(droppedFrameCount) / Double(totalFrames)) * 100.0 : 0.0
            
            // Log performance metrics
            print("📊 Camera Performance - FPS: \(String(format: "%.1f", currentFrameRate)), Avg: \(String(format: "%.1f", averageFrameRate)), Dropped: \(String(format: "%.1f", droppedFramePercentage))%")
            
            // Warn if frame dropping is detected
            if droppedFramePercentage > 5.0 || currentFrameRate < 15.0 {
                isFrameDropping = true
                print("⚠️ Frame dropping detected! FPS: \(String(format: "%.1f", currentFrameRate)), Dropped: \(String(format: "%.1f", droppedFramePercentage))%")
            } else {
                isFrameDropping = false
            }
        }
        
        // Reset counters for next interval
        frameCount = 0
        droppedFrameCount = 0
        lastFrameTime = currentTime
    }
    
    /// Convert UIDeviceOrientation to AVCaptureVideoOrientation
    func videoOrientation(from deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch deviceOrientation {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeRight  // Camera is rotated 90° from device
        case .landscapeRight:
            return .landscapeLeft   // Camera is rotated 90° from device
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    /// Convert UIDeviceOrientation to CGImagePropertyOrientation for Vision framework
    func visionOrientation(from deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        switch deviceOrientation {
        case .portrait:
            return .right
        case .landscapeLeft:
            return .down
        case .landscapeRight:
            return .up
        case .portraitUpsideDown:
            return .left
        default:
            return .right
        }
    }
    
    /// Monitor device orientation changes
    private func startOrientationMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    /// Stop monitoring device orientation changes
    private func stopOrientationMonitoring() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    /// Handle orientation changes
    @objc private func orientationChanged() {
        let newOrientation = UIDevice.current.orientation
        
        // Only update for valid orientations
        guard newOrientation.isValidInterfaceOrientation else { return }
        
        DispatchQueue.main.async {
            self.currentOrientation = newOrientation
        }
        
        // Update video connection orientation
        sessionQueue.async {
            if let connection = self.videoConnection {
                connection.videoOrientation = self.videoOrientation(from: newOrientation)
            }
        }
    }

    /// Configure the AVCaptureSession with the camera input and video output.
    /// Optimized for performance and reduced frame drops with proper focus configuration.
    private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            
            // Use the lowest preset to reduce frame drops and CPU usage
            self.session.sessionPreset = .low // Changed from .medium to .low for minimal resource usage
            
            guard let camera = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  self.session.canAddInput(input) else {
                print("❌ Failed to access camera input")
                return
            }

            // Configure camera focus settings for sharp image quality
            self.configureCameraFocus(camera)

            self.session.addInput(input)

            // Optimize video output for better performance
            self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoOutputQueue", qos: .userInitiated))
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            
            // Set video settings for optimal performance
            if let videoConnection = self.videoOutput.connection(with: .video) {
                if videoConnection.isVideoStabilizationSupported {
                    videoConnection.preferredVideoStabilizationMode = .off // Disable stabilization to reduce processing
                }
            }

            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
                
                // Configure the connection orientation for proper ML processing
                if let connection = self.videoOutput.connection(with: .video) {
                    self.videoConnection = connection
                    connection.videoOrientation = self.videoOrientation(from: UIDevice.current.orientation)
                    // Let the system handle mirroring automatically to avoid crashes
                    // connection.isVideoMirrored = false
                }
                
                print("✅ Camera session configured successfully with focus optimization")
            } else {
                print("❌ Failed to add video output to session")
            }

            self.session.commitConfiguration()
        }
    }
    
    /// Configure camera focus settings for optimal image quality
    /// - Parameter camera: The AVCaptureDevice to configure
    /// - Note: This method must be called on the session queue to avoid threading issues
    private func configureCameraFocus(_ camera: AVCaptureDevice) {
        do {
            try camera.lockForConfiguration()
            
            // Enable continuous autofocus for sharp images
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
                print("✅ Continuous autofocus enabled")
            } else if camera.isFocusModeSupported(.autoFocus) {
                camera.focusMode = .autoFocus
                print("✅ Auto focus enabled")
            }
            
            // Enable continuous auto exposure for proper lighting
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
                print("✅ Continuous auto exposure enabled")
            }
            
            // Enable auto white balance for accurate colors
            if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                camera.whiteBalanceMode = .continuousAutoWhiteBalance
                print("✅ Continuous auto white balance enabled")
            }
            
            // Set focus point to center of frame for consistent focus
            if camera.isFocusPointOfInterestSupported {
                camera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                print("✅ Focus point set to center")
            }
            
            // Set exposure point to center for consistent exposure
            if camera.isExposurePointOfInterestSupported {
                camera.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
                print("✅ Exposure point set to center")
            }
            
            camera.unlockForConfiguration()
            print("✅ Camera focus and exposure configuration completed")
            
        } catch {
            print("❌ Failed to configure camera focus: \(error)")
        }
    }
}

extension LiveCameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Update frame monitoring
        frameMonitoringQueue.async {
            self.frameCount += 1
        }
        // Log every frame delivered to the ML pipeline
        print("📸 Frame delivered to ML pipeline at \(Date())")
        // Process the sample buffer
        sampleBufferHandler?(sampleBuffer)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameMonitoringQueue.async {
            self.droppedFrameCount += 1
            print("⚠️ Frame dropped: \(self.droppedFrameCount) total dropped frames")
        }
    }
}

extension UIDeviceOrientation {
    /// Check if orientation is valid for interface
    var isValidInterfaceOrientation: Bool {
        switch self {
        case .portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown:
            return true
        default:
            return false
        }
    }
}

/// A UIViewRepresentable wrapper to display the AVCaptureVideoPreviewLayer in SwiftUI.
/// Now supports dynamic orientation changes for proper camera display on all devices including iPad.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    @ObservedObject var cameraManager: LiveCameraView

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        // Use resizeAspectFill for better iPad display
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        // Set the preview layer orientation to match the camera connection
        if let connection = previewLayer.connection {
            connection.videoOrientation = cameraManager.videoOrientation(from: UIDevice.current.orientation)
            // Let the system handle mirroring automatically to avoid crashes
            // connection.isVideoMirrored = false
        }
        
        view.layer.addSublayer(previewLayer)

        // Keep previewLayer properly sized with proper timing
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            // Update frame to match view bounds
            previewLayer.frame = uiView.bounds
            
            // Update orientation when the view updates
            if let connection = previewLayer.connection {
                connection.videoOrientation = cameraManager.videoOrientation(from: cameraManager.currentOrientation)
                // Let the system handle mirroring automatically to avoid crashes
                // connection.isVideoMirrored = false
            }
        }
    }
}
