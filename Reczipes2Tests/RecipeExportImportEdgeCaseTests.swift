//
//  RecipeExportImportEdgeCaseTests.swift
//  Reczipes2Tests
//
//  Edge case tests for export/import including error handling, special characters, and large data
//  Created on 1/5/26.
//

import Testing
import Foundation
import SwiftData
@testable import Reczipes2

@Suite("Recipe Export/Import Edge Cases")
struct RecipeExportImportEdgeCaseTests {
    
    // MARK: - Special Characters Tests
    
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
    
    // MARK: - Corrupted File Tests
    
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
    
    // MARK: - Error Message Tests
    
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
    
    // MARK: - Data Integrity Tests
    
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
    
    // MARK: - Large Data Tests
    
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
    
    // MARK: - File Name Sanitization Tests
    
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
    
    // MARK: - Version Compatibility Tests
    
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
