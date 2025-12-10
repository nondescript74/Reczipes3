# RecipeCollection Refactor

## Overview
The `RecipeCollection` class has been refactored to properly merge bundled recipes (from Extensions.swift) with user-saved recipes (from SwiftData), with SwiftData recipes taking precedence when duplicates exist.

## Changes Made

### 1. RecipeCollection.swift
**Before:** Had a single `allRecipes` property that only contained bundled recipes from Extensions.

**After:** Now provides methods that merge bundled and saved recipes:

- `allRecipes(savedRecipes:)` - Returns all recipes, with SwiftData versions taking precedence
- `allRecipesWithStatus(savedRecipes:)` - Returns recipes with save status flags
- `bundledRecipesOnly` - Returns only the original bundled recipes
- `recipe(withID:savedRecipes:)` - Find recipe by ID, checking saved first
- `recipe(withTitle:savedRecipes:)` - Find recipe by title, checking saved first
- `isRecipeSaved(_:savedRecipes:)` - Check if a recipe has been saved

**Key Architecture:**
- Bundled recipes are stored internally as `bundledRecipes`
- Methods accept `savedRecipes: [Recipe]` parameter from SwiftData `@Query`
- Deduplication logic: If a recipe ID exists in both bundled and saved, the saved version is used
- This ensures user edits are always displayed instead of the original bundled version

### 2. ContentView.swift
**Before:** 
- Showed two separate sections: "Available Recipes" and "Saved Recipes"
- Used `RecipeCollection.shared.allRecipes` directly
- Had redundant display of recipes

**After:**
- Single unified list showing all recipes
- Uses `RecipeCollection.shared.allRecipes(savedRecipes: savedRecipes)` to get merged list
- Saved recipes are marked with a blue pencil icon
- Swipe-to-delete and context menu for removing saved versions
- When a saved recipe is deleted, the bundled version automatically reappears

## Benefits

1. **No Duplication**: Users never see the same recipe twice in the list
2. **User Edits Preserved**: Saved recipes always override bundled versions
3. **Seamless Experience**: Deleting a saved recipe reverts to the bundled version
4. **Cleaner UI**: Single unified recipe list instead of two sections
5. **Flexible Architecture**: Easy to add new recipe sources in the future

## How It Works

### Recipe Lifecycle

1. **Initial State**: All bundled recipes from Extensions.swift are available
2. **User Saves**: When a user saves/edits a recipe, it's stored in SwiftData
3. **Merged Display**: `RecipeCollection` merges both sources, preferring SwiftData
4. **Deletion**: Deleting a saved recipe reverts display to the bundled version
5. **Persistence**: Bundled recipes always remain available as defaults

### Code Flow

```swift
// In ContentView
@Query private var savedRecipes: [Recipe] // From SwiftData

private var availableRecipes: [RecipeModel] {
    // Gets merged list: saved recipes + non-saved bundled recipes
    let allRecipes = RecipeCollection.shared.allRecipes(savedRecipes: savedRecipes)
    // ... apply image assignments
}

private func isRecipeSaved(_ recipe: RecipeModel) -> Bool {
    RecipeCollection.shared.isRecipeSaved(recipe, savedRecipes: savedRecipes)
}
```

## Future Enhancements

Potential improvements:
1. Add a "Revert to Original" button for saved recipes
2. Show diff/comparison between bundled and saved versions
3. Add search/filter capabilities
4. Support for importing recipes from files
5. Export saved recipes to share with others

## Migration Notes

If you have existing code that references `RecipeCollection.shared.allRecipes`, update it to:
- Pass the `savedRecipes` parameter: `RecipeCollection.shared.allRecipes(savedRecipes: savedRecipes)`
- Access the SwiftData context through `@Query` in your view
- Use `@Environment(\.modelContext)` if you need to modify recipes

## Testing

To test the new behavior:
1. View the recipe list - you should see all bundled recipes
2. Save a recipe - it should show a blue pencil icon
3. The recipe should appear in the same position (no duplication)
4. Delete the saved version - it should revert to the bundled version
5. Extract a new recipe - it should appear in the list

## Files Modified

- `RecipeCollection.swift` - Core refactor with new API
- `ContentView.swift` - Updated to use new API, unified list UI
- `RecipeExtractorView.swift` - Fixed to provide required parameters to RecipeDetailView
