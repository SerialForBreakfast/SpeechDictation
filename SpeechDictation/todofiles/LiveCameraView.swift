import AVFoundation
import UIKit
import SwiftUI

/// A class that manages the live camera feed and delivers sample buffers.
/// Now supports dynamic orientation changes for proper camera display across device orientations.
final class LiveCameraView: NSObject, ObservableObject {
    private let sessionQueue = DispatchQueue(label: "LiveCameraView.sessionQueue")
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var sampleBufferHandler: ((CMSampleBuffer) -> Void)?
    private var videoConnection: AVCaptureConnection?
    
    /// Current device orientation for Vision framework processing
    @Published var currentOrientation: UIDeviceOrientation = .portrait

    override init() {
        super.init()
        configureSession()
        startOrientationMonitoring()
    }
    
    deinit {
        stopOrientationMonitoring()
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
            }
        }
    }

    /// Stops the camera capture session.
    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
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
    private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard let camera = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  self.session.canAddInput(input) else {
                print("Failed to access camera input")
                return
            }

            self.session.addInput(input)

            self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoOutputQueue"))
            self.videoOutput.alwaysDiscardsLateVideoFrames = true

            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
                
                // Configure the connection orientation for proper ML processing
                if let connection = self.videoOutput.connection(with: .video) {
                    self.videoConnection = connection
                    connection.videoOrientation = self.videoOrientation(from: UIDevice.current.orientation)
                    connection.isVideoMirrored = false
                }
            }

            self.session.commitConfiguration()
        }
    }
}

extension LiveCameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        sampleBufferHandler?(sampleBuffer)
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
/// Now supports dynamic orientation changes for proper camera display.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    @ObservedObject var cameraManager: LiveCameraView

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        // Set the preview layer orientation to match the camera connection
        if let connection = previewLayer.connection {
            connection.videoOrientation = cameraManager.videoOrientation(from: UIDevice.current.orientation)
        }
        
        view.layer.addSublayer(previewLayer)

        // Keep previewLayer properly sized
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
            
            // Update orientation when the view updates
            if let connection = previewLayer.connection {
                connection.videoOrientation = cameraManager.videoOrientation(from: cameraManager.currentOrientation)
            }
        }
    }
}
