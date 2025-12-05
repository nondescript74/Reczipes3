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
    var id: UUID
    var title: String
    var headerNotes: String?
    var recipeYield: String?
    var reference: String?
    var dateAdded: Date
    var imageName: String? // Name of the image in Assets catalog
    
    // Store complex structures as JSON Data
    var ingredientSectionsData: Data?
    var instructionSectionsData: Data?
    var notesData: Data?
    
    init(id: UUID = UUID(),
         title: String,
         headerNotes: String? = nil,
         recipeYield: String? = nil,
         reference: String? = nil,
         dateAdded: Date = Date(),
         imageName: String? = nil,
         ingredientSectionsData: Data? = nil,
         instructionSectionsData: Data? = nil,
         notesData: Data? = nil) {
        self.id = id
        self.title = title
        self.headerNotes = headerNotes
        self.recipeYield = recipeYield
        self.reference = reference
        self.dateAdded = dateAdded
        self.imageName = imageName
        self.ingredientSectionsData = ingredientSectionsData
        self.instructionSectionsData = instructionSectionsData
        self.notesData = notesData
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
            notesData: notesData
        )
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
            imageName: imageName
        )
    }
}
