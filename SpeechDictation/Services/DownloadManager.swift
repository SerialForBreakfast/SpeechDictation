//
//  DownloadManager.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/29/24.
//

import Foundation
import AVFoundation

class DownloadManager {
    static let shared = DownloadManager()
    
    private init () {
        
    }
    
    func downloadAudioFile(from url: URL, completion: @escaping (URL?) -> Void) {
        let task: URLSessionDownloadTask = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let error = error {
                AppLog.error(.download, "Download error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let localURL = localURL else {
                AppLog.error(.download, "No local URL after download.")
                completion(nil)
                return
            }
            AppLog.info(.download, "Downloaded file to: \(localURL)")
            completion(localURL)
        }
        task.resume()
    }
    
    private func verifyAudioFile(url: URL, completion: @escaping (Bool) -> Void) {
        let asset: AVAsset = AVAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            var error: NSError? = nil
            let status: AVKeyValueStatus = asset.statusOfValue(forKey: "playable", error: &error)
            DispatchQueue.main.async {
                if status == .loaded {
                    AppLog.info(.download, "Audio file is playable.")
                    completion(true)
                } else {
                    AppLog.error(.download, "Error verifying audio file: \(String(describing: error))")
                    completion(false)
                }
            }
        }
    }
    
}
