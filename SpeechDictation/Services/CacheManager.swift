//
//  CacheManager.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/28/24.
//
//  Enhanced cache manager with secure storage capabilities for private recordings.
//  Provides both standard caching and secure storage with complete file protection.
//

import Foundation

/// Enhanced cache manager providing both standard caching and secure storage capabilities
/// Supports secure storage with complete file protection for sensitive private recordings
/// Uses iOS file protection levels to ensure data security at rest
class CacheManager {
    static let shared = CacheManager()
    private init() {}

    // MARK: - Storage Directories
    
    /// Standard cache directory for temporary files and downloads
    private var cacheDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    /// Secure documents directory for protected private recordings
    private var secureDocumentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Dedicated directory for secure private recordings with complete file protection
    private var secureRecordingsDirectory: URL {
        let recordingsDir = secureDocumentsDirectory.appendingPathComponent("SecureRecordings")
        ensureDirectoryExists(at: recordingsDir, withProtection: .complete)
        return recordingsDir
    }

    // MARK: - Standard Cache Operations (Existing API)
    
    /// Saves data to standard cache directory
    /// - Parameters:
    ///   - data: Data to save
    ///   - key: Cache key identifier
    /// - Returns: URL of saved file, or nil if failed
    func save(data: Data, forKey key: String) -> URL? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            try data.write(to: fileURL)
            AppLog.info(.storage, "Saved file to: \(fileURL)")
            return fileURL
        } catch {
            AppLog.error(.storage, "Error saving file: \(error)")
            return nil
        }
    }

    /// Retrieves data from standard cache directory
    /// - Parameter key: Cache key identifier
    /// - Returns: Retrieved data, or nil if not found
    func retrieveData(forKey key: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            let data = try Data(contentsOf: fileURL)
            AppLog.debug(.storage, "Retrieved file from: \(fileURL)", verboseOnly: true)
            return data
        } catch {
            AppLog.error(.storage, "Error retrieving file: \(error)")
            return nil
        }
    }

    /// Deletes data from standard cache directory
    /// - Parameter key: Cache key identifier
    func deleteData(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            try FileManager.default.removeItem(at: fileURL)
            AppLog.info(.storage, "Deleted file at: \(fileURL)")
        } catch {
            AppLog.error(.storage, "Error deleting file: \(error)")
        }
    }
    
    // MARK: - Secure Storage Operations
    
    /// Saves data securely with complete file protection
    /// - Parameters:
    ///   - data: Data to save securely
    ///   - key: Unique identifier for the secure file
    ///   - subdirectory: Optional subdirectory within secure recordings
    /// - Returns: URL of securely saved file, or nil if failed
    func saveSecurely(data: Data, forKey key: String, subdirectory: String? = nil) -> URL? {
        var targetDirectory = secureRecordingsDirectory
        
        if let subdirectory = subdirectory {
            targetDirectory = targetDirectory.appendingPathComponent(subdirectory)
            ensureDirectoryExists(at: targetDirectory, withProtection: .complete)
        }
        
        let fileURL = targetDirectory.appendingPathComponent(key)
        
        do {
            // Write data to file
            try data.write(to: fileURL)
            
            // Apply complete file protection
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: fileURL.path
            )
            
            AppLog.info(.storage, "Securely saved file to: \(fileURL) with complete file protection")
            return fileURL
        } catch {
            AppLog.error(.storage, "Error saving secure file: \(error)")
            return nil
        }
    }
    
    /// Retrieves data from secure storage
    /// - Parameters:
    ///   - key: Unique identifier for the secure file
    ///   - subdirectory: Optional subdirectory within secure recordings
    /// - Returns: Retrieved data, or nil if not found or inaccessible
    func retrieveSecureData(forKey key: String, subdirectory: String? = nil) -> Data? {
        var targetDirectory = secureRecordingsDirectory
        
        if let subdirectory = subdirectory {
            targetDirectory = targetDirectory.appendingPathComponent(subdirectory)
        }
        
        let fileURL = targetDirectory.appendingPathComponent(key)
        
        do {
            let data = try Data(contentsOf: fileURL)
            AppLog.debug(.storage, "Retrieved secure file from: \(fileURL)", verboseOnly: true)
            return data
        } catch {
            AppLog.error(.storage, "Error retrieving secure file: \(error)")
            return nil
        }
    }
    
    /// Deletes data from secure storage
    /// - Parameters:
    ///   - key: Unique identifier for the secure file
    ///   - subdirectory: Optional subdirectory within secure recordings
    /// - Returns: True if deletion was successful
    @discardableResult
    func deleteSecureData(forKey key: String, subdirectory: String? = nil) -> Bool {
        var targetDirectory = secureRecordingsDirectory
        
        if let subdirectory = subdirectory {
            targetDirectory = targetDirectory.appendingPathComponent(subdirectory)
        }
        
        let fileURL = targetDirectory.appendingPathComponent(key)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            AppLog.info(.storage, "Deleted secure file at: \(fileURL)")
            return true
        } catch {
            AppLog.error(.storage, "Error deleting secure file: \(error)")
            return false
        }
    }
    
    /// Lists all files in secure storage
    /// - Parameter subdirectory: Optional subdirectory to list
    /// - Returns: Array of file URLs in secure storage
    func listSecureFiles(inSubdirectory subdirectory: String? = nil) -> [URL] {
        var targetDirectory = secureRecordingsDirectory
        
        if let subdirectory = subdirectory {
            targetDirectory = targetDirectory.appendingPathComponent(subdirectory)
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: targetDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )
            return fileURLs.sorted { $0.lastPathComponent > $1.lastPathComponent }
        } catch {
            AppLog.error(.storage, "Error listing secure files: \(error)")
            return []
        }
    }
    
    // MARK: - Directory Management
    
    /// Ensures a directory exists with specified file protection
    /// - Parameters:
    ///   - url: Directory URL to create
    ///   - protection: File protection level to apply
    private func ensureDirectoryExists(at url: URL, withProtection protection: FileProtectionType) {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                try fileManager.setAttributes(
                    [.protectionKey: protection],
                    ofItemAtPath: url.path
                )
                AppLog.info(.storage, "Created secure directory: \(url.path)")
            } catch {
                AppLog.error(.storage, "Error creating secure directory: \(error)")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Gets a secure file URL for a given filename and optional session
    /// - Parameters:
    ///   - fileName: Name of the file
    ///   - sessionId: Optional session identifier for grouping
    /// - Returns: URL in secure storage directory
    func getSecureFileURL(fileName: String, sessionId: String? = nil) -> URL {
        var targetDirectory = secureRecordingsDirectory
        
        if let sessionId = sessionId {
            targetDirectory = targetDirectory.appendingPathComponent(sessionId)
            ensureDirectoryExists(at: targetDirectory, withProtection: .complete)
        }
        
        return targetDirectory.appendingPathComponent(fileName)
    }
    
    /// Gets available storage space for security validation
    /// - Returns: Available bytes, or nil if unable to determine
    func getAvailableStorageSpace() -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: secureDocumentsDirectory.path)
            return attributes[.systemFreeSize] as? Int64
        } catch {
            AppLog.error(.storage, "Error getting storage space: \(error)")
            return nil
        }
    }
    
    /// Validates file protection level
    /// - Parameter url: File URL to check
    /// - Returns: True if file has complete protection
    /// - Throws: Error if validation fails
    func validateFileProtection(at url: URL) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let protection = attributes[.protectionKey] as? FileProtectionType
        
        guard protection == .complete else {
            throw NSError(
                domain: "CacheManagerError",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "File does not have complete protection: \(url.lastPathComponent)"]
            )
        }
    }
}
