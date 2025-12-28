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
    struct ValidationResult: Sendable {
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
    
    /// URL fix result for a single link
    struct URLFixResult: Sendable {
        let linkNumber: Int
        let title: String
        let originalURL: String
        let fixedURL: String
        let wasFixed: Bool
        let issues: [String]
        let verificationStatus: VerificationStatus
        
        enum VerificationStatus: Sendable {
            case valid
            case invalid(String)
            case skipped
        }
        
        var logEntry: String {
            var lines: [String] = []
            
            if wasFixed {
                lines.append("🔧 Link #\(linkNumber): \(title)")
                lines.append("   Original: \(originalURL)")
                lines.append("   Fixed:    \(fixedURL)")
                lines.append("   Issues fixed:")
                issues.forEach { lines.append("     • \($0)") }
                
                switch verificationStatus {
                case .valid:
                    lines.append("   ✅ Verification: URL is now valid")
                case .invalid(let reason):
                    lines.append("   ❌ Verification failed: \(reason)")
                case .skipped:
                    lines.append("   ⏭️ Verification skipped")
                }
            } else {
                lines.append("✅ Link #\(linkNumber): \(title)")
                lines.append("   URL: \(originalURL)")
                lines.append("   No fixes needed")
            }
            
            return lines.joined(separator: "\n")
        }
    }
    
    /// Complete fix report
    struct FixReport: Sendable {
        let totalLinks: Int
        let fixedCount: Int
        let unfixedCount: Int
        let fixResults: [URLFixResult]
        
        var summary: String {
            var lines: [String] = []
            lines.append("=" + String(repeating: "=", count: 59))
            lines.append("URL Fix Report")
            lines.append("=" + String(repeating: "=", count: 59))
            lines.append("")
            lines.append("Total links: \(totalLinks)")
            lines.append("Fixed: \(fixedCount)")
            lines.append("Already valid: \(unfixedCount)")
            lines.append("")
            
            if !fixResults.isEmpty {
                lines.append("Detailed Results:")
                lines.append("")
                fixResults.forEach { result in
                    lines.append(result.logEntry)
                    lines.append("")
                }
            }
            
            let failedVerifications = fixResults.filter {
                if case .invalid = $0.verificationStatus { return true }
                return false
            }
            
            if !failedVerifications.isEmpty {
                lines.append("⚠️ Warning: \(failedVerifications.count) link(s) failed verification after fixing")
            }
            
            lines.append("=" + String(repeating: "=", count: 59))
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
            errors.append("Invalid JSON format. Expected array of {title, url, tips?} objects")
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
            
            // Check for HTML tags in URL
            if link.url.contains("<") || link.url.contains(">") {
                errors.append("Link #\(linkNumber) (\(link.title)) contains HTML tags in URL: \(link.url)")
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
            
            // Validate tips if present
            if let tips = link.tips {
                if tips.isEmpty {
                    // Empty tips array is OK, but might want to mention it
                    // (Not adding a warning as this is intentional)
                } else {
                    let emptyTips = tips.filter { $0.trimmingCharacters(in: .whitespaces).isEmpty }
                    if !emptyTips.isEmpty {
                        warnings.append("Link #\(linkNumber) (\(link.title)) has \(emptyTips.count) empty tip(s)")
                    }
                    
                    // Check for very long tips (might be accidentally pasted data)
                    let longTips = tips.filter { $0.count > 500 }
                    if !longTips.isEmpty {
                        warnings.append("Link #\(linkNumber) (\(link.title)) has \(longTips.count) very long tip(s) (>500 chars)")
                    }
                }
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
            errors.append("Invalid JSON format. Expected array of {title, url, tips?} objects")
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
            
            // Check for HTML tags in URL
            if link.url.contains("<") || link.url.contains(">") {
                errors.append("Link #\(linkNumber) (\(link.title)) contains HTML tags in URL")
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
            
            // Validate tips if present
            if let tips = link.tips, !tips.isEmpty {
                let emptyTips = tips.filter { $0.trimmingCharacters(in: .whitespaces).isEmpty }
                if !emptyTips.isEmpty {
                    warnings.append("Link #\(linkNumber) (\(link.title)) has \(emptyTips.count) empty tip(s)")
                }
                
                let longTips = tips.filter { $0.count > 500 }
                if !longTips.isEmpty {
                    warnings.append("Link #\(linkNumber) (\(link.title)) has \(longTips.count) very long tip(s)")
                }
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
    
    // MARK: - URL Fixing
    
    /// Fix all URLs in a JSON file with detailed logging
    /// - Parameters:
    ///   - inputURL: Input file URL
    ///   - outputURL: Output file URL (can be same as input to overwrite)
    ///   - verify: Whether to verify each URL after fixing
    /// - Returns: Fix report with details of all changes
    /// - Throws: File reading/writing errors
    static func fixURLs(
        inputURL: URL,
        outputURL: URL,
        verify: Bool = true
    ) throws -> FixReport {
        // Read and parse
        let data = try Data(contentsOf: inputURL)
        let decoder = JSONDecoder()
        let originalLinks = try decoder.decode([JSONLink].self, from: data)
        
        var fixResults: [URLFixResult] = []
        var fixedLinks: [JSONLink] = []
        
        // Process each link
        for (index, link) in originalLinks.enumerated() {
            let linkNumber = index + 1
            let result = fixURL(
                for: link,
                linkNumber: linkNumber,
                verify: verify
            )
            
            fixResults.append(result)
            fixedLinks.append(
                JSONLink(
                    title: link.title,
                    url: result.fixedURL,
                    tips: link.tips
                )
            )
        }
        
        // Write fixed version
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let fixedData = try encoder.encode(fixedLinks)
        try fixedData.write(to: outputURL)
        
        // Create report
        let fixedCount = fixResults.filter { $0.wasFixed }.count
        let report = FixReport(
            totalLinks: originalLinks.count,
            fixedCount: fixedCount,
            unfixedCount: originalLinks.count - fixedCount,
            fixResults: fixResults
        )
        
        return report
    }
    
    /// Fix a single URL with detailed issue tracking
    /// - Parameters:
    ///   - link: The link to fix
    ///   - linkNumber: Link number for reporting
    ///   - verify: Whether to verify the URL after fixing
    /// - Returns: Fix result with details
    private static func fixURL(
        for link: JSONLink,
        linkNumber: Int,
        verify: Bool
    ) -> URLFixResult {
        var currentURL = link.url
        var issues: [String] = []
        let originalURL = currentURL
        
        // 1. Remove HTML tags
        let withoutHTML = cleanHTML(from: currentURL)
        if withoutHTML != currentURL {
            issues.append("Removed HTML tags")
            currentURL = withoutHTML
        }
        
        // 2. Trim whitespace and newlines
        let trimmed = currentURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed != currentURL {
            issues.append("Trimmed whitespace")
            currentURL = trimmed
        }
        
        // 3. Remove invisible characters (zero-width spaces, etc.)
        let withoutInvisible = removeInvisibleCharacters(from: currentURL)
        if withoutInvisible != currentURL {
            issues.append("Removed invisible characters")
            currentURL = withoutInvisible
        }
        
        // 4. Decode HTML entities
        let decodedHTML = decodeHTMLEntities(currentURL)
        if decodedHTML != currentURL {
            issues.append("Decoded HTML entities")
            currentURL = decodedHTML
        }
        
        // 5. Fix common URL issues
        let fixedCommon = fixCommonURLIssues(currentURL)
        if fixedCommon != currentURL {
            issues.append("Fixed common URL issues")
            currentURL = fixedCommon
        }
        
        // 6. Verify the URL if requested
        let verificationStatus: URLFixResult.VerificationStatus
        if verify {
            verificationStatus = verifyURL(currentURL)
        } else {
            verificationStatus = .skipped
        }
        
        let wasFixed = currentURL != originalURL
        
        return URLFixResult(
            linkNumber: linkNumber,
            title: link.title,
            originalURL: originalURL,
            fixedURL: currentURL,
            wasFixed: wasFixed,
            issues: issues,
            verificationStatus: verificationStatus
        )
    }
    
    /// Verify that a URL is valid and well-formed
    /// - Parameter urlString: URL string to verify
    /// - Returns: Verification status
    private static func verifyURL(_ urlString: String) -> URLFixResult.VerificationStatus {
        // Check for empty URL
        if urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid("URL is empty")
        }
        
        // Check for HTML tags
        if urlString.contains("<") || urlString.contains(">") {
            return .invalid("URL still contains HTML tags")
        }
        
        // Try to create URL
        guard let url = URL(string: urlString) else {
            return .invalid("URL string is not a valid URL")
        }
        
        // Check for scheme
        guard let scheme = url.scheme?.lowercased() else {
            return .invalid("URL has no scheme (http/https)")
        }
        
        // Check for HTTP/HTTPS
        guard ["http", "https"].contains(scheme) else {
            return .invalid("URL scheme is '\(scheme)' (expected http or https)")
        }
        
        // Check for host
        guard url.host != nil else {
            return .invalid("URL has no host/domain")
        }
        
        // All checks passed
        return .valid
    }
    
    /// Remove invisible characters from a string
    /// - Parameter string: Input string
    /// - Returns: String without invisible characters
    private static func removeInvisibleCharacters(from string: String) -> String {
        // Remove zero-width spaces, zero-width joiners, etc.
        let invisibleCharacters: [Character] = [
            "\u{200B}", // Zero-width space
            "\u{200C}", // Zero-width non-joiner
            "\u{200D}", // Zero-width joiner
            "\u{FEFF}", // Zero-width no-break space (BOM)
            "\u{00AD}"  // Soft hyphen
        ]
        
        var cleaned = string
        for char in invisibleCharacters {
            cleaned = cleaned.replacingOccurrences(of: String(char), with: "")
        }
        
        return cleaned
    }
    
    /// Decode common HTML entities
    /// - Parameter string: String that may contain HTML entities
    /// - Returns: String with decoded entities
    private static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        
        // Common HTML entities - NOTE: Order matters! Process &amp; last to avoid double-decoding
        let entities: [(entity: String, replacement: String)] = [
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&nbsp;", " "),
            ("&#x2F;", "/"),
            ("&#47;", "/"),
            // Extended Latin characters
            ("&Agrave;", "À"),
            ("&Aacute;", "Á"),
            ("&Acirc;", "Â"),
            ("&Atilde;", "Ã"),
            ("&Auml;", "Ä"),
            ("&Aring;", "Å"),
            ("&AElig;", "Æ"),
            ("&Ccedil;", "Ç"),
            ("&Egrave;", "È"),
            ("&Eacute;", "É"),
            ("&Ecirc;", "Ê"),
            ("&Euml;", "Ë"),
            ("&Igrave;", "Ì"),
            ("&Iacute;", "Í"),
            ("&Icirc;", "Î"),
            ("&Iuml;", "Ï"),
            ("&Ntilde;", "Ñ"),
            ("&Ograve;", "Ò"),
            ("&Oacute;", "Ó"),
            ("&Ocirc;", "Ô"),
            ("&Otilde;", "Õ"),
            ("&Ouml;", "Ö"),
            ("&Oslash;", "Ø"),
            ("&Ugrave;", "Ù"),
            ("&Uacute;", "Ú"),
            ("&Ucirc;", "Û"),
            ("&Uuml;", "Ü"),
            ("&Yacute;", "Ý"),
            ("&agrave;", "à"),
            ("&aacute;", "á"),
            ("&acirc;", "â"),
            ("&atilde;", "ã"),
            ("&auml;", "ä"),
            ("&aring;", "å"),
            ("&aelig;", "æ"),
            ("&ccedil;", "ç"),
            ("&egrave;", "è"),
            ("&eacute;", "é"),
            ("&ecirc;", "ê"),
            ("&euml;", "ë"),
            ("&igrave;", "ì"),
            ("&iacute;", "í"),
            ("&icirc;", "î"),
            ("&iuml;", "ï"),
            ("&ntilde;", "ñ"),
            ("&ograve;", "ò"),
            ("&oacute;", "ó"),
            ("&ocirc;", "ô"),
            ("&otilde;", "õ"),
            ("&ouml;", "ö"),
            ("&oslash;", "ø"),
            ("&ugrave;", "ù"),
            ("&uacute;", "ú"),
            ("&ucirc;", "û"),
            ("&uuml;", "ü"),
            ("&yacute;", "ý"),
            ("&yuml;", "ÿ"),
            // Process &amp; last to avoid double-decoding
            ("&amp;", "&")
        ]
        
        for entity in entities {
            result = result.replacingOccurrences(of: entity.entity, with: entity.replacement)
        }
        
        // Handle numeric entities (&#123; or &#xAB;)
        let decimalPattern = "&#(\\d+);"
        let hexPattern = "&#x([0-9A-Fa-f]+);"
        
        if let decimalRegex = try? NSRegularExpression(pattern: decimalPattern) {
            let nsString = result as NSString
            let matches = decimalRegex.matches(in: result, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if match.numberOfRanges > 1 {
                    let numRange = match.range(at: 1)
                    let numString = nsString.substring(with: numRange)
                    
                    if let num = Int(numString), let scalar = UnicodeScalar(num) {
                        let char = String(Character(scalar))
                        let fullRange = match.range(at: 0)
                        result = (result as NSString).replacingCharacters(in: fullRange, with: char)
                    }
                }
            }
        }
        
        if let hexRegex = try? NSRegularExpression(pattern: hexPattern) {
            let nsString = result as NSString
            let matches = hexRegex.matches(in: result, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if match.numberOfRanges > 1 {
                    let numRange = match.range(at: 1)
                    let numString = nsString.substring(with: numRange)
                    
                    if let num = Int(numString, radix: 16), let scalar = UnicodeScalar(num) {
                        let char = String(Character(scalar))
                        let fullRange = match.range(at: 0)
                        result = (result as NSString).replacingCharacters(in: fullRange, with: char)
                    }
                }
            }
        }
        
        return result
    }
    
    /// Fix common URL issues
    /// - Parameter urlString: URL string to fix
    /// - Returns: Fixed URL string
    private static func fixCommonURLIssues(_ urlString: String) -> String {
        var fixed = urlString
        
        // Remove trailing slashes from parameters (but keep path trailing slashes)
        // Example: "http://example.com/path?param=value/" -> "http://example.com/path?param=value"
        if fixed.contains("?") {
            let components = fixed.components(separatedBy: "?")
            if components.count == 2 {
                let path = components[0]
                let query = components[1].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                fixed = path + "?" + query
            }
        }
        
        // Fix double slashes in path (but not in protocol)
        if let urlComponents = URLComponents(string: fixed) {
            var components = urlComponents
            let path = components.path
            let fixedPath = path.replacingOccurrences(of: "//", with: "/")
            components.path = fixedPath
            if let newURL = components.url?.absoluteString {
                fixed = newURL
            }
        }
        
        // Remove spaces in URL (replace with %20)
        fixed = fixed.replacingOccurrences(of: " ", with: "%20")
        
        return fixed
    }
    
    // MARK: - Cleaning
    
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
        
        // Clean titles, URLs, and tips
        links = links.map { link in
            // Clean tips by trimming whitespace and removing empty strings
            let cleanedTips: [String]? = link.tips?.compactMap { tip in
                let trimmed = tip.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            
            // Clean URL by removing HTML tags and trimming
            let cleanedURL = cleanHTML(from: link.url).trimmingCharacters(in: .whitespacesAndNewlines)
            
            return JSONLink(
                title: link.title.trimmingCharacters(in: .whitespacesAndNewlines),
                url: cleanedURL,
                tips: cleanedTips?.isEmpty == true ? nil : cleanedTips
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
    
    /// Remove HTML tags from a string
    /// - Parameter string: String that may contain HTML tags
    /// - Returns: String with HTML tags removed
    private static func cleanHTML(from string: String) -> String {
        // Remove HTML tags using regex
        let pattern = "<[^>]+>"
        let cleanedString = string.replacingOccurrences(
            of: pattern,
            with: "",
            options: .regularExpression
        )
        return cleanedString
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
    
    /// Example of how to fix URLs in a file
    static func exampleFixURLs() throws {
        guard let inputURL = Bundle.main.url(forResource: "links_from_notes", withExtension: "json") else {
            print("❌ Could not find input file")
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent("links_fixed.json")
        
        // Fix all URLs with verification
        let report = try fixURLs(
            inputURL: inputURL,
            outputURL: outputURL,
            verify: true
        )
        
        // Print the detailed report
        print(report.summary)
        print("\n✅ Fixed file saved to: \(outputURL.path)")
        
        // Optionally validate the fixed file
        let validationResult = validate(fileAt: outputURL)
        print("\nPost-Fix Validation:")
        print(validationResult.summary)
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
    
    /// Example of complete workflow: fix URLs, then clean
    static func exampleCompleteWorkflow() throws {
        guard let inputURL = Bundle.main.url(forResource: "links_from_notes", withExtension: "json") else {
            print("❌ Could not find input file")
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fixedURL = documentsPath.appendingPathComponent("links_fixed.json")
        let finalURL = documentsPath.appendingPathComponent("links_final.json")
        
        print("🔧 Step 1: Fixing URLs...")
        print()
        
        let fixReport = try fixURLs(
            inputURL: inputURL,
            outputURL: fixedURL,
            verify: true
        )
        print(fixReport.summary)
        
        print()
        print("🧹 Step 2: Cleaning and removing duplicates...")
        print()
        
        try clean(
            inputURL: fixedURL,
            outputURL: finalURL,
            removeDuplicates: true
        )
        
        print("✅ Cleaning completed")
        print()
        print("📊 Step 3: Final validation...")
        print()
        
        let finalValidation = validate(fileAt: finalURL)
        print(finalValidation.summary)
        
        print()
        print("🎉 Complete! Final file saved to: \(finalURL.path)")
    }
}
#endif
