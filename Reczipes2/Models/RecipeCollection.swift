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
    /// Automatically deduplicates based on title and content
    func allRecipes(savedRecipes: [Recipe]) -> [RecipeModel] {
        logInfo("📚 RecipeCollection.allRecipes called with \(savedRecipes.count) saved recipes", category: "recipe")
        
        // Deduplicate first
        let deduplicatedRecipes = deduplicateRecipes(savedRecipes)
        
        if deduplicatedRecipes.count < savedRecipes.count {
            logWarning("⚠️ Found \(savedRecipes.count - deduplicatedRecipes.count) duplicate recipes (filtered out)", category: "recipe")
        }
        
        // Convert saved Recipe objects to RecipeModels
        let models = deduplicatedRecipes.compactMap { recipe -> RecipeModel? in
            let model = recipe.toRecipeModel()
            return model
        }
        
        logInfo("📚 RecipeCollection.allRecipes returning \(models.count) models", category: "recipe")
        return models
    }
    
    // MARK: - Deduplication
    
    /// Remove duplicate recipes, keeping the canonical (oldest) version
    private func deduplicateRecipes(_ recipes: [Recipe]) -> [Recipe] {
        var uniqueRecipes: [Recipe] = []
        var seenFingerprints: Set<String> = []
        
        // Sort by creation date (oldest first) to prefer older recipes
        let sortedRecipes = recipes.sorted { recipe1, recipe2 in
            let date1 = recipe1.dateCreated ?? recipe1.dateAdded
            let date2 = recipe2.dateCreated ?? recipe2.dateAdded
            return date1 < date2
        }
        
        for recipe in sortedRecipes {
            let fingerprint = recipe.contentFingerprint
            
            // Check if we've seen this content before
            if !seenFingerprints.contains(fingerprint) {
                uniqueRecipes.append(recipe)
                seenFingerprints.insert(fingerprint)
            } else {
                logInfo("🔍 Duplicate detected: '\(recipe.title)' (ID: \(recipe.id))", category: "recipe")
            }
        }
        
        return uniqueRecipes
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
