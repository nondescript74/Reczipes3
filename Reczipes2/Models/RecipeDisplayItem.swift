//
//  RecipeDisplayItem.swift
//  Reczipes2
//
//  Created on 1/23/26.
//

import Foundation

/// Unified type for displaying both owned recipes and cached community recipes
enum RecipeDisplayItem: Identifiable {
    case owned(RecipeModel)
    case cached(CachedSharedRecipe)
    
    var id: UUID {
        switch self {
        case .owned(let recipe): return recipe.id
        case .cached(let cached): return cached.id
        }
    }
    
    var title: String {
        switch self {
        case .owned(let recipe): return recipe.title
        case .cached(let cached): return cached.title
        }
    }
    
    var headerNotes: String? {
        switch self {
        case .owned(let recipe): return recipe.headerNotes
        case .cached(let cached): return cached.headerNotes
        }
    }
    
    var yield: String? {
        switch self {
        case .owned(let recipe): return recipe.yield
        case .cached(let cached): return cached.yield
        }
    }
    
    var ingredientSections: [IngredientSection] {
        switch self {
        case .owned(let recipe): return recipe.ingredientSections
        case .cached(let cached): return cached.ingredientSections
        }
    }
    
    var instructionSections: [InstructionSection] {
        switch self {
        case .owned(let recipe): return recipe.instructionSections
        case .cached(let cached): return cached.instructionSections
        }
    }
    
    var notes: [RecipeNote] {
        switch self {
        case .owned(let recipe): return recipe.notes
        case .cached(let cached): return cached.notes
        }
    }
    
    var reference: String? {
        switch self {
        case .owned(let recipe): return recipe.reference
        case .cached(let cached): return cached.reference
        }
    }
    
    var imageName: String? {
        switch self {
        case .owned(let recipe): return recipe.imageName
        case .cached(let cached): return cached.imageName
        }
    }
    
    var additionalImageNames: [String]? {
        switch self {
        case .owned(let recipe): return recipe.additionalImageNames
        case .cached(let cached): return cached.additionalImageNames
        }
    }
    
    var imageURLs: [String]? {
        switch self {
        case .owned(let recipe): return recipe.imageURLs
        case .cached: return nil // Cached recipes don't have imageURLs
        }
    }
    
    var isCached: Bool {
        if case .cached = self { return true }
        return false
    }
    
    var sharedByUserName: String? {
        switch self {
        case .owned: return nil
        case .cached(let cached): return cached.sharedByUserName
        }
    }
    
    /// Convert to RecipeModel for compatibility with existing code
    func toRecipeModel() -> RecipeModel {
        switch self {
        case .owned(let recipe):
            return recipe
        case .cached(let cached):
            return RecipeModel(
                id: cached.id,
                title: cached.title,
                headerNotes: cached.headerNotes,
                yield: cached.yield,
                ingredientSections: cached.ingredientSections,
                instructionSections: cached.instructionSections,
                notes: cached.notes,
                reference: cached.reference,
                imageName: cached.imageName,
                additionalImageNames: cached.additionalImageNames
            )
        }
    }
}
