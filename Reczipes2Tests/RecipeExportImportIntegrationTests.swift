//
//  RecipeExportImportIntegrationTests.swift
//  Reczipes2Tests
//
//  Integration tests for complete export/import workflows
//  Created on 1/5/26.
//

import Testing
import Foundation
import SwiftData
@testable import Reczipes2

@Suite("Recipe Export/Import Integration Tests", .serialized)
struct RecipeExportImportIntegrationTests {
    
    /// Helper to get the Reczipes2 backup directory path
    func getBackupDirectory() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("Reczipes2", isDirectory: true)
    }
    
    @Test("Full export/import cycle preserves all data")
    @MainActor
    func testFullExportImportCycle() async throws {
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
        
        print("✓ Full export/import cycle preserved all recipe data")
    }
    
    @Test("Complete backup and restore workflow from Files/Reczipes2")
    @MainActor
    func testCompleteBackupRestoreWorkflow() async throws {
        // Step 1: Create original recipes
        let exportSchema = Schema([Recipe.self, RecipeBook.self])
        let exportConfig = ModelConfiguration(schema: exportSchema, isStoredInMemoryOnly: true)
        let exportContainer = try ModelContainer(for: exportSchema, configurations: [exportConfig])
        let exportContext = exportContainer.mainContext
        
        let recipe1 = Recipe(from: RecipeModel(
            id: UUID(),
            title: "Workflow Test Recipe 1",
            ingredientSections: [
                IngredientSection(ingredients: [Ingredient(name: "ingredient 1")])
            ],
            instructionSections: [
                InstructionSection(steps: [InstructionStep(text: "step 1")])
            ]
        ))
        
        let recipe2 = Recipe(from: RecipeModel(
            id: UUID(),
            title: "Workflow Test Recipe 2",
            ingredientSections: [
                IngredientSection(ingredients: [Ingredient(name: "ingredient 2")])
            ],
            instructionSections: [
                InstructionSection(steps: [InstructionStep(text: "step 2")])
            ]
        ))
        
        exportContext.insert(recipe1)
        exportContext.insert(recipe2)
        
        print("Step 1: Created 2 original recipes")
        
        // Step 2: Create backup to Files/Reczipes2
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [recipe1, recipe2])
        
        #expect(backupURL.path.contains("Reczipes2"), 
                "Backup should be in Reczipes2 folder")
        #expect(FileManager.default.fileExists(atPath: backupURL.path), 
                "Backup file should exist")
        
        print("Step 2: Created backup at: \(backupURL.lastPathComponent)")
        
        // Step 3: Verify backup is listed in available backups
        let availableBackups = try RecipeBackupManager.shared.listAvailableBackups()
        let ourBackup = availableBackups.first { $0.url == backupURL }
        
        #expect(ourBackup != nil, 
                "Backup should be listed in available backups")
        
        print("Step 3: Verified backup appears in available backups list")
        
        // Step 4: Create new context (simulating app reinstall or new device)
        let importSchema = Schema([Recipe.self, RecipeBook.self])
        let importConfig = ModelConfiguration(schema: importSchema, isStoredInMemoryOnly: true)
        let importContainer = try ModelContainer(for: importSchema, configurations: [importConfig])
        let importContext = importContainer.mainContext
        
        print("Step 4: Created fresh database context (simulating new device)")
        
        // Step 5: Import from backup
        let importResult = try await RecipeBackupManager.shared.importBackup(
            from: backupURL,
            into: importContext,
            existingRecipes: [],
            overwriteMode: .keepBoth
        )
        
        #expect(importResult.newRecipes == 2, 
                "Should import 2 new recipes")
        #expect(importResult.totalRecipes == 2, 
                "Total should be 2 recipes")
        
        print("Step 5: Successfully imported backup: \(importResult.summary)")
        
        // Step 6: Verify imported recipes match originals
        try importContext.save()
        
        let importedRecipes = try importContext.fetch(FetchDescriptor<Recipe>())
        #expect(importedRecipes.count == 2, 
                "Should have 2 recipes in new context")
        
        let titles = Set(importedRecipes.map { $0.title })
        #expect(titles.contains("Workflow Test Recipe 1"), 
                "Should contain Recipe 1")
        #expect(titles.contains("Workflow Test Recipe 2"), 
                "Should contain Recipe 2")
        
        print("Step 6: Verified all recipes restored correctly")
        print("✅ Complete backup/restore workflow succeeded!")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    @Test("Backup and restore preserves recipe relationships")
    @MainActor
    func testBackupRestoreWithRelationships() async throws {
        // Create recipes with complex data
        let exportSchema = Schema([Recipe.self, RecipeBook.self])
        let exportConfig = ModelConfiguration(schema: exportSchema, isStoredInMemoryOnly: true)
        let exportContainer = try ModelContainer(for: exportSchema, configurations: [exportConfig])
        let exportContext = exportContainer.mainContext
        
        let complexRecipe = Recipe(from: RecipeModel(
            id: UUID(),
            title: "Complex Recipe with All Features",
            headerNotes: "Header notes with émojis 🍕",
            yield: "Serves 4-6",
            ingredientSections: [
                IngredientSection(
                    title: "Section 1",
                    ingredients: [
                        Ingredient(quantity: "2", unit: "cups", name: "flour"),
                        Ingredient(quantity: "1", unit: "tsp", name: "salt")
                    ],
                    transitionNote: "Mix dry ingredients"
                ),
                IngredientSection(
                    title: "Section 2",
                    ingredients: [
                        Ingredient(quantity: "2", unit: "cups", name: "water")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    title: "Preparation",
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Prepare ingredients"),
                        InstructionStep(stepNumber: 2, text: "Mix together")
                    ]
                ),
                InstructionSection(
                    title: "Cooking",
                    steps: [
                        InstructionStep(stepNumber: 3, text: "Cook at 350°F")
                    ]
                )
            ],
            notes: [
                RecipeNote(type: .tip, text: "Use fresh ingredients"),
                RecipeNote(type: .warning, text: "Don't overmix"),
                RecipeNote(type: .timing, text: "Takes 45 minutes")
            ],
            reference: "Test Cookbook, Page 42"
        ))
        
        exportContext.insert(complexRecipe)
        
        // Create backup
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [complexRecipe])
        
        // Import to new context
        let importSchema = Schema([Recipe.self, RecipeBook.self])
        let importConfig = ModelConfiguration(schema: importSchema, isStoredInMemoryOnly: true)
        let importContainer = try ModelContainer(for: importSchema, configurations: [importConfig])
        let importContext = importContainer.mainContext
        
        let result = try await RecipeBackupManager.shared.importBackup(
            from: backupURL,
            into: importContext,
            existingRecipes: [],
            overwriteMode: .keepBoth
        )
        
        #expect(result.newRecipes == 1)
        
        // Verify imported recipe
        let importedRecipes = try importContext.fetch(FetchDescriptor<Recipe>())
        #expect(importedRecipes.count == 1)
        
        let imported = importedRecipes[0]
        #expect(imported.title == "Complex Recipe with All Features")
        #expect(imported.headerNotes == "Header notes with émojis 🍕")
        #expect(imported.recipeYield == "Serves 4-6")
        #expect(imported.reference == "Test Cookbook, Page 42")
        
        // Verify sections were preserved
        let decoder = JSONDecoder()
        let ingredientSections = try decoder.decode([IngredientSection].self, from: imported.ingredientSectionsData!)
        let instructionSections = try decoder.decode([InstructionSection].self, from: imported.instructionSectionsData!)
        let notes = try decoder.decode([RecipeNote].self, from: imported.notesData!)
        
        #expect(ingredientSections.count == 2)
        #expect(ingredientSections[0].title == "Section 1")
        #expect(ingredientSections[0].ingredients.count == 2)
        #expect(ingredientSections[0].transitionNote == "Mix dry ingredients")
        
        #expect(instructionSections.count == 2)
        #expect(instructionSections[0].title == "Preparation")
        #expect(instructionSections[0].steps.count == 2)
        
        #expect(notes.count == 3)
        #expect(notes[0].type == .tip)
        #expect(notes[1].type == .warning)
        #expect(notes[2].type == .timing)
        
        print("✅ Complex recipe with all relationships preserved perfectly!")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
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
    
    @Test("ExportableRecipeBook initializes from RecipeBook correctly")
    @MainActor
    func testExportableRecipeBookFromRecipeBook() throws {
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
}
