//
//  RecipeXMigrationManager.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 1/26/26.
//
//  Migrates existing Recipe models to RecipeX with CloudKit sync enabled

import Foundation
import SwiftData
import UIKit

/// Manages migration from Recipe → RecipeX
/// 
/// USAGE:
/// ```swift
/// let manager = RecipeXMigrationManager(modelContext: modelContext)
/// let result = await manager.migrateAllRecipes()
/// print("Migrated \(result.migratedCount) recipes")
/// ```
@MainActor
class RecipeXMigrationManager {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let getCurrentUserID: () async -> String?
    private let getCurrentUserDisplayName: () async -> String?
    
    // MARK: - Migration Result
    
    struct MigrationResult {
        let migratedCount: Int
        let skippedCount: Int
        let errorCount: Int
        let errors: [(recipeTitle: String, error: String)]
        
        var summary: String {
            """
            Migration Complete:
            ✅ Migrated: \(migratedCount)
            ⏭️  Skipped: \(skippedCount)
            ❌ Errors: \(errorCount)
            """
        }
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext,
         getCurrentUserID: @escaping () async -> String? = { nil },
         getCurrentUserDisplayName: @escaping () async -> String? = { nil }) {
        self.modelContext = modelContext
        self.getCurrentUserID = getCurrentUserID
        self.getCurrentUserDisplayName = getCurrentUserDisplayName
    }
    
    // MARK: - Migration Methods
    
    /// Check if migration is needed
    func needsMigration() -> Bool {
        // Check if there are any Recipe objects without corresponding RecipeX
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let recipeXDescriptor = FetchDescriptor<RecipeX>()
        
        do {
            let recipeCount = try modelContext.fetchCount(recipeDescriptor)
            let recipeXCount = try modelContext.fetchCount(recipeXDescriptor)
            
            // If we have more Recipes than RecipeX, migration is needed
            let needsMigration = recipeCount > recipeXCount
            
            if needsMigration {
                logInfo("📊 Migration check: \(recipeCount) Recipe(s), \(recipeXCount) RecipeX(s) - migration needed", category: "migration")
            } else {
                logInfo("✅ Migration check: All recipes already migrated", category: "migration")
            }
            
            return needsMigration
        } catch {
            logError("Failed to check migration status: \(error)", category: "migration")
            return false
        }
    }
    
    /// Migrate all Recipe objects to RecipeX
    func migrateAllRecipes() async -> MigrationResult {
        logInfo("🚀 Starting Recipe → RecipeX migration", category: "migration")
        
        // Fetch all Recipe objects
        let descriptor = FetchDescriptor<Recipe>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        
        do {
            let recipes = try modelContext.fetch(descriptor)
            logInfo("Found \(recipes.count) recipe(s) to process", category: "migration")
            
            // Get existing RecipeX IDs to avoid duplicates
            let existingIDs = try getExistingRecipeXIDs()
            
            var migratedCount = 0
            var skippedCount = 0
            var errorCount = 0
            var errors: [(String, String)] = []
            
            // Get current user info
            let userID = await getCurrentUserID()
            let displayName = await getCurrentUserDisplayName()
            
            // Process each recipe
            for (index, recipe) in recipes.enumerated() {
                // Skip if already migrated
                if existingIDs.contains(recipe.id) {
                    logDebug("Skipping '\(recipe.title)' - already migrated", category: "migration")
                    skippedCount += 1
                    continue
                }
                
                logInfo("[\(index + 1)/\(recipes.count)] Migrating '\(recipe.title)'...", category: "migration")
                
                do {
                    try await migrateRecipe(recipe, ownerUserID: userID, ownerDisplayName: displayName)
                    migratedCount += 1
                    
                    // Save every 10 recipes to avoid memory issues
                    if migratedCount % 10 == 0 {
                        try modelContext.save()
                        logInfo("💾 Saved batch of 10 recipes (\(migratedCount) total)", category: "migration")
                    }
                } catch {
                    logError("Failed to migrate '\(recipe.title)': \(error)", category: "migration")
                    errors.append((recipe.title, error.localizedDescription))
                    errorCount += 1
                }
            }
            
            // Final save
            try modelContext.save()
            
            let result = MigrationResult(
                migratedCount: migratedCount,
                skippedCount: skippedCount,
                errorCount: errorCount,
                errors: errors
            )
            
            logInfo("✅ Migration complete:", category: "migration")
            logInfo(result.summary, category: "migration")
            
            return result
            
        } catch {
            logError("Migration failed: \(error)", category: "migration")
            return MigrationResult(
                migratedCount: 0,
                skippedCount: 0,
                errorCount: 1,
                errors: [("Migration", error.localizedDescription)]
            )
        }
    }
    
    /// Migrate a single recipe to RecipeX
    func migrateRecipe(_ recipe: Recipe, ownerUserID: String? = nil, ownerDisplayName: String? = nil) async throws {
        // Create RecipeX from Recipe
        let recipeX = RecipeX(from: recipe)
        
        // Set user attribution
        recipeX.ownerUserID = ownerUserID
        recipeX.ownerDisplayName = ownerDisplayName
        
        // Set device identifier for tracking
        recipeX.lastModifiedDeviceID = UIDevice.current.identifierForVendor?.uuidString
        
        // Generate content fingerprint for duplicate detection
        recipeX.updateContentFingerprint()
        
        // Mark for CloudKit sync (always sync new RecipeX models)
        recipeX.needsCloudSync = true
        
        // Insert into SwiftData
        modelContext.insert(recipeX)
        
        logDebug("Created RecipeX for '\(recipe.title)'", category: "migration")
    }
    
    /// Delete old Recipe objects after successful migration
    /// ⚠️ WARNING: Only call this after verifying RecipeX migration is complete!
    func deleteOldRecipes() async throws -> Int {
        logWarning("🗑️  Deleting old Recipe objects (this is irreversible!)", category: "migration")
        
        let descriptor = FetchDescriptor<Recipe>()
        let recipes = try modelContext.fetch(descriptor)
        
        for recipe in recipes {
            modelContext.delete(recipe)
        }
        
        try modelContext.save()
        
        logInfo("Deleted \(recipes.count) old Recipe object(s)", category: "migration")
        return recipes.count
    }
    
    // MARK: - Helper Methods
    
    private func getExistingRecipeXIDs() throws -> Set<UUID> {
        let descriptor = FetchDescriptor<RecipeX>()
        let recipeXs = try modelContext.fetch(descriptor)
        return Set(recipeXs.compactMap { $0.id })
    }
}

// MARK: - Convenience Extensions

extension RecipeXMigrationManager {
    
    /// Run migration with progress reporting
    func migrateWithProgress(progressHandler: @escaping (Int, Int, String) -> Void) async -> MigrationResult {
        logInfo("🚀 Starting migration with progress reporting", category: "migration")
        
        let descriptor = FetchDescriptor<Recipe>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        
        do {
            let recipes = try modelContext.fetch(descriptor)
            let total = recipes.count
            let existingIDs = try getExistingRecipeXIDs()
            
            var migratedCount = 0
            var skippedCount = 0
            var errorCount = 0
            var errors: [(String, String)] = []
            
            let userID = await getCurrentUserID()
            let displayName = await getCurrentUserDisplayName()
            
            for (index, recipe) in recipes.enumerated() {
                let current = index + 1
                
                // Skip if already migrated
                if existingIDs.contains(recipe.id) {
                    progressHandler(current, total, "Skipped: \(recipe.title)")
                    skippedCount += 1
                    continue
                }
                
                progressHandler(current, total, "Migrating: \(recipe.title)")
                
                do {
                    try await migrateRecipe(recipe, ownerUserID: userID, ownerDisplayName: displayName)
                    migratedCount += 1
                    
                    if migratedCount % 10 == 0 {
                        try modelContext.save()
                    }
                } catch {
                    errors.append((recipe.title, error.localizedDescription))
                    errorCount += 1
                }
            }
            
            try modelContext.save()
            
            progressHandler(total, total, "Complete!")
            
            return MigrationResult(
                migratedCount: migratedCount,
                skippedCount: skippedCount,
                errorCount: errorCount,
                errors: errors
            )
            
        } catch {
            progressHandler(0, 0, "Error: \(error.localizedDescription)")
            return MigrationResult(
                migratedCount: 0,
                skippedCount: 0,
                errorCount: 1,
                errors: [("Migration", error.localizedDescription)]
            )
        }
    }
}
