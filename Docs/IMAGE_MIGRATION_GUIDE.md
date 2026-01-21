# Image Storage Migration Guide

## Overview

Reczipes2 is migrating from **file-based image storage** (Documents directory) to **SwiftData imageData** storage. This ensures recipe images sync properly via CloudKit.

## Why This Change?

### Before (File-Based Storage) ❌
- Images saved as `.jpg` files in Documents directory
- `recipe.imageName` contains filename like `"recipe_123.jpg"`
- **Problem**: Files don't sync via CloudKit
- **Result**: Users lose images when reinstalling app

### After (SwiftData Storage) ✅
- Images saved as `Data` in SwiftData with `@Attribute(.externalStorage)`
- `recipe.imageData` contains actual image bytes
- **Benefit**: Images sync automatically via CloudKit
- **Result**: Users keep images across devices and reinstalls

## Migration Architecture

### Automatic Migration on App Startup

1. **Detection**: `ImageMigrationService.needsMigration` checks if migration is needed
2. **Execution**: Runs once per user during app startup
3. **Process**: Loads image files → Converts to Data → Saves to SwiftData
4. **Persistence**: Marks migration complete in UserDefaults

### How It Works

```swift
// 1. Check if migration needed
if ImageMigrationService.needsMigration {
    // 2. Run migration
    let count = await ImageMigrationService.migrateAllRecipes(context: modelContext)
    
    // 3. Migration complete - never runs again
}
```

## Files Changed

### New Files

- **`ImageMigrationService.swift`**: Orchestrates migration process
  - Tracks migration state
  - Migrates all recipes in database
  - Provides cleanup utilities

### Modified Files

1. **`Recipe.swift`**
   - Added `setImage(_:isMainImage:)` - NEW way to save images
   - Added `migrateImagesToSwiftData()` - Migration logic
   - Added `getAllImageData()` - Retrieve all images
   - Added `cleanupFileBasedImages()` - Remove old files

2. **`RecipeImageView.swift`**
   - Now accepts `imageData` parameter
   - Checks `imageData` FIRST, then falls back to files
   - Auto-updates when `imageData` changes

3. **`ModelContainerManager.swift`**
   - Runs migration during startup health check
   - Logs migration progress

## Usage for Developers

### Saving Images (NEW Way)

```swift
// When extracting a new recipe
let recipe = Recipe(...)

// Set main image
recipe.setImage(extractedImage, isMainImage: true)

// Add additional images
recipe.setImage(additionalImage1, isMainImage: false)
recipe.setImage(additionalImage2, isMainImage: false)

// Save to SwiftData
modelContext.insert(recipe)
try? modelContext.save()

// ✅ Images now sync via CloudKit automatically!
```

### Displaying Images (Updated)

```swift
// OLD: Only passed imageName
RecipeImageView(imageName: recipe.imageName)

// NEW: Pass both imageData and imageName
RecipeImageView(
    imageName: recipe.imageName,  // Fallback for legacy recipes
    imageData: recipe.imageData    // Primary source (CloudKit-synced)
)
```

### Backward Compatibility

The migration is **fully backward compatible**:

✅ **Old recipes** (with image files) → Automatically migrated to `imageData`  
✅ **New recipes** → Save directly to `imageData`  
✅ **Mixed state** → RecipeImageView handles both formats

## Migration Timeline

### Phase 1: Migration Runs (Current)
- Migration code runs on app startup
- File-based images copied to `imageData`
- Files kept in Documents directory (safety)
- Users see no difference

### Phase 2: Verification (After 1-2 weeks)
- Monitor CloudKit sync
- Verify images syncing across devices
- Check user feedback

### Phase 3: Cleanup (Optional, Future)
- Uncomment cleanup code in `ModelContainerManager.swift`:
  ```swift
  let cleanedCount = await ImageMigrationService.cleanupFileBasedImages(context: self.container.mainContext)
  ```
- This deletes old image files to save storage

## Testing

### Test Migration Locally

```swift
// In a test or debug view:
ImageMigrationService.resetMigrationState()
// Restart app - migration will run again
```

### Verify Migration Status

```swift
// Check migration status
let status = ImageMigrationService.getMigrationStatus()
print(status) // "✅ Completed (version 1)" or "⏳ Pending"
```

### Test Image Display

1. Create recipe with old file-based image
2. Run migration
3. Check `recipe.imageData != nil`
4. Verify image displays in UI
5. Delete app and reinstall
6. Images should sync back from CloudKit

## Troubleshooting

### Images Not Migrating?

Check console logs:
```
🔄 Starting image migration to SwiftData...
   Found X recipes to check
✅ Image migration completed successfully!
   Migrated: X recipes
```

### Migration Fails?

1. Check file permissions
2. Verify Documents directory is accessible
3. Check available storage space
4. Review error logs with tag `[migration]`

### Images Still Missing After Migration?

Possible causes:
- Image files were already deleted before migration ran
- CloudKit sync not enabled
- User not signed into iCloud

**Solution**: User must restore from backup or re-extract recipes

## Code Migration Checklist

When extracting recipes, update to use `setImage(_:)`:

- [ ] Find all `saveImageToDocuments()` calls
- [ ] Replace with `recipe.setImage(image, isMainImage: true)`
- [ ] Remove file writing code
- [ ] Remove imageName assignment code
- [ ] Test that images save and display correctly
- [ ] Verify CloudKit sync works

## Benefits Summary

✅ **CloudKit Sync**: Images sync automatically across devices  
✅ **Reinstall Safety**: Images restore after deleting/reinstalling app  
✅ **Simplified Code**: No manual file management  
✅ **Better Performance**: SwiftData handles storage optimization  
✅ **External Storage**: Large images don't bloat database file  
✅ **Automatic Cleanup**: Old file references eventually removed

## Migration Logs

Look for these log messages:

```
🔄 Image migration needed - starting migration...
✅ Successfully migrated X recipe images
✅ Image migration already completed
```

## Future Enhancements

Potential improvements:
- Progress UI during migration for large databases
- Image compression optimization
- Duplicate image detection
- Background migration for better UX

## Support

If users report missing images:
1. Check Settings → Developer Tools → Database Diagnostics
2. Verify migration status: `ImageMigrationService.getMigrationStatus()`
3. Check CloudKit sync status
4. Recommend backup/restore if data loss occurred
