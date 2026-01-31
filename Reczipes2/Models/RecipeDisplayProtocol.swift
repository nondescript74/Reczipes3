//
//  RecipeDisplayProtocol.swift
//  Reczipes2
//
//  Created on 1/31/26.
//

import Foundation

/// Protocol for displaying recipes in lists and detail views
/// Allows both RecipeX (owned recipes) and CachedSharedRecipe (community recipes) to be displayed uniformly
protocol RecipeDisplayProtocol {
    var displayID: UUID { get }
    var displayTitle: String { get }
    var headerNotes: String? { get }
    var yield: String? { get }
    var ingredientSections: [IngredientSection] { get }
    var instructionSections: [InstructionSection] { get }
    var notes: [RecipeNote] { get }
    var reference: String? { get }
    var imageName: String? { get }
    var additionalImageNames: [String]? { get }
    
    // Metadata for display
    var displayDate: Date { get }
    var isSharedRecipe: Bool { get }
    var sharedByUserName: String? { get }
}

/// Extension to make RecipeX conform to RecipeDisplayProtocol
extension RecipeX: RecipeDisplayProtocol {
    // Protocol uses displayID and displayTitle to avoid conflicts with RecipeX's optional id/title
    var displayID: UUID {
        self.safeID // RecipeX already has safeID computed property
    }
    
    var displayTitle: String {
        self.safeTitle // RecipeX already has safeTitle computed property
    }
    
    var displayDate: Date {
        dateAdded ?? Date()
    }
    
    var isSharedRecipe: Bool {
        false // RecipeX are owned recipes
    }
    
    var sharedByUserName: String? {
        nil // Not shared, so no sharer name
    }
}

/// Extension to make CachedSharedRecipe conform to RecipeDisplayProtocol
extension CachedSharedRecipe: RecipeDisplayProtocol {
    var displayID: UUID {
        id
    }
    
    var displayTitle: String {
        title
    }
    
    var displayDate: Date {
        cachedDate
    }
    
    var isSharedRecipe: Bool {
        true // CachedSharedRecipe are always shared recipes
    }
    
    // sharedByUserName already exists on CachedSharedRecipe
}
