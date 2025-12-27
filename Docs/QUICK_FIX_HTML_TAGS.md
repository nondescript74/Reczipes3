# Quick Fix Guide: HTML Tags in Recipe URLs

> **Note:** This file should be located at `docs/QUICK_FIX_HTML_TAGS.md`

## The Problem

Your `links_from_notes.json` file has URLs with HTML tags:
```
https://www.seriouseats.com/.../recipe.html<br></div>
```

This causes "Page Not Found" errors when extracting recipes.

## Quick Solution (Choose One)

### Option A: Use Auto-Clean on Import (Recommended)

When importing your links, enable the `autoClean` option:

```swift
try await LinkImportService.importLinksFromBundle(
    filename: "links_from_notes.json",
    into: modelContext,
    validate: true,
    autoClean: true  // ✅ This will clean HTML tags automatically
)
```

The app will automatically remove HTML tags from all URLs during import.

### Option B: Pre-Clean Your JSON File

Run this code once to create a cleaned version of your file:

```swift
// 1. Get the input file
guard let inputURL = Bundle.main.url(
    forResource: "links_from_notes",
    withExtension: "json"
) else { return }

// 2. Create output path
let documentsPath = FileManager.default.urls(
    for: .documentDirectory, 
    in: .userDomainMask
)[0]
let outputURL = documentsPath.appendingPathComponent("links_cleaned.json")

// 3. Clean the file
try JSONLinkValidator.clean(
    inputURL: inputURL,
    outputURL: outputURL,
    removeDuplicates: true
)

print("✅ Cleaned file saved to: \(outputURL.path)")
```

Then replace your original file with the cleaned version.

### Option C: Manual Find & Replace

Open `links_from_notes.json` in a text editor:

1. Find: `<br></div>"`
2. Replace with: `"`
3. Save the file

Repeat for other HTML tag patterns like `</div>"`, `<br>"`, etc.

## Verify the Fix

After cleaning, try extracting these recipes:
- "Crispy Fried Tofu and Broccoli"
- "Stir fried flank steak and mushrooms"  
- "Braised Asian Meatballs and Cabbage"

They should now extract successfully!

## Automatic Protection

Even without cleaning your data, the app now automatically:
- ✅ Detects HTML tags during validation
- ✅ Removes HTML tags during import (if autoClean enabled)
- ✅ Cleans URLs at runtime before fetching web pages

So your app won't crash, but cleaning the data is more efficient.

## See Also

- `docs/HTML_TAG_URL_FIX.md` - Detailed technical documentation
- `JSONLinkValidator.swift` - Validation and cleaning code
- `WebRecipeExtractor.swift` - Runtime URL cleaning
