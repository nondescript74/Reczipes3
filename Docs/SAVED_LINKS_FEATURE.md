# Saved Recipe Links Feature

## Overview

This feature allows you to import, manage, and extract recipes from a collection of saved web links stored in a JSON file. It integrates seamlessly with your existing recipe extraction system powered by Claude AI.

## Components Created

### 1. **SavedLink.swift**
SwiftData model that represents a saved recipe link with:
- `id`: Unique identifier
- `title`: Display name for the link
- `url`: The web address of the recipe
- `dateAdded`: When the link was imported
- `isProcessed`: Whether recipe extraction has been attempted
- `extractedRecipeID`: ID of the successfully extracted recipe (if any)
- `processingError`: Error message if extraction failed

### 2. **LinkImportService.swift**
Service class for importing links from JSON:
- `importLinksFromBundle()`: Import from a JSON file in your app bundle
- `importLinks(from:into:)`: Import from any URL or Data
- Automatic duplicate detection and filtering
- Batch import with progress tracking

### 3. **SavedLinksView.swift**
Main management interface for saved links featuring:
- **Statistics Bar**: Shows total, unprocessed, extracted, and failed links
- **Filtering**: View all links, only unprocessed, only extracted, or only failed
- **Search**: Find links by title or URL
- **Swipe Actions**: Quick access to extract or delete
- **Import Sheet**: Easy JSON file import
- **Batch Operations**: Extract all unprocessed links at once

### 4. **LinkExtractionView.swift**
Dedicated extraction view that:
- Uses your existing `RecipeExtractorViewModel` for consistency
- Automatically starts extraction when opened
- Shows progress and error states
- Allows image selection from web page
- Downloads and saves recipe images
- Marks links as processed and links them to extracted recipes
- Sets the original URL as the recipe's reference

## JSON File Format

Your `links_from_notes.json` file should be in this format:

```json
[
  {
    "title": "Recipe Name",
    "url": "https://example.com/recipe-url"
  },
  {
    "title": "Another Recipe",
    "url": "https://example.com/another-recipe"
  }
]
```

## How to Use

### Step 1: Add Your JSON File to Xcode

1. Locate your `links_from_notes.json` file
2. Drag it into your Xcode project
3. Make sure "Copy items if needed" is checked
4. Ensure it's added to your app target

### Step 2: Import Links

1. Open your app and tap on "Recipes" tab
2. Tap the menu button (ellipsis icon) in the toolbar
3. Select "Saved Links"
4. Tap the menu button (ellipsis) in the top right
5. Select "Import from JSON"
6. Tap "Import Links"

The app will:
- Read the JSON file from your app bundle
- Filter out any duplicate URLs (if you've imported before)
- Add new links to the database
- Show you how many links were imported

### Step 3: Extract Recipes

There are several ways to extract recipes from your saved links:

#### Option A: Extract Individual Links
1. In the Saved Links view, tap on any link
2. The extraction will start automatically
3. Once complete, you can:
   - Select images to save with the recipe
   - Preview the extracted recipe
   - Save it to your collection

#### Option B: Swipe to Extract
1. In the Saved Links list, swipe left on any unprocessed link
2. Tap the "Extract" button
3. Follow the same process as Option A

#### Option C: Batch Extract (Coming Soon)
1. Tap the menu button (ellipsis)
2. Select "Extract All Unprocessed"
3. The app will process all links sequentially

### Step 4: Monitor Progress

The Saved Links view shows:
- **Statistics at the top**: Quick overview of your link collection
- **Status badges**: Each link shows its current state:
  - 🕐 "To Extract" - Not yet processed
  - ✅ "Extracted" - Successfully extracted and saved
  - ❌ "Failed" - Extraction failed (shows error message)
- **Filter tabs**: Switch between different views of your links

### Step 5: Manage Links

You can:
- **Search**: Use the search bar to find specific links
- **Delete**: Swipe right on any link to delete it
- **Open in Browser**: Long-press a link and select "Open in Browser"
- **Copy URL**: Long-press and select "Copy URL"
- **Clear All**: Delete all links at once (from the menu)

## Integration with Existing Features

### Recipe Extraction
- Uses your existing `RecipeExtractorViewModel` for consistent extraction
- Supports your current web scraping and Claude AI analysis
- Automatically extracts images from web pages
- Saves recipes with all metadata (ingredients, instructions, notes)

### Recipe Storage
- Extracted recipes appear in your main recipe collection
- Each recipe's `reference` field is set to the original URL
- Images are downloaded and stored locally
- Full SwiftData integration for persistence

### Recipe Images
- Automatically finds images from the web page
- Allows you to select which images to save
- First selected image becomes the main thumbnail
- Additional images are saved as supplementary images
- Creates `RecipeImageAssignment` entries for compatibility

## Database Schema

The `SavedLink` model is added to your SwiftData schema in `Reczipes2App.swift`:

```swift
let schema = Schema([
    Recipe.self,
    RecipeImageAssignment.self,
    UserAllergenProfile.self,
    CachedDiabeticAnalysis.self,
    SavedLink.self,  // ← New model
])
```

## Error Handling

The system handles various errors gracefully:
- **Network errors**: Can't connect to the website
- **Parsing errors**: Website doesn't contain recipe data
- **Invalid URLs**: Malformed or unreachable links
- **Duplicate imports**: Skips links you've already imported

Errors are:
- Displayed inline in the link list
- Saved to the database for reference
- Allow retry without losing your place

## Tips

1. **Start Small**: Import a few links first to test the system
2. **Check Errors**: Some websites may block automated access
3. **Review Before Saving**: Always preview the extracted recipe before saving
4. **Select Good Images**: Choose high-quality recipe images for best results
5. **Use Filters**: Filter by status to focus on unprocessed links
6. **Search Effectively**: Use the search to quickly find specific recipes

## Troubleshooting

### Import Fails
- Ensure `links_from_notes.json` is in your app bundle
- Check that the JSON format matches the expected structure
- Verify the file is not corrupted

### Extraction Fails
- Check your internet connection
- Verify your Claude API key is configured
- Some websites may block automated access
- Try opening the URL in a browser to confirm it works

### No Images Extracted
- The website may not have suitable images
- Try extracting from the original recipe source
- You can always add images manually later

### Duplicate Links
- The system automatically skips duplicate URLs
- If you need to re-extract, delete the link first, then re-import

## Future Enhancements

Potential improvements for this feature:
- Batch extraction with progress bar
- Export links to share with others
- Schedule automatic imports
- Integration with Safari extension
- Cloud sync for links across devices
- Categorize links by tags or folders
- Priority queue for extraction

## Summary

This feature transforms your static JSON file of recipe links into a dynamic, managed collection that integrates seamlessly with your app's recipe extraction workflow. It saves time, tracks progress, and ensures you never lose track of recipes you want to try.
