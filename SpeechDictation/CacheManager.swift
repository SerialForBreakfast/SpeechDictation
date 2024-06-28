//
//  CacheManager.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/28/24.
//

import Foundation

class CacheManager {
    static let shared = CacheManager()
    private init() {}

    private var cacheDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    func save(data: Data, forKey key: String) -> URL? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            try data.write(to: fileURL)
            print("Saved file to: \(fileURL)")
            return fileURL
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }

    func retrieveData(forKey key: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            let data = try Data(contentsOf: fileURL)
            print("Retrieved file from: \(fileURL)")
            return data
        } catch {
            print("Error retrieving file: \(error)")
            return nil
        }
    }

    func deleteData(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Deleted file at: \(fileURL)")
        } catch {
            print("Error deleting file: \(error)")
        }
    }
}
