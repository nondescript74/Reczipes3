# Quick Start: Fix Your URLs in 3 Steps

## 🎯 What You Need to Do

Your `links_from_notes.json` file has URLs with HTML tags and other issues. This guide will help you fix them all automatically.

## ✅ Three Ways to Fix Your URLs

### Method 1: Run a Test (Easiest)

1. Open Xcode
2. Go to the Test Navigator (⌘6)
3. Find `RunURLFixer` → `Fix links_from_notes.json`
4. Click the ▶️ button next to it
5. Check the console for detailed logs
6. Find your fixed file in `~/Documents/links_from_notes_FIXED.json`

**OR for the complete workflow:**

Run: `RunURLFixer` → `Complete workflow: fix, clean, and deduplicate`

This gives you a perfectly cleaned file at `~/Documents/links_FINAL.json`

### Method 2: Code Snippet

Add this anywhere in your app or tests and run it:

```swift
import Foundation

// Quick fix
do {
    try FixLinksCommand.fixLinksFromNotes(saveToDocuments: true)
    print("✅ Done! Check your Documents folder")
} catch {
    print("❌ Error: \(error)")
}
```

### Method 3: Complete Workflow (Recommended)

```swift
do {
    try FixLinksCommand.completeWorkflow(saveToDocuments: true)
} catch {
    print("Error: \(error)")
}
```

## 📊 What Will Happen

The fixer will:

1. **Scan** every URL in your file
2. **Fix** these issues:
   - Remove HTML tags (`<br>`, `</div>`, etc.)
   - Trim whitespace
   - Remove invisible characters
   - Decode HTML entities (`&amp;` → `&`)
   - Fix spaces and other common issues
3. **Verify** each URL to ensure it's valid
4. **Log** every change with details
5. **Save** the fixed file

## 📋 Example Output

You'll see detailed logs like this:

```
============================================================
URL Fix Report
============================================================

Total links: 87
Fixed: 23
Already valid: 64

Detailed Results:

🔧 Link #5: Crispy Tofu and Broccoli
   Original: https://www.seriouseats.com/recipes/tofu.html<br></div>
   Fixed:    https://www.seriouseats.com/recipes/tofu.html
   Issues fixed:
     • Removed HTML tags
   ✅ Verification: URL is now valid

✅ Link #6: Pasta Carbonara
   URL: https://www.example.com/pasta
   No fixes needed

🔧 Link #12: Asian Meatballs
   Original: https://www.100daysofrealfood.com/meatballs/</div>
   Fixed:    https://www.100daysofrealfood.com/meatballs/
   Issues fixed:
     • Removed HTML tags
   ✅ Verification: URL is now valid
```

## 🔍 Before Running: Check What Needs Fixing

Want to see the problems first? Run:

```swift
// In RunURLFixer tests:
@Test("Validate current file (no fixes)")
func validateOnly() throws { ... }
```

Or in code:

```swift
if let url = Bundle.main.url(forResource: "links_from_notes", withExtension: "json") {
    let result = JSONLinkValidator.validate(fileAt: url)
    print(result.summary)
}
```

## 📁 File Locations

### Input
- `links_from_notes.json` in your app bundle

### Output Options

**Quick fix:**
- `~/Documents/links_from_notes_FIXED.json`

**Complete workflow:**
- `~/Documents/links_FINAL.json`

**Backup (auto-created):**
- `links_from_notes.backup.json` (when overwriting)

## ⚡ Quick Command Reference

All in one place:

```swift
// 1. Validate (no changes)
let result = JSONLinkValidator.validate(fileAt: url)
print(result.summary)

// 2. Fix URLs only
let report = try JSONLinkValidator.fixURLs(
    inputURL: inputURL,
    outputURL: outputURL,
    verify: true
)
print(report.summary)

// 3. Clean (trim, remove duplicates)
try JSONLinkValidator.clean(
    inputURL: inputURL,
    outputURL: outputURL,
    removeDuplicates: true
)

// 4. Complete workflow (fix + clean)
try FixLinksCommand.completeWorkflow(saveToDocuments: true)
```

## 🐛 Common Issues

**"Could not find links_from_notes.json"**
- Make sure the file is in your Xcode project
- Check it's added to your app bundle target

**"Some URLs still failing"**
- Check the verification status in the log
- Some URLs might have invalid domains or missing protocols
- Review the specific error messages

**"Want to overwrite the original file"**
```swift
try FixLinksCommand.fixLinksFromNotes(saveToDocuments: false)
// A backup will be created automatically
```

## 🎉 After Fixing

Once your URLs are fixed:

1. ✅ Check the console logs
2. ✅ Review the fixed file
3. ✅ Import your clean links
4. ✅ Delete the temp files if you want

## 📚 Need More Details?

See `URL_FIXER_GUIDE.md` for complete documentation.

---

**Ready? Run the test now! ▶️**

Test Navigator (⌘6) → RunURLFixer → Fix links_from_notes.json
