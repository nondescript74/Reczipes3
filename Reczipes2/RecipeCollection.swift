//
//  RecipeCollection.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/5/25.
//
//  Single source of truth for all recipes with stable UUIDs

import Foundation

final class RecipeCollection {
    static let shared = RecipeCollection()
    
    /// All available recipes with stable UUIDs
    let allRecipes: [RecipeModel]
    
    private init() {
        // Recipes are created ONCE when the app launches
        // Their UUIDs remain stable throughout the app's lifetime
        self.allRecipes = [
            // Import all recipes from Extensions
            .limePickleExample,
            .ambliNiChutney,
            .carrotPickle,
            .corianderChutney,
            .cucumberRaita,
            .dhokraChutney,
            .driedCarrots,
            .eggplantRaita,
            .garamMasala,
            .ghee,
            .homemadeYogurt,
            .instantTomatoChutney,
            .kachumber,
            .kadho,
            .lassi,
            .lemonChutney,
            .mangoPickleInOil,
            .sherbet,
            .vegetableSoup,
            .vegetableSambhar
        ]
    }
    
    /// Find a recipe by its ID
    func recipe(withID id: UUID) -> RecipeModel? {
        allRecipes.first { $0.id == id }
    }
    
    /// Find a recipe by its title
    func recipe(withTitle title: String) -> RecipeModel? {
        allRecipes.first { $0.title == title }
    }
}
