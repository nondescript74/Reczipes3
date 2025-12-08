//
//  RecipeCollection.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/5/25.
//
//  Single source of truth for all recipes with stable UUIDs

import Foundation
import SwiftData

final class RecipeCollection {
    static let shared = RecipeCollection()
    
    /// All recipes from Extensions (stable source)
    /// These are the default recipes bundled with the app
    private let bundledRecipes: [RecipeModel]
    
    private init() {
        // Recipes are created ONCE when the app launches
        // Their UUIDs remain stable throughout the app's lifetime
        self.bundledRecipes = [
            // Import all recipes from Extensions
            .ambli_ni_chutney,
            .chicken_soup,
            .cucumber_raita,
            .dhokra_chutney,
            .eggplant_raita,
            .garam_masala,
            .ghee,
            .homemade_yogurt,
            .kachumber,
            .kadho,
            .lassi,
            .sherbet,
            .vegetable_soup,
            .vegetable_sambhar,
            .moong_bean_soup
        ]
    }
    
    /// Returns all recipes, merging bundled recipes with saved recipes from SwiftData
    /// If a recipe exists in both sources (matched by ID), the SwiftData version takes precedence
    /// as it contains user edits
    func allRecipes(savedRecipes: [Recipe]) -> [RecipeModel] {
        // Convert saved Recipe objects to RecipeModels
        let savedModels = savedRecipes.compactMap { $0.toRecipeModel() }
        
        // Create a set of saved recipe IDs for quick lookup
        let savedIDs = Set(savedModels.map { $0.id })
        
        // Filter out bundled recipes that have been saved (user-edited versions take precedence)
        let uniqueBundledRecipes = bundledRecipes.filter { !savedIDs.contains($0.id) }
        
        // Combine: saved recipes (user-edited) + bundled recipes not yet saved
        return savedModels + uniqueBundledRecipes
    }
    
    /// Returns all recipes, including a flag indicating if each is saved
    /// Useful for UI that needs to show save status
    func allRecipesWithStatus(savedRecipes: [Recipe]) -> [(recipe: RecipeModel, isSaved: Bool)] {
        let savedModels = savedRecipes.compactMap { $0.toRecipeModel() }
        let savedIDs = Set(savedModels.map { $0.id })
        
        // Saved recipes are marked as saved
        let savedWithStatus = savedModels.map { (recipe: $0, isSaved: true) }
        
        // Bundled recipes not yet saved are marked as not saved
        let bundledNotSaved = bundledRecipes
            .filter { !savedIDs.contains($0.id) }
            .map { (recipe: $0, isSaved: false) }
        
        return savedWithStatus + bundledNotSaved
    }
    
    /// Returns only the bundled recipes (from Extensions)
    /// Use this when you need the original, unedited versions
    var bundledRecipesOnly: [RecipeModel] {
        bundledRecipes
    }
    
    /// Find a recipe by its ID (checks both bundled and saved)
    func recipe(withID id: UUID, savedRecipes: [Recipe]) -> RecipeModel? {
        // First check saved recipes (they take precedence)
        if let savedRecipe = savedRecipes.first(where: { $0.id == id }) {
            return savedRecipe.toRecipeModel()
        }
        
        // Fall back to bundled recipes
        return bundledRecipes.first { $0.id == id }
    }
    
    /// Find a recipe by its title (checks both bundled and saved)
    func recipe(withTitle title: String, savedRecipes: [Recipe]) -> RecipeModel? {
        // First check saved recipes (they take precedence)
        if let savedRecipe = savedRecipes.first(where: { $0.title == title }) {
            return savedRecipe.toRecipeModel()
        }
        
        // Fall back to bundled recipes
        return bundledRecipes.first { $0.title == title }
    }
    
    /// Check if a recipe is saved in SwiftData
    func isRecipeSaved(_ recipe: RecipeModel, savedRecipes: [Recipe]) -> Bool {
        savedRecipes.contains { $0.id == recipe.id }
    }
}
