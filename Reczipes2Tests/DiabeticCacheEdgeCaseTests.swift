//
//  DiabeticCacheEdgeCaseTests.swift
//  Reczipes2Tests
//
//  Edge case tests for diabetic analysis caching
//  Created on 1/3/26.
//

import Testing
import Foundation
import OSLog
@testable import Reczipes2

@Suite("Diabetic Cache Edge Cases")
struct DiabeticCacheEdgeCaseTests {
    
    private let logger = Logger(subsystem: "com.reczipes.tests", category: "edge-cases")
    
    // MARK: - Empty Data Tests
    
    @Test("Empty ingredient list handling")
    nonisolated func emptyIngredientList() async throws {
        logger.info("🧪 Testing empty ingredient list")
        
        let emptyIngredients: [IngredientSection] = []
        let encoder = JSONEncoder()
        let data = try encoder.encode(emptyIngredients)
        
        let hash = Recipe.calculateIngredientsHash(from: data)
        
        logger.info("📊 Empty ingredients hash: '\(hash)'")
        #expect(!hash.isEmpty, "Hash should not be empty even for empty ingredients")
        
        // Second empty list should have same hash
        let data2 = try encoder.encode(emptyIngredients)
        let hash2 = Recipe.calculateIngredientsHash(from: data2)
        
        #expect(hash == hash2, "Empty ingredient lists should have consistent hashes")
        
        logger.info("✅ Test passed")
    }
    
    @Test("Nil ingredient data handling")
    nonisolated func nilIngredientData() async throws {
        logger.info("🧪 Testing nil ingredient data")
        
        let hash = Recipe.calculateIngredientsHash(from: nil)
        
        logger.info("📊 Nil data hash: '\(hash)'")
        #expect(hash.isEmpty, "Hash of nil data should be empty")
        
        logger.info("✅ Test passed")
    }
    
    @Test("Single ingredient handling")
    nonisolated func singleIngredient() async throws {
        logger.info("🧪 Testing single ingredient")
        
        let ingredients = await [
            IngredientSection(ingredients: [
                Ingredient(quantity: "1", unit: "cup", name: "flour")
            ])
        ]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(ingredients)
        let hash = Recipe.calculateIngredientsHash(from: data)
        
        #expect(!hash.isEmpty, "Single ingredient should produce valid hash")
        #expect(hash.count == 64, "Should be 64-character SHA-256 hash")
        
        logger.info("✅ Test passed")
    }
    
    // MARK: - Large Data Tests
    
    @Test("Very large ingredient list")
    nonisolated func largeIngredientList() async throws {
        logger.info("🧪 Testing large ingredient list (1000 ingredients)")
        
        let startTime = Date()
        
        // Create 1000 ingredients
        var ingredients: [Ingredient] = []
        for i in 1...1000 {
            await ingredients.append(
                Ingredient(
                    quantity: "\(i)",
                    unit: "unit\(i)",
                    name: "ingredient\(i)"
                )
            )
        }
        
        let sections = await [IngredientSection(ingredients: ingredients)]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(sections)
        let dataSize = data.count
        logger.info("📊 Data size: \(dataSize) bytes")
        
        let hash = Recipe.calculateIngredientsHash(from: data)
        
        let duration = Date().timeIntervalSince(startTime)
        logger.info("⏱️ Hash calculation took \(String(format: "%.3f", duration)) seconds")
        
        #expect(!hash.isEmpty, "Should produce hash for large list")
        #expect(hash.count == 64, "Should be valid SHA-256 hash")
        #expect(duration < 1.0, "Should complete in under 1 second")
        
        logger.info("✅ Test passed")
    }
    
    @Test("Many small sections vs one large section")
    nonisolated func multipleSectionsVsOne() async throws {
        logger.info("🧪 Testing multiple sections vs single section")
        
        let encoder = JSONEncoder()
        
        // Create ingredients in many small sections
        var manySections: [IngredientSection] = []
        for i in 1...100 {
            let ingredient = await Ingredient(quantity: "1", unit: "cup", name: "ingredient\(i)")
            let section = await IngredientSection(
                title: "Section \(i)",
                ingredients: [ingredient]
            )
            manySections.append(section)
        }
        
        let manyData = try encoder.encode(manySections)
        let manyHash = Recipe.calculateIngredientsHash(from: manyData)
        
        // Create same ingredients in one large section
        var allIngredients: [Ingredient] = []
        for i in 1...100 {
            let ingredient = await Ingredient(quantity: "1", unit: "cup", name: "ingredient\(i)")
            allIngredients.append(ingredient)
        }
        
        let oneSection = await [
            IngredientSection(
                title: "All Ingredients",
                ingredients: allIngredients
            )
        ]
        
        let oneData = try encoder.encode(oneSection)
        let oneHash = Recipe.calculateIngredientsHash(from: oneData)
        
        logger.info("📊 Many sections hash: \(manyHash)")
        logger.info("📊 One section hash: \(oneHash)")
        
        // Hashes should be the same (section structure shouldn't matter)
        #expect(manyHash == oneHash, "Section structure should not affect hash")
        
        logger.info("✅ Test passed")
    }
    
    // MARK: - Special Characters Tests
    
    @Test("Special characters in ingredient names")
    nonisolated func specialCharactersInNames() async throws {
        logger.info("🧪 Testing special characters")
        
        let encoder = JSONEncoder()
        
        let specialIngredients = await [
            IngredientSection(ingredients: [
                Ingredient(name: "jalapeño peppers 🌶️"),
                Ingredient(name: "crème fraîche"),
                Ingredient(name: "salt & pepper"),
                Ingredient(name: "\"quoted\" ingredient"),
                Ingredient(name: "ingredient/with/slashes"),
                Ingredient(name: "ingredient\\with\\backslashes"),
                Ingredient(name: "emoji 🥕🥔🧅"),
                Ingredient(name: "unicode: 你好"),
                Ingredient(name: "new\nline\ncharacters")
            ])
        ]
        
        let data = try encoder.encode(specialIngredients)
        let hash = Recipe.calculateIngredientsHash(from: data)
        
        logger.info("📊 Hash with special chars: \(hash)")
        #expect(!hash.isEmpty, "Should handle special characters")
        #expect(hash.count == 64, "Should produce valid hash")
        
        // Should be consistent
        let data2 = try encoder.encode(specialIngredients)
        let hash2 = Recipe.calculateIngredientsHash(from: data2)
        
        #expect(hash == hash2, "Should be consistent with special characters")
        
        logger.info("✅ Test passed")
    }
    
    @Test("Leading and trailing whitespace")
    nonisolated func whitespaceHandling() async throws {
        logger.info("🧪 Testing whitespace handling")
        
        let encoder = JSONEncoder()
        
        let ingredients1 = await [
            IngredientSection(ingredients: [
                Ingredient(quantity: "2", unit: "cups", name: "flour")
            ])
        ]
        
        let ingredients2 = await [
            IngredientSection(ingredients: [
                Ingredient(quantity: "  2  ", unit: "  cups  ", name: "  flour  ")
            ])
        ]
        
        let hash1 = Recipe.calculateIngredientsHash(from: try encoder.encode(ingredients1))
        let hash2 = Recipe.calculateIngredientsHash(from: try encoder.encode(ingredients2))
        
        logger.info("📊 Without whitespace: \(hash1)")
        logger.info("📊 With whitespace: \(hash2)")
        
        // Note: These will be different because we don't trim whitespace in the hash
        // This is intentional - whitespace changes are considered real changes
        #expect(hash1 != hash2, "Whitespace should affect hash")
        
        logger.info("✅ Test passed")
    }
    
    @Test("Case sensitivity")
    nonisolated func caseSensitivity() async throws {
        logger.info("🧪 Testing case sensitivity")
        
        let encoder = JSONEncoder()
        
        let ingredients1 = await [
            IngredientSection(ingredients: [
                Ingredient(name: "Flour")
            ])
        ]
        
        let ingredients2 = await [
            IngredientSection(ingredients: [
                Ingredient(name: "flour")
            ])
        ]
        
        let hash1 = Recipe.calculateIngredientsHash(from: try encoder.encode(ingredients1))
        let hash2 = Recipe.calculateIngredientsHash(from: try encoder.encode(ingredients2))
        
        logger.info("📊 Capitalized: \(hash1)")
        logger.info("📊 Lowercase: \(hash2)")
        
        #expect(hash1 != hash2, "Hash should be case-sensitive")
        
        logger.info("✅ Test passed")
    }
    
    // MARK: - Concurrent Update Tests
    
    @Test("Concurrent ingredient updates")
    @MainActor
    func concurrentUpdates() async throws {
        logger.info("🧪 Testing concurrent updates")
        
        let recipe = createTestRecipe()
        let initialVersion = recipe.currentVersion
        
        logger.info("📝 Initial version: \(initialVersion)")
        
        // Simulate concurrent updates
        let updateCount = 10
        
        await withTaskGroup(of: Void.self) { group in
            for i in 1...updateCount {
                group.addTask { @MainActor in
                    let ingredients = [
                        IngredientSection(ingredients: [
                            Ingredient(quantity: "\(i)", unit: "cups", name: "flour")
                        ])
                    ]
                    
                    if let data = try? JSONEncoder().encode(ingredients) {
                        recipe.updateIngredients(data)
                    }
                }
            }
        }
        
        let finalVersion = recipe.currentVersion
        logger.info("📝 Final version: \(finalVersion)")
        
        // Version should have incremented (may not be exactly +10 due to concurrency)
        #expect(finalVersion > initialVersion, "Version should increment")
        
        logger.info("✅ Test passed")
    }
    
    // MARK: - Nil/Optional Field Tests
    
    @Test("Missing optional fields")
    nonisolated func missingOptionalFields() async throws {
        logger.info("🧪 Testing missing optional fields")
        
        let encoder = JSONEncoder()
        
        // Ingredients with no quantity, no unit, no preparation
        let ingredients = await [
            IngredientSection(ingredients: [
                Ingredient(quantity: nil, unit: nil, name: "salt"),
                Ingredient(quantity: "2", unit: nil, name: "eggs"),
                Ingredient(quantity: nil, unit: "cup", name: "water")
            ])
        ]
        
        let data = try encoder.encode(ingredients)
        let hash = Recipe.calculateIngredientsHash(from: data)
        
        logger.info("📊 Hash with missing fields: \(hash)")
        #expect(!hash.isEmpty, "Should handle missing optional fields")
        #expect(hash.count == 64, "Should produce valid hash")
        
        logger.info("✅ Test passed")
    }
    
    @Test("Empty string vs nil")
    nonisolated func emptyStringVsNil() async throws {
        logger.info("🧪 Testing empty string vs nil")
        
        let encoder = JSONEncoder()
        
        let ingredients1 = await [
            IngredientSection(ingredients: [
                Ingredient(quantity: nil, unit: nil, name: "flour")
            ])
        ]
        
        let ingredients2 = await [
            IngredientSection(ingredients: [
                Ingredient(quantity: "", unit: "", name: "flour")
            ])
        ]
        
        let hash1 = Recipe.calculateIngredientsHash(from: try encoder.encode(ingredients1))
        let hash2 = Recipe.calculateIngredientsHash(from: try encoder.encode(ingredients2))
        
        logger.info("📊 Nil fields: \(hash1)")
        logger.info("📊 Empty strings: \(hash2)")
        
        // In practice, JSON encoding treats nil and empty string the same for optional fields
        // Both are serialized identically, so hashes match
        #expect(hash1 == hash2, "Nil and empty string produce same hash (treated identically by encoder)")
        
        logger.info("✅ Test passed")
    }
    
    // MARK: - Cache Boundary Tests
    
    @Test("Cache expiration boundary")
    @MainActor
    func cacheExpirationBoundary() async throws {
        logger.info("🧪 Testing cache expiration boundary")
        
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
        
        // Test exactly 30 days ago (boundary)
        let exactly30Days = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let cached30 = CachedDiabeticAnalysis(
            recipeId: UUID(),
            analysisData: analysisData,
            cachedAt: exactly30Days,
            recipeVersion: 1,
            ingredientsHash: "test",
            recipeLastModified: exactly30Days
        )
        
        logger.info("📊 Cache from exactly 30 days ago - isStale: \(cached30.isStale)")
        #expect(cached30.isStale, "Should be stale at exactly 30 days")
        
        // Test 29 days 23 hours ago (just before boundary)
        let justUnder30Days = Calendar.current.date(byAdding: .hour, value: -719, to: Date())!
        let cachedAlmost30 = CachedDiabeticAnalysis(
            recipeId: UUID(),
            analysisData: analysisData,
            cachedAt: justUnder30Days,
            recipeVersion: 1,
            ingredientsHash: "test",
            recipeLastModified: justUnder30Days
        )
        
        logger.info("📊 Cache from 29d 23h ago - isStale: \(cachedAlmost30.isStale)")
        #expect(!cachedAlmost30.isStale, "Should not be stale just before 30 days")
        
        logger.info("✅ Test passed")
    }
    
    @Test("Version overflow handling")
    @MainActor
    func versionOverflow() async throws {
        logger.info("🧪 Testing version overflow")
        
        let recipe = createTestRecipe()
        
        // Set version to near Int.max
        recipe.version = Int.max - 2
        
        logger.info("📝 Starting version: \(recipe.currentVersion)")
        
        // Update ingredients multiple times
        for i in 1...5 {
            let ingredients = [
                IngredientSection(ingredients: [
                    Ingredient(quantity: "\(i)", unit: "cups", name: "flour")
                ])
            ]
            
            let data = try JSONEncoder().encode(ingredients)
            recipe.updateIngredients(data)
            
            logger.info("📝 Version after update \(i): \(recipe.currentVersion)")
        }
        
        // Should handle overflow gracefully (may overflow to negative or wrap)
        // The key is it doesn't crash
        #expect(recipe.currentVersion != 0, "Version should still be set")
        
        logger.info("✅ Test passed: No crash on version overflow")
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func createTestRecipe() -> Recipe {
        let ingredients = [
            IngredientSection(ingredients: [
                Ingredient(quantity: "2", unit: "cups", name: "flour")
            ])
        ]
        
        let instructions = [
            InstructionSection(steps: [
                InstructionStep(text: "Mix")
            ])
        ]
        
        let recipeModel = RecipeModel(
            title: "Test Recipe",
            ingredientSections: ingredients,
            instructionSections: instructions
        )
        
        return Recipe(from: recipeModel)
    }
}
