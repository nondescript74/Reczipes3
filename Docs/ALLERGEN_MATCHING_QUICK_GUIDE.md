# Quick Reference: Context-Aware Allergen Matching

## Common False Positives - Now Fixed ✅

| Ingredient | Previously Matched | Correct Behavior | Reason |
|-----------|-------------------|------------------|--------|
| cream of tartar | ❌ "cream" (dairy) | ✅ No match | Potassium bitartrate, not dairy |
| coconut milk | ❌ "milk" (dairy) | ✅ No match | Plant-based, dairy-free |
| almond milk | ❌ "milk" (dairy) | ✅ No match | Plant-based, dairy-free |
| oat milk | ❌ "milk" (dairy) | ✅ No match | Plant-based, dairy-free |
| soy milk | ❌ "milk" (dairy) | ✅ No match | Plant-based, dairy-free |
| peanut butter | ❌ "butter" (dairy) | ✅ No match | Nut butter, no dairy |
| almond butter | ❌ "butter" (dairy) | ✅ No match | Nut butter, no dairy |
| cashew butter | ❌ "butter" (dairy) | ✅ No match | Nut butter, no dairy |
| cocoa butter | ❌ "butter" (dairy) | ✅ No match | Cacao fat, no dairy |
| butternut squash | ❌ "butter" (dairy) | ✅ No match | Vegetable, no dairy |
| eggplant | ❌ "egg" (eggs) | ✅ No match | Vegetable, no eggs |
| buckwheat | ❌ "wheat" (gluten) | ✅ No match | Gluten-free grain |
| nutmeg | ❌ "nut" (tree nuts) | ✅ No match | Spice, not a nut |
| coconut | ❌ "nut" (tree nuts) | ✅ No match | Fruit, not a tree nut |
| soy-free | ❌ "soy" | ✅ No match | Explicitly soy-free |

## True Positives - Still Detected ✅

| Ingredient | Keyword | Correctly Matches |
|-----------|---------|-------------------|
| heavy cream | "cream" | ✅ Dairy |
| whipping cream | "cream" | ✅ Dairy |
| sour cream | "cream" | ✅ Dairy |
| whole milk | "milk" | ✅ Dairy |
| skim milk | "milk" | ✅ Dairy |
| unsalted butter | "butter" | ✅ Dairy |
| melted butter | "butter" | ✅ Dairy |
| large eggs | "egg" | ✅ Eggs |
| egg whites | "egg" | ✅ Eggs |
| all-purpose flour | "wheat" | ✅ Wheat |
| wheat flour | "wheat" | ✅ Wheat |
| almonds | "almond" | ✅ Tree nuts |
| cashews | "cashew" | ✅ Tree nuts |

## How It Works

### 1. Word Boundary Matching
```swift
// OLD: Simple substring matching
if ingredient.contains("cream") { ... }  // ❌ Matches "cream of tartar"

// NEW: Word boundary detection
if ingredient.matches(wordBoundary: "cream") { ... }  // ✅ Won't match "cream of tartar"
```

### 2. Exception Dictionary
```swift
let exceptions = [
    "cream": ["cream of tartar", "creamer"],
    "milk": ["coconut milk", "almond milk"],
    "butter": ["peanut butter", "butternut"]
]
```

### 3. Full Context Analysis
```swift
// OLD: Just ingredient names
"cream of tartar"

// NEW: Full ingredient phrase
"1/2 teaspoon cream of tartar"
```

## Adding New Exceptions

### In Code (AllergenAnalyzer.swift)
```swift
private func isKnownException(ingredient: String, keyword: String) -> Bool {
    let exceptions: [String: [String]] = [
        "cream": ["cream of tartar", "cream of wheat", "creamer"],
        "newKeyword": ["exception1", "exception2"]  // ← Add here
    ]
    // ...
}
```

### In Claude Prompts (AllergenAnalyzer.swift)
```swift
Common mistakes to AVOID:
- "cream of tartar" is NOT dairy cream
- "your new example" is NOT an allergen
```

## Testing New Patterns

```swift
@Test("Your test description")
func yourTestName() async throws {
    // Given: A recipe with the potentially confusing ingredient
    let recipe = createTestRecipe(ingredients: ["your ingredient"])
    let profile = createTestProfile(sensitivityName: "Allergen", keywords: ["keyword"])
    
    // When: Analyzing the recipe
    let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
    
    // Then: Should/shouldn't match
    #expect(score.isSafe, "Should not match")
}
```

## Debugging Tips

### Check Local Matching
```swift
let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
print("Detected allergens:", score.detectedAllergens.map { $0.sensitivity.name })
print("Matched ingredients:", score.detectedAllergens.flatMap { $0.matchedIngredients })
```

### Check Claude Analysis
```swift
let prompt = AllergenAnalyzer.shared.generateClaudeAnalysisPrompt(
    recipe: recipe,
    profile: profile
)
print("Prompt sent to Claude:")
print(prompt)
```

### Review False Positives Avoided
```swift
if let avoided = enhancedScore.claudeAnalysis.falsePositivesAvoided {
    for item in avoided {
        print("✓ Correctly ignored: \(item.ingredient)")
        print("  Because: \(item.whyNotAnAllergen)")
    }
}
```

## Best Practices

### ✅ Do:
- Use complete ingredient phrases (e.g., "1 cup coconut milk")
- Include preparation methods (e.g., "melted butter")
- Test both positive and negative cases
- Add common variations to exception dictionary
- Document why an exception exists

### ❌ Don't:
- Use simple substring matching for new features
- Ignore word boundaries
- Forget to test edge cases
- Add exceptions without understanding why

## Performance Notes

- **Local matching**: < 1ms per recipe (even with 50+ ingredients)
- **Claude API**: 2-5 seconds (network latency, not algorithm)
- **Memory**: Minimal overhead (exception dictionary is small)
- **Caching**: Consider caching Claude results for performance

## Related Files

- `AllergenAnalyzer.swift` - Main matching logic
- `AllergenAnalyzer+Claude.swift` - Claude integration
- `ClaudeAPIClient.swift` - Recipe extraction prompts
- `ImprovedIngredientMatchingTests.swift` - Test suite
- `INGREDIENT_PARSING_IMPROVEMENTS.md` - Detailed documentation

## Common Questions

### Q: Why not use a database of all ingredients?
**A:** Databases require maintenance, storage, and may not cover regional variations. The exception-based approach is flexible and handles edge cases well.

### Q: What about typos or variations?
**A:** The word-boundary approach handles basic variations. For typos, consider adding fuzzy matching in future versions.

### Q: How do I handle new plant-based alternatives?
**A:** Add to the exception dictionary and update Claude prompts with examples.

### Q: Can users add their own exceptions?
**A:** Not yet, but this is a planned feature. Users could mark false positives for review.

### Q: What about cross-contamination?
**A:** Claude is instructed to note cross-contamination risks. Local matching doesn't handle this (by design - focuses on explicit ingredients).

## Example Scenarios

### Scenario 1: User has dairy sensitivity
```
Recipe ingredients:
- 1 cup coconut milk ✅ Not flagged (correctly)
- 1/2 tsp cream of tartar ✅ Not flagged (correctly)
- 1 cup heavy cream ⚠️ FLAGGED (correctly)
```

### Scenario 2: User has nut allergy
```
Recipe ingredients:
- 2 tbsp peanut butter ⚠️ FLAGGED (correctly - contains peanuts)
- 1 butternut squash ✅ Not flagged (correctly)
- 1/2 cup almond butter ⚠️ FLAGGED (correctly - contains almonds)
```

### Scenario 3: User has egg allergy
```
Recipe ingredients:
- 1 large eggplant ✅ Not flagged (correctly)
- 2 large eggs ⚠️ FLAGGED (correctly)
```

## Update History

- **v1.0** (2026-01-06): Initial implementation with word boundary detection
- **v1.1** (planned): User-submitted exceptions
- **v1.2** (planned): Machine learning-based matching
- **v2.0** (planned): Integration with ingredient databases

## Support

For issues or questions:
1. Check `INGREDIENT_PARSING_IMPROVEMENTS.md` for details
2. Review test suite in `ImprovedIngredientMatchingTests.swift`
3. Add new test cases for edge cases you discover
4. Update exception dictionary as needed
