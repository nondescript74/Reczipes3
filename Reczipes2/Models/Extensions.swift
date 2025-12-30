//
//  Extensions.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import Foundation

// MARK: - Recipe Collection
extension RecipeModel {
    /// All available recipes from the Extensions file.
    /// NOTE: Use RecipeCollection.shared.allRecipes instead for stable UUIDs!
    
    /// Returns a copy of this recipe with the specified image name
    func withImageName(_ imageName: String?) -> RecipeModel {
        RecipeModel(
            id: self.id,
            title: self.title,
            headerNotes: self.headerNotes,
            yield: self.yield,
            ingredientSections: self.ingredientSections,
            instructionSections: self.instructionSections,
            notes: self.notes,
            reference: self.reference,
            imageName: imageName
        )
    }
}

// MARK: - Ingredient Extensions
extension Ingredient {
    /// Returns a formatted display text for the ingredient
    var displayText: String {
        var parts: [String] = []
        
        if let quantity = quantity {
            parts.append(quantity)
        }
        
        if let unit = unit {
            parts.append(unit)
        }
        
        parts.append(name)
        
        if let preparation = preparation {
            parts.append("(\(preparation))")
        }
        
        return parts.joined(separator: " ")
    }
}
