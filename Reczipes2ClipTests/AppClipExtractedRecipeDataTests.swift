import Foundation
import Testing

@testable import Reczipes2Clip

@Suite("AppClipExtractedRecipeData Encoding/Decoding")
struct AppClipExtractedRecipeDataTests {

    @Test("Round-trip encode/decode with all fields populated")
    @MainActor func roundTrip_full() throws {
        let original = AppClipExtractedRecipeData(
            title: "Classic Pancakes",
            servings: 4,
            prepTime: "10 min",
            cookTime: "15 min",
            ingredients: [
                "1 1/2 cups all-purpose flour",
                "3 1/2 teaspoons baking powder",
                "1 teaspoon salt",
                "1 tablespoon white sugar",
                "1 1/4 cups milk",
                "1 egg",
                "3 tablespoons butter (melted)"
            ],
            instructions: [
                "Sift dry ingredients.",
                "Whisk in wet ingredients.",
                "Cook on griddle until golden."
            ],
            notes: "Serve with syrup."
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppClipExtractedRecipeData.self, from: data)

        #expect(decoded == original)
    }

    @Test("Round-trip encode/decode with nil optionals")
    @MainActor func roundTrip_minimal() throws {
        let original = AppClipExtractedRecipeData(
            title: "Untitled",
            servings: 1,
            prepTime: nil,
            cookTime: nil,
            ingredients: [],
            instructions: [],
            notes: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppClipExtractedRecipeData.self, from: data)

        #expect(decoded == original)
    }

    @Test("Sample JSON decodes as expected")
    @MainActor func decode_sampleJSON() throws {
        let json = """
        {
          "title": "Classic Pancakes",
          "servings": 4,
          "prepTime": "10 min",
          "cookTime": "15 min",
          "ingredients": [
            "1 1/2 cups all-purpose flour",
            "3 1/2 teaspoons baking powder",
            "1 teaspoon salt"
          ],
          "instructions": [
            "Sift dry ingredients.",
            "Whisk in wet ingredients."
          ],
          "notes": "Serve with syrup."
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AppClipExtractedRecipeData.self, from: json)
        #expect(decoded.title == "Classic Pancakes")
        #expect(decoded.servings == 4)
        #expect(decoded.prepTime == "10 min")
        #expect(decoded.cookTime == "15 min")
        #expect(decoded.ingredients.count == 3)
        #expect(decoded.instructions.count == 2)
        #expect(decoded.notes == "Serve with syrup.")
    }
}
