//
//  Recipe.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID = UUID()
    var title: String = ""
    var headerNotes: String?
    var recipeYield: String?
    var reference: String?
    var dateAdded: Date = Date()
    var imageName: String? // Main/primary image (set during extraction, immutable in UI)
    var additionalImageNames: [String]? // Additional images added by user
    
    // Image data stored directly in SwiftData for CloudKit sync
    @Attribute(.externalStorage) var imageData: Data? // Main image data
    @Attribute(.externalStorage) var additionalImagesData: Data? // JSON array of additional image data
    
    // Store complex structures as JSON Data
    var ingredientSectionsData: Data?
    var instructionSectionsData: Data?
    var notesData: Data?
    
    // Version tracking for cache invalidation (optional for backward compatibility)
    var version: Int? // Increments on each edit, defaults to 1 for existing recipes
    var lastModified: Date? // Timestamp of last modification
    var ingredientsHash: String? // Hash of ingredients for change detection
    
    // Computed property for safe version access
    var currentVersion: Int {
        return version ?? 1
    }
    
    // Computed property for safe lastModified access
    var modificationDate: Date {
        return lastModified ?? dateAdded
    }
    
    init(id: UUID = UUID(),
         title: String,
         headerNotes: String? = nil,
         recipeYield: String? = nil,
         reference: String? = nil,
         dateAdded: Date = Date(),
         imageName: String? = nil,
         additionalImageNames: [String]? = nil,
         imageData: Data? = nil,
         additionalImagesData: Data? = nil,
         ingredientSectionsData: Data? = nil,
         instructionSectionsData: Data? = nil,
         notesData: Data? = nil,
         version: Int? = 1,
         lastModified: Date? = nil,
         ingredientsHash: String? = nil) {
        self.id = id
        self.title = title
        self.headerNotes = headerNotes
        self.recipeYield = recipeYield
        self.reference = reference
        self.dateAdded = dateAdded
        self.imageName = imageName
        self.additionalImageNames = additionalImageNames
        self.imageData = imageData
        self.additionalImagesData = additionalImagesData
        self.ingredientSectionsData = ingredientSectionsData
        self.instructionSectionsData = instructionSectionsData
        self.notesData = notesData
        self.version = version
        self.lastModified = lastModified ?? Date()
        self.ingredientsHash = ingredientsHash ?? Self.calculateIngredientsHash(from: ingredientSectionsData)
    }
    
    // Helper computed properties
    var allImageNames: [String] {
        var images: [String] = []
        if let mainImage = imageName {
            images.append(mainImage)
        }
        if let additional = additionalImageNames {
            images.append(contentsOf: additional)
        }
        return images
    }
    
    var imageCount: Int {
        var count = 0
        if imageName != nil { count += 1 }
        count += additionalImageNames?.count ?? 0
        return count
    }
    
    // MARK: - Image Data Management
    
    /// Load image data from file system if not already stored
    func ensureImageDataLoaded() {
        // Load main image if we have a filename but no data
        if let imageName = imageName, imageData == nil {
            if let data = loadImageData(fileName: imageName) {
                self.imageData = data
            }
        }
        
        // Load additional images if we have filenames but no data
        if let additionalNames = additionalImageNames, !additionalNames.isEmpty, additionalImagesData == nil {
            var imagesArray: [[String: Data]] = []
            for imageName in additionalNames {
                if let data = loadImageData(fileName: imageName) {
                    imagesArray.append(["fileName": imageName.data(using: .utf8)!, "imageData": data])
                }
            }
            
            if !imagesArray.isEmpty {
                // Encode as JSON
                if let encoded = try? JSONEncoder().encode(imagesArray) {
                    self.additionalImagesData = encoded
                }
            }
        }
    }
    
    /// Save image data back to file system (for compatibility with existing code)
    func ensureImageFilesExist() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Restore main image if data exists but file doesn't
        if let imageData = imageData, let imageName = imageName {
            let fileURL = documentsPath.appendingPathComponent(imageName)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                try? imageData.write(to: fileURL)
            }
        }
        
        // Restore additional images
        if let additionalImagesData = additionalImagesData,
           let imagesArray = try? JSONDecoder().decode([[String: Data]].self, from: additionalImagesData) {
            for imageDict in imagesArray {
                if let fileNameData = imageDict["fileName"],
                   let fileName = String(data: fileNameData, encoding: .utf8),
                   let data = imageDict["imageData"] {
                    let fileURL = documentsPath.appendingPathComponent(fileName)
                    if !FileManager.default.fileExists(atPath: fileURL.path) {
                        try? data.write(to: fileURL)
                    }
                }
            }
        }
    }
    
    private func loadImageData(fileName: String) -> Data? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    // Convenience initializer from RecipeModel
    convenience init(from recipeModel: RecipeModel) {
        let encoder = JSONEncoder()
        
        let ingredientsData = try? encoder.encode(recipeModel.ingredientSections)
        let instructionsData = try? encoder.encode(recipeModel.instructionSections)
        let notesData = try? encoder.encode(recipeModel.notes)
        
        self.init(
            id: recipeModel.id,
            title: recipeModel.title,
            headerNotes: recipeModel.headerNotes,
            recipeYield: recipeModel.yield,
            reference: recipeModel.reference,
            dateAdded: Date(),
            imageName: recipeModel.imageName,
            ingredientSectionsData: ingredientsData,
            instructionSectionsData: instructionsData,
            notesData: notesData,
            version: 1,
            lastModified: Date(),
            ingredientsHash: Self.calculateIngredientsHash(from: ingredientsData)
        )
    }
    
    // MARK: - Ingredient Change Detection
    
    /// Calculate a hash of the ingredients for change detection
    static func calculateIngredientsHash(from ingredientsData: Data?) -> String {
        guard let data = ingredientsData else { return "" }
        
        // Decode the ingredients
        let decoder = JSONDecoder()
        guard let sections = try? decoder.decode([IngredientSection].self, from: data) else {
            return ""
        }
        
        // Create a stable string representation of ingredients
        // Include: name, quantity, unit (but not preparation, as that's less critical)
        let ingredientStrings = sections.flatMap { section in
            section.ingredients.map { ingredient in
                let qty = ingredient.quantity ?? ""
                let unit = ingredient.unit ?? ""
                let name = ingredient.name
                return "\(qty)|\(unit)|\(name)"
            }
        }.sorted() // Sort for stable ordering
        
        let combined = ingredientStrings.joined(separator: "||")
        return combined.sha256Hash()
    }
    
    /// Update the recipe with new data and increment version
    func updateIngredients(_ ingredientsData: Data) {
        self.ingredientSectionsData = ingredientsData
        self.ingredientsHash = Self.calculateIngredientsHash(from: ingredientsData)
        self.version = currentVersion + 1 // Use computed property for safe access
        self.lastModified = Date()
    }
    
    /// Check if ingredients have changed compared to a hash
    func hasIngredientsChanged(comparedTo hash: String?) -> Bool {
        guard let hash = hash else { return true }
        return self.ingredientsHash != hash
    }
    
    // Convert back to RecipeModel for display
    func toRecipeModel() -> RecipeModel? {
        let decoder = JSONDecoder()
        
        guard let ingredientsData = ingredientSectionsData,
              let instructionsData = instructionSectionsData,
              let ingredients = try? decoder.decode([IngredientSection].self, from: ingredientsData),
              let instructions = try? decoder.decode([InstructionSection].self, from: instructionsData) else {
            return nil
        }
        
        let notes = notesData.flatMap { try? decoder.decode([RecipeNote].self, from: $0) } ?? []
        
        return RecipeModel(
            id: id,
            title: title,
            headerNotes: headerNotes,
            yield: recipeYield,
            ingredientSections: ingredients,
            instructionSections: instructions,
            notes: notes,
            reference: reference,
            imageName: imageName,
            additionalImageNames: additionalImageNames
        )
    }
}
// MARK: - String Extension for SHA256 Hashing

import CryptoKit

extension String {
    /// Generate SHA256 hash of the string
    func sha256Hash() -> String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

