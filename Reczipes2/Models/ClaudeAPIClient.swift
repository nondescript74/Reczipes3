//
//  ClaudeAPIClient.swift
//  Reczipes2
//
//  Created for Claude-powered recipe extraction
//

import Foundation
import UIKit

class ClaudeAPIClient {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let imagePreprocessor = ImagePreprocessor()
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// Validate the API key by making a minimal test request to Anthropic
    /// - Returns: true if the API key is valid, false otherwise
    func validateAPIKey() async -> Bool {
        print("🔍 Validating API key...")
        print("🔍 API key prefix: \(String(apiKey.prefix(15)))...")
        
        let testPrompt = "Hello"
        
        // Use a stable model that's definitely available for validation
        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 10,
            "messages": [
                [
                    "role": "user",
                    "content": testPrompt
                ]
            ]
        ]
        
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("🔍 Sending validation request to Anthropic...")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return false
            }
            
            print("🔍 Response status code: \(httpResponse.statusCode)")
            
            // Log the response body for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 Response body: \(responseString)")
            }
            
            // Status code 200 means the API key is valid
            if httpResponse.statusCode == 200 {
                print("✅ API key is valid!")
                return true
            } else {
                print("❌ API key validation failed with status: \(httpResponse.statusCode)")
                return false
            }
        } catch {
            print("❌ Validation error: \(error.localizedDescription)")
            return false
        }
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
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
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
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("📸 ❌ API Error Response: \(errorMessage)")
            throw ClaudeAPIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
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
    let quantity: String
    let unit: String
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
