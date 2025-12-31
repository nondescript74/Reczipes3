//
//  AppClipSharedModels.swift
//  Reczipes2
//
//  Shared data models between main app and App Clip
//  Created by Zahirudeen Premji on 12/31/25.
//
//  ⚠️ IMPORTANT: This file must be included in BOTH targets:
//  - Reczipes2 (main app)
//  - Reczipes2Clip (App Clip)
//

import Foundation

// MARK: - Extracted Recipe Data

/// Data structure for recipes extracted in the App Clip
/// This structure is simple and Codable so it can be passed between targets via App Groups
struct AppClipExtractedRecipeData: Codable {
    let title: String
    let servings: Int
    let prepTime: String?
    let cookTime: String?
    let ingredients: [String]
    let instructions: [String]
    let notes: String?
    
    var totalTime: String? {
        // Calculate total time if both prep and cook are available
        guard let prep = prepTime, let cook = cookTime else { return nil }
        return "\(prep) + \(cook)"
    }
}
