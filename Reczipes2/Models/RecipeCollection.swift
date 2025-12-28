//
//  RecipeCollection.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/5/25.
//
//  Single source of truth for all recipes extracted via Claude API

import Foundation
import SwiftData

final class RecipeCollection {
    static let shared = RecipeCollection()
    
    private init() {
        // Empty initializer - no bundled recipes
        // All recipes come from Claude API extraction and are stored in SwiftData
    }
    
    /// Returns all recipes from SwiftData (extracted via Claude API)
    func allRecipes(savedRecipes: [Recipe]) -> [RecipeModel] {
        // Convert saved Recipe objects to RecipeModels
        print("📚 RecipeCollection.allRecipes called with \(savedRecipes.count) saved recipes")
        let models = savedRecipes.compactMap { recipe -> RecipeModel? in
            let model = recipe.toRecipeModel()
            if let model = model {
                print("📚 Converting Recipe '\(recipe.title)' - imageName in Recipe: '\(recipe.imageName ?? "nil")' -> imageName in Model: '\(model.imageName ?? "nil")'")
            }
            return model
        }
        print("📚 RecipeCollection.allRecipes returning \(models.count) models")
        return models
    }
    
    /// Returns all recipes with their save status
    /// Note: In this simplified version, all recipes are always saved (isSaved: true)
    /// since we only work with Claude API-extracted recipes stored in SwiftData
    func allRecipesWithStatus(savedRecipes: [Recipe]) -> [(recipe: RecipeModel, isSaved: Bool)] {
        let savedModels = savedRecipes.compactMap { $0.toRecipeModel() }
        return savedModels.map { (recipe: $0, isSaved: true) }
    }
    
    /// Find a recipe by its ID
    func recipe(withID id: UUID, savedRecipes: [Recipe]) -> RecipeModel? {
        guard let savedRecipe = savedRecipes.first(where: { $0.id == id }) else {
            return nil
        }
        return savedRecipe.toRecipeModel()
    }
    
    /// Find a recipe by its title
    func recipe(withTitle title: String, savedRecipes: [Recipe]) -> RecipeModel? {
        guard let savedRecipe = savedRecipes.first(where: { $0.title == title }) else {
            return nil
        }
        return savedRecipe.toRecipeModel()
    }
    
    /// Check if a recipe exists in SwiftData
    /// Note: In this simplified version, this always returns true for recipes
    /// that exist in the app, since all recipes come from SwiftData
    func isRecipeSaved(_ recipe: RecipeModel, savedRecipes: [Recipe]) -> Bool {
        savedRecipes.contains { $0.id == recipe.id }
    }
}
