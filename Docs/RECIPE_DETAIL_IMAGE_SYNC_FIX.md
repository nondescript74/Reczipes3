# Fix: Images Not Appearing in RecipeDetailView After Adding

## Problem

When adding images in the Recipe Editor:
1. User adds images successfully
2. Images save to SwiftData correctly
3. Images appear when returning to the editor
4. **BUT** images don't show in the sliding image gallery in RecipeDetailView
5. User has to close and reopen the recipe to see new images

## Root Cause

The issue is a **data synchronization problem** between two representations of the same recipe:

### Two Sources of Data
1. **RecipeModel** (struct) - Immutable snapshot passed to RecipeDetailView
2. **Recipe** (SwiftData entity) - Live database entity that gets updated

### The Flow
```
RecipeDetailView initialized
    ├── Receives: RecipeModel (snapshot)
    ├── Queries: Recipe entity (live)
    └── Image display: Uses RecipeModel ❌

User adds image in Editor
    ├── Updates: Recipe entity ✅
    └── RecipeModel snapshot: Not updated ❌

RecipeDetailView displays images
    ├── Reads from: RecipeModel (stale) ❌
    └── Result: New images not shown
```

### The Code Issue

**Before (line 894-923):**
```swift
private func getAllImageNames(for recipe: RecipeModel) -> [String] {
    var names: [String] = []
    
    // Always reads from RecipeModel snapshot
    if let imageName = recipe.imageName {
        names.append(imageName)
    }
    
    if let additionalNames = recipe.additionalImageNames {
        names.append(contentsOf: additionalNames)
    }
    
    // ...
}
```

This function always reads from the `RecipeModel` parameter, which is a snapshot taken when the view was created. It never reflects updates made to the live `Recipe` entity.

## Solution

**Read from the live SwiftData entity when available**, which always has the most current data.

### Implementation

```swift
private func getAllImageNames(for recipe: RecipeModel) -> [String] {
    var names: [String] = []
    
    // Check if this is a saved recipe with a live entity
    if let savedRecipe = savedRecipe {
        // Use live SwiftData entity (always current)
        if let imageName = savedRecipe.imageName {
            names.append(imageName)
        }
        
        if let additionalNames = savedRecipe.additionalImageNames {
            names.append(contentsOf: additionalNames)
        }
    } else {
        // For unsaved recipes, use the RecipeModel snapshot
        if let imageName = recipe.imageName {
            names.append(imageName)
        }
        
        if let additionalNames = recipe.additionalImageNames {
            names.append(contentsOf: additionalNames)
        }
        
        if let imageURLs = recipe.imageURLs {
            names.append(contentsOf: imageURLs)
        }
    }
    
    // Remove duplicates while preserving order
    let uniqueNames = names.reduce(into: [String]()) { result, item in
        if !result.contains(item) {
            result.append(item)
        }
    }
    
    return uniqueNames
}
```

## How It Works

### For Saved Recipes
```
RecipeDetailView displays images
    ├── Calls: getAllImageNames(for: recipeModel)
    ├── Checks: savedRecipe (live entity) exists? ✅
    ├── Reads from: savedRecipe.additionalImageNames
    └── Result: Shows ALL images including newly added ✅
```

### For Unsaved Recipes (Preview)
```
RecipeDetailView displays images
    ├── Calls: getAllImageNames(for: recipeModel)
    ├── Checks: savedRecipe exists? ❌
    ├── Reads from: recipeModel (snapshot)
    └── Result: Shows images from extraction ✅
```

## Data Flow Diagram

### Before Fix
```
┌──────────────────┐
│ Recipe Editor    │
│ Add image        │
└────────┬─────────┘
         │
         v
┌──────────────────┐
│ Recipe (Entity)  │ ← Updated ✅
│ SwiftData        │
└──────────────────┘

┌──────────────────┐
│ RecipeModel      │ ← Not updated ❌
│ (Snapshot)       │
└────────┬─────────┘
         │
         v
┌──────────────────┐
│ RecipeDetailView │
│ Shows old images │ ← Problem ❌
└──────────────────┘
```

### After Fix
```
┌──────────────────┐
│ Recipe Editor    │
│ Add image        │
└────────┬─────────┘
         │
         v
┌──────────────────┐
│ Recipe (Entity)  │ ← Updated ✅
│ SwiftData        │
└────────┬─────────┘
         │
         └─────────────────────┐
                               v
┌──────────────────┐    ┌──────────────────┐
│ RecipeModel      │    │ RecipeDetailView │
│ (Snapshot)       │    │ Reads from       │
└──────────────────┘    │ live entity ✅   │
                        │ Shows new images │ ← Fixed ✅
                        └──────────────────┘
```

## Benefits

1. ✅ **Immediate Updates**: New images appear instantly
2. ✅ **No Refresh Needed**: Don't need to close/reopen recipe
3. ✅ **Correct Data Source**: Always reads from live data
4. ✅ **Backward Compatible**: Unsaved recipes still work
5. ✅ **Maintains Performance**: No extra queries needed

## Testing Scenarios

### Test 1: Add Single Image
1. Open saved recipe detail view
2. Tap Edit → Images → Add Photo
3. Select and add image
4. Tap Done → Done
5. **Result**: New image appears in sliding gallery ✅

### Test 2: Add Multiple Images
1. Open saved recipe
2. Add 3 images in sequence
3. Return to detail view
4. **Result**: All 3 new images visible in gallery ✅

### Test 3: Delete Image
1. Open recipe with multiple images
2. Delete one image in editor
3. Return to detail view
4. **Result**: Deleted image no longer shown ✅

### Test 4: Unsaved Recipe Preview
1. Extract recipe from URL
2. View in preview (not saved yet)
3. **Result**: Extraction images shown correctly ✅

### Test 5: Mixed Scenario
1. Recipe has main image + 2 additional
2. Add 2 more images
3. Delete 1 old image
4. **Result**: Shows main + 1 old + 2 new = 4 images ✅

## Files Modified

- `RecipeDetailView.swift`
  - Modified `getAllImageNames(for:)` function
  - Added logic to prefer live SwiftData entity
  - Maintains fallback to RecipeModel for unsaved recipes

## Technical Notes

### Why Use savedRecipe Property?

The view already has a computed property:
```swift
private var savedRecipe: Recipe? {
    savedRecipes.first { $0.id == recipe.id }
}
```

This queries the live SwiftData entity, which is automatically kept up-to-date by SwiftUI/SwiftData observation. No manual refresh needed!

### SwiftData Observation

SwiftData uses `@Observable` macro which means:
- Changes to `Recipe.additionalImageNames` trigger view updates
- The `savedRecipe` computed property always returns current data
- No need for manual `@Published` or `objectWillChange`

### Performance Impact

Negligible:
- No extra database queries (property already existed)
- Array concatenation is O(n) where n = number of images (small)
- Deduplication is O(n²) in worst case, but n is typically < 10

## Related Issues Prevented

This fix also prevents:
1. Stale image counts in UI
2. Deleted images still showing
3. Reordered images not reflecting
4. Any other image array modifications not appearing

## Future Improvements

Consider updating the entire view to use live data:
1. Pass `Recipe` entity instead of `RecipeModel`
2. Convert `RecipeModel` to computed property
3. Eliminate dual data sources entirely
4. Would require refactoring extraction flow

## Summary

The fix ensures that **RecipeDetailView always shows the current state** of a recipe's images by reading from the live SwiftData entity (`savedRecipe`) instead of the stale snapshot (`recipe: RecipeModel`). This provides a seamless user experience where image changes appear immediately without any manual refresh.
