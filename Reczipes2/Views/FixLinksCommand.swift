//
//  FixLinksCommand.swift
//  Reczipes2
//
//  Quick command to fix URLs in links_from_notes.json
//  Run this from your app or tests to fix all URLs
//

import Foundation

/// Command-line style tool to fix URLs in JSON files
struct FixLinksCommand {
    
    /// Fix the links_from_notes.json file
    /// - Parameter saveToDocuments: If true, saves to Documents directory. If false, overwrites original
    static func fixLinksFromNotes(saveToDocuments: Bool = true) throws {
        print("🔧 URL Fixer for links_from_notes.json")
        print("=" + String(repeating: "=", count: 59))
        print()
        
        // Find input file
        guard let inputURL = Bundle.main.url(forResource: "links_from_notes", withExtension: "json") else {
            throw FixError.fileNotFound("Could not find links_from_notes.json in bundle")
        }
        
        print("📂 Input file: \(inputURL.path)")
        
        // Determine output location
        let outputURL: URL
        if saveToDocuments {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            outputURL = documentsPath.appendingPathComponent("links_from_notes_FIXED.json")
        } else {
            // Create a backup first
            let backupURL = inputURL.deletingPathExtension()
                .appendingPathExtension("backup.json")
            try? FileManager.default.copyItem(at: inputURL, to: backupURL)
            print("💾 Backup created at: \(backupURL.path)")
            outputURL = inputURL
        }
        
        print("📝 Output file: \(outputURL.path)")
        print()
        print("🔍 Analyzing and fixing URLs...")
        print()
        
        // Run the fixer
        let report = try JSONLinkValidator.fixURLs(
            inputURL: inputURL,
            outputURL: outputURL,
            verify: true
        )
        
        // Print detailed report
        print(report.summary)
        print()
        
        // Validate the fixed file
        print("🔍 Validating fixed file...")
        print()
        
        let validation = JSONLinkValidator.validate(fileAt: outputURL)
        print(validation.summary)
        print()
        
        // Summary
        if validation.isValid {
            print("✅ SUCCESS! All URLs have been fixed and validated.")
        } else {
            print("⚠️ URLs have been fixed, but some validation issues remain.")
            print("   Review the errors above for details.")
        }
        
        print()
        print("💾 Fixed file saved to:")
        print("   \(outputURL.path)")
    }
    
    /// Fix any JSON file at a given path
    /// - Parameters:
    ///   - inputPath: Path to input JSON file
    ///   - outputPath: Optional path to output file (if nil, overwrites input after backup)
    static func fixFile(inputPath: String, outputPath: String? = nil) throws {
        let inputURL = URL(fileURLWithPath: inputPath)
        
        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw FixError.fileNotFound("File not found: \(inputPath)")
        }
        
        let outputURL: URL
        if let outputPath = outputPath {
            outputURL = URL(fileURLWithPath: outputPath)
        } else {
            // Create backup
            let backupPath = inputPath.replacingOccurrences(of: ".json", with: "_backup.json")
            let backupURL = URL(fileURLWithPath: backupPath)
            try FileManager.default.copyItem(at: inputURL, to: backupURL)
            print("💾 Backup created at: \(backupPath)")
            outputURL = inputURL
        }
        
        print("🔧 Fixing URLs in: \(inputPath)")
        print()
        
        let report = try JSONLinkValidator.fixURLs(
            inputURL: inputURL,
            outputURL: outputURL,
            verify: true
        )
        
        print(report.summary)
        print()
        print("✅ Fixed file saved to: \(outputURL.path)")
    }
    
    /// Complete workflow: fix URLs, clean, and remove duplicates
    static func completeWorkflow(saveToDocuments: Bool = true) throws {
        print("🚀 Complete Link Cleaning Workflow")
        print("=" + String(repeating: "=", count: 59))
        print()
        
        guard let inputURL = Bundle.main.url(forResource: "links_from_notes", withExtension: "json") else {
            throw FixError.fileNotFound("Could not find links_from_notes.json in bundle")
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fixedURL = documentsPath.appendingPathComponent("links_step1_fixed.json")
        let finalURL = documentsPath.appendingPathComponent("links_FINAL.json")
        
        // Step 1: Fix URLs
        print("📝 Step 1/3: Fixing URLs...")
        print()
        
        let fixReport = try JSONLinkValidator.fixURLs(
            inputURL: inputURL,
            outputURL: fixedURL,
            verify: true
        )
        
        print(fixReport.summary)
        print()
        
        // Step 2: Clean and remove duplicates
        print("🧹 Step 2/3: Cleaning and removing duplicates...")
        print()
        
        try JSONLinkValidator.clean(
            inputURL: fixedURL,
            outputURL: finalURL,
            removeDuplicates: true
        )
        
        print("✅ Cleaning complete")
        print()
        
        // Step 3: Final validation
        print("🔍 Step 3/3: Final validation...")
        print()
        
        let finalValidation = JSONLinkValidator.validate(fileAt: finalURL)
        print(finalValidation.summary)
        print()
        
        // Summary
        print("=" + String(repeating: "=", count: 59))
        print("🎉 WORKFLOW COMPLETE!")
        print("=" + String(repeating: "=", count: 59))
        print()
        print("Original file: \(inputURL.lastPathComponent)")
        print("  Total links: \(fixReport.totalLinks)")
        print()
        print("Fixed file: \(finalURL.lastPathComponent)")
        print("  URLs fixed: \(fixReport.fixedCount)")
        print("  Final link count: \(finalValidation.linkCount)")
        print("  Valid: \(finalValidation.isValid ? "✅" : "❌")")
        print()
        print("📂 Location: \(finalURL.path)")
        print()
        
        // Offer to delete intermediate file
        try? FileManager.default.removeItem(at: fixedURL)
    }
    
    enum FixError: Error, LocalizedError {
        case fileNotFound(String)
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound(let message):
                return message
            }
        }
    }
}

// MARK: - Example Usage in Tests or App

#if DEBUG
extension FixLinksCommand {
    /// Quick test to demonstrate usage
    static func runExample() {
        do {
            // Option 1: Just fix URLs
            // try fixLinksFromNotes(saveToDocuments: true)
            
            // Option 2: Complete workflow (recommended)
            try completeWorkflow(saveToDocuments: true)
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}
#endif
