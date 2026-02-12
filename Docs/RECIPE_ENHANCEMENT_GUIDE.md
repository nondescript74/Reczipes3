# Recipe Enhancement System - Complete Guide

## Overview

The Recipe Enhancement System is a powerful AI-driven feature designed to improve recipes extracted from images and help users discover similar recipes from top recipe websites. This feature addresses the common challenge of extracting recipes from images where content may be poorly organized or incomplete.

## Problem Statement

When users extract recipes from images (photos of recipe cards, cookbook pages, handwritten recipes), the extracted content often has several issues:

1. **Haphazard Content Placement**: Text may appear in the wrong sections
   - Ingredients mixed with instructions
   - Recipe notes in the wrong place
   - Title or description embedded in other content

2. **Missing Information**: Extracted recipes often lack:
   - Cuisine identification
   - Proper yield/servings information
   - Complete metadata

3. **Limited Context**: Image-based recipes typically have less detail than web recipes
   - Sparse instructions
   - Missing tips and variations
   - No visual reference for final result

## Solution: Two-Phase Enhancement

### Phase 1: Content Validation & Correction

After extracting a recipe from an image, the system validates and corrects the content:

**What It Does:**
- Analyzes recipe structure and content placement
- Identifies misplaced content (e.g., instructions in notes, ingredients in header)
- Suggests corrections for title, cuisine, yield
- Provides confidence scores for all suggestions
- Presents corrections to the user for approval

**User Experience:**
1. User extracts recipe from image
2. Extraction completes successfully
3. User taps "Validate Content" button
4. AI analyzes the recipe (takes 5-10 seconds)
5. Validation results appear in a modal sheet
6. User can:
   - Apply all corrections
   - Skip validation and proceed to similar recipes
   - Skip everything and save as-is

### Phase 2: Similar Recipe Discovery

After validation (or skipping it), users can discover similar recipes:

**What It Does:**
- Searches the web for 5 similar recipes
- Matches based on:
  - Main ingredients
  - Cuisine style
  - Cooking method
  - Recipe type
- Prioritizes recipes from reputable sources:
  - AllRecipes, Food Network, Bon Appétit
  - NYT Cooking, Serious Eats
  - Other established recipe websites
- Extracts complete recipe details:
  - Full ingredient lists
  - Step-by-step instructions
  - Images, timing, servings
  - Match reasons and scores

**User Experience:**
1. User taps "Find Similar" button
2. AI searches the web (takes 15-30 seconds)
3. Results appear showing 5 similar recipes
4. Each card shows:
   - Recipe image
   - Title and source
   - Match score (percentage)
   - Why it matches
   - Quick info (time, servings, cuisine)
5. User can tap any recipe to see full details
6. Full detail view includes:
   - Complete ingredients
   - All instructions
   - Link to original source
   - All metadata

## Architecture

### Components

#### 1. Data Models (`SimilarRecipe.swift`)

**SimilarRecipe**
- Represents a recipe found on the web
- Includes all recipe details plus match information
- Properties:
  - Basic: title, source, sourceURL, imageURL, description
  - Content: ingredients[], instructions[]
  - Metadata: prepTime, cookTime, servings, cuisine
  - Matching: matchScore (0.0-1.0), matchReasons[]

**RecipeValidationResult**
- Contains validation analysis results
- Properties:
  - isValid: Boolean indicating if recipe is well-structured
  - corrections: Optional corrections to apply
  - suggestions: Human-readable suggestions
  - confidence: 0.0-1.0 confidence score

**RecipeValidationResult.RecipeCorrections**
- Specific corrections for recipe fields
- All properties optional (only set if correction needed)
- Properties:
  - title, cuisine, headerNotes, recipeYield
  - ingredientSections[], instructionSections[]
  - misplacedContent[] - items in wrong locations

#### 2. Service Layer (`RecipeEnhancementService.swift`)

**RecipeEnhancementService**
- Main service coordinating enhancement operations
- Uses ClaudeAPIClient for AI operations
- Methods:
  - `validateRecipeContent(recipe)` → RecipeValidationResult
  - `findSimilarRecipes(recipe, count)` → [SimilarRecipe]

**Implementation Details:**
- Uses Claude Opus 4.5 for both operations
- Validation prompt focuses on structure and categorization
- Similar recipe search uses web search capabilities
- All JSON responses are strongly typed and validated

#### 3. UI Components

**RecipeValidationView**
- Modal sheet showing validation results
- Displays:
  - Status indicator (valid/needs improvement)
  - Confidence score
  - List of suggestions
  - Preview of corrections
  - Misplaced content warnings
- Actions:
  - Apply corrections & find similar recipes
  - Skip validation & find similar recipes
  - Skip everything and save as-is

**SimilarRecipesView**
- Modal sheet showing search results
- Displays grid of recipe cards
- Each card is tappable for full details
- Header shows count and original recipe reference

**SimilarRecipeCard**
- Compact recipe preview
- Shows image, title, source, match score
- Lists top 3 match reasons
- Quick info (time, servings, cuisine)

**SimilarRecipeDetailView**
- Full-screen recipe detail
- Complete recipe information
- Link to open source website
- All ingredients and instructions
- Match information highlighted

#### 4. Integration (`RecipeExtractorViewModel.swift`)

**New Properties:**
```swift
@Published var showingValidation = false
@Published var validationResult: RecipeValidationResult?
@Published var showingSimilarRecipes = false
@Published var similarRecipes: [SimilarRecipe] = []
@Published var isValidating = false
@Published var isFindingSimilar = false
private var enhancementService: RecipeEnhancementService?
```

**New Methods:**
- `validateRecipe()` - Triggers validation flow
- `applyValidationCorrections(result)` - Applies corrections to recipe
- `findSimilarRecipes(count)` - Searches for similar recipes
- `extractRecipeWithEnhancement(image)` - Enhanced extraction workflow

**Integration Points:**
- Initialized in `init(apiKey:)`
- Cleared in `reset()`
- Triggered from RecipeExtractorView UI

#### 5. View Integration (`RecipeExtractorView.swift`)

**Enhancement UI Section:**
- Displayed only for image-based extractions (camera/library)
- Two buttons: "Validate Content" and "Find Similar"
- Loading states shown during operations
- Positioned between extraction results and save button

**Sheets:**
- `.sheet(isPresented: $viewModel.showingValidation)` - Validation results
- `.sheet(isPresented: $viewModel.showingSimilarRecipes)` - Search results

## User Workflows

### Workflow 1: Full Enhancement Flow

1. User takes photo of recipe card
2. Recipe extracted from image
3. User taps "Validate Content"
4. Validation results shown
5. User taps "Apply Corrections & Find Similar Recipes"
6. Corrections applied automatically
7. Search executes
8. 5 similar recipes displayed
9. User explores similar recipes
10. User taps "Done"
11. User taps "Save to Collection"
12. Recipe saved with enhancements

### Workflow 2: Skip Validation, Just Search

1. User extracts recipe from image
2. User taps "Find Similar" directly
3. Search executes
4. Results displayed
5. User explores recipes
6. User saves original recipe

### Workflow 3: Validation Only

1. User extracts recipe
2. User taps "Validate Content"
3. User reviews suggestions
4. User taps "Apply Corrections & Find Similar Recipes" but dismisses search
5. User saves corrected recipe

### Workflow 4: No Enhancement

1. User extracts recipe
2. User ignores enhancement buttons
3. User taps "Save to Collection" directly
4. Original extracted recipe saved

## API Usage

### ClaudeAPIClient Extension

A new generic method was added:

```swift
func callClaude(
    systemPrompt: String,
    userPrompt: String,
    maxTokens: Int = 4096
) async throws -> String
```

This allows the enhancement service to make custom Claude API calls without being limited to recipe extraction.

### Validation Prompt Strategy

**System Prompt:**
- Defines role as recipe validation expert
- Lists validation criteria
- Emphasizes accuracy over guessing

**User Prompt:**
- Provides complete recipe JSON
- Requests specific JSON response format
- Specifies only include corrections that are needed
- Asks for confidence score

**Response Format:**
```json
{
  "isValid": true/false,
  "corrections": {
    "title": "corrected if needed",
    "cuisine": "identified cuisine",
    "misplacedContent": [...]
  },
  "suggestions": ["human readable..."],
  "confidence": 0.95
}
```

### Similar Recipe Search Strategy

**System Prompt:**
- Defines role as recipe research assistant
- Instructs to use web search
- Prioritizes reputable sources
- Requests complete recipe details

**User Prompt:**
- Provides recipe summary (title, cuisine, key ingredients)
- Requests 5 similar recipes
- Specifies JSON array response format
- Emphasizes real recipes from actual websites

**Response Format:**
```json
[
  {
    "title": "Recipe Name",
    "source": "Website Name",
    "sourceURL": "https://...",
    "imageURL": "https://...",
    "ingredients": ["1 cup flour", ...],
    "instructions": ["Step 1", ...],
    "matchScore": 0.85,
    "matchReasons": ["Uses same protein", ...]
  }
]
```

## Performance Considerations

### Timing
- Validation: 5-10 seconds (depends on recipe complexity)
- Similar recipe search: 15-30 seconds (web search + extraction)
- Both operations show loading indicators

### Token Usage
- Validation: ~2,000-4,000 tokens (input + output)
- Similar recipes: ~4,000-8,000 tokens (includes web content)
- Uses Claude Opus 4.5 for best results

### Error Handling
- Network errors caught and displayed to user
- Timeout protection (2 minutes max)
- JSON parsing errors handled gracefully
- Users can always skip and save original recipe

## Best Practices

### For Users

1. **When to Use Validation:**
   - Recipe from old recipe card
   - Handwritten recipe
   - Recipe with unclear organization
   - Text recognition seemed uncertain

2. **When to Use Similar Recipe Search:**
   - Want more detailed instructions
   - Looking for variations
   - Need timing information
   - Want to see professional photos
   - Exploring similar dishes

3. **When to Skip:**
   - Recipe is well-structured already
   - Web-extracted recipe (already complete)
   - Time-sensitive situation
   - Don't need additional recipes

### For Developers

1. **Extending Validation:**
   - Add new correction types to `RecipeCorrections`
   - Update validation prompt in `RecipeEnhancementService`
   - Update UI in `RecipeValidationView`

2. **Customizing Search:**
   - Modify `findSimilarRecipes(count:)` parameter
   - Adjust search prompt for different criteria
   - Filter by cuisine, dietary restrictions, etc.

3. **Adding Match Criteria:**
   - Update search prompt with new matching rules
   - Adjust `matchScore` calculation logic
   - Add new `matchReasons` categories

## Future Enhancements

### Potential Features

1. **Advanced Filtering:**
   - Filter similar recipes by:
     - Dietary restrictions (vegetarian, gluten-free)
     - Difficulty level
     - Cooking time
     - Rating/popularity

2. **Recipe Merging:**
   - Allow users to merge insights from similar recipes
   - Import ingredients from better recipe
   - Combine instructions
   - Add tips from multiple sources

3. **Batch Enhancement:**
   - Validate multiple recipes at once
   - Find similar recipes for entire cookbook
   - Bulk corrections

4. **Learning System:**
   - Learn from user corrections
   - Improve validation over time
   - Personalize similar recipe suggestions

5. **Offline Caching:**
   - Cache validation results
   - Store similar recipes locally
   - Reduce API calls

## Troubleshooting

### Common Issues

**Validation takes too long:**
- Check network connection
- Recipe may be very complex
- Wait for timeout, then retry

**No similar recipes found:**
- Recipe may be very unique/obscure
- Try adjusting recipe title or cuisine
- Ensure main ingredients are clear

**Validation suggests incorrect corrections:**
- AI confidence may be low (check score)
- Original extraction may have errors
- Review and skip if suggestions don't make sense

**Similar recipes don't match well:**
- Match scores indicate similarity
- Lower scores (50-70%) are looser matches
- Review match reasons to understand why suggested

## Files Created/Modified

### New Files
1. `Reczipes2/Models/SimilarRecipe.swift` - Data models
2. `Reczipes2/Models/RecipeEnhancementService.swift` - Service layer
3. `Reczipes2/Views/RecipeValidationView.swift` - Validation UI
4. `Reczipes2/Views/SimilarRecipesView.swift` - Similar recipes UI
5. `Reczipes2/Docs/RECIPE_ENHANCEMENT_GUIDE.md` - This documentation

### Modified Files
1. `Reczipes2/Models/ClaudeAPIClient.swift` - Added generic `callClaude()` method
2. `Reczipes2/Models/RecipeExtractorViewModel.swift` - Added enhancement properties and methods
3. `Reczipes2/Views/RecipeExtractorView.swift` - Added enhancement UI and sheets

## Testing Recommendations

1. **Test with various image types:**
   - Printed recipe cards
   - Handwritten recipes
   - Cookbook pages
   - Screenshots

2. **Test validation scenarios:**
   - Well-organized recipe (should validate as good)
   - Messy recipe (should suggest corrections)
   - Partial recipe (should identify missing info)

3. **Test similar recipe search:**
   - Common recipes (should find many matches)
   - Ethnic recipes (should match cuisine)
   - Unique recipes (should find related dishes)

4. **Test error conditions:**
   - No network connection
   - Invalid API key
   - Timeout scenarios

## Summary

The Recipe Enhancement System transforms image-based recipe extraction from a basic OCR operation into an intelligent, AI-powered workflow that:

1. **Validates** extracted content for accuracy and organization
2. **Corrects** common extraction errors and misplacements
3. **Enriches** recipes by finding similar, more detailed versions online
4. **Empowers** users to discover variations and professional versions of their recipes

This feature is especially valuable for users digitizing family recipe collections, old cookbooks, or handwritten recipes where the source material may be incomplete or poorly organized.
