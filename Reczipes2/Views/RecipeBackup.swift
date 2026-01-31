//
//  RecipeBackup.swift
//  Reczipes2
//
//  Created by Xcode Assistant on 12/20/25.
//

import Foundation

/// Codable representation of RecipeX for backup/restore
struct RecipeData: Codable {
    // Core Identity
    let id: UUID?
    let title: String?
    
    // Recipe Content
    let headerNotes: String?
    let recipeYield: String?
    let reference: String?
    let ingredientSectionsData: Data?
    let instructionSectionsData: Data?
    let notesData: Data?
    
    // Images (data only, not file references)
    let imageData: Data?
    let additionalImagesData: Data?
    
    // Timestamps
    let dateAdded: Date?
    let dateCreated: Date?
    let lastModified: Date?
    
    // Versioning
    let version: Int?
    let ingredientsHash: String?
    let contentFingerprint: String?
    
    // User Attribution
    let ownerUserID: String?
    let ownerDisplayName: String?
    
    // Metadata
    let imageHash: String?
    let extractionSource: String?
    let originalFileName: String?
    let tagsData: Data?
    let cuisine: String?
    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?
    let difficultyLevel: Int?
    let personalRating: Int?
    let timesCooked: Int?
    let lastCookedDate: Date?
    
    // Explicit coding keys
    enum CodingKeys: String, CodingKey {
        case id, title, headerNotes, recipeYield, reference
        case ingredientSectionsData, instructionSectionsData, notesData
        case imageData, additionalImagesData
        case dateAdded, dateCreated, lastModified
        case version, ingredientsHash, contentFingerprint
        case ownerUserID, ownerDisplayName
        case imageHash, extractionSource, originalFileName
        case tagsData, cuisine, prepTimeMinutes, cookTimeMinutes
        case difficultyLevel, personalRating, timesCooked, lastCookedDate
    }
    
    /// Initialize from RecipeX
    init(from recipe: RecipeX) {
        self.id = recipe.id
        self.title = recipe.title
        self.headerNotes = recipe.headerNotes
        self.recipeYield = recipe.recipeYield
        self.reference = recipe.reference
        self.ingredientSectionsData = recipe.ingredientSectionsData
        self.instructionSectionsData = recipe.instructionSectionsData
        self.notesData = recipe.notesData
        self.imageData = recipe.imageData
        self.additionalImagesData = recipe.additionalImagesData
        self.dateAdded = recipe.dateAdded
        self.dateCreated = recipe.dateCreated
        self.lastModified = recipe.lastModified
        self.version = recipe.version
        self.ingredientsHash = recipe.ingredientsHash
        self.contentFingerprint = recipe.contentFingerprint
        self.ownerUserID = recipe.ownerUserID
        self.ownerDisplayName = recipe.ownerDisplayName
        self.imageHash = recipe.imageHash
        self.extractionSource = recipe.extractionSource
        self.originalFileName = recipe.originalFileName
        self.tagsData = recipe.tagsData
        self.cuisine = recipe.cuisine
        self.prepTimeMinutes = recipe.prepTimeMinutes
        self.cookTimeMinutes = recipe.cookTimeMinutes
        self.difficultyLevel = recipe.difficultyLevel
        self.personalRating = recipe.personalRating
        self.timesCooked = recipe.timesCooked
        self.lastCookedDate = recipe.lastCookedDate
    }
    
    /// Create a new RecipeX from this data
    func toRecipeX() -> RecipeX {
        let recipe = RecipeX(
            id: id,
            title: title,
            headerNotes: headerNotes,
            recipeYield: recipeYield,
            reference: reference,
            ingredientSectionsData: ingredientSectionsData,
            instructionSectionsData: instructionSectionsData,
            notesData: notesData,
            imageData: imageData,
            additionalImagesData: additionalImagesData,
            dateAdded: dateAdded,
            dateCreated: dateCreated,
            lastModified: lastModified,
            version: version,
            ingredientsHash: ingredientsHash,
            contentFingerprint: contentFingerprint,
            ownerUserID: ownerUserID,
            ownerDisplayName: ownerDisplayName,
            imageHash: imageHash,
            extractionSource: extractionSource,
            originalFileName: originalFileName,
            tagsData: tagsData,
            cuisine: cuisine,
            prepTimeMinutes: prepTimeMinutes,
            cookTimeMinutes: cookTimeMinutes,
            difficultyLevel: difficultyLevel,
            personalRating: personalRating,
            timesCooked: timesCooked
        )
        
        // Set lastCookedDate separately since it's not in the initializer
        recipe.lastCookedDate = lastCookedDate
        
        return recipe
    }
}

/// A complete backup of a recipe including all data and associated images
struct RecipeBackup: Codable {
    let recipe: RecipeData
    let dateAdded: Date
    let mainImage: ImageBackup?
    let additionalImages: [ImageBackup]?
    
    struct ImageBackup: Codable {
        let fileName: String
        let imageData: Data
    }
    
    // Explicit coding keys to ensure recipe is encoded
    enum CodingKeys: String, CodingKey {
        case recipe
        case dateAdded
        case mainImage
        case additionalImages
    }
    
    // Manual encoding to force recipe field to be included
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        print("🔵 RecipeBackup.encode called")
        print("🔵 About to encode recipe field - recipe.title: \(recipe.title ?? "nil")")
        
        // Force encode recipe field
        try container.encode(recipe, forKey: .recipe)
        print("🔵 ✅ Recipe field encoded successfully!")
        
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encodeIfPresent(mainImage, forKey: .mainImage)
        try container.encodeIfPresent(additionalImages, forKey: .additionalImages)
        
        print("🔵 RecipeBackup.encode completed")
    }
}

/// Container for multiple recipe backups
struct RecipeBackupPackage: Codable {
    let version: String
    let exportDate: Date
    let recipeCount: Int
    let recipes: [RecipeBackup]
    
    init(recipes: [RecipeBackup]) {
        self.version = "1.0"
        self.exportDate = Date()
        self.recipeCount = recipes.count
        self.recipes = recipes
    }
}
