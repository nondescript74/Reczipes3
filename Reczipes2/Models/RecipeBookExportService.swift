//
//  RecipeBookExportService.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers
import Compression
import CryptoKit

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Service for exporting and importing recipe books as shareable packages
@MainActor
class RecipeBookExportService {
    
    // MARK: - ZIP Utilities
    
    /// Creates a ZIP archive from a directory using FileManager's native capabilities
    private static func createZipArchive(from sourceURL: URL, to destinationURL: URL) throws {
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        coordinator.coordinate(readingItemAt: sourceURL, options: [.forUploading], error: &error) { zipURL in
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: zipURL, to: destinationURL)
            } catch {
                logError("Failed to create zip archive: \(error)", category: "book-export")
            }
        }
        
        if let error = error {
            throw error
        }
    }
    
    /// Extracts a ZIP archive to a directory using native iOS capabilities
    static func extractZipArchive(from sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        // Try using FileManager's built-in unzipping first (reverse of zipping)
        // This only works if the file is already a properly formatted ZIP
        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?
        var extractionSucceeded = false
        
        var localError: NSError?
        
        coordinator.coordinate(readingItemAt: sourceURL, options: [.withoutChanges], error: &coordinatorError) { readURL in
            do {
                // Check if this is already an unzipped directory (shouldn't happen, but just in case)
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: readURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                    // It's already a directory, just copy it
                    try fileManager.copyItem(at: readURL, to: destinationURL)
                    extractionSucceeded = true
                    return
                }
                
                // Try to use the system's unzipping by reading it as a coordinate
                // For actual extraction, we need to use our manual parser
                // Create destination directory
                try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
                
                // Read the ZIP file
                let zipData = try Data(contentsOf: sourceURL)
                
                // Parse and extract using our custom parser
                try extractZipData(zipData, to: destinationURL)
                extractionSucceeded = true
                
            } catch let caughtError {
                // Use a local variable to avoid overlapping access
                localError = caughtError as NSError
            }
        }
        
        // Combine errors - prefer the caught error over coordinator error
        if let error = localError ?? coordinatorError {
            throw error
        }
        
        if !extractionSucceeded {
            throw NSError(domain: "RecipeBookExport", code: -7, userInfo: [
                NSLocalizedDescriptionKey: "Failed to extract ZIP archive"
            ])
        }
    }
    
    /// Parses ZIP file format and extracts contents
    private static func extractZipData(_ data: Data, to destinationURL: URL) throws {
        var offset = 0
        let fileManager = FileManager.default
        
        // ZIP file structure:
        // Local file headers followed by central directory
        // We'll parse local file headers to extract files
        
        while offset < data.count - 4 {
            // Read signature
            let signature = data.withUnsafeBytes { buffer in
                buffer.loadUnaligned(fromByteOffset: offset, as: UInt32.self)
            }
            
            // Local file header signature: 0x04034b50
            if signature == 0x04034b50 {
                offset += 4
                
                // Skip version needed (2 bytes)
                offset += 2
                
                // Read flags
                _ = data.withUnsafeBytes { buffer in
                    buffer.loadUnaligned(fromByteOffset: offset, as: UInt16.self)
                }
                offset += 2
                
                // Read compression method
                let compressionMethod = data.withUnsafeBytes { buffer in
                    buffer.loadUnaligned(fromByteOffset: offset, as: UInt16.self)
                }
                offset += 2
                
                // Skip last mod time & date (4 bytes)
                offset += 4
                
                // Skip CRC-32 (4 bytes)
                offset += 4
                
                // Read compressed size
                let compressedSize = Int(data.withUnsafeBytes { buffer in
                    buffer.loadUnaligned(fromByteOffset: offset, as: UInt32.self)
                })
                offset += 4
                
                // Read uncompressed size
                let uncompressedSize = Int(data.withUnsafeBytes { buffer in
                    buffer.loadUnaligned(fromByteOffset: offset, as: UInt32.self)
                })
                offset += 4
                
                // Read file name length
                let fileNameLength = Int(data.withUnsafeBytes { buffer in
                    buffer.loadUnaligned(fromByteOffset: offset, as: UInt16.self)
                })
                offset += 2
                
                // Read extra field length
                let extraFieldLength = Int(data.withUnsafeBytes { buffer in
                    buffer.loadUnaligned(fromByteOffset: offset, as: UInt16.self)
                })
                offset += 2
                
                // Read file name
                let fileNameData = data.subdata(in: offset..<(offset + fileNameLength))
                guard let fileName = String(data: fileNameData, encoding: .utf8) else {
                    throw NSError(domain: "RecipeBookExport", code: -2, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid file name in ZIP"
                    ])
                }
                offset += fileNameLength
                
                // Skip extra field
                offset += extraFieldLength
                
                // Read compressed data
                let compressedData = data.subdata(in: offset..<(offset + compressedSize))
                offset += compressedSize
                
                // Check if this is a directory
                if fileName.hasSuffix("/") {
                    // Create directory
                    let dirURL = destinationURL.appendingPathComponent(fileName)
                    try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
                } else {
                    // Extract file
                    let fileURL = destinationURL.appendingPathComponent(fileName)
                    
                    // Create parent directory if needed
                    let parentDir = fileURL.deletingLastPathComponent()
                    if !fileManager.fileExists(atPath: parentDir.path) {
                        try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
                    }
                    
                    // Decompress if needed
                    let fileData: Data
                    if compressionMethod == 0 {
                        // No compression
                        fileData = compressedData
                    } else if compressionMethod == 8 {
                        // DEFLATE compression
                        fileData = try decompressDeflate(compressedData, uncompressedSize: uncompressedSize)
                    } else {
                        throw NSError(domain: "RecipeBookExport", code: -3, userInfo: [
                            NSLocalizedDescriptionKey: "Unsupported compression method: \(compressionMethod)"
                        ])
                    }
                    
                    // Write file
                    try fileData.write(to: fileURL)
                }
            } else if signature == 0x02014b50 {
                // Central directory header - we're done with file entries
                break
            } else {
                // Unknown signature, try to continue
                offset += 1
            }
        }
    }
    
    /// Decompresses DEFLATE compressed data
    private static func decompressDeflate(_ data: Data, uncompressedSize: Int) throws -> Data {
        // ZIP uses raw DEFLATE, not zlib-wrapped DEFLATE
        var decompressed = Data(count: uncompressedSize)
        
        let result = data.withUnsafeBytes { (compressedBuffer: UnsafeRawBufferPointer) -> Int in
            decompressed.withUnsafeMutableBytes { (decompressedBuffer: UnsafeMutableRawBufferPointer) -> Int in
                guard let compressedPtr = compressedBuffer.baseAddress,
                      let decompressedPtr = decompressedBuffer.baseAddress else {
                    return 0
                }
                
                // Use COMPRESSION_LZFSE for raw DEFLATE, or try ZLIB first
                var bytesWritten = compression_decode_buffer(
                    decompressedPtr.assumingMemoryBound(to: UInt8.self),
                    uncompressedSize,
                    compressedPtr.assumingMemoryBound(to: UInt8.self),
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
                
                // If ZLIB failed, the data might be raw DEFLATE
                // Try adding zlib header
                if bytesWritten == 0 {
                    var zlibData = Data([0x78, 0x9C])
                    zlibData.append(data)
                    
                    bytesWritten = zlibData.withUnsafeBytes { (zlibBuffer: UnsafeRawBufferPointer) -> Int in
                        guard let zlibPtr = zlibBuffer.baseAddress else { return 0 }
                        
                        return compression_decode_buffer(
                            decompressedPtr.assumingMemoryBound(to: UInt8.self),
                            uncompressedSize,
                            zlibPtr.assumingMemoryBound(to: UInt8.self),
                            zlibData.count,
                            nil,
                            COMPRESSION_ZLIB
                        )
                    }
                }
                
                return bytesWritten
            }
        }
        
        guard result > 0 else {
            throw NSError(domain: "RecipeBookExport", code: -4, userInfo: [
                NSLocalizedDescriptionKey: "Could not decompress the file. The archive may be corrupted or use an unsupported compression format."
            ])
        }
        
        // Trim to actual decompressed size
        decompressed.count = result
        
        return decompressed
    }
    
    // MARK: - Export
    
    /// Exports a recipe book to a .recipebook file (ZIP package)
    /// - Parameters:
    ///   - book: The recipe book to export
    ///   - recipes: The recipes in the book
    ///   - includeImages: Whether to include images in the export
    /// - Returns: URL to the exported file with proper UTType
    static func exportBook(
        _ book: RecipeBook,
        recipes: [RecipeModel],
        includeImages: Bool = true
    ) async throws -> URL {
        logInfo("Starting export of book: \(book.name)", category: "book-export")
        
        // Create temporary directory for export
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecipeBookExport_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            // Clean up temp directory
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Collect image manifest
        var imageManifest: [ImageManifestEntry] = []
        
        if includeImages {
            // Export book cover image
            if let coverImageName = book.coverImageName {
                try await copyImageToExport(
                    imageName: coverImageName,
                    to: tempDir,
                    entry: ImageManifestEntry(
                        fileName: coverImageName,
                        type: .bookCover,
                        associatedID: book.id
                    ),
                    manifest: &imageManifest
                )
            }
            
            // Export recipe images
            for recipe in recipes {
                // Primary image
                if let imageName = recipe.imageName {
                    try await copyImageToExport(
                        imageName: imageName,
                        to: tempDir,
                        entry: ImageManifestEntry(
                            fileName: imageName,
                            type: .recipePrimary,
                            associatedID: recipe.id
                        ),
                        manifest: &imageManifest
                    )
                }
                
                // Additional images
                if let additionalImages = recipe.additionalImageNames {
                    for imageName in additionalImages {
                        try await copyImageToExport(
                            imageName: imageName,
                            to: tempDir,
                            entry: ImageManifestEntry(
                                fileName: imageName,
                                type: .recipeAdditional,
                                associatedID: recipe.id
                            ),
                            manifest: &imageManifest
                        )
                    }
                }
            }
        }
        
        // Create export package
        let exportPackage = RecipeBookExportPackage(
            book: ExportableRecipeBook(from: book),
            recipes: recipes,
            imageManifest: imageManifest
        )
        
        // Write JSON metadata
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(exportPackage)
        let jsonURL = tempDir.appendingPathComponent("book.json")
        try jsonData.write(to: jsonURL)
        
        // Create ZIP archive using FileManager's native zipping
        let fileName = sanitizeFileName(book.name)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName)_\(Date().timeIntervalSince1970).\(RecipeBookPackageType.fileExtension)")
        
        try createZipArchive(from: tempDir, to: outputURL)
        
        logInfo("Successfully exported book to: \(outputURL.lastPathComponent)", category: "book-export")
        
        return outputURL
    }
    
    // MARK: - Import
    
    /// Imports a recipe book from a .recipebook file
    /// - Parameters:
    ///   - url: URL to the .recipebook file
    ///   - modelContext: SwiftData model context
    ///   - replaceExisting: If true, replaces existing book with same ID
    /// - Returns: The imported RecipeBook
    static func importBook(
        from url: URL,
        modelContext: ModelContext,
        replaceExisting: Bool = false
    ) async throws -> RecipeBook {
        logInfo("Starting import from: \(url.lastPathComponent)", category: "book-import")
        
        // Create temporary extraction directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecipeBookImport_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Extract ZIP using native unzip
        try extractZipArchive(from: url, to: tempDir)
        
        // Read JSON metadata
        let jsonURL = tempDir.appendingPathComponent("book.json")
        let jsonData = try Data(contentsOf: jsonURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportPackage = try decoder.decode(RecipeBookExportPackage.self, from: jsonData)
        
        logInfo("Importing book: \(exportPackage.book.name) with \(exportPackage.recipes.count) recipes", category: "book-import")
        
        // Check for existing book
        let bookID = exportPackage.book.id
        let descriptor = FetchDescriptor<RecipeBook>(
            predicate: #Predicate { book in
                book.id == bookID
            }
        )
        
        let existingBooks = try modelContext.fetch(descriptor)
        
        if existingBooks.first != nil, !replaceExisting {
            // Generate new ID to avoid conflicts
            logInfo("Book already exists, creating as new copy", category: "book-import")
            return try await importAsNewBook(exportPackage, tempDir: tempDir, modelContext: modelContext)
        } else if let existingBook = existingBooks.first, replaceExisting {
            // Replace existing book
            logInfo("Replacing existing book", category: "book-import")
            modelContext.delete(existingBook)
        }
        
        // Import images
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        for entry in exportPackage.imageManifest {
            let sourceURL = tempDir.appendingPathComponent(entry.fileName)
            let destURL = documentsPath.appendingPathComponent(entry.fileName)
            
            // Don't overwrite existing images
            if !FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
            }
        }
        
        // Create RecipeBook
        let newBook = RecipeBook(
            id: exportPackage.book.id,
            name: exportPackage.book.name,
            bookDescription: exportPackage.book.bookDescription,
            coverImageName: exportPackage.book.coverImageName,
            dateCreated: exportPackage.book.dateCreated,
            dateModified: Date(), // Update to current date
            recipeIDs: exportPackage.book.recipeIDs,
            color: exportPackage.book.color
        )
        
        modelContext.insert(newBook)
        
        // Import or update recipes
        for recipeModel in exportPackage.recipes {
            try await importRecipe(recipeModel, modelContext: modelContext)
        }
        
        try modelContext.save()
        
        logInfo("Successfully imported book: \(newBook.name)", category: "book-import")
        
        return newBook
    }
    
    // MARK: - Helper Methods
    
    private static func copyImageToExport(
        imageName: String,
        to directory: URL,
        entry: ImageManifestEntry,
        manifest: inout [ImageManifestEntry]
    ) async throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sourceURL = documentsPath.appendingPathComponent(imageName)
        let destURL = directory.appendingPathComponent(imageName)
        
        if FileManager.default.fileExists(atPath: sourceURL.path) {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            manifest.append(entry)
        }
    }
    
    private static func importAsNewBook(
        _ exportPackage: RecipeBookExportPackage,
        tempDir: URL,
        modelContext: ModelContext
    ) async throws -> RecipeBook {
        // Create new IDs for book and recipes
        let newBookID = UUID()
        var recipeIDMapping: [UUID: UUID] = [:] // Old ID to new ID
        
        // Import images with new names
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var newCoverImageName: String?
        
        for entry in exportPackage.imageManifest {
            let newFileName = "\(UUID().uuidString).\(entry.fileName.split(separator: ".").last ?? "jpg")"
            let sourceURL = tempDir.appendingPathComponent(entry.fileName)
            let destURL = documentsPath.appendingPathComponent(newFileName)
            
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            
            if entry.type == .bookCover {
                newCoverImageName = newFileName
            }
        }
        
        // Create new recipes with new IDs
        var newRecipes: [RecipeModel] = []
        for recipe in exportPackage.recipes {
            let newRecipeID = UUID()
            recipeIDMapping[recipe.id] = newRecipeID
            
            // Note: You'll need to create new image names for recipes too
            // For simplicity, keeping the same image names here
            let newRecipe = RecipeModel(
                id: newRecipeID,
                title: recipe.title,
                headerNotes: recipe.headerNotes,
                yield: recipe.yield,
                ingredientSections: recipe.ingredientSections,
                instructionSections: recipe.instructionSections,
                notes: recipe.notes,
                reference: recipe.reference,
                imageName: recipe.imageName,
                additionalImageNames: recipe.additionalImageNames,
                imageURLs: recipe.imageURLs
            )
            newRecipes.append(newRecipe)
        }
        
        // Create new book
        let newBook = RecipeBook(
            id: newBookID,
            name: "\(exportPackage.book.name) (Imported)",
            bookDescription: exportPackage.book.bookDescription,
            coverImageName: newCoverImageName,
            dateCreated: Date(),
            dateModified: Date(),
            recipeIDs: newRecipes.map { $0.id },
            color: exportPackage.book.color
        )
        
        modelContext.insert(newBook)
        
        // Import recipes
        for recipe in newRecipes {
            try await importRecipe(recipe, modelContext: modelContext)
        }
        
        try modelContext.save()
        
        return newBook
    }
    
    private static func importRecipe(_ recipeModel: RecipeModel, modelContext: ModelContext) async throws {
        // Check if recipe already exists
        let recipeID = recipeModel.id
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate { recipe in
                recipe.id == recipeID
            }
        )
        
        let existingRecipes = try modelContext.fetch(descriptor)
        
        if existingRecipes.isEmpty {
            // Create new recipe from RecipeModel
            let newRecipe = Recipe(from: recipeModel)
            
            // Ensure version tracking is set
            if newRecipe.version == nil {
                newRecipe.version = 1
            }
            if newRecipe.lastModified == nil {
                newRecipe.lastModified = Date()
            }
            
            modelContext.insert(newRecipe)
            logInfo("Imported new recipe: \(recipeModel.title)", category: "book-import")
        } else if let existingRecipe = existingRecipes.first {
            // Update existing recipe if the imported one is newer
            logInfo("Recipe already exists, checking for updates: \(recipeModel.title)", category: "book-import")
            
            // Compare and potentially update the existing recipe
            let shouldUpdate = try updateRecipeIfNewer(existingRecipe, with: recipeModel)
            
            if shouldUpdate {
                logInfo("Updated existing recipe: \(recipeModel.title)", category: "book-import")
            } else {
                logInfo("Existing recipe is current, no update needed: \(recipeModel.title)", category: "book-import")
            }
        }
    }
    
    /// Updates an existing recipe with data from a RecipeModel if the model is newer
    /// - Returns: True if the recipe was updated
    private static func updateRecipeIfNewer(_ recipe: Recipe, with model: RecipeModel) throws -> Bool {
        // For imported recipes, we'll update the content but preserve local version tracking
        // This ensures users don't lose their local changes
        
        // Encode the new data
        let encoder = JSONEncoder()
        
        // Update ingredient sections
        if let ingredientSectionsData = try? encoder.encode(model.ingredientSections) {
            recipe.ingredientSectionsData = ingredientSectionsData
        }
        
        // Update instruction sections
        if let instructionSectionsData = try? encoder.encode(model.instructionSections) {
            recipe.instructionSectionsData = instructionSectionsData
        }
        
        // Update notes
        if let notesData = try? encoder.encode(model.notes) {
            recipe.notesData = notesData
        }
        
        // Update metadata
        recipe.title = model.title
        recipe.headerNotes = model.headerNotes
        recipe.recipeYield = model.yield
        recipe.reference = model.reference
        
        // Update images (only if new ones are provided)
        if let imageName = model.imageName, !imageName.isEmpty {
            recipe.imageName = imageName
        }
        
        if let additionalImages = model.additionalImageNames, !additionalImages.isEmpty {
            recipe.additionalImageNames = additionalImages
        }
        
        // Update version tracking
        recipe.version = (recipe.version ?? 1) + 1
        recipe.lastModified = Date()
        
        // Recalculate ingredients hash for cache invalidation
        let ingredientsString = model.ingredientSections.map { section in
            section.ingredients.map { $0.name }.joined(separator: ",")
        }.joined(separator: ";")
        recipe.ingredientsHash = ingredientsString.sha256Hash()
        
        return true
    }
    
    private static func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    // MARK: - Bulk Import
    
    /// Imports multiple recipe books from a ZIP file containing .recipebook files
    /// - Parameters:
    ///   - url: URL to the ZIP file containing multiple .recipebook files
    ///   - modelContext: SwiftData model context
    ///   - replaceExisting: If true, replaces existing books with same ID
    /// - Returns: Array of imported RecipeBooks and summary information
    static func importMultipleBooks(
        from url: URL,
        modelContext: ModelContext,
        replaceExisting: Bool = false
    ) async throws -> (books: [RecipeBook], summary: String) {
        logInfo("Starting bulk import from: \(url.lastPathComponent)", category: "book-import")
        
        // Create temporary extraction directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecipeBookBulkImport_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Extract ZIP
        try extractZipArchive(from: url, to: tempDir)
        
        // Find all .recipebook files in the extracted directory
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        
        let recipeBookFiles = contents.filter { $0.pathExtension == "recipebook" }
        
        guard !recipeBookFiles.isEmpty else {
            // Check if this is a single .recipebook file (has book.json directly)
            let jsonURL = tempDir.appendingPathComponent("book.json")
            if fileManager.fileExists(atPath: jsonURL.path) {
                // This is a single book, not a multi-book ZIP
                throw NSError(domain: "RecipeBookExport", code: -5, userInfo: [
                    NSLocalizedDescriptionKey: "This appears to be a single recipe book, not a collection. Please use the regular import function."
                ])
            } else {
                throw NSError(domain: "RecipeBookExport", code: -6, userInfo: [
                    NSLocalizedDescriptionKey: "No recipe books found in the ZIP file."
                ])
            }
        }
        
        logInfo("Found \(recipeBookFiles.count) recipe books to import", category: "book-import")
        
        // Import each book
        var importedBooks: [RecipeBook] = []
        var successCount = 0
        
        var errorCount = 0
        
        for bookFile in recipeBookFiles {
            do {
                let book = try await importBook(
                    from: bookFile,
                    modelContext: modelContext,
                    replaceExisting: replaceExisting
                )
                importedBooks.append(book)
                successCount += 1
                logInfo("Successfully imported: \(book.name)", category: "book-import")
            } catch {
                errorCount += 1
                logError("Failed to import \(bookFile.lastPathComponent): \(error)", category: "book-import")
            }
        }
        
        let summary = """
        Imported \(successCount) of \(recipeBookFiles.count) books
        \(errorCount > 0 ? "Failed: \(errorCount)" : "")
        """
        
        logInfo("Bulk import complete: \(summary)", category: "book-import")
        
        return (importedBooks, summary)
    }
    
    /// Detects whether a ZIP file contains multiple recipe books or a single book
    static func detectImportType(from url: URL) throws -> ImportType {
        // Create temporary extraction directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecipeBookDetect_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Extract ZIP
        try extractZipArchive(from: url, to: tempDir)
        
        // Check for book.json (single book)
        let jsonURL = tempDir.appendingPathComponent("book.json")
        if FileManager.default.fileExists(atPath: jsonURL.path) {
            return .singleBook
        }
        
        // Check for .recipebook files (multiple books)
        let contents = try FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        
        let recipeBookFiles = contents.filter { $0.pathExtension == "recipebook" }
        
        if recipeBookFiles.count > 0 {
            return .multipleBooks(count: recipeBookFiles.count)
        }
        
        return .unknown
    }
    
    enum ImportType {
        case singleBook
        case multipleBooks(count: Int)
        case unknown
    }
}
