//
//  BoundingBoxOverlayView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 7/12/25.
//
//  UIKit-based bounding box overlay with dark/light mode support
//  UIKit import justified for: UIView, UIColor, CAShapeLayer, CATextLayer for bounding box overlays
//

import Foundation
import UIKit
import Vision

/// UIKit-based bounding box overlay with dark/light mode support
/// Always shows green color with proper undetected state
final class BoundingBoxOverlay: UIView {
    private var boxLayers: [CAShapeLayer] = []
    private var noObjectsLabel: UILabel?

    func show(boxes: [DetectedObject], in frame: CGRect) {
        // Remove old layers
        boxLayers.forEach { $0.removeFromSuperlayer() }
        boxLayers.removeAll()
        noObjectsLabel?.removeFromSuperview()
        noObjectsLabel = nil

        if boxes.isEmpty {
            // Show "No objects detected" message
            showNoObjectsMessage(in: frame)
        } else {
            // Show bounding boxes
            showBoundingBoxes(boxes: boxes, in: frame)
        }
    }
    
    private func showNoObjectsMessage(in frame: CGRect) {
        let label = UILabel()
        label.text = "No objects detected"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.backgroundColor = noObjectsBackgroundColor
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(label)
        noObjectsLabel = label
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -100),
            label.widthAnchor.constraint(equalToConstant: 200),
            label.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func showBoundingBoxes(boxes: [DetectedObject], in frame: CGRect) {
        for box in boxes {
            let rect = VNImageRectForNormalizedRect(box.boundingBox, Int(frame.width), Int(frame.height))
            let layer = CAShapeLayer()
            layer.frame = rect
            layer.borderColor = boundingBoxColor.cgColor
            layer.borderWidth = 2

            let label = CATextLayer()
            label.string = "\(box.label) (\(Int(box.confidence * 100))%)"
            label.fontSize = 12
            label.foregroundColor = labelTextColor.cgColor
            label.backgroundColor = labelBackgroundColor.cgColor
            label.cornerRadius = 4
            label.frame = CGRect(x: 0, y: -20, width: min(rect.width, 120), height: 20)

            layer.addSublayer(label)
            self.layer.addSublayer(layer)
            boxLayers.append(layer)
        }
    }
    
    // MARK: - Dark/Light Mode Color Helpers
    
    /// No objects message background color that adapts to dark/light mode - Always green
    private var noObjectsBackgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor.systemGreen.withAlphaComponent(0.9)
                case .light:
                    return UIColor.systemGreen.withAlphaComponent(0.8)
                default:
                    return UIColor.systemGreen.withAlphaComponent(0.8)
                }
            }
        } else {
            return UIColor.green.withAlphaComponent(0.8)
        }
    }
    
    /// Bounding box border color that adapts to dark/light mode - Always green
    private var boundingBoxColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor.systemGreen.withAlphaComponent(0.9)
                case .light:
                    return UIColor.systemGreen.withAlphaComponent(0.8)
                default:
                    return UIColor.systemGreen.withAlphaComponent(0.8)
                }
            }
        } else {
            return UIColor.green.withAlphaComponent(0.8)
        }
    }
    
    /// Label text color that adapts to dark/light mode
    private var labelTextColor: UIColor {
        return UIColor.white // White text works well on green backgrounds in both modes
    }
    
    /// Label background color that adapts to dark/light mode - Always green
    private var labelBackgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor.systemGreen.withAlphaComponent(0.95)
                case .light:
                    return UIColor.systemGreen.withAlphaComponent(0.9)
                default:
                    return UIColor.systemGreen.withAlphaComponent(0.9)
                }
            }
        } else {
            return UIColor.green.withAlphaComponent(0.9)
        }
    }
}
