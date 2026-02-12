//
//  RecipeEnhancementService.swift
//  Reczipes2
//
//  Service for validating and enhancing recipes extracted from images
//

import Foundation

/// Service for validating recipe content and finding similar recipes online
@MainActor
class RecipeEnhancementService {
    private let apiClient: ClaudeAPIClient
    
    init(apiKey: String) {
        self.apiClient = ClaudeAPIClient(apiKey: apiKey)
    }
    
    // MARK: - Content Validation
    
    /// Validates and corrects recipe content extracted from an image
    /// - Parameter recipe: The extracted recipe to validate
    /// - Returns: Validation result with suggested corrections
    func validateRecipeContent(_ recipe: RecipeX) async throws -> RecipeValidationResult {
        logInfo("Starting recipe content validation for: \(recipe.safeTitle)", category: "enhancement")
        
        let systemPrompt = """
        You are a recipe validation expert. Your job is to review recipes extracted from images and ensure:
        1. The title accurately describes the dish
        2. Ingredients are properly categorized and formatted
        3. Instructions are in the correct location and logical order
        4. General text is correctly placed (header notes vs. instructions vs. notes)
        5. Cuisine type is identified if possible
        6. Yield/servings information is present and clear
        
        For recipes extracted from images, content placement can be haphazard. Look for:
        - Ingredient-like text in notes or instructions
        - Instruction-like text in ingredients or notes
        - Title or description text mixed in with other sections
        - Missing or unclear cuisine identification
        
        Provide specific corrections and high confidence when you're certain.
        """
        
        // Build the recipe data for validation
        let recipeData = buildRecipeJSON(recipe)
        
        let userPrompt = """
        Please validate this recipe extracted from an image and provide corrections:
        
        \(recipeData)
        
        Return your analysis in this exact JSON format:
        {
          "isValid": true/false,
          "corrections": {
            "title": "corrected title if needed",
            "cuisine": "identified cuisine type",
            "ingredientSections": [...corrected sections if needed...],
            "instructionSections": [...corrected sections if needed...],
            "headerNotes": "corrected header notes if needed",
            "recipeYield": "corrected yield if needed",
            "misplacedContent": [
              {
                "content": "the misplaced text",
                "currentLocation": "where it currently is",
                "suggestedLocation": "where it should be",
                "reason": "why it should be moved"
              }
            ]
          },
          "suggestions": [
            "human-readable suggestion 1",
            "human-readable suggestion 2"
          ],
          "confidence": 0.95
        }
        
        IMPORTANT:
        - Only include fields in "corrections" that actually need correction
        - If the recipe is well-structured, set "isValid" to true and minimize corrections
        - If no corrections are needed for a field, set it to null
        - Be specific in suggestions
        - Confidence should reflect how certain you are about the corrections (0.0 to 1.0)
        
        Return ONLY valid JSON with no markdown formatting.
        """
        
        let validationJSON = try await apiClient.callClaude(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 4096
        )
        
        logInfo("Received validation response", category: "enhancement")
        
        // Extract JSON from response (remove markdown code blocks if present)
        let cleanedJSON = extractJSON(from: validationJSON)
        logDebug("Cleaned JSON for decoding: \(String(cleanedJSON.prefix(500)))", category: "enhancement")
        
        // Parse the validation result
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            logError("Failed to convert cleaned JSON to data", category: "enhancement")
            throw EnhancementError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(RecipeValidationResult.self, from: jsonData)
            logInfo("✅ Validation complete. Valid: \(result.isValid), Confidence: \(result.confidence)", category: "enhancement")
            if let corrections = result.corrections {
                logInfo("Corrections found: cuisine=\(corrections.cuisine ?? "nil"), sections=\(corrections.ingredientSections?.count ?? 0)", category: "enhancement")
            }
            return result
        } catch let DecodingError.keyNotFound(key, context) {
            logError("❌ Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))", category: "enhancement")
            logDebug("Context: \(context.debugDescription)", category: "enhancement")
            logDebug("Full JSON: \(cleanedJSON)", category: "enhancement")
            throw EnhancementError.validationFailed
        } catch {
            logError("Failed to decode validation result: \(error)", category: "enhancement")
            logDebug("Cleaned JSON: \(cleanedJSON)", category: "enhancement")
            throw EnhancementError.validationFailed
        }
    }
    
    // MARK: - Similar Recipe Search
    
    /// Searches for similar recipes on the web
    /// - Parameter recipe: The recipe to find similar recipes for
    /// - Returns: Array of similar recipes found online
    func findSimilarRecipes(_ recipe: RecipeX, count: Int = 5) async throws -> [SimilarRecipe] {
        logInfo("Searching for \(count) similar recipes to: \(recipe.safeTitle)", category: "enhancement")
        
        let systemPrompt = """
        You are a recipe research assistant with web search access. Search the web for \(count) real recipes from popular recipe websites like AllRecipes, Food Network, Bon Appétit, NYT Cooking, Serious Eats, etc.
        
        For each recipe found, extract all available details including: title, website name and URL, image URL, description, ingredients, instructions, timing, servings, and cuisine type.
        """
        
        // Extract key information from the recipe
        let recipeInfo = buildRecipeSearchQuery(recipe)
        
        let userPrompt = """
        Search the web for \(count) recipes for: \(recipeInfo)
        
        Find real recipes from popular recipe websites. For each recipe, provide complete details in this JSON format:
        
        [
          {
            "title": "Recipe Title",
            "source": "Website Name",
            "sourceURL": "https://example.com/recipe",
            "imageURL": "https://example.com/image.jpg",
            "description": "Brief description of the recipe",
            "ingredients": [
              "1 cup flour",
              "2 eggs",
              "..."
            ],
            "instructions": [
              "Preheat oven to 350°F",
              "Mix ingredients",
              "..."
            ],
            "prepTime": "15 minutes",
            "cookTime": "30 minutes",
            "totalTime": "45 minutes",
            "servings": "Serves 4",
            "cuisine": "Italian",
            "matchScore": 0.85,
            "matchReasons": [
              "Uses same main protein (beef)",
              "Similar East Indian spice profile",
              "Comparable cooking method (curry)"
            ]
          }
        ]
        
        IMPORTANT:
        - Use web search to find REAL recipes from actual websites
        - Include complete ingredient lists and instructions
        - Match score: 1.0 = very similar, 0.7 = moderately similar, 0.5 = loosely similar
        - If you cannot find the exact recipe, search for similar alternatives based on:
          * Same cuisine type (e.g., if "Mani flatbread" isn't found, search for other Indian flatbreads like naan, roti, paratha)
          * Similar ingredients or cooking methods
          * Related dishes from the same culinary tradition
        - Only return an empty array [] if you truly cannot find ANY related recipes
        - Return ONLY valid JSON array with no markdown formatting or explanatory text
        """
        
        let recipesJSON = try await apiClient.callClaude(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 8192,
            enableWebSearch: true
        )
        
        logInfo("Received similar recipes response", category: "enhancement")
        logDebug("Raw response length: \(recipesJSON.count) characters", category: "enhancement")
        logDebug("Raw response preview: \(String(recipesJSON.prefix(500)))", category: "enhancement")
        
        // Extract JSON from response (remove markdown code blocks if present)
        let cleanedJSON = extractJSON(from: recipesJSON)
        logDebug("Cleaned JSON length: \(cleanedJSON.count) characters", category: "enhancement")
        logDebug("Cleaned JSON preview: \(String(cleanedJSON.prefix(500)))", category: "enhancement")
        
        // Parse the similar recipes
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            logError("Failed to convert cleaned JSON to data", category: "enhancement")
            throw EnhancementError.invalidResponse
        }
        
        do {
            let recipes = try JSONDecoder().decode([SimilarRecipe].self, from: jsonData)
            logInfo("Found \(recipes.count) similar recipes", category: "enhancement")
            return recipes
        } catch {
            logError("Failed to decode similar recipes: \(error)", category: "enhancement")
            logDebug("Cleaned JSON: \(cleanedJSON)", category: "enhancement")
            throw EnhancementError.noRecipesFound
        }
    }
    
    // MARK: - Helper Methods
    
    private func buildRecipeJSON(_ recipe: RecipeX) -> String {
        var json = [String: Any]()
        
        json["title"] = recipe.title ?? ""
        json["headerNotes"] = recipe.headerNotes ?? ""
        json["yield"] = recipe.recipeYield ?? ""
        json["cuisine"] = recipe.cuisine ?? ""
        json["reference"] = recipe.reference ?? ""
        
        // Include ingredient sections
        if let ingredientData = recipe.ingredientSectionsData,
           let sections = try? JSONDecoder().decode([IngredientSection].self, from: ingredientData) {
            json["ingredientSections"] = sections.map { section in
                [
                    "title": section.title ?? "",
                    "ingredients": section.ingredients.map { ingredient in
                        "\(ingredient.quantity ?? "") \(ingredient.unit ?? "") \(ingredient.name) \(ingredient.preparation ?? "")".trimmingCharacters(in: .whitespaces)
                    }
                ]
            }
        }
        
        // Include instruction sections
        if let instructionData = recipe.instructionSectionsData,
           let sections = try? JSONDecoder().decode([InstructionSection].self, from: instructionData) {
            json["instructionSections"] = sections.map { section in
                [
                    "title": section.title ?? "",
                    "steps": section.steps.map { $0.text }
                ]
            }
        }
        
        // Include notes
        if let notesData = recipe.notesData,
           let notes = try? JSONDecoder().decode([RecipeNote].self, from: notesData) {
            json["notes"] = notes.map { note in
                [
                    "type": note.type.rawValue,
                    "text": note.text
                ]
            }
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    /// Extracts clean JSON from Claude's response (removes markdown code blocks)
    private func extractJSON(from text: String) -> String {
        // Remove markdown code blocks if present
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to find JSON array first (for similar recipes list)
        if let arrayStart = cleaned.firstIndex(of: "["),
           let arrayEnd = cleaned.lastIndex(of: "]") {
            // Check if this looks like a valid array by seeing if it starts at root level
            // (not nested inside an object). We do this by checking if there's a { before [
            // at the same nesting level
            let beforeArray = cleaned[..<arrayStart]
            let hasObjectBefore = beforeArray.contains("{") && !beforeArray.contains("}")
            
            if !hasObjectBefore {
                // This is a root-level array, extract it
                return String(cleaned[arrayStart...arrayEnd])
            }
        }
        
        // Fall back to object extraction (for validation responses)
        if let objectStart = cleaned.firstIndex(of: "{"),
           let objectEnd = cleaned.lastIndex(of: "}") {
            return String(cleaned[objectStart...objectEnd])
        }
        
        // Return cleaned text as-is if no JSON found
        return cleaned
    }
    
    private func buildRecipeSearchQuery(_ recipe: RecipeX) -> String {
        var query = ""
        
        // Title (primary search term)
        query += "\(recipe.safeTitle)"
        
        // Cuisine (helps narrow down)
        if let cuisine = recipe.cuisine, !cuisine.isEmpty {
            query += " (\(cuisine) cuisine)"
        }
        
        return query
    }
}

// MARK: - Errors

enum EnhancementError: Error, LocalizedError {
    case invalidResponse
    case noRecipesFound
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from enhancement service"
        case .noRecipesFound:
            return "No similar recipes found"
        case .validationFailed:
            return "Recipe validation failed"
        }
    }
}
