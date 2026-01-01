//
//  CookingSession.swift
//  reczipes2-imageextract
//
//  SwiftData model for persisting cooking mode state
//

import Foundation
import SwiftData

@Model
final class CookingSession {
    var id: UUID = UUID()
    var primaryRecipeID: UUID?
    var secondaryRecipeID: UUID?
    var createdAt: Date = Date()
    var lastUpdated: Date = Date()
    var keepAwakeEnabled: Bool = true
    
    init(
        primaryRecipeID: UUID? = nil,
        secondaryRecipeID: UUID? = nil,
        keepAwakeEnabled: Bool = true
    ) {
        self.id = UUID()
        self.primaryRecipeID = primaryRecipeID
        self.secondaryRecipeID = secondaryRecipeID
        self.createdAt = Date()
        self.lastUpdated = Date()
        self.keepAwakeEnabled = keepAwakeEnabled
    }
    
    func updateRecipe(_ recipeID: UUID?, slot: Int) {
        if slot == 0 {
            primaryRecipeID = recipeID
        } else {
            secondaryRecipeID = recipeID
        }
        lastUpdated = Date()
    }
}
