//
//  Recipe.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import Foundation
import SwiftData
import CryptoKit
import UIKit

// MARK: - CookingMode Compatibility

extension Recipe {
    
    // MARK: Flat Ingredients List
    
    /// Returns a flat array of all ingredients across all sections
    /// Formatted as "quantity unit name" for CookingMode display
    ///
    /// Example: ["2 cups flour", "1 tsp salt", "3 eggs"]
    var ingredients: [String] {
        // Decode the ingredientSections from stored Data
        guard let sectionsData = ingredientSectionsData,
              let sections = try? JSONDecoder().decode([IngredientSection].self, from: sectionsData) else {
            return []
        }
        
        // Flatten all sections and format each ingredient
        return sections.flatMap { section in
            section.ingredients.map { ingredient in
                formatIngredient(ingredient)
            }
        }
    }
    
    // MARK: Flat Instructions List
    
    /// Returns a flat array of all instruction steps across all sections
    /// Just the text of each step for CookingMode display
    ///
    /// Example: ["Preheat oven to 350°F", "Mix dry ingredients", "Add wet ingredients"]
    var instructions: [String] {
        // Decode the instructionSections from stored Data
        guard let sectionsData = instructionSectionsData,
              let sections = try? JSONDecoder().decode([InstructionSection].self, from: sectionsData) else {
            return []
        }
        
        // Flatten all sections and extract step text
        return sections.flatMap { section in
            section.steps.map { $0.text }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Formats an Ingredient into a readable string
    /// Combines quantity, unit, and name with proper spacing
    private func formatIngredient(_ ingredient: Ingredient) -> String {
        var parts: [String] = []
        
        // Add quantity if present (safely unwrap optional)
        if let quantity = ingredient.quantity, !quantity.trimmingCharacters(in: .whitespaces).isEmpty {
            parts.append(quantity)
        }
        
        // Add unit if present (safely unwrap optional)
        if let unit = ingredient.unit, !unit.trimmingCharacters(in: .whitespaces).isEmpty {
            parts.append(unit)
        }
        
        // Always add name (required)
        parts.append(ingredient.name)
        
        // Join with spaces
        return parts.joined(separator: " ")
    }
}

// MARK: - Optional: Enhanced CookingMode Features

extension Recipe {
    
    /// Number of servings (if available from yield string)
    /// CookingMode can use this for scaling ingredients
    var servings: Int? {
        guard let yieldString = recipeYield else { return nil }
        
        // Try to extract number from yield string
        // Example: "Serves 4" → 4, "Makes 12 cookies" → 12
        let numbers = yieldString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        
        return numbers.first
    }
    
    /// Cuisine type (if you add this to your model in the future)
    /// Placeholder for now - returns nil
    var cuisine: String? {
        // TODO: Add cuisine field to Recipe model if desired
        // For now, could parse from headerNotes or reference
        return nil
    }
    
    /// Prep time (if you add this to your model in the future)
    /// Placeholder for now - returns nil
    var prepTime: String? {
        // TODO: Add prepTime field to Recipe model if desired
        // For now, could parse from headerNotes or notes
        return nil
    }
    
    // Note: imageData is now a stored property in the main Recipe class
    // No need for computed property here since we store it directly
}

// MARK: - Data Validation

extension Recipe {
    
    /// Checks if recipe has minimum required data for CookingMode
    var isValidForCookingMode: Bool {
        return !title.isEmpty &&
               !ingredients.isEmpty &&
               !instructions.isEmpty
    }
    
    /// Returns missing fields for CookingMode compatibility
    var cookingModeMissingFields: [String] {
        var missing: [String] = []
        
        if title.isEmpty {
            missing.append("title")
        }
        if ingredients.isEmpty {
            missing.append("ingredients")
        }
        if instructions.isEmpty {
            missing.append("instructions")
        }
        
        return missing
    }
}


// MARK: - Usage Notes

/*
 USAGE:
 
 This extension provides computed properties that CookingMode expects
 without modifying your existing Recipe model structure.
 
 BEFORE:
 - Recipe stored: ingredientSectionsData (complex)
 - CookingMode wanted: ingredients (simple array)
 - ❌ Incompatible
 
 AFTER:
 - Recipe still stores: ingredientSectionsData (complex)
 - Extension provides: ingredients (computed property)
 - ✅ Compatible!
 
 BENEFITS:
 - ✅ No schema migration needed
 - ✅ No data changes required
 - ✅ Existing code still works
 - ✅ CookingMode gets what it needs
 - ✅ Can remove extension anytime
 
 TESTING:
 
 // In your code:
 let recipe: Recipe = // get a recipe
 print("Ingredients: \(recipe.ingredients)")
 print("Instructions: \(recipe.instructions)")
 print("Valid for cooking: \(recipe.isValidForCookingMode)")
 
 CUSTOMIZATION:
 
 If your Recipe model uses different property names:
 1. Update the property names in this extension
 2. Common variations:
    - ingredientSectionsData vs ingredientsData
    - instructionSectionsData vs instructionsData
 
 If your data structures are different:
 1. Adjust the decoder logic
 2. Update IngredientSection/InstructionSection types if needed
 
 TROUBLESHOOTING:
 
 "Cannot find IngredientSection in scope"
 → Import the file where IngredientSection is defined
 → Or define the struct here if needed
 
 "ingredients returns empty array"
 → Check decoder is successful: add debug prints
 → Verify data is actually stored in ingredientSectionsData
 → Check IngredientSection structure matches what's stored
 
 "Recipe already has ingredients property"
 → You might have a stored property named ingredients
 → Rename this computed property to flatIngredients
 → Update CookingMode files to use flatIngredients
 */

@Model
final class Recipe {
    var id: UUID = UUID()
    var title: String = ""
    var headerNotes: String?
    var recipeYield: String?
    var reference: String?
    var dateAdded: Date = Date()
    var dateCreated: Date?  // CloudKit creation timestamp (for duplicate resolution)
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
        guard let version = version else { return 1 }
        
        // Protect against corrupted data with extremely large values
        // If version is close to Int.max, reset to prevent overflow
        if version >= Int.max - 100 {
            return 1
        }
        
        return version
    }
    
    // Computed property for safe lastModified access
    var modificationDate: Date {
        return lastModified ?? dateAdded
    }
    
    // NEW: For duplicate detection
    var imageHash: String?
    var extractionSource: String? // "camera", "photos", "files"
    var originalFileName: String?
    
    init(id: UUID = UUID(),
         title: String,
         headerNotes: String? = nil,
         recipeYield: String? = nil,
         reference: String? = nil,
         dateAdded: Date = Date(),
         dateCreated: Date? = nil,
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
        self.dateCreated = dateCreated ?? Date()  // Default to now if not provided
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
    
    /// Get main image as UIImage (from imageData)
    /// No longer loads from file system - uses SwiftData imageData
    func getMainImage() -> UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
    
    /// Get all additional images as UIImage array (from additionalImagesData)
    /// No longer loads from file system - uses SwiftData additionalImagesData
    func getAdditionalImages() -> [UIImage] {
        guard let additionalImagesData = additionalImagesData,
              let decoded = try? JSONDecoder().decode([[String: Data]].self, from: additionalImagesData) else {
            return []
        }
        
        return decoded.compactMap { imageDict in
            guard let data = imageDict["data"] else { return nil }
            return UIImage(data: data)
        }
    }
    
    /// Get image by index (0 = main image, 1+ = additional images)
    func getImage(at index: Int) -> UIImage? {
        if index == 0 {
            return getMainImage()
        } else {
            let additionalImages = getAdditionalImages()
            let additionalIndex = index - 1
            guard additionalIndex < additionalImages.count else { return nil }
            return additionalImages[additionalIndex]
        }
    }
    
    /// Remove an additional image by index
    @MainActor
    func removeAdditionalImage(at index: Int) {
        guard let additionalImagesData = additionalImagesData,
              var decoded = try? JSONDecoder().decode([[String: Data]].self, from: additionalImagesData),
              index < decoded.count else {
            return
        }
        
        // Remove from data array
        decoded.remove(at: index)
        
        // Update additionalImagesData
        if decoded.isEmpty {
            self.additionalImagesData = nil
        } else {
            self.additionalImagesData = try? JSONEncoder().encode(decoded)
        }
        
        // Update additionalImageNames
        if var names = additionalImageNames, index < names.count {
            names.remove(at: index)
            self.additionalImageNames = names.isEmpty ? nil : names
        }
        
        logInfo("🗑️ Removed additional image at index \(index) for recipe: \(title)", category: "recipe")
    }
    
    // MARK: - Deprecated File-Based Methods
    
    /// DEPRECATED: No longer needed - images are stored in SwiftData imageData
    @MainActor @available(*, deprecated, message: "Images are now stored in imageData, not files")
    func ensureImageFilesExist() {
        // This method is no longer needed
        // Images are stored in SwiftData and sync via CloudKit
        logWarning("⚠️ ensureImageFilesExist() called but is deprecated - images in SwiftData", category: "recipe")
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
            additionalImageNames: recipeModel.additionalImageNames,
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
    @MainActor func updateIngredients(_ ingredientsData: Data) {
        self.ingredientSectionsData = ingredientsData
        self.ingredientsHash = Self.calculateIngredientsHash(from: ingredientsData)
        
        // Safely increment version with overflow protection
        let newVersion = currentVersion.addingReportingOverflow(1)
        if newVersion.overflow {
            // If overflow occurs, reset to 1
            self.version = 1
            logWarning("Warning: Recipe version overflow detected for '\(title)', resetting to 1", category: "recipe")
        } else {
            self.version = newVersion.partialValue
        }
        
        self.lastModified = Date()
    }
    
    /// Check if ingredients have changed compared to a hash
    func hasIngredientsChanged(comparedTo hash: String?) -> Bool {
        guard let hash = hash else { return true }
        return self.ingredientsHash != hash
    }
    
    // MARK: - Diagnostics
    
    /// Check if the recipe has a corrupted or problematic version number
    var hasVersionIssue: Bool {
        guard let version = version else { return false }
        return version >= Int.max - 100 || version < 0
    }
    
    /// Reset version to a safe value if corrupted
    @MainActor func resetVersionIfNeeded() {
        if hasVersionIssue {
            logWarning("Warning: Resetting corrupted version (\(version ?? 0)) for recipe '\(title)'", category: "recipe")
            self.version = 1
            self.lastModified = Date()
        }
    }
    
    // Convert back to RecipeModel for display
    @MainActor func toRecipeModel() -> RecipeModel? {
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
    
    // MARK: - Preview Helper
    
    @MainActor
    static var preview: Recipe {
        let sampleIngredients = [
            IngredientSection(
                title: "Main Ingredients",
                ingredients: [
                    Ingredient(quantity: "2", unit: "cups", name: "flour"),
                    Ingredient(quantity: "1", unit: "tsp", name: "salt"),
                    Ingredient(quantity: "3", unit: "", name: "eggs")
                ]
            )
        ]
        
        let sampleInstructions = [
            InstructionSection(
                title: "Preparation",
                steps: [
                    InstructionStep(stepNumber: 1, text: "Preheat oven to 350°F"),
                    InstructionStep(stepNumber: 2, text: "Mix dry ingredients in a bowl"),
                    InstructionStep(stepNumber: 3, text: "Add wet ingredients and stir until combined")
                ]
            )
        ]
        
        let sampleNotes = [
            RecipeNote(type: .tip, text: "Make sure all ingredients are at room temperature")
        ]
        
        let recipe = Recipe(
            title: "Sample Recipe",
            headerNotes: "A delicious sample recipe for testing",
            recipeYield: "Serves 4",
            reference: "Test Recipe",
            ingredientSectionsData: try? JSONEncoder().encode(sampleIngredients),
            instructionSectionsData: try? JSONEncoder().encode(sampleInstructions),
            notesData: try? JSONEncoder().encode(sampleNotes)
        )
        
        return recipe
    }
    
    // MARK: - Duplicate Detection
    
    /// Generate a content fingerprint for duplicate detection
    /// Combines title + ingredients hash + instructions hash
    /// Two recipes with the same fingerprint are likely duplicates
    var contentFingerprint: String {
        var components: [String] = []
        
        // Normalized title (lowercase, trimmed)
        let normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespaces)
        components.append(normalizedTitle)
        
        // Ingredients hash (already calculated for cache invalidation)
        if let hash = ingredientsHash {
            components.append(hash)
        }
        
        // Instructions hash
        if let instructionsData = instructionSectionsData {
            let instructionsHash = String(describing: instructionsData.hashValue)
            components.append(instructionsHash)
        }
        
        // Combine and hash
        let combined = components.joined(separator: "|")
        return combined.sha256Hash()
    }
}

// MARK: - String Extension for SHA256 Hashing

// MARK: - Image Migration

extension Recipe {
    /// Save image data directly to SwiftData (for CloudKit sync)
    /// This is the NEW way - replaces file-based storage
    @MainActor
    func setImage(_ image: UIImage, isMainImage: Bool = true) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            logError("Failed to convert image to JPEG data", category: "recipe")
            return
        }
        
        if isMainImage {
            // Set main image
            self.imageData = imageData
            
            // Also set imageName for backward compatibility (but file won't be saved)
            self.imageName = "recipe_\(id.uuidString).jpg"
            
            logInfo("✅ Saved main image data (\(imageData.count / 1024)KB) for recipe: \(title)", category: "recipe")
        } else {
            // Add to additional images
            var additionalImages: [[String: Data]] = []
            
            // Decode existing additional images
            if let existingData = additionalImagesData,
               let existing = try? JSONDecoder().decode([[String: Data]].self, from: existingData) {
                additionalImages = existing
            }
            
            // Add new image
            let imageName = "recipe_\(id.uuidString)_\(additionalImages.count).jpg"
            additionalImages.append(["data": imageData, "name": Data(imageName.utf8)])
            
            // Encode back to JSON
            if let encoded = try? JSONEncoder().encode(additionalImages) {
                self.additionalImagesData = encoded
            }
            
            // Update additionalImageNames for backward compatibility
            if self.additionalImageNames == nil {
                self.additionalImageNames = []
            }
            self.additionalImageNames?.append(imageName)
            
            logInfo("✅ Added additional image data (\(imageData.count / 1024)KB) for recipe: \(title)", category: "recipe")
        }
    }
    
    /// Get all image data (main + additional) for display or export
    func getAllImageData() -> [Data] {
        var images: [Data] = []
        
        // Add main image
        if let imageData = imageData {
            images.append(imageData)
        }
        
        // Add additional images
        if let additionalImagesData = additionalImagesData,
           let decoded = try? JSONDecoder().decode([[String: Data]].self, from: additionalImagesData) {
            for imageDict in decoded {
                if let data = imageDict["data"] {
                    images.append(data)
                }
            }
        }
        
        return images
    }
    
    /// Migrate file-based images to SwiftData imageData for CloudKit sync
    /// This loads images from the Documents directory and stores them in imageData
    /// so they sync properly via CloudKit. Call this once during app startup.
    ///
    /// Returns true if migration was performed, false if already migrated
    @MainActor
    func migrateImagesToSwiftData() -> Bool {
        var didMigrate = false
        
        // Only migrate if imageData is nil but we have an imageName
        if imageData == nil, let imageName = imageName {
            if let data = loadImageDataFromDocuments(imageName) {
                imageData = data
                didMigrate = true
                logInfo("✅ Migrated main image for recipe: \(title)", category: "migration")
            } else {
                logWarning("⚠️ Could not load image file for migration: \(imageName)", category: "migration")
            }
        }
        
        // Migrate additional images
        if additionalImagesData == nil, let additionalImageNames = additionalImageNames, !additionalImageNames.isEmpty {
            var migratedImages: [[String: Data]] = []
            
            for imageName in additionalImageNames {
                if let imageData = loadImageDataFromDocuments(imageName) {
                    migratedImages.append(["data": imageData, "name": Data(imageName.utf8)])
                }
            }
            
            if !migratedImages.isEmpty {
                // Encode array of image data as JSON
                if let encoded = try? JSONEncoder().encode(migratedImages) {
                    additionalImagesData = encoded
                    didMigrate = true
                    logInfo("✅ Migrated \(migratedImages.count) additional images for recipe: \(title)", category: "migration")
                }
            }
        }
        
        return didMigrate
    }
    
    /// Load image data from Documents directory
    @MainActor private func loadImageDataFromDocuments(_ filename: String) -> Data? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            logDebug("Could not load image file: \(filename) - \(error.localizedDescription)", category: "migration")
            return nil
        }
    }
    
    /// Clean up file-based images after successful migration to imageData
    /// Only call this AFTER confirming imageData is populated and synced
    @MainActor
    func cleanupFileBasedImages() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Delete main image file
        if let imageName = imageName {
            let fileURL = documentsPath.appendingPathComponent(imageName)
            try? fileManager.removeItem(at: fileURL)
            logDebug("🗑️ Cleaned up image file: \(imageName)", category: "migration")
        }
        
        // Delete additional image files
        if let additionalImageNames = additionalImageNames {
            for imageName in additionalImageNames {
                let fileURL = documentsPath.appendingPathComponent(imageName)
                try? fileManager.removeItem(at: fileURL)
                logDebug("🗑️ Cleaned up additional image file: \(imageName)", category: "migration")
            }
        }
    }
}



extension String {
    /// Generate SHA256 hash of the string
    nonisolated func sha256Hash() -> String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

