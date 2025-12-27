# Manual Testing Guide: HTML Tags Fix

> **Location:** `docs/fixes/TESTING_HTML_TAG_FIX.md`

## Overview

This guide walks you through manually testing the HTML tag cleaning fix for recipe URLs.

## Prerequisites

- App is built and running
- You have the "Saved Links" feature visible in your app
- `links_from_notes.json` is imported (with or without cleaning)

## Test Cases

### Test 1: Validate Detection (Optional)

If you want to see what URLs have HTML tags before fixing:

1. In Xcode, add this to your app launch or a debug menu:
   ```swift
   if let url = Bundle.main.url(forResource: "links_from_notes", withExtension: "json") {
       let result = JSONLinkValidator.validate(fileAt: url)
       print(result.summary)
   }
   ```

2. Run the app and check the console

3. **Expected Output:**
   ```
   ❌ Invalid JSON file
   
   Errors:
     • Link #XY (...) contains HTML tags in URL: https://...html<br></div>
     • Link #XZ (...) contains HTML tags in URL: https://...</div>
   ```

### Test 2: Clean the JSON File (Recommended)

This creates a cleaned version of your JSON file:

1. Add this code to a debug button or view:
   ```swift
   Button("Clean Links JSON") {
       Task {
           do {
               guard let inputURL = Bundle.main.url(
                   forResource: "links_from_notes",
                   withExtension: "json"
               ) else { return }
               
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
           } catch {
               print("❌ Error: \(error)")
           }
       }
   }
   ```

2. Tap the button

3. **Expected Output:**
   ```
   ✅ Cleaned file saved to: /path/to/Documents/links_cleaned.json
   ```

4. Check the file - URLs should no longer have HTML tags

### Test 3: Auto-Clean on Import

Test automatic cleaning during import:

1. Make sure you have the dirty `links_from_notes.json` in your bundle

2. In your import code, enable `autoClean`:
   ```swift
   try await LinkImportService.importLinksFromBundle(
       filename: "links_from_notes.json",
       into: modelContext,
       validate: true,
       autoClean: true  // ✅ Enable this
   )
   ```

3. Trigger the import

4. **Expected:** URLs are cleaned automatically during import

### Test 4: Extract a Problematic Recipe

The main test - extract one of the recipes with dirty URLs:

1. In your app, navigate to "Saved Links"

2. Find one of these recipes:
   - "Crispy Fried Tofu and Broccoli"
   - "Stir fried flank steak and mushrooms"
   - "Braised Asian Meatballs and Cabbage"

3. Tap the recipe to start extraction

4. **Monitor Console Output:**
   ```
   🌐 ========== WEB CONTENT FETCH START ==========
   🌐 URL: https://www.seriouseats.com/.../recipe.html<br></div>
   🌐 ⚠️ Removed HTML tags from URL
   🌐 Cleaned URL: https://www.seriouseats.com/.../recipe.html
   🌐 Creating URL request...
   🌐 Fetching webpage...
   🌐 HTTP Status: 200
   🌐 ✅ Successfully fetched HTML content
   ```

5. **Expected Results:**
   - ✅ Console shows "Removed HTML tags from URL"
   - ✅ Console shows "HTTP Status: 200" (page found)
   - ✅ Recipe extraction succeeds
   - ✅ Recipe is displayed in the app

6. **If it fails:**
   - Check console for actual error
   - Verify the cleaned URL is correct
   - Check if the recipe page exists (try in Safari)

### Test 5: Extract Multiple Recipes

Test batch extraction with problematic URLs:

1. In "Saved Links", select multiple recipes including some with HTML tags

2. Tap "Extract Selected" (if you have batch extraction)

3. **Expected:**
   - All recipes extract successfully
   - Console shows cleaning messages for dirty URLs
   - No "Page Not Found" errors

## Success Criteria

✅ **Validation Test:** HTML tags are detected in URLs  
✅ **Cleaning Test:** Cleaned file has no HTML tags in URLs  
✅ **Auto-Clean Test:** Import succeeds with clean data  
✅ **Single Extraction:** Problematic recipe extracts successfully  
✅ **Batch Extraction:** Multiple recipes extract without errors  

## Troubleshooting

### "Invalid URL format" error

**Symptom:** Still getting invalid URL errors even with cleaning

**Solution:**
- Check if the URL has other issues (not just HTML tags)
- Verify the cleaned URL is valid by copying it to Safari
- Look for encoding issues (spaces, special characters)

### "Page Not Found" (404) error

**Symptom:** Cleaning works but page still not found

**Solution:**
- The URL might have changed or the page was removed
- Try the cleaned URL in Safari to verify it exists
- Check if the domain is blocking automated requests

### Cleaning doesn't seem to work

**Symptom:** HTML tags still present after cleaning

**Solution:**
- Verify you're using the cleaned file, not the original
- Check that `autoClean: true` is set in import code
- Look for console messages confirming cleaning occurred

### Recipe extracts but content is wrong

**Symptom:** Page loads but recipe data is incomplete

**Solution:**
- This is unrelated to the HTML tags fix
- The website might have changed its HTML structure
- Check Claude's extraction logic in the console logs

## Additional Verification

### Check Database

After importing with auto-clean, verify the database has clean URLs:

```swift
let descriptor = FetchDescriptor<SavedLink>()
let links = try modelContext.fetch(descriptor)

for link in links {
    if link.url.contains("<") || link.url.contains(">") {
        print("⚠️ Found dirty URL: \(link.url)")
    }
}

print("✅ Checked \(links.count) links in database")
```

### Test with New URLs

Add a test with a manually created dirty URL:

```swift
let testURL = "https://www.example.com/recipe.html<br></div>"
let extractor = WebRecipeExtractor()

Task {
    do {
        let content = try await extractor.fetchWebContent(from: testURL)
        print("✅ Successfully fetched despite dirty URL")
    } catch {
        print("❌ Error: \(error)")
    }
}
```

## Test Results Template

Copy this to document your test results:

```
HTML Tags Fix - Test Results
============================

Date: _______________
Tester: _______________

Test 1 - Validation Detection
[ ] Detected HTML tags in URLs
[ ] Listed specific problematic links
Notes: _______________

Test 2 - File Cleaning
[ ] Created cleaned JSON file
[ ] Verified URLs are clean
[ ] No HTML tags remain
Notes: _______________

Test 3 - Auto-Clean Import
[ ] Import succeeded
[ ] Database has clean URLs
Notes: _______________

Test 4 - Single Recipe Extraction
[ ] Console showed cleaning message
[ ] HTTP Status 200 received
[ ] Recipe extracted successfully
[ ] Recipe displays correctly
Recipe tested: _______________
Notes: _______________

Test 5 - Batch Extraction
[ ] Multiple recipes succeeded
[ ] No "Page Not Found" errors
Number of recipes: _______________
Notes: _______________

Overall Result: [ PASS / FAIL ]

Issues found:
_______________
_______________

```

## Next Steps

After successful testing:

1. ✅ Clean your production `links_from_notes.json` file
2. ✅ Replace the original with the cleaned version
3. ✅ Re-import links if needed
4. ✅ Document any remaining issues
5. ✅ Update user documentation if necessary

## Questions?

If you encounter issues during testing:
- Check console logs for detailed error messages
- Review the cleaned URLs manually
- Verify the fix code is in place (check git status)
- Test with a simpler URL first
