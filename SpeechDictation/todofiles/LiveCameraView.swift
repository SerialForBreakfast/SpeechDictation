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
    var previewLayer: AVCaptureVideoPreviewLayer?
    var latestSampleBuffer: CMSampleBuffer?
    
    /// Current device orientation for Vision framework processing
    @Published var currentOrientation: UIDeviceOrientation = .portrait
    @Published var isFlashlightOn: Bool = false

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
        startAutofocusMonitoring()
    }
    
    deinit {
        stopOrientationMonitoring()
        stopFrameMonitoring()
        stopAutofocusMonitoring()
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
                print("Camera session started")
            }
        }
    }

    /// Stops the camera capture session.
    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                print("Camera session stopped")
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
            print("Camera Performance - FPS: \(String(format: "%.1f", currentFrameRate)), Avg: \(String(format: "%.1f", averageFrameRate)), Dropped: \(String(format: "%.1f", droppedFramePercentage))%")
            
            // Warn if frame dropping is detected
            if droppedFramePercentage > 5.0 || currentFrameRate < 15.0 {
                isFrameDropping = true
                print("Frame dropping detected! FPS: \(String(format: "%.1f", currentFrameRate)), Dropped: \(String(format: "%.1f", droppedFramePercentage))%")
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
    
    /// Start monitoring autofocus setting changes
    private func startAutofocusMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(autofocusSettingChanged),
            name: .autofocusSettingChanged,
            object: nil
        )
    }
    
    /// Stop monitoring autofocus setting changes
    private func stopAutofocusMonitoring() {
        NotificationCenter.default.removeObserver(self, name: .autofocusSettingChanged, object: nil)
    }
    
    /// Handle autofocus setting changes
    @objc private func autofocusSettingChanged() {
        reconfigureFocus()
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
                print(" Failed to access camera input")
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
                
                print(" Camera session configured successfully with focus optimization")
            } else {
                print("Failed to add video output to session")
            }

            self.session.commitConfiguration()
        }
    }

    /// Toggles the device's flashlight.
    func toggleFlashlight() {
        sessionQueue.async {
            guard let camera = AVCaptureDevice.default(for: .video), camera.hasTorch else { return }
            
            do {
                try camera.lockForConfiguration()
                let isOn = camera.torchMode == .on
                camera.torchMode = isOn ? .off : .on
                camera.unlockForConfiguration()
                
                DispatchQueue.main.async {
                    self.isFlashlightOn = !isOn
                }
            } catch {
                print("Failed to toggle flashlight: \(error)")
            }
        }
    }
    
    /// Reconfigures camera focus settings when autofocus setting changes
    func reconfigureFocus() {
        sessionQueue.async {
            guard let camera = AVCaptureDevice.default(for: .video) else { return }
            self.configureCameraFocus(camera)
        }
    }

    /// Sets the focus and exposure point of the camera to a specified point.
    /// - Parameter point: The point in the view's coordinate system to focus on.
    func focus(at point: CGPoint) {
        print("Focus requested at point: \(point)")
        
        guard let camera = AVCaptureDevice.default(for: .video), let previewLayer = self.previewLayer else { 
            print("ERROR: Cannot focus - camera or preview layer not available")
            return 
        }
        
        // Convert the tap point to camera coordinates, accounting for device orientation
        let cameraPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        
        // Ensure the point is within valid bounds (0.0 to 1.0)
        let clampedPoint = CGPoint(
            x: max(0.0, min(1.0, cameraPoint.x)),
            y: max(0.0, min(1.0, cameraPoint.y))
        )
        
        print("Camera point: \(cameraPoint), clamped: \(clampedPoint)")
        
        sessionQueue.async {
            do {
                try camera.lockForConfiguration()
                
                // Always allow tap-to-focus regardless of autofocus setting
                if camera.isFocusPointOfInterestSupported {
                    camera.focusPointOfInterest = clampedPoint
                    camera.focusMode = .autoFocus
                    print("Focus point set to: \(clampedPoint)")
                } else {
                    print("WARNING: Focus point of interest not supported")
                }
                
                if camera.isExposurePointOfInterestSupported {
                    camera.exposurePointOfInterest = clampedPoint
                    camera.exposureMode = .autoExpose
                    print("Exposure point set to: \(clampedPoint)")
                } else {
                    print("WARNING: Exposure point of interest not supported")
                }
                
                camera.unlockForConfiguration()
                print("Focus configuration completed successfully")
            } catch {
                print("ERROR: Failed to set focus point: \(error)")
            }
        }
    }

    /// Configure camera focus settings for optimal image quality
    /// - Parameter camera: The AVCaptureDevice to configure
    /// - Note: This method must be called on the session queue to avoid threading issues
    private func configureCameraFocus(_ camera: AVCaptureDevice) {
        do {
            try camera.lockForConfiguration()
            
            // Check autofocus setting from CameraSettingsManager
            let settings = CameraSettingsManager.shared
            
            if settings.enableAutofocus {
                // Enable continuous autofocus for sharp images
                if camera.isFocusModeSupported(.continuousAutoFocus) {
                    camera.focusMode = .continuousAutoFocus
                    print("Continuous autofocus enabled")
                } else if camera.isFocusModeSupported(.autoFocus) {
                    camera.focusMode = .autoFocus
                    print("Auto focus enabled")
                }
            } else {
                // Disable autofocus for manual tap-to-focus
                if camera.isFocusModeSupported(.locked) {
                    camera.focusMode = .locked
                    print("Autofocus disabled - tap to focus enabled")
                }
            }
            
            // Enable continuous auto exposure for proper lighting
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
                print("Continuous auto exposure enabled")
            }
            
            // Enable auto white balance for accurate colors
            if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                camera.whiteBalanceMode = .continuousAutoWhiteBalance
                print("Continuous auto white balance enabled")
            }
            
            // Set focus point to center of frame for consistent focus
            if camera.isFocusPointOfInterestSupported {
                camera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                print("Focus point set to center")
            }
            
            // Set exposure point to center for consistent exposure
            if camera.isExposurePointOfInterestSupported {
                camera.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
                print("Exposure point set to center")
            }
            
            camera.unlockForConfiguration()
            print("Camera focus and exposure configuration completed")
            
        } catch {
            print("Failed to configure camera focus: \(error)")
        }
    }
}

extension LiveCameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Update frame monitoring
        frameMonitoringQueue.async {
            self.frameCount += 1
        }
        self.latestSampleBuffer = sampleBuffer
        // Process the sample buffer
        sampleBufferHandler?(sampleBuffer)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameMonitoringQueue.async {
            self.droppedFrameCount += 1
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
    let cameraManager: LiveCameraView
    var onTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        cameraManager.previewLayer = previewLayer

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
            
            // Update video orientation when device orientation changes
            if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
                connection.videoOrientation = cameraManager.videoOrientation(from: cameraManager.currentOrientation)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    class Coordinator: NSObject {
        var onTap: (CGPoint) -> Void

        init(onTap: @escaping (CGPoint) -> Void) {
            self.onTap = onTap
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            print("Tap detected at location: \(location)")
            onTap(location)
        }
    }
}
