//
//  RecipeImageMigrationService.swift
//  Reczipes2
//
//  Service to migrate recipe images from file system to SwiftData
//

import Foundation
import SwiftData

@MainActor
class RecipeImageMigrationService {
    
    /// Migrate all recipe images from file system to SwiftData
    /// This ensures images are synced via CloudKit and survive app reinstall
    static func migrateAllRecipeImages(modelContext: ModelContext) async throws {
        logInfo("Starting recipe image migration to SwiftData", category: "image-migration")
        
        // Fetch all recipes
        let descriptor = FetchDescriptor<Recipe>()
        let recipes = try modelContext.fetch(descriptor)
        
        var migratedCount = 0
        var skippedCount = 0
        var errorCount = 0
        
        for recipe in recipes {
            do {
                let didMigrate = try await migrateRecipeImages(recipe: recipe)
                if didMigrate {
                    migratedCount += 1
                } else {
                    skippedCount += 1
                }
            } catch {
                errorCount += 1
                logError("Failed to migrate images for recipe '\(recipe.title)': \(error)", category: "image-migration")
            }
        }
        
        // Save changes
        if migratedCount > 0 {
            try modelContext.save()
        }
        
        logInfo("Image migration complete: \(migratedCount) migrated, \(skippedCount) skipped, \(errorCount) errors", category: "image-migration")
    }
    
    /// Migrate images for a single recipe
    /// Returns true if migration was performed, false if skipped
    @discardableResult
    static func migrateRecipeImages(recipe: Recipe) async throws -> Bool {
        var didMigrate = false
        
        // Check if already migrated
        if recipe.imageData != nil && recipe.additionalImagesData != nil {
            return false // Already migrated
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Migrate main image
        if let imageName = recipe.imageName, recipe.imageData == nil {
            let fileURL = documentsPath.appendingPathComponent(imageName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let data = try? Data(contentsOf: fileURL) {
                    recipe.imageData = data
                    didMigrate = true
                    logInfo("Migrated main image for '\(recipe.title)'", category: "image-migration")
                }
            }
        }
        
        // Migrate additional images
        if let additionalNames = recipe.additionalImageNames, !additionalNames.isEmpty, recipe.additionalImagesData == nil {
            var imagesArray: [[String: String]] = []
            
            for imageName in additionalNames {
                let fileURL = documentsPath.appendingPathComponent(imageName)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    if let data = try? Data(contentsOf: fileURL) {
                        // Store as base64 string for JSON encoding
                        imagesArray.append([
                            "fileName": imageName,
                            "imageData": data.base64EncodedString()
                        ])
                    }
                }
            }
            
            if !imagesArray.isEmpty {
                if let encoded = try? JSONEncoder().encode(imagesArray) {
                    recipe.additionalImagesData = encoded
                    didMigrate = true
                    logInfo("Migrated \(imagesArray.count) additional images for '\(recipe.title)'", category: "image-migration")
                }
            }
        }
        
        return didMigrate
    }
    
    /// Restore images from SwiftData to file system
    /// Call this after app reinstall when recipes are synced but files are missing
    static func restoreAllRecipeImages(modelContext: ModelContext) async throws {
        logInfo("Starting recipe image restoration from SwiftData", category: "image-migration")
        
        let descriptor = FetchDescriptor<Recipe>()
        let recipes = try modelContext.fetch(descriptor)
        
        var restoredCount = 0
        
        for recipe in recipes {
            let didRestore = restoreRecipeImages(recipe: recipe)
            if didRestore {
                restoredCount += 1
            }
        }
        
        logInfo("Image restoration complete: \(restoredCount) recipes restored", category: "image-migration")
    }
    
    /// Restore images for a single recipe from SwiftData to file system
    @discardableResult
    static func restoreRecipeImages(recipe: Recipe) -> Bool {
        var didRestore = false
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Restore main image
        if let imageData = recipe.imageData, let imageName = recipe.imageName {
            let fileURL = documentsPath.appendingPathComponent(imageName)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                try? imageData.write(to: fileURL)
                didRestore = true
            }
        }
        
        // Restore additional images
        if let additionalImagesData = recipe.additionalImagesData {
            if let imagesArray = try? JSONDecoder().decode([[String: String]].self, from: additionalImagesData) {
                for imageDict in imagesArray {
                    if let fileName = imageDict["fileName"],
                       let base64String = imageDict["imageData"],
                       let data = Data(base64Encoded: base64String) {
                        let fileURL = documentsPath.appendingPathComponent(fileName)
                        if !FileManager.default.fileExists(atPath: fileURL.path) {
                            try? data.write(to: fileURL)
                            didRestore = true
                        }
                    }
                }
            }
        }
        
        return didRestore
    }
    
    /// Check if any recipes need image restoration
    static func needsImageRestoration(modelContext: ModelContext) -> Bool {
        do {
            let descriptor = FetchDescriptor<Recipe>()
            let recipes = try modelContext.fetch(descriptor)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            // Check if any recipe has image data but missing files
            for recipe in recipes {
                if let imageName = recipe.imageName, recipe.imageData != nil {
                    let fileURL = documentsPath.appendingPathComponent(imageName)
                    if !FileManager.default.fileExists(atPath: fileURL.path) {
                        return true
                    }
                }
            }
            
            return false
        } catch {
            logError("Failed to check if restoration needed: \(error)", category: "image-migration")
            return false
        }
    }
}
