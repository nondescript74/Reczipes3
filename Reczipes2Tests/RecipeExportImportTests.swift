//
//  RecipeExportImportTests.swift
//  Reczipes2Tests
//
//  Comprehensive test suite for Recipe and RecipeModel export/import
//

import Testing
import Foundation
import SwiftData
@testable import Reczipes2

@Suite("Recipe Export/Import Tests")
struct RecipeExportImportTests {
    
    // MARK: - Test Data Factories
    
    /// Creates a complete RecipeModel with all fields populated
    func createCompleteRecipeModel() -> RecipeModel {
        return RecipeModel(
            id: UUID(),
            title: "Test Recipe: Complete Lasagna",
            headerNotes: "A delicious Italian classic with layers of pasta, meat, and cheese",
            yield: "Serves 8-10",
            ingredientSections: [
                IngredientSection(
                    title: "For the Sauce",
                    ingredients: [
                        Ingredient(
                            quantity: "2",
                            unit: "lbs",
                            name: "ground beef",
                            preparation: "browned",
                            metricQuantity: "900",
                            metricUnit: "g"
                        ),
                        Ingredient(
                            quantity: "1",
                            unit: "jar",
                            name: "marinara sauce",
                            metricQuantity: "680",
                            metricUnit: "mL"
                        )
                    ],
                    transitionNote: "Sauce should simmer for 30 minutes"
                ),
                IngredientSection(
                    title: "For the Filling",
                    ingredients: [
                        Ingredient(
                            quantity: "15",
                            unit: "oz",
                            name: "ricotta cheese",
                            metricQuantity: "425",
                            metricUnit: "g"
                        ),
                        Ingredient(
                            quantity: "2",
                            unit: "cups",
                            name: "mozzarella cheese",
                            preparation: "shredded",
                            metricQuantity: "500",
                            metricUnit: "mL"
                        )
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    title: "Prepare the Sauce",
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Brown the ground beef in a large skillet"),
                        InstructionStep(stepNumber: 2, text: "Add marinara sauce and simmer for 30 minutes")
                    ]
                ),
                InstructionSection(
                    title: "Assemble and Bake",
                    steps: [
                        InstructionStep(stepNumber: 3, text: "Layer pasta, sauce, and cheese in a 9x13 pan"),
                        InstructionStep(stepNumber: 4, text: "Bake at 375°F for 45 minutes")
                    ]
                )
            ],
            notes: [
                RecipeNote(type: .tip, text: "Let the lasagna rest for 10 minutes before cutting"),
                RecipeNote(type: .substitution, text: "Can use ground turkey instead of beef"),
                RecipeNote(type: .warning, text: "Be careful not to overbake"),
                RecipeNote(type: .timing, text: "Total prep and cook time: 2 hours")
            ],
            reference: "Grandma's recipe book, page 42",
            imageName: "lasagna_main.jpg",
            additionalImageNames: ["lasagna_slice.jpg", "lasagna_prep.jpg"],
            imageURLs: ["https://example.com/image1.jpg"]
        )
    }
    
    /// Creates a minimal RecipeModel with only required fields
    func createMinimalRecipeModel() -> RecipeModel {
        return RecipeModel(
            title: "Simple Toast",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(name: "bread"),
                        Ingredient(name: "butter")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Toast the bread"),
                        InstructionStep(text: "Spread butter on toast")
                    ]
                )
            ]
        )
    }
    
    // MARK: - RecipeModel Encoding/Decoding Tests
    
    @Test("RecipeModel complete encoding and decoding")
    @MainActor
    func testCompleteRecipeModelCoding() throws {
        let original = createCompleteRecipeModel()
        
        // Encode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        
        // Decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RecipeModel.self, from: data)
        
        // Verify all fields
        #expect(decoded.id == original.id)
        #expect(decoded.title == original.title)
        #expect(decoded.headerNotes == original.headerNotes)
        #expect(decoded.yield == original.yield)
        #expect(decoded.reference == original.reference)
        #expect(decoded.imageName == original.imageName)
        #expect(decoded.additionalImageNames?.count == original.additionalImageNames?.count)
        #expect(decoded.imageURLs?.count == original.imageURLs?.count)
        
        // Verify ingredient sections
        #expect(decoded.ingredientSections.count == original.ingredientSections.count)
        #expect(decoded.ingredientSections[0].title == original.ingredientSections[0].title)
        #expect(decoded.ingredientSections[0].ingredients.count == original.ingredientSections[0].ingredients.count)
        #expect(decoded.ingredientSections[0].transitionNote == original.ingredientSections[0].transitionNote)
        
        // Verify ingredients details
        let firstIngredient = decoded.ingredientSections[0].ingredients[0]
        let originalFirstIngredient = original.ingredientSections[0].ingredients[0]
        #expect(firstIngredient.name == originalFirstIngredient.name)
        #expect(firstIngredient.quantity == originalFirstIngredient.quantity)
        #expect(firstIngredient.unit == originalFirstIngredient.unit)
        #expect(firstIngredient.preparation == originalFirstIngredient.preparation)
        #expect(firstIngredient.metricQuantity == originalFirstIngredient.metricQuantity)
        #expect(firstIngredient.metricUnit == originalFirstIngredient.metricUnit)
        
        // Verify instruction sections
        #expect(decoded.instructionSections.count == original.instructionSections.count)
        #expect(decoded.instructionSections[0].title == original.instructionSections[0].title)
        #expect(decoded.instructionSections[0].steps.count == original.instructionSections[0].steps.count)
        
        // Verify instruction steps
        let firstStep = decoded.instructionSections[0].steps[0]
        let originalFirstStep = original.instructionSections[0].steps[0]
        #expect(firstStep.text == originalFirstStep.text)
        #expect(firstStep.stepNumber == originalFirstStep.stepNumber)
        
        // Verify notes
        #expect(decoded.notes.count == original.notes.count)
        #expect(decoded.notes[0].type == original.notes[0].type)
        #expect(decoded.notes[0].text == original.notes[0].text)
    }
    
    @Test("RecipeModel minimal encoding and decoding")
    @MainActor
    func testMinimalRecipeModelCoding() throws {
        let original = createMinimalRecipeModel()
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecipeModel.self, from: data)
        
        // Verify required fields
        #expect(decoded.title == original.title)
        #expect(decoded.ingredientSections.count == 1)
        #expect(decoded.instructionSections.count == 1)
        
        // Verify optional fields are nil
        #expect(decoded.headerNotes == nil)
        #expect(decoded.yield == nil)
        #expect(decoded.reference == nil)
        #expect(decoded.imageName == nil)
        #expect(decoded.additionalImageNames == nil)
    }
    
    @Test("RecipeModel handles empty arrays")
    @MainActor
    func testRecipeModelWithEmptyArrays() throws {
        let model = RecipeModel(
            title: "Empty Recipe",
            ingredientSections: [],
            instructionSections: [],
            notes: []
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(model)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecipeModel.self, from: data)
        
        #expect(decoded.ingredientSections.isEmpty)
        #expect(decoded.instructionSections.isEmpty)
        #expect(decoded.notes.isEmpty)
    }
    
    // MARK: - Recipe to RecipeModel Conversion Tests
    
    @Test("Recipe initializes from RecipeModel with all fields")
    @MainActor
    func testRecipeInitFromCompleteRecipeModel() throws {
        let model = createCompleteRecipeModel()
        let recipe = Recipe(from: model)
        
        // Verify basic fields
        #expect(recipe.id == model.id)
        #expect(recipe.title == model.title)
        #expect(recipe.headerNotes == model.headerNotes)
        #expect(recipe.recipeYield == model.yield)
        #expect(recipe.reference == model.reference)
        #expect(recipe.imageName == model.imageName)
        #expect(recipe.additionalImageNames?.count == model.additionalImageNames?.count)
        
        // Verify encoded data exists
        #expect(recipe.ingredientSectionsData != nil)
        #expect(recipe.instructionSectionsData != nil)
        #expect(recipe.notesData != nil)
        
        // Decode and verify ingredient sections
        let decoder = JSONDecoder()
        if let data = recipe.ingredientSectionsData {
            let sections = try decoder.decode([IngredientSection].self, from: data)
            #expect(sections.count == model.ingredientSections.count)
            #expect(sections[0].title == model.ingredientSections[0].title)
        }
        
        // Decode and verify instruction sections
        if let data = recipe.instructionSectionsData {
            let sections = try decoder.decode([InstructionSection].self, from: data)
            #expect(sections.count == model.instructionSections.count)
            #expect(sections[0].title == model.instructionSections[0].title)
        }
        
        // Decode and verify notes
        if let data = recipe.notesData {
            let notes = try decoder.decode([RecipeNote].self, from: data)
            #expect(notes.count == model.notes.count)
            #expect(notes[0].type == model.notes[0].type)
        }
        
        // Verify version tracking
        #expect(recipe.version != nil)
        #expect(recipe.lastModified != nil)
    }
    
    @Test("Recipe initializes from minimal RecipeModel")
    @MainActor
    func testRecipeInitFromMinimalRecipeModel() throws {
        let model = createMinimalRecipeModel()
        let recipe = Recipe(from: model)
        
        #expect(recipe.title == model.title)
        #expect(recipe.headerNotes == nil)
        #expect(recipe.recipeYield == nil)
        #expect(recipe.ingredientSectionsData != nil)
        #expect(recipe.instructionSectionsData != nil)
    }
    
    // MARK: - RecipeModel Export Package Tests
    
    @Test("RecipeBookExportPackage encodes and decodes correctly")
    @MainActor
    func testExportPackageEncoding() throws {
        let recipes = [createCompleteRecipeModel(), createMinimalRecipeModel()]
        
        let exportableBook = ExportableRecipeBook(
            id: UUID(),
            name: "Test Cookbook",
            bookDescription: "A collection of test recipes",
            coverImageName: "cover.jpg",
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: recipes.map { $0.id },
            color: "blue"
        )
        
        let imageManifest = [
            ImageManifestEntry(
                fileName: "cover.jpg",
                type: .bookCover,
                associatedID: exportableBook.id
            ),
            ImageManifestEntry(
                fileName: "lasagna_main.jpg",
                type: .recipePrimary,
                associatedID: recipes[0].id
            )
        ]
        
        let package = RecipeBookExportPackage(
            book: exportableBook,
            recipes: recipes,
            imageManifest: imageManifest
        )
        
        // Encode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(package)
        
        // Decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RecipeBookExportPackage.self, from: data)
        
        // Verify package structure
        #expect(decoded.version == package.version)
        #expect(decoded.book.id == exportableBook.id)
        #expect(decoded.book.name == exportableBook.name)
        #expect(decoded.recipes.count == recipes.count)
        #expect(decoded.imageManifest.count == imageManifest.count)
        
        // Verify recipes
        #expect(decoded.recipes[0].title == recipes[0].title)
        #expect(decoded.recipes[1].title == recipes[1].title)
        
        // Verify image manifest
        #expect(decoded.imageManifest[0].type == .bookCover)
        #expect(decoded.imageManifest[1].type == .recipePrimary)
    }
    
    // MARK: - Edge Cases and Validation
    
    @Test("RecipeModel handles special characters in text")
    @MainActor
    func testSpecialCharactersInRecipeModel() throws {
        let model = RecipeModel(
            title: "Recipe with \"quotes\" & <symbols>",
            headerNotes: "Notes with émojis 🍕 and unicode",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(name: "ingredient with ½ fraction"),
                        Ingredient(name: "ingredient with © symbol")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Step with newlines\nand\ttabs")
                    ]
                )
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(model)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecipeModel.self, from: data)
        
        #expect(decoded.title == model.title)
        #expect(decoded.headerNotes == model.headerNotes)
        #expect(decoded.ingredientSections[0].ingredients[0].name.contains("½"))
        #expect(decoded.instructionSections[0].steps[0].text.contains("\n"))
    }
    
    @Test("RecipeModel handles very long text fields")
    @MainActor
    func testLongTextFieldsInRecipeModel() throws {
        let longText = String(repeating: "This is a very long text. ", count: 100)
        
        let model = RecipeModel(
            title: longText,
            headerNotes: longText,
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(name: longText)
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: longText)
                    ]
                )
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(model)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecipeModel.self, from: data)
        
        #expect(decoded.title == longText)
        #expect(decoded.headerNotes == longText)
    }
    
    @Test("Recipe computed properties work correctly")
    @MainActor
    func testRecipeComputedProperties() throws {
        let model = RecipeModel(
            title: "Test Recipe",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(name: "flour"),
                        Ingredient(name: "sugar")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Mix ingredients")
                    ]
                )
            ],
            imageName: "main.jpg",
            additionalImageNames: ["photo1.jpg", "photo2.jpg"]
        )
        
        let recipe = Recipe(from: model)
        
        // Test allImageNames computed property (from RecipeModel)
        #expect(model.allImageNames.count == 3)
        #expect(model.allImageNames.contains("main.jpg"))
        #expect(model.allImageNames.contains("photo1.jpg"))
        
        // Test imageCount computed property
        #expect(model.imageCount == 3)
        
        // Test currentVersion computed property (from Recipe)
        #expect(recipe.currentVersion >= 1)
        
        // Test modificationDate computed property
        #expect(recipe.modificationDate <= Date())
    }
    
    @Test("Ingredient preserves all metric and imperial data")
    @MainActor
    func testIngredientMetricAndImperialUnits() throws {
        let ingredient = Ingredient(
            quantity: "1",
            unit: "cup",
            name: "flour",
            preparation: "sifted",
            metricQuantity: "240",
            metricUnit: "mL"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(ingredient)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Ingredient.self, from: data)
        
        #expect(decoded.quantity == "1")
        #expect(decoded.unit == "cup")
        #expect(decoded.metricQuantity == "240")
        #expect(decoded.metricUnit == "mL")
        #expect(decoded.preparation == "sifted")
    }
    
    @Test("RecipeNote all types encode correctly")
    @MainActor
    func testRecipeNoteTypes() throws {
        let notes = [
            RecipeNote(type: .tip, text: "A helpful tip"),
            RecipeNote(type: .substitution, text: "Use X instead of Y"),
            RecipeNote(type: .warning, text: "Be careful!"),
            RecipeNote(type: .timing, text: "This takes 30 minutes"),
            RecipeNote(type: .general, text: "General information")
        ]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(notes)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([RecipeNote].self, from: data)
        
        #expect(decoded.count == 5)
        #expect(decoded[0].type == .tip)
        #expect(decoded[1].type == .substitution)
        #expect(decoded[2].type == .warning)
        #expect(decoded[3].type == .timing)
        #expect(decoded[4].type == .general)
    }
    
    @Test("ImageManifestEntry all types work correctly")
    @MainActor
    func testImageManifestTypes() throws {
        let bookID = UUID()
        let recipeID = UUID()
        
        let entries = [
            ImageManifestEntry(fileName: "cover.jpg", type: .bookCover, associatedID: bookID),
            ImageManifestEntry(fileName: "main.jpg", type: .recipePrimary, associatedID: recipeID),
            ImageManifestEntry(fileName: "extra.jpg", type: .recipeAdditional, associatedID: recipeID)
        ]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(entries)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([ImageManifestEntry].self, from: data)
        
        #expect(decoded.count == 3)
        #expect(decoded[0].type == .bookCover)
        #expect(decoded[1].type == .recipePrimary)
        #expect(decoded[2].type == .recipeAdditional)
        #expect(decoded[0].associatedID == bookID)
    }
    
    // MARK: - Version Compatibility Tests
    
    @Test("Old RecipeModel format without new fields still decodes")
    @MainActor
    func testBackwardCompatibility() throws {
        // Simulate an old JSON format without additionalImageNames or imageURLs
        let oldJSON = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "title": "Old Recipe",
            "ingredientSections": [
                {
                    "id": "87654321-4321-4321-4321-210987654321",
                    "ingredients": [
                        {
                            "id": "11111111-1111-1111-1111-111111111111",
                            "name": "flour"
                        }
                    ]
                }
            ],
            "instructionSections": [
                {
                    "id": "22222222-2222-2222-2222-222222222222",
                    "steps": [
                        {
                            "id": "33333333-3333-3333-3333-333333333333",
                            "text": "Mix well"
                        }
                    ]
                }
            ],
            "notes": []
        }
        """
        
        let decoder = JSONDecoder()
        let model = try decoder.decode(RecipeModel.self, from: oldJSON.data(using: .utf8)!)
        
        #expect(model.title == "Old Recipe")
        #expect(model.additionalImageNames == nil)
        #expect(model.imageURLs == nil)
        #expect(model.ingredientSections.count == 1)
    }
    
    @Test("ExportableRecipeBook initializes from RecipeBook correctly")
    @MainActor
    func testExportableRecipeBookFromRecipeBook() throws {
        // This test would require a RecipeBook instance
        // Since RecipeBook is a @Model class, we'll test the data structure
        
        let exportable = ExportableRecipeBook(
            id: UUID(),
            name: "My Cookbook",
            bookDescription: "A test cookbook",
            coverImageName: "cover.jpg",
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: [UUID(), UUID()],
            color: "red"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportable)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ExportableRecipeBook.self, from: data)
        
        #expect(decoded.name == exportable.name)
        #expect(decoded.bookDescription == exportable.bookDescription)
        #expect(decoded.recipeIDs.count == 2)
        #expect(decoded.color == "red")
    }
}

// MARK: - Integration Test Suite

@Suite("Recipe Export/Import Integration Tests")
struct RecipeExportImportIntegrationTests {
    
    @Test("Full export/import cycle preserves all data")
    @MainActor
    func testFullExportImportCycle() throws {
        // Create a complete recipe
        let original = RecipeModel(
            id: UUID(),
            title: "Integration Test Recipe",
            headerNotes: "Test notes",
            yield: "4 servings",
            ingredientSections: [
                IngredientSection(
                    title: "Main",
                    ingredients: [
                        Ingredient(
                            quantity: "2",
                            unit: "cups",
                            name: "flour",
                            metricQuantity: "480",
                            metricUnit: "mL"
                        )
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Mix ingredients")
                    ]
                )
            ],
            notes: [
                RecipeNote(type: .tip, text: "Test tip")
            ],
            reference: "Test source",
            imageName: "test.jpg"
        )
        
        // Convert to Recipe (simulating save)
        let recipe = Recipe(from: original)
        
        // Convert back to RecipeModel (simulating export)
        let decoder = JSONDecoder()
        
        let ingredientSections = try decoder.decode(
            [IngredientSection].self,
            from: recipe.ingredientSectionsData!
        )
        let instructionSections = try decoder.decode(
            [InstructionSection].self,
            from: recipe.instructionSectionsData!
        )
        let notes = try decoder.decode(
            [RecipeNote].self,
            from: recipe.notesData!
        )
        
        let exported = RecipeModel(
            id: recipe.id,
            title: recipe.title,
            headerNotes: recipe.headerNotes,
            yield: recipe.recipeYield,
            ingredientSections: ingredientSections,
            instructionSections: instructionSections,
            notes: notes,
            reference: recipe.reference,
            imageName: recipe.imageName,
            additionalImageNames: recipe.additionalImageNames
        )
        
        // Verify everything matches
        #expect(exported.id == original.id)
        #expect(exported.title == original.title)
        #expect(exported.headerNotes == original.headerNotes)
        #expect(exported.yield == original.yield)
        #expect(exported.reference == original.reference)
        #expect(exported.imageName == original.imageName)
        #expect(exported.ingredientSections.count == original.ingredientSections.count)
        #expect(exported.instructionSections.count == original.instructionSections.count)
        #expect(exported.notes.count == original.notes.count)
    }
}
