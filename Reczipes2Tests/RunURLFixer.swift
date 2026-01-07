//
//  RunURLFixer.swift
//  Reczipes2Tests
//
//  Run this test to fix your actual links_from_notes.json file
//  This will process the real file and output detailed logs
//

import Testing
import Foundation
@testable import Reczipes2

@Suite("Run URL Fixer on Real Files")
@MainActor
struct RunURLFixer {
    
    /// Run this test to fix the actual links_from_notes.json file
    /// This will:
    /// 1. Fix all URLs with detailed logging
    /// 2. Verify each URL after fixing
    /// 3. Save the result to your Documents directory
    @Test("Fix links_from_notes.json")
    func fixRealFile() throws {
        print("\n\n")
        print("🚀 " + String(repeating: "=", count: 58))
        print("   FIXING links_from_notes.json")
        print(String(repeating: "=", count: 62))
        print()
        
        try FixLinksCommand.fixLinksFromNotes(saveToDocuments: true)
        
        print()
        print("=" + String(repeating: "=", count: 61))
        print("✅ DONE! Check your Documents folder for the fixed file.")
        print("=" + String(repeating: "=", count: 61))
        print()
    }
    
    /// Run the complete workflow: fix URLs + clean + remove duplicates
    /// This is the recommended approach for production use
    @Test("Complete workflow: fix, clean, and deduplicate")
    func completeWorkflow() throws {
        print("\n\n")
        try FixLinksCommand.completeWorkflow(saveToDocuments: true)
    }
    
    /// Just validate the current file without fixing
    /// Use this to see what issues exist
    @Test("Validate current file (no fixes)")
    func validateOnly() throws {
        print("\n\n")
        print("🔍 Validating links_from_notes.json")
        print("=" + String(repeating: "=", count: 59))
        print()
        
        guard let url = Bundle.main.url(forResource: "links_from_notes", withExtension: "json") else {
            Issue.record("Could not find links_from_notes.json")
            return
        }
        
        let result = JSONLinkValidator.validate(fileAt: url)
        print(result.summary)
        print()
        
        if !result.isValid {
            print("💡 TIP: Run 'Fix links_from_notes.json' test to fix these issues")
        }
        
        print()
    }
    
    /// Compare before and after to see what changed
    @Test("Show diff between original and fixed")
    func showDiff() throws {
        print("\n\n")
        print("📊 Before/After Comparison")
        print("=" + String(repeating: "=", count: 59))
        print()
        
        // Get original file
        guard let originalURL = Bundle.main.url(forResource: "links_from_notes", withExtension: "json") else {
            Issue.record("Could not find links_from_notes.json")
            return
        }
        
        // Validate original
        print("📄 ORIGINAL FILE:")
        print()
        let originalValidation = JSONLinkValidator.validate(fileAt: originalURL)
        print(originalValidation.summary)
        print()
        
        // Create temp fixed file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("temp_comparison.json")
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // Fix URLs
        print("🔧 FIXING URLS...")
        print()
        
        let report = try JSONLinkValidator.fixURLs(
            inputURL: originalURL,
            outputURL: tempURL,
            verify: true
        )
        
        // Show only the URLs that were fixed
        let fixedLinks = report.fixResults.filter { $0.wasFixed }
        
        if fixedLinks.isEmpty {
            print("✅ No URLs needed fixing!")
        } else {
            print("🔧 URLs that were fixed:")
            print()
            
            for result in fixedLinks {
                print(result.logEntry)
                print()
            }
        }
        
        // Validate fixed
        print("📄 AFTER FIXING:")
        print()
        let fixedValidation = JSONLinkValidator.validate(fileAt: tempURL)
        print(fixedValidation.summary)
        print()
        
        // Summary
        print("📊 SUMMARY:")
        print()
        print("  Total links: \(originalValidation.linkCount)")
        print("  URLs fixed: \(fixedLinks.count)")
        print("  Errors before: \(originalValidation.errors.count)")
        print("  Errors after: \(fixedValidation.errors.count)")
        print("  Warnings before: \(originalValidation.warnings.count)")
        print("  Warnings after: \(fixedValidation.warnings.count)")
        print()
    }
}
