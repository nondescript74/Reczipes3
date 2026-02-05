//
//  ClaudeAPIClient.swift
//  Reczipes2
//
//  Created for Claude-powered recipe extraction
//

import Foundation

#if os(iOS)
import UIKit
#endif

class ClaudeAPIClient {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let imagePreprocessor = ImagePreprocessor()
    private let retryManager = ExtractionRetryManager()
    
    // Timeout configuration
    private let requestTimeout: TimeInterval = 120.0 // 2 minutes for recipe extraction
    private let validationTimeout: TimeInterval = 30.0 // 30 seconds for API key validation
    
    // Model fallback list - try these in order for validation
    private let validationModels = [
        "claude-sonnet-4-20250514",      // Latest Sonnet 4 (primary)
        "claude-3-7-sonnet-20250219",    // Sonnet 3.7
        "claude-3-5-sonnet-20241022",    // Sonnet 3.5 (Oct 2024)
        "claude-3-5-sonnet-20240620"     // Sonnet 3.5 (June 2024)
    ]
    
    // Primary model for recipe extraction
    private let recipeExtractionModel = "claude-sonnet-4-20250514"
    
    // URLSession with custom configuration
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout
        return URLSession(configuration: config)
    }()
    
    private lazy var validationSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = validationTimeout
        config.timeoutIntervalForResource = validationTimeout
        return URLSession(configuration: config)
    }()
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// Validate the API key by making a minimal test request to Anthropic
    /// - Returns: true if the API key is valid, false otherwise
    func validateAPIKey() async -> Bool {
        logInfo("API KEY VALIDATION START", category: "network")
        logDebug("API key configured: \(apiKey.isEmpty ? "NO" : "YES")", category: "network")
        
        let testPrompt = "Hi"
        
        // Try each model in the fallback list
        for (index, model) in validationModels.enumerated() {
            logInfo("Attempt \(index + 1)/\(validationModels.count): Trying model '\(model)'", category: "network")
            
            let requestBody: [String: Any] = [
                "model": model,
                "max_tokens": 10,
                "messages": [
                    [
                        "role": "user",
                        "content": testPrompt
                    ]
                ]
            ]
            
            guard let url = URL(string: baseURL) else {
                logError("Invalid URL: \(baseURL)", category: "network")
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                logDebug("Request body size: \(request.httpBody?.count ?? 0) bytes", category: "network")
                logInfo("Sending validation request to: \(baseURL)", category: "network")
                
                let (data, response) = try await validationSession.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    logError("Invalid response type (not HTTPURLResponse)", category: "network")
                    continue
                }
                
                logDebug("Response status code: \(httpResponse.statusCode)", category: "network")
                logDebug("Response headers: \(httpResponse.allHeaderFields)", category: "network")
                
                // Parse and log the response body for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    logDebug("Response body (\(responseString.count) chars): \(responseString)", category: "network")
                    
                    // If it's an error response, parse it nicely
                    if httpResponse.statusCode != 200 {
                        let parsedError = parseAPIError(from: data)
                        logDebug("Parsed error: \(parsedError)", category: "network")
                    }
                } else {
                    logWarning("Unable to decode response body", category: "network")
                }
                
                // Status code 200 means the API key is valid
                if httpResponse.statusCode == 200 {
                    logInfo("API key is VALID! Successfully validated with model: \(model)", category: "network")
                    logInfo("API KEY VALIDATION SUCCESS", category: "network")
                    return true
                } else if httpResponse.statusCode == 404 {
                    // Model not found, try next one
                    logWarning("Model '\(model)' not found (404), trying next model", category: "network")
                    continue
                } else if httpResponse.statusCode == 401 {
                    // Unauthorized - bad API key
                    logError("API key is INVALID (401 Unauthorized)", category: "network")
                    logError("API KEY VALIDATION FAILED", category: "network")
                    return false
                } else {
                    // Other error, try next model
                    logWarning("Validation failed with status \(httpResponse.statusCode), trying next model", category: "network")
                    continue
                }
            } catch {
                logError("Validation error with model '\(model)': \(error.localizedDescription)", category: "network")
                logError("Full error: \(error)", category: "network")
                // Try next model
                continue
            }
        }
        
        // If we got here, none of the models worked
        logError("All validation attempts failed. No models were successful", category: "network")
        logError("API KEY VALIDATION FAILED", category: "network")
        return false
    }
    
    /// Extract a recipe from web content using Claude's text capabilities
    /// - Parameter htmlContent: The HTML or text content containing the recipe
    /// - Returns: A RecipeX parsed from the content
    /// - Note: Only available in the main app target (requires SwiftData / RecipeX)
#if !APPCLIP
    func extractRecipe(from htmlContent: String) async throws -> RecipeX {
        logInfo("WEB RECIPE EXTRACTION START", category: "extraction")
        logDebug("Content length: \(htmlContent.count) characters", category: "extraction")
        
        // Use retry manager for API resilience
        let operationID = "claude-extract-web-\(htmlContent.prefix(100).hashValue)"
        
        // Get the Sendable RecipeResponse from retry logic
        let recipeResponse = try await retryManager.withRetry(
            operationID: operationID,
            configuration: .init(
                maxAttempts: 3,
                initialDelay: 2.0,
                maxDelay: 20.0,
                backoffMultiplier: 2.0,
                useJitter: true
            )
        ) {
            try await self.performWebExtraction(htmlContent: htmlContent)
        }
        
        // Convert to RecipeX outside of retry closure
        return recipeResponse.toRecipeX()
    }
#endif
    
    /// Perform the actual web extraction (wrapped by retry logic)
    /// Returns RecipeResponse (Sendable) instead of RecipeX (SwiftData model)
    private func performWebExtraction(htmlContent: String) async throws -> RecipeResponse {
        
        let systemPrompt = """
        You are an expert at extracting recipes from web pages and text content. 
        Your task is to carefully analyze the HTML/text and extract ALL recipe information into a structured JSON format.
        
        PRIORITY: Look for JSON-LD structured data (application/ld+json) which may appear in sections marked "STRUCTURED RECIPE DATA".
        This data is the authoritative source and should be used if available. It follows schema.org Recipe format.
        
        Pay special attention to:
        - Recipe title and description
        - Multiple ingredient sections (e.g., "For the dough", "For the filling")
        - Multiple instruction sections (e.g., "Preparation", "Assembly", "Baking")
        - Measurements in both imperial and metric units when available
        - Preparation notes within ingredients (e.g., "finely chopped", "at room temperature")
        - Recipe notes, tips, warnings, and variations
        - Transition notes between sections
        - Header notes or descriptions
        - Yield/servings information
        - Recipe source or author information
        - Cook time, prep time, and total time information
        
        **INGREDIENT PARSING PRECISION:**
        When extracting ingredient names, be extremely precise to avoid false allergen matches:
        - "cream of tartar" is NOT dairy cream (it's potassium bitartrate, a leavening agent)
        - "coconut milk" is NOT dairy milk (it's plant-based, dairy-free)
        - "peanut butter" is NOT dairy butter (contains peanuts but no dairy)
        - "almond milk", "oat milk", "soy milk" are NOT dairy (they're plant-based alternatives)
        - "butternut squash" is NOT related to dairy butter
        - "eggplant" does NOT contain eggs
        - Record the COMPLETE ingredient phrase including all modifying words
        - Preserve qualifiers like "lactose-free", "vegan", "dairy-free", "gluten-free"
        - Include preparation methods: "ghee (clarified butter)" vs "butter"
        
        Web pages often have extra navigation, ads, and unrelated content. Focus ONLY on the recipe content.
        If JSON-LD structured data is present, use it as your primary source. Otherwise, parse the HTML.
        
        CRITICAL: Return ONLY valid JSON with no markdown formatting, no preamble, and no explanation.
        """
        
        let userPrompt = """
        Extract the recipe from this web content and structure it according to this exact JSON schema:
        
        {
          "title": "Recipe Title",
          "headerNotes": "Optional description or subtitle (can include prep time, cook time, etc.)",
          "yield": "Servings or yield information",
          "ingredientSections": [
            {
              "title": "Optional section title (e.g., 'For the sauce')",
              "ingredients": [
                {
                  "quantity": "1",
                  "unit": "cup",
                  "name": "flour",
                  "preparation": "sifted",
                  "metricQuantity": "250",
                  "metricUnit": "mL"
                }
              ],
              "transitionNote": "Optional note between sections"
            }
          ],
          "instructionSections": [
            {
              "title": "Optional section title (e.g., 'Preparation')",
              "steps": [
                {
                  "stepNumber": 1,
                  "text": "Step instruction text"
                }
              ]
            }
          ],
          "notes": [
            {
              "type": "tip",
              "text": "Note text"
            }
          ],
          "reference": "Optional reference like website URL or author"
        }
        
        IMPORTANT INSTRUCTIONS:
        - If you see JSON-LD structured data (marked with "STRUCTURED RECIPE DATA"), use that as your PRIMARY source
        - JSON-LD data follows schema.org Recipe format with recipeIngredient, recipeInstructions, etc.
        - Note types can be: "tip", "substitution", "warning", "timing", or "general"
        - If the recipe has no section titles, leave "title" as null
        - If step numbers aren't visible, leave "stepNumber" as null
        - Include metric conversions when they're present in the original
        - Extract ALL ingredients and instructions - don't truncate or summarize
        - Extract ALL text including notes, variations, and tips
        
        Here's the web content:
        
        \(htmlContent)
        """
        
        logInfo("Building API request", category: "extraction")
        logDebug("Using model: \(recipeExtractionModel)", category: "extraction")
        let requestBody: [String: Any] = [
            "model": recipeExtractionModel,
            "max_tokens": 8192,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ]
        ]
        
        guard let url = URL(string: baseURL) else {
            logError("Invalid base URL: \(baseURL)", category: "extraction")
            throw ClaudeAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 120 // 2 minutes for processing
        
        logDebug("Serializing request body", category: "extraction")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            logDebug("Request body size: \(request.httpBody?.count ?? 0) bytes", category: "extraction")
        } catch {
            logError("Failed to serialize request body: \(error)", category: "extraction")
            throw ClaudeAPIError.invalidJSON
        }
        
        logInfo("Sending request to Anthropic", category: "network")
        
        // Use do-catch to handle timeouts specifically
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            logError("Request timed out after \(requestTimeout) seconds", category: "network")
            throw ClaudeAPIError.timeout
        } catch let error as URLError {
            logError("Network error: \(error.localizedDescription)", category: "network")
            throw ClaudeAPIError.networkError(error)
        } catch {
            logError("Unexpected error: \(error)", category: "network")
            throw ClaudeAPIError.networkError(error)
        }
        
        logInfo("Received response", category: "network")
        logDebug("Response data size: \(data.count) bytes", category: "network")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logError("Response is not HTTPURLResponse", category: "network")
            throw ClaudeAPIError.invalidResponse
        }
        
        logDebug("HTTP Status Code: \(httpResponse.statusCode)", category: "network")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = parseAPIError(from: data)
            logError("API Error Response: \(errorMessage)", category: "network")
            
            let detailedMessage: String
            switch httpResponse.statusCode {
            case 401:
                detailedMessage = "Authentication failed. Please check your API key."
            case 404:
                detailedMessage = "Model '\(recipeExtractionModel)' not found. It may have been deprecated."
            case 429:
                detailedMessage = "Rate limit exceeded. Please try again later."
            case 500...599:
                detailedMessage = "Anthropic server error. Please try again later."
            default:
                detailedMessage = errorMessage
            }
            
            throw ClaudeAPIError.apiError(statusCode: httpResponse.statusCode, message: detailedMessage)
        }
        
        logDebug("Decoding Claude response", category: "extraction")
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        logInfo("Successfully decoded Claude response", category: "extraction")
        
        // Extract JSON from Claude's response
        logDebug("Extracting recipe JSON from response", category: "extraction")
        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }) else {
            logError("No text content found in response", category: "extraction")
            throw ClaudeAPIError.noRecipeFound
        }
        
        logDebug("Raw text content length: \(textContent.text.count) characters", category: "extraction")
        
        guard let jsonString = extractJSON(from: textContent.text) else {
            logError("Failed to extract JSON from text", category: "extraction")
            throw ClaudeAPIError.noRecipeFound
        }
        
        logDebug("Extracted JSON string length: \(jsonString.count) characters", category: "extraction")
        
        // Parse the recipe JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            logError("Failed to convert JSON string to Data", category: "extraction")
            throw ClaudeAPIError.invalidJSON
        }
        
        logDebug("Parsing recipe JSON", category: "extraction")
        let recipeResponse = try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
        logInfo("Successfully parsed recipe", category: "extraction")
        logDebug("Recipe title: \(recipeResponse.title)", category: "extraction")
        logInfo("Web recipe extraction complete", category: "extraction")
        logInfo("WEB RECIPE EXTRACTION END", category: "extraction")
        
        return recipeResponse
    }
    
    /// Extract a recipe from an image using Claude's vision capabilities
    /// - Parameters:
    ///   - image: The UIImage containing the recipe
    ///   - usePreprocessing: Whether to apply image preprocessing for better OCR results
    /// - Returns: A RecipeX parsed from the image
    /// - Note: Only available in the main app target (requires SwiftData / RecipeX)
#if !APPCLIP
    func extractRecipe(from imageData: Data, usePreprocessing: Bool = true) async throws -> RecipeX {
        logInfo("RECIPE EXTRACTION START", category: "extraction")
        logDebug("Original image data size: \(imageData.count) bytes", category: "extraction")
        logDebug("Use preprocessing: \(usePreprocessing)", category: "extraction")
        
        // Use retry manager for API resilience
        let operationID = "claude-extract-image-\(imageData.hashValue)"
        
        // Get the Sendable RecipeResponse from retry logic
        let recipeResponse = try await retryManager.withRetry(
            operationID: operationID,
            configuration: .init(
                maxAttempts: 3,
                initialDelay: 2.0,
                maxDelay: 20.0,
                backoffMultiplier: 2.0,
                useJitter: true
            )
        ) {
            try await self.performImageExtraction(imageData: imageData, usePreprocessing: usePreprocessing)
        }
        
        // Convert to RecipeX outside of retry closure
        return recipeResponse.toRecipeX()
    }
#endif

    // MARK: - App Clip extraction (returns AppClipExtractedRecipeData directly)
    //
    // These mirror the two extractRecipe overloads above but skip the
    // RecipeX / SwiftData conversion.  The App Clip target cannot include
    // RecipeX, so it calls these instead.

    /// App-Clip–friendly variant: extracts from web content and returns the
    /// lightweight Codable model that can be serialized through App Groups.
    func extractRecipeAsClipData(from htmlContent: String) async throws -> AppClipExtractedRecipeData {
        let operationID = "claude-extract-web-clip-\(htmlContent.prefix(100).hashValue)"

        let recipeResponse = try await retryManager.withRetry(
            operationID: operationID,
            configuration: .init(
                maxAttempts: 3,
                initialDelay: 2.0,
                maxDelay: 20.0,
                backoffMultiplier: 2.0,
                useJitter: true
            )
        ) {
            try await self.performWebExtraction(htmlContent: htmlContent)
        }

        return recipeResponse.toClipData()
    }

    /// App-Clip–friendly variant: extracts from an image and returns the
    /// lightweight Codable model that can be serialized through App Groups.
    func extractRecipeAsClipData(from imageData: Data, usePreprocessing: Bool = true) async throws -> AppClipExtractedRecipeData {
        let operationID = "claude-extract-image-clip-\(imageData.hashValue)"

        let recipeResponse = try await retryManager.withRetry(
            operationID: operationID,
            configuration: .init(
                maxAttempts: 3,
                initialDelay: 2.0,
                maxDelay: 20.0,
                backoffMultiplier: 2.0,
                useJitter: true
            )
        ) {
            try await self.performImageExtraction(imageData: imageData, usePreprocessing: usePreprocessing)
        }

        return recipeResponse.toClipData()
    }

    /// Perform the actual image extraction (wrapped by retry logic)
    /// Returns RecipeResponse (Sendable) instead of RecipeX (SwiftData model)
    private func performImageExtraction(imageData: Data, usePreprocessing: Bool) async throws -> RecipeResponse {
        
        // Preprocess the image if requested
        let finalImageData: Data
        if usePreprocessing, let uiImage = UIImage(data: imageData) {
            logDebug("Converting to UIImage for preprocessing", category: "extraction")
            if let processedData = imagePreprocessor.preprocessForOCR(uiImage) {
                finalImageData = processedData
                logInfo("Image preprocessed - new size: \(finalImageData.count) bytes", category: "extraction")
            } else {
                logWarning("Preprocessing failed, using original", category: "extraction")
                finalImageData = imageData
            }
        } else {
            logDebug("Using original image data without preprocessing", category: "extraction")
            finalImageData = imageData
        }
        
        logDebug("Converting image to base64", category: "extraction")
        let base64Image = finalImageData.base64EncodedString()
        logDebug("Base64 string length: \(base64Image.count) characters", category: "extraction")
        
        let systemPrompt = """
        You are an expert at extracting recipes from images of recipe cards, cookbooks, and handwritten notes. 
        Your task is to carefully analyze the image and extract ALL recipe information into a structured JSON format.
        
        Pay special attention to:
        - Multiple ingredient sections (e.g., "For the dough", "For the filling")
        - Multiple instruction sections (e.g., "Preparation", "Assembly", "Baking")
        - Measurements in both imperial and metric units when available
        - Preparation notes within ingredients (e.g., "finely chopped", "at room temperature")
        - Recipe notes, tips, warnings, and variations
        - Transition notes between sections
        - Header notes or descriptions
        - Yield/servings information
        - Reference information (page numbers, source notes)
        
        **INGREDIENT PARSING PRECISION:**
        When extracting ingredient names, be extremely precise:
        - "cream of tartar" is NOT the same as "cream" (it's potassium bitartrate, a leavening agent)
        - "coconut milk" is NOT the same as "milk" (it's dairy-free)
        - "peanut butter" is NOT the same as "butter" (it contains no dairy)
        - "almond milk" is NOT the same as "milk" (it's dairy-free)
        - "soy sauce" contains soy but "fish sauce" does not
        - Record the COMPLETE ingredient name including all modifying words
        - Include preparation methods that change allergen content (e.g., "lactose-free milk", "vegan cheese")
        
        CRITICAL: Return ONLY valid JSON with no markdown formatting, no preamble, and no explanation.
        """
        
        let userPrompt = """
        Extract the recipe from this image and structure it according to this exact JSON schema:
        
        {
          "title": "Recipe Title",
          "headerNotes": "Optional description or subtitle",
          "yield": "Servings or yield information",
          "ingredientSections": [
            {
              "title": "Optional section title (e.g., 'For the sauce')",
              "ingredients": [
                {
                  "quantity": "1",
                  "unit": "cup",
                  "name": "flour",
                  "preparation": "sifted",
                  "metricQuantity": "250",
                  "metricUnit": "mL"
                }
              ],
              "transitionNote": "Optional note between sections"
            }
          ],
          "instructionSections": [
            {
              "title": "Optional section title (e.g., 'Preparation')",
              "steps": [
                {
                  "stepNumber": 1,
                  "text": "Step instruction text"
                }
              ]
            }
          ],
          "notes": [
            {
              "type": "tip",
              "text": "Note text"
            }
          ],
          "reference": "Optional reference like page number or source"
        }
        
        Note types can be: "tip", "substitution", "warning", "timing", or "general"
        
        If the recipe has no section titles, leave "title" as null.
        If step numbers aren't visible, leave "stepNumber" as null.
        Include metric conversions when they're present in the original.
        Extract ALL text including notes, variations, and tips.
        """
        
        logInfo("Building API request", category: "extraction")
        logDebug("Using model: \(recipeExtractionModel)", category: "extraction")
        let requestBody: [String: Any] = [
            "model": recipeExtractionModel,
            "max_tokens": 8192,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": userPrompt
                        ]
                    ]
                ]
            ]
        ]
        
        guard let url = URL(string: baseURL) else {
            logError("Invalid base URL: \(baseURL)", category: "extraction")
            throw ClaudeAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 120 // 2 minutes for image processing
        
        logDebug("Serializing request body", category: "extraction")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            logDebug("Request body size: \(request.httpBody?.count ?? 0) bytes", category: "extraction")
        } catch {
            logError("Failed to serialize request body: \(error)", category: "extraction")
            throw ClaudeAPIError.invalidJSON
        }
        
        logInfo("Sending request to Anthropic", category: "network")
        logDebug("URL: \(baseURL)", category: "network")
        // Note: Not logging headers to protect API key security
        
        // Use do-catch to handle timeouts specifically
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            logError("Request timed out after \(requestTimeout) seconds", category: "network")
            throw ClaudeAPIError.timeout
        } catch let error as URLError {
            logError("Network error: \(error.localizedDescription)", category: "network")
            throw ClaudeAPIError.networkError(error)
        } catch {
            logError("Unexpected error: \(error)", category: "network")
            throw ClaudeAPIError.networkError(error)
        }
        
        logInfo("Received response", category: "network")
        logDebug("Response data size: \(data.count) bytes", category: "network")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logError("Response is not HTTPURLResponse", category: "network")
            throw ClaudeAPIError.invalidResponse
        }
        
        logDebug("HTTP Status Code: \(httpResponse.statusCode)", category: "network")
        logDebug("Response Headers: \(httpResponse.allHeaderFields)", category: "network")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = parseAPIError(from: data)
            logError("API Error Response: \(errorMessage)", category: "network")
            logError("Status Code: \(httpResponse.statusCode)", category: "network")
            
            // Provide more detailed error messages based on status code
            let detailedMessage: String
            switch httpResponse.statusCode {
            case 401:
                detailedMessage = "Authentication failed. Please check your API key."
            case 404:
                detailedMessage = "Model '\(recipeExtractionModel)' not found. It may have been deprecated."
            case 429:
                detailedMessage = "Rate limit exceeded. Please try again later."
            case 500...599:
                detailedMessage = "Anthropic server error. Please try again later."
            default:
                detailedMessage = errorMessage
            }
            
            throw ClaudeAPIError.apiError(statusCode: httpResponse.statusCode, message: detailedMessage)
        }
        
        logDebug("Decoding Claude response", category: "extraction")
        let claudeResponse: ClaudeResponse
        do {
            claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            logInfo("Successfully decoded Claude response", category: "extraction")
            logDebug("Response model: \(claudeResponse.model ?? "unknown")", category: "extraction")
            logDebug("Response role: \(claudeResponse.role ?? "unknown")", category: "extraction")
            logDebug("Content blocks: \(claudeResponse.content.count)", category: "extraction")
        } catch {
            logError("Failed to decode Claude response: \(error)", category: "extraction")
            if let responseString = String(data: data, encoding: .utf8) {
                logDebug("Raw response: \(responseString)", category: "extraction")
            }
            throw ClaudeAPIError.invalidResponse
        }
        
        // Extract JSON from Claude's response
        logDebug("Extracting recipe JSON from response", category: "extraction")
        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }) else {
            logError("No text content found in response", category: "extraction")
            throw ClaudeAPIError.noRecipeFound
        }
        
        logDebug("Raw text content length: \(textContent.text.count) characters", category: "extraction")
        logDebug("Raw text preview: \(String(textContent.text.prefix(200)))...", category: "extraction")
        
        guard let jsonString = extractJSON(from: textContent.text) else {
            logError("Failed to extract JSON from text", category: "extraction")
            logDebug("Full text: \(textContent.text)", category: "extraction")
            throw ClaudeAPIError.noRecipeFound
        }
        
        logDebug("Extracted JSON string length: \(jsonString.count) characters", category: "extraction")
        logDebug("JSON preview: \(String(jsonString.prefix(200)))...", category: "extraction")
        
        // Parse the recipe JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            logError("Failed to convert JSON string to Data", category: "extraction")
            throw ClaudeAPIError.invalidJSON
        }
        
        logDebug("Parsing recipe JSON", category: "extraction")
        let recipeResponse: RecipeResponse
        do {
            recipeResponse = try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
            logInfo("Successfully parsed recipe", category: "extraction")
            logDebug("Recipe title: \(recipeResponse.title)", category: "extraction")
            logDebug("Ingredient sections: \(recipeResponse.ingredientSections.count)", category: "extraction")
            logDebug("Instruction sections: \(recipeResponse.instructionSections.count)", category: "extraction")
        } catch {
            logError("Failed to decode recipe JSON: \(error)", category: "extraction")
            logDebug("JSON data: \(jsonString)", category: "extraction")
            throw ClaudeAPIError.invalidJSON
        }
        
        // Convert to RecipeX
        logInfo("Recipe extraction complete", category: "extraction")
        logInfo("RECIPE EXTRACTION END", category: "extraction")
        
        return recipeResponse
    }
    
    private func extractJSON(from text: String) -> String? {
        // Remove markdown code blocks if present
        var cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find JSON object boundaries
        if let startIndex = cleaned.firstIndex(of: "{"),
           let endIndex = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[startIndex...endIndex])
        }
        
        return cleaned
    }
    
    /// Parse Anthropic API error response for better debugging
    private func parseAPIError(from data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return String(data: data, encoding: .utf8) ?? "Unable to parse error"
        }
        
        if let error = json["error"] as? [String: Any] {
            let type = error["type"] as? String ?? "unknown"
            let message = error["message"] as? String ?? "No message"
            return "[\(type)] \(message)"
        }
        
        return String(data: data, encoding: .utf8) ?? "Unable to parse error"
    }
}

// MARK: - Response Models

struct ClaudeResponse: Codable {
    let content: [ContentBlock]
    let model: String?
    let role: String?
}

struct ContentBlock: Codable {
    let type: String
    let text: String
}

// MARK: - Intermediate Recipe Response (matches Claude's JSON output)

struct RecipeResponse: Codable, Sendable {
    let title: String
    let headerNotes: String?
    let yield: String?
    let ingredientSections: [IngredientSectionResponse]
    let instructionSections: [InstructionSectionResponse]
    let notes: [RecipeNoteResponse]?
    let reference: String?
    
#if !APPCLIP
    func toRecipeX() -> RecipeX {
        let encoder = JSONEncoder()
        
        // Properly encode the data
        let ingredientSectionsData = try? encoder.encode(ingredientSections.map { $0.toIngredientSection() })
        let instructionSectionsData = try? encoder.encode(instructionSections.map { $0.toInstructionSection() })
        let notesData = try? encoder.encode(notes?.map { $0.toRecipeNote() } ?? [])
        
        return RecipeX(
            id: UUID(),
            title: title,
            headerNotes: headerNotes,
            recipeYield: yield,
            reference: reference,
            ingredientSectionsData: ingredientSectionsData,
            instructionSectionsData: instructionSectionsData,
            notesData: notesData
        )
    }
#endif

    /// Converts directly to the lightweight App Clip model without going
    /// through RecipeX (which requires SwiftData and cannot live in the
    /// App Clip target).
    func toClipData(sourceURL: String? = nil) -> AppClipExtractedRecipeData {
        // ── Ingredients: flatten all sections into plain strings ──
        let ingredientNames: [String] = ingredientSections.flatMap { section in
            section.ingredients.map { ingredient in
                var parts: [String] = []
                if let q = ingredient.quantity    { parts.append(q) }
                if let u = ingredient.unit        { parts.append(u) }
                parts.append(ingredient.name)
                if let p = ingredient.preparation { parts.append("(\(p))") }
                return parts.joined(separator: " ")
            }
        }

        // ── Instructions: flatten all sections into plain strings ──
        let instructionTexts: [String] = instructionSections.flatMap { section in
            section.steps.map { $0.text }
        }

        // ── Notes ──
        let notesString = (notes ?? []).map { $0.text }.joined(separator: "\n")

        // ── Timing: parse out of headerNotes if present ──
        var prepTime: String?
        var cookTime: String?
        if let header = headerNotes {
            for line in header.split(separator: "\n") {
                let l = String(line)
                if l.lowercased().hasPrefix("prep") {
                    prepTime = l.components(separatedBy: ":").dropFirst()
                        .joined(separator: ":").trimmingCharacters(in: .whitespaces)
                } else if l.lowercased().hasPrefix("cook") {
                    cookTime = l.components(separatedBy: ":").dropFirst()
                        .joined(separator: ":").trimmingCharacters(in: .whitespaces)
                }
            }
        }

        // ── Servings: best-effort parse from yield (e.g. "Serves 4" → 4) ──
        let servings: Int = {
            guard let y = yield else { return 1 }
            let scanner = Scanner(string: y)
            scanner.charactersToBeSkipped = .letters.union(.whitespaces)
            var n: Int = 1
            scanner.scanInt(&n)
            return n
        }()

        return AppClipExtractedRecipeData(
            title:        title.isEmpty ? "Untitled Recipe" : title,
            servings:     servings,
            prepTime:     prepTime,
            cookTime:     cookTime,
            ingredients:  ingredientNames,
            instructions: instructionTexts,
            notes:        notesString.isEmpty ? nil : notesString
        )
    }
}

struct IngredientSectionResponse: Codable, Sendable {
    let title: String?
    let ingredients: [IngredientResponse]
    let transitionNote: String?
    
#if !APPCLIP
    func toIngredientSection() -> IngredientSection {
        IngredientSection(
            title: title,
            ingredients: ingredients.map { $0.toIngredient() },
            transitionNote: transitionNote
        )
    }
#endif
}

struct IngredientResponse: Codable, Sendable {
    let quantity: String?
    let unit: String?
    let name: String
    let preparation: String?
    let metricQuantity: String?
    let metricUnit: String?
    
#if !APPCLIP
    func toIngredient() -> Ingredient {
        Ingredient(
            quantity: quantity,
            unit: unit,
            name: name,
            preparation: preparation,
            metricQuantity: metricQuantity,
            metricUnit: metricUnit
        )
    }
#endif
}

struct InstructionSectionResponse: Codable, Sendable {
    let title: String?
    let steps: [InstructionStepResponse]
    
#if !APPCLIP
    func toInstructionSection() -> InstructionSection {
        InstructionSection(
            title: title,
            steps: steps.map { $0.toInstructionStep() }
        )
    }
#endif
}

struct InstructionStepResponse: Codable, Sendable {
    let stepNumber: Int?
    let text: String
    
#if !APPCLIP
    func toInstructionStep() -> InstructionStep {
        InstructionStep(
            stepNumber: stepNumber ?? 1,
            text: text
        )
    }
#endif
}

struct RecipeNoteResponse: Codable, Sendable {
    let type: String
    let text: String
    
#if !APPCLIP
    func toRecipeNote() -> RecipeNote {
        let noteType = RecipeNoteType(rawValue: type) ?? .general
        return RecipeNote(type: noteType, text: text)
    }
#endif
}

// MARK: - Error Types

enum ClaudeAPIError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noRecipeFound
    case invalidJSON
    case networkError(Error)
    case timeout
    case notARecipe
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .noRecipeFound:
            return "No recipe could be extracted from the image. Please ensure the image contains a recipe with clear text."
        case .invalidJSON:
            return "Could not parse recipe JSON"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out. This may happen with very complex images or slow connections. Please try again or use a simpler image."
        case .notARecipe:
            return "This image doesn't appear to contain a recipe. Please select an image with recipe text, ingredients, and instructions."
        }
    }
}
