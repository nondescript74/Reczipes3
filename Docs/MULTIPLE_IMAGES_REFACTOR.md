# Multiple Images Refactoring Summary

## Overview
Refactored the Recipe model and RecipeImageAssignmentView to support multiple images per recipe, with the main image being immutable (set during extraction) and additional images being user-manageable.

## Changes Made

### 1. Recipe Model (`Recipe-Models.swift`)
**Added:**
- `additionalImageNames: [String]?` - Array to store additional user-added images
- `allImageNames` computed property - Returns all images (main + additional)
- `imageCount` computed property - Returns total count of images

**Modified:**
- Updated `init` to accept `additionalImageNames` parameter
- Updated `toRecipeModel()` to include `additionalImageNames` when converting to RecipeModel

**Behavior:**
- Main image (`imageName`) is set during recipe extraction and cannot be modified in the UI
- Additional images are stored as an array and can be added/removed by the user
- All images are saved to the Documents directory with unique filenames

### 2. RecipeModel (`RecipeModel.swift`)
**Added:**
- `additionalImageNames: [String]?` - Matches Recipe's additional images field
- `allImageNames` computed property - Returns combined array of all images
- `imageCount` computed property - Returns total image count

**Modified:**
- Updated `init` to accept `additionalImageNames` parameter

### 3. RecipeImageAssignmentView (`RecipeImageAssignmentView.swift`)

#### Removed Dependencies
- Removed `@Query` for `RecipeImageAssignment` (no longer needed)
- Removed helper methods that worked with the old assignment system
- All image management now directly through Recipe entities

#### Updated Architecture
- Works directly with `Recipe` entities from SwiftData
- Added `getRecipe(for:)` helper to retrieve Recipe entity from RecipeModel
- Simplified data flow by eliminating the separate assignment model

#### New UI Components

**RecipePhotoRow:**
- Displays main image with "MAIN" badge (read-only)
- Shows count of additional images
- Horizontal scrollable gallery of additional images
- Each additional image has a remove button
- "Add" button opens multi-photo picker

**MultiPhotoPickerSheet:**
- Supports discontinuous multi-selection using `Set<String>` for selected assets
- Visual feedback with blue borders and checkmarks on selected photos
- Bottom toolbar shows selection count and "Clear" button
- "Add X" button (disabled when no selection) to confirm
- Saves all selected photos with unique filenames

**SelectablePhotoThumbnailView:**
- Toggle selection on tap
- Visual states: unselected (gray border) vs selected (blue border + checkmark)
- Smooth animation on selection state change

### 4. File Naming Convention
```swift
// Main image (set during extraction)
"recipe_<UUID>.jpg"

// Additional images (user-added)
"recipe_<UUID>_additional_<timestamp>_<random>.jpg"
```

This ensures:
- No filename conflicts
- Easy identification of image type
- Association with recipe via UUID

## User Experience

### Main Image
- Automatically assigned when recipe is first extracted
- Displayed with "MAIN" badge in the assignment view
- Cannot be changed or removed in RecipeImageAssignmentView
- Always the first image for the recipe

### Additional Images
- User can add multiple photos from their library
- Discontinuous selection supported (tap to select/deselect multiple)
- Displayed in a horizontal scroll view below the main image
- Each image has an X button to remove it
- Images are saved immediately to Documents directory

### Visual Hierarchy
```
┌─────────────────────────────────────────┐
│ [Main Image]  Recipe Title              │
│ "MAIN" badge  Main + 2 additional       │
│                                    [+]   │
├─────────────────────────────────────────┤
│ [img1] [img2]  ← scrollable gallery     │
│   [x]    [x]   ← remove buttons         │
└─────────────────────────────────────────┘
```

## Data Persistence

### SwiftData Schema
```swift
@Model
final class Recipe {
    var imageName: String?              // Main image
    var additionalImageNames: [String]? // Additional images
    // ... other properties
}
```

### File System
All images stored in Documents directory:
```
Documents/
├── recipe_<UUID>.jpg                          (main)
├── recipe_<UUID>_additional_<ts>_<rand>.jpg  (additional)
└── recipe_<UUID>_additional_<ts>_<rand>.jpg  (additional)
```

## Migration Notes

### Existing Data
- Recipes with existing `imageName` will continue to work
- The `additionalImageNames` field is optional, so existing recipes default to `nil`
- No migration needed for existing recipes

### RecipeImageAssignment Model
- The old `RecipeImageAssignment` model is no longer used by RecipeImageAssignmentView
- Can be deprecated or removed if not used elsewhere
- Old assignment data won't affect new functionality

## Benefits

1. **Cleaner Architecture**: Direct relationship between Recipe and images
2. **Better User Control**: Users can manage a gallery of images per recipe
3. **Protected Main Image**: Main image set during extraction is preserved
4. **Flexible Selection**: Multi-select with discontinuous support
5. **Scalable**: Array-based storage allows unlimited additional images
6. **Type Safety**: Using SwiftData directly instead of separate assignment model

## Testing Checklist

- [ ] Verify main image is displayed correctly
- [ ] Verify main image cannot be removed
- [ ] Add multiple images in one session
- [ ] Remove individual additional images
- [ ] Test discontinuous selection (tap multiple non-adjacent photos)
- [ ] Verify images persist after app restart
- [ ] Test with recipes that have no main image
- [ ] Test with recipes that have no additional images
- [ ] Verify image files are deleted when removed from recipe
- [ ] Test with photo library permission states (denied, limited, full)

## Future Enhancements

1. **Reordering**: Drag to reorder additional images
2. **Full Screen Preview**: Tap image to view full size
3. **Image Metadata**: Store captions or notes per image
4. **Main Image Selection**: Allow user to choose which image is the main one
5. **Batch Operations**: Select multiple recipes to add same images
6. **Image Optimization**: Auto-resize/compress images for performance
