//
//  DiabeticAnalyzer.swift
//  Reczipes2
//
//  Simplified analyzer wrapper for diabetic analysis
//  Created by Zahirudeen Premji on 12/24/25.
//

import Foundation
import SwiftData

/// Main interface for diabetic analysis (uses DiabeticAnalysisService internally)
struct DiabeticAnalyzer {
    static let shared = DiabeticAnalyzer()
    
    private init() {}
    
    /// Analyze a recipe for diabetic-friendly information
    /// - Parameters:
    ///   - recipe: The RecipeModel to analyze
    ///   - modelContainer: SwiftData container for cache
    ///   - forceRefresh: Whether to bypass cache
    /// - Returns: Diabetic analysis information
    func analyzeDiabeticInfo(
        for recipe: RecipeModel,
        modelContainer: ModelContainer,
        forceRefresh: Bool = false
    ) async throws -> DiabeticInfo {
        // We need to convert RecipeModel to Recipe or work with Recipe directly
        // For now, create a temporary Recipe
        let tempRecipe = Recipe(from: recipe)
        
        return try await DiabeticAnalysisService.shared.analyzeDiabeticImpact(
            recipe: tempRecipe,
            modelContainer: modelContainer,
            forceRefresh: forceRefresh
        )
    }
    
    /// Analyze using Recipe directly (preferred method)
    /// - Parameters:
    ///   - recipe: The Recipe entity to analyze
    ///   - modelContainer: SwiftData container for cache
    ///   - forceRefresh: Whether to bypass cache
    /// - Returns: Diabetic analysis information
    func analyzeDiabeticInfo(
        for recipe: Recipe,
        modelContainer: ModelContainer,
        forceRefresh: Bool = false
    ) async throws -> DiabeticInfo {
        return try await DiabeticAnalysisService.shared.analyzeDiabeticImpact(
            recipe: recipe,
            modelContainer: modelContainer,
            forceRefresh: forceRefresh
        )
    }
}
