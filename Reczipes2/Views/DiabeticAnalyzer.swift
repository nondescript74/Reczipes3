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
    
    /// Analyze a RecipeX for diabetic-friendly information
    /// - Parameters:
    ///   - recipe: The RecipeX to analyze
    ///   - modelContainer: SwiftData container for cache
    ///   - forceRefresh: Whether to bypass cache
    /// - Returns: Diabetic analysis information
    @MainActor
    func analyzeDiabeticInfo(
        for recipe: RecipeX,
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
