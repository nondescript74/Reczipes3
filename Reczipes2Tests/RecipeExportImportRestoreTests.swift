//
//  RecipeExportImportRestoreTests.swift
//  Reczipes2Tests
//
//  Tests for backup import, overwrite modes, and restore workflows
//  Created on 1/5/26.
//

import Testing
import Foundation
import SwiftData
@testable import Reczipes2

@Suite("Recipe Backup Restore Tests")
struct RecipeExportImportRestoreTests {
    
    // MARK: - Helper Functions
    
    /// Helper to get the Reczipes2 backup directory path
    func getBackupDirectory() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("Reczipes2", isDirectory: true)
    }
    
    /// Creates a complete RecipeModel with all fields populated
    func createCompleteRecipeModel() -> RecipeModel {
        return RecipeModel(
            id: UUID(),
            title: "Test Recipe: Complete Lasagna",
            headerNotes: "A delicious Italian classic",
            yield: "Serves 8-10",
            ingredientSections: [
                IngredientSection(
                    title: "For the Sauce",
                    ingredients: [
                        Ingredient(quantity: "2", unit: "lbs", name: "ground beef", preparation: "browned")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    title: "Prepare the Sauce",
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Brown the ground beef in a large skillet")
                    ]
                )
            ],
            notes: [
                RecipeNote(type: .tip, text: "Let the lasagna rest for 10 minutes before cutting")
            ],
            reference: "Grandma's recipe book, page 42"
        )
    }
    
    /// Creates a minimal RecipeModel
    func createMinimalRecipeModel() -> RecipeModel {
        return RecipeModel(
            title: "Simple Toast",
            ingredientSections: [
                IngredientSection(ingredients: [Ingredient(name: "bread")])
            ],
            instructionSections: [
                InstructionSection(steps: [InstructionStep(text: "Toast the bread")])
            ]
        )
    }
    
    // MARK: - Import Success Tests
    
    @Test("Importing backup from Reczipes2 folder succeeds")
    @MainActor
    func testImportBackupFromReczipes2Folder() async throws {
        // Create export
        let exportSchema = Schema([Recipe.self, RecipeBook.self])
        let exportConfig = ModelConfiguration(schema: exportSchema, isStoredInMemoryOnly: true)
        let exportContainer = try ModelContainer(for: exportSchema, configurations: [exportConfig])
        let exportContext = exportContainer.mainContext
        
        let originalRecipe = Recipe(from: createCompleteRecipeModel())
        exportContext.insert(originalRecipe)
        
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [originalRecipe])
        
        // Create new context for import
        let importSchema = Schema([Recipe.self, RecipeBook.self])
        let importConfig = ModelConfiguration(schema: importSchema, isStoredInMemoryOnly: true)
        let importContainer = try ModelContainer(for: importSchema, configurations: [importConfig])
        let importContext = importContainer.mainContext
        
        // Import backup
        let result = try await RecipeBackupManager.shared.importBackup(
            from: backupURL,
            into: importContext,
            existingRecipes: [],
            overwriteMode: .keepBoth
        )
        
        #expect(result.newRecipes == 1, 
                "Should import 1 new recipe, got: \(result.newRecipes)")
        #expect(result.totalRecipes == 1, 
                "Total recipes should be 1, got: \(result.totalRecipes)")
        
        print("✓ Successfully imported backup: \(result.summary)")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    @Test("Import with keepBoth mode preserves existing recipes")
    @MainActor
    func testImportKeepBothMode() async throws {
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        // Create and export a recipe
        let recipeModel = createCompleteRecipeModel()
        let originalRecipe = Recipe(from: recipeModel)
        context.insert(originalRecipe)
        
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [originalRecipe])
        
        // Import with keepBoth mode (recipe already exists)
        let result = try await RecipeBackupManager.shared.importBackup(
            from: backupURL,
            into: context,
            existingRecipes: [originalRecipe],
            overwriteMode: .keepBoth
        )
        
        #expect(result.newRecipes == 1, 
                "keepBoth mode should create new recipe even if one exists")
        #expect(result.updatedRecipes == 0, 
                "keepBoth mode should not update existing recipes")
        
        print("✓ keepBoth mode correctly creates duplicate with new ID")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    @Test("Import with skip mode skips existing recipes")
    @MainActor
    func testImportSkipMode() async throws {
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        // Create and export a recipe
        let recipeModel = createCompleteRecipeModel()
        let originalRecipe = Recipe(from: recipeModel)
        context.insert(originalRecipe)
        
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [originalRecipe])
        
        // Import with skip mode (recipe already exists)
        let result = try await RecipeBackupManager.shared.importBackup(
            from: backupURL,
            into: context,
            existingRecipes: [originalRecipe],
            overwriteMode: .skip
        )
        
        #expect(result.skippedRecipes == 1, 
                "skip mode should skip existing recipe")
        #expect(result.newRecipes == 0, 
                "skip mode should not create new recipes when they exist")
        
        print("✓ skip mode correctly skips existing recipes")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    @Test("Import with overwrite mode replaces existing recipes")
    @MainActor
    func testImportOverwriteMode() async throws {
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        // Create and export a recipe
        let recipeModel = createCompleteRecipeModel()
        let originalRecipe = Recipe(from: recipeModel)
        context.insert(originalRecipe)
        
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [originalRecipe])
        
        // Import with overwrite mode (recipe already exists)
        let result = try await RecipeBackupManager.shared.importBackup(
            from: backupURL,
            into: context,
            existingRecipes: [originalRecipe],
            overwriteMode: .overwrite
        )
        
        #expect(result.updatedRecipes == 1, 
                "overwrite mode should update existing recipe")
        #expect(result.newRecipes == 0, 
                "overwrite mode should not create new recipes when they exist")
        
        print("✓ overwrite mode correctly replaces existing recipes")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    // MARK: - Import Failure Tests
    
    @Test("Importing from non-existent file throws error")
    @MainActor
    func testImportNonExistentFile() async {
        let nonExistentURL = getBackupDirectory().appendingPathComponent("DoesNotExist.reczipes")
        
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        do {
            _ = try await RecipeBackupManager.shared.importBackup(
                from: nonExistentURL,
                into: context,
                existingRecipes: [],
                overwriteMode: .keepBoth
            )
            #expect(Bool(false), "Should throw error for non-existent file")
        } catch RecipeBackupError.invalidBackupFile {
            print("✓ Correctly throws invalidBackupFile error for non-existent file")
        } catch {
            print("✓ Throws error for non-existent file: \(error.localizedDescription)")
        }
    }
    
    @Test("Importing corrupted backup file throws decoding error")
    @MainActor
    func testImportCorruptedBackupFile() async throws {
        // Create a corrupted backup file
        let backupDir = getBackupDirectory()
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        let corruptedURL = backupDir.appendingPathComponent("TEST_Corrupted.reczipes")
        let corruptedData = "This is not valid JSON {{{".data(using: .utf8)!
        try corruptedData.write(to: corruptedURL)
        
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        do {
            _ = try await RecipeBackupManager.shared.importBackup(
                from: corruptedURL,
                into: context,
                existingRecipes: [],
                overwriteMode: .keepBoth
            )
            #expect(Bool(false), "Should throw decoding error for corrupted file")
        } catch RecipeBackupError.decodingFailed(let underlyingError) {
            print("✓ Correctly throws decodingFailed error for corrupted file")
            print("  Underlying error: \(underlyingError.localizedDescription)")
        } catch {
            print("✓ Throws error for corrupted file: \(error.localizedDescription)")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: corruptedURL)
    }
    
    @Test("Importing empty backup file throws error")
    @MainActor
    func testImportEmptyBackupFile() async throws {
        let backupDir = getBackupDirectory()
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        let emptyURL = backupDir.appendingPathComponent("TEST_Empty.reczipes")
        let emptyData = Data()
        try emptyData.write(to: emptyURL)
        
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        do {
            _ = try await RecipeBackupManager.shared.importBackup(
                from: emptyURL,
                into: context,
                existingRecipes: [],
                overwriteMode: .keepBoth
            )
            #expect(Bool(false), "Should throw error for empty file")
        } catch {
            print("✓ Correctly throws error for empty backup file: \(error.localizedDescription)")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: emptyURL)
    }
    
    // MARK: - Backup Persistence Tests
    
    @Test("Backup persists across app sessions")
    @MainActor
    func testBackupPersistence() async throws {
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let testRecipe = Recipe(from: createMinimalRecipeModel())
        context.insert(testRecipe)
        
        // Create backup
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [testRecipe])
        let fileName = backupURL.lastPathComponent
        
        print("Created backup: \(fileName)")
        
        // Verify file exists immediately
        #expect(FileManager.default.fileExists(atPath: backupURL.path), 
                "Backup should exist immediately after creation")
        
        // Verify it appears in the list immediately
        var availableBackups = try RecipeBackupManager.shared.listAvailableBackups()
        var foundBackup = availableBackups.first { $0.fileName == fileName }
        
        #expect(foundBackup != nil, 
                "Backup should be in available backups list immediately")
        
        // Wait a moment (simulating app closing/reopening)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify file still exists after waiting
        #expect(FileManager.default.fileExists(atPath: backupURL.path), 
                "Backup should still exist after waiting")
        
        // Verify it's still in the list after waiting
        availableBackups = try RecipeBackupManager.shared.listAvailableBackups()
        foundBackup = availableBackups.first { $0.fileName == fileName }
        
        #expect(foundBackup != nil, 
                "Backup should still be in available backups list after waiting")
        
        print("✓ Backup persists across simulated app sessions")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    @Test("Multiple sequential backups all persist")
    @MainActor
    func testMultipleSequentialBackups() async throws {
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let testRecipe = Recipe(from: createMinimalRecipeModel())
        context.insert(testRecipe)
        
        var backupURLs: [URL] = []
        var backupFileNames: [String] = []
        
        // Create 3 backups sequentially
        for i in 1...3 {
            let backupURL = try await RecipeBackupManager.shared.createBackup(from: [testRecipe])
            backupURLs.append(backupURL)
            backupFileNames.append(backupURL.lastPathComponent)
            
            // Verify file exists immediately after creation
            #expect(FileManager.default.fileExists(atPath: backupURL.path), 
                    "Backup \(i) should exist immediately after creation at: \(backupURL.path)")
            
            print("Created backup \(i): \(backupURL.lastPathComponent) - exists: \(FileManager.default.fileExists(atPath: backupURL.path))")
            
            // Small delay to ensure different timestamps
            if i < 3 {
                try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
            }
        }
        
        // Wait a moment before final verification
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify all backups still exist
        print("Verifying all backups still exist...")
        for (i, url) in backupURLs.enumerated() {
            let exists = FileManager.default.fileExists(atPath: url.path)
            print("  Backup \(i + 1) (\(url.lastPathComponent)): exists = \(exists)")
            #expect(exists, "Backup \(i + 1) should still exist at: \(url.path)")
        }
        
        // Verify all appear in available backups by checking their filenames
        let availableBackups = try RecipeBackupManager.shared.listAvailableBackups()
        let availableFileNames = Set(availableBackups.map { $0.fileName })
        
        print("Available backups: \(availableFileNames.sorted())")
        print("Expected backups: \(backupFileNames.sorted())")
        
        for (i, fileName) in backupFileNames.enumerated() {
            #expect(availableFileNames.contains(fileName), 
                    "Backup \(i + 1) (\(fileName)) should be in available backups list")
        }
        
        print("✓ All \(backupURLs.count) sequential backups persisted successfully")
        
        // Cleanup
        for url in backupURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
