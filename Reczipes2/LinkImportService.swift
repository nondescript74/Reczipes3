//
//  LinkImportService.swift
//  Reczipes2
//
//  Created for importing recipe links from JSON
//

import Foundation
import SwiftData

/// Service for importing recipe links from JSON files
class LinkImportService {
    
    /// Import links from a JSON file in the app bundle
    /// - Parameters:
    ///   - filename: Name of the JSON file (including extension)
    ///   - modelContext: SwiftData model context for saving
    ///   - validate: Whether to validate the file before importing (default: true)
    ///   - autoClean: Whether to automatically clean the data (default: false)
    /// - Returns: Number of links imported
    /// - Throws: Import errors
    static func importLinksFromBundle(
        filename: String,
        into modelContext: ModelContext,
        validate: Bool = true,
        autoClean: Bool = false
    ) async throws -> Int {
        logInfo("Starting import from bundle file: \(filename)", category: "import")
        
        // Locate the file in the bundle
        guard let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".json", with: ""), withExtension: "json") else {
            logError("Could not find \(filename) in app bundle", category: "import")
            throw LinkImportError.fileNotFound
        }
        
        return try await importLinks(from: url, into: modelContext, validate: validate, autoClean: autoClean)
    }
    
    /// Import links from a JSON file URL
    /// - Parameters:
    ///   - url: URL of the JSON file
    ///   - modelContext: SwiftData model context for saving
    ///   - validate: Whether to validate the file before importing (default: true)
    ///   - autoClean: Whether to automatically clean the data (default: false)
    /// - Returns: Number of links imported
    /// - Throws: Import errors
    static func importLinks(
        from url: URL,
        into modelContext: ModelContext,
        validate: Bool = true,
        autoClean: Bool = false
    ) async throws -> Int {
        logInfo("Importing links from: \(url.path)", category: "import")
        
        // Validate the file if requested
        if validate {
            logInfo("Validating JSON file...", category: "import")
            let validationResult = JSONLinkValidator.validate(fileAt: url)
            
            if !validationResult.isValid {
                logError("Validation failed: \(validationResult.errors.joined(separator: ", "))", category: "import")
                throw LinkImportError.invalidJSON
            }
            
            logInfo("Validation passed: \(validationResult.linkCount) links, \(validationResult.warnings.count) warnings, \(validationResult.duplicateURLs.count) duplicates in file", category: "import")
        }
        
        // Read the file (with optional cleaning)
        let data: Data
        if autoClean {
            logInfo("Auto-cleaning data before import...", category: "import")
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("cleaned_links_\(UUID().uuidString).json")
            try JSONLinkValidator.clean(inputURL: url, outputURL: tempURL, removeDuplicates: true)
            data = try Data(contentsOf: tempURL)
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            logInfo("Used cleaned data for import", category: "import")
        } else {
            data = try Data(contentsOf: url)
        }
        
        logDebug("Read \(data.count) bytes from file", category: "import")
        
        // Decode JSON
        let decoder = JSONDecoder()
        let jsonLinks = try decoder.decode([JSONLink].self, from: data)
        logInfo("Decoded \(jsonLinks.count) links from JSON", category: "import")
        
        // Filter out already-imported links
        let existingURLs = try await getExistingURLs(from: modelContext)
        let newLinks = jsonLinks.filter { !existingURLs.contains($0.url) }
        
        logInfo("Found \(newLinks.count) new links to import (skipping \(jsonLinks.count - newLinks.count) duplicates)", category: "import")
        
        // Convert to SavedLink models and insert
        var importCount = 0
        for jsonLink in newLinks {
            let savedLink = SavedLink(from: jsonLink)
            modelContext.insert(savedLink)
            importCount += 1
        }
        
        // Save the context
        try modelContext.save()
        logInfo("Successfully imported \(importCount) links", category: "import")
        
        return importCount
    }
    
    /// Import links from JSON data
    /// - Parameters:
    ///   - data: JSON data
    ///   - modelContext: SwiftData model context for saving
    ///   - validate: Whether to validate the data before importing (default: true)
    /// - Returns: Number of links imported
    /// - Throws: Import errors
    static func importLinks(
        from data: Data,
        into modelContext: ModelContext,
        validate: Bool = true
    ) async throws -> Int {
        logInfo("Importing links from data (\(data.count) bytes)", category: "import")
        
        // Validate the data if requested
        if validate {
            logInfo("Validating JSON data...", category: "import")
            let validationResult = JSONLinkValidator.validate(data: data)
            
            if !validationResult.isValid {
                logError("Validation failed: \(validationResult.errors.joined(separator: ", "))", category: "import")
                throw LinkImportError.invalidJSON
            }
            
            logInfo("Validation passed: \(validationResult.linkCount) links, \(validationResult.warnings.count) warnings", category: "import")
        }
        
        // Decode JSON
        let decoder = JSONDecoder()
        let jsonLinks = try decoder.decode([JSONLink].self, from: data)
        logInfo("Decoded \(jsonLinks.count) links from JSON", category: "import")
        
        // Filter out already-imported links
        let existingURLs = try await getExistingURLs(from: modelContext)
        let newLinks = jsonLinks.filter { !existingURLs.contains($0.url) }
        
        logInfo("Found \(newLinks.count) new links to import (skipping \(jsonLinks.count - newLinks.count) duplicates)", category: "import")
        
        // Convert to SavedLink models and insert
        var importCount = 0
        for jsonLink in newLinks {
            let savedLink = SavedLink(from: jsonLink)
            modelContext.insert(savedLink)
            importCount += 1
        }
        
        // Save the context
        try modelContext.save()
        logInfo("Successfully imported \(importCount) links", category: "import")
        
        return importCount
    }
    
    /// Get all existing URLs from the database
    private static func getExistingURLs(from modelContext: ModelContext) async throws -> Set<String> {
        let descriptor = FetchDescriptor<SavedLink>()
        let existingLinks = try modelContext.fetch(descriptor)
        return Set(existingLinks.map { $0.url })
    }
    
    /// Delete all saved links (useful for re-importing)
    static func clearAllLinks(from modelContext: ModelContext) throws {
        logWarning("Clearing all saved links", category: "import")
        
        let descriptor = FetchDescriptor<SavedLink>()
        let allLinks = try modelContext.fetch(descriptor)
        
        for link in allLinks {
            modelContext.delete(link)
        }
        
        try modelContext.save()
        logInfo("Cleared \(allLinks.count) links", category: "import")
    }
}

// MARK: - Error Types

enum LinkImportError: LocalizedError {
    case fileNotFound
    case invalidJSON
    case duplicateURL
    case databaseError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Could not find the JSON file in the app bundle"
        case .invalidJSON:
            return "The JSON file format is invalid"
        case .duplicateURL:
            return "This URL has already been imported"
        case .databaseError:
            return "Failed to save links to the database"
        }
    }
}
