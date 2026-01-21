//
//  RecipeBookImageMigrationService.swift
//  Reczipes2
//
//  Service to migrate book cover images from Documents directory to SwiftData
//  Created on 1/20/26.
//

import Foundation
import SwiftData
import UIKit

/// Service responsible for migrating book cover images from file-based storage to SwiftData
@MainActor
class RecipeBookImageMigrationService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let userDefaults = UserDefaults.standard
    
    // Key to track if migration has been performed
    private static let migrationCompletedKey = "RecipeBookImageMigration_Completed"
    private static let migrationVersionKey = "RecipeBookImageMigration_Version"
    private static let currentMigrationVersion = 1
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Check if migration is needed
    var needsMigration: Bool {
        // Check if migration has been completed
        let completed = userDefaults.bool(forKey: Self.migrationCompletedKey)
        let version = userDefaults.integer(forKey: Self.migrationVersionKey)
        
        // Migration needed if not completed OR version is old
        return !completed || version < Self.currentMigrationVersion
    }
    
    /// Perform the migration of book cover images from Documents to SwiftData
    /// - Returns: Result with statistics about the migration
    func performMigration() async throws -> MigrationResult {
        logInfo("🔄 Starting RecipeBook cover image migration...", category: "migration")
        
        // Fetch all recipe books
        let descriptor = FetchDescriptor<RecipeBook>()
        let books = try modelContext.fetch(descriptor)
        
        logInfo("Found \(books.count) recipe book(s) to check", category: "migration")
        
        var migratedCount = 0
        var skippedCount = 0
        var failedCount = 0
        var errors: [(String, Error)] = []
        
        for book in books {
            do {
                let result = try await migrateBook(book)
                
                switch result {
                case .migrated:
                    migratedCount += 1
                case .skipped(let reason):
                    skippedCount += 1
                    logInfo("Skipped '\(book.name)': \(reason)", category: "migration")
                case .failed(let error):
                    failedCount += 1
                    errors.append((book.name, error))
                    logWarning("Failed to migrate '\(book.name)': \(error)", category: "migration")
                }
            } catch {
                failedCount += 1
                errors.append((book.name, error))
                logError("Error migrating '\(book.name)': \(error)", category: "migration")
            }
        }
        
        // Save all changes to the context
        if migratedCount > 0 {
            try modelContext.save()
            logInfo("Saved \(migratedCount) migrated book(s) to SwiftData", category: "migration")
        }
        
        // Mark migration as completed
        userDefaults.set(true, forKey: Self.migrationCompletedKey)
        userDefaults.set(Self.currentMigrationVersion, forKey: Self.migrationVersionKey)
        
        let result = MigrationResult(
            totalBooks: books.count,
            migratedCount: migratedCount,
            skippedCount: skippedCount,
            failedCount: failedCount,
            errors: errors
        )
        
        logInfo("✅ Migration complete: \(migratedCount) migrated, \(skippedCount) skipped, \(failedCount) failed", category: "migration")
        
        return result
    }
    
    /// Manually reset migration status (for testing or forcing re-migration)
    func resetMigrationStatus() {
        userDefaults.removeObject(forKey: Self.migrationCompletedKey)
        userDefaults.removeObject(forKey: Self.migrationVersionKey)
        logInfo("Migration status reset", category: "migration")
    }
    
    // MARK: - Private Methods
    
    /// Migrate a single book's cover image from file to SwiftData
    private func migrateBook(_ book: RecipeBook) async throws -> BookMigrationResult {
        // Check if book already has image data
        if book.coverImageData != nil {
            // Already migrated or created with new system
            return .skipped(reason: "Already has imageData")
        }
        
        // Check if book has a cover image name
        guard let imageName = book.coverImageName, !imageName.isEmpty else {
            return .skipped(reason: "No cover image")
        }
        
        // Try to load image from Documents directory
        guard let imageData = loadImageDataFromDocuments(imageName) else {
            return .failed(error: MigrationError.imageFileNotFound(imageName))
        }
        
        // Validate that it's actually an image
        guard UIImage(data: imageData) != nil else {
            return .failed(error: MigrationError.invalidImageData(imageName))
        }
        
        // Migrate: Store the image data in SwiftData
        book.coverImageData = imageData
        book.dateModified = Date()
        
        logInfo("✓ Migrated cover image for '\(book.name)' (\(imageData.count / 1024)KB)", category: "migration")
        
        // Note: We keep the coverImageName for reference/backwards compatibility
        // The file can be cleaned up later if desired
        
        return .migrated
    }
    
    /// Load image data from the Documents directory
    private func loadImageDataFromDocuments(_ filename: String) -> Data? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logWarning("Image file not found: \(filename)", category: "migration")
            return nil
        }
        
        // Load the data
        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            logError("Failed to load image data from \(filename): \(error)", category: "migration")
            return nil
        }
    }
    
    /// Optional: Clean up old image files after successful migration
    /// This should only be called after verifying migration was successful
    func cleanupOldImageFiles() async throws -> CleanupResult {
        logInfo("🧹 Starting cleanup of old book cover image files...", category: "migration")
        
        // Fetch all books
        let descriptor = FetchDescriptor<RecipeBook>()
        let books = try modelContext.fetch(descriptor)
        
        var deletedCount = 0
        var failedCount = 0
        var totalFreedBytes = 0
        
        for book in books {
            // Only clean up if book has imageData AND imageName (successfully migrated)
            guard let imageName = book.coverImageName,
                  book.coverImageData != nil else {
                continue
            }
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(imageName)
            
            // Get file size before deletion
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? Int {
                totalFreedBytes += fileSize
            }
            
            // Delete the file
            do {
                try FileManager.default.removeItem(at: fileURL)
                deletedCount += 1
                logInfo("Deleted old file: \(imageName)", category: "migration")
            } catch {
                failedCount += 1
                logWarning("Failed to delete \(imageName): \(error)", category: "migration")
            }
        }
        
        let result = CleanupResult(
            deletedCount: deletedCount,
            failedCount: failedCount,
            bytesFreed: totalFreedBytes
        )
        
        logInfo("✅ Cleanup complete: \(deletedCount) files deleted, \(totalFreedBytes / 1024)KB freed", category: "migration")
        
        return result
    }
}

// MARK: - Supporting Types

extension RecipeBookImageMigrationService {
    
    /// Result of a single book migration
    enum BookMigrationResult {
        case migrated
        case skipped(reason: String)
        case failed(error: Error)
    }
    
    /// Overall migration result with statistics
    struct MigrationResult {
        let totalBooks: Int
        let migratedCount: Int
        let skippedCount: Int
        let failedCount: Int
        let errors: [(bookName: String, error: Error)]
        
        var successRate: Double {
            guard totalBooks > 0 else { return 0 }
            return Double(migratedCount) / Double(totalBooks)
        }
        
        var summary: String {
            """
            Migration Summary:
            - Total Books: \(totalBooks)
            - Successfully Migrated: \(migratedCount)
            - Skipped (no action needed): \(skippedCount)
            - Failed: \(failedCount)
            - Success Rate: \(String(format: "%.1f%%", successRate * 100))
            """
        }
    }
    
    /// Result of cleanup operation
    struct CleanupResult {
        let deletedCount: Int
        let failedCount: Int
        let bytesFreed: Int
        
        var megabytesFreed: Double {
            Double(bytesFreed) / (1024 * 1024)
        }
        
        var summary: String {
            """
            Cleanup Summary:
            - Files Deleted: \(deletedCount)
            - Failed Deletions: \(failedCount)
            - Disk Space Freed: \(String(format: "%.2f MB", megabytesFreed))
            """
        }
    }
    
    /// Migration-specific errors
    enum MigrationError: LocalizedError {
        case imageFileNotFound(String)
        case invalidImageData(String)
        case contextSaveFailure(Error)
        
        var errorDescription: String? {
            switch self {
            case .imageFileNotFound(let filename):
                return "Image file not found: \(filename)"
            case .invalidImageData(let filename):
                return "Invalid image data in file: \(filename)"
            case .contextSaveFailure(let error):
                return "Failed to save context: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Automatic Migration on App Launch

extension RecipeBookImageMigrationService {
    
    /// Perform migration automatically on app launch if needed
    /// This is designed to be called once during app startup
    static func migrateIfNeeded(modelContext: ModelContext) async {
        let service = RecipeBookImageMigrationService(modelContext: modelContext)
        
        guard service.needsMigration else {
            logInfo("Book cover image migration not needed (already completed)", category: "migration")
            return
        }
        
        logInfo("Book cover image migration needed - starting automatic migration...", category: "migration")
        
        do {
            let result = try await service.performMigration()
            logInfo(result.summary, category: "migration")
            
            // Log any errors that occurred
            if !result.errors.isEmpty {
                logWarning("Migration completed with \(result.errors.count) error(s):", category: "migration")
                for (bookName, error) in result.errors {
                    logError("  - \(bookName): \(error.localizedDescription)", category: "migration")
                }
            }
            
            // Optional: Clean up old files after successful migration
            // Uncomment if you want automatic cleanup
            // if result.failedCount == 0 && result.migratedCount > 0 {
            //     let cleanupResult = try await service.cleanupOldImageFiles()
            //     logInfo(cleanupResult.summary, category: "migration")
            // }
            
        } catch {
            logError("Book cover image migration failed: \(error)", category: "migration")
        }
    }
}

// MARK: - Usage Instructions

/*
 
 ## Usage Instructions
 
 ### Automatic Migration (Recommended)
 
 Add this to your app's initialization (e.g., in App struct or main view's `onAppear`):
 
 ```swift
 .task {
     await RecipeBookImageMigrationService.migrateIfNeeded(
         modelContext: modelContext
     )
 }
 ```
 
 ### Manual Migration
 
 If you want more control:
 
 ```swift
 let service = RecipeBookImageMigrationService(modelContext: modelContext)
 
 if service.needsMigration {
     do {
         let result = try await service.performMigration()
         print(result.summary)
         
         // Optionally clean up old files
         let cleanupResult = try await service.cleanupOldImageFiles()
         print(cleanupResult.summary)
     } catch {
         print("Migration failed: \(error)")
     }
 }
 ```
 
 ### Testing Migration
 
 To test the migration again:
 
 ```swift
 let service = RecipeBookImageMigrationService(modelContext: modelContext)
 service.resetMigrationStatus()
 let result = try await service.performMigration()
 ```
 
 ## What This Migration Does
 
 1. **Finds all RecipeBooks** in the database
 2. **For each book**:
    - Checks if it already has `coverImageData` (skip if yes)
    - Checks if it has a `coverImageName` (skip if no)
    - Loads the image file from Documents directory
    - Stores the image data in `coverImageData` property
    - Keeps `coverImageName` for reference
 3. **Saves all changes** to SwiftData
 4. **Marks migration as complete** so it doesn't run again
 
 ## Benefits
 
 - ✅ **CloudKit Sync**: Images now sync via iCloud
 - ✅ **Backwards Compatible**: Old code still works
 - ✅ **One-time Migration**: Runs once per device
 - ✅ **Safe**: Original files remain until cleanup
 - ✅ **Logged**: All actions logged for debugging
 - ✅ **Error Handling**: Failed migrations don't crash app
 
 ## File Cleanup
 
 After successful migration, you can optionally clean up the old image files
 to free disk space. The cleanup is separate from migration so you can verify
 everything works before deleting files.
 
 To enable automatic cleanup, uncomment the cleanup code in `migrateIfNeeded`.
 
 */
