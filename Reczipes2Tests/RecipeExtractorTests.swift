//
//  RecipeExtractorTests.swift
//  Reczipes2Tests
//
//  Testing utilities and examples for recipe extraction
//

import Testing
import Foundation
import UIKit
@testable import Reczipes2

@Suite("Recipe Extractor Tests")
struct RecipeExtractorTests {
    
    // MARK: - Image Preprocessing Tests
    
    @Test("Image preprocessing returns valid data")
    func testImagePreprocessing() async throws {
        // Generate a test image instead of loading from assets
        guard let testImage = TestImageGenerator.generateTestRecipeImage() else {
            throw TestSkipError()
        }
        
        let imagePreprocessor = ImagePreprocessor()
        
        // Test preprocessing
        let processedData = imagePreprocessor.preprocessForOCR(testImage)
        #expect(processedData != nil, "Preprocessing should return data")
        
        // Verify processed image can be decoded
        if let processedData = processedData {
            let processedImage = UIImage(data: processedData)
            #expect(processedImage != nil, "Processed data should create valid image")
        }
    }
    
    @Test("Lightweight preprocessing returns valid data")
    func testLightweightPreprocessing() async throws {
        guard let testImage = TestImageGenerator.generateTestRecipeImage() else {
            throw TestSkipError()
        }
        
        let imagePreprocessor = ImagePreprocessor()
        let processedData = imagePreprocessor.preprocessLightweight(testImage)
        #expect(processedData != nil, "Lightweight preprocessing should return data")
    }
    
    // MARK: - Recipe Model Tests
    
    @Test("Recipe model ingredient initialization")
    @MainActor
    func testRecipeModelInitialization() async throws {
        let ingredient = Ingredient(
            quantity: "1",
            unit: "cup",
            name: "flour",
            preparation: "sifted"
        )
        
        #expect(ingredient.quantity == "1")
        #expect(ingredient.unit == "cup")
        #expect(ingredient.name == "flour")
        #expect(ingredient.preparation == "sifted")
    }
    
    @Test("Recipe with multiple sections")
    @MainActor
    func testRecipeWithMultipleSections() async throws {
        let recipe = RecipeModel(
            title: "Test Recipe",
            yield: "4 servings",
            ingredientSections: [
                IngredientSection(
                    title: "For the dough",
                    ingredients: [
                        Ingredient(quantity: "2", unit: "cups", name: "flour")
                    ]
                ),
                IngredientSection(
                    title: "For the filling",
                    ingredients: [
                        Ingredient(quantity: "1", unit: "cup", name: "sugar")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Mix ingredients")
                    ]
                )
            ]
        )
        
        #expect(recipe.ingredientSections.count == 2)
        #expect(recipe.instructionSections.count == 1)
    }
    
    // MARK: - JSON Parsing Tests
    
    @Test("Recipe response JSON parsing")
    @MainActor
    func testRecipeResponseParsing() async throws {
        let json = """
        {
            "title": "Test Recipe",
            "yield": "4 servings",
            "ingredientSections": [{
                "ingredients": [{
                    "quantity": "1",
                    "unit": "cup",
                    "name": "flour"
                }]
            }],
            "instructionSections": [{
                "steps": [{
                    "stepNumber": 1,
                    "text": "Mix well"
                }]
            }]
        }
        """
        
        let jsonData = json.data(using: .utf8)!
        
        let recipeResponse = try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
        let recipe = recipeResponse.toRecipeModel()
        
        #expect(recipe.title == "Test Recipe")
        #expect(recipe.yield == "4 servings")
        #expect(recipe.ingredientSections.count == 1)
        #expect(recipe.instructionSections.count == 1)
    }
    
    // MARK: - Keychain Tests
    
    @Test("Keychain storage and retrieval")
    func testKeychainStorage() async {
        let testKey = "test_api_key_\(UUID().uuidString)"
        let testValue = "sk-ant-test-key-123"
        
        // Test save
        let saveSuccess = await KeychainManager.shared.save(key: testKey, value: testValue)
        #expect(saveSuccess, "Should save to keychain")
        
        // Test retrieve
        let retrieved = await KeychainManager.shared.get(key: testKey)
        #expect(retrieved == testValue, "Should retrieve correct value")
        
        // Test delete
        let deleteSuccess = await KeychainManager.shared.delete(key: testKey)
        #expect(deleteSuccess, "Should delete from keychain")
        
        // Verify deleted
        let afterDelete = await KeychainManager.shared.get(key: testKey)
        #expect(afterDelete == nil, "Should be nil after deletion")
    }
}

// MARK: - Test Skip Error

struct TestSkipError: Error {
    let reason: String
    
    init(reason: String = "Test skipped") {
        self.reason = reason
    }
}

// MARK: - Manual Testing Guide

/*
 
 # Manual Testing Checklist
 
 ## Setup
 - [ ] API key properly configured in Keychain
 - [ ] Camera and photo library permissions granted
 - [ ] Info.plist has required privacy descriptions
 
 ## Image Selection
 - [ ] Can open camera
 - [ ] Can select from photo library
 - [ ] Can cancel selection
 - [ ] Selected image displays correctly
 
 ## Preprocessing
 - [ ] Toggle works correctly
 - [ ] Comparison view shows original vs processed
 - [ ] Processed image has better contrast
 - [ ] Can re-extract with different preprocessing setting
 
 ## Recipe Extraction
 - [ ] Loading indicator appears
 - [ ] Extracts recipe successfully from clear image
 - [ ] Handles poor quality images gracefully
 - [ ] Error messages are clear and helpful
 - [ ] Can retry after error
 
 ## Extracted Recipe Display
 - [ ] Recipe title displays correctly
 - [ ] All ingredient sections shown
 - [ ] All instruction sections shown
 - [ ] Notes and tips appear correctly
 - [ ] Metric conversions shown when present
 - [ ] Can navigate to detail view
 
 ## Recipe Detail View
 - [ ] All sections render properly
 - [ ] Step numbers display correctly
 - [ ] Ingredient formatting is clear
 - [ ] Notes have correct icons and colors
 - [ ] Share functionality works
 - [ ] Can navigate back
 
 ## Edge Cases
 - [ ] Handles multi-column recipe cards
 - [ ] Extracts handwritten recipes
 - [ ] Works with faded/old recipe cards
 - [ ] Handles recipes without section titles
 - [ ] Handles recipes without step numbers
 - [ ] Handles empty notes array
 
 ## Performance
 - [ ] Image preprocessing completes quickly (<2s)
 - [ ] API request completes in reasonable time (<30s)
 - [ ] No memory leaks
 - [ ] Smooth UI transitions
 
 ## Error Handling
 - [ ] Invalid API key shows clear error
 - [ ] Network failure shows retry option
 - [ ] Rate limit error is handled
 - [ ] Malformed JSON is caught
 - [ ] Missing fields don't crash app
 
 */

// MARK: - Debugging Utilities

extension RecipeExtractorViewModel {
    
    /// Debug helper to print extraction details
    @MainActor
    func debugPrint() {
        print("=== Recipe Extractor Debug Info ===")
        print("Is Loading: \(isLoading)")
        print("Use Preprocessing: \(usePreprocessing)")
        print("Error Message: \(errorMessage ?? "none")")
        print("Has Selected Image: \(selectedImage != nil)")
        print("Has Processed Image: \(processedImage != nil)")
        print("Has Extracted Recipe: \(extractedRecipe != nil)")
        
        if let recipe = extractedRecipe {
            print("\n=== Extracted Recipe ===")
            print("Title: \(recipe.title)")
            print("Yield: \(recipe.yield ?? "none")")
            print("Ingredient Sections: \(recipe.ingredientSections.count)")
            print("Instruction Sections: \(recipe.instructionSections.count)")
            print("Notes: \(recipe.notes.count)")
        }
        print("==================================")
    }
}

// MARK: - Mock Data for Testing

extension RecipeModel {
    
    /// Sample recipe for testing UI
    @MainActor
    static var sampleRecipe: RecipeModel {
        RecipeModel(
            title: "Classic Chocolate Chip Cookies",
            headerNotes: "The perfect crispy-chewy cookie",
            yield: "Makes 24 cookies",
            ingredientSections: [
                IngredientSection(
                    title: "Dry Ingredients",
                    ingredients: [
                        Ingredient(quantity: "2¼", unit: "cups", name: "all-purpose flour", metricQuantity: "280", metricUnit: "g"),
                        Ingredient(quantity: "1", unit: "tsp", name: "baking soda", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tsp", name: "salt", metricQuantity: "5", metricUnit: "mL")
                    ]
                ),
                IngredientSection(
                    title: "Wet Ingredients",
                    ingredients: [
                        Ingredient(quantity: "1", unit: "cup", name: "butter", preparation: "softened", metricQuantity: "227", metricUnit: "g"),
                        Ingredient(quantity: "¾", unit: "cup", name: "granulated sugar", metricQuantity: "150", metricUnit: "g"),
                        Ingredient(quantity: "¾", unit: "cup", name: "brown sugar", preparation: "packed", metricQuantity: "165", metricUnit: "g"),
                        Ingredient(quantity: "2", unit: "", name: "large eggs"),
                        Ingredient(quantity: "2", unit: "tsp", name: "vanilla extract", metricQuantity: "10", metricUnit: "mL")
                    ]
                ),
                IngredientSection(
                    title: "Mix-ins",
                    ingredients: [
                        Ingredient(quantity: "2", unit: "cups", name: "chocolate chips", metricQuantity: "340", metricUnit: "g")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    title: "Preparation",
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Preheat oven to 375°F (190°C)."),
                        InstructionStep(stepNumber: 2, text: "Line baking sheets with parchment paper."),
                        InstructionStep(stepNumber: 3, text: "Whisk together flour, baking soda, and salt in a bowl.")
                    ]
                ),
                InstructionSection(
                    title: "Mixing",
                    steps: [
                        InstructionStep(stepNumber: 4, text: "Cream butter and sugars until fluffy, about 3 minutes."),
                        InstructionStep(stepNumber: 5, text: "Beat in eggs one at a time, then vanilla."),
                        InstructionStep(stepNumber: 6, text: "Gradually mix in flour mixture."),
                        InstructionStep(stepNumber: 7, text: "Fold in chocolate chips.")
                    ]
                ),
                InstructionSection(
                    title: "Baking",
                    steps: [
                        InstructionStep(stepNumber: 8, text: "Drop rounded tablespoons of dough onto prepared sheets."),
                        InstructionStep(stepNumber: 9, text: "Bake 9-11 minutes until golden brown."),
                        InstructionStep(stepNumber: 10, text: "Cool on baking sheet for 2 minutes, then transfer to wire rack.")
                    ]
                )
            ],
            notes: [
                RecipeNote(type: .tip, text: "For chewier cookies, slightly underbake and let cool completely on the baking sheet."),
                RecipeNote(type: .substitution, text: "Can use all granulated sugar for crispier cookies."),
                RecipeNote(type: .timing, text: "Dough can be refrigerated for up to 3 days or frozen for 3 months."),
                RecipeNote(type: .warning, text: "Don't overbake - cookies will continue to cook as they cool.")
            ],
            reference: "Adapted from family recipe"
        )
    }
    
    /// Minimal recipe for testing edge cases
    @MainActor
    static var minimalRecipe: RecipeModel {
        RecipeModel(
            title: "Simple Toast",
            yield: "1 serving",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "1", unit: "slice", name: "bread"),
                        Ingredient(quantity: "1", unit: "tbsp", name: "butter")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Toast bread until golden."),
                        InstructionStep(text: "Spread with butter.")
                    ]
                )
            ]
        )
    }
}

// MARK: - Test Image Generation

class TestImageGenerator {
    
    /// Generate a simple test image with text
    static func generateTestRecipeImage() -> UIImage? {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Title
            let title = "Test Recipe"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            title.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)
            
            // Ingredients
            let ingredients = "Ingredients:\n• 1 cup flour\n• 2 eggs\n• 1 tsp salt"
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
            ingredients.draw(at: CGPoint(x: 20, y: 60), withAttributes: bodyAttributes)
            
            // Instructions
            let instructions = "Instructions:\n1. Mix ingredients\n2. Bake at 350°F"
            instructions.draw(at: CGPoint(x: 20, y: 160), withAttributes: bodyAttributes)
        }
    }
}

// MARK: - Performance Testing

@Suite("Recipe Extractor Performance Tests")
struct RecipeExtractorPerformanceTests {
    
    @Test("Image preprocessing performance", .timeLimit(.minutes(1)))
    func testImagePreprocessingPerformance() async throws {
        guard let testImage = TestImageGenerator.generateTestRecipeImage() else {
            throw TestSkipError(reason: "Test image not available")
        }
        
        let preprocessor = ImagePreprocessor()
        
        // Run preprocessing and measure time
        let startTime = Date()
        _ = preprocessor.preprocessForOCR(testImage)
        let duration = Date().timeIntervalSince(startTime)
        
        // Verify it completes in reasonable time
        // Note: Simulator performance can be slower, so we use a generous limit
        // On actual devices, this typically completes in < 2 seconds
        #expect(duration < 15.0, "Preprocessing should complete in under 15 seconds (simulator), took \(duration)s")
        
        if duration > 5.0 {
            print("⚠️ Preprocessing took \(String(format: "%.3f", duration))s - slower than ideal (consider testing on device)")
        } else {
            print("✓ Image preprocessing completed in \(String(format: "%.3f", duration))s")
        }
    }
    
    @Test("Recipe JSON parsing performance", .timeLimit(.minutes(1)))
    @MainActor
    func testRecipeJSONParsingPerformance() async throws {
        let json = createLargeRecipeJSON()
        let jsonData = json.data(using: .utf8)!
        
        // Run parsing and measure time
        let startTime = Date()
        _ = try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
        let duration = Date().timeIntervalSince(startTime)
        
        // Verify it completes in reasonable time (< 1 second)
        #expect(duration < 1.0, "JSON parsing should complete in under 1 second, took \(duration)s")
        print("✓ JSON parsing completed in \(String(format: "%.3f", duration))s")
    }
    
    private func createLargeRecipeJSON() -> String {
        // Generate JSON for a recipe with many sections
        return """
        {
            "title": "Complex Recipe",
            "yield": "12 servings",
            "ingredientSections": [\(String(repeating: """
                {"ingredients": [{"quantity": "1", "unit": "cup", "name": "ingredient"}]},
                """, count: 10))
                {"ingredients": [{"quantity": "1", "unit": "cup", "name": "ingredient"}]}
            ],
            "instructionSections": [\(String(repeating: """
                {"steps": [{"stepNumber": 1, "text": "Do something"}]},
                """, count: 10))
                {"steps": [{"stepNumber": 1, "text": "Do something"}]}
            ]
        }
        """
    }
}
