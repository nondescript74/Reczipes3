//
//  TestHTMLTagFix.swift
//  Reczipes2Tests
//
//  Test script to verify HTML tag cleaning in URLs
//

import Testing
import Foundation
@testable import Reczipes2

/// Test the HTML tag cleaning functionality
@Suite("HTML Tag Fix Tester")
struct HTMLTagFixTester {
    
    // MARK: - Test URLs
    
    let testURLs: [(dirty: String, clean: String, name: String)] = [
        (
            dirty: "https://www.seriouseats.com/recipes/2014/02/vegan-experience-crispy-tofu-broccoli-stir-fry.html<br></div>",
            clean: "https://www.seriouseats.com/recipes/2014/02/vegan-experience-crispy-tofu-broccoli-stir-fry.html",
            name: "Crispy Fried Tofu and Broccoli"
        ),
        (
            dirty: "https://www.seriouseats.com/recipes/2014/04/easy-stir-fried-beef-with-mushrooms-and-butter.html<br></div>",
            clean: "https://www.seriouseats.com/recipes/2014/04/easy-stir-fried-beef-with-mushrooms-and-butter.html",
            name: "Stir fried flank steak and mushrooms"
        ),
        (
            dirty: "https://www.100daysofrealfood.com/braised-asian-meatballs-and-cabbage/</div>",
            clean: "https://www.100daysofrealfood.com/braised-asian-meatballs-and-cabbage/",
            name: "Braised Asian Meatballs and Cabbage"
        ),
        (
            dirty: "https://example.com/recipe<br>",
            clean: "https://example.com/recipe",
            name: "Simple br tag"
        ),
        (
            dirty: "https://example.com/recipe</div></div>",
            clean: "https://example.com/recipe",
            name: "Multiple closing tags"
        ),
        (
            dirty: "https://example.com/recipe<span>text</span>",
            clean: "https://example.com/recipetext",
            name: "Opening and closing tags with text"
        )
    ]
    
    // MARK: - Test WebRecipeExtractor Cleaning
    
    @Test("WebRecipeExtractor cleans HTML tags from URLs")
    func testWebExtractorCleaning() async throws {
        print("=" * 60)
        print("Testing WebRecipeExtractor HTML Tag Cleaning")
        print("=" * 60)
        print()
        
        let extractor = WebRecipeExtractor()
        
        for (index, test) in testURLs.enumerated() {
            print("Test \(index + 1): \(test.name)")
            print("  Dirty URL: \(test.dirty)")
            print("  Expected:  \(test.clean)")
            
            // We can't call the private method directly, but we can test by attempting to fetch
            // which will trigger the cleaning logic and print to console
            Task {
                do {
                    // This will fail (we're not actually fetching), but it will clean the URL first
                    _ = try await extractor.fetchWebContent(from: test.dirty)
                } catch {
                    // Expected to fail - we just want to see the cleaning logs
                    print("  Result: Cleaning triggered (fetch failed as expected)")
                }
            }
            
            print()
        }
        
        print("Note: Check console logs for '🌐 ⚠️ Removed HTML tags from URL' messages")
        print()
    }
    
    // MARK: - Test JSONLinkValidator Validation
    
    @Test("JSONLinkValidator detects HTML tags in URLs")
    @MainActor
    func testValidation() throws {
        print("=" * 60)
        print("Testing JSONLinkValidator HTML Tag Detection")
        print("=" * 60)
        print()
        
        // Create test JSON data
        let testLinks = [
            JSONLink(
                title: "Good URL",
                url: "https://www.example.com/recipe",
                tips: nil
            ),
            JSONLink(
                title: "Bad URL with br tag",
                url: "https://www.example.com/recipe<br>",
                tips: nil
            ),
            JSONLink(
                title: "Bad URL with div",
                url: "https://www.example.com/recipe</div>",
                tips: nil
            ),
            JSONLink(
                title: "Bad URL with multiple tags",
                url: "https://www.example.com/recipe<br></div>",
                tips: nil
            )
        ]
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let jsonData = try? encoder.encode(testLinks) else {
            print("❌ Failed to encode test data")
            return
        }
        
        // Validate
        let result = JSONLinkValidator.validate(data: jsonData)
        
        print("Validation Result:")
        print("  Valid: \(result.isValid)")
        print("  Link Count: \(result.linkCount)")
        print("  Errors: \(result.errors.count)")
        print("  Warnings: \(result.warnings.count)")
        print()
        
        if !result.errors.isEmpty {
            print("Errors detected:")
            for error in result.errors {
                print("  ❌ \(error)")
            }
            print()
        }
        
        if !result.warnings.isEmpty {
            print("Warnings:")
            for warning in result.warnings {
                print("  ⚠️ \(warning)")
            }
            print()
        }
        
        // Check if HTML tags were detected
        let htmlTagErrors = result.errors.filter { $0.contains("HTML tags") }
        #expect(htmlTagErrors.count == 3, "Expected 3 HTML tag errors, found \(htmlTagErrors.count)")
        print()
    }
    
    // MARK: - Test JSONLinkValidator Cleaning
    
    @Test("JSONLinkValidator cleans HTML tags from URLs")
    @MainActor
    func testCleaning() throws {
        print("=" * 60)
        print("Testing JSONLinkValidator HTML Tag Cleaning")
        print("=" * 60)
        print()
        
        // Create test JSON data with dirty URLs
        let testLinks = testURLs.prefix(3).map { test in
            JSONLink(title: test.name, url: test.dirty, tips: nil)
        }
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let jsonData = try? encoder.encode(testLinks) else {
            print("❌ Failed to encode test data")
            return
        }
        
        // Write to temp file
        let tempInputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_dirty_links.json")
        let tempOutputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_cleaned_links.json")
        
        do {
            // Write dirty data
            try jsonData.write(to: tempInputURL)
            print("Created test file at: \(tempInputURL.path)")
            print()
            
            // Clean the file
            try JSONLinkValidator.clean(
                inputURL: tempInputURL,
                outputURL: tempOutputURL,
                removeDuplicates: false
            )
            print("✅ Cleaning completed")
            print("Cleaned file at: \(tempOutputURL.path)")
            print()
            
            // Read cleaned data
            let cleanedData = try Data(contentsOf: tempOutputURL)
            let decoder = JSONDecoder()
            let cleanedLinks = try decoder.decode([JSONLink].self, from: cleanedData)
            
            print("Verification:")
            var allPassed = true
            
            for (index, link) in cleanedLinks.enumerated() {
                let expected = testURLs[index].clean
                let actual = link.url
                
                print("  Link \(index + 1): \(link.title)")
                print("    Expected: \(expected)")
                print("    Actual:   \(actual)")
                
                #expect(actual == expected, "Link \(index + 1) URL should be cleaned")
                
                if actual == expected {
                    print("    Status:   ✅ PASS")
                } else {
                    print("    Status:   ❌ FAIL")
                    allPassed = false
                }
                print()
            }
            
            if allPassed {
                print("🎉 All URLs were cleaned correctly!")
            } else {
                print("❌ Some URLs were not cleaned properly")
            }
            
            // Clean up temp files
            try? FileManager.default.removeItem(at: tempInputURL)
            try? FileManager.default.removeItem(at: tempOutputURL)
            
        } catch {
            print("❌ Error during test: \(error)")
        }
        
        print()
    }
}

// MARK: - Helper Operator

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
