# Quick Setup Guide: Saved Recipe Links

## What Was Created

I've created a complete system for importing and managing recipe links from your `links_from_notes.json` file. Here's what you now have:

### New Files
1. **SavedLink.swift** - SwiftData model for storing links
2. **LinkImportService.swift** - Handles JSON import with duplicate detection
3. **SavedLinksView.swift** - Main UI for managing links
4. **LinkExtractionView.swift** - UI for extracting recipes from links
5. **SAVED_LINKS_FEATURE.md** - Complete documentation

### Modified Files
1. **Reczipes2App.swift** - Added `SavedLink` to the database schema
2. **ContentView.swift** - Added "Saved Links" menu item

## To Make It Work

### Step 1: Add Your JSON File
Move your `links_from_notes.json` file into your Xcode project:
1. Drag the file into your project navigator
2. Check "Copy items if needed"
3. Check your app target in "Add to targets"

### Step 2: Build and Run
That's it! The code is ready to use. When you run the app:
1. Go to the Recipes tab
2. Tap the "More" menu (ellipsis icon)
3. Select "Saved Links"
4. Tap "Import from JSON"

## How It Works

```
┌─────────────────────┐
│  JSON File          │
│  links_from_notes   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Import Service     │
│  • Parse JSON       │
│  • Filter dupes     │
│  • Save to DB       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  SavedLinksView     │
│  • Display list     │
│  • Filter/Search    │
│  • Track status     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ LinkExtractionView  │
│ • Call Claude API   │
│ • Extract recipe    │
│ • Download images   │
│ • Save to DB        │
└─────────────────────┘
```

## Key Features

### Smart Import
- Automatically skips duplicate URLs
- Shows count of new vs. existing links
- Preserves your existing data

### Status Tracking
Each link can be:
- **To Extract** (orange clock) - Not yet processed
- **Extracted** (green checkmark) - Successfully saved as recipe
- **Failed** (red X) - Error during extraction (shows error message)

### Extraction Integration
Uses your existing recipe extraction system:
- Same Claude API calls
- Same image handling
- Same recipe storage
- Sets original URL as recipe reference

### Filtering & Search
- Filter by status (All/To Extract/Extracted/Failed)
- Search by title or URL
- Statistics bar shows counts

## Example Workflow

```swift
// User opens Saved Links
// Taps "Import from JSON"
LinkImportService.importLinksFromBundle(
    filename: "links_from_notes.json",
    into: modelContext
)
// Result: 150 new links imported

// User taps a link
// LinkExtractionView opens automatically
// Calls your existing RecipeExtractorViewModel
await viewModel.extractRecipe(from: link.url)

// User selects images
// Taps "Save to Collection"
// Recipe saved with:
// - All ingredients & instructions
// - Downloaded images
// - Reference = original URL
// - Link marked as "Extracted"
```

## Code Integration Points

### 1. Uses Your Existing ViewModel
```swift
@StateObject private var viewModel: RecipeExtractorViewModel

// Same extraction logic you already use
await viewModel.extractRecipe(from: link.url)
```

### 2. Uses Your Image System
```swift
// Same image downloader
private let imageDownloader = WebImageDownloader()

// Same image saving
saveImageToDisk(image, filename: filename)
```

### 3. Uses Your Recipe Storage
```swift
// Same Recipe model conversion
let recipe = Recipe(from: recipeModel)
recipe.reference = link.url  // Link back to source

// Same context saving
modelContext.insert(recipe)
try modelContext.save()
```

## Customization Options

### Change JSON File Name
In `SavedLinksView.swift`, line in `ImportLinksSheet`:
```swift
// Change this:
filename: "links_from_notes.json"

// To whatever your file is called:
filename: "my_recipe_links.json"
```

### Add Custom Fields
In `SavedLink.swift`, add new properties:
```swift
@Model
final class SavedLink {
    // ... existing properties ...
    var category: String?  // Add categories
    var priority: Int?     // Add priority
    var tags: [String]?    // Add tags
}
```

### Customize Filters
In `SavedLinksView.swift`, add to `FilterOption`:
```swift
enum FilterOption: String, CaseIterable {
    case all = "All"
    case unprocessed = "To Extract"
    case processed = "Extracted"
    case failed = "Failed"
    case favorites = "Favorites"  // Add new filter
}
```

## Testing It Out

1. **Import a few links** - Start with 5-10 to test
2. **Extract one link** - Verify it works end-to-end
3. **Check the recipe** - Confirm it appears in your collection
4. **Try a failed extraction** - See how errors are handled
5. **Import again** - Verify duplicates are skipped

## Troubleshooting

### "File not found" error
- Your JSON file isn't in the app bundle
- Re-add it to Xcode with "Copy items if needed" checked

### Extraction fails
- Check your Claude API key is configured
- Verify the URL is accessible
- Some sites block automated access

### Duplicate imports
- This is normal and safe - duplicates are automatically skipped
- The system checks URLs, not titles

### Images don't download
- Some websites block image downloads
- You can always add images manually later

## What's Next?

Try these enhancements:
1. **Add batch extraction** - Process multiple links at once
2. **Add categories** - Organize links by meal type
3. **Add notes** - Save comments about each link
4. **Export feature** - Share your link collection
5. **Safari extension** - Add links from Safari

## Questions?

The code is heavily commented and follows your existing patterns:
- Same SwiftData usage
- Same view structure
- Same naming conventions
- Same error handling approach

Everything integrates cleanly with your current codebase!
