//
//  ClaudeAPIClient.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/8/25.
//

import Foundation

class ClaudeAPIClient {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func extractRecipe(from image: Data, recipeModel: String) async throws -> RecipeModel {
        let base64Image = image.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 4096,
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
                            "text": """
                            Please extract the recipe from this image and return it as JSON matching this structure:
                            \(recipeModel)
                            
                            Return ONLY the JSON object, no additional text or markdown formatting.
                            """
                        ]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        
        // Extract JSON from Claude's response
        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
              let jsonString = extractJSON(from: textContent.text) else {
            throw APIError.noRecipeFound
        }
        
        let recipe = try JSONDecoder().decode(RecipeModel.self, from: jsonString.data(using: .utf8)!)
        return recipe
    }
    
    private func extractJSON(from text: String) -> String? {
        // Remove markdown code blocks if present
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
}

struct ClaudeResponse: Codable {
    let content: [ContentBlock]
}

struct ContentBlock: Codable {
    let type: String
    let text: String
}

enum APIError: Error {
    case invalidResponse
    case noRecipeFound
}
