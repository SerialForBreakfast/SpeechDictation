import AVFoundation
import UIKit
import SwiftUI

/// A class that manages the live camera feed and delivers sample buffers.
final class LiveCameraView: NSObject, ObservableObject {
    private let sessionQueue = DispatchQueue(label: "LiveCameraView.sessionQueue")
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var sampleBufferHandler: ((CMSampleBuffer) -> Void)?

    override init() {
        super.init()
        configureSession()
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

/// A UIViewRepresentable wrapper to display the AVCaptureVideoPreviewLayer in SwiftUI.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
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
        }
    }
}
