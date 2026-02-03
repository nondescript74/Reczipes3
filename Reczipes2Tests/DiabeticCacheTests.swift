//  DiabeticCacheTests.swift
//  Reczipes2Tests
//
//  Tests for diabetic analysis caching with ingredient change detection
//  Created by Zahirudeen Premji on 12/25/25.
//

import Testing
import Foundation
import OSLog
@testable import Reczipes2

@Suite("Diabetic Analysis Caching Tests", .serialized)
struct DiabeticCacheTests {
    
    // Logger for test diagnostics
    private let logger = Logger(subsystem: "com.reczipes.tests", category: "diabetic-cache")
    
    @Test("Ingredients hash calculation is consistent")
    nonisolated func ingredientsHashConsistency() async throws {
        logger.info("🧪 Starting ingredientsHashConsistency test")
        
        // Create ingredient data
        logger.info("📝 Creating first ingredient set")
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
        let hash1 = RecipeX.calculateIngredientsHash(from: data1)
        logger.info("✅ Hash 1: \(hash1 ?? "nil")")
        
        // Create identical ingredients (different order)
        logger.info("📝 Creating second ingredient set (different order)")
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
        let hash2 = RecipeX.calculateIngredientsHash(from: data2)
        logger.info("✅ Hash 2: \(hash2 ?? "nil")")
        
        // Hashes should be identical (sorted internally)
        logger.info("🔍 Comparing hashes...")
        #expect(hash1 == hash2, "Hashes should match regardless of ingredient order")
        #expect(hash1?.isEmpty == false, "Hash should not be empty")
        
        logger.info("✅ Test completed successfully")
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
        let hash1 = RecipeX.calculateIngredientsHash(from: data1)
        
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
        let hash2 = RecipeX.calculateIngredientsHash(from: data2)
        
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
        let hash3 = RecipeX.calculateIngredientsHash(from: data3)
        
        #expect(hash1 != hash3, "Hashes should differ when ingredient names change")
    }
    
    @Test("Recipe version increments on ingredient update")
    @MainActor func recipeVersionIncrement() async throws {
        logger.info("🧪 Starting recipeVersionIncrement test")
        let encoder = JSONEncoder()
        
        // Create a recipe
        logger.info("📝 Creating recipe")
        let ingredients = [
            IngredientSection(
                title: "Main",
                ingredients: [
                    Ingredient(quantity: "2", unit: "cups", name: "flour")
                ]
            )
        ]
        let instructions = [
            InstructionSection(steps: [
                InstructionStep(stepNumber: 1, text: "Mix ingredients")
            ])
        ]
        
        let recipe = RecipeX(
            title: "Test Recipe",
            ingredientSectionsData: try encoder.encode(ingredients),
            instructionSectionsData: try encoder.encode(instructions)
        )
        
        let initialVersion = recipe.currentVersion
        let initialHash = recipe.ingredientsHash
        
        logger.info("✅ Initial state - Version: \(initialVersion), Hash: \(initialHash ?? "nil")")
        
        #expect(initialVersion == 1, "Initial version should be 1")
        #expect(initialHash != nil, "Initial hash should be calculated")
        logger.info("✅ Initial state verified")
        
        // Update ingredients
        logger.info("📝 Creating new ingredients")
        let newIngredients = [
            IngredientSection(
                title: "Main",
                ingredients: [
                    Ingredient(quantity: "3", unit: "cups", name: "flour") // Changed quantity
                ]
            )
        ]
        let newData = try encoder.encode(newIngredients)
        
        logger.info("🔄 Updating recipe ingredients")
        recipe.updateIngredients(newData)
        
        let newVersion = recipe.currentVersion
        let newHash = recipe.ingredientsHash
        logger.info("✅ Updated state - Version: \(newVersion), Hash: \(newHash ?? "nil")")
        
        logger.info("🔍 Verifying version incremented: \(initialVersion) -> \(newVersion)")
        #expect(recipe.currentVersion == initialVersion + 1, "Version should increment after update")
        
        logger.info("🔍 Verifying hash changed: \(initialHash ?? "nil") -> \(newHash ?? "nil")")
        #expect(recipe.ingredientsHash != initialHash, "Hash should change with ingredients")
        
        logger.info("🔍 Verifying modification date is recent")
        #expect(recipe.modificationDate > Date(timeIntervalSinceNow: -1), "lastModified should be recent")
        
        logger.info("✅ Test completed successfully")
    }
    
    @Test("Cache detects ingredient changes via version")
    @MainActor func cacheDetectsVersionChange() async throws {
        logger.info("🧪 Starting cacheDetectsVersionChange test")
        let encoder = JSONEncoder()
        
        // Create recipe and cache
        logger.info("📝 Creating recipe")
        let ingredients = [
            IngredientSection(ingredients: [
                Ingredient(quantity: "2", unit: "cups", name: "flour")
            ])
        ]
        let instructions = [
            InstructionSection(steps: [InstructionStep(stepNumber: 1, text: "Mix")])
        ]
        
        let recipe = RecipeX(
            title: "Test Recipe",
            ingredientSectionsData: try encoder.encode(ingredients),
            instructionSectionsData: try encoder.encode(instructions)
        )
        logger.info("✅ Recipe created - Version: \(recipe.currentVersion), Hash: \(recipe.ingredientsHash ?? "nil")")
        
        // Create a mock cache entry
        logger.info("📝 Creating mock diabetic analysis")
        let mockAnalysis = DiabeticInfo(
            id: UUID(),
            recipeId: recipe.safeID,
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
        logger.info("✅ Mock analysis created and encoded")
        
        // Create cache
        logger.info("📝 Creating cached analysis")
        let cached = CachedDiabeticAnalysis(
            recipeId: recipe.safeID,
            analysisData: analysisData,
            cachedAt: Date(),
            recipeVersion: recipe.currentVersion,
            ingredientsHash: recipe.ingredientsHash ?? "",
            recipeLastModified: recipe.modificationDate
        )
        logger.info("✅ Cache created - Version: \(cached.recipeVersion), Hash: \(cached.ingredientsHash)")
        
        // Cache should be valid initially
        logger.info("🔍 Checking if cache is valid for unchanged recipe")
        let isInitiallyValid = cached.isValid(for: recipe)
        logger.info("   Result: \(isInitiallyValid ? "VALID ✅" : "INVALID ❌")")
        #expect(isInitiallyValid, "Cache should be valid for unchanged recipe")
        
        // Update recipe version
        logger.info("🔄 Updating recipe ingredients")
        let newIngredients = [
            IngredientSection(ingredients: [
                Ingredient(quantity: "3", unit: "cups", name: "flour")
            ])
        ]
        let newData = try encoder.encode(newIngredients)
        recipe.updateIngredients(newData)
        logger.info("✅ Recipe updated - New Version: \(recipe.currentVersion), New Hash: \(recipe.ingredientsHash ?? "nil")")
        
        // Cache should now be invalid
        logger.info("🔍 Checking if cache is invalid after ingredient change")
        let isStillValid = cached.isValid(for: recipe)
        logger.info("   Result: \(isStillValid ? "VALID ❌" : "INVALID ✅")")
        #expect(!isStillValid, "Cache should be invalid after ingredient change")
        
        logger.info("🔍 Checking if cache detects outdated ingredients")
        let isOutdated = cached.isIngredientsOutdated(recipe: recipe)
        logger.info("   Result: \(isOutdated ? "OUTDATED ✅" : "UP TO DATE ❌")")
        #expect(isOutdated, "Cache should detect outdated ingredients")
        
        logger.info("✅ Test completed successfully")
    }
    
    @Test("Cache detects ingredient changes via hash")
    @MainActor func cacheDetectsHashChange() async throws {
        let encoder = JSONEncoder()
        
        // Create recipe
        let ingredients = [
            IngredientSection(ingredients: [
                Ingredient(quantity: "2", unit: "cups", name: "flour")
            ])
        ]
        let instructions = [
            InstructionSection(steps: [InstructionStep(stepNumber: 1, text: "Mix")])
        ]
        
        let recipe = RecipeX(
            title: "Test Recipe",
            ingredientSectionsData: try encoder.encode(ingredients),
            instructionSectionsData: try encoder.encode(instructions)
        )
        
        // Create cache with current hash
        let mockAnalysis = DiabeticInfo(
            id: UUID(),
            recipeId: recipe.safeID,
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
            recipeId: recipe.safeID,
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
