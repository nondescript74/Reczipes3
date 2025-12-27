# URL Fixer Guide

## Overview

The enhanced `JSONLinkValidator` now includes comprehensive URL fixing capabilities that detect, fix, and verify all URLs in your JSON link files with detailed logging.

## What Gets Fixed

The URL fixer automatically detects and corrects:

1. **HTML Tags** - Removes `<br>`, `</div>`, and other HTML tags from URLs
2. **Whitespace** - Trims leading/trailing spaces, tabs, and newlines
3. **Invisible Characters** - Removes zero-width spaces and other invisible Unicode characters
4. **HTML Entities** - Decodes `&amp;`, `&#39;`, `&#x2F;`, etc.
5. **Common URL Issues** - Fixes spaces (converts to `%20`), double slashes in paths
6. **URL Validation** - Verifies scheme (http/https), host, and format

## How to Use

### Option 1: Quick Fix (Recommended)

Run the test suite to fix your `links_from_notes.json` file:

```swift
// In RunURLFixer.swift, run this test:
@Test("Fix links_from_notes.json")
func fixRealFile() throws {
    try FixLinksCommand.fixLinksFromNotes(saveToDocuments: true)
}
```

This will:
- Fix all URLs with detailed logging
- Verify each URL after fixing
- Save to your Documents directory as `links_from_notes_FIXED.json`

### Option 2: Complete Workflow (Best for Production)

For the most thorough cleaning:

```swift
@Test("Complete workflow: fix, clean, and deduplicate")
func completeWorkflow() throws {
    try FixLinksCommand.completeWorkflow(saveToDocuments: true)
}
```

This performs:
1. URL fixing with verification
2. Cleaning (trimming whitespace, removing empty entries)
3. Duplicate removal
4. Final validation

Output file: `links_FINAL.json` in Documents

### Option 3: Manual/Programmatic Use

Use the validator directly in your code:

```swift
// Fix URLs in a file
let report = try JSONLinkValidator.fixURLs(
    inputURL: inputFileURL,
    outputURL: outputFileURL,
    verify: true  // Verify each URL after fixing
)

// Print detailed report
print(report.summary)

// Check results
print("Fixed: \(report.fixedCount) URLs")
print("Total: \(report.totalLinks)")

// Access individual fix details
for result in report.fixResults where result.wasFixed {
    print(result.logEntry)
}
```

## Understanding the Output

### Fix Report Structure

```
============================================================
URL Fix Report
============================================================

Total links: 100
Fixed: 45
Already valid: 55

Detailed Results:

🔧 Link #3: Asian Meatballs Recipe
   Original: https://example.com/recipe<br></div>
   Fixed:    https://example.com/recipe
   Issues fixed:
     • Removed HTML tags
   ✅ Verification: URL is now valid

✅ Link #4: Pasta Recipe
   URL: https://example.com/pasta
   No fixes needed
```

### Verification Status Indicators

- ✅ **Valid** - URL is properly formed and passes all checks
- ❌ **Invalid** - URL failed verification (with reason)
- ⏭️ **Skipped** - Verification was not performed

### Common Issues Fixed

| Original URL | Fixed URL | Issue |
|-------------|-----------|-------|
| `https://example.com/recipe<br>` | `https://example.com/recipe` | HTML tags |
| `  https://example.com/recipe  ` | `https://example.com/recipe` | Whitespace |
| `https://example.com/recipe<br></div>` | `https://example.com/recipe` | Multiple tags |
| `https://example.com/recipe?q=Rock%20&amp;%20Roll` | `https://example.com/recipe?q=Rock%20&%20Roll` | HTML entities |
| `https://example.com/recipe with spaces` | `https://example.com/recipe%20with%20spaces` | Spaces |

## Testing Your Changes

### Run All URL Fixer Tests

```bash
# In Xcode, run the test suite:
# Test Navigator > URLFixerTests
```

Tests include:
- HTML tag removal
- Whitespace trimming
- HTML entity decoding
- Common URL fixes
- URL verification
- Complete file processing

### Validate Before Fixing

To see what issues exist without making changes:

```swift
@Test("Validate current file (no fixes)")
func validateOnly() throws {
    let result = JSONLinkValidator.validate(fileAt: url)
    print(result.summary)
}
```

### Compare Before/After

```swift
@Test("Show diff between original and fixed")
func showDiff() throws {
    // Shows detailed comparison of what changed
}
```

## API Reference

### Main Functions

#### `fixURLs(inputURL:outputURL:verify:)`

Fixes all URLs in a JSON file.

**Parameters:**
- `inputURL: URL` - Input JSON file
- `outputURL: URL` - Output JSON file (can be same as input)
- `verify: Bool` - Whether to verify each URL (default: true)

**Returns:** `FixReport` with detailed results

**Throws:** File I/O or JSON parsing errors

#### `clean(inputURL:outputURL:removeDuplicates:)`

Cleans and normalizes a JSON file (existing function, enhanced).

**Parameters:**
- `inputURL: URL` - Input JSON file
- `outputURL: URL` - Output JSON file
- `removeDuplicates: Bool` - Remove duplicate URLs (default: true)

### Result Types

#### `FixReport`

```swift
struct FixReport {
    let totalLinks: Int
    let fixedCount: Int
    let unfixedCount: Int
    let fixResults: [URLFixResult]
    
    var summary: String  // Formatted report
}
```

#### `URLFixResult`

```swift
struct URLFixResult {
    let linkNumber: Int
    let title: String
    let originalURL: String
    let fixedURL: String
    let wasFixed: Bool
    let issues: [String]
    let verificationStatus: VerificationStatus
    
    var logEntry: String  // Formatted log entry
}
```

## Best Practices

1. **Always make a backup** - The tools create backups automatically, but keep your originals
2. **Run validation first** - See what issues exist before fixing
3. **Use verification** - Set `verify: true` to catch remaining issues
4. **Review the report** - Check the detailed log to understand what was changed
5. **Run complete workflow** - For production, use the complete workflow to fix + clean + deduplicate

## Troubleshooting

### Issue: "Could not find links_from_notes.json"

**Solution:** Make sure the file is in your app bundle or provide the full path.

### Issue: URLs still failing after fixing

**Solution:** Check the verification status in the report. Some URLs may have deeper issues (invalid domains, missing protocols, etc.).

### Issue: Want to fix in place (overwrite original)

**Solution:** Use `saveToDocuments: false` or set output URL same as input URL. A backup will be created automatically.

```swift
try FixLinksCommand.fixLinksFromNotes(saveToDocuments: false)
```

## Examples

### Example 1: Quick Command Line Style

```swift
// Run from anywhere in your app/tests
do {
    try FixLinksCommand.completeWorkflow(saveToDocuments: true)
} catch {
    print("Error: \(error)")
}
```

### Example 2: Custom File Processing

```swift
let inputURL = URL(fileURLWithPath: "/path/to/links.json")
let outputURL = URL(fileURLWithPath: "/path/to/links_fixed.json")

let report = try JSONLinkValidator.fixURLs(
    inputURL: inputURL,
    outputURL: outputURL,
    verify: true
)

// Process results
for result in report.fixResults {
    if result.wasFixed {
        print("Fixed: \(result.title)")
        print("  \(result.originalURL) -> \(result.fixedURL)")
    }
}
```

### Example 3: Integration with Import Pipeline

```swift
// Before importing links, fix them first
let tempURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("links_fixed.json")

let report = try JSONLinkValidator.fixURLs(
    inputURL: userSelectedFile,
    outputURL: tempURL,
    verify: true
)

// Only proceed if valid
if report.fixResults.allSatisfy({ $0.verificationStatus == .valid }) {
    // Import the fixed links
    try importLinks(from: tempURL)
} else {
    // Show errors to user
    showValidationErrors(from: report)
}
```

## Next Steps

1. Run `RunURLFixer` tests to fix your `links_from_notes.json`
2. Review the detailed log output
3. Check the fixed file in your Documents directory
4. Import the clean, validated links into your app

---

Last updated: December 27, 2025
