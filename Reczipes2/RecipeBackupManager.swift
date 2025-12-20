//
//  RecipeBackupManager.swift
//  Reczipes2
//
//  Created by Xcode Assistant on 12/20/25.
//

import Foundation
import SwiftData

enum RecipeBackupError: LocalizedError {
    case noRecipesToBackup
    case fileCreationFailed
    case encodingFailed(Error)
    case decodingFailed(Error)
    case imageLoadFailed(String)
    case invalidBackupFile
    case importFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noRecipesToBackup:
            return "No recipes available to backup"
        case .fileCreationFailed:
            return "Failed to create backup file"
        case .encodingFailed(let error):
            return "Failed to encode recipes: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode backup file: \(error.localizedDescription)"
        case .imageLoadFailed(let name):
            return "Failed to load image: \(name)"
        case .invalidBackupFile:
            return "Invalid or corrupted backup file"
        case .importFailed(let error):
            return "Failed to import recipes: \(error.localizedDescription)"
        }
    }
}

struct RecipeImportResult {
    let newRecipes: Int
    let updatedRecipes: Int
    let skippedRecipes: Int
    let totalRecipes: Int
    
    var summary: String {
        var parts: [String] = []
        if newRecipes > 0 {
            parts.append("\(newRecipes) new")
        }
        if updatedRecipes > 0 {
            parts.append("\(updatedRecipes) updated")
        }
        if skippedRecipes > 0 {
            parts.append("\(skippedRecipes) skipped")
        }
        return parts.isEmpty ? "No changes" : parts.joined(separator: ", ")
    }
}

@MainActor
class RecipeBackupManager {
    static let shared = RecipeBackupManager()
    
    private init() {}
    
    // MARK: - Export
    
    /// Creates a backup package of all recipes with their images
    func createBackup(from recipes: [Recipe]) async throws -> URL {
        guard !recipes.isEmpty else {
            throw RecipeBackupError.noRecipesToBackup
        }
        
        logInfo("Starting backup of \(recipes.count) recipe(s)", category: "backup")
        
        var recipeBackups: [RecipeBackup] = []
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        for recipe in recipes {
            guard let recipeModel = recipe.toRecipeModel() else {
                logWarning("Skipping recipe '\(recipe.title)' - could not convert to RecipeModel", category: "backup")
                continue
            }
            
            // Load main image if exists
            var mainImageBackup: RecipeBackup.ImageBackup?
            if let mainImageName = recipe.imageName {
                let imageURL = documentsPath.appendingPathComponent(mainImageName)
                if let imageData = try? Data(contentsOf: imageURL) {
                    mainImageBackup = RecipeBackup.ImageBackup(fileName: mainImageName, imageData: imageData)
                    logDebug("Loaded main image '\(mainImageName)' for '\(recipe.title)'", category: "backup")
                } else {
                    logWarning("Could not load main image '\(mainImageName)' for '\(recipe.title)'", category: "backup")
                }
            }
            
            // Load additional images if exist
            var additionalImageBackups: [RecipeBackup.ImageBackup]?
            if let additionalImageNames = recipe.additionalImageNames, !additionalImageNames.isEmpty {
                var imageBackups: [RecipeBackup.ImageBackup] = []
                for imageName in additionalImageNames {
                    let imageURL = documentsPath.appendingPathComponent(imageName)
                    if let imageData = try? Data(contentsOf: imageURL) {
                        imageBackups.append(RecipeBackup.ImageBackup(fileName: imageName, imageData: imageData))
                        logDebug("Loaded additional image '\(imageName)' for '\(recipe.title)'", category: "backup")
                    } else {
                        logWarning("Could not load additional image '\(imageName)' for '\(recipe.title)'", category: "backup")
                    }
                }
                if !imageBackups.isEmpty {
                    additionalImageBackups = imageBackups
                }
            }
            
            let backup = RecipeBackup(
                recipe: recipeModel,
                dateAdded: recipe.dateAdded,
                mainImage: mainImageBackup,
                additionalImages: additionalImageBackups
            )
            
            recipeBackups.append(backup)
        }
        
        let package = RecipeBackupPackage(recipes: recipeBackups)
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData: Data
        do {
            jsonData = try encoder.encode(package)
        } catch {
            logError("Failed to encode backup: \(error)", category: "backup")
            throw RecipeBackupError.encodingFailed(error)
        }
        
        // Create temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "RecipeBackup_\(dateString).reczipes"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try jsonData.write(to: fileURL)
            logInfo("Backup created successfully: \(fileName) (\(jsonData.count) bytes)", category: "backup")
            return fileURL
        } catch {
            logError("Failed to write backup file: \(error)", category: "backup")
            throw RecipeBackupError.fileCreationFailed
        }
    }
    
    // MARK: - Import
    
    /// Imports recipes from a backup file
    func importBackup(
        from url: URL,
        into modelContext: ModelContext,
        existingRecipes: [Recipe],
        overwriteMode: ImportOverwriteMode
    ) async throws -> RecipeImportResult {
        logInfo("Starting import from \(url.lastPathComponent)", category: "backup")
        
        // Read and decode the backup file
        let jsonData: Data
        do {
            jsonData = try Data(contentsOf: url)
        } catch {
            logError("Failed to read backup file: \(error)", category: "backup")
            throw RecipeBackupError.invalidBackupFile
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let package: RecipeBackupPackage
        do {
            package = try decoder.decode(RecipeBackupPackage.self, from: jsonData)
        } catch {
            logError("Failed to decode backup file: \(error)", category: "backup")
            throw RecipeBackupError.decodingFailed(error)
        }
        
        logInfo("Backup package version \(package.version), exported \(package.exportDate), contains \(package.recipeCount) recipe(s)", category: "backup")
        
        var newCount = 0
        var updatedCount = 0
        var skippedCount = 0
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        for recipeBackup in package.recipes {
            let recipeModel = recipeBackup.recipe
            
            // Check if recipe already exists
            let existingRecipe = existingRecipes.first { $0.id == recipeModel.id }
            
            if let existing = existingRecipe {
                switch overwriteMode {
                case .skip:
                    logDebug("Skipping existing recipe '\(recipeModel.title)'", category: "backup")
                    skippedCount += 1
                    continue
                    
                case .overwrite:
                    logInfo("Overwriting existing recipe '\(recipeModel.title)'", category: "backup")
                    // Delete the existing recipe (images will be overwritten)
                    modelContext.delete(existing)
                    updatedCount += 1
                    
                case .keepBoth:
                    logInfo("Keeping both versions of '\(recipeModel.title)'", category: "backup")
                    // Will create new recipe with new ID below
                    newCount += 1
                }
            } else {
                newCount += 1
            }
            
            // Restore images
            var restoredMainImageName: String?
            if let mainImage = recipeBackup.mainImage {
                let imageURL = documentsPath.appendingPathComponent(mainImage.fileName)
                do {
                    try mainImage.imageData.write(to: imageURL)
                    restoredMainImageName = mainImage.fileName
                    logDebug("Restored main image '\(mainImage.fileName)'", category: "backup")
                } catch {
                    logWarning("Failed to restore main image '\(mainImage.fileName)': \(error)", category: "backup")
                }
            }
            
            var restoredAdditionalImageNames: [String]?
            if let additionalImages = recipeBackup.additionalImages, !additionalImages.isEmpty {
                var restoredNames: [String] = []
                for image in additionalImages {
                    let imageURL = documentsPath.appendingPathComponent(image.fileName)
                    do {
                        try image.imageData.write(to: imageURL)
                        restoredNames.append(image.fileName)
                        logDebug("Restored additional image '\(image.fileName)'", category: "backup")
                    } catch {
                        logWarning("Failed to restore additional image '\(image.fileName)': \(error)", category: "backup")
                    }
                }
                if !restoredNames.isEmpty {
                    restoredAdditionalImageNames = restoredNames
                }
            }
            
            // Create recipe model with restored image names
            var recipeToImport = recipeModel
            if let mainImageName = restoredMainImageName {
                recipeToImport = recipeToImport.withImageName(mainImageName)
            }
            if let additionalNames = restoredAdditionalImageNames {
                recipeToImport = recipeToImport.withAdditionalImageNames(additionalNames)
            }
            
            // Handle keep both mode - create new ID
            if overwriteMode == .keepBoth && existingRecipe != nil {
                recipeToImport = RecipeModel(
                    id: UUID(), // New ID
                    title: recipeToImport.title,
                    headerNotes: recipeToImport.headerNotes,
                    yield: recipeToImport.yield,
                    ingredientSections: recipeToImport.ingredientSections,
                    instructionSections: recipeToImport.instructionSections,
                    notes: recipeToImport.notes,
                    reference: recipeToImport.reference,
                    imageName: recipeToImport.imageName,
                    additionalImageNames: recipeToImport.additionalImageNames,
                    imageURLs: recipeToImport.imageURLs
                )
            }
            
            // Create and insert the recipe
            let newRecipe = Recipe(from: recipeToImport)
            modelContext.insert(newRecipe)
            logDebug("Imported recipe '\(recipeToImport.title)'", category: "backup")
        }
        
        // Save the context
        do {
            try modelContext.save()
            logInfo("Import completed: \(newCount) new, \(updatedCount) updated, \(skippedCount) skipped", category: "backup")
        } catch {
            logError("Failed to save imported recipes: \(error)", category: "backup")
            throw RecipeBackupError.importFailed(error)
        }
        
        return RecipeImportResult(
            newRecipes: newCount,
            updatedRecipes: updatedCount,
            skippedRecipes: skippedCount,
            totalRecipes: package.recipeCount
        )
    }
}

enum ImportOverwriteMode {
    case skip          // Skip recipes that already exist
    case overwrite     // Replace existing recipes with imported ones
    case keepBoth      // Import as new recipe with different ID
}

// MARK: - RecipeModel Extension

extension RecipeModel {
    func withImageName(_ imageName: String) -> RecipeModel {
        RecipeModel(
            id: self.id,
            title: self.title,
            headerNotes: self.headerNotes,
            yield: self.yield,
            ingredientSections: self.ingredientSections,
            instructionSections: self.instructionSections,
            notes: self.notes,
            reference: self.reference,
            imageName: imageName,
            additionalImageNames: self.additionalImageNames,
            imageURLs: self.imageURLs
        )
    }
    
    func withAdditionalImageNames(_ names: [String]) -> RecipeModel {
        RecipeModel(
            id: self.id,
            title: self.title,
            headerNotes: self.headerNotes,
            yield: self.yield,
            ingredientSections: self.ingredientSections,
            instructionSections: self.instructionSections,
            notes: self.notes,
            reference: self.reference,
            imageName: self.imageName,
            additionalImageNames: names,
            imageURLs: self.imageURLs
        )
    }
}
