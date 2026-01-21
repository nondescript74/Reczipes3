//
//  RecipeBookImportService.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 01/02/26.
//

import Foundation
import SwiftData

/// Errors that can occur during recipe book import
enum RecipeBookImportError: LocalizedError {
    case invalidFile
    case decodingFailed(Error)
    case existingBookConflict(String)
    case extractionFailed(Error)
    case imageCopyFailed(Error)
    case saveFailed(Error)
    case unsupportedVersion(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "The selected file is not a valid recipe book."
        case .decodingFailed(let error):
            return "Could not read recipe book: \(error.localizedDescription)"
        case .existingBookConflict(let name):
            return "A book named '\(name)' already exists. Choose how to handle this conflict."
        case .extractionFailed(let error):
            return "Failed to extract recipe book: \(error.localizedDescription)"
        case .imageCopyFailed(let error):
            return "Failed to import images: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save imported book: \(error.localizedDescription)"
        case .unsupportedVersion(let version):
            return "This recipe book version (\(version)) is not supported by this app version."
        }
    }
}

/// Service for importing recipe books shared from other users
@MainActor
class RecipeBookImportService {
    
    static let shared = RecipeBookImportService()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Previews a recipe book file without importing it
    /// - Parameter url: URL to the .recipebook file
    /// - Returns: Information about the book to be imported
    func previewBook(from url: URL) async throws -> RecipeBookExportPackage {
        logInfo("Previewing recipe book from: \(url.lastPathComponent)", category: "book-import")
        
        // Create temporary extraction directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecipeBookPreview_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Extract ZIP
        do {
            try RecipeBookExportService.extractZipArchive(from: url, to: tempDir)
        } catch {
            logError("Failed to extract book for preview: \(error)", category: "book-import")
            throw RecipeBookImportError.extractionFailed(error)
        }
        
        // Read JSON metadata
        let jsonURL = tempDir.appendingPathComponent("book.json")
        
        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            logError("book.json not found in archive", category: "book-import")
            throw RecipeBookImportError.invalidFile
        }
        
        let jsonData = try Data(contentsOf: jsonURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let exportPackage = try decoder.decode(RecipeBookExportPackage.self, from: jsonData)
            
            // Validate version
            if !isSupportedVersion(exportPackage.version) {
                throw RecipeBookImportError.unsupportedVersion(exportPackage.version)
            }
            
            logInfo("Preview loaded: \(exportPackage.book.name) - \(exportPackage.summary)", category: "book-import")
            return exportPackage
        } catch let error as RecipeBookImportError {
            throw error
        } catch {
            logError("Failed to decode book metadata: \(error)", category: "book-import")
            throw RecipeBookImportError.decodingFailed(error)
        }
    }
    
    /// Checks if a book with the same ID already exists
    /// - Parameters:
    ///   - bookID: The ID of the book to check
    ///   - modelContext: SwiftData model context
    /// - Returns: The existing book if found, nil otherwise
    func checkForExistingBook(bookID: UUID, modelContext: ModelContext) throws -> RecipeBook? {
        let descriptor = FetchDescriptor<RecipeBook>(
            predicate: #Predicate { book in
                book.id == bookID
            }
        )
        
        let existingBooks = try modelContext.fetch(descriptor)
        return existingBooks.first
    }
    
    /// Imports a recipe book with the specified import mode
    /// - Parameters:
    ///   - url: URL to the .recipebook file
    ///   - modelContext: SwiftData model context
    ///   - importMode: How to handle conflicts with existing books
    /// - Returns: Result information about the import
    func importBook(
        from url: URL,
        modelContext: ModelContext,
        importMode: RecipeBookImportMode = .keepBoth
    ) async throws -> RecipeBookImportResult {
        logInfo("Starting import with mode: \(importMode.description)", category: "book-import")
        
        // First, preview the book to get its metadata
        let exportPackage = try await previewBook(from: url)
        
        // Check for existing book
        let existingBook = try checkForExistingBook(bookID: exportPackage.book.id, modelContext: modelContext)
        
        var recipesImported = 0
        var recipesUpdated = 0
        var imagesImported = 0
        var wasReplaced = false
        
        // Handle import based on mode
        let importedBook: RecipeBook
        
        switch importMode {
        case .replace:
            if let existing = existingBook {
                wasReplaced = true
                // Delete existing book and all its recipes
                modelContext.delete(existing)
                logInfo("Deleted existing book: \(existing.name)", category: "book-import")
            }
            
            // Import as original book
            let result = try await performImport(
                exportPackage: exportPackage,
                url: url,
                modelContext: modelContext,
                createNewID: false
            )
            importedBook = result.book
            recipesImported = result.newRecipes
            recipesUpdated = result.updatedRecipes
            imagesImported = result.images
            
        case .keepBoth:
            // Always create a new book with new IDs
            let result = try await performImport(
                exportPackage: exportPackage,
                url: url,
                modelContext: modelContext,
                createNewID: true
            )
            importedBook = result.book
            recipesImported = result.newRecipes
            imagesImported = result.images
            
        case .merge:
            if let existing = existingBook {
                // Merge recipes into existing book
                let result = try await performMergeImport(
                    exportPackage: exportPackage,
                    url: url,
                    existingBook: existing,
                    modelContext: modelContext
                )
                importedBook = existing
                recipesImported = result.newRecipes
                recipesUpdated = result.updatedRecipes
                imagesImported = result.images
            } else {
                // No existing book, just import normally
                let result = try await performImport(
                    exportPackage: exportPackage,
                    url: url,
                    modelContext: modelContext,
                    createNewID: false
                )
                importedBook = result.book
                recipesImported = result.newRecipes
                imagesImported = result.images
            }
        }
        
        // Save context
        do {
            try modelContext.save()
            logInfo("Successfully saved imported book: \(importedBook.name)", category: "book-import")
        } catch {
            logError("Failed to save imported book: \(error)", category: "book-import")
            throw RecipeBookImportError.saveFailed(error)
        }
        
        return RecipeBookImportResult(
            book: importedBook,
            recipesImported: recipesImported,
            recipesUpdated: recipesUpdated,
            imagesImported: imagesImported,
            wasReplaced: wasReplaced
        )
    }
    
    // MARK: - Private Helpers
    
    private func performImport(
        exportPackage: RecipeBookExportPackage,
        url: URL,
        modelContext: ModelContext,
        createNewID: Bool
    ) async throws -> (book: RecipeBook, newRecipes: Int, updatedRecipes: Int, images: Int) {
        // Extract to temp directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecipeBookImport_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        do {
            try RecipeBookExportService.extractZipArchive(from: url, to: tempDir)
        } catch {
            throw RecipeBookImportError.extractionFailed(error)
        }
        
        // Load images from archive into memory
        let imageDataMap = try loadImagesFromArchive(from: tempDir, manifest: exportPackage.imageManifest)
        
        // Create or update recipes
        var newRecipes = 0
        var updatedRecipes = 0
        var importedRecipeIDs: [UUID] = []
        var imagesImported = 0
        
        for recipeModel in exportPackage.recipes {
            let result = try await importOrUpdateRecipe(
                recipeModel,
                imageDataMap: imageDataMap,
                modelContext: modelContext,
                createNewID: createNewID
            )
            
            importedRecipeIDs.append(result.recipeID)
            imagesImported += result.imagesAssigned
            
            if result.wasNew {
                newRecipes += 1
            } else {
                updatedRecipes += 1
            }
        }
        
        // Create the book
        let bookID = createNewID ? UUID() : exportPackage.book.id
        let bookName = createNewID ? "\(exportPackage.book.name) (Imported)" : exportPackage.book.name
        
        let book = RecipeBook(
            id: bookID,
            name: bookName,
            bookDescription: exportPackage.book.bookDescription,
            coverImageName: exportPackage.book.coverImageName,
            dateCreated: createNewID ? Date() : exportPackage.book.dateCreated,
            dateModified: Date(),
            recipeIDs: importedRecipeIDs,
            color: exportPackage.book.color
        )
        
        modelContext.insert(book)
        
        return (book: book, newRecipes: newRecipes, updatedRecipes: updatedRecipes, images: imagesImported)
    }
    
    private func performMergeImport(
        exportPackage: RecipeBookExportPackage,
        url: URL,
        existingBook: RecipeBook,
        modelContext: ModelContext
    ) async throws -> (newRecipes: Int, updatedRecipes: Int, images: Int) {
        // Extract to temp directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecipeBookImport_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        do {
            try RecipeBookExportService.extractZipArchive(from: url, to: tempDir)
        } catch {
            throw RecipeBookImportError.extractionFailed(error)
        }
        
        // Load images from archive into memory
        let imageDataMap = try loadImagesFromArchive(from: tempDir, manifest: exportPackage.imageManifest)
        
        // Import/update recipes
        var newRecipes = 0
        var updatedRecipes = 0
        var imagesImported = 0
        
        for recipeModel in exportPackage.recipes {
            let result = try await importOrUpdateRecipe(
                recipeModel,
                imageDataMap: imageDataMap,
                modelContext: modelContext,
                createNewID: false
            )
            
            imagesImported += result.imagesAssigned
            
            // Add to book if not already there
            if !existingBook.recipeIDs.contains(result.recipeID) {
                existingBook.addRecipe(result.recipeID)
            }
            
            if result.wasNew {
                newRecipes += 1
            } else {
                updatedRecipes += 1
            }
        }
        
        existingBook.dateModified = Date()
        
        return (newRecipes: newRecipes, updatedRecipes: updatedRecipes, images: imagesImported)
    }
    
    private func importOrUpdateRecipe(
        _ recipeModel: RecipeModel,
        imageDataMap: [String: Data],
        modelContext: ModelContext,
        createNewID: Bool
    ) async throws -> (recipeID: UUID, wasNew: Bool, imagesAssigned: Int) {
        let recipeID = createNewID ? UUID() : recipeModel.id
        
        // Check if recipe exists
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate { recipe in
                recipe.id == recipeID
            }
        )
        
        let existingRecipes = try modelContext.fetch(descriptor)
        
        if let existingRecipe = existingRecipes.first, !createNewID {
            // Update existing recipe
            let imagesAssigned = try updateRecipe(existingRecipe, with: recipeModel, imageDataMap: imageDataMap)
            return (recipeID: recipeID, wasNew: false, imagesAssigned: imagesAssigned)
        } else {
            // Create new recipe
            var newRecipeModel = recipeModel
            if createNewID {
                newRecipeModel = RecipeModel(
                    id: recipeID,
                    title: recipeModel.title,
                    headerNotes: recipeModel.headerNotes,
                    yield: recipeModel.yield,
                    ingredientSections: recipeModel.ingredientSections,
                    instructionSections: recipeModel.instructionSections,
                    notes: recipeModel.notes,
                    reference: recipeModel.reference,
                    imageName: recipeModel.imageName,
                    additionalImageNames: recipeModel.additionalImageNames,
                    imageURLs: recipeModel.imageURLs
                )
            }
            
            let newRecipe = Recipe(from: newRecipeModel)
            
            // Assign image data from the map
            var imagesAssigned = 0
            
            // Assign main image
            if let imageName = newRecipeModel.imageName,
               let imageData = imageDataMap[imageName] {
                newRecipe.imageData = imageData
                imagesAssigned += 1
                logDebug("Assigned main image data (\(imageData.count / 1024)KB) to recipe: \(newRecipe.title)", category: "book-import")
            }
            
            // Assign additional images
            if let additionalImageNames = newRecipeModel.additionalImageNames {
                var additionalImages: [[String: Data]] = []
                
                for imageName in additionalImageNames {
                    if let imageData = imageDataMap[imageName] {
                        additionalImages.append(["data": imageData, "name": Data(imageName.utf8)])
                        imagesAssigned += 1
                    }
                }
                
                if !additionalImages.isEmpty {
                    if let encoded = try? JSONEncoder().encode(additionalImages) {
                        newRecipe.additionalImagesData = encoded
                        logDebug("Assigned \(additionalImages.count) additional images to recipe: \(newRecipe.title)", category: "book-import")
                    }
                }
            }
            
            modelContext.insert(newRecipe)
            
            return (recipeID: recipeID, wasNew: true, imagesAssigned: imagesAssigned)
        }
    }
    
    private func updateRecipe(_ recipe: Recipe, with model: RecipeModel, imageDataMap: [String: Data]) throws -> Int {
        let encoder = JSONEncoder()
        var imagesAssigned = 0
        
        // Update structured data
        if let ingredientSectionsData = try? encoder.encode(model.ingredientSections) {
            recipe.ingredientSectionsData = ingredientSectionsData
        }
        
        if let instructionSectionsData = try? encoder.encode(model.instructionSections) {
            recipe.instructionSectionsData = instructionSectionsData
        }
        
        if let notesData = try? encoder.encode(model.notes) {
            recipe.notesData = notesData
        }
        
        // Update metadata
        recipe.title = model.title
        recipe.headerNotes = model.headerNotes
        recipe.recipeYield = model.yield
        recipe.reference = model.reference
        
        // Update images (both filename and data)
        if let imageName = model.imageName {
            recipe.imageName = imageName
            
            // Also update the image data from the map
            if let imageData = imageDataMap[imageName] {
                recipe.imageData = imageData
                imagesAssigned += 1
                logDebug("Updated main image data (\(imageData.count / 1024)KB) for recipe: \(recipe.title)", category: "book-import")
            }
        }
        
        if let additionalImages = model.additionalImageNames {
            recipe.additionalImageNames = additionalImages
            
            // Also update the additional images data from the map
            var additionalImagesData: [[String: Data]] = []
            
            for imageName in additionalImages {
                if let imageData = imageDataMap[imageName] {
                    additionalImagesData.append(["data": imageData, "name": Data(imageName.utf8)])
                    imagesAssigned += 1
                }
            }
            
            if !additionalImagesData.isEmpty {
                if let encoded = try? encoder.encode(additionalImagesData) {
                    recipe.additionalImagesData = encoded
                    logDebug("Updated \(additionalImagesData.count) additional images for recipe: \(recipe.title)", category: "book-import")
                }
            }
        }
        
        // Update version tracking
        recipe.version = (recipe.version ?? 1) + 1
        recipe.lastModified = Date()
        
        return imagesAssigned
    }
    
    /// Loads images from the export archive into memory as a dictionary
    /// Maps filename -> image Data for assignment to recipes during import
    private func loadImagesFromArchive(from directory: URL, manifest: [ImageManifestEntry]) throws -> [String: Data] {
        var imageDataMap: [String: Data] = [:]
        
        for entry in manifest {
            let sourceURL = directory.appendingPathComponent(entry.fileName)
            
            // Load image data from archive
            if FileManager.default.fileExists(atPath: sourceURL.path) {
                do {
                    let imageData = try Data(contentsOf: sourceURL)
                    imageDataMap[entry.fileName] = imageData
                    logDebug("Loaded image data: \(entry.fileName) (\(imageData.count / 1024)KB)", category: "book-import")
                } catch {
                    logWarning("Failed to load image \(entry.fileName): \(error)", category: "book-import")
                }
            } else {
                logWarning("Source image not found: \(entry.fileName)", category: "book-import")
            }
        }
        
        logInfo("Loaded \(imageDataMap.count) images from archive", category: "book-import")
        return imageDataMap
    }
    
    private func isSupportedVersion(_ version: String) -> Bool {
        // Support versions 1.0 through 2.x
        let components = version.split(separator: ".").compactMap { Int($0) }
        guard let major = components.first else { return false }
        return major <= 2
    }
}
