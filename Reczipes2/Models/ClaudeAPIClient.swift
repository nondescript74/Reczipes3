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
    
    // Model fallback list - try these in order for validation
    private let validationModels = [
        "claude-sonnet-4-20250514",      // Latest Sonnet 4 (primary)
        "claude-3-7-sonnet-20250219",    // Sonnet 3.7
        "claude-3-5-sonnet-20241022",    // Sonnet 3.5 (Oct 2024)
        "claude-3-5-sonnet-20240620"     // Sonnet 3.5 (June 2024)
    ]
    
    // Primary model for recipe extraction
    private let recipeExtractionModel = "claude-sonnet-4-20250514"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// Validate the API key by making a minimal test request to Anthropic
    /// - Returns: true if the API key is valid, false otherwise
    func validateAPIKey() async -> Bool {
        print("🔍 ========== API KEY VALIDATION START ==========")
        print("🔍 API key length: \(apiKey.count) characters")
        print("🔍 API key prefix: \(String(apiKey.prefix(15)))...")
        print("🔍 API key suffix: ...\(String(apiKey.suffix(10)))")
        
        let testPrompt = "Hi"
        
        // Try each model in the fallback list
        for (index, model) in validationModels.enumerated() {
            print("🔍 Attempt \(index + 1)/\(validationModels.count): Trying model '\(model)'...")
            
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
                print("❌ Invalid URL: \(baseURL)")
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                print("🔍 Request body size: \(request.httpBody?.count ?? 0) bytes")
                print("🔍 Sending validation request to: \(baseURL)")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type (not HTTPURLResponse)")
                    continue
                }
                
                print("🔍 Response status code: \(httpResponse.statusCode)")
                print("🔍 Response headers: \(httpResponse.allHeaderFields)")
                
                // Parse and log the response body for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 Response body (\(responseString.count) chars): \(responseString)")
                    
                    // If it's an error response, parse it nicely
                    if httpResponse.statusCode != 200 {
                        let parsedError = parseAPIError(from: data)
                        print("🔍 Parsed error: \(parsedError)")
                    }
                } else {
                    print("🔍 Unable to decode response body")
                }
                
                // Status code 200 means the API key is valid
                if httpResponse.statusCode == 200 {
                    print("✅ API key is VALID! Successfully validated with model: \(model)")
                    print("🔍 ========== API KEY VALIDATION SUCCESS ==========")
                    return true
                } else if httpResponse.statusCode == 404 {
                    // Model not found, try next one
                    print("⚠️ Model '\(model)' not found (404), trying next model...")
                    continue
                } else if httpResponse.statusCode == 401 {
                    // Unauthorized - bad API key
                    print("❌ API key is INVALID (401 Unauthorized)")
                    print("🔍 ========== API KEY VALIDATION FAILED ==========")
                    return false
                } else {
                    // Other error, try next model
                    print("⚠️ Validation failed with status \(httpResponse.statusCode), trying next model...")
                    continue
                }
            } catch {
                print("❌ Validation error with model '\(model)': \(error.localizedDescription)")
                print("❌ Full error: \(error)")
                // Try next model
                continue
            }
        }
        
        // If we got here, none of the models worked
        print("❌ All validation attempts failed. No models were successful.")
        print("🔍 ========== API KEY VALIDATION FAILED ==========")
        return false
    }
    
    /// Extract a recipe from web content using Claude's text capabilities
    /// - Parameter htmlContent: The HTML or text content containing the recipe
    /// - Returns: A RecipeModel parsed from the content
    func extractRecipe(from htmlContent: String) async throws -> RecipeModel {
        print("🌐 ========== WEB RECIPE EXTRACTION START ==========")
        print("🌐 Content length: \(htmlContent.count) characters")
        
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
        
        print("🌐 Building API request...")
        print("🌐 Using model: \(recipeExtractionModel)")
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
            print("🌐 ❌ Invalid base URL: \(baseURL)")
            throw ClaudeAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 120 // 2 minutes for processing
        
        print("🌐 Serializing request body...")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("🌐 ✅ Request body size: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            print("🌐 ❌ Failed to serialize request body: \(error)")
            throw ClaudeAPIError.invalidJSON
        }
        
        print("🌐 Sending request to Anthropic...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("🌐 ✅ Received response")
        print("🌐 Response data size: \(data.count) bytes")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🌐 ❌ Response is not HTTPURLResponse")
            throw ClaudeAPIError.invalidResponse
        }
        
        print("🌐 HTTP Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = parseAPIError(from: data)
            print("🌐 ❌ API Error Response: \(errorMessage)")
            
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
        
        print("🌐 Decoding Claude response...")
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        print("🌐 ✅ Successfully decoded Claude response")
        
        // Extract JSON from Claude's response
        print("🌐 Extracting recipe JSON from response...")
        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }) else {
            print("🌐 ❌ No text content found in response")
            throw ClaudeAPIError.noRecipeFound
        }
        
        print("🌐 Raw text content length: \(textContent.text.count) characters")
        
        guard let jsonString = extractJSON(from: textContent.text) else {
            print("🌐 ❌ Failed to extract JSON from text")
            throw ClaudeAPIError.noRecipeFound
        }
        
        print("🌐 ✅ Extracted JSON string length: \(jsonString.count) characters")
        
        // Parse the recipe JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("🌐 ❌ Failed to convert JSON string to Data")
            throw ClaudeAPIError.invalidJSON
        }
        
        print("🌐 Parsing recipe JSON...")
        let recipeResponse = try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
        print("🌐 ✅ Successfully parsed recipe")
        print("🌐 Recipe title: \(recipeResponse.title)")
        
        let recipeModel = recipeResponse.toRecipeModel()
        print("🌐 ✅ Web recipe extraction complete!")
        print("🌐 ========== WEB RECIPE EXTRACTION END ==========")
        
        return recipeModel
    }
    
    /// Extract a recipe from an image using Claude's vision capabilities
    /// - Parameters:
    ///   - image: The UIImage containing the recipe
    ///   - usePreprocessing: Whether to apply image preprocessing for better OCR results
    /// - Returns: A RecipeModel parsed from the image
    func extractRecipe(from imageData: Data, usePreprocessing: Bool = true) async throws -> RecipeModel {
        print("📸 ========== RECIPE EXTRACTION START ==========")
        print("📸 Original image data size: \(imageData.count) bytes")
        print("📸 Use preprocessing: \(usePreprocessing)")
        
        // Preprocess the image if requested
        let finalImageData: Data
        if usePreprocessing, let uiImage = UIImage(data: imageData) {
            print("📸 Converting to UIImage for preprocessing...")
            if let processedData = imagePreprocessor.preprocessForOCR(uiImage) {
                finalImageData = processedData
                print("📸 ✅ Image preprocessed - new size: \(finalImageData.count) bytes")
            } else {
                print("📸 ⚠️ Preprocessing failed, using original")
                finalImageData = imageData
            }
        } else {
            print("📸 Using original image data without preprocessing")
            finalImageData = imageData
        }
        
        print("📸 Converting image to base64...")
        let base64Image = finalImageData.base64EncodedString()
        print("📸 Base64 string length: \(base64Image.count) characters")
        
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
        
        print("📸 Building API request...")
        print("📸 Using model: \(recipeExtractionModel)")
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
            print("📸 ❌ Invalid base URL: \(baseURL)")
            throw ClaudeAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 120 // 2 minutes for image processing
        
        print("📸 Serializing request body...")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("📸 ✅ Request body size: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            print("📸 ❌ Failed to serialize request body: \(error)")
            throw ClaudeAPIError.invalidJSON
        }
        
        print("📸 Sending request to Anthropic...")
        print("📸 URL: \(baseURL)")
        print("📸 Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📸 ✅ Received response")
        print("📸 Response data size: \(data.count) bytes")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("📸 ❌ Response is not HTTPURLResponse")
            throw ClaudeAPIError.invalidResponse
        }
        
        print("📸 HTTP Status Code: \(httpResponse.statusCode)")
        print("📸 Response Headers: \(httpResponse.allHeaderFields)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = parseAPIError(from: data)
            print("📸 ❌ API Error Response: \(errorMessage)")
            print("📸 ❌ Status Code: \(httpResponse.statusCode)")
            
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
        
        print("📸 Decoding Claude response...")
        let claudeResponse: ClaudeResponse
        do {
            claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            print("📸 ✅ Successfully decoded Claude response")
            print("📸 Response model: \(claudeResponse.model ?? "unknown")")
            print("📸 Response role: \(claudeResponse.role ?? "unknown")")
            print("📸 Content blocks: \(claudeResponse.content.count)")
        } catch {
            print("📸 ❌ Failed to decode Claude response: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📸 Raw response: \(responseString)")
            }
            throw ClaudeAPIError.invalidResponse
        }
        
        // Extract JSON from Claude's response
        print("📸 Extracting recipe JSON from response...")
        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }) else {
            print("📸 ❌ No text content found in response")
            throw ClaudeAPIError.noRecipeFound
        }
        
        print("📸 Raw text content length: \(textContent.text.count) characters")
        print("📸 Raw text preview: \(String(textContent.text.prefix(200)))...")
        
        guard let jsonString = extractJSON(from: textContent.text) else {
            print("📸 ❌ Failed to extract JSON from text")
            print("📸 Full text: \(textContent.text)")
            throw ClaudeAPIError.noRecipeFound
        }
        
        print("📸 ✅ Extracted JSON string length: \(jsonString.count) characters")
        print("📸 JSON preview: \(String(jsonString.prefix(200)))...")
        
        // Parse the recipe JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("📸 ❌ Failed to convert JSON string to Data")
            throw ClaudeAPIError.invalidJSON
        }
        
        print("📸 Parsing recipe JSON...")
        let recipeResponse: RecipeResponse
        do {
            recipeResponse = try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
            print("📸 ✅ Successfully parsed recipe")
            print("📸 Recipe title: \(recipeResponse.title)")
            print("📸 Ingredient sections: \(recipeResponse.ingredientSections.count)")
            print("📸 Instruction sections: \(recipeResponse.instructionSections.count)")
        } catch {
            print("📸 ❌ Failed to decode recipe JSON: \(error)")
            print("📸 JSON data: \(jsonString)")
            throw ClaudeAPIError.invalidJSON
        }
        
        // Convert to RecipeModel
        let recipeModel = recipeResponse.toRecipeModel()
        print("📸 ✅ Recipe extraction complete!")
        print("📸 ========== RECIPE EXTRACTION END ==========")
        
        return recipeModel
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

struct RecipeResponse: Codable {
    let title: String
    let headerNotes: String?
    let yield: String?
    let ingredientSections: [IngredientSectionResponse]
    let instructionSections: [InstructionSectionResponse]
    let notes: [RecipeNoteResponse]?
    let reference: String?
    
    func toRecipeModel() -> RecipeModel {
        RecipeModel(
            title: title,
            headerNotes: headerNotes,
            yield: yield,
            ingredientSections: ingredientSections.map { $0.toIngredientSection() },
            instructionSections: instructionSections.map { $0.toInstructionSection() },
            notes: notes?.map { $0.toRecipeNote() } ?? [],
            reference: reference
        )
    }
}

struct IngredientSectionResponse: Codable {
    let title: String?
    let ingredients: [IngredientResponse]
    let transitionNote: String?
    
    func toIngredientSection() -> IngredientSection {
        IngredientSection(
            title: title,
            ingredients: ingredients.map { $0.toIngredient() },
            transitionNote: transitionNote
        )
    }
}

struct IngredientResponse: Codable {
    let quantity: String?
    let unit: String?
    let name: String
    let preparation: String?
    let metricQuantity: String?
    let metricUnit: String?
    
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
}

struct InstructionSectionResponse: Codable {
    let title: String?
    let steps: [InstructionStepResponse]
    
    func toInstructionSection() -> InstructionSection {
        InstructionSection(
            title: title,
            steps: steps.map { $0.toInstructionStep() }
        )
    }
}

struct InstructionStepResponse: Codable {
    let stepNumber: Int?
    let text: String
    
    func toInstructionStep() -> InstructionStep {
        InstructionStep(
            stepNumber: stepNumber,
            text: text
        )
    }
}

struct RecipeNoteResponse: Codable {
    let type: String
    let text: String
    
    func toRecipeNote() -> RecipeNote {
        let noteType = RecipeNote.NoteType(rawValue: type) ?? .general
        return RecipeNote(type: noteType, text: text)
    }
}

// MARK: - Error Types

enum ClaudeAPIError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noRecipeFound
    case invalidJSON
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .noRecipeFound:
            return "No recipe could be extracted from the image"
        case .invalidJSON:
            return "Could not parse recipe JSON"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
