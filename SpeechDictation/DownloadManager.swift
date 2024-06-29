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
                print("Download error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let localURL = localURL else {
                print("No local URL after download.")
                completion(nil)
                return
            }
            print("Downloaded file to: \(localURL)")
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
                    print("Audio file is playable.")
                    completion(true)
                } else {
                    print("Error verifying audio file: \(String(describing: error))")
                    completion(false)
                }
            }
        }
    }
    
}
