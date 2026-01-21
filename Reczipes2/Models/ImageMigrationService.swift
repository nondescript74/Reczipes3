//
//  ImageMigrationService.swift
//  Reczipes2
//
//  Service to migrate file-based recipe images to SwiftData imageData
//  This ensures images sync properly via CloudKit
//

import Foundation
import SwiftData

/// Manages one-time migration of file-based images to SwiftData
@MainActor
class ImageMigrationService {
    private static let migrationCompletedKey = "com.reczipes.imageMigrationCompleted"
    private static let migrationVersionKey = "com.reczipes.imageMigrationVersion"
    private static let currentMigrationVersion = 1
    
    /// Check if migration has already been completed
    static var needsMigration: Bool {
        let completed = UserDefaults.standard.bool(forKey: migrationCompletedKey)
        let version = UserDefaults.standard.integer(forKey: migrationVersionKey)
        
        // If never completed, or version is outdated, migration is needed
        return !completed || version < currentMigrationVersion
    }
    
    /// Perform image migration for all recipes
    /// Returns the number of recipes migrated
    static func migrateAllRecipes(context: ModelContext) async -> Int {
        guard needsMigration else {
            logInfo("ℹ️ Image migration already completed, skipping...", category: "migration")
            return 0
        }
        
        logInfo("🔄 Starting image migration to SwiftData...", category: "migration")
        logInfo("   This will move images from Documents to SwiftData for CloudKit sync", category: "migration")
        
        do {
            // Fetch all recipes
            let descriptor = FetchDescriptor<Recipe>()
            let recipes = try context.fetch(descriptor)
            
            logInfo("   Found \(recipes.count) recipes to check", category: "migration")
            
            var migratedCount = 0
            var skippedCount = 0
            var errorCount = 0
            
            for recipe in recipes {
                let didMigrate = recipe.migrateImagesToSwiftData()
                if didMigrate {
                    migratedCount += 1
                } else if recipe.imageData != nil {
                    // Already has imageData, skip
                    skippedCount += 1
                } else {
                    // No image file found and no imageData
                    errorCount += 1
                }
            }
            
            // Save all changes
            try context.save()
            
            // Mark migration as completed
            UserDefaults.standard.set(true, forKey: migrationCompletedKey)
            UserDefaults.standard.set(currentMigrationVersion, forKey: migrationVersionKey)
            
            logInfo("✅ Image migration completed successfully!", category: "migration")
            logInfo("   Migrated: \(migratedCount) recipes", category: "migration")
            logInfo("   Already migrated: \(skippedCount) recipes", category: "migration")
            if errorCount > 0 {
                logWarning("   Missing images: \(errorCount) recipes", category: "migration")
            }
            
            // Log user-facing diagnostic
            logUserDiagnostic(
                .info,
                category: .storage,
                title: "Image Migration Completed",
                message: "Successfully migrated \(migratedCount) recipe images to cloud storage.",
                technicalDetails: "Recipes migrated: \(migratedCount), Already synced: \(skippedCount), Missing: \(errorCount)"
            )
            
            return migratedCount
            
        } catch {
            logError("❌ Image migration failed: \(error.localizedDescription)", category: "migration")
            
            logUserDiagnostic(
                .error,
                category: .storage,
                title: "Image Migration Failed",
                message: "Could not migrate recipe images to cloud storage.",
                technicalDetails: error.localizedDescription,
                suggestedActions: [
                    DiagnosticAction(
                        title: "Restart App",
                        description: "Close and reopen the app to retry migration",
                        actionType: .retryOperation
                    )
                ]
            )
            
            return 0
        }
    }
    
    /// Clean up file-based images after successful migration
    /// Only call this after confirming CloudKit sync is working
    static func cleanupFileBasedImages(context: ModelContext) async -> Int {
        logInfo("🗑️ Starting cleanup of file-based images...", category: "migration")
        
        do {
            let descriptor = FetchDescriptor<Recipe>()
            let recipes = try context.fetch(descriptor)
            
            var cleanedCount = 0
            
            for recipe in recipes {
                // Only clean up if imageData is populated (migration successful)
                if recipe.imageData != nil {
                    recipe.cleanupFileBasedImages()
                    cleanedCount += 1
                }
            }
            
            logInfo("✅ Cleaned up \(cleanedCount) recipe image files", category: "migration")
            return cleanedCount
            
        } catch {
            logError("❌ Cleanup failed: \(error.localizedDescription)", category: "migration")
            return 0
        }
    }
    
    /// Reset migration state (for testing/debugging)
    static func resetMigrationState() {
        UserDefaults.standard.removeObject(forKey: migrationCompletedKey)
        UserDefaults.standard.removeObject(forKey: migrationVersionKey)
        logInfo("🔄 Migration state reset", category: "migration")
    }
    
    /// Get migration status for diagnostics
    static func getMigrationStatus() -> String {
        let completed = UserDefaults.standard.bool(forKey: migrationCompletedKey)
        let version = UserDefaults.standard.integer(forKey: migrationVersionKey)
        
        if completed {
            return "✅ Completed (version \(version))"
        } else {
            return "⏳ Pending"
        }
    }
}
