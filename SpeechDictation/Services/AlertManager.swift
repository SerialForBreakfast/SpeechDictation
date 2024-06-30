//
//  AlertManager.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/29/24.
//
import UIKit

class AlertManager {
    static let shared = AlertManager()
    
    private init() {}
    
    func showShareOptions(from viewController: UIViewController, text: String?, audioURL: URL?, sourceView: UIView) {
        let alert = UIAlertController(title: "Share", message: "Choose what you want to share", preferredStyle: .actionSheet)
        
        if let text = text {
            alert.addAction(UIAlertAction(title: "Share Transcript", style: .default, handler: { _ in
                self.share(items: [text], from: viewController)
            }))
        }
        
        if let audioURL = audioURL {
            alert.addAction(UIAlertAction(title: "Share Recording", style: .default, handler: { _ in
                self.share(items: [audioURL], from: viewController)
            }))
        }
        
        if let text = text, let audioURL = audioURL {
            alert.addAction(UIAlertAction(title: "Share Both", style: .default, handler: { _ in
                self.share(items: [text, audioURL], from: viewController)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
        }
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    private func share(items: [Any], from viewController: UIViewController) {
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        viewController.present(activityViewController, animated: true, completion: nil)
    }
}
