//
//  RecipeBackup.swift
//  Reczipes2
//
//  Created by Xcode Assistant on 12/20/25.
//

import Foundation

/// A complete backup of a recipe including all data and associated images
struct RecipeBackup: Codable {
    let recipe: RecipeModel
    let dateAdded: Date
    let mainImage: ImageBackup?
    let additionalImages: [ImageBackup]?
    
    struct ImageBackup: Codable {
        let fileName: String
        let imageData: Data
    }
}

/// Container for multiple recipe backups
struct RecipeBackupPackage: Codable {
    let version: String
    let exportDate: Date
    let recipeCount: Int
    let recipes: [RecipeBackup]
    
    init(recipes: [RecipeBackup]) {
        self.version = "1.0"
        self.exportDate = Date()
        self.recipeCount = recipes.count
        self.recipes = recipes
    }
}
