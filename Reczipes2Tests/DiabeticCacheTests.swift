//  DiabeticCacheTests.swift
//  Reczipes2Tests
//
//  Tests for diabetic analysis caching with ingredient change detection
//  Created by Zahirudeen Premji on 12/25/25.
//

import Testing
import Foundation
@testable import Reczipes2

@Suite("Diabetic Analysis Caching Tests")
struct DiabeticCacheTests {
    
    @Test("Ingredients hash calculation is consistent")
    nonisolated func ingredientsHashConsistency() async throws {
        // Create ingredient data
        let ingredients1 = await [
            IngredientSection(
                title: "Main",
                ingredients: [
                    Ingredient(quantity: "2", unit: "cups", name: "flour"),
                    Ingredient(quantity: "1", unit: "cup", name: "sugar")
                ]
            )
        ]
        
        let encoder = JSONEncoder()
        let data1 = try encoder.encode(ingredients1)
        let hash1 = Recipe.calculateIngredientsHash(from: data1)
        
        // Create identical ingredients (different order)
        let ingredients2 = await [
            IngredientSection(
                title: "Main",
                ingredients: [
                    Ingredient(quantity: "1", unit: "cup", name: "sugar"),
                    Ingredient(quantity: "2", unit: "cups", name: "flour")
                ]
            )
        ]
        
        let data2 = try encoder.encode(ingredients2)
        let hash2 = Recipe.calculateIngredientsHash(from: data2)
        
        // Hashes should be identical (sorted internally)
        #expect(hash1 == hash2, "Hashes should match regardless of ingredient order")
        #expect(!hash1.isEmpty, "Hash should not be empty")
    }
    
    @Test("Ingredients hash changes when ingredients differ")
    nonisolated func ingredientsHashDifference() async throws {
        let encoder = JSONEncoder()
        
        // Original ingredients
        let ingredients1 = await [
            IngredientSection(
                title: "Main",
                ingredients: [
                    Ingredient(quantity: "2", unit: "cups", name: "flour")
                ]
            )
        ]
        let data1 = try encoder.encode(ingredients1)
        let hash1 = Recipe.calculateIngredientsHash(from: data1)
        
        // Modified ingredients (different quantity)
        let ingredients2 = await [
            IngredientSection(
                title: "Main",
                ingredients: [
                    Ingredient(quantity: "3", unit: "cups", name: "flour")
                ]
            )
        ]
        let data2 = try encoder.encode(ingredients2)
        let hash2 = Recipe.calculateIngredientsHash(from: data2)
        
        #expect(hash1 != hash2, "Hashes should differ when quantities change")
        
        // Modified ingredients (different name)
        let ingredients3 = await [
            IngredientSection(
                title: "Main",
                ingredients: [
                    Ingredient(quantity: "2", unit: "cups", name: "sugar")
                ]
            )
        ]
        let data3 = try encoder.encode(ingredients3)
        let hash3 = Recipe.calculateIngredientsHash(from: data3)
        
        #expect(hash1 != hash3, "Hashes should differ when ingredient names change")
    }
    
    @Test("Recipe version increments on ingredient update")
    nonisolated func recipeVersionIncrement() async throws {
        let encoder = JSONEncoder()
        
        // Create a recipe
        let recipeModel = await RecipeModel(
            title: "Test Recipe",
            ingredientSections: [
                IngredientSection(
                    title: "Main",
                    ingredients: [
                        Ingredient(quantity: "2", unit: "cups", name: "flour")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(steps: [
                    InstructionStep(text: "Mix ingredients")
                ])
            ]
        )
        
        let recipe = Recipe(from: recipeModel)
        let initialVersion = recipe.currentVersion  // ✅ Use computed property
        let initialHash = recipe.ingredientsHash
        
        #expect(initialVersion == 1, "Initial version should be 1")
        #expect(initialHash != nil, "Initial hash should be calculated")
        
        // Update ingredients
        let newIngredients = await [
            IngredientSection(
                title: "Main",
                ingredients: [
                    Ingredient(quantity: "3", unit: "cups", name: "flour") // Changed quantity
                ]
            )
        ]
        let newData = try encoder.encode(newIngredients)
        
        recipe.updateIngredients(newData)
        
        #expect(recipe.currentVersion == initialVersion + 1, "Version should increment after update")  // ✅ Use computed property
        #expect(recipe.ingredientsHash != initialHash, "Hash should change with ingredients")
        #expect(recipe.modificationDate > Date(timeIntervalSinceNow: -1), "lastModified should be recent")  // ✅ Use computed property
    }
    
    @Test("Cache detects ingredient changes via version")
    @MainActor func cacheDetectsVersionChange() async throws {
        let encoder = JSONEncoder()
        
        // Create recipe and cache
        let recipeModel = RecipeModel(
            title: "Test Recipe",
            ingredientSections: [
                IngredientSection(ingredients: [
                    Ingredient(quantity: "2", unit: "cups", name: "flour")
                ])
            ],
            instructionSections: [
                InstructionSection(steps: [InstructionStep(text: "Mix")])
            ]
        )
        
        let recipe = Recipe(from: recipeModel)
        
        // Create a mock cache entry
        let mockAnalysis = DiabeticInfo(
            id: UUID(),
            recipeId: recipe.id,
            lastUpdated: Date(),
            estimatedGlycemicLoad: nil,
            glycemicImpactFactors: [],
            carbCount: CarbInfo(totalCarbs: 50, netCarbs: 45, fiber: 5),
            fiberContent: FiberInfo(total: 5),
            sugarBreakdown: SugarBreakdown(total: 10),
            diabeticGuidance: [],
            portionRecommendations: nil,
            substitutionSuggestions: [],
            sources: [],
            consensusLevel: .strongConsensus
        )
        
        let analysisData = try encoder.encode(mockAnalysis)
        
        // ✅ Use computed properties for cache initialization
        let cached = CachedDiabeticAnalysis(
            recipeId: recipe.id,
            analysisData: analysisData,
            cachedAt: Date(),
            recipeVersion: recipe.currentVersion,
            ingredientsHash: recipe.ingredientsHash ?? "",
            recipeLastModified: recipe.modificationDate
        )
        
        // Cache should be valid initially
        #expect(cached.isValid(for: recipe), "Cache should be valid for unchanged recipe")
        
        // Update recipe version
        let newIngredients = [
            IngredientSection(ingredients: [
                Ingredient(quantity: "3", unit: "cups", name: "flour")
            ])
        ]
        let newData = try encoder.encode(newIngredients)
        recipe.updateIngredients(newData)
        
        // Cache should now be invalid
        #expect(!cached.isValid(for: recipe), "Cache should be invalid after ingredient change")
        #expect(cached.isIngredientsOutdated(recipe: recipe), "Cache should detect outdated ingredients")
    }
    
    @Test("Cache detects ingredient changes via hash")
    @MainActor func cacheDetectsHashChange() async throws {
        let encoder = JSONEncoder()
        
        // Create recipe
        let recipeModel = RecipeModel(
            title: "Test Recipe",
            ingredientSections: [
                IngredientSection(ingredients: [
                    Ingredient(quantity: "2", unit: "cups", name: "flour")
                ])
            ],
            instructionSections: [
                InstructionSection(steps: [InstructionStep(text: "Mix")])
            ]
        )
        
        let recipe = Recipe(from: recipeModel)
        
        // Create cache with current hash
        let mockAnalysis = DiabeticInfo(
            id: UUID(),
            recipeId: recipe.id,
            lastUpdated: Date(),
            estimatedGlycemicLoad: nil,
            glycemicImpactFactors: [],
            carbCount: CarbInfo(totalCarbs: 50, netCarbs: 45, fiber: 5),
            fiberContent: FiberInfo(total: 5),
            sugarBreakdown: SugarBreakdown(total: 10),
            diabeticGuidance: [],
            portionRecommendations: nil,
            substitutionSuggestions: [],
            sources: [],
            consensusLevel: .strongConsensus
        )
        
        let analysisData = try encoder.encode(mockAnalysis)
        
        // ✅ Use computed properties for cache initialization
        let cached = CachedDiabeticAnalysis(
            recipeId: recipe.id,
            analysisData: analysisData,
            cachedAt: Date(),
            recipeVersion: recipe.currentVersion,
            ingredientsHash: recipe.ingredientsHash ?? "",
            recipeLastModified: recipe.modificationDate
        )
        
        // Manually change hash (simulating shared recipe with different ingredients)
        recipe.ingredientsHash = "different_hash_value"
        
        // Cache should detect the change
        #expect(!cached.isValid(for: recipe), "Cache should be invalid with different hash")
        #expect(cached.isIngredientsOutdated(recipe: recipe), "Should detect hash mismatch")
    }
    
    @Test("Cache expires after 30 days")
    @MainActor func cacheExpiration() async throws {
        let encoder = JSONEncoder()
        
        let mockAnalysis = DiabeticInfo(
            id: UUID(),
            recipeId: UUID(),
            lastUpdated: Date(),
            estimatedGlycemicLoad: nil,
            glycemicImpactFactors: [],
            carbCount: CarbInfo(totalCarbs: 50, netCarbs: 45, fiber: 5),
            fiberContent: FiberInfo(total: 5),
            sugarBreakdown: SugarBreakdown(total: 10),
            diabeticGuidance: [],
            portionRecommendations: nil,
            substitutionSuggestions: [],
            sources: [],
            consensusLevel: .strongConsensus
        )
        
        let analysisData = try encoder.encode(mockAnalysis)
        
        // Create cache from 31 days ago
        let oldDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        
        let cached = CachedDiabeticAnalysis(
            recipeId: UUID(),
            analysisData: analysisData,
            cachedAt: oldDate,
            recipeVersion: 1,
            ingredientsHash: "test_hash",
            recipeLastModified: oldDate
        )
        
        #expect(cached.isStale, "Cache should be stale after 30 days")
        
        // Create fresh cache
        let freshCached = CachedDiabeticAnalysis(
            recipeId: UUID(),
            analysisData: analysisData,
            cachedAt: Date(),
            recipeVersion: 1,
            ingredientsHash: "test_hash",
            recipeLastModified: Date()
        )
        
        #expect(!freshCached.isStale, "Fresh cache should not be stale")
    }
    
    @Test("SHA256 hash is stable")
    nonisolated func sha256HashStability() async throws {
        let testString = "test_ingredient_data"
        
        let hash1 = testString.sha256Hash()
        let hash2 = testString.sha256Hash()
        
        #expect(hash1 == hash2, "Hash should be deterministic")
        #expect(hash1.count == 64, "SHA-256 produces 64-character hex string")
        
        // Different strings should produce different hashes
        let differentString = "different_data"
        let hash3 = differentString.sha256Hash()
        
        #expect(hash1 != hash3, "Different inputs should produce different hashes")
    }
}
