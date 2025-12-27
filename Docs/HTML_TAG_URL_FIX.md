# HTML Tags in URLs - Fix Documentation

## Problem Description

Some URLs in the `links_from_notes.json` file contain HTML tags (e.g., `<br></div>`) at the end:

```json
"url" : "https://www.seriouseats.com/recipes/2014/02/vegan-experience-crispy-tofu-broccoli-stir-fry.html<br></div>"
```

This causes the recipe extraction to fail with a "Page Not Found" error because the URL is invalid.

## Root Cause

When links were originally extracted from your notes, HTML formatting tags were accidentally included in the URL strings. This happened during the initial data extraction process.

## Solution

We've implemented a multi-layered fix to handle this issue:

### 1. JSON Validation Enhancement

The `JSONLinkValidator` now detects HTML tags in URLs during validation:

```swift
// Check for HTML tags in URL
if link.url.contains("<") || link.url.contains(">") {
    errors.append("Link #\(linkNumber) (\(link.title)) contains HTML tags in URL")
}
```

This will flag any URLs with HTML tags as errors during import validation.

### 2. JSON Cleaning Enhancement

The `JSONLinkValidator.clean()` function now automatically removes HTML tags from URLs:

```swift
// Clean URL by removing HTML tags and trimming
let cleanedURL = cleanHTML(from: link.url).trimmingCharacters(in: .whitespacesAndNewlines)
```

This ensures that when you clean your JSON file, all HTML tags are stripped from URLs.

### 3. Runtime URL Cleaning

The `WebRecipeExtractor` now cleans HTML tags from URLs before attempting to fetch them:

```swift
// Clean HTML tags from URL string (defense-in-depth)
let cleanedURLString = cleanHTMLTags(from: urlString)
```

This provides protection even if corrupted URLs somehow make it into the database.

## How to Fix Your Existing Data

### Option 1: Clean the JSON File

1. Use the validation tool to see all issues:
   ```swift
   let result = JSONLinkValidator.validate(fileAt: url)
   print(result.summary)
   ```

2. Clean the file to remove HTML tags:
   ```swift
   try JSONLinkValidator.clean(
       inputURL: inputFileURL,
       outputURL: cleanedFileURL,
       removeDuplicates: true
   )
   ```

3. Replace your `links_from_notes.json` with the cleaned version

4. Re-import the links into your app

### Option 2: Fix Individual URLs Manually

You can manually edit the `links_from_notes.json` file and remove the HTML tags:

**Before:**
```json
"url" : "https://www.seriouseats.com/recipes/2014/02/vegan-experience-crispy-tofu-broccoli-stir-fry.html<br></div>"
```

**After:**
```json
"url" : "https://www.seriouseats.com/recipes/2014/02/vegan-experience-crispy-tofu-broccoli-stir-fry.html"
```

### Option 3: Let the App Handle It

With the new runtime cleaning in `WebRecipeExtractor`, the app will automatically clean HTML tags from URLs when attempting to extract recipes. However, this is less efficient than cleaning the source data.

## Prevention

To prevent this issue in the future:

1. **Always validate** JSON files before importing:
   ```swift
   let result = JSONLinkValidator.validate(fileAt: url)
   if !result.isValid {
       print("❌ File has errors:")
       result.errors.forEach { print("  • \($0)") }
   }
   ```

2. **Use the auto-clean option** when importing:
   ```swift
   try await LinkImportService.importLinksFromBundle(
       filename: "links_from_notes.json",
       into: modelContext,
       validate: true,
       autoClean: true  // ✅ Automatically cleans data before import
   )
   ```

3. **Check data sources** - If you're extracting links from notes or other sources, ensure the extraction process properly handles HTML content.

## Testing the Fix

To verify the fix works:

1. Try extracting one of the problematic recipes:
   - "Crispy Fried Tofu and Broccoli"
   - "Stir fried flank steak and mushrooms"
   - "Braised Asian Meatballs and Cabbage"

2. Check the console logs - you should see:
   ```
   🌐 ⚠️ Removed HTML tags from URL
   🌐 Cleaned URL: https://www.seriouseats.com/...
   ```

3. The extraction should now succeed

## Files Modified

- `JSONLinkValidator.swift` - Added HTML tag detection and cleaning
- `WebRecipeExtractor.swift` - Added runtime URL cleaning
- `LinkImportService.swift` - Already supported auto-clean option

## API Changes

### JSONLinkValidator

New capabilities:
- Detects HTML tags in URLs during validation
- Removes HTML tags during cleaning

### WebRecipeExtractor

New behavior:
- Automatically cleans HTML tags from URLs before fetching
- Logs when HTML tags are detected and removed

### LinkImportService

No API changes, but the existing `autoClean` parameter now cleans HTML tags:
```swift
try await LinkImportService.importLinksFromBundle(
    filename: "links_from_notes.json",
    into: modelContext,
    validate: true,
    autoClean: true  // Now removes HTML tags from URLs
)
```

## Example: Cleaning Your File

Here's a complete example of how to clean your existing JSON file:

```swift
import Foundation

// 1. Locate your JSON file
guard let inputURL = Bundle.main.url(
    forResource: "links_from_notes",
    withExtension: "json"
) else {
    fatalError("Could not find links_from_notes.json")
}

// 2. Validate to see issues
let validationResult = JSONLinkValidator.validate(fileAt: inputURL)
print(validationResult.summary)

// 3. Clean the file
let documentsPath = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0]
let outputURL = documentsPath.appendingPathComponent("links_cleaned.json")

try JSONLinkValidator.clean(
    inputURL: inputURL,
    outputURL: outputURL,
    removeDuplicates: true
)

print("✅ Cleaned file saved to: \(outputURL.path)")

// 4. Review the cleaned file and replace the original if satisfied
```

## Affected URLs in Your Data

Based on your JSON file, these URLs have HTML tags and will be cleaned:

1. "Crispy Fried Tofu and Broccoli" - has `<br></div>`
2. "Stir fried flank steak and mushrooms" - has `<br></div>`
3. "Braised Asian Meatballs and Cabbage" - has `</div>`
4. Many other entries have similar issues

Run the validation tool to get a complete list.

## Questions?

If you encounter any issues with the fix:

1. Check the console logs for cleaning messages
2. Verify the cleaned URLs are valid
3. Test with a single problematic recipe first
4. Use the validation tool to identify remaining issues

The fix is comprehensive and handles HTML tags at multiple levels, so your recipe extraction should now work correctly!
