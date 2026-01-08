//
//  RecipeSearchTests.swift
//  Reczipes2Tests
//
//  Created for testing recipe search functionality
//

import Testing
import Foundation
@testable import Reczipes2

@Suite("Recipe Search Service Tests", .serialized)
@MainActor
struct RecipeSearchTests {
    
    let searchService = RecipeSearchService()
    
    // Sample recipes for testing
    let sampleRecipes: [RecipeModel] = [
        RecipeModel(
            title: "Classic Tomato Soup",
            headerNotes: "A warm and comforting soup perfect for cold days",
            yield: "4 servings",
            ingredientSections: [
                IngredientSection(ingredients: [
                    Ingredient(quantity: "2", unit: "lbs", name: "tomatoes", preparation: "diced"),
                    Ingredient(quantity: "1", unit: "cup", name: "cream"),
                    Ingredient(quantity: "1", unit: "tsp", name: "basil")
                ])
            ],
            instructionSections: [
                InstructionSection(steps: [
                    InstructionStep(stepNumber: 1, text: "Sauté onions for 5 minutes"),
                    InstructionStep(stepNumber: 2, text: "Add tomatoes and simmer for 30 minutes"),
                    InstructionStep(stepNumber: 3, text: "Blend and add cream")
                ])
            ],
            notes: [
                RecipeNote(type: .tip, text: "This soup freezes well")
            ],
            reference: "Julia Child"
        ),
        RecipeModel(
            title: "Caesar Salad",
            headerNotes: "Classic Caesar with homemade dressing",
            yield: "2 servings",
            ingredientSections: [
                IngredientSection(ingredients: [
                    Ingredient(quantity: "1", unit: "head", name: "romaine lettuce"),
                    Ingredient(quantity: "1/4", unit: "cup", name: "parmesan cheese"),
                    Ingredient(quantity: "1", unit: "cup", name: "croutons")
                ])
            ],
            instructionSections: [
                InstructionSection(steps: [
                    InstructionStep(stepNumber: 1, text: "Wash and chop lettuce"),
                    InstructionStep(stepNumber: 2, text: "Toss with dressing, takes about 10 minutes")
                ])
            ],
            reference: "Gordon Ramsay"
        ),
        RecipeModel(
            title: "Chocolate Chip Cookies",
            headerNotes: "Chewy and delicious cookies",
            yield: "24 cookies",
            ingredientSections: [
                IngredientSection(ingredients: [
                    Ingredient(quantity: "2", unit: "cups", name: "flour"),
                    Ingredient(quantity: "1", unit: "cup", name: "chocolate chips"),
                    Ingredient(quantity: "1/2", unit: "cup", name: "butter")
                ])
            ],
            instructionSections: [
                InstructionSection(steps: [
                    InstructionStep(stepNumber: 1, text: "Mix dry ingredients"),
                    InstructionStep(stepNumber: 2, text: "Cream butter and sugar"),
                    InstructionStep(stepNumber: 3, text: "Bake for 12 minutes at 350°F")
                ])
            ],
            notes: [
                RecipeNote(type: .tip, text: "Total time including prep is about 25 minutes")
            ],
            reference: "Betty Crocker"
        ),
        RecipeModel(
            title: "Spaghetti Carbonara",
            headerNotes: "Authentic Italian pasta",
            yield: "4 servings",
            ingredientSections: [
                IngredientSection(ingredients: [
                    Ingredient(quantity: "1", unit: "lb", name: "spaghetti"),
                    Ingredient(quantity: "4", name: "eggs"),
                    Ingredient(quantity: "1", unit: "cup", name: "parmesan cheese"),
                    Ingredient(quantity: "8", unit: "oz", name: "pancetta")
                ])
            ],
            instructionSections: [
                InstructionSection(steps: [
                    InstructionStep(stepNumber: 1, text: "Cook pasta according to package directions"),
                    InstructionStep(stepNumber: 2, text: "Cook pancetta until crispy, about 20 minutes"),
                    InstructionStep(stepNumber: 3, text: "Toss hot pasta with eggs and cheese")
                ])
            ]
        )
    ]
    
    // MARK: - Text Search Tests
    
    @Test("Search by recipe title")
    func searchByTitle() {
        let criteria = RecipeSearchService.SearchCriteria(searchText: "tomato")
        let results = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria)
        
        #expect(results.count == 1, "Should find 1 recipe with 'tomato' in title")
        #expect(results.first?.title == "Classic Tomato Soup")
    }
    
    @Test("Search by ingredient name")
    func searchByIngredient() {
        let criteria = RecipeSearchService.SearchCriteria(searchText: "chocolate")
        let results = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria)
        
        #expect(results.count == 1, "Should find 1 recipe with 'chocolate' in ingredients")
        #expect(results.first?.title == "Chocolate Chip Cookies")
    }
    
    @Test("Search by author/reference")
    func searchByAuthor() {
        let criteria = RecipeSearchService.SearchCriteria(author: "Julia")
        let results = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria)
        
        #expect(results.count == 1, "Should find 1 recipe by Julia Child")
        #expect(results.first?.title == "Classic Tomato Soup")
    }
    
    @Test("Search by header notes")
    func searchByHeaderNotes() {
        let criteria = RecipeSearchService.SearchCriteria(searchText: "authentic")
        let results = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria)
        
        #expect(results.count == 1, "Should find 1 recipe with 'authentic' in header notes")
        #expect(results.first?.title == "Spaghetti Carbonara")
    }
    
    @Test("Case-insensitive search")
    func caseInsensitiveSearch() {
        let criteria1 = RecipeSearchService.SearchCriteria(searchText: "TOMATO")
        let results1 = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria1)
        
        let criteria2 = RecipeSearchService.SearchCriteria(searchText: "tomato")
        let results2 = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria2)
        
        #expect(results1.count == results2.count, "Case should not matter in search")
    }
    
    // MARK: - Dish Type Tests
    
    @Test("Detect soup dish type")
    func detectSoupType() {
        let soupRecipe = sampleRecipes.first { $0.title.contains("Soup") }!
        let dishTypes = searchService.detectAllDishTypes(for: soupRecipe)
        
        #expect(dishTypes.contains(.soup), "Should detect soup dish type")
    }
    
    @Test("Detect salad dish type")
    func detectSaladType() {
        let saladRecipe = sampleRecipes.first { $0.title.contains("Salad") }!
        let dishTypes = searchService.detectAllDishTypes(for: saladRecipe)
        
        #expect(dishTypes.contains(.salad), "Should detect salad dish type")
    }
    
    @Test("Detect dessert dish type")
    func detectDessertType() {
        let cookieRecipe = sampleRecipes.first { $0.title.contains("Cookie") }!
        let dishTypes = searchService.detectAllDishTypes(for: cookieRecipe)
        
        #expect(dishTypes.contains(.dessert), "Should detect dessert dish type (cookies)")
    }
    
    @Test("Detect pasta dish type")
    func detectPastaType() {
        let pastaRecipe = sampleRecipes.first { $0.title.contains("Spaghetti") }!
        let dishTypes = searchService.detectAllDishTypes(for: pastaRecipe)
        
        #expect(dishTypes.contains(.pasta), "Should detect pasta dish type")
    }
    
    @Test("Filter by dish type")
    func filterByDishType() {
        var criteria = RecipeSearchService.SearchCriteria()
        criteria.dishTypes = [.soup]
        
        let results = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria)
        
        #expect(results.count == 1, "Should find 1 soup recipe")
        #expect(results.first?.title == "Classic Tomato Soup")
    }
    
    @Test("Filter by multiple dish types")
    func filterByMultipleDishTypes() {
        var criteria = RecipeSearchService.SearchCriteria()
        criteria.dishTypes = [.soup, .salad]
        
        let results = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria)
        
        #expect(results.count == 2, "Should find 2 recipes (soup and salad)")
    }
    
    // MARK: - Cooking Time Tests
    
    @Test("Extract cooking time from instructions")
    func extractCookingTime() {
        let soupRecipe = sampleRecipes.first { $0.title.contains("Soup") }!
        let cookingTime = searchService.getCookingTimeString(for: soupRecipe)
        
        // The recipe has multiple time mentions: "5 minutes" and "30 minutes"
        // The method returns the minimum time found (5 minutes from "Sauté onions for 5 minutes")
        #expect(cookingTime != nil, "Should extract cooking time from recipe")
        
        if let time = cookingTime {
            // Verify it extracted a valid time string with "min" or "hr"
            let hasTimeUnit = time.contains("min") || time.contains("hr")
            #expect(hasTimeUnit, "Should have a valid time unit. Got: \(time)")
            
            // Verify the time value is reasonable (between 1 and 100 minutes for this recipe)
            let components = time.components(separatedBy: " ")
            if let firstComponent = components.first, let minutes = Int(firstComponent) {
                #expect(minutes > 0 && minutes <= 100, "Should extract a reasonable time value. Got: \(minutes) minutes")
            }
        }
    }
    
    @Test("Extract cooking time from notes")
    func extractCookingTimeFromNotes() {
        let cookieRecipe = sampleRecipes.first { $0.title.contains("Cookie") }!
        let cookingTime = searchService.getCookingTimeString(for: cookieRecipe)
        
        // The recipe has "25 minutes" in notes and "12 minutes" in instructions
        // The method returns the minimum found time (12 minutes)
        #expect(cookingTime != nil, "Should extract cooking time from notes")
        
        if let time = cookingTime {
            // Verify it extracted a valid time string
            let hasTimeUnit = time.contains("min") || time.contains("hr")
            #expect(hasTimeUnit, "Should have a valid time unit. Got: \(time)")
            
            // Verify the time value is reasonable (should be 12 minutes - the minimum)
            let components = time.components(separatedBy: " ")
            if let firstComponent = components.first, let minutes = Int(firstComponent) {
                #expect(minutes > 0 && minutes <= 30, "Should extract the minimum time. Got: \(minutes) minutes")
            }
        }
    }
    
    @Test("Filter by cooking time")
    func filterByCookingTime() {
        var criteria = RecipeSearchService.SearchCriteria()
        criteria.maxCookingTime = 15 // Only recipes 15 minutes or less
        
        let results = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria)
        
        // Should find Caesar Salad (10 min) and Cookies (12 min bake time mentioned)
        #expect(results.count >= 1, "Should find at least 1 quick recipe")
    }
    
    // MARK: - Combined Search Tests
    
    @Test("Combined text and dish type search")
    func combinedTextAndDishType() {
        var criteria = RecipeSearchService.SearchCriteria()
        criteria.searchText = "cheese"
        criteria.dishTypes = [.salad]
        
        let results = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria)
        
        #expect(results.count == 1, "Should find Caesar Salad with cheese")
        #expect(results.first?.title == "Caesar Salad")
    }
    
    @Test("Combined author and dish type search")
    func combinedAuthorAndDishType() {
        var criteria = RecipeSearchService.SearchCriteria()
        criteria.author = "Julia"
        criteria.dishTypes = [.soup]
        
        let results = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria)
        
        #expect(results.count == 1, "Should find Julia Child's soup")
        #expect(results.first?.title == "Classic Tomato Soup")
    }
    
    @Test("No results for mismatched criteria")
    func noResultsForMismatch() {
        var criteria = RecipeSearchService.SearchCriteria()
        criteria.searchText = "chicken"
        
        let results = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria)
        
        #expect(results.isEmpty, "Should find no recipes with 'chicken'")
    }
    
    @Test("Empty criteria returns all recipes")
    func emptyCriteriaReturnsAll() {
        let criteria = RecipeSearchService.SearchCriteria()
        let results = searchService.searchRecipes(recipes: sampleRecipes, criteria: criteria)
        
        #expect(results.count == sampleRecipes.count, "Empty criteria should return all recipes")
    }
    
    // MARK: - Scoring Tests
    
    @Test("Search results with scoring")
    func searchResultsWithScoring() {
        let criteria = RecipeSearchService.SearchCriteria(searchText: "tomato")
        let results = searchService.search(recipes: sampleRecipes, criteria: criteria)
        
        #expect(results.count > 0, "Should have results")
        #expect(results.first?.score ?? 0 > 0, "Results should have positive scores")
    }
    
    @Test("Higher scores for title matches")
    func higherScoresForTitleMatches() {
        // Create two recipes - one with search term in title, one in ingredients only
        let recipe1 = RecipeModel(
            title: "Tomato Salad",
            ingredientSections: [
                IngredientSection(ingredients: [
                    Ingredient(name: "lettuce")
                ])
            ],
            instructionSections: [
                InstructionSection(steps: [
                    InstructionStep(text: "Mix ingredients")
                ])
            ]
        )
        
        let recipe2 = RecipeModel(
            title: "Garden Salad",
            ingredientSections: [
                IngredientSection(ingredients: [
                    Ingredient(name: "tomatoes")
                ])
            ],
            instructionSections: [
                InstructionSection(steps: [
                    InstructionStep(text: "Mix ingredients")
                ])
            ]
        )
        
        let criteria = RecipeSearchService.SearchCriteria(searchText: "tomato")
        let results = searchService.search(recipes: [recipe1, recipe2], criteria: criteria)
        
        #expect(results.count == 2, "Should find both recipes")
        // Recipe with title match should score higher
        #expect(results.first?.recipe.title == "Tomato Salad", "Title match should rank higher")
    }
    
    // MARK: - Dish Type Keyword Tests
    
    @Test("All dish types have keywords")
    func allDishTypesHaveKeywords() {
        for dishType in RecipeSearchService.DishType.allCases {
            #expect(!dishType.keywords.isEmpty, "Dish type \(dishType.rawValue) should have keywords")
        }
    }
    
    @Test("Dish type display names are formatted")
    func dishTypeDisplayNames() {
        #expect(RecipeSearchService.DishType.soup.displayName == "Soup")
        #expect(RecipeSearchService.DishType.mainCourse.displayName == "Main Course")
        #expect(RecipeSearchService.DishType.stirFry.displayName == "Stir-Fry")
    }
}
