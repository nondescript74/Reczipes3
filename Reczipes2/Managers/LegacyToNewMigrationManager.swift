//
//  LegacyToNewMigrationManager.swift
//  Reczipes2
//
//  Created on 1/27/26.
//
//  Handles one-time migration from legacy Recipe and RecipeBook models
//  to new RecipeX and Book models with automatic CloudKit sync.
//
//  MIGRATION STRATEGY:
//  1. Copy all Recipe → RecipeX (preserve IDs for book references)
//  2. Copy all RecipeBook → Book (preserve recipe references)
//  3. Keep legacy models for safety (optional delete later)
//  4. Mark new models for CloudKit sync
//  5. Validate migration success

import Foundation
import SwiftData
import OSLog

/// Manages one-time migration from legacy models to new unified models
@MainActor
class LegacyToNewMigrationManager {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.reczipes2", category: "LegacyMigration")
    
    /// User defaults key for tracking migration status
    private static let migrationCompletedKey = "com.reczipes2.legacyMigrationCompleted"
    private static let migrationDateKey = "com.reczipes2.legacyMigrationDate"
    private static let migrationVersionKey = "com.reczipes2.legacyMigrationVersion"
    
    private let currentMigrationVersion = 1
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Migration Status
    
    /// Check if migration has been completed
    var isMigrationCompleted: Bool {
        UserDefaults.standard.bool(forKey: Self.migrationCompletedKey)
    }
    
    /// Get the date when migration was completed
    var migrationDate: Date? {
        UserDefaults.standard.object(forKey: Self.migrationDateKey) as? Date
    }
    
    /// Get the version of the migration that was completed
    var migrationVersion: Int {
        UserDefaults.standard.integer(forKey: Self.migrationVersionKey)
    }
    
    /// Check if migration is needed
    func needsMigration() async -> Bool {
        // If migration already completed, no need to run again
        if isMigrationCompleted {
            logger.info("Migration already completed on \(self.migrationDate?.description ?? "unknown date")")
            return false
        }
        
        // Check if there are any legacy recipes or books
        do {
            let recipeDescriptor = FetchDescriptor<Recipe>()
            let recipes = try modelContext.fetch(recipeDescriptor)
            
            let bookDescriptor = FetchDescriptor<RecipeBook>()
            let books = try modelContext.fetch(bookDescriptor)
            
            let hasLegacyData = !recipes.isEmpty || !books.isEmpty
            
            if hasLegacyData {
                logger.info("Migration needed: \(recipes.count) recipes, \(books.count) books")
            } else {
                logger.info("No legacy data found - migration not needed")
            }
            
            return hasLegacyData
            
        } catch {
            logger.error("Failed to check migration status: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Get migration statistics
    func getMigrationStats() async -> MigrationStats {
        do {
            let recipeDescriptor = FetchDescriptor<Recipe>()
            let recipes = try modelContext.fetch(recipeDescriptor)
            
            let recipeXDescriptor = FetchDescriptor<RecipeX>()
            let recipesX = try modelContext.fetch(recipeXDescriptor)
            
            let bookDescriptor = FetchDescriptor<RecipeBook>()
            let books = try modelContext.fetch(bookDescriptor)
            
            let newBookDescriptor = FetchDescriptor<Book>()
            let newBooks = try modelContext.fetch(newBookDescriptor)
            
            return MigrationStats(
                legacyRecipeCount: recipes.count,
                legacyBookCount: books.count,
                migratedRecipeCount: recipesX.count,
                migratedBookCount: newBooks.count
            )
            
        } catch {
            logger.error("Failed to get migration stats: \(error.localizedDescription)")
            return MigrationStats(
                legacyRecipeCount: 0,
                legacyBookCount: 0,
                migratedRecipeCount: 0,
                migratedBookCount: 0
            )
        }
    }
    
    // MARK: - Migration Execution
    
    /// Perform full migration from legacy to new models
    /// 
    /// - Parameters:
    ///   - deleteLegacyData: Whether to delete legacy models after successful migration (default: false for safety)
    ///   - skipCloudSync: Skip marking models for CloudKit sync (useful for testing)
    /// - Returns: Migration result with success/error details
    func performMigration(
        deleteLegacyData: Bool = false,
        skipCloudSync: Bool = false
    ) async throws -> MigrationResult {
        logger.info("🚀 Starting legacy to new migration (version \(self.currentMigrationVersion))...")
        
        var result = MigrationResult()
        let startTime = Date()
        
        // Step 1: Migrate Recipes → RecipeX
        do {
            let (migrated, skipped) = try await migrateRecipes(skipCloudSync: skipCloudSync)
            result.recipesSuccess = migrated
            result.recipesSkipped = skipped
            logger.info("✅ Migrated \(migrated) recipes, skipped \(skipped) duplicates")
        } catch {
            logger.error("❌ Recipe migration failed: \(error.localizedDescription)")
            result.recipesError = error
            // Don't continue if recipe migration fails (books depend on recipe IDs)
            throw error
        }
        
        // Step 2: Migrate RecipeBooks → Book
        do {
            let (migrated, skipped) = try await migrateBooks(skipCloudSync: skipCloudSync)
            result.booksSuccess = migrated
            result.booksSkipped = skipped
            logger.info("✅ Migrated \(migrated) books, skipped \(skipped) duplicates")
        } catch {
            logger.error("❌ Book migration failed: \(error.localizedDescription)")
            result.booksError = error
            // Continue even if book migration fails - recipes are more important
        }
        
        // Step 3: Save all changes
        do {
            try modelContext.save()
            logger.info("💾 Saved migration changes to SwiftData")
        } catch {
            logger.error("❌ Failed to save migration: \(error.localizedDescription)")
            throw error
        }
        
        // Step 4: Validate migration
        do {
            let validation = try await validateMigration()
            result.validation = validation
            
            if !validation.isValid {
                logger.warning("⚠️ Migration validation failed: \(validation.errors.joined(separator: ", "))")
            } else if validation.hasWarnings {
                logger.warning("⚠️ Migration completed with warnings: \(validation.warnings.joined(separator: ", "))")
            }
        } catch {
            logger.error("❌ Migration validation failed: \(error.localizedDescription)")
        }
        
        // Step 5: Optionally delete legacy data
        if deleteLegacyData && result.isSuccess {
            do {
                try await deleteLegacyModels()
                result.legacyDataDeleted = true
                logger.info("🗑️ Deleted legacy data after successful migration")
            } catch {
                logger.error("❌ Failed to delete legacy data: \(error.localizedDescription)")
                result.deletionError = error
                // Don't fail migration if cleanup fails
            }
        }
        
        // Step 6: Mark migration as completed
        if result.isSuccess {
            markMigrationCompleted()
            let duration = Date().timeIntervalSince(startTime)
            logger.info("✅ Migration completed successfully in \(String(format: "%.2f", duration))s")
        } else {
            logger.error("❌ Migration failed: \(result.errorSummary)")
        }
        
        return result
    }
    
    // MARK: - Recipe Migration
    
    /// Migrate all Recipe models to RecipeX
    private func migrateRecipes(skipCloudSync: Bool) async throws -> (migrated: Int, skipped: Int) {
        let descriptor = FetchDescriptor<Recipe>()
        let recipes = try modelContext.fetch(descriptor)
        
        logger.info("📦 Migrating \(recipes.count) recipes...")
        
        var migrated = 0
        var skipped = 0
        
        for recipe in recipes {
            // Check if RecipeX with this ID already exists
            let recipeID = recipe.id  // Capture the ID value
            let predicate = #Predicate<RecipeX> { recipeX in
                recipeX.id == recipeID
            }
            let recipeXDescriptor = FetchDescriptor<RecipeX>(predicate: predicate)
            let existingRecipes = try modelContext.fetch(recipeXDescriptor)
            
            if !existingRecipes.isEmpty {
                logger.debug("⏭️ Skipping recipe '\(recipe.title)' - already exists as RecipeX")
                skipped += 1
                continue
            }
            
            // Create new RecipeX from Recipe
            let recipeX = RecipeX(from: recipe)
            
            // Mark for CloudKit sync unless skipped
            if !skipCloudSync {
                recipeX.needsCloudSync = true
                recipeX.ownerUserID = CloudKitSharingService.shared.currentUserID
                recipeX.ownerDisplayName = CloudKitSharingService.shared.currentUserName
            }
            
            // Insert into context
            modelContext.insert(recipeX)
            migrated += 1
            
            if migrated % 10 == 0 {
                logger.debug("Progress: \(migrated)/\(recipes.count) recipes")
            }
        }
        
        return (migrated, skipped)
    }
    
    // MARK: - Book Migration
    
    /// Migrate all RecipeBook models to Book
    private func migrateBooks(skipCloudSync: Bool) async throws -> (migrated: Int, skipped: Int) {
        let descriptor = FetchDescriptor<RecipeBook>()
        let books = try modelContext.fetch(descriptor)
        
        logger.info("📚 Migrating \(books.count) books...")
        
        var migrated = 0
        var skipped = 0
        
        for book in books {
            // Check if Book with this ID already exists
            let bookID = book.id  // Capture the ID value
            let predicate = #Predicate<Book> { newBook in
                newBook.id == bookID
            }
            let bookDescriptor = FetchDescriptor<Book>(predicate: predicate)
            let existingBooks = try modelContext.fetch(bookDescriptor)
            
            if !existingBooks.isEmpty {
                logger.debug("⏭️ Skipping book '\(book.name)' - already exists as Book")
                skipped += 1
                continue
            }
            
            // Create new Book from RecipeBook
            let newBook = Book(from: book)
            
            // Mark for CloudKit sync unless skipped
            if !skipCloudSync {
                newBook.needsCloudSync = true
                newBook.ownerUserID = CloudKitSharingService.shared.currentUserID
                newBook.ownerDisplayName = CloudKitSharingService.shared.currentUserName
            }
            
            // Insert into context
            modelContext.insert(newBook)
            migrated += 1
        }
        
        return (migrated, skipped)
    }
    
    // MARK: - Validation
    
    /// Validate migration integrity
    private func validateMigration() async throws -> MigrationValidation {
        var validation = MigrationValidation()
        
        // Check recipes
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let recipes = try modelContext.fetch(recipeDescriptor)
        
        let recipeXDescriptor = FetchDescriptor<RecipeX>()
        let recipesX = try modelContext.fetch(recipeXDescriptor)
        
        // Check if all recipes were migrated
        let recipeIDs = Set(recipes.map { $0.id })
        let recipeXIDs = Set(recipesX.compactMap { $0.id })
        
        let unmigrated = recipeIDs.subtracting(recipeXIDs)
        if !unmigrated.isEmpty {
            validation.errors.append("❌ \(unmigrated.count) recipes not migrated")
        }
        
        // Check for duplicate RecipeX IDs
        let recipeXIDArray = recipesX.compactMap { $0.id }
        if recipeXIDArray.count != Set(recipeXIDArray).count {
            validation.errors.append("❌ Duplicate RecipeX IDs detected")
        }
        
        // Check books
        let bookDescriptor = FetchDescriptor<RecipeBook>()
        let books = try modelContext.fetch(bookDescriptor)
        
        let newBookDescriptor = FetchDescriptor<Book>()
        let newBooks = try modelContext.fetch(newBookDescriptor)
        
        // Check if all books were migrated
        let bookIDs = Set(books.map { $0.id })
        let newBookIDs = Set(newBooks.compactMap { $0.id })
        
        let unmigratedBooks = bookIDs.subtracting(newBookIDs)
        if !unmigratedBooks.isEmpty {
            validation.warnings.append("⚠️ \(unmigratedBooks.count) books not migrated")
        }
        
        // Check for missing data
        for recipeX in recipesX {
            if recipeX.id == nil {
                validation.errors.append("❌ RecipeX with nil ID found")
            }
            if recipeX.title?.isEmpty ?? true {
                validation.warnings.append("⚠️ RecipeX \(recipeX.id?.uuidString ?? "unknown") has no title")
            }
        }
        
        for book in newBooks {
            if book.id == nil {
                validation.errors.append("❌ Book with nil ID found")
            }
            if book.name?.isEmpty ?? true {
                validation.warnings.append("⚠️ Book \(book.id?.uuidString ?? "unknown") has no name")
            }
        }
        
        validation.isValid = validation.errors.isEmpty
        return validation
    }
    
    // MARK: - Cleanup
    
    /// Delete legacy Recipe and RecipeBook models after successful migration
    /// USE WITH CAUTION - This is irreversible
    private func deleteLegacyModels() async throws {
        logger.warning("🗑️ Deleting legacy models...")
        
        // Delete all Recipe models
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let recipes = try modelContext.fetch(recipeDescriptor)
        for recipe in recipes {
            modelContext.delete(recipe)
        }
        logger.info("Deleted \(recipes.count) Recipe models")
        
        // Delete all RecipeBook models
        let bookDescriptor = FetchDescriptor<RecipeBook>()
        let books = try modelContext.fetch(bookDescriptor)
        for book in books {
            modelContext.delete(book)
        }
        logger.info("Deleted \(books.count) RecipeBook models")
        
        // Save deletion
        try modelContext.save()
    }
    
    // MARK: - Migration Tracking
    
    /// Mark migration as completed
    private func markMigrationCompleted() {
        UserDefaults.standard.set(true, forKey: Self.migrationCompletedKey)
        UserDefaults.standard.set(Date(), forKey: Self.migrationDateKey)
        UserDefaults.standard.set(currentMigrationVersion, forKey: Self.migrationVersionKey)
    }
    
    /// Reset migration status (for testing or re-running migration)
    func resetMigrationStatus() {
        UserDefaults.standard.removeObject(forKey: Self.migrationCompletedKey)
        UserDefaults.standard.removeObject(forKey: Self.migrationDateKey)
        UserDefaults.standard.removeObject(forKey: Self.migrationVersionKey)
        logger.info("🔄 Migration status reset")
    }
    
    // MARK: - Manual Migration
    
    /// Migrate a single recipe manually
    func migrateRecipe(_ recipe: Recipe) async throws -> RecipeX {
        let recipeX = RecipeX(from: recipe)
        recipeX.needsCloudSync = true
        recipeX.ownerUserID = CloudKitSharingService.shared.currentUserID
        recipeX.ownerDisplayName = CloudKitSharingService.shared.currentUserName
        
        modelContext.insert(recipeX)
        try modelContext.save()
        
        logger.info("✅ Manually migrated recipe: \(recipe.title)")
        return recipeX
    }
    
    /// Migrate a single book manually
    func migrateBook(_ book: RecipeBook) async throws -> Book {
        let newBook = Book(from: book)
        newBook.needsCloudSync = true
        newBook.ownerUserID = CloudKitSharingService.shared.currentUserID
        newBook.ownerDisplayName = CloudKitSharingService.shared.currentUserName
        
        modelContext.insert(newBook)
        try modelContext.save()
        
        logger.info("✅ Manually migrated book: \(book.name)")
        return newBook
    }
}

// MARK: - Supporting Types

/// Statistics about legacy and migrated data
struct MigrationStats {
    let legacyRecipeCount: Int
    let legacyBookCount: Int
    let migratedRecipeCount: Int
    let migratedBookCount: Int
    
    var totalLegacyItems: Int {
        legacyRecipeCount + legacyBookCount
    }
    
    var totalMigratedItems: Int {
        migratedRecipeCount + migratedBookCount
    }
    
    var recipesMigrationProgress: Double {
        guard legacyRecipeCount > 0 else { return 1.0 }
        return Double(migratedRecipeCount) / Double(legacyRecipeCount)
    }
    
    var booksMigrationProgress: Double {
        guard legacyBookCount > 0 else { return 1.0 }
        return Double(migratedBookCount) / Double(legacyBookCount)
    }
    
    var overallProgress: Double {
        guard totalLegacyItems > 0 else { return 1.0 }
        return Double(totalMigratedItems) / Double(totalLegacyItems)
    }
    
    var summary: String {
        """
        Legacy Data:
        - Recipes: \(legacyRecipeCount)
        - Books: \(legacyBookCount)
        
        Migrated Data:
        - Recipes: \(migratedRecipeCount)
        - Books: \(migratedBookCount)
        
        Progress: \(String(format: "%.0f%%", overallProgress * 100))
        """
    }
}

/// Result of migration operation
struct MigrationResult {
    var recipesSuccess: Int = 0
    var recipesSkipped: Int = 0
    var recipesError: Error?
    
    var booksSuccess: Int = 0
    var booksSkipped: Int = 0
    var booksError: Error?
    
    var validation: MigrationValidation?
    
    var legacyDataDeleted: Bool = false
    var deletionError: Error?
    
    var totalSuccess: Int {
        recipesSuccess + booksSuccess
    }
    
    var totalSkipped: Int {
        recipesSkipped + booksSkipped
    }
    
    var hasErrors: Bool {
        recipesError != nil || booksError != nil || deletionError != nil
    }
    
    var isSuccess: Bool {
        !hasErrors && totalSuccess > 0
    }
    
    var errorSummary: String {
        var errors: [String] = []
        if let error = recipesError {
            errors.append("Recipes: \(error.localizedDescription)")
        }
        if let error = booksError {
            errors.append("Books: \(error.localizedDescription)")
        }
        if let error = deletionError {
            errors.append("Deletion: \(error.localizedDescription)")
        }
        return errors.isEmpty ? "No errors" : errors.joined(separator: "; ")
    }
    
    var summary: String {
        var lines: [String] = []
        
        lines.append("Migration Results:")
        lines.append("━━━━━━━━━━━━━━━━")
        lines.append("✅ Recipes: \(recipesSuccess) migrated, \(recipesSkipped) skipped")
        lines.append("✅ Books: \(booksSuccess) migrated, \(booksSkipped) skipped")
        
        if hasErrors {
            lines.append("")
            lines.append("❌ Errors:")
            lines.append(errorSummary)
        }
        
        if let validation = validation {
            lines.append("")
            lines.append("Validation: \(validation.summary)")
        }
        
        if legacyDataDeleted {
            lines.append("")
            lines.append("🗑️ Legacy data deleted")
        }
        
        return lines.joined(separator: "\n")
    }
}

/// Validation result
struct MigrationValidation {
    var isValid: Bool = true
    var errors: [String] = []
    var warnings: [String] = []
    
    var hasWarnings: Bool {
        !warnings.isEmpty
    }
    
    var summary: String {
        if isValid && !hasWarnings {
            return "✓ All checks passed"
        } else if isValid && hasWarnings {
            return "✓ Passed with \(warnings.count) warning(s)"
        } else {
            return "✗ Failed with \(errors.count) error(s)"
        }
    }
    
    var detailedSummary: String {
        var lines: [String] = []
        
        if !errors.isEmpty {
            lines.append("Errors:")
            lines.append(contentsOf: errors)
        }
        
        if !warnings.isEmpty {
            if !lines.isEmpty { lines.append("") }
            lines.append("Warnings:")
            lines.append(contentsOf: warnings)
        }
        
        if lines.isEmpty {
            return "All validation checks passed ✓"
        }
        
        return lines.joined(separator: "\n")
    }
}

// MARK: - Migration Error

enum MigrationError: LocalizedError {
    case fetchFailed(Error)
    case saveFailed(Error)
    case validationFailed([String])
    case partialFailure(recipes: Error?, books: Error?)
    case alreadyCompleted
    case noDataToMigrate
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save migrated data: \(error.localizedDescription)"
        case .validationFailed(let errors):
            return "Migration validation failed: \(errors.joined(separator: ", "))"
        case .partialFailure(let recipesError, let booksError):
            var message = "Partial migration failure:"
            if let rError = recipesError {
                message += " Recipes: \(rError.localizedDescription);"
            }
            if let bError = booksError {
                message += " Books: \(bError.localizedDescription)"
            }
            return message
        case .alreadyCompleted:
            return "Migration has already been completed"
        case .noDataToMigrate:
            return "No legacy data found to migrate"
        }
    }
}
