# Recipe Book Export/Import Feature Guide

## Overview

The Recipe Book feature now includes comprehensive export and import capabilities, allowing you to:
- **Export recipe books** as shareable `.recipebook` files
- **Include or exclude images** in exports
- **Share books** via AirDrop, Messages, Email, etc.
- **Import books** from other devices
- **Enhanced book editing** with cover images and descriptions

## What's New

### Enhanced Recipe Book Model
- ✅ Cover images for recipe books
- ✅ Rich descriptions
- ✅ Custom color themes
- ✅ Complete metadata tracking

### Export Functionality
- ✅ Export entire recipe books with all recipes
- ✅ Optional image inclusion (with/without images)
- ✅ ZIP-based `.recipebook` format
- ✅ Share via system share sheet
- ✅ Progress indicators during export

### Import Functionality
- ✅ Import `.recipebook` files
- ✅ Automatic duplicate handling
- ✅ Image restoration
- ✅ Recipe merging (existing recipes updated, new ones added)
- ✅ Progress indicators during import

## File Structure

### New Files Created

1. **RecipeBookExportModel.swift** - Data models for export/import
   - `RecipeBookExportPackage` - Complete export container
   - `ExportableRecipeBook` - Codable book representation
   - `ImageManifestEntry` - Tracks images in the package

2. **RecipeBookExportService.swift** - Export/import service
   - `exportBook()` - Exports a book to `.recipebook` file
   - `importBook()` - Imports from `.recipebook` file
   - Image handling and ZIP operations

3. **RecipeBookImportView.swift** - UI for importing books
   - File picker integration
   - Import progress and error handling
   - Success/failure feedback

4. **Recipe+RecipeModel.swift** - Recipe conversion extensions
   - `init(from: RecipeModel)` - Creates Recipe from RecipeModel
   - `toRecipeModel()` - Converts Recipe to RecipeModel

5. **Color+Hex.swift** - Color utilities
   - Hex string to Color conversion
   - Color to hex string conversion

6. **LoggingHelpers.swift** - Logging utilities
   - Consistent logging throughout the app

### Modified Files

1. **RecipeBookDetailView.swift**
   - Added export menu option
   - Export confirmation dialog
   - Share sheet integration
   - Progress overlay
   - Error handling

2. **RecipeBookEditorView.swift** (already had these features)
   - Cover image picker
   - Description field
   - Color theme selector

## Usage Guide

### Exporting a Recipe Book

1. Open a recipe book in `RecipeBookDetailView`
2. Tap the "•••" (more) button in the top right
3. Select "Export Book"
4. Choose whether to include images:
   - **With Images**: Full fidelity export (larger file size)
   - **Without Images**: Metadata only (smaller file size)
5. Wait for export to complete
6. Share via the system share sheet (AirDrop, Messages, Email, etc.)

### Importing a Recipe Book

**Option 1: From Files App**
1. Receive the `.recipebook` file
2. Save to Files app
3. In Reczipes app, navigate to Books section
4. Tap "Import Book" button
5. Select the `.recipebook` file
6. Wait for import to complete

**Option 2: From Share Sheet**
1. Receive the `.recipebook` file via AirDrop/Messages/Email
2. Tap "Share" → "Open in Reczipes"
3. App will automatically start import
4. Wait for import to complete

### Editing Book Details

1. Open a recipe book
2. Tap "•••" → "Edit Book"
3. Modify:
   - Book name
   - Description (supports multi-line)
   - Cover image (tap to add/change)
   - Color theme (tap a color circle)
4. Tap "Save"

## Technical Details

### Export Format (`.recipebook`)

The `.recipebook` file is a ZIP archive containing:

```
book.json              # Main metadata and recipe data
book_cover_xxx.jpg     # Cover image (if present)
recipe_img_xxx.jpg     # Recipe images (if included)
...                    # Additional images
```

### JSON Structure

```json
{
  "version": "1.0",
  "exportDate": "2025-12-28T12:00:00Z",
  "book": {
    "id": "uuid",
    "name": "My Recipe Book",
    "bookDescription": "A collection of favorites",
    "coverImageName": "book_cover_xxx.jpg",
    "color": "FF6B6B",
    "recipeIDs": ["uuid1", "uuid2"],
    ...
  },
  "recipes": [...],
  "imageManifest": [...]
}
```

### Image Handling

**Export:**
- Images are copied from Documents directory
- Original file names preserved
- Manifest tracks image associations
- Optional compression available

**Import:**
- Images extracted to Documents directory
- Duplicate file names handled
- Missing images logged but don't fail import
- Unused images cleaned up

### Conflict Resolution

**When importing an existing book:**

1. **Default (replaceExisting: false)**
   - Creates new book with "(Imported)" suffix
   - Generates new UUIDs
   - Copies all images with new names
   - Safe, non-destructive

2. **Replace Mode (replaceExisting: true)**
   - Deletes existing book
   - Imports with original UUIDs
   - Updates existing recipes
   - Use with caution

## Dependencies

### Required Package

**ZIPFoundation** - For ZIP file operations
- Add via Xcode: File → Add Package Dependencies
- URL: `https://github.com/weichsel/ZIPFoundation`
- Version: 0.9.0 or later

To add to your project:
1. Open your Xcode project
2. File → Add Package Dependencies
3. Search for "ZIPFoundation"
4. Add to your app target

## Implementation Checklist

### Required Setup

- [x] Add ZIPFoundation package
- [x] Create export models
- [x] Create export service
- [x] Update RecipeBookDetailView with export UI
- [x] Create import view
- [x] Add Recipe/RecipeModel conversion extensions
- [x] Add Color hex extensions
- [x] Add logging helpers

### Optional Enhancements

- [ ] Add export to iCloud Drive
- [ ] Add batch export (multiple books)
- [ ] Add export history/log
- [ ] Add import from URL
- [ ] Add encryption for sensitive recipes
- [ ] Add export templates
- [ ] Add selective recipe export

## Error Handling

The implementation includes comprehensive error handling:

- **Export Errors**
  - File system access denied
  - Insufficient storage
  - Image access failures
  - ZIP creation failures

- **Import Errors**
  - Invalid file format
  - Corrupted ZIP archive
  - Missing required data
  - JSON parsing errors
  - Database conflicts

All errors are logged using the unified logging system and displayed to users with actionable messages.

## Testing Recommendations

### Export Testing
1. Export book with images (large)
2. Export book without images (small)
3. Export empty book (should be disabled)
4. Export with missing images
5. Share via different methods (AirDrop, Messages, etc.)

### Import Testing
1. Import from Files app
2. Import from share sheet
3. Import duplicate book
4. Import corrupted file
5. Import with missing images
6. Import very large book

### Integration Testing
1. Export then import same book
2. Export from device A, import on device B
3. Verify images are preserved
4. Verify recipe order is maintained
5. Verify book appearance is consistent

## Troubleshooting

### Export Issues

**"Export Failed" Error**
- Check available storage space
- Verify image files exist in Documents directory
- Check file permissions

**Missing Images in Export**
- Verify images exist before export
- Check image file names match recipe data
- Try export without images first

### Import Issues

**"Unable to Access File"**
- Make sure file is saved locally
- Check file isn't still downloading from iCloud
- Try copying file to different location

**"Invalid Format" Error**
- Verify file has `.recipebook` extension
- Ensure file isn't corrupted
- Try re-downloading the file

**Import Hangs**
- Large books with many images take time
- Don't close app during import
- Check Console app for detailed errors

## Future Enhancements

Potential additions for v2:
- Cloud sync integration
- Collaborative recipe books
- Version history
- Compressed image formats (HEIC)
- Selective sync (only changed recipes)
- Export to PDF for printing
- Export to Markdown/HTML
- Integration with recipe sharing platforms

## API Reference

### RecipeBookExportService

```swift
// Export a book
static func exportBook(
    _ book: RecipeBook,
    recipes: [RecipeModel],
    includeImages: Bool = true
) async throws -> URL

// Import a book
static func importBook(
    from url: URL,
    modelContext: ModelContext,
    replaceExisting: Bool = false
) async throws -> RecipeBook
```

### RecipeBookExportPackage

```swift
struct RecipeBookExportPackage: Codable {
    let version: String
    let exportDate: Date
    let book: ExportableRecipeBook
    let recipes: [RecipeModel]
    let imageManifest: [ImageManifestEntry]
}
```

## Support

For issues or questions:
1. Check logs in Console app (category: "book-export" or "book-import")
2. Verify all dependencies are installed
3. Ensure file permissions are correct
4. Check available storage space

---

**Version**: 1.0  
**Last Updated**: December 28, 2025  
**Compatibility**: iOS 17.0+
