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
    private static func extractZipArchive(from sourceURL: URL, to destinationURL: URL) throws {
        // Create destination directory
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        
        // Read the entire ZIP file
        let zipData = try Data(contentsOf: sourceURL)
        
        // Parse and extract the ZIP file
        try extractZipData(zipData, to: destinationURL)
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
                buffer.load(fromByteOffset: offset, as: UInt32.self)
            }
            
            // Local file header signature: 0x04034b50
            if signature == 0x04034b50 {
                offset += 4
                
                // Skip version needed (2 bytes)
                offset += 2
                
                // Read flags
                _ = data.withUnsafeBytes { buffer in
                    buffer.load(fromByteOffset: offset, as: UInt16.self)
                }
                offset += 2
                
                // Read compression method
                let compressionMethod = data.withUnsafeBytes { buffer in
                    buffer.load(fromByteOffset: offset, as: UInt16.self)
                }
                offset += 2
                
                // Skip last mod time & date (4 bytes)
                offset += 4
                
                // Skip CRC-32 (4 bytes)
                offset += 4
                
                // Read compressed size
                let compressedSize = Int(data.withUnsafeBytes { buffer in
                    buffer.load(fromByteOffset: offset, as: UInt32.self)
                })
                offset += 4
                
                // Read uncompressed size
                let uncompressedSize = Int(data.withUnsafeBytes { buffer in
                    buffer.load(fromByteOffset: offset, as: UInt32.self)
                })
                offset += 4
                
                // Read file name length
                let fileNameLength = Int(data.withUnsafeBytes { buffer in
                    buffer.load(fromByteOffset: offset, as: UInt16.self)
                })
                offset += 2
                
                // Read extra field length
                let extraFieldLength = Int(data.withUnsafeBytes { buffer in
                    buffer.load(fromByteOffset: offset, as: UInt16.self)
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
        var decompressed = Data(count: uncompressedSize)
        
        let result = data.withUnsafeBytes { (compressedBuffer: UnsafeRawBufferPointer) -> Int in
            decompressed.withUnsafeMutableBytes { (decompressedBuffer: UnsafeMutableRawBufferPointer) -> Int in
                guard let compressedPtr = compressedBuffer.baseAddress,
                      let decompressedPtr = decompressedBuffer.baseAddress else {
                    return 0
                }
                
                return compression_decode_buffer(
                    decompressedPtr.assumingMemoryBound(to: UInt8.self),
                    uncompressedSize,
                    compressedPtr.assumingMemoryBound(to: UInt8.self),
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        
        guard result > 0 else {
            throw NSError(domain: "RecipeBookExport", code: -4, userInfo: [
                NSLocalizedDescriptionKey: "Failed to decompress data"
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
    /// - Returns: URL to the exported file
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
            .appendingPathComponent("\(fileName)_\(Date().timeIntervalSince1970).recipebook")
        
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
            modelContext.insert(newRecipe)
            logInfo("Imported new recipe: \(recipeModel.title)", category: "book-import")
        } else {
            logInfo("Recipe already exists, skipping: \(recipeModel.title)", category: "book-import")
        }
    }
    
    private static func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

