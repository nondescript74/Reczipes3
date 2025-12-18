//
//  WebRecipeExtractor.swift
//  Reczipes2
//
//  Created for web-based recipe extraction
//

import Foundation

/// Extracts recipe content from web pages
class WebRecipeExtractor {
    
    /// Fetch and extract text content from a URL
    /// - Parameter urlString: The URL of the recipe webpage
    /// - Returns: The HTML content as a string
    func fetchWebContent(from urlString: String) async throws -> String {
        print("🌐 ========== WEB CONTENT FETCH START ==========")
        print("🌐 URL: \(urlString)")
        
        // Validate URL
        guard let url = URL(string: urlString) else {
            print("🌐 ❌ Invalid URL format")
            throw WebExtractionError.invalidURL
        }
        
        // Ensure it's an HTTP(S) URL
        guard let scheme = url.scheme, ["http", "https"].contains(scheme.lowercased()) else {
            print("🌐 ❌ URL must use HTTP or HTTPS protocol")
            throw WebExtractionError.invalidURL
        }
        
        print("🌐 Creating URL request...")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        // Set a user agent to avoid being blocked by some sites
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        print("🌐 Fetching webpage...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🌐 ❌ Invalid response type")
            throw WebExtractionError.networkError
        }
        
        print("🌐 HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("🌐 ❌ HTTP error: \(httpResponse.statusCode)")
            throw WebExtractionError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Detect encoding from response
        var encoding = String.Encoding.utf8
        if let encodingName = httpResponse.textEncodingName {
            print("🌐 Detected encoding: \(encodingName)")
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
            if cfEncoding != kCFStringEncodingInvalidId {
                encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
            }
        }
        
        guard let htmlContent = String(data: data, encoding: encoding) else {
            print("🌐 ❌ Failed to decode HTML content")
            throw WebExtractionError.decodingError
        }
        
        print("🌐 ✅ Successfully fetched HTML content")
        print("🌐 Content length: \(htmlContent.count) characters")
        print("🌐 ========== WEB CONTENT FETCH END ==========")
        
        return htmlContent
    }
    
    /// Clean HTML content by removing unwanted tags while preserving structured data
    /// This provides a cleaner input for the LLM while keeping JSON-LD recipe data
    func cleanHTML(_ html: String) -> String {
        print("🧹 Cleaning HTML content...")
        var cleaned = html
        
        // PRESERVE JSON-LD structured data - it contains the recipe!
        // Extract all JSON-LD script tags before cleaning
        var jsonLDScripts: [String] = []
        let jsonLDPattern = "<script[^>]*type=[\"']application/ld\\+json[\"'][^>]*>(.*?)</script>"
        if let regex = try? NSRegularExpression(pattern: jsonLDPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                if match.numberOfRanges > 1 {
                    let jsonContent = nsString.substring(with: match.range(at: 1))
                    jsonLDScripts.append(jsonContent)
                    print("🧹 📦 Preserved JSON-LD structured data (\(jsonContent.count) chars)")
                }
            }
        }
        
        // Remove OTHER script tags (JavaScript) but NOT JSON-LD
        cleaned = cleaned.replacingOccurrences(
            of: "<script(?![^>]*type=[\"']application/ld\\+json[\"'])[^>]*>.*?</script>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // Remove style tags and their content
        cleaned = cleaned.replacingOccurrences(
            of: "<style[^>]*>.*?</style>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // Remove HTML comments
        cleaned = cleaned.replacingOccurrences(
            of: "<!--.*?-->",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // If we found JSON-LD data, prepend it prominently for Claude
        if !jsonLDScripts.isEmpty {
            let structuredDataSection = """
            
            === STRUCTURED RECIPE DATA (JSON-LD Schema) ===
            \(jsonLDScripts.joined(separator: "\n\n"))
            === END STRUCTURED DATA ===
            
            """
            cleaned = structuredDataSection + cleaned
            print("🧹 ✅ Added \(jsonLDScripts.count) JSON-LD structured data block(s) to top of content")
        }
        
        // Replace common HTML entities
        let entities = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&rsquo;": "'",
            "&lsquo;": "'",
            "&rdquo;": "\"",
            "&ldquo;": "\"",
            "&mdash;": "—",
            "&ndash;": "–",
            "&bull;": "•",
            "&frac12;": "½",
            "&frac14;": "¼",
            "&frac34;": "¾"
        ]
        
        for (entity, replacement) in entities {
            cleaned = cleaned.replacingOccurrences(of: entity, with: replacement)
        }
        
        print("🧹 ✅ HTML cleaned")
        print("🧹 Cleaned length: \(cleaned.count) characters")
        
        return cleaned
    }
}

// MARK: - Error Types

enum WebExtractionError: LocalizedError {
    case invalidURL
    case networkError
    case httpError(statusCode: Int)
    case decodingError
    case noRecipeFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please enter a valid web address starting with http:// or https://"
        case .networkError:
            return "Network error. Please check your internet connection."
        case .httpError(let statusCode):
            switch statusCode {
            case 403:
                return "Access denied. The website may be blocking automated access."
            case 404:
                return "Page not found. Please check the URL."
            case 500...599:
                return "Server error. The website may be temporarily unavailable."
            default:
                return "HTTP error: \(statusCode)"
            }
        case .decodingError:
            return "Could not decode webpage content."
        case .noRecipeFound:
            return "No recipe could be found on this webpage."
        }
    }
}
