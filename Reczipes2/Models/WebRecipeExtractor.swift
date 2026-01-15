//
//  WebRecipeExtractor.swift
//  Reczipes2
//
//  Created for web-based recipe extraction
//

import Foundation

/// Extracts recipe content from web pages
class WebRecipeExtractor {
    
    private let retryManager = ExtractionRetryManager()
    
    /// Fetch and extract text content from a URL with automatic retry on transient failures
    /// - Parameter urlString: The URL of the recipe webpage
    /// - Returns: The HTML content as a string
    func fetchWebContent(from urlString: String) async throws -> String {
        logInfo("🌐 ========== WEB CONTENT FETCH START ==========", category: "network")
        logInfo("🌐 URL: \(urlString)", category: "network")
        
        // Create operation ID for retry tracking
        let operationID = "web-fetch-\(urlString.hashValue)"
        
        // Use retry manager for resilience
        return try await retryManager.withRetry(
            operationID: operationID,
            configuration: .init(
                maxAttempts: 3,
                initialDelay: 2.0,
                maxDelay: 15.0,
                backoffMultiplier: 2.0,
                useJitter: true
            )
        ) {
            try await self.performFetch(urlString: urlString)
        }
    }
    
    /// Perform the actual web content fetch (wrapped by retry logic)
    private func performFetch(urlString: String) async throws -> String {
        // Clean HTML tags from URL string (defense-in-depth)
        let cleanedURLString = cleanHTMLTags(from: urlString)
        if cleanedURLString != urlString {
            logInfo("🌐 ⚠️ Removed HTML tags from URL", category: "network")
            logInfo("🌐 Cleaned URL: \(cleanedURLString)", category: "network")
        }
        
        // Validate URL
        guard let url = URL(string: cleanedURLString) else {
            logError("🌐 ❌ Invalid URL format", category: "network")
            throw WebExtractionError.invalidURL
        }
        
        // Ensure it's an HTTP(S) URL
        guard let scheme = url.scheme, ["http", "https"].contains(scheme.lowercased()) else {
            logError("🌐 ❌ URL must use HTTP or HTTPS protocol", category: "network")
            throw WebExtractionError.invalidURL
        }
        
        logInfo("🌐 Creating URL request...", category: "network")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        // Set a user agent to avoid being blocked by some sites
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        logInfo("🌐 Fetching webpage...", category: "network")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logError("🌐 ❌ Invalid response type", category: "network")
            throw WebExtractionError.networkError
        }
        
        logInfo("🌐 HTTP Status: \(httpResponse.statusCode)", category: "network")
        
        guard httpResponse.statusCode == 200 else {
            logError("🌐 ❌ HTTP error: \(httpResponse.statusCode)", category: "network")
            throw WebExtractionError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Detect encoding from response
        var encoding = String.Encoding.utf8
        if let encodingName = httpResponse.textEncodingName {
            logInfo("🌐 Detected encoding: \(encodingName)", category: "network")
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
            if cfEncoding != kCFStringEncodingInvalidId {
                encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
            }
        }
        
        guard let htmlContent = String(data: data, encoding: encoding) else {
            logError("🌐 ❌ Failed to decode HTML content", category: "network")
            throw WebExtractionError.decodingError
        }
        
        logInfo("🌐 ✅ Successfully fetched HTML content", category: "network")
        logInfo("🌐 Content length: \(htmlContent.count) characters", category: "network")
        logInfo("🌐 ========== WEB CONTENT FETCH END ==========", category: "network")
        
        return htmlContent
    }
    
    /// Clean HTML content by removing unwanted tags while preserving structured data
    /// This provides a cleaner input for the LLM while keeping JSON-LD recipe data
    func cleanHTML(_ html: String) -> String {
        logInfo("🧹 Cleaning HTML content...", category: "extraction")
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
                    logInfo("🧹 📦 Preserved JSON-LD structured data (\(jsonContent.count) chars)", category: "extraction")
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
            logInfo("🧹 ✅ Added \(jsonLDScripts.count) JSON-LD structured data block(s) to top of content", category: "extraction")
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
        
        logInfo("🧹 ✅ HTML cleaned", category: "extraction")
        logInfo("🧹 Cleaned length: \(cleaned.count) characters", category: "extraction")
        
        return cleaned
    }
    
    /// Extract image URLs from HTML content
    /// Prioritizes JSON-LD structured data, then falls back to og:image and img tags
    /// - Parameter html: The HTML content
    /// - Returns: Array of image URLs found in the content
    func extractImageURLs(from html: String) -> [String] {
        logInfo("🖼️ Extracting image URLs from HTML...", category: "extraction")
        var imageURLs: [String] = []
        
        // 1. Try to extract from JSON-LD structured data (most reliable)
        let jsonLDPattern = "<script[^>]*type=[\"']application/ld\\+json[\"'][^>]*>(.*?)</script>"
        if let regex = try? NSRegularExpression(pattern: jsonLDPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if match.numberOfRanges > 1 {
                    let jsonContent = nsString.substring(with: match.range(at: 1))
                    if let jsonData = jsonContent.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        
                        // Handle both single Recipe and array of recipes
                        let recipes: [[String: Any]]
                        if let recipeArray = jsonObject["@graph"] as? [[String: Any]] {
                            recipes = recipeArray.filter { ($0["@type"] as? String) == "Recipe" }
                        } else if (jsonObject["@type"] as? String) == "Recipe" {
                            recipes = [jsonObject]
                        } else {
                            recipes = []
                        }
                        
                        for recipe in recipes {
                            // Extract image from various formats
                            if let imageString = recipe["image"] as? String {
                                imageURLs.append(imageString)
                            } else if let imageArray = recipe["image"] as? [String] {
                                imageURLs.append(contentsOf: imageArray)
                            } else if let imageDict = recipe["image"] as? [String: Any],
                                      let imageURL = imageDict["url"] as? String {
                                imageURLs.append(imageURL)
                            }
                        }
                    }
                }
            }
        }
        
        // 2. Extract Open Graph image (common fallback)
        let ogImagePattern = "<meta[^>]*property=[\"']og:image[\"'][^>]*content=[\"']([^\"']+)[\"'][^>]*>"
        if let ogRegex = try? NSRegularExpression(pattern: ogImagePattern, options: [.caseInsensitive]) {
            let nsString = html as NSString
            let matches = ogRegex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                if match.numberOfRanges > 1 {
                    let imageURL = nsString.substring(with: match.range(at: 1))
                    if !imageURLs.contains(imageURL) {
                        imageURLs.append(imageURL)
                    }
                }
            }
        }
        
        // 3. Extract from img tags with recipe-related classes/attributes (last resort)
        let imgPattern = "<img[^>]*src=[\"']([^\"']+)[\"'][^>]*>"
        if let imgRegex = try? NSRegularExpression(pattern: imgPattern, options: [.caseInsensitive]) {
            let nsString = html as NSString
            let matches = imgRegex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
            
            // Limit to first 5-10 images to avoid thumbnails/icons
            let limitedMatches = Array(matches.prefix(10))
            for match in limitedMatches {
                if match.numberOfRanges > 1 {
                    let imageURL = nsString.substring(with: match.range(at: 1))
                    // Filter out likely thumbnails, icons, and tracking pixels
                    if !imageURL.contains("icon") &&
                       !imageURL.contains("logo") &&
                       !imageURL.contains("tracking") &&
                       !imageURL.hasSuffix(".svg") &&
                       !imageURLs.contains(imageURL) {
                        imageURLs.append(imageURL)
                    }
                }
            }
        }
        
        // Clean and validate URLs
        imageURLs = imageURLs.compactMap { urlString in
            // Handle relative URLs
            let cleanURL = urlString.trimmingCharacters(in: .whitespaces)
            
            // Skip data URLs and very small images
            if cleanURL.hasPrefix("data:") || cleanURL.contains("1x1") {
                return nil
            }
            
            return cleanURL
        }
        
        logInfo("🖼️ ✅ Found \(imageURLs.count) image URL(s)", category: "extraction")
        for (index, url) in imageURLs.prefix(5).enumerated() {
            logInfo("🖼️   [\(index + 1)] \(url)", category: "extraction")
        }
        
        return imageURLs
    }
    
    /// Remove HTML tags from a string
    /// - Parameter string: String that may contain HTML tags
    /// - Returns: String with HTML tags removed and trimmed
    private func cleanHTMLTags(from string: String) -> String {
        // Remove HTML tags using regex
        let pattern = "<[^>]+>"
        let cleaned = string.replacingOccurrences(
            of: pattern,
            with: "",
            options: .regularExpression
        )
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
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
