//
//  BookMigrationManager.swift
//  Reczipes2
//
//  Created on 1/26/26.
//
//  Handles migration from RecipeBook, SharedRecipeBook, and CloudKit book models
//  to the unified Book model.

import Foundation
import SwiftData
import OSLog

/// Manages migration from legacy book models to unified Book model
@MainActor
class BookMigrationManager {
    
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.reczipes2", category: "BookMigration")
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Migration Status
    
    /// Check if migration is needed
    func needsMigration() -> Bool {
        do {
            let recipeBookDescriptor = FetchDescriptor<RecipeBook>()
            let recipeBooks = try modelContext.fetch(recipeBookDescriptor)
            
            let sharedBookDescriptor = FetchDescriptor<SharedRecipeBook>()
            let sharedBooks = try modelContext.fetch(sharedBookDescriptor)
            
            let bookDescriptor = FetchDescriptor<Book>()
            let books = try modelContext.fetch(bookDescriptor)
            
            // Migration needed if there are legacy books but no new books
            let hasLegacyBooks = !recipeBooks.isEmpty || !sharedBooks.isEmpty
            let hasNewBooks = !books.isEmpty
            
            return hasLegacyBooks && !hasNewBooks
            
        } catch {
            logger.error("Failed to check migration status: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Get migration statistics
    func getMigrationStats() -> BookMigrationStats {
        do {
            let recipeBookDescriptor = FetchDescriptor<RecipeBook>()
            let recipeBooks = try modelContext.fetch(recipeBookDescriptor)
            
            let sharedBookDescriptor = FetchDescriptor<SharedRecipeBook>()
            let sharedBooks = try modelContext.fetch(sharedBookDescriptor)
            
            let bookDescriptor = FetchDescriptor<Book>()
            let books = try modelContext.fetch(bookDescriptor)
            
            return BookMigrationStats(
                recipeBookCount: recipeBooks.count,
                sharedRecipeBookCount: sharedBooks.count,
                migratedBookCount: books.count,
                totalRecipesInBooks: recipeBooks.reduce(0) { $0 + $1.recipeCount }
            )
            
        } catch {
            logger.error("Failed to get migration stats: \(error.localizedDescription)")
            return BookMigrationStats(recipeBookCount: 0, sharedRecipeBookCount: 0, migratedBookCount: 0, totalRecipesInBooks: 0)
        }
    }
    
    // MARK: - Migration Execution
    
    /// Perform full migration
    func performMigration(deleteOldRecords: Bool = false) async throws -> BookMigrationResult {
        logger.info("Starting book migration...")
        
        var result = BookMigrationResult()
        
        // Migrate RecipeBook models
        do {
            let migrated = try await migrateRecipeBooks()
            result.recipeBooksSuccess = migrated
            logger.info("Migrated \(migrated) RecipeBooks")
        } catch {
            logger.error("RecipeBook migration failed: \(error.localizedDescription)")
            result.recipeBooksError = error
        }
        
        // Migrate SharedRecipeBook models
        do {
            let migrated = try await migrateSharedRecipeBooks()
            result.sharedRecipeBooksSuccess = migrated
            logger.info("Migrated \(migrated) SharedRecipeBooks")
        } catch {
            logger.error("SharedRecipeBook migration failed: \(error.localizedDescription)")
            result.sharedRecipeBooksError = error
        }
        
        // Save all changes
        try modelContext.save()
        
        // Optionally delete old records
        if deleteOldRecords {
            try await deleteOldBookRecords()
            logger.info("Deleted old book records")
        }
        
        logger.info("Migration complete: \(result.totalSuccess) books migrated")
        return result
    }
    
    /// Migrate all RecipeBook models to Book
    private func migrateRecipeBooks() async throws -> Int {
        let descriptor = FetchDescriptor<RecipeBook>()
        let recipeBooks = try modelContext.fetch(descriptor)
        
        var count = 0
        for recipeBook in recipeBooks {
            let book = Book(from: recipeBook)
            modelContext.insert(book)
            count += 1
        }
        
        return count
    }
    
    /// Migrate all SharedRecipeBook models to Book
    private func migrateSharedRecipeBooks() async throws -> Int {
        let descriptor = FetchDescriptor<SharedRecipeBook>()
        let sharedBooks = try modelContext.fetch(descriptor)
        
        var count = 0
        for sharedBook in sharedBooks {
            // Check if we already have a Book with this ID (from RecipeBook migration)
            if let bookID = sharedBook.bookID {
                let predicate = #Predicate<Book> { book in
                    book.id == bookID
                }
                let bookDescriptor = FetchDescriptor<Book>(predicate: predicate)
                
                if let existingBook = try modelContext.fetch(bookDescriptor).first {
                    // Update existing book with shared metadata
                    existingBook.cloudRecordID = sharedBook.cloudRecordID
                    existingBook.ownerUserID = sharedBook.sharedByUserID
                    existingBook.ownerDisplayName = sharedBook.sharedByUserName
                    existingBook.sharedDate = sharedBook.sharedDate
                    existingBook.isShared = sharedBook.isActive
                    existingBook.isImported = false // User shared this book
                    continue
                }
            }
            
            // Create new book from shared book (imported from another user)
            let book = Book(from: sharedBook, isImported: true)
            modelContext.insert(book)
            count += 1
        }
        
        return count
    }
    
    /// Delete old book records after successful migration
    private func deleteOldBookRecords() async throws {
        // Delete RecipeBooks
        let recipeBookDescriptor = FetchDescriptor<RecipeBook>()
        let recipeBooks = try modelContext.fetch(recipeBookDescriptor)
        for recipeBook in recipeBooks {
            modelContext.delete(recipeBook)
        }
        
        // Delete SharedRecipeBooks
        let sharedBookDescriptor = FetchDescriptor<SharedRecipeBook>()
        let sharedBooks = try modelContext.fetch(sharedBookDescriptor)
        for sharedBook in sharedBooks {
            modelContext.delete(sharedBook)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Individual Book Migration
    
    /// Migrate a single RecipeBook
    func migrateRecipeBook(_ recipeBook: RecipeBook) throws -> Book {
        let book = Book(from: recipeBook)
        modelContext.insert(book)
        try modelContext.save()
        return book
    }
    
    /// Migrate a single SharedRecipeBook
    func migrateSharedRecipeBook(_ sharedBook: SharedRecipeBook) throws -> Book {
        let book = Book(from: sharedBook, isImported: true)
        modelContext.insert(book)
        try modelContext.save()
        return book
    }
    
    // MARK: - Rollback
    
    /// Rollback migration (convert Books back to RecipeBooks)
    /// USE WITH CAUTION - Will lose data that doesn't fit in old model
    func rollbackMigration() async throws -> Int {
        logger.warning("Rolling back book migration - some data may be lost!")
        
        let bookDescriptor = FetchDescriptor<Book>()
        let books = try modelContext.fetch(bookDescriptor)
        
        var count = 0
        for book in books {
            // Convert Book back to RecipeBook (loses some data)
            let recipeBook = RecipeBook(
                id: book.id ?? UUID(),
                name: book.name ?? "",
                bookDescription: book.bookDescription,
                coverImageName: book.coverImageName,
                coverImageData: book.coverImageData,
                dateCreated: book.dateCreated ?? Date(),
                dateModified: book.dateModified ?? Date(),
                recipeIDs: book.recipeIDs ?? [],
                color: book.color
            )
            modelContext.insert(recipeBook)
            
            // If book was shared, create SharedRecipeBook record
            if book.isShared == true || book.cloudRecordID != nil {
                let sharedBook = SharedRecipeBook(
                    bookID: book.id ?? UUID(),
                    cloudRecordID: book.cloudRecordID,
                    sharedByUserID: book.ownerUserID ?? "",
                    sharedByUserName: book.ownerDisplayName,
                    sharedDate: book.sharedDate ?? Date(),
                    bookName: book.name ?? "",
                    bookDescription: book.bookDescription,
                    coverImageName: book.coverImageName
                )
                modelContext.insert(sharedBook)
            }
            
            // Delete the Book
            modelContext.delete(book)
            count += 1
        }
        
        try modelContext.save()
        logger.info("Rolled back \(count) books")
        return count
    }
}

// MARK: - Supporting Types

/// Statistics about the migration
struct BookMigrationStats {
    let recipeBookCount: Int
    let sharedRecipeBookCount: Int
    let migratedBookCount: Int
    let totalRecipesInBooks: Int
    
    var needsMigration: Bool {
        recipeBookCount > 0 || sharedRecipeBookCount > 0
    }
    
    var totalLegacyBooks: Int {
        recipeBookCount + sharedRecipeBookCount
    }
    
    var migrationProgress: Double {
        guard totalLegacyBooks > 0 else { return 1.0 }
        return Double(migratedBookCount) / Double(totalLegacyBooks)
    }
}

/// Result of migration operation
struct BookMigrationResult {
    var recipeBooksSuccess: Int = 0
    var recipeBooksError: Error?
    
    var sharedRecipeBooksSuccess: Int = 0
    var sharedRecipeBooksError: Error?
    
    var totalSuccess: Int {
        recipeBooksSuccess + sharedRecipeBooksSuccess
    }
    
    var hasErrors: Bool {
        recipeBooksError != nil || sharedRecipeBooksError != nil
    }
    
    var isFullSuccess: Bool {
        !hasErrors && totalSuccess > 0
    }
    
    var summary: String {
        if isFullSuccess {
            return "Successfully migrated \(totalSuccess) books"
        } else if hasErrors {
            var message = "Migrated \(totalSuccess) books with errors:\n"
            if let error = recipeBooksError {
                message += "RecipeBooks: \(error.localizedDescription)\n"
            }
            if let error = sharedRecipeBooksError {
                message += "SharedRecipeBooks: \(error.localizedDescription)"
            }
            return message
        } else {
            return "No books to migrate"
        }
    }
}

// MARK: - Migration Error

enum BookMigrationError: LocalizedError {
    case fetchFailed(Error)
    case saveFailed(Error)
    case invalidBookData(bookID: UUID)
    case duplicateBook(bookID: UUID)
    case missingRequiredData(bookID: UUID, field: String)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch books: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save migrated books: \(error.localizedDescription)"
        case .invalidBookData(let id):
            return "Invalid book data for book ID: \(id.uuidString)"
        case .duplicateBook(let id):
            return "Duplicate book detected during migration: \(id.uuidString)"
        case .missingRequiredData(let id, let field):
            return "Missing required field '\(field)' for book ID: \(id.uuidString)"
        }
    }
}

// MARK: - Migration Helpers

extension BookMigrationManager {
    
    /// Validate migration integrity
    func validateMigration() async throws -> BookMigrationValidation {
        let stats = getMigrationStats()
        
        var validation = BookMigrationValidation()
        
        // Check if all legacy books were migrated
        if stats.totalLegacyBooks > stats.migratedBookCount {
            validation.warnings.append("Not all legacy books were migrated: \(stats.totalLegacyBooks) legacy, \(stats.migratedBookCount) migrated")
        }
        
        // Check for duplicate books
        let bookDescriptor = FetchDescriptor<Book>()
        let books = try modelContext.fetch(bookDescriptor)
        
        let ids = books.compactMap { $0.id }
        let uniqueIDs = Set(ids)
        if ids.count != uniqueIDs.count {
            validation.errors.append("Duplicate book IDs detected")
        }
        
        // Check for books with missing data
        for book in books {
            if book.id == nil {
                validation.errors.append("Book with nil ID found")
            }
            if book.name == nil || book.name?.isEmpty == true {
                validation.warnings.append("Book \(book.id?.uuidString ?? "unknown") has no name")
            }
        }
        
        validation.isValid = validation.errors.isEmpty
        return validation
    }
}

struct BookMigrationValidation {
    var isValid: Bool = true
    var errors: [String] = []
    var warnings: [String] = []
    
    var hasWarnings: Bool {
        !warnings.isEmpty
    }
    
    var summary: String {
        if isValid && !hasWarnings {
            return "Migration validation passed ✓"
        } else if isValid && hasWarnings {
            return "Migration validation passed with \(warnings.count) warning(s)"
        } else {
            return "Migration validation failed with \(errors.count) error(s)"
        }
    }
}
