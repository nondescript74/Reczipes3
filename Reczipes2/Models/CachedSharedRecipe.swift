//
//  CachedSharedRecipe.swift
//  Reczipes2
//
//  Created on 1/23/26.
//

import Foundation
import SwiftData

/// Temporary cache of community recipes for viewing and cooking
/// Auto-cleaned after 30 days of no access
@Model
final class CachedSharedRecipe {
    var id: UUID = UUID() // CloudKit recipe ID
    var title: String = ""
    var headerNotes: String?
    var yield: String?
    var ingredientSections: [IngredientSection] = []
    var instructionSections: [InstructionSection] = []
    var notes: [RecipeNote] = []
    var reference: String?
    var imageName: String?
    var additionalImageNames: [String]?
    
    // Metadata
    var sharedByUserID: String = ""
    var sharedByUserName: String?
    var sharedDate: Date = Date()
    var cachedDate: Date = Date()
    var lastAccessedDate: Date = Date()
    
    // Distinguish from imported recipes
    var isTemporaryCache: Bool = true
    
    init(from cloudRecipe: CloudKitRecipe) {
        self.id = cloudRecipe.id
        self.title = cloudRecipe.title
        self.headerNotes = cloudRecipe.headerNotes
        self.yield = cloudRecipe.yield
        self.ingredientSections = cloudRecipe.ingredientSections
        self.instructionSections = cloudRecipe.instructionSections
        self.notes = cloudRecipe.notes
        self.reference = cloudRecipe.reference
        self.imageName = cloudRecipe.imageName
        self.additionalImageNames = cloudRecipe.additionalImageNames
        self.sharedByUserID = cloudRecipe.sharedByUserID
        self.sharedByUserName = cloudRecipe.sharedByUserName
        self.sharedDate = cloudRecipe.sharedDate
        self.cachedDate = Date()
        self.lastAccessedDate = Date()
    }
}
