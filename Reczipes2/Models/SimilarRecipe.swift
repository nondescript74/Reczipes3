//
//  SimilarRecipe.swift
//  Reczipes2
//
//  Model for representing similar recipe suggestions from web searches
//

import Foundation

/// Represents a similar recipe found on the web
struct SimilarRecipe: Identifiable, Codable {
    let id: UUID
    let title: String
    let source: String // Website name
    let sourceURL: String
    let imageURL: String?
    let description: String?
    let ingredients: [String] // Simplified ingredient list
    let instructions: [String] // Simplified instruction steps
    let prepTime: String?
    let cookTime: String?
    let totalTime: String?
    let servings: String?
    let cuisine: String?
    let matchScore: Double // 0.0 to 1.0, how closely it matches the original
    let matchReasons: [String] // Why this recipe was suggested
    
    // Custom decoding to auto-generate UUID if not provided
    enum CodingKeys: String, CodingKey {
        case id, title, source, sourceURL, imageURL, description
        case ingredients, instructions, prepTime, cookTime, totalTime
        case servings, cuisine, matchScore, matchReasons
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.source = try container.decode(String.self, forKey: .source)
        self.sourceURL = try container.decode(String.self, forKey: .sourceURL)
        self.imageURL = try? container.decode(String.self, forKey: .imageURL)
        self.description = try? container.decode(String.self, forKey: .description)
        self.ingredients = try container.decode([String].self, forKey: .ingredients)
        self.instructions = try container.decode([String].self, forKey: .instructions)
        self.prepTime = try? container.decode(String.self, forKey: .prepTime)
        self.cookTime = try? container.decode(String.self, forKey: .cookTime)
        self.totalTime = try? container.decode(String.self, forKey: .totalTime)
        self.servings = try? container.decode(String.self, forKey: .servings)
        self.cuisine = try? container.decode(String.self, forKey: .cuisine)
        self.matchScore = try container.decode(Double.self, forKey: .matchScore)
        self.matchReasons = try container.decode([String].self, forKey: .matchReasons)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        source: String,
        sourceURL: String,
        imageURL: String? = nil,
        description: String? = nil,
        ingredients: [String],
        instructions: [String],
        prepTime: String? = nil,
        cookTime: String? = nil,
        totalTime: String? = nil,
        servings: String? = nil,
        cuisine: String? = nil,
        matchScore: Double = 0.0,
        matchReasons: [String] = []
    ) {
        self.id = id
        self.title = title
        self.source = source
        self.sourceURL = sourceURL
        self.imageURL = imageURL
        self.description = description
        self.ingredients = ingredients
        self.instructions = instructions
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = totalTime
        self.servings = servings
        self.cuisine = cuisine
        self.matchScore = matchScore
        self.matchReasons = matchReasons
    }
}

/// Response from recipe validation containing corrections and suggestions
struct RecipeValidationResult: Codable {
    let isValid: Bool
    let corrections: RecipeCorrections?
    let suggestions: [String]
    let confidence: Double // 0.0 to 1.0
    
    struct RecipeCorrections: Codable {
        let title: String?
        let cuisine: String?
        let ingredientSections: [SimplifiedIngredientSection]?
        let instructionSections: [SimplifiedInstructionSection]?
        let headerNotes: String?
        let recipeYield: String?
        let misplacedContent: [MisplacedContent]?
        
        struct MisplacedContent: Codable {
            let content: String
            let currentLocation: String // e.g., "notes", "ingredients"
            let suggestedLocation: String // e.g., "instructions", "headerNotes"
            let reason: String
        }
        
        // Simplified structure for validation responses (no UUIDs needed)
        struct SimplifiedIngredientSection: Codable {
            let title: String?
            let ingredients: [String] // Simple string array like "1 cup flour"
        }
        
        struct SimplifiedInstructionSection: Codable {
            let title: String?
            let steps: [String] // Simple string array
        }
    }
}
