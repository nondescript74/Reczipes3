//
//  URLFixerTests.swift
//  Reczipes2Tests
//
//  Tests for the enhanced URL fixing functionality
//

import Testing
import Foundation
@testable import Reczipes2

@Suite("URL Fixer Tests")
struct URLFixerTests {
    
    // MARK: - Test Individual URL Fixes
    
    @Test("Remove HTML tags from URLs")
    func testHTMLTagRemoval() throws {
        let testCases: [(input: String, expected: String)] = [
            (
                "https://example.com/recipe<br>",
                "https://example.com/recipe"
            ),
            (
                "https://example.com/recipe</div>",
                "https://example.com/recipe"
            ),
            (
                "https://example.com/recipe<br></div>",
                "https://example.com/recipe"
            ),
            (
                "https://www.seriouseats.com/recipes/2014/02/vegan-tofu-stir-fry.html<br></div>",
                "https://www.seriouseats.com/recipes/2014/02/vegan-tofu-stir-fry.html"
            )
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let link = JSONLink(title: "Test \(index + 1)", url: testCase.input, tips: nil)
            let result = try runFixTest(link: link, expectedURL: testCase.expected)
            #expect(result.wasFixed, "Link should have been fixed")
            #expect(result.fixedURL == testCase.expected, "URL should be: \(testCase.expected)")
        }
    }
    
    @Test("Trim whitespace from URLs")
    func testWhitespaceTrimming() throws {
        let testCases: [(input: String, expected: String)] = [
            (
                "  https://example.com/recipe  ",
                "https://example.com/recipe"
            ),
            (
                "https://example.com/recipe\n",
                "https://example.com/recipe"
            ),
            (
                "\thttps://example.com/recipe\t",
                "https://example.com/recipe"
            )
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let link = JSONLink(title: "Test \(index + 1)", url: testCase.input, tips: nil)
            let result = try runFixTest(link: link, expectedURL: testCase.expected)
            #expect(result.wasFixed, "Link should have been fixed")
            #expect(result.fixedURL == testCase.expected, "URL should be trimmed")
        }
    }
    
    @Test("Decode HTML entities")
    func testHTMLEntityDecoding() throws {
        let testCases: [(input: String, expected: String)] = [
            (
                "https://example.com/recipe?name=Caf&eacute;",
                "https://example.com/recipe?name=Caf%C3%A9"  // Properly percent-encoded é
            ),
            (
                "https://example.com/recipe?q=Rock%20&amp;%20Roll",
                "https://example.com/recipe?q=Rock%20&%20Roll"
            ),
            (
                "https://example.com&#x2F;recipe",
                "https://example.com/recipe"
            )
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let link = JSONLink(title: "Test \(index + 1)", url: testCase.input, tips: nil)
            let result = try runFixTest(link: link, expectedURL: testCase.expected)
            #expect(result.wasFixed, "Link should have been fixed")
            #expect(result.fixedURL == testCase.expected, "HTML entities should be decoded and properly encoded")
        }
    }
    
    @Test("Fix common URL issues")
    func testCommonURLIssues() throws {
        let testCases: [(input: String, expected: String)] = [
            (
                "https://example.com/recipe with spaces",
                "https://example.com/recipe%20with%20spaces"
            ),
            (
                "https://example.com//double//slashes",
                "https://example.com/double/slashes"
            )
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let link = JSONLink(title: "Test \(index + 1)", url: testCase.input, tips: nil)
            let result = try runFixTest(link: link, expectedURL: testCase.expected)
            #expect(result.wasFixed, "Link should have been fixed")
        }
    }
    
    @Test("URL verification works correctly")
    func testURLVerification() throws {
        let validURL = "https://example.com/recipe"
        let invalidURL = "not-a-url"
        let noSchemeURL = "example.com/recipe"
        
        let validLink = JSONLink(title: "Valid", url: validURL, tips: nil)
        let invalidLink = JSONLink(title: "Invalid", url: invalidURL, tips: nil)
        let noSchemeLink = JSONLink(title: "No Scheme", url: noSchemeURL, tips: nil)
        
        let validResult = try runFixTest(link: validLink, expectedURL: validURL, verify: true)
        let invalidResult = try runFixTest(link: invalidLink, expectedURL: invalidURL, verify: true)
        let noSchemeResult = try runFixTest(link: noSchemeLink, expectedURL: noSchemeURL, verify: true)
        
        if case .valid = validResult.verificationStatus {
            // Pass
        } else {
            Issue.record("Valid URL should pass verification")
        }
        
        if case .invalid = invalidResult.verificationStatus {
            // Pass
        } else {
            Issue.record("Invalid URL should fail verification")
        }
        
        if case .invalid = noSchemeResult.verificationStatus {
            // Pass
        } else {
            Issue.record("URL without scheme should fail verification")
        }
    }
    
    // MARK: - Test Full File Processing
    
    @Test("Fix URLs in complete JSON file")
    func testCompleteFileFixing() throws {
        // Create test JSON with various issues
        let testLinks = [
            JSONLink(
                title: "Clean URL",
                url: "https://example.com/recipe1",
                tips: nil
            ),
            JSONLink(
                title: "URL with HTML",
                url: "https://example.com/recipe2<br></div>",
                tips: nil
            ),
            JSONLink(
                title: "URL with whitespace",
                url: "  https://example.com/recipe3  ",
                tips: nil
            ),
            JSONLink(
                title: "URL with entities",
                url: "https://example.com/recipe4?q=Rock%20&amp;%20Roll",
                tips: nil
            ),
            JSONLink(
                title: "URL with spaces",
                url: "https://example.com/recipe with spaces",
                tips: nil
            )
        ]
        
        // Create temp files
        let tempInputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_urls_to_fix.json")
        let tempOutputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_urls_fixed.json")
        
        // Write test data
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(testLinks)
        try jsonData.write(to: tempInputURL)
        
        // Fix URLs
        let report = try JSONLinkValidator.fixURLs(
            inputURL: tempInputURL,
            outputURL: tempOutputURL,
            verify: true
        )
        
        // Verify report
        #expect(report.totalLinks == 5, "Should have 5 links")
        #expect(report.fixedCount == 4, "Should have fixed 4 links")
        #expect(report.unfixedCount == 1, "Should have 1 unfixed link")
        
        print("\n" + report.summary)
        
        // Read fixed file and verify
        let fixedData = try Data(contentsOf: tempOutputURL)
        let decoder = JSONDecoder()
        let fixedLinks = try decoder.decode([JSONLink].self, from: fixedData)
        
        #expect(fixedLinks[0].url == "https://example.com/recipe1")
        #expect(fixedLinks[1].url == "https://example.com/recipe2")
        #expect(fixedLinks[2].url == "https://example.com/recipe3")
        #expect(fixedLinks[3].url == "https://example.com/recipe4?q=Rock%20&%20Roll")
        #expect(fixedLinks[4].url == "https://example.com/recipe%20with%20spaces")
        
        // Clean up
        try? FileManager.default.removeItem(at: tempInputURL)
        try? FileManager.default.removeItem(at: tempOutputURL)
    }
    
    @Test("Complete workflow: fix and clean")
    func testCompleteWorkflow() throws {
        // Create test JSON with issues and duplicates
        let testLinks = [
            JSONLink(title: "Recipe 1", url: "https://example.com/recipe1<br>", tips: nil),
            JSONLink(title: "Recipe 2", url: "https://example.com/recipe2", tips: nil),
            JSONLink(title: "Recipe 1 Duplicate", url: "https://example.com/recipe1<br>", tips: nil),
            JSONLink(title: "Recipe 3", url: "  https://example.com/recipe3  ", tips: nil)
        ]
        
        // Create temp files
        let tempDir = FileManager.default.temporaryDirectory
        let inputURL = tempDir.appendingPathComponent("test_workflow_input.json")
        let fixedURL = tempDir.appendingPathComponent("test_workflow_fixed.json")
        let finalURL = tempDir.appendingPathComponent("test_workflow_final.json")
        
        // Write test data
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(testLinks)
        try jsonData.write(to: inputURL)
        
        // Step 1: Fix URLs
        let fixReport = try JSONLinkValidator.fixURLs(
            inputURL: inputURL,
            outputURL: fixedURL,
            verify: true
        )
        
        print("\n" + fixReport.summary)
        
        // Step 2: Clean and remove duplicates
        try JSONLinkValidator.clean(
            inputURL: fixedURL,
            outputURL: finalURL,
            removeDuplicates: true
        )
        
        // Step 3: Verify final result
        let finalData = try Data(contentsOf: finalURL)
        let decoder = JSONDecoder()
        let finalLinks = try decoder.decode([JSONLink].self, from: finalData)
        
        #expect(finalLinks.count == 3, "Should have 3 unique links after deduplication")
        
        // Validate final file
        let validationResult = JSONLinkValidator.validate(fileAt: finalURL)
        #expect(validationResult.isValid, "Final file should be valid")
        #expect(validationResult.duplicateURLs.isEmpty, "Should have no duplicates")
        
        print("\nFinal Validation:")
        print(validationResult.summary)
        
        // Clean up
        try? FileManager.default.removeItem(at: inputURL)
        try? FileManager.default.removeItem(at: fixedURL)
        try? FileManager.default.removeItem(at: finalURL)
    }
    
    // MARK: - Helper Methods
    
    /// Helper to run a fix test on a single link
    private func runFixTest(
        link: JSONLink,
        expectedURL: String,
        verify: Bool = false
    ) throws -> JSONLinkValidator.URLFixResult {
        // Create temp file
        let tempInputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_single_fix_\(UUID().uuidString).json")
        let tempOutputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_single_fixed_\(UUID().uuidString).json")
        
        defer {
            try? FileManager.default.removeItem(at: tempInputURL)
            try? FileManager.default.removeItem(at: tempOutputURL)
        }
        
        // Write single link
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode([link])
        try jsonData.write(to: tempInputURL)
        
        // Fix it
        let report = try JSONLinkValidator.fixURLs(
            inputURL: tempInputURL,
            outputURL: tempOutputURL,
            verify: verify
        )
        
        return report.fixResults[0]
    }
}
