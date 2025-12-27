# JSONLinkValidator - Tips Support Update

## Issue Fixed

**Error:** `Missing argument for parameter 'tips' in call`

**Location:** `JSONLinkValidator.swift` → `clean()` function

## Changes Made

### 1. Updated `clean()` Function

Fixed the JSONLink initialization to include the `tips` parameter:

**Before:**
```swift
JSONLink(
    title: link.title.trimmingCharacters(in: .whitespacesAndNewlines),
    url: link.url.trimmingCharacters(in: .whitespacesAndNewlines)
)
// ❌ Missing tips parameter
```

**After:**
```swift
// Clean tips by trimming whitespace and removing empty strings
let cleanedTips: [String]? = link.tips?.compactMap { tip in
    let trimmed = tip.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

JSONLink(
    title: link.title.trimmingCharacters(in: .whitespacesAndNewlines),
    url: link.url.trimmingCharacters(in: .whitespacesAndNewlines),
    tips: cleanedTips?.isEmpty == true ? nil : cleanedTips
)
// ✅ Tips included and cleaned
```

### 2. Added Tips Validation

Both `validate(fileAt:)` and `validate(data:)` functions now check tips:

```swift
// Validate tips if present
if let tips = link.tips, !tips.isEmpty {
    // Check for empty tip strings
    let emptyTips = tips.filter { $0.trimmingCharacters(in: .whitespaces).isEmpty }
    if !emptyTips.isEmpty {
        warnings.append("Link #\(linkNumber) (\(link.title)) has \(emptyTips.count) empty tip(s)")
    }
    
    // Check for very long tips (might be accidentally pasted data)
    let longTips = tips.filter { $0.count > 500 }
    if !longTips.isEmpty {
        warnings.append("Link #\(linkNumber) (\(link.title)) has \(longTips.count) very long tip(s)")
    }
}
```

### 3. Updated Error Messages

Changed JSON format expectation messages:
- **Before:** `"Expected array of {title, url} objects"`
- **After:** `"Expected array of {title, url, tips?} objects"`

## New Validation Rules for Tips

### ✅ Valid
- Missing `tips` field (tips are optional)
- `tips: null`
- `tips: []` (empty array)
- `tips: ["Tip 1", "Tip 2"]` (valid tips)

### ⚠️ Warnings
- Empty tip strings: `tips: ["", "Valid tip"]`
- Very long tips (>500 chars): Tips that might be accidental data pastes

### Cleaning Behavior

The `clean()` function now:
1. **Trims whitespace** from each tip
2. **Removes empty tips** after trimming
3. **Sets tips to nil** if all tips are empty after cleaning
4. **Preserves tips** in the cleaned output

## Example Cleaning

**Input:**
```json
{
  "tips": [
    "  Good recipe  ",
    "",
    "Add more salt",
    "   ",
    "Will make again"
  ],
  "title": "Test Recipe",
  "url": "https://example.com"
}
```

**After Cleaning:**
```json
{
  "tips": [
    "Good recipe",
    "Add more salt",
    "Will make again"
  ],
  "title": "Test Recipe",
  "url": "https://example.com"
}
```

## Integration

The validator now properly handles:
1. ✅ **Import** - JSON files with tips field
2. ✅ **Validation** - Checks tip quality and length
3. ✅ **Cleaning** - Normalizes and removes bad tips
4. ✅ **Export** - Preserves cleaned tips in output

## Testing

To test the fix:

1. **Validate a file with tips:**
   ```swift
   let result = JSONLinkValidator.validate(fileAt: url)
   print(result.summary)
   ```

2. **Clean a file with tips:**
   ```swift
   try JSONLinkValidator.clean(
       inputURL: inputURL,
       outputURL: outputURL,
       removeDuplicates: true
   )
   ```

Both should now work without errors and properly handle the tips field!

## Summary

✅ **Fixed:** Missing tips parameter in JSONLink initialization  
✅ **Added:** Tips validation (empty tips, long tips)  
✅ **Improved:** Cleaning function now normalizes tips  
✅ **Updated:** Error messages to reflect tips field  

The JSONLinkValidator now fully supports the tips field introduced in the tips integration update.
