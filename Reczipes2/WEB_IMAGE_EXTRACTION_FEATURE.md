# Web Recipe Image Extraction Feature

## Overview
This feature enables automatic extraction and selection of images from recipe websites during web-based recipe extraction. When a user extracts a recipe from a URL, the app now:

1. Extracts image URLs from the webpage
2. Allows the user to preview and select from multiple images
3. Downloads the selected image asynchronously
4. Saves it with the recipe

## Implementation Details

### Files Modified

#### 1. **RecipeModel.swift**
- Added `imageURLs: [String]?` property to store URLs of images found during web extraction
- This allows the model to carry image URL data from extraction through to the save flow

#### 2. **WebRecipeExtractor.swift**
- Added `extractImageURLs(from html: String) -> [String]` method
- Extraction priority:
  1. **JSON-LD structured data** (schema.org Recipe format) - Most reliable
  2. **Open Graph `og:image` meta tags** - Common fallback
  3. **`<img>` tags** (filtered and limited to first 10) - Last resort
- Filters out icons, logos, tracking pixels, and SVG files
- Handles relative URLs and validates image URLs

#### 3. **RecipeExtractorViewModel.swift**
- Updated `extractRecipe(from url: String)` to call `extractImageURLs()` before cleaning HTML
- Populates the `imageURLs` field in the extracted `RecipeModel`
- Image URLs are extracted early to preserve all HTML before cleaning

#### 4. **RecipeExtractorView.swift**
- Added new state variables:
  - `showWebImagePicker: Bool` - Controls image picker sheet
  - `selectedWebImageURL: String?` - Stores user's selected image URL
  - `downloadedWebImage: UIImage?` - Caches downloaded image
  - `isDownloadingImage: Bool` - Shows loading state during download
- Added `imageDownloader: WebImageDownloader` - Actor for async image downloads
- Updated `extractedRecipeSection()` to show:
  - Image selection button when URLs are available
  - Preview of selected image
  - Download progress indicator
- Added `downloadAndSaveRecipe(imageURL:)` function to handle async image download
- Modified `saveRecipe()` to prioritize downloaded web image over extracted image

### Files Created

#### 5. **WebImagePickerView.swift** (NEW)
A SwiftUI view that presents a grid of available recipe images:
- Uses `AsyncImage` for efficient loading with placeholders
- 2-column grid layout
- Visual selection indicator with checkmark overlay
- "Skip" option to save without an image
- "Done" button to confirm selection

**Key Features:**
- Lazy loading of images
- Error handling for failed loads
- Selected state visualization
- Clean, user-friendly interface

#### 6. **WebImageDownloader.swift** (NEW)
An actor that handles asynchronous image downloads:
- Thread-safe image downloading
- Proper error handling with custom `ImageDownloadError` enum
- User-agent header to avoid website blocking
- Validates HTTP responses and image data
- Comprehensive logging for debugging

**Error Cases:**
- Invalid URL
- Network errors
- HTTP errors (403, 404, etc.)
- Invalid image data

## User Flow

### Web Recipe Extraction with Images

1. **User enters recipe URL and taps "Extract Recipe from URL"**
   - App fetches webpage HTML
   - Extracts image URLs from JSON-LD, og:image, and img tags
   - Sends cleaned HTML to Claude for recipe extraction

2. **Recipe extracted successfully**
   - If image URLs found: Shows "Select Recipe Image (X available)" button
   - User can tap to open image picker sheet
   - Or skip and save without an image

3. **User selects an image (optional)**
   - Opens `WebImagePickerView` with grid of available images
   - Images load asynchronously with placeholders
   - User taps to select their preferred image
   - Can "Skip" or "Done" to confirm

4. **User taps "Save to Collection"**
   - If image selected: Downloads image in background
   - Shows "Downloading Image..." progress indicator
   - Once downloaded, saves recipe with image to SwiftData
   - Falls back to saving without image if download fails

5. **Success confirmation**
   - Shows alert confirming recipe and image saved
   - Options to view in collection or extract another

## Technical Highlights

### Image URL Extraction Strategy

The `extractImageURLs()` method uses a multi-tier approach:

```swift
// Priority 1: JSON-LD structured data (most reliable)
// Parses schema.org Recipe JSON for "image" field
// Handles: string, array, or object with "url" key

// Priority 2: Open Graph metadata
// Extracts og:image meta tags (widely used)

// Priority 3: HTML img tags
// Filters out icons, logos, tracking pixels
// Limits to first 10 to avoid thumbnail spam
```

### Async Image Downloading

Uses Swift's `actor` for thread-safe downloads:

```swift
actor WebImageDownloader {
    func downloadImage(from urlString: String) async throws -> UIImage
}
```

Benefits:
- Prevents blocking the main thread
- Safe concurrent access
- Clean error handling
- Automatic cancellation support

### State Management

The view maintains clean state separation:
- `selectedWebImageURL` - User's choice from picker
- `downloadedWebImage` - Cached result after download
- Resets properly when extracting another recipe

## Testing Considerations

### Test Cases

1. **Recipe with JSON-LD images**
   - Example: Serious Eats, AllRecipes
   - Should extract primary recipe image

2. **Recipe with og:image only**
   - Example: Some blogs
   - Should fall back to Open Graph image

3. **Recipe with multiple images**
   - Should show image picker with grid
   - User can select preferred image

4. **Recipe with no images**
   - Should not show image picker button
   - Save button works normally

5. **Image download failures**
   - Network errors
   - 403 forbidden
   - 404 not found
   - Should still save recipe without image

6. **User skips image selection**
   - Should save recipe without image
   - No errors or crashes

### Edge Cases Handled

- Relative image URLs (needs base URL resolution - TODO)
- Data URLs (filtered out)
- SVG files (filtered out)
- Tracking pixels and 1x1 images (filtered out)
- Very large HTML pages (truncated before sending to Claude)
- Image download timeouts (30 second limit)

## Future Enhancements

### Potential Improvements

1. **Relative URL Resolution**
   - Currently relative URLs may not work
   - Need to resolve against base URL from original recipe page

2. **Image Size Validation**
   - Download and check dimensions before presenting
   - Filter out very small images (< 200x200)

3. **Image Caching**
   - Cache downloaded images during selection
   - Avoid re-downloading when user changes selection

4. **Multiple Image Support**
   - Allow saving multiple images per recipe
   - Create a photo gallery for recipes

5. **Smart Image Selection**
   - Use ML to identify food images
   - Auto-select highest quality image

6. **CDN Support**
   - Handle responsive image srcsets
   - Select appropriate resolution for device

## API Changes

### RecipeModel
```swift
struct RecipeModel {
    // ... existing fields
    var imageURLs: [String]?  // NEW
}
```

### WebRecipeExtractor
```swift
func extractImageURLs(from html: String) -> [String]  // NEW
```

### RecipeExtractorViewModel
```swift
// Updated to populate imageURLs
func extractRecipe(from url: String) async
```

## Dependencies

- **Foundation** - URL handling, JSON parsing
- **UIKit** - UIImage
- **SwiftUI** - AsyncImage, views
- **SwiftData** - Recipe persistence

## Performance Considerations

- Image extraction happens before HTML cleaning (preserves all data)
- Image downloads are async and don't block the UI
- Failed downloads don't prevent recipe saving
- AsyncImage provides automatic caching and memory management
- Limited to first 10 img tags to avoid processing overhead

## Security Considerations

- Validates all URLs before downloading
- Sets User-Agent to appear as mobile Safari
- 30-second timeout prevents hanging requests
- Only downloads from http/https schemes
- No execution of JavaScript or dynamic content

---

## Summary

This feature significantly enhances the web extraction experience by automatically finding and allowing users to select images from recipe websites. The implementation is robust, handles errors gracefully, and provides a smooth user experience with async image loading and downloading.

The multi-tier extraction strategy (JSON-LD → og:image → img tags) ensures compatibility with most recipe websites while filtering out unwanted images like icons and tracking pixels.
