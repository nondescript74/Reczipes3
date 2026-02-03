//
//  FODMAPSubstitutionTests.swift
//  Reczipes2Tests
//
//  Tests for FODMAP substitution functionality
//  Created on 12/20/25.
//

import Testing
import Foundation
@testable import Reczipes2

@Suite("FODMAP Substitution Tests", .serialized)
struct FODMAPSubstitutionTests {
    
    // MARK: - Database Tests
    
    @Test("Database has substitutions for common ingredients")
    @MainActor
    func testDatabaseHasCommonSubstitutions() {
        let db = FODMAPSubstitutionDatabase.shared
        
        // Test high FODMAP ingredients
        let highFODMAPs = ["onion", "garlic", "milk", "honey", "apple", "mushroom"]
        
        for ingredient in highFODMAPs {
            let substitution = db.getSubstitutions(for: ingredient)
            #expect(substitution != nil, "Should have substitution for \(ingredient)")
            #expect(!substitution!.substitutes.isEmpty, "\(ingredient) should have at least one substitute")
        }
    }
    
    @Test("Database returns nil for low FODMAP ingredients")
    @MainActor
    func testDatabaseReturnsNilForLowFODMAP() {
        let db = FODMAPSubstitutionDatabase.shared
        
        // Test low FODMAP ingredients
        let lowFODMAPs = ["rice", "chicken", "carrot", "spinach", "tomato"]
        
        for ingredient in lowFODMAPs {
            let substitution = db.getSubstitutions(for: ingredient)
            #expect(substitution == nil, "\(ingredient) should not have substitution (it's low FODMAP)")
        }
    }
    
    @Test("All substitutions have valid data")
    @MainActor
    func testAllSubstitutionsHaveValidData() {
        let db = FODMAPSubstitutionDatabase.shared
        let allSubs = db.getAllSubstitutions()
        
        #expect(allSubs.count >= 20, "Should have substantial database")
        
        for sub in allSubs {
            // Check required fields
            #expect(!sub.originalIngredient.isEmpty, "Original ingredient should not be empty")
            #expect(!sub.fodmapCategories.isEmpty, "Should have at least one FODMAP category")
            #expect(!sub.substitutes.isEmpty, "Should have at least one substitute")
            #expect(!sub.explanation.isEmpty, "Should have explanation")
            
            // Check substitutes
            for substitute in sub.substitutes {
                #expect(!substitute.name.isEmpty, "Substitute name should not be empty")
            }
        }
    }
    
    @Test("Ingredient lookup is case-insensitive")
    @MainActor
    func testCaseInsensitiveLookup() {
        let db = FODMAPSubstitutionDatabase.shared
        
        let lower = db.getSubstitutions(for: "onion")
        let upper = db.getSubstitutions(for: "ONION")
        let mixed = db.getSubstitutions(for: "Onion")
        
        #expect(lower != nil)
        #expect(upper != nil)
        #expect(mixed != nil)
        #expect(lower?.originalIngredient == upper?.originalIngredient)
        #expect(lower?.originalIngredient == mixed?.originalIngredient)
    }
    
    @Test("Ingredient lookup handles variations")
    @MainActor
    func testIngredientVariations() {
        let db = FODMAPSubstitutionDatabase.shared
        
        // Should match "onion" for variations
        #expect(db.getSubstitutions(for: "red onion") != nil)
        #expect(db.getSubstitutions(for: "yellow onions") != nil)
        #expect(db.getSubstitutions(for: "chopped onion") != nil)
        
        // Should match "garlic" for variations
        #expect(db.getSubstitutions(for: "garlic cloves") != nil)
        #expect(db.getSubstitutions(for: "minced garlic") != nil)
    }
    
    // MARK: - Recipe Analysis Tests
    
    @Test("Recipe with no high FODMAP ingredients")
    @MainActor
    func testLowFODMAPRecipe() {
        let ingredientSections = [
            IngredientSection(
                ingredients: [
                    Ingredient(quantity: "1", unit: "cup", name: "rice"),
                    Ingredient(quantity: "2", unit: "cups", name: "bok choy"),
                    Ingredient(quantity: "100", unit: "g", name: "chicken"),
                    Ingredient(quantity: "1", unit: "tbsp", name: "soy sauce")
                ]
            )
        ]
        
        let recipe = RecipeX(
            title: "Low FODMAP Stir Fry",
            ingredientSectionsData: try? JSONEncoder().encode(ingredientSections),
            instructionSectionsData: try? JSONEncoder().encode([InstructionSection]())
        )
        
        let db = FODMAPSubstitutionDatabase.shared
        let analysis = db.analyzeRecipe(recipe)
        
        #expect(!analysis.hasSubstitutions, "Should have no substitutions")
        #expect(analysis.substitutions.isEmpty, "Substitutions array should be empty")
        #expect(analysis.isSafeWithoutSubstitutions, "Recipe should be safe")
    }
    
    @Test("Recipe with high FODMAP ingredients")
    @MainActor
    func testHighFODMAPRecipe() {
        let ingredientSections = [
            IngredientSection(
                ingredients: [
                    Ingredient(quantity: "1", unit: "medium", name: "onion"),
                    Ingredient(quantity: "3", unit: "cloves", name: "garlic"),
                    Ingredient(quantity: "1", unit: "cup", name: "mushrooms"),
                    Ingredient(quantity: "1", unit: "cup", name: "milk")
                ]
            )
        ]
        
        let recipe = RecipeX(
            title: "Pasta with Mushroom Sauce",
            ingredientSectionsData: try? JSONEncoder().encode(ingredientSections),
            instructionSectionsData: try? JSONEncoder().encode([InstructionSection]())
        )
        
        let db = FODMAPSubstitutionDatabase.shared
        let analysis = db.analyzeRecipe(recipe)
        
        #expect(analysis.hasSubstitutions, "Should have substitutions")
        #expect(analysis.substitutions.count == 4, "Should detect 4 high FODMAP ingredients")
        #expect(!analysis.isSafeWithoutSubstitutions, "Recipe should not be safe without subs")
    }
    
    @Test("Recipe analysis includes all detected ingredients")
    @MainActor
    func testAnalysisCompleteness() {
        let ingredientSections = [
            IngredientSection(
                title: "Main",
                ingredients: [
                    Ingredient(quantity: "1", unit: "medium", name: "onion"),
                    Ingredient(quantity: "1", unit: "cup", name: "rice")
                ]
            ),
            IngredientSection(
                title: "Sauce",
                ingredients: [
                    Ingredient(quantity: "2", unit: "cloves", name: "garlic"),
                    Ingredient(quantity: "1", unit: "cup", name: "tomatoes")
                ]
            )
        ]
        
        let recipe = RecipeX(
            title: "Test Recipe",
            ingredientSectionsData: try? JSONEncoder().encode(ingredientSections),
            instructionSectionsData: try? JSONEncoder().encode([InstructionSection]())
        )
        
        let db = FODMAPSubstitutionDatabase.shared
        let analysis = db.analyzeRecipe(recipe)
        
        // Should detect onion and garlic (2 high FODMAP)
        #expect(analysis.substitutions.count == 2)
        
        // Check section titles are preserved
        let onionSub = analysis.substitutions.first { $0.originalIngredient.name == "onion" }
        #expect(onionSub?.sectionTitle == "Main")
        
        let garlicSub = analysis.substitutions.first { $0.originalIngredient.name == "garlic" }
        #expect(garlicSub?.sectionTitle == "Sauce")
    }
    
    // MARK: - Substitution Model Tests
    
    @Test("Substitute confidence levels are valid")
    @MainActor
    func testSubstituteConfidenceLevels() {
        let high = SubstituteOption.SubstituteConfidence.high
        let medium = SubstituteOption.SubstituteConfidence.medium
        let low = SubstituteOption.SubstituteConfidence.low
        
        #expect(high.rawValue == "Recommended")
        #expect(medium.rawValue == "Good Alternative")
        #expect(low.rawValue == "Limited Option")
        
        #expect(high.color == "green")
        #expect(medium.color == "orange")
        #expect(low.color == "yellow")
    }
    
    @Test("FODMAP categories have correct properties")
    @MainActor
    func testFODMAPCategories() {
        let oligo = FODMAPCategory.oligosaccharides
        let di = FODMAPCategory.disaccharides
        let mono = FODMAPCategory.monosaccharides
        let poly = FODMAPCategory.polyols
        
        // Check icons are not empty
        #expect(!oligo.icon.isEmpty)
        #expect(!di.icon.isEmpty)
        #expect(!mono.icon.isEmpty)
        #expect(!poly.icon.isEmpty)
        
        // Check descriptions
        #expect(!oligo.description.isEmpty)
        #expect(!di.description.isEmpty)
        #expect(!mono.description.isEmpty)
        #expect(!poly.description.isEmpty)
        
        // Check examples
        #expect(!oligo.examples.isEmpty)
        #expect(!di.examples.isEmpty)
        #expect(!mono.examples.isEmpty)
        #expect(!poly.examples.isEmpty)
    }
    
    // MARK: - Settings Tests
    
    @Test("FODMAP settings have default values")
    @MainActor
    func testSettingsDefaults() {
        let settings = UserFODMAPSettings.shared
        
        // Default should be disabled
        #expect(settings.isFODMAPEnabled == false, "FODMAP should be disabled by default")
        #expect(settings.showInlineIndicators == true, "Inline indicators default to on")
        #expect(settings.autoExpandSubstitutions == false, "Auto-expand default to off")
    }
    
    // MARK: - Real World Recipe Tests
    
    @Test("Real world recipe: Onion soup")
    @MainActor
    func testOnionSoup() {
        let ingredientSections = [
            IngredientSection(
                ingredients: [
                    Ingredient(quantity: "4", unit: "large", name: "onions, sliced"),
                    Ingredient(quantity: "4", unit: "cloves", name: "garlic, minced"),
                    Ingredient(quantity: "6", unit: "cups", name: "beef broth"),
                    Ingredient(quantity: "1", unit: "cup", name: "gruyere cheese, shredded")
                ]
            )
        ]
        
        let recipe = RecipeX(
            title: "French Onion Soup",
            ingredientSectionsData: try? JSONEncoder().encode(ingredientSections),
            instructionSectionsData: try? JSONEncoder().encode([InstructionSection]())
        )
        
        let analysis = FODMAPSubstitutionDatabase.shared.analyzeRecipe(recipe)
        
        #expect(analysis.hasSubstitutions)
        #expect(analysis.substitutions.count >= 2, "Should detect onions and garlic")
        
        // Check onion substitution exists
        let onionSub = analysis.substitutions.first { $0.substitution.originalIngredient == "onion" }
        #expect(onionSub != nil)
        #expect(onionSub!.substitution.substitutes.count >= 3, "Onion should have multiple substitutes")
    }
    
    @Test("Real world recipe: Mushroom risotto")
    @MainActor
    func testMushroomRisotto() {
        let ingredientSections = [
            IngredientSection(
                ingredients: [
                    Ingredient(quantity: "2", unit: "cups", name: "arborio rice"),
                    Ingredient(quantity: "2", unit: "cups", name: "mushrooms, sliced"),
                    Ingredient(quantity: "1", unit: "medium", name: "onion, diced"),
                    Ingredient(quantity: "1", unit: "cup", name: "white wine"),
                    Ingredient(quantity: "½", unit: "cup", name: "parmesan cheese")
                ]
            )
        ]
        
        let recipe = RecipeX(
            title: "Mushroom Risotto",
            ingredientSectionsData: try? JSONEncoder().encode(ingredientSections),
            instructionSectionsData: try? JSONEncoder().encode([InstructionSection]())
        )
        
        let analysis = FODMAPSubstitutionDatabase.shared.analyzeRecipe(recipe)
        
        #expect(analysis.hasSubstitutions)
        
        // Check mushroom substitution
        let mushroomSub = analysis.substitutions.first { 
            $0.substitution.originalIngredient == "mushroom" 
        }
        #expect(mushroomSub != nil, "Should detect mushrooms")
        #expect(mushroomSub!.substitution.fodmapCategories.contains(.polyols))
    }
    
    @Test("Real world recipe: Smoothie with honey and apple")
    @MainActor
    func testFruitSmoothie() {
        let ingredientSections = [
            IngredientSection(
                ingredients: [
                    Ingredient(quantity: "1", unit: "large", name: "apple, cored"),
                    Ingredient(quantity: "1", unit: "cup", name: "milk"),
                    Ingredient(quantity: "2", unit: "tbsp", name: "honey"),
                    Ingredient(quantity: "½", unit: "cup", name: "yogurt")
                ]
            )
        ]
        
        let recipe = RecipeX(
            title: "Apple Smoothie",
            ingredientSectionsData: try? JSONEncoder().encode(ingredientSections),
            instructionSectionsData: try? JSONEncoder().encode([InstructionSection]())
        )
        
        let analysis = FODMAPSubstitutionDatabase.shared.analyzeRecipe(recipe)
        
        #expect(analysis.substitutions.count >= 3, "Should detect apple, milk, honey, yogurt")
        
        // Check honey substitution
        let honeySub = analysis.substitutions.first { $0.substitution.originalIngredient == "honey" }
        #expect(honeySub != nil)
        
        // Check it has maple syrup as substitute
        let hasMaple = honeySub!.substitution.substitutes.contains { 
            $0.name.lowercased().contains("maple") 
        }
        #expect(hasMaple, "Honey should have maple syrup substitute")
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Empty recipe")
    @MainActor
    func testEmptyRecipe() {
        let recipe = RecipeX(
            title: "Empty",
            ingredientSectionsData: try? JSONEncoder().encode([IngredientSection]()),
            instructionSectionsData: try? JSONEncoder().encode([InstructionSection]())
        )
        
        let analysis = FODMAPSubstitutionDatabase.shared.analyzeRecipe(recipe)
        
        #expect(!analysis.hasSubstitutions)
        #expect(analysis.substitutions.isEmpty)
        #expect(analysis.isSafeWithoutSubstitutions)
    }
    
    @Test("Recipe with only section titles, no ingredients")
    @MainActor
    func testRecipeWithEmptySections() {
        let ingredientSections = [
            IngredientSection(title: "Section 1", ingredients: []),
            IngredientSection(title: "Section 2", ingredients: [])
        ]
        
        let recipe = RecipeX(
            title: "Test",
            ingredientSectionsData: try? JSONEncoder().encode(ingredientSections),
            instructionSectionsData: try? JSONEncoder().encode([InstructionSection]())
        )
        
        let analysis = FODMAPSubstitutionDatabase.shared.analyzeRecipe(recipe)
        
        #expect(!analysis.hasSubstitutions)
        #expect(analysis.substitutions.isEmpty)
    }
    
    @Test("Ingredient with preparation note")
    @MainActor
    func testIngredientWithPreparation() {
        let ingredientSections = [
            IngredientSection(
                ingredients: [
                    Ingredient(
                        quantity: "1",
                        unit: "medium",
                        name: "onion",
                        preparation: "finely diced"
                    )
                ]
            )
        ]
        
        let recipe = RecipeX(
            title: "Test",
            ingredientSectionsData: try? JSONEncoder().encode(ingredientSections),
            instructionSectionsData: try? JSONEncoder().encode([InstructionSection]())
        )
        
        let analysis = FODMAPSubstitutionDatabase.shared.analyzeRecipe(recipe)
        
        #expect(analysis.hasSubstitutions)
        #expect(analysis.substitutions.count == 1)
        
        // Should still detect onion despite preparation note
        let sub = analysis.substitutions.first
        #expect(sub?.originalIngredient.name == "onion")
        #expect(sub?.originalIngredient.preparation == "finely diced")
    }
    
    // MARK: - Performance Tests
    
    @Test("Database lookup is fast")
    @MainActor
    func testLookupPerformance() async {
        let db = FODMAPSubstitutionDatabase.shared
        let startTime = Date()
        
        // Perform 100 lookups
        for _ in 0..<100 {
            _ = db.getSubstitutions(for: "onion")
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 0.1, "100 lookups should complete in under 100ms")
    }
    
    @Test("Recipe analysis is fast")
    @MainActor
    func testAnalysisPerformance() async {
        let ingredientSections = [
            IngredientSection(
                ingredients: (0..<50).map { i in
                    Ingredient(
                        quantity: "1",
                        unit: "cup",
                        name: i % 2 == 0 ? "rice" : "onion"
                    )
                }
            )
        ]
        
        let recipe = RecipeX(
            title: "Large Recipe",
            ingredientSectionsData: try? JSONEncoder().encode(ingredientSections),
            instructionSectionsData: try? JSONEncoder().encode([InstructionSection]())
        )
        
        let db = FODMAPSubstitutionDatabase.shared
        let startTime = Date()
        
        _ = db.analyzeRecipe(recipe)
        
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 0.05, "Analyzing 50 ingredients should complete in under 50ms")
    }
}

// MARK: - Integration Tests

@Suite("FODMAP Integration Tests")
struct FODMAPIntegrationTests {
    
    @Test("Settings persistence")
    @MainActor
    func testSettingsPersistence() {
        let settings = UserFODMAPSettings.shared
        
        // Enable and check
        settings.isFODMAPEnabled = true
        #expect(settings.isFODMAPEnabled == true)
        
        // Disable and check
        settings.isFODMAPEnabled = false
        #expect(settings.isFODMAPEnabled == false)
    }
    
    @Test("Category breakdown includes all categories")
    @MainActor
    func testCategoryBreakdown() {
        let ingredientSections = [
            IngredientSection(
                ingredients: [
                    Ingredient(name: "onion"),      // Oligosaccharides
                    Ingredient(name: "milk"),       // Disaccharides
                    Ingredient(name: "honey"),      // Monosaccharides
                    Ingredient(name: "mushroom")    // Polyols
                ]
            )
        ]
        
        let recipe = RecipeX(
            title: "Multi-FODMAP Recipe",
            ingredientSectionsData: try? JSONEncoder().encode(ingredientSections),
            instructionSectionsData: try? JSONEncoder().encode([InstructionSection]())
        )
        
        let analysis = FODMAPSubstitutionDatabase.shared.analyzeRecipe(recipe)
        
        // Should have substitutions for all 4 categories
        var categories: Set<FODMAPCategory> = []
        for sub in analysis.substitutions {
            categories.formUnion(sub.substitution.fodmapCategories)
        }
        
        #expect(categories.count >= 3, "Should detect multiple FODMAP categories")
    }
}
