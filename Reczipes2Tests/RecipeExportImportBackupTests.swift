//
//  RecipeExportImportBackupTests.swift
//  Reczipes2Tests
//
//  Tests for backup creation, file naming, and directory management
//  Created on 1/5/26.
//

import Testing
import Foundation
import SwiftData
@testable import Reczipes2

@Suite("Recipe Backup Creation Tests")
struct RecipeExportImportBackupTests {
    
    // MARK: - Test Configuration
    
    /// Helper to get the Reczipes2 backup directory path
    func getBackupDirectory() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("Reczipes2", isDirectory: true)
    }
    
    /// Creates a minimal RecipeModel with only required fields
    @MainActor
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
    
    /// Creates a complete RecipeModel with all fields populated
    @MainActor
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
                )
            ],
            instructionSections: [
                InstructionSection(
                    title: "Prepare the Sauce",
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Brown the ground beef in a large skillet"),
                        InstructionStep(stepNumber: 2, text: "Add marinara sauce and simmer for 30 minutes")
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
    
    // MARK: - Backup Directory Tests
    
    @Test("Backup directory path is correct")
    @MainActor
    func testBackupDirectoryPath() {
        let backupDir = getBackupDirectory()
        #expect(backupDir.lastPathComponent == "Reczipes2", "Backup directory should be named Reczipes2")
        #expect(backupDir.path.contains("Documents"), "Backup directory should be in Documents folder")
    }
    
    @Test("Backup directory is created when it doesn't exist")
    @MainActor
    func testBackupDirectoryCreation() async throws {
        let backupDir = getBackupDirectory()
        
        // Remove directory if it exists
        if FileManager.default.fileExists(atPath: backupDir.path) {
            try? FileManager.default.removeItem(at: backupDir)
        }
        
        // Create a test recipe
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let testRecipe = Recipe(from: createMinimalRecipeModel())
        context.insert(testRecipe)
        
        // Create backup - this should create the directory
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [testRecipe])
        
        // Verify directory exists
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: backupDir.path, isDirectory: &isDirectory)
        #expect(exists, "Backup directory should be created if it doesn't exist")
        #expect(isDirectory.boolValue, "Backup directory path should be a directory")
        
        // Verify backup file is in the directory
        #expect(backupURL.deletingLastPathComponent() == backupDir, "Backup should be saved in Reczipes2 folder")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    @Test("Backup files are saved to Files/Reczipes2 folder")
    @MainActor
    func testBackupSavedToCorrectLocation() async throws {
        _ = getBackupDirectory()
        
        // Create a test recipe
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let testRecipe = Recipe(from: createCompleteRecipeModel())
        context.insert(testRecipe)
        
        // Create backup
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [testRecipe])
        
        // Verify it's in the correct location
        #expect(backupURL.path.contains("Documents/Reczipes2"), 
                "Backup should be in Documents/Reczipes2 folder, but was at: \(backupURL.path)")
        
        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: backupURL.path), 
                "Backup file should exist at: \(backupURL.path)")
        
        // Verify file extension
        #expect(backupURL.pathExtension == "reczipes", 
                "Backup file should have .reczipes extension")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    // MARK: - Backup File Naming Tests
    
    @Test("Backup file naming convention is correct")
    @MainActor
    func testBackupFileNaming() async throws {
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let testRecipe = Recipe(from: createMinimalRecipeModel())
        context.insert(testRecipe)
        
        // Create backup
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [testRecipe])
        
        let fileName = backupURL.lastPathComponent
        
        // Should start with "RecipeBackup_"
        #expect(fileName.hasPrefix("RecipeBackup_"), 
                "Backup filename should start with 'RecipeBackup_', got: \(fileName)")
        
        // Should contain a date in YYYY-MM-DD format
        let datePattern = #/\d{4}-\d{2}-\d{2}/#
        #expect(fileName.contains(datePattern), 
                "Backup filename should contain date in YYYY-MM-DD format")
        
        // Should contain a time in HHmmss format
        let timePattern = #/\d{6}/#
        #expect(fileName.contains(timePattern), 
                "Backup filename should contain time in HHmmss format")
        
        // Should contain milliseconds (3 digits) for uniqueness
        let millisPattern = #/_\d{3}\.reczipes/#
        #expect(fileName.contains(millisPattern), 
                "Backup filename should contain milliseconds for uniqueness")
        
        // Should end with .reczipes
        #expect(fileName.hasSuffix(".reczipes"), 
                "Backup filename should end with .reczipes")
        
        // Example: RecipeBackup_2026-01-05_143022_123.reczipes
        print("✓ Created backup with valid filename: \(fileName)")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    @Test("BackupFileInfo display name removes prefix and extension")
    @MainActor
    func testBackupFileInfoDisplayName() {
        // Test with new format (with milliseconds)
        let url1 = getBackupDirectory().appendingPathComponent("RecipeBackup_2026-01-05_143022_123.reczipes")
        let backupInfo1 = BackupFileInfo(
            url: url1,
            fileName: "RecipeBackup_2026-01-05_143022_123.reczipes",
            fileSize: 12345,
            creationDate: Date(),
            modificationDate: Date()
        )
        
        #expect(backupInfo1.displayName == "2026-01-05_143022", 
                "Display name should remove 'RecipeBackup_' prefix, milliseconds, and '.reczipes' extension, got: \(backupInfo1.displayName)")
        
        // Test with old format (without milliseconds) for backward compatibility
        let url2 = getBackupDirectory().appendingPathComponent("RecipeBackup_2026-01-05_143022.reczipes")
        let backupInfo2 = BackupFileInfo(
            url: url2,
            fileName: "RecipeBackup_2026-01-05_143022.reczipes",
            fileSize: 12345,
            creationDate: Date(),
            modificationDate: Date()
        )
        
        #expect(backupInfo2.displayName == "2026-01-05_143022", 
                "Display name should work with old format too")
        
        #expect(backupInfo1.fileSizeFormatted.contains("KB") || backupInfo1.fileSizeFormatted.contains("bytes"), 
                "File size should be formatted with units")
        
        print("✓ Display name (new format): \(backupInfo1.displayName)")
        print("✓ Display name (old format): \(backupInfo2.displayName)")
        print("✓ Formatted size: \(backupInfo1.fileSizeFormatted)")
    }
    
    // MARK: - Backup Listing Tests
    
    @Test("listAvailableBackups finds backups in Reczipes2 folder")
    @MainActor
    func testListAvailableBackups() async throws {
        // Create test backup files
        let backupDir = getBackupDirectory()
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        // Create a test recipe
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let testRecipe = Recipe(from: createMinimalRecipeModel())
        context.insert(testRecipe)
        
        // Create multiple backups
        let backup1URL = try await RecipeBackupManager.shared.createBackup(from: [testRecipe])
        
        // Wait a moment to ensure different timestamps
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let backup2URL = try await RecipeBackupManager.shared.createBackup(from: [testRecipe])
        
        // List available backups
        let availableBackups = try RecipeBackupManager.shared.listAvailableBackups()
        
        // Should find both backups
        #expect(availableBackups.count >= 2, 
                "Should find at least 2 backups, found: \(availableBackups.count)")
        
        // Backups should be sorted by modification date (most recent first)
        if availableBackups.count >= 2 {
            let firstDate = availableBackups[0].modificationDate
            let secondDate = availableBackups[1].modificationDate
            #expect(firstDate >= secondDate, 
                    "Backups should be sorted by modification date (newest first)")
        }
        
        // Verify backup info is populated
        for backup in availableBackups.prefix(2) {
            #expect(backup.fileSize > 0, "Backup file size should be greater than 0")
            #expect(!backup.fileName.isEmpty, "Backup filename should not be empty")
            #expect(!backup.displayName.isEmpty, "Backup display name should not be empty")
            #expect(!backup.fileSizeFormatted.isEmpty, "Backup formatted file size should not be empty")
            
            print("✓ Found backup: \(backup.displayName) - \(backup.fileSizeFormatted)")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: backup1URL)
        try? FileManager.default.removeItem(at: backup2URL)
    }
    
    @Test("listAvailableBackups returns empty array when no backups exist")
    @MainActor
    func testListAvailableBackupsEmpty() throws {
        let backupDir = getBackupDirectory()
        
        // Remove all .reczipes files
        if FileManager.default.fileExists(atPath: backupDir.path) {
            let contents = try FileManager.default.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: nil)
            for file in contents where file.pathExtension == "reczipes" {
                try? FileManager.default.removeItem(at: file)
            }
        }
        
        let availableBackups = try RecipeBackupManager.shared.listAvailableBackups()
        
        #expect(availableBackups.isEmpty, "Should return empty array when no backups exist")
        print("✓ Correctly returns empty array when no backups found")
    }
    
    @Test("listAvailableBackups handles missing directory gracefully")
    @MainActor
    func testListAvailableBackupsMissingDirectory() throws {
        let backupDir = getBackupDirectory()
        
        // Remove directory if it exists
        if FileManager.default.fileExists(atPath: backupDir.path) {
            try? FileManager.default.removeItem(at: backupDir)
        }
        
        // Should not throw, should return empty array
        let availableBackups = try RecipeBackupManager.shared.listAvailableBackups()
        
        #expect(availableBackups.isEmpty, 
                "Should return empty array when directory doesn't exist")
        print("✓ Gracefully handles missing directory")
    }
    
    // MARK: - Backup Creation Tests
    
    @Test("Creating backup with no recipes throws error")
    @MainActor
    func testCreateBackupNoRecipes() async {
        do {
            _ = try await RecipeBackupManager.shared.createBackup(from: [])
            #expect(Bool(false), "Should throw RecipeBackupError.noRecipesToBackup")
        } catch RecipeBackupError.noRecipesToBackup {
            print("✓ Correctly throws noRecipesToBackup error when recipe array is empty")
        } catch {
            #expect(Bool(false), "Should throw RecipeBackupError.noRecipesToBackup, but threw: \(error)")
        }
    }
    
    @Test("Creating backup with single recipe succeeds")
    @MainActor
    func testCreateBackupSingleRecipe() async throws {
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let testRecipe = Recipe(from: createCompleteRecipeModel())
        context.insert(testRecipe)
        
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [testRecipe])
        
        #expect(FileManager.default.fileExists(atPath: backupURL.path), 
                "Backup file should exist after creation")
        
        // Verify file size is reasonable
        let attributes = try FileManager.default.attributesOfItem(atPath: backupURL.path)
        let fileSize = attributes[.size] as? Int ?? 0
        #expect(fileSize > 0, "Backup file should have content")
        #expect(fileSize < 10_000_000, "Single recipe backup should be under 10MB")
        
        print("✓ Successfully created backup for single recipe: \(fileSize) bytes")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    @Test("Creating backup with multiple recipes succeeds")
    @MainActor
    func testCreateBackupMultipleRecipes() async throws {
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let recipes = [
            Recipe(from: createCompleteRecipeModel()),
            Recipe(from: createMinimalRecipeModel()),
            Recipe(from: createCompleteRecipeModel())
        ]
        
        for recipe in recipes {
            context.insert(recipe)
        }
        
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: recipes)
        
        #expect(FileManager.default.fileExists(atPath: backupURL.path), 
                "Backup file should exist after creation")
        
        // Verify backup can be read and contains correct number of recipes
        let data = try Data(contentsOf: backupURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let package = try decoder.decode(RecipeBackupPackage.self, from: data)
        
        #expect(package.recipeCount == 3, 
                "Backup should contain 3 recipes, found: \(package.recipeCount)")
        
        print("✓ Successfully created backup for \(package.recipeCount) recipes")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    @Test("Backup file is valid JSON and can be decoded")
    @MainActor
    func testBackupFileIsValidJSON() async throws {
        let schema = Schema([Recipe.self, RecipeBook.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let testRecipe = Recipe(from: createCompleteRecipeModel())
        context.insert(testRecipe)
        
        let backupURL = try await RecipeBackupManager.shared.createBackup(from: [testRecipe])
        
        // Read and decode
        let data = try Data(contentsOf: backupURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let package = try decoder.decode(RecipeBackupPackage.self, from: data)
        
        #expect(!package.recipes.isEmpty, "Backup package should contain recipes")
        #expect(!package.version.isEmpty, "Backup package should have version")
        #expect(!package.exportDate.description.isEmpty, "Backup package should have export date")
        
        print("✓ Backup file is valid JSON")
        print("✓ Package version: \(package.version)")
        print("✓ Export date: \(package.exportDate)")
        
        // Cleanup
        try? FileManager.default.removeItem(at: backupURL)
    }
}
