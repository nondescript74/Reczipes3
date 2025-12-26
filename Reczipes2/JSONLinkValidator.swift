//
//  JSONLinkValidator.swift
//  Reczipes2
//
//  Helper utility for validating link JSON files
//

import Foundation

/// Utility for validating JSON link files before import
struct JSONLinkValidator {
    
    /// Validation result
    struct ValidationResult {
        let isValid: Bool
        let linkCount: Int
        let errors: [String]
        let warnings: [String]
        let duplicateURLs: [String]
        
        var summary: String {
            var lines: [String] = []
            
            if isValid {
                lines.append("✅ Valid JSON file with \(linkCount) link(s)")
            } else {
                lines.append("❌ Invalid JSON file")
            }
            
            if !errors.isEmpty {
                lines.append("\nErrors:")
                errors.forEach { lines.append("  • \($0)") }
            }
            
            if !warnings.isEmpty {
                lines.append("\nWarnings:")
                warnings.forEach { lines.append("  • \($0)") }
            }
            
            if !duplicateURLs.isEmpty {
                lines.append("\nDuplicate URLs:")
                duplicateURLs.forEach { lines.append("  • \($0)") }
            }
            
            return lines.joined(separator: "\n")
        }
    }
    
    /// Validate a JSON file
    /// - Parameter url: URL of the JSON file
    /// - Returns: Validation result
    static func validate(fileAt url: URL) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        var duplicateURLs: [String] = []
        var linkCount = 0
        
        // Read file
        guard let data = try? Data(contentsOf: url) else {
            errors.append("Could not read file at \(url.path)")
            return ValidationResult(
                isValid: false,
                linkCount: 0,
                errors: errors,
                warnings: warnings,
                duplicateURLs: duplicateURLs
            )
        }
        
        // Parse JSON
        let decoder = JSONDecoder()
        guard let links = try? decoder.decode([JSONLink].self, from: data) else {
            errors.append("Invalid JSON format. Expected array of {title, url} objects")
            return ValidationResult(
                isValid: false,
                linkCount: 0,
                errors: errors,
                warnings: warnings,
                duplicateURLs: duplicateURLs
            )
        }
        
        linkCount = links.count
        
        if links.isEmpty {
            warnings.append("File contains no links")
        }
        
        // Track URLs to find duplicates
        var seenURLs: [String: Int] = [:]
        
        // Validate each link
        for (index, link) in links.enumerated() {
            let linkNumber = index + 1
            
            // Check title
            if link.title.trimmingCharacters(in: .whitespaces).isEmpty {
                warnings.append("Link #\(linkNumber) has empty title")
            }
            
            if link.title.count > 200 {
                warnings.append("Link #\(linkNumber) has very long title (\(link.title.count) chars)")
            }
            
            // Check URL
            if link.url.trimmingCharacters(in: .whitespaces).isEmpty {
                errors.append("Link #\(linkNumber) (\(link.title)) has empty URL")
                continue
            }
            
            // Validate URL format
            if let url = URL(string: link.url) {
                if url.scheme == nil {
                    warnings.append("Link #\(linkNumber) (\(link.title)) has no URL scheme (http/https)")
                } else if !["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                    warnings.append("Link #\(linkNumber) (\(link.title)) uses non-HTTP(S) scheme: \(url.scheme ?? "unknown")")
                }
            } else {
                errors.append("Link #\(linkNumber) (\(link.title)) has invalid URL: \(link.url)")
            }
            
            // Track duplicates
            if let firstOccurrence = seenURLs[link.url] {
                duplicateURLs.append("Link #\(linkNumber) duplicates link #\(firstOccurrence): \(link.url)")
            } else {
                seenURLs[link.url] = linkNumber
            }
        }
        
        let isValid = errors.isEmpty
        
        return ValidationResult(
            isValid: isValid,
            linkCount: linkCount,
            errors: errors,
            warnings: warnings,
            duplicateURLs: duplicateURLs
        )
    }
    
    /// Validate JSON data
    /// - Parameter data: JSON data
    /// - Returns: Validation result
    static func validate(data: Data) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        var duplicateURLs: [String] = []
        
        // Parse JSON
        let decoder = JSONDecoder()
        guard let links = try? decoder.decode([JSONLink].self, from: data) else {
            errors.append("Invalid JSON format. Expected array of {title, url} objects")
            return ValidationResult(
                isValid: false,
                linkCount: 0,
                errors: errors,
                warnings: warnings,
                duplicateURLs: duplicateURLs
            )
        }
        
        let linkCount = links.count
        
        if links.isEmpty {
            warnings.append("Data contains no links")
        }
        
        // Track URLs to find duplicates
        var seenURLs: [String: Int] = [:]
        
        // Validate each link
        for (index, link) in links.enumerated() {
            let linkNumber = index + 1
            
            // Check title
            if link.title.trimmingCharacters(in: .whitespaces).isEmpty {
                warnings.append("Link #\(linkNumber) has empty title")
            }
            
            // Check URL
            if link.url.trimmingCharacters(in: .whitespaces).isEmpty {
                errors.append("Link #\(linkNumber) (\(link.title)) has empty URL")
                continue
            }
            
            // Validate URL format
            if let url = URL(string: link.url) {
                if url.scheme == nil {
                    warnings.append("Link #\(linkNumber) (\(link.title)) has no URL scheme")
                } else if !["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                    warnings.append("Link #\(linkNumber) (\(link.title)) uses non-HTTP(S) scheme")
                }
            } else {
                errors.append("Link #\(linkNumber) (\(link.title)) has invalid URL")
            }
            
            // Track duplicates
            if let firstOccurrence = seenURLs[link.url] {
                duplicateURLs.append("Link #\(linkNumber) duplicates link #\(firstOccurrence)")
            } else {
                seenURLs[link.url] = linkNumber
            }
        }
        
        let isValid = errors.isEmpty
        
        return ValidationResult(
            isValid: isValid,
            linkCount: linkCount,
            errors: errors,
            warnings: warnings,
            duplicateURLs: duplicateURLs
        )
    }
    
    /// Clean and normalize a JSON link file
    /// - Parameters:
    ///   - inputURL: Input file URL
    ///   - outputURL: Output file URL
    ///   - removeDuplicates: Whether to remove duplicate URLs
    /// - Throws: Cleaning errors
    static func clean(
        inputURL: URL,
        outputURL: URL,
        removeDuplicates: Bool = true
    ) throws {
        // Read and parse
        let data = try Data(contentsOf: inputURL)
        let decoder = JSONDecoder()
        var links = try decoder.decode([JSONLink].self, from: data)
        
        // Clean titles and URLs
        links = links.map { link in
            JSONLink(
                title: link.title.trimmingCharacters(in: .whitespacesAndNewlines),
                url: link.url.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        
        // Remove empty entries
        links = links.filter { !$0.title.isEmpty && !$0.url.isEmpty }
        
        // Remove duplicates if requested
        if removeDuplicates {
            var seen = Set<String>()
            links = links.filter { link in
                if seen.contains(link.url) {
                    return false
                } else {
                    seen.insert(link.url)
                    return true
                }
            }
        }
        
        // Write cleaned version
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let cleanedData = try encoder.encode(links)
        try cleanedData.write(to: outputURL)
    }
}

// MARK: - Example Usage

#if DEBUG
extension JSONLinkValidator {
    /// Example of how to validate a file
    static func exampleValidation() {
        // Validate from bundle
        if let url = Bundle.main.url(forResource: "links_from_notes", withExtension: "json") {
            let result = validate(fileAt: url)
            print(result.summary)
        }
    }
    
    /// Example of how to clean a file
    static func exampleCleaning() throws {
        guard let inputURL = Bundle.main.url(forResource: "links_from_notes", withExtension: "json") else {
            print("❌ Could not find input file")
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent("links_cleaned.json")
        
        try clean(inputURL: inputURL, outputURL: outputURL, removeDuplicates: true)
        print("✅ Cleaned file saved to: \(outputURL.path)")
    }
}
#endif
