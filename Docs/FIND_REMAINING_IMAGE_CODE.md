# How to Find and Update Remaining Image Saving Code

## Quick Search Commands

Use Xcode's "Find in Project" (Cmd+Shift+F) to search for these patterns:

### 1. Find File-Based Image Saving
```
FileManager.default.urls(for: .documentDirectory
```
Look for any code writing image files to Documents directory.

### 2. Find Image Name Assignment
```
recipe.imageName =
```
Look for any direct assignment of imageName without using `setImage()`.

### 3. Find saveImageToDisk Calls
```
saveImageToDisk
```
Any remaining calls to this deprecated method.

### 4. Find Image File Writing
```
.write(to: fileURL)
```
In context of recipe images being saved.

## Files to Check Manually

### High Priority (Likely Contains Image Saving)

1. **RecipeBookImportService.swift**
   - When importing recipe books, images may need restoration
   - Check if it uses file-based or data-based approach

2. **RecipeBackupManager.swift**  
   - When restoring from backups
   - May restore image files to Documents directory

3. **RecipeEditorView.swift**
   - When users manually add/edit recipe images
   - May use old file-based saving

4. **RecipeExtractorView.swift** (if exists)
   - Single image extraction view
   - May have its own save logic

5. **RecipeImageAssignmentView.swift**
   - Image assignment/management
   - Check if it copies files around

### Medium Priority

6. **LinkImportService.swift**
   - URL-based recipe import
   - May download and save images

7. **RecipeBookExportService.swift**
   - Exporting recipe books
   - May read from imageData or files

### Low Priority (Probably Just Reading)

8. **RecipeDetailView.swift**
   - Displaying recipes
   - Likely only reads, doesn't write

9. **RecipeImageView.swift**
   - Image display component
   - Already updated to check imageData first

## What to Look For

### ❌ Old Pattern (File-Based)
```swift
// DON'T DO THIS ANYMORE
let imageName = "recipe_\(uuid).jpg"
recipe.imageName = imageName

let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let fileURL = documentsPath.appendingPathComponent(imageName)
try imageData.write(to: fileURL)
```

### ✅ New Pattern (SwiftData with CloudKit Sync)
```swift
// DO THIS INSTEAD
recipe.setImage(image, isMainImage: true) // For main image
recipe.setImage(additionalImage, isMainImage: false) // For additional images
```

## Update Template

When you find old file-based image saving code, replace it with:

```swift
// OLD CODE:
// let imageName = "recipe_\(recipe.id.uuidString).jpg"
// recipe.imageName = imageName
// saveImageToDisk(image, filename: imageName)

// NEW CODE:
recipe.setImage(image, isMainImage: true)
// imageName is automatically set by setImage()
```

For additional images:

```swift
// OLD CODE:
// for (index, image) in additionalImages.enumerated() {
//     let filename = "recipe_\(uuid)_\(index).jpg"
//     saveImageToDisk(image, filename: filename)
//     additionalImageNames.append(filename)
// }
// recipe.additionalImageNames = additionalImageNames

// NEW CODE:
for image in additionalImages {
    recipe.setImage(image, isMainImage: false)
}
// additionalImageNames is automatically managed by setImage()
```

## Verification Steps

After updating each file:

1. **Build** the project (Cmd+B) to check for compilation errors
2. **Search** for any remaining `saveImageToDisk` calls
3. **Search** for any remaining direct `recipe.imageName =` assignments
4. **Test** that extraction method to ensure images save and display
5. **Check CloudKit sync** on a second device

## Special Cases

### Recipe Book Import/Export

These may legitimately need to work with image **files** temporarily during import/export:

- **Export**: May extract `imageData` and write to temp files for .recipebook archive
- **Import**: May read from .recipebook archive and load into `imageData`

This is OK as long as the final Recipe object has `imageData` populated, not just files in Documents.

### Backup/Restore

Similar to import/export - may use temporary files but should end with `imageData` populated.

Pattern:
```swift
// Import from backup (OK to use temp files)
let tempImage = UIImage(contentsOfFile: tempPath)

// But final save should use setImage()
recipe.setImage(tempImage, isMainImage: true)
modelContext.insert(recipe)
```

## When You're Done

Create a checklist in this format:

- [ ] RecipeBookImportService.swift - Updated `importRecipeBook()` method
- [ ] RecipeBackupManager.swift - Updated `restoreFromBackup()` method  
- [ ] RecipeEditorView.swift - Updated `saveImageChanges()` method
- [ ] etc.

Add your completed checklist to `IMAGE_EXTRACTION_UPDATE_SUMMARY.md` under a "Additional Updates" section.
