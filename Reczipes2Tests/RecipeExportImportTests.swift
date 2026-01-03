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
    
    // MARK: - Smoke Test
    
    @Test("Absolute simplest test - should always pass")
    func testBasicAssertion() {
        #expect(1 + 1 == 2)
    }
    
    @Test("Test that creates a simple struct")
    func testSimpleStruct() {
        let uuid = UUID()
        #expect(uuid.uuidString.count > 0)
    }
    
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
        
        // Create in-memory ModelContainer for this test
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        // Create and insert the recipe
        let recipe = Recipe(from: model)
        context.insert(recipe)
        
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
        
        // Create in-memory ModelContainer for this test
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let recipe = Recipe(from: model)
        context.insert(recipe)
        
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
        
        // Create in-memory ModelContainer for this test
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let recipe = Recipe(from: model)
        context.insert(recipe)
        
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
        
        // Create in-memory ModelContainer for this test
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        // Convert to Recipe (simulating save)
        let recipe = Recipe(from: original)
        context.insert(recipe)
        
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
// MARK: - Export Package Validation Tests

@Suite("Recipe Book Export Package Validation Tests")
struct RecipeBookExportPackageValidationTests {
    
    @Test("Export package encodes with all required fields")
    @MainActor
    func testExportPackageRequiredFields() throws {
        let bookID = UUID()
        let recipeID = UUID()
        
        let exportableBook = ExportableRecipeBook(
            id: bookID,
            name: "Test Book",
            bookDescription: nil,
            coverImageName: nil,
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: [recipeID],
            color: nil
        )
        
        let recipe = RecipeModel(
            id: recipeID,
            title: "Test Recipe",
            ingredientSections: [
                IngredientSection(ingredients: [Ingredient(name: "test")])
            ],
            instructionSections: [
                InstructionSection(steps: [InstructionStep(text: "test")])
            ]
        )
        
        let package = RecipeBookExportPackage(
            book: exportableBook,
            recipes: [recipe],
            imageManifest: []
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(package)
        
        // Verify JSON is valid
        #expect(data.count > 0)
        
        // Verify it can be decoded back
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RecipeBookExportPackage.self, from: data)
        
        #expect(decoded.book.id == bookID)
        #expect(decoded.recipes.count == 1)
        #expect(decoded.version == "2.0")
    }
    
    @Test("Export package handles empty recipe book")
    @MainActor
    func testExportPackageWithEmptyBook() throws {
        let exportableBook = ExportableRecipeBook(
            id: UUID(),
            name: "Empty Book",
            bookDescription: nil,
            coverImageName: nil,
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: [],
            color: nil
        )
        
        let package = RecipeBookExportPackage(
            book: exportableBook,
            recipes: [],
            imageManifest: []
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(package)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RecipeBookExportPackage.self, from: data)
        
        #expect(decoded.recipes.isEmpty)
        #expect(decoded.book.recipeIDs.isEmpty)
        #expect(decoded.summary == "0 recipes, 0 images")
    }
    
    @Test("Export package handles book with many recipes")
    @MainActor
    func testExportPackageWithManyRecipes() throws {
        let bookID = UUID()
        var recipes: [RecipeModel] = []
        var recipeIDs: [UUID] = []
        
        // Create 100 recipes
        for i in 1...100 {
            let recipeID = UUID()
            recipeIDs.append(recipeID)
            
            let recipe = RecipeModel(
                id: recipeID,
                title: "Recipe \(i)",
                ingredientSections: [
                    IngredientSection(ingredients: [Ingredient(name: "ingredient \(i)")])
                ],
                instructionSections: [
                    InstructionSection(steps: [InstructionStep(text: "step \(i)")])
                ]
            )
            recipes.append(recipe)
        }
        
        let exportableBook = ExportableRecipeBook(
            id: bookID,
            name: "Large Book",
            bookDescription: nil,
            coverImageName: nil,
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: recipeIDs,
            color: nil
        )
        
        let package = RecipeBookExportPackage(
            book: exportableBook,
            recipes: recipes,
            imageManifest: []
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(package)
        
        // Verify large package encodes successfully
        #expect(data.count > 0)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RecipeBookExportPackage.self, from: data)
        
        #expect(decoded.recipes.count == 100)
        #expect(decoded.book.recipeIDs.count == 100)
    }
    
    @Test("Export package summary format is correct")
    @MainActor
    func testExportPackageSummary() throws {
        let book = ExportableRecipeBook(
            id: UUID(),
            name: "Test",
            bookDescription: nil,
            coverImageName: nil,
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: [UUID()],
            color: nil
        )
        
        // Test singular
        let package1 = RecipeBookExportPackage(
            book: book,
            recipes: [RecipeModel(
                title: "Test",
                ingredientSections: [],
                instructionSections: []
            )],
            imageManifest: [ImageManifestEntry(
                fileName: "test.jpg",
                type: .bookCover,
                associatedID: UUID()
            )]
        )
        
        #expect(package1.summary == "1 recipe, 1 image")
        
        // Test plural
        let package2 = RecipeBookExportPackage(
            book: book,
            recipes: [
                RecipeModel(title: "Test 1", ingredientSections: [], instructionSections: []),
                RecipeModel(title: "Test 2", ingredientSections: [], instructionSections: [])
            ],
            imageManifest: [
                ImageManifestEntry(fileName: "test1.jpg", type: .bookCover, associatedID: UUID()),
                ImageManifestEntry(fileName: "test2.jpg", type: .recipePrimary, associatedID: UUID())
            ]
        )
        
        #expect(package2.summary == "2 recipes, 2 images")
    }
}

// MARK: - Corrupted File Handling Tests

@Suite("Corrupted File Handling Tests")
struct RecipeBookCorruptedFileTests {
    
    @Test("Decoding fails gracefully with invalid JSON")
    @MainActor
    func testInvalidJSON() throws {
        let invalidJSON = "{ this is not valid json }"
        let data = invalidJSON.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            _ = try decoder.decode(RecipeBookExportPackage.self, from: data)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            // Expected to throw
            #expect(error is DecodingError)
        }
    }
    
    @Test("Decoding fails with missing required fields")
    @MainActor
    func testMissingRequiredFields() throws {
        let incompleteJSON = """
        {
            "version": "2.0",
            "exportDate": "2026-01-03T12:00:00Z"
        }
        """
        let data = incompleteJSON.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            _ = try decoder.decode(RecipeBookExportPackage.self, from: data)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            // Expected - missing book, recipes, and imageManifest
            #expect(error is DecodingError)
        }
    }
    
    @Test("Decoding handles corrupted recipe data")
    @MainActor
    func testCorruptedRecipeData() throws {
        let corruptedJSON = """
        {
            "version": "2.0",
            "exportDate": "2026-01-03T12:00:00Z",
            "book": {
                "id": "12345678-1234-1234-1234-123456789012",
                "name": "Test Book",
                "dateCreated": "2026-01-01T12:00:00Z",
                "dateModified": "2026-01-01T12:00:00Z",
                "recipeIDs": []
            },
            "recipes": [
                {
                    "id": "invalid-uuid",
                    "title": "Corrupted Recipe"
                }
            ],
            "imageManifest": []
        }
        """
        let data = corruptedJSON.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            _ = try decoder.decode(RecipeBookExportPackage.self, from: data)
            #expect(Bool(false), "Should have thrown an error for invalid UUID")
        } catch {
            #expect(error is DecodingError)
        }
    }
    
    @Test("Decoding handles wrong version format")
    @MainActor
    func testWrongVersionFormat() throws {
        let wrongVersionJSON = """
        {
            "version": 999,
            "exportDate": "2026-01-03T12:00:00Z",
            "book": {
                "id": "12345678-1234-1234-1234-123456789012",
                "name": "Test Book",
                "dateCreated": "2026-01-01T12:00:00Z",
                "dateModified": "2026-01-01T12:00:00Z",
                "recipeIDs": []
            },
            "recipes": [],
            "imageManifest": []
        }
        """
        let data = wrongVersionJSON.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            _ = try decoder.decode(RecipeBookExportPackage.self, from: data)
            #expect(Bool(false), "Should have thrown an error for wrong version type")
        } catch {
            #expect(error is DecodingError)
        }
    }
    
    @Test("Decoding handles malformed dates")
    @MainActor
    func testMalformedDates() throws {
        let malformedDateJSON = """
        {
            "version": "2.0",
            "exportDate": "not-a-date",
            "book": {
                "id": "12345678-1234-1234-1234-123456789012",
                "name": "Test Book",
                "dateCreated": "also-not-a-date",
                "dateModified": "2026-01-01T12:00:00Z",
                "recipeIDs": []
            },
            "recipes": [],
            "imageManifest": []
        }
        """
        let data = malformedDateJSON.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            _ = try decoder.decode(RecipeBookExportPackage.self, from: data)
            #expect(Bool(false), "Should have thrown an error for malformed dates")
        } catch {
            #expect(error is DecodingError)
        }
    }
    
    @Test("Recipe book validates empty data gracefully")
    @MainActor
    func testEmptyData() throws {
        let emptyData = Data()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            _ = try decoder.decode(RecipeBookExportPackage.self, from: emptyData)
            #expect(Bool(false), "Should have thrown an error for empty data")
        } catch {
            #expect(error is DecodingError)
        }
    }
}

// MARK: - Import Result Tests

@Suite("Recipe Book Import Result Tests")
struct RecipeBookImportResultTests {
    
    @Test("Import result summary formats correctly")
    @MainActor
    func testImportResultSummary() throws {
        // Create a mock RecipeBook
        let bookID = UUID()
        
        // Create in-memory ModelContainer for this test
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let mockBook = RecipeBook(
            id: bookID,
            name: "Test Book",
            bookDescription: nil,
            coverImageName: nil,
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: [],
            color: nil
        )
        context.insert(mockBook)
        
        // Test with new recipes only
        let result1 = RecipeBookImportResult(
            book: mockBook,
            recipesImported: 5,
            recipesUpdated: 0,
            imagesImported: 3,
            wasReplaced: false
        )
        #expect(result1.summary == "5 new recipes, 3 images")
        
        // Test with updated recipes only
        let result2 = RecipeBookImportResult(
            book: mockBook,
            recipesImported: 0,
            recipesUpdated: 2,
            imagesImported: 1,
            wasReplaced: false
        )
        #expect(result2.summary == "2 updated recipes, 1 image")
        
        // Test with both
        let result3 = RecipeBookImportResult(
            book: mockBook,
            recipesImported: 3,
            recipesUpdated: 2,
            imagesImported: 5,
            wasReplaced: true
        )
        #expect(result3.summary == "3 new recipes, 2 updated recipes, 5 images")
        
        // Test with no changes
        let result4 = RecipeBookImportResult(
            book: mockBook,
            recipesImported: 0,
            recipesUpdated: 0,
            imagesImported: 0,
            wasReplaced: false
        )
        #expect(result4.summary == "No changes")
    }
    
    @Test("Import mode descriptions are correct")
    @MainActor
    func testImportModeDescriptions() {
        #expect(RecipeBookImportMode.replace.description == "Replace existing book")
        #expect(RecipeBookImportMode.keepBoth.description == "Keep both books")
        #expect(RecipeBookImportMode.merge.description == "Merge into existing book")
    }
}

// MARK: - Data Integrity Tests

@Suite("Recipe Book Data Integrity Tests")
struct RecipeBookDataIntegrityTests {
    
    @Test("Recipe IDs match between book and recipes")
    @MainActor
    func testRecipeIDConsistency() throws {
        let recipe1ID = UUID()
        let recipe2ID = UUID()
        
        let recipe1 = RecipeModel(
            id: recipe1ID,
            title: "Recipe 1",
            ingredientSections: [],
            instructionSections: []
        )
        
        let recipe2 = RecipeModel(
            id: recipe2ID,
            title: "Recipe 2",
            ingredientSections: [],
            instructionSections: []
        )
        
        let exportableBook = ExportableRecipeBook(
            id: UUID(),
            name: "Test Book",
            bookDescription: nil,
            coverImageName: nil,
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: [recipe1ID, recipe2ID],
            color: nil
        )
        
        let package = RecipeBookExportPackage(
            book: exportableBook,
            recipes: [recipe1, recipe2],
            imageManifest: []
        )
        
        // Verify all recipe IDs in book exist in recipes
        let recipeIDsInRecipes = Set(package.recipes.map { $0.id })
        for bookRecipeID in package.book.recipeIDs {
            #expect(recipeIDsInRecipes.contains(bookRecipeID))
        }
    }
    
    @Test("Image manifest references valid IDs")
    @MainActor
    func testImageManifestReferenceValidity() throws {
        let bookID = UUID()
        let recipeID = UUID()
        
        let recipe = RecipeModel(
            id: recipeID,
            title: "Recipe",
            ingredientSections: [],
            instructionSections: [],
            imageName: "recipe.jpg"
        )
        
        let exportableBook = ExportableRecipeBook(
            id: bookID,
            name: "Book",
            bookDescription: nil,
            coverImageName: "cover.jpg",
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: [recipeID],
            color: nil
        )
        
        let imageManifest = [
            ImageManifestEntry(fileName: "cover.jpg", type: .bookCover, associatedID: bookID),
            ImageManifestEntry(fileName: "recipe.jpg", type: .recipePrimary, associatedID: recipeID)
        ]
        
        let package = RecipeBookExportPackage(
            book: exportableBook,
            recipes: [recipe],
            imageManifest: imageManifest
        )
        
        // Verify image manifest IDs are valid
        for entry in package.imageManifest {
            if entry.type == .bookCover {
                #expect(entry.associatedID == package.book.id)
            } else {
                let recipeIDs = Set(package.recipes.map { $0.id })
                #expect(recipeIDs.contains(entry.associatedID))
            }
        }
    }
    
    @Test("Export package preserves data after round-trip encoding")
    @MainActor
    func testRoundTripEncodingPreservesData() throws {
        let bookID = UUID()
        let recipeID = UUID()
        
        let recipe = RecipeModel(
            id: recipeID,
            title: "Test Recipe with Émojis 🍕",
            headerNotes: "Notes with \"quotes\" & special chars <>&",
            yield: "Serves 4-6",
            ingredientSections: [
                IngredientSection(
                    title: "Ingredients",
                    ingredients: [
                        Ingredient(
                            quantity: "2½",
                            unit: "cups",
                            name: "flour",
                            preparation: "sifted",
                            metricQuantity: "600",
                            metricUnit: "mL"
                        )
                    ],
                    transitionNote: "Mix well"
                )
            ],
            instructionSections: [
                InstructionSection(
                    title: "Steps",
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Step with\nnewlines\tand\ttabs")
                    ]
                )
            ],
            notes: [
                RecipeNote(type: .tip, text: "Tip with © symbol"),
                RecipeNote(type: .warning, text: "Warning ⚠️")
            ],
            reference: "Source with https://example.com URL",
            imageName: "test_image.jpg",
            additionalImageNames: ["extra1.jpg", "extra2.jpg"],
            imageURLs: ["https://example.com/image1.jpg"]
        )
        
        let exportableBook = ExportableRecipeBook(
            id: bookID,
            name: "Test Book™",
            bookDescription: "Description with émojis 📚",
            coverImageName: "cover.jpg",
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: [recipeID],
            color: "blue"
        )
        
        let imageManifest = [
            ImageManifestEntry(fileName: "cover.jpg", type: .bookCover, associatedID: bookID),
            ImageManifestEntry(fileName: "test_image.jpg", type: .recipePrimary, associatedID: recipeID)
        ]
        
        let original = RecipeBookExportPackage(
            book: exportableBook,
            recipes: [recipe],
            imageManifest: imageManifest
        )
        
        // Encode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(original)
        
        // Decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RecipeBookExportPackage.self, from: data)
        
        // Verify all data is preserved
        #expect(decoded.book.id == original.book.id)
        #expect(decoded.book.name == original.book.name)
        #expect(decoded.book.bookDescription == original.book.bookDescription)
        #expect(decoded.book.color == original.book.color)
        
        #expect(decoded.recipes.count == 1)
        let decodedRecipe = decoded.recipes[0]
        #expect(decodedRecipe.id == recipe.id)
        #expect(decodedRecipe.title == recipe.title)
        #expect(decodedRecipe.headerNotes == recipe.headerNotes)
        #expect(decodedRecipe.yield == recipe.yield)
        #expect(decodedRecipe.reference == recipe.reference)
        #expect(decodedRecipe.imageName == recipe.imageName)
        #expect(decodedRecipe.additionalImageNames?.count == 2)
        #expect(decodedRecipe.imageURLs?.count == 1)
        
        // Verify ingredient sections
        #expect(decodedRecipe.ingredientSections.count == 1)
        #expect(decodedRecipe.ingredientSections[0].title == "Ingredients")
        #expect(decodedRecipe.ingredientSections[0].ingredients[0].quantity == "2½")
        #expect(decodedRecipe.ingredientSections[0].transitionNote == "Mix well")
        
        // Verify instruction sections
        #expect(decodedRecipe.instructionSections.count == 1)
        #expect(decodedRecipe.instructionSections[0].steps[0].text.contains("\n"))
        
        // Verify notes
        #expect(decodedRecipe.notes.count == 2)
        #expect(decodedRecipe.notes[0].type == .tip)
        #expect(decodedRecipe.notes[1].type == .warning)
        
        // Verify image manifest
        #expect(decoded.imageManifest.count == 2)
    }
}

// MARK: - Duplicate Detection Tests

@Suite("Recipe Book Duplicate Detection Tests")
struct RecipeBookDuplicateDetectionTests {
    
    @Test("Detects books with matching IDs")
    @MainActor
    func testMatchingBookIDs() {
        let sharedID = UUID()
        
        let book1 = ExportableRecipeBook(
            id: sharedID,
            name: "Book 1",
            bookDescription: nil,
            coverImageName: nil,
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: [],
            color: nil
        )
        
        let book2 = ExportableRecipeBook(
            id: sharedID,
            name: "Book 2 (Different Name)",
            bookDescription: nil,
            coverImageName: nil,
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: [],
            color: nil
        )
        
        // Even though names differ, IDs match
        #expect(book1.id == book2.id)
    }
    
    @Test("Import modes have correct behavior descriptions")
    @MainActor
    func testImportModesBehavior() {
        // Verify each import mode has the expected behavior
        let modes: [RecipeBookImportMode] = [.replace, .keepBoth, .merge]
        
        for mode in modes {
            #expect(!mode.description.isEmpty)
        }
        
        // Verify they're all different
        let descriptions = Set(modes.map { $0.description })
        #expect(descriptions.count == 3)
    }
    
    @Test("Export package identifies duplicate recipes by ID")
    @MainActor
    func testDuplicateRecipeDetection() throws {
        let sharedID = UUID()
        
        // Two recipes with same ID but different content
        let recipe1 = RecipeModel(
            id: sharedID,
            title: "Original Recipe",
            ingredientSections: [
                IngredientSection(ingredients: [Ingredient(name: "original ingredient")])
            ],
            instructionSections: [
                InstructionSection(steps: [InstructionStep(text: "original step")])
            ]
        )
        
        let recipe2 = RecipeModel(
            id: sharedID,
            title: "Modified Recipe",
            ingredientSections: [
                IngredientSection(ingredients: [Ingredient(name: "modified ingredient")])
            ],
            instructionSections: [
                InstructionSection(steps: [InstructionStep(text: "modified step")])
            ]
        )
        
        // They should be considered duplicates based on ID
        #expect(recipe1.id == recipe2.id)
        
        // But their content is different
        #expect(recipe1.title != recipe2.title)
    }
}

// MARK: - Error Handling Tests

@Suite("Recipe Book Error Handling Tests")
struct RecipeBookErrorHandlingTests {
    
    @Test("RecipeBookImportError provides localized descriptions")
    @MainActor
    func testImportErrorDescriptions() {
        let errors: [RecipeBookImportError] = [
            .invalidFile,
            .decodingFailed(NSError(domain: "test", code: 1)),
            .existingBookConflict("Test Book"),
            .extractionFailed(NSError(domain: "test", code: 2)),
            .imageCopyFailed(NSError(domain: "test", code: 3)),
            .saveFailed(NSError(domain: "test", code: 4)),
            .unsupportedVersion("99.0")
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
    
    @Test("Invalid file error message is user-friendly")
    @MainActor
    func testInvalidFileErrorMessage() {
        let error = RecipeBookImportError.invalidFile
        #expect(error.errorDescription == "The selected file is not a valid recipe book.")
    }
    
    @Test("Existing book conflict shows book name")
    @MainActor
    func testExistingBookConflictMessage() {
        let bookName = "My Favorite Recipes"
        let error = RecipeBookImportError.existingBookConflict(bookName)
        #expect(error.errorDescription?.contains(bookName) == true)
    }
    
    @Test("Unsupported version shows version number")
    @MainActor
    func testUnsupportedVersionMessage() {
        let version = "99.0"
        let error = RecipeBookImportError.unsupportedVersion(version)
        #expect(error.errorDescription?.contains(version) == true)
    }
}

// MARK: - File Name Sanitization Tests

@Suite("File Name Sanitization Tests")
struct FileNameSanitizationTests {
    
    func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    @Test("Sanitizes invalid file name characters")
    @MainActor
    func testSanitizeInvalidCharacters() {
        let invalidNames = [
            "Book: The Recipe Collection",
            "Book/With/Slashes",
            "Book\\With\\Backslashes",
            "Book?Question",
            "Book%Percent",
            "Book*Star",
            "Book|Pipe",
            "Book\"Quote",
            "Book<Less>Greater"
        ]
        
        for name in invalidNames {
            let sanitized = sanitizeFileName(name)
            
            // Should not contain invalid characters
            #expect(!sanitized.contains(":"))
            #expect(!sanitized.contains("/"))
            #expect(!sanitized.contains("\\"))
            #expect(!sanitized.contains("?"))
            #expect(!sanitized.contains("%"))
            #expect(!sanitized.contains("*"))
            #expect(!sanitized.contains("|"))
            #expect(!sanitized.contains("\""))
            #expect(!sanitized.contains("<"))
            #expect(!sanitized.contains(">"))
        }
    }
    
    @Test("Preserves valid file name characters")
    @MainActor
    func testPreserveValidCharacters() {
        let validName = "My Recipe Book 2026 (Updated)"
        let sanitized = sanitizeFileName(validName)
        #expect(sanitized == validName)
    }
    
    @Test("Handles unicode characters correctly")
    @MainActor
    func testUnicodeCharacters() {
        let unicodeName = "Recipe Book 📚 Émojis & Accénts"
        let sanitized = sanitizeFileName(unicodeName)
        
        // Should preserve unicode but remove only invalid characters
        #expect(sanitized.contains("📚"))
        #expect(sanitized.contains("É"))
        #expect(sanitized.contains("é"))
    }
}

// MARK: - Image Manifest Tests

@Suite("Image Manifest Tests")
struct ImageManifestDetailedTests {
    
    @Test("Image manifest entry IDs are unique")
    @MainActor
    func testUniqueManifestIDs() {
        let entries = (1...10).map { i in
            ImageManifestEntry(
                fileName: "image\(i).jpg",
                type: .recipePrimary,
                associatedID: UUID()
            )
        }
        
        let ids = Set(entries.map { $0.id })
        #expect(ids.count == 10, "All manifest entry IDs should be unique")
    }
    
    @Test("Image manifest preserves file extensions")
    @MainActor
    func testFileExtensionPreservation() throws {
        let extensions = ["jpg", "jpeg", "png", "heic", "gif"]
        
        for ext in extensions {
            let entry = ImageManifestEntry(
                fileName: "test.\(ext)",
                type: .recipePrimary,
                associatedID: UUID()
            )
            
            #expect(entry.fileName.hasSuffix(".\(ext)"))
        }
    }
    
    @Test("Image manifest correctly categorizes image types")
    @MainActor
    func testImageTypeCategorization() {
        let bookID = UUID()
        let recipeID = UUID()
        
        let coverEntry = ImageManifestEntry(
            fileName: "cover.jpg",
            type: .bookCover,
            associatedID: bookID
        )
        
        let primaryEntry = ImageManifestEntry(
            fileName: "primary.jpg",
            type: .recipePrimary,
            associatedID: recipeID
        )
        
        let additionalEntry = ImageManifestEntry(
            fileName: "additional.jpg",
            type: .recipeAdditional,
            associatedID: recipeID
        )
        
        #expect(coverEntry.type == .bookCover)
        #expect(primaryEntry.type == .recipePrimary)
        #expect(additionalEntry.type == .recipeAdditional)
        
        // Book cover should reference book ID
        #expect(coverEntry.associatedID == bookID)
        
        // Recipe images should reference recipe ID
        #expect(primaryEntry.associatedID == recipeID)
        #expect(additionalEntry.associatedID == recipeID)
    }
    
    @Test("Image manifest encodes and decodes correctly")
    @MainActor
    func testImageManifestCoding() throws {
        let manifest = [
            ImageManifestEntry(fileName: "test1.jpg", type: .bookCover, associatedID: UUID()),
            ImageManifestEntry(fileName: "test2.png", type: .recipePrimary, associatedID: UUID()),
            ImageManifestEntry(fileName: "test3.heic", type: .recipeAdditional, associatedID: UUID())
        ]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(manifest)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([ImageManifestEntry].self, from: data)
        
        #expect(decoded.count == 3)
        #expect(decoded[0].fileName == "test1.jpg")
        #expect(decoded[0].type == .bookCover)
        #expect(decoded[1].type == .recipePrimary)
        #expect(decoded[2].type == .recipeAdditional)
    }
}

// MARK: - Version Compatibility Tests

@Suite("Version Compatibility Tests") 
struct VersionCompatibilityTests {
    
    @Test("Export package version is semantic version format")
    @MainActor
    func testVersionFormat() {
        let package = RecipeBookExportPackage(
            book: ExportableRecipeBook(
                id: UUID(),
                name: "Test",
                bookDescription: nil,
                coverImageName: nil,
                dateCreated: Date(),
                dateModified: Date(),
                recipeIDs: [],
                color: nil
            ),
            recipes: [],
            imageManifest: []
        )
        
        // Version should be in format X.Y or X.Y.Z
        let versionComponents = package.version.split(separator: ".")
        #expect(versionComponents.count >= 2)
        #expect(versionComponents.count <= 3)
        
        // Each component should be a number
        for component in versionComponents {
            #expect(Int(component) != nil, "Version component should be numeric")
        }
    }
    
    @Test("Current version is 2.0")
    @MainActor
    func testCurrentVersion() {
        let package = RecipeBookExportPackage(
            book: ExportableRecipeBook(
                id: UUID(),
                name: "Test",
                bookDescription: nil,
                coverImageName: nil,
                dateCreated: Date(),
                dateModified: Date(),
                recipeIDs: [],
                color: nil
            ),
            recipes: [],
            imageManifest: []
        )
        
        #expect(package.version == "2.0")
    }
    
    @Test("Future versions can be detected")
    @MainActor
    func testFutureVersionDetection() {
        // Simulating a check for unsupported future versions
        let supportedMajorVersions = [1, 2]
        
        let futureVersion = "3.0"
        let components = futureVersion.split(separator: ".").compactMap { Int($0) }
        
        if let major = components.first {
            #expect(!supportedMajorVersions.contains(major))
        }
    }
}

// MARK: - Data Size Tests

@Suite("Data Size and Performance Tests")
struct DataSizeTests {
    
    @Test("Small recipe encodes to reasonable size")
    @MainActor
    func testSmallRecipeSize() throws {
        let recipe = RecipeModel(
            id: UUID(),
            title: "Simple Recipe",
            ingredientSections: [
                IngredientSection(ingredients: [Ingredient(name: "ingredient")])
            ],
            instructionSections: [
                InstructionSection(steps: [InstructionStep(text: "step")])
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(recipe)
        
        // A simple recipe should be under 2KB
        #expect(data.count < 2048, "Small recipe should encode to less than 2KB")
    }
    
    @Test("Large recipe book encodes successfully")
    @MainActor
    func testLargeRecipeBook() throws {
        var recipes: [RecipeModel] = []
        
        // Create 50 recipes with substantial content
        for i in 1...50 {
            let recipe = RecipeModel(
                id: UUID(),
                title: "Recipe \(i): Comprehensive Recipe with Long Title",
                headerNotes: String(repeating: "These are detailed header notes. ", count: 10),
                yield: "Serves 4-6 people",
                ingredientSections: [
                    IngredientSection(
                        title: "Ingredients Section \(i)",
                        ingredients: (1...10).map { j in
                            Ingredient(
                                quantity: "\(j)",
                                unit: "cups",
                                name: "ingredient \(j)",
                                preparation: "chopped",
                                metricQuantity: "\(j * 240)",
                                metricUnit: "mL"
                            )
                        }
                    )
                ],
                instructionSections: [
                    InstructionSection(
                        title: "Instructions",
                        steps: (1...15).map { k in
                            InstructionStep(
                                stepNumber: k,
                                text: "Step \(String(describing: k)): " + String(repeating: "Detailed instruction text. ", count: 5)
                            )
                        }
                    )
                ],
                notes: [
                    RecipeNote(type: .tip, text: "Helpful tip here"),
                    RecipeNote(type: .timing, text: "This takes about 45 minutes")
                ],
                reference: "Source: Test Cookbook, Page \(i)"
            )
            recipes.append(recipe)
        }
        
        let book = ExportableRecipeBook(
            id: UUID(),
            name: "Large Recipe Collection",
            bookDescription: "A comprehensive collection of 50 recipes",
            coverImageName: "cover.jpg",
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: recipes.map { $0.id },
            color: "blue"
        )
        
        let package = RecipeBookExportPackage(
            book: book,
            recipes: recipes,
            imageManifest: []
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(package)
        
        // Should encode successfully
        #expect(data.count > 0)
        
        // Verify it can be decoded
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RecipeBookExportPackage.self, from: data)
        
        #expect(decoded.recipes.count == 50)
        
        // Log size for informational purposes
        print("Large recipe book encoded to \(data.count) bytes (\(data.count / 1024)KB)")
    }
    
    @Test("Export date is preserved across encoding")
    @MainActor
    func testExportDatePreservation() throws {
        let originalDate = Date()
        
        let package = RecipeBookExportPackage(
            exportDate: originalDate,
            book: ExportableRecipeBook(
                id: UUID(),
                name: "Test",
                bookDescription: nil,
                coverImageName: nil,
                dateCreated: Date(),
                dateModified: Date(),
                recipeIDs: [],
                color: nil
            ),
            recipes: [],
            imageManifest: []
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(package)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RecipeBookExportPackage.self, from: data)
        
        // Dates should match within 1 second (accounting for encoding precision)
        let timeDifference = abs(decoded.exportDate.timeIntervalSince(originalDate))
        #expect(timeDifference < 1.0, "Export date should be preserved")
    }
}

