# Loading Indicator Visibility Fix

## Problem Identified
When extracting a recipe from a library image, the user would:
1. Tap "Library" button
2. Select an image from photo library
3. Return to the RecipeExtractorView
4. **See the three source buttons (Camera, Library, URL) still visible**
5. **No loading indicator visible** even though extraction was running in background

The extraction was happening, but the UI gave no feedback to the user.

## Root Cause
The `sourceSelectionSection` and other UI components were always visible, even when `isLoading = true`. The loading indicator was added to the view stack, but it appeared **below** the source selection buttons, making it invisible or easy to miss.

## Solution
Hide all non-essential UI elements when `viewModel.isLoading` is `true`, so the loading indicator becomes the primary focus.

## Changes Made

### File: `RecipeExtractorView.swift`

**Before:**
```swift
ScrollView {
    VStack(spacing: 24) {
        // Source Selection Section
        sourceSelectionSection
        
        // URL Input (if URL source selected)
        if extractionSource == .url {
            urlInputSection
        }
        
        // Preprocessing Toggle (only for images)
        if viewModel.selectedImage != nil && extractionSource != .url {
            preprocessingToggle
        }
        
        // Image Preview
        if let image = viewModel.selectedImage, extractionSource != .url {
            imagePreviewSection(image: image)
        }
        
        // Loading Indicator
        if viewModel.isLoading {
            loadingSection
        }
        
        // Error Display
        if let error = viewModel.errorMessage {
            errorSection(message: error)
        }
        
        // Extracted Recipe
        if let recipe = viewModel.extractedRecipe {
            extractedRecipeSection(recipe: recipe)
        }
    }
}
```

**After:**
```swift
ScrollView {
    VStack(spacing: 24) {
        // Source Selection Section (hide when loading)
        if !viewModel.isLoading {
            sourceSelectionSection
        }
        
        // URL Input (if URL source selected and not loading)
        if extractionSource == .url && !viewModel.isLoading {
            urlInputSection
        }
        
        // Preprocessing Toggle (only for images and not loading)
        if viewModel.selectedImage != nil && extractionSource != .url && !viewModel.isLoading {
            preprocessingToggle
        }
        
        // Image Preview (hide during loading to keep focus on spinner)
        if let image = viewModel.selectedImage, extractionSource != .url && !viewModel.isLoading {
            imagePreviewSection(image: image)
        }
        
        // Loading Indicator
        if viewModel.isLoading {
            loadingSection
        }
        
        // Error Display
        if let error = viewModel.errorMessage {
            errorSection(message: error)
        }
        
        // Extracted Recipe
        if let recipe = viewModel.extractedRecipe {
            extractedRecipeSection(recipe: recipe)
        }
    }
}
```

## UI Behavior Changes

### Before
- User selects image from library
- Returns to main view
- Sees: Source selection buttons (Camera, Library, URL)
- Extraction happens silently in background
- **No feedback that anything is happening**

### After
- User selects image from library
- Returns to main view  
- Sees: **Only the ExtractionLoadingView** with:
  - Large animated spinner
  - Rotating messages ("Analyzing your recipe image...", "Claude is reading the text...", etc.)
  - Time estimate ("This typically takes 10-30 seconds")
- **Clear feedback that extraction is in progress**
- After completion: Error message or extracted recipe appears

## What's Hidden During Loading

✓ Source selection buttons (Camera, Library, URL)  
✓ URL input field  
✓ Preprocessing toggle  
✓ Image preview  

## What's Always Visible

✓ Navigation title ("Recipe Extractor")  
✓ Loading indicator (when `isLoading = true`)  
✓ Error messages (when extraction fails)  
✓ Extracted recipe (when extraction succeeds)

## Benefits

1. **Clear feedback** - User knows extraction is running
2. **No confusion** - Can't tap buttons during extraction
3. **Focus on progress** - Loading indicator fills the view
4. **Professional UX** - Standard iOS pattern for long operations
5. **Prevents accidental taps** - Buttons hidden during processing

## Testing Scenarios

### Valid Recipe Image
1. Tap Library → Select image → Crop
2. ✅ See loading indicator (full screen)
3. ✅ Messages rotate during extraction
4. ✅ After 10-30s, recipe appears

### Invalid Recipe Image (User's Reported Issue)
1. Tap Library → Select non-recipe image → Crop
2. ✅ See loading indicator (full screen)
3. ✅ Messages show progress
4. ✅ After processing, error message appears: "This image doesn't contain a recipe"

### URL Extraction
1. Tap Web URL → Enter URL → Extract
2. ✅ URL input disappears
3. ✅ Loading indicator appears (full screen)
4. ✅ After 15-45s, recipe or error appears

## Related Files
- `RecipeExtractorView.swift` - Updated to hide UI during loading
- `ExtractionLoadingView.swift` - The loading indicator component (already created)
- `RecipeExtractorViewModel.swift` - Manages `isLoading` state (already updated)

## Conclusion

The fix ensures that when extraction is running, users see **only** the loading indicator, providing clear, unambiguous feedback that an operation is in progress. This solves the reported issue where users saw no indication that extraction was happening.
