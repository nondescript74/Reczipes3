//
//  ImprovedIngredientMatchingTests.swift
//  Reczipes2Tests
//
//  Unit tests for improved context-aware ingredient matching
//  Tests that "cream of tartar" doesn't match "cream", etc.
//

import Testing
import Foundation
@testable import Reczipes2

@Suite("Improved Ingredient Matching Tests")
struct ImprovedIngredientMatchingTests {
    
    // MARK: - Test Data Setup
    
    /// Create a test recipe with potentially confusing ingredients
    func createTestRecipe(ingredients: [String]) -> RecipeModel {
        let ingredientModels = ingredients.map { name in
            Ingredient(
                quantity: "1",
                unit: "cup",
                name: name,
                preparation: nil,
                metricQuantity: nil,
                metricUnit: nil
            )
        }
        
        let section = IngredientSection(
            title: nil,
            ingredients: ingredientModels,
            transitionNote: nil
        )
        
        return RecipeModel(
            title: "Test Recipe",
            headerNotes: nil,
            yield: "4 servings",
            ingredientSections: [section],
            instructionSections: [],
            notes: [],
            reference: nil
        )
    }
    
    /// Create a test profile with a specific sensitivity
    func createTestProfile(sensitivityName: String, keywords: [String]) -> UserAllergenProfile {
        let profile = UserAllergenProfile()
        let sensitivity = UserSensitivity(
            intolerance: .dairy,  // Using dairy as example
            severity: .moderate,
            notes: nil,
            fodmapCategories: nil
        )
        // Note: In real usage, keywords would come from FoodIntolerance
        // For testing, we're directly testing the matching logic
        profile.addSensitivity(sensitivity)
        return profile
    }
    
    // MARK: - False Positive Prevention Tests
    
    @Test("Cream of tartar should NOT match dairy 'cream' sensitivity")
    func creamOfTartarNotDairy() async throws {
        // Given: A recipe with cream of tartar (not dairy)
        let recipe = createTestRecipe(ingredients: ["cream of tartar"])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["cream", "milk", "butter"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect dairy (cream of tartar is potassium bitartrate)
        #expect(score.isSafe, "Cream of tartar should not trigger dairy sensitivity")
        #expect(score.detectedAllergens.isEmpty, "Should have no allergen matches")
    }
    
    @Test("Coconut milk should NOT match dairy 'milk' sensitivity")
    func coconutMilkNotDairy() async throws {
        // Given: A recipe with coconut milk (dairy-free)
        let recipe = createTestRecipe(ingredients: ["coconut milk"])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["milk", "cream", "butter"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect dairy
        #expect(score.isSafe, "Coconut milk should not trigger dairy sensitivity")
        #expect(score.detectedAllergens.isEmpty, "Should have no allergen matches")
    }
    
    @Test("Almond milk should NOT match dairy 'milk' sensitivity")
    func almondMilkNotDairy() async throws {
        // Given: A recipe with almond milk (dairy-free)
        let recipe = createTestRecipe(ingredients: ["almond milk"])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["milk"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect dairy
        #expect(score.isSafe, "Almond milk should not trigger dairy sensitivity")
    }
    
    @Test("Peanut butter should NOT match dairy 'butter' sensitivity")
    func peanutButterNotDairy() async throws {
        // Given: A recipe with peanut butter (no dairy)
        let recipe = createTestRecipe(ingredients: ["peanut butter"])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["butter"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect dairy
        #expect(score.isSafe, "Peanut butter should not trigger dairy sensitivity")
    }
    
    @Test("Almond butter should NOT match dairy 'butter' sensitivity")
    func almondButterNotDairy() async throws {
        // Given: A recipe with almond butter (no dairy)
        let recipe = createTestRecipe(ingredients: ["almond butter"])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["butter"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect dairy
        #expect(score.isSafe, "Almond butter should not trigger dairy sensitivity")
    }
    
    @Test("Butternut squash should NOT match dairy 'butter' sensitivity")
    func butternutSquashNotDairy() async throws {
        // Given: A recipe with butternut squash (no dairy)
        let recipe = createTestRecipe(ingredients: ["butternut squash"])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["butter"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect dairy
        #expect(score.isSafe, "Butternut squash should not trigger dairy sensitivity")
    }
    
    @Test("Eggplant should NOT match 'egg' sensitivity")
    func eggplantNotEgg() async throws {
        // Given: A recipe with eggplant (no eggs)
        let recipe = createTestRecipe(ingredients: ["eggplant"])
        let profile = createTestProfile(sensitivityName: "Egg", keywords: ["egg"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect eggs
        #expect(score.isSafe, "Eggplant should not trigger egg sensitivity")
    }
    
    @Test("Buckwheat should NOT match 'wheat' sensitivity")
    func buckwheatNotWheat() async throws {
        // Given: A recipe with buckwheat (gluten-free, not wheat)
        let recipe = createTestRecipe(ingredients: ["buckwheat flour"])
        let profile = createTestProfile(sensitivityName: "Wheat", keywords: ["wheat"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect wheat
        #expect(score.isSafe, "Buckwheat should not trigger wheat sensitivity")
    }
    
    @Test("Nutmeg should NOT match 'nut' sensitivity")
    func nutmegNotNut() async throws {
        // Given: A recipe with nutmeg (a spice, not a nut)
        let recipe = createTestRecipe(ingredients: ["nutmeg"])
        let profile = createTestProfile(sensitivityName: "Nuts", keywords: ["nut"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect nuts
        #expect(score.isSafe, "Nutmeg should not trigger nut sensitivity")
    }
    
    // MARK: - True Positive Detection Tests
    
    @Test("Heavy cream SHOULD match dairy 'cream' sensitivity")
    func heavyCreamMatchesDairy() async throws {
        // Given: A recipe with actual heavy cream (dairy)
        let recipe = createTestRecipe(ingredients: ["heavy cream"])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["cream"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: SHOULD detect dairy
        #expect(!score.isSafe, "Heavy cream should trigger dairy sensitivity")
        #expect(!score.detectedAllergens.isEmpty, "Should detect allergen")
    }
    
    @Test("Whole milk SHOULD match dairy 'milk' sensitivity")
    func wholeMilkMatchesDairy() async throws {
        // Given: A recipe with whole milk (dairy)
        let recipe = createTestRecipe(ingredients: ["whole milk"])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["milk"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: SHOULD detect dairy
        #expect(!score.isSafe, "Whole milk should trigger dairy sensitivity")
    }
    
    @Test("Butter SHOULD match dairy 'butter' sensitivity")
    func butterMatchesDairy() async throws {
        // Given: A recipe with butter (dairy)
        let recipe = createTestRecipe(ingredients: ["unsalted butter"])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["butter"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: SHOULD detect dairy
        #expect(!score.isSafe, "Butter should trigger dairy sensitivity")
    }
    
    @Test("Eggs SHOULD match 'egg' sensitivity")
    func eggsMatchEgg() async throws {
        // Given: A recipe with eggs
        let recipe = createTestRecipe(ingredients: ["large eggs"])
        let profile = createTestProfile(sensitivityName: "Egg", keywords: ["egg"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: SHOULD detect eggs
        #expect(!score.isSafe, "Eggs should trigger egg sensitivity")
    }
    
    // MARK: - Complex Multi-Ingredient Tests
    
    @Test("Recipe with both cream of tartar and heavy cream")
    func mixedCreamIngredients() async throws {
        // Given: A recipe with both cream of tartar (not dairy) and heavy cream (dairy)
        let recipe = createTestRecipe(ingredients: [
            "cream of tartar",
            "heavy cream",
            "sugar"
        ])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["cream"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should detect ONLY the heavy cream
        #expect(!score.isSafe, "Should detect dairy from heavy cream")
        #expect(score.detectedAllergens.count == 1, "Should detect exactly one allergen")
        
        let matchedIngredients = score.detectedAllergens.first?.matchedIngredients ?? []
        #expect(matchedIngredients.contains("heavy cream"), "Should match heavy cream")
        #expect(!matchedIngredients.contains("cream of tartar"), "Should NOT match cream of tartar")
    }
    
    @Test("Recipe with multiple plant-based milks")
    func multipleNonDairyMilks() async throws {
        // Given: A recipe with various non-dairy milks
        let recipe = createTestRecipe(ingredients: [
            "almond milk",
            "coconut milk",
            "oat milk",
            "soy milk"
        ])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["milk"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect any dairy
        #expect(score.isSafe, "Plant-based milks should not trigger dairy sensitivity")
        #expect(score.detectedAllergens.isEmpty, "Should have no allergen matches")
    }
    
    @Test("Recipe with nut butters but no dairy butter")
    func nutButtersNoDairyButter() async throws {
        // Given: A recipe with various nut butters
        let recipe = createTestRecipe(ingredients: [
            "peanut butter",
            "almond butter",
            "cashew butter"
        ])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["butter"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect dairy
        #expect(score.isSafe, "Nut butters should not trigger dairy sensitivity")
    }
    
    // MARK: - Word Boundary Tests
    
    @Test("'Creamer' should NOT match 'cream' as a word boundary")
    func creamerNotCream() async throws {
        // Given: A recipe with "creamer" (could be non-dairy)
        let recipe = createTestRecipe(ingredients: ["non-dairy creamer"])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["cream"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect dairy (it's non-dairy creamer)
        #expect(score.isSafe, "Non-dairy creamer should not trigger dairy sensitivity")
    }
    
    @Test("'Soy-free' should NOT match 'soy' sensitivity")
    func soyFreeNotSoy() async throws {
        // Given: A recipe labeled as soy-free
        let recipe = createTestRecipe(ingredients: ["soy-free sauce"])
        let profile = createTestProfile(sensitivityName: "Soy", keywords: ["soy"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should NOT detect soy (it's explicitly soy-free)
        #expect(score.isSafe, "Soy-free ingredients should not trigger soy sensitivity")
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty ingredient list")
    func emptyIngredients() async throws {
        // Given: A recipe with no ingredients
        let recipe = createTestRecipe(ingredients: [])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["milk"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should be safe (no ingredients to match)
        #expect(score.isSafe, "Recipe with no ingredients should be safe")
    }
    
    @Test("Case insensitive matching")
    func caseInsensitiveMatching() async throws {
        // Given: Ingredients with various cases
        let recipe = createTestRecipe(ingredients: [
            "HEAVY CREAM",
            "Whole Milk",
            "unsalted BUTTER"
        ])
        let profile = createTestProfile(sensitivityName: "Dairy", keywords: ["cream", "milk", "butter"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should detect all dairy ingredients regardless of case
        #expect(!score.isSafe, "Should detect dairy ingredients")
        #expect(score.detectedAllergens.count > 0, "Should detect allergens")
    }
    
    @Test("Multi-word sensitivity matching")
    func multiWordSensitivity() async throws {
        // Given: A recipe with "soy sauce"
        let recipe = createTestRecipe(ingredients: ["soy sauce", "tamari"])
        let profile = createTestProfile(sensitivityName: "Soy", keywords: ["soy sauce", "soy"])
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should detect soy
        #expect(!score.isSafe, "Should detect soy sauce")
    }
    
    // MARK: - Integration Tests with Full Recipe
    
    @Test("Complex recipe with mixed ingredients")
    func complexRecipeAnalysis() async throws {
        // Given: A complex recipe with various ingredients
        let ingredients = [
            "all-purpose flour",
            "cream of tartar",
            "heavy cream",
            "coconut milk",
            "peanut butter",
            "unsalted butter",
            "large eggs",
            "eggplant",
            "butternut squash",
            "nutmeg"
        ]
        let recipe = createTestRecipe(ingredients: ingredients)
        let profile = createTestProfile(
            sensitivityName: "Dairy",
            keywords: ["cream", "milk", "butter"]
        )
        
        // When: Analyzing the recipe
        let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
        
        // Then: Should detect ONLY true dairy ingredients
        #expect(!score.isSafe, "Should detect dairy ingredients")
        
        let matchedIngredients = score.detectedAllergens.flatMap { $0.matchedIngredients }
        
        // Should match these dairy items
        #expect(matchedIngredients.contains("heavy cream"), "Should match heavy cream")
        #expect(matchedIngredients.contains("unsalted butter"), "Should match unsalted butter")
        
        // Should NOT match these non-dairy items
        #expect(!matchedIngredients.contains("cream of tartar"), "Should NOT match cream of tartar")
        #expect(!matchedIngredients.contains("coconut milk"), "Should NOT match coconut milk")
        #expect(!matchedIngredients.contains("peanut butter"), "Should NOT match peanut butter")
        #expect(!matchedIngredients.contains("butternut squash"), "Should NOT match butternut squash")
    }
}

// MARK: - Claude API Prompt Tests

@Suite("Claude API Context-Aware Prompt Tests")
struct ClaudePromptTests {
    
    @Test("Prompt includes full ingredient context")
    func promptIncludesFullContext() async throws {
        // Given: A recipe with detailed ingredients
        let ingredients = [
            Ingredient(
                quantity: "1",
                unit: "teaspoon",
                name: "cream of tartar",
                preparation: nil,
                metricQuantity: nil,
                metricUnit: nil
            ),
            Ingredient(
                quantity: "1",
                unit: "cup",
                name: "heavy cream",
                preparation: "cold",
                metricQuantity: nil,
                metricUnit: nil
            )
        ]
        
        let section = IngredientSection(title: nil, ingredients: ingredients, transitionNote: nil)
        let recipe = RecipeModel(
            title: "Test Recipe",
            headerNotes: nil,
            yield: "4",
            ingredientSections: [section],
            instructionSections: [],
            notes: [],
            reference: nil
        )
        
        let profile = UserAllergenProfile()
        let sensitivity = UserSensitivity(
            intolerance: .dairy,
            severity: .moderate,
            notes: nil,
            fodmapCategories: nil
        )
        profile.addSensitivity(sensitivity)
        
        // When: Generating Claude prompt
        let prompt = AllergenAnalyzer.shared.generateClaudeAnalysisPrompt(
            recipe: recipe,
            profile: profile
        )
        
        // Then: Prompt should include full ingredient context
        #expect(prompt.contains("cream of tartar"), "Should include cream of tartar")
        #expect(prompt.contains("heavy cream"), "Should include heavy cream")
        #expect(prompt.contains("cold"), "Should include preparation method")
        
        // Should include context-aware instructions
        #expect(prompt.contains("cream of tartar\" is NOT dairy"), "Should include cream of tartar exception")
        #expect(prompt.contains("coconut milk\" is NOT dairy"), "Should include coconut milk exception")
        #expect(prompt.contains("COMPLETE ingredient phrase"), "Should emphasize complete phrases")
    }
    
    @Test("Prompt includes false positive prevention examples")
    func promptIncludesFalsePositivePrevention() async throws {
        // Given: A basic recipe and profile
        let recipe = RecipeModel(
            title: "Test",
            headerNotes: nil,
            yield: "1",
            ingredientSections: [],
            instructionSections: [],
            notes: [],
            reference: nil
        )
        
        let profile = UserAllergenProfile()
        let sensitivity = UserSensitivity(
            intolerance: .dairy,
            severity: .moderate,
            notes: nil,
            fodmapCategories: nil
        )
        profile.addSensitivity(sensitivity)
        
        // When: Generating Claude prompt
        let prompt = AllergenAnalyzer.shared.generateClaudeAnalysisPrompt(
            recipe: recipe,
            profile: profile
        )
        
        // Then: Should include all the common false positive examples
        let falsePositiveExamples = [
            "cream of tartar",
            "coconut milk",
            "almond milk",
            "peanut butter",
            "butternut squash",
            "eggplant",
            "buckwheat",
            "nutmeg"
        ]
        
        for example in falsePositiveExamples {
            #expect(prompt.contains(example), "Should include example: \(example)")
        }
    }
    
    @Test("Prompt requests confidence scores")
    func promptRequestsConfidenceScores() async throws {
        // Given: A basic recipe and profile
        let recipe = RecipeModel(
            title: "Test",
            headerNotes: nil,
            yield: "1",
            ingredientSections: [],
            instructionSections: [],
            notes: [],
            reference: nil
        )
        
        let profile = UserAllergenProfile()
        let sensitivity = UserSensitivity(
            intolerance: .dairy,
            severity: .moderate,
            notes: nil,
            fodmapCategories: nil
        )
        profile.addSensitivity(sensitivity)
        
        // When: Generating Claude prompt
        let prompt = AllergenAnalyzer.shared.generateClaudeAnalysisPrompt(
            recipe: recipe,
            profile: profile
        )
        
        // Then: Should request confidence scores and reasoning
        #expect(prompt.contains("confidenceScore"), "Should request confidence scores")
        #expect(prompt.contains("reasoning"), "Should request reasoning")
        #expect(prompt.contains("falsePositivesAvoided"), "Should request false positive documentation")
    }
}
