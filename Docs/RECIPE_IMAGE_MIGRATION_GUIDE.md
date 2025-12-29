# Recipe Image Migration to SwiftData - Complete Guide

## Problem

When you delete and reinstall your app, CloudKit syncs your Recipe records but **NOT** the image files stored in the Documents directory. This causes all recipe images to disappear even though the recipes themselves are restored.

## Solution

Store recipe images directly in SwiftData using the `@Attribute(.externalStorage)` modifier. This allows CloudKit to sync the actual image data across devices and survive app deletion/reinstallation.

---

## Changes Made

### 1. Recipe Model Updates (`Recipe.swift`)

Added two new fields to store image data:

```swift
@Attribute(.externalStorage) var imageData: Data? // Main image data
@Attribute(.externalStorage) var additionalImagesData: Data? // JSON array of additional images
```

The `@Attribute(.externalStorage)` modifier tells SwiftData to:
- Store large data efficiently outside the main database
- Automatically sync via CloudKit
- Handle large files without bloating the database

### 2. Helper Methods

Added methods to `Recipe` model:

- **`ensureImageDataLoaded()`**: Loads image data from files into SwiftData
- **`ensureImageFilesExist()`**: Recreates image files from SwiftData (for backwards compatibility)

### 3. Migration Service (`RecipeImageMigrationService.swift`)

Created a service to handle migration:

- **`migrateAllRecipeImages()`**: Copies all image files → SwiftData
- **`restoreAllRecipeImages()`**: Recreates image files from SwiftData
- **`needsImageRestoration()`**: Checks if restoration is needed

### 4. Migration UI (`RecipeImageMigrationView.swift`)

Added a user-friendly interface in **Settings → Data & Sync → Image Migration**:

- Shows migration status
- **"Migrate Images to SwiftData"** button - run BEFORE deleting app
- **"Restore Images from SwiftData"** button - run AFTER reinstalling app
- Automatic detection of missing images

### 5. Automatic Restoration (`Reczipes2App.swift`)

Added automatic image restoration on app launch:

```swift
.onAppear {
    Task {
        await checkAndRestoreImages()
    }
}
```

This automatically restores missing image files when the app starts.

---

## How to Use

### Before Deleting the App

1. Open **Settings → Data & Sync → Image Migration**
2. Tap **"Migrate Images to SwiftData"**
3. Wait for migration to complete (shows count of migrated recipes)
4. Wait for CloudKit sync to complete
5. Now safe to delete the app

### After Reinstalling the App

1. Open the app and wait for CloudKit sync
2. Images should **automatically restore** on app launch
3. If not, go to **Settings → Data & Sync → Image Migration**
4. Tap **"Restore Images from SwiftData"**
5. All images will be recreated from CloudKit data

---

## Technical Details

### Image Storage Strategy

**Old Approach:**
- Recipe stores `imageName: String` (filename only)
- Image saved as file in Documents directory
- CloudKit syncs Recipe record but NOT the file
- ❌ Images lost on app deletion

**New Approach:**
- Recipe stores `imageName: String` (backwards compatible)
- Recipe stores `imageData: Data` (actual image)
- CloudKit syncs both the record AND the image data
- ✅ Images survive app deletion

### External Storage

The `@Attribute(.externalStorage)` modifier:
- Stores data in a separate file, not inline in database
- Reduces database size and improves performance
- CloudKit automatically handles sync for external storage
- Works seamlessly with large files (photos, videos, etc.)

### Additional Images Format

Additional images are stored as JSON:

```json
[
  {
    "fileName": "recipe_ABC123_1.jpg",
    "imageData": "base64EncodedString..."
  },
  {
    "fileName": "recipe_ABC123_2.jpg",
    "imageData": "base64EncodedString..."
  }
]
```

This allows multiple images per recipe while keeping the data structure flexible.

---

## Migration Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  BEFORE APP DELETION                                        │
├─────────────────────────────────────────────────────────────┤
│  1. User taps "Migrate Images to SwiftData"               │
│  2. Service reads image files from Documents directory      │
│  3. Service stores Data in recipe.imageData                │
│  4. SwiftData saves to persistent store                    │
│  5. CloudKit syncs imageData to iCloud                     │
│  ✅ Images now backed up in CloudKit                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  APP DELETION                                               │
├─────────────────────────────────────────────────────────────┤
│  • Documents directory deleted                             │
│  • Local SwiftData deleted                                 │
│  ✅ CloudKit data remains in iCloud                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  AFTER APP REINSTALL                                        │
├─────────────────────────────────────────────────────────────┤
│  1. App starts, CloudKit syncs Recipe records              │
│  2. Recipes have imageData but no files yet                │
│  3. App detects missing files (automatic check)            │
│  4. Service reads recipe.imageData                         │
│  5. Service writes Data back to Documents directory        │
│  6. recipe.imageName files recreated                       │
│  ✅ All images restored!                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Testing

### Test Scenario 1: Fresh Migration

1. Create/import recipes with images
2. Open Image Migration view
3. Tap "Migrate Images to SwiftData"
4. Verify count increases
5. Check a recipe - images should still display

### Test Scenario 2: App Deletion & Restore

1. Complete migration (Test 1)
2. Wait for CloudKit sync (check CloudKit Diagnostics)
3. Delete app from device
4. Reinstall app
5. Wait for CloudKit sync
6. **Expected**: Images automatically restore
7. If not, manually tap "Restore Images"

### Test Scenario 3: Multiple Devices

1. Migrate on Device A
2. Wait for sync
3. Install app on Device B
4. Wait for sync
5. **Expected**: All recipes and images appear on Device B

---

## Troubleshooting

### Images Not Restoring

**Problem**: After reinstall, recipes show but no images

**Solutions**:
1. Check CloudKit sync status (Settings → CloudKit Diagnostics)
2. Manually tap "Restore Images from SwiftData"
3. Check if iCloud Drive is enabled
4. Check if CloudKit sync is working

### Migration Takes Too Long

**Problem**: Migration stuck or very slow

**Causes**:
- Large image files (10+ MB each)
- Many recipes with multiple images
- Low memory on device

**Solutions**:
- Close other apps
- Ensure device has free storage
- Let it run - may take several minutes for 100+ recipes

### Images Missing After Migration

**Problem**: Migration completes but images still missing

**Causes**:
- Image files were already deleted before migration
- File permissions issue
- CloudKit not syncing external storage

**Solutions**:
1. Check if files exist in Documents directory
2. Re-import from backup (.reczipes file)
3. Check CloudKit quota (Settings → CloudKit Diagnostics)

---

## Best Practices

1. **Migrate Early**: Run migration as soon as you update to this version
2. **Wait for Sync**: After migration, wait 5-10 minutes for CloudKit sync
3. **Regular Backups**: Still use Backup & Restore for extra safety
4. **Test Restore**: After migration, test on a second device or simulator
5. **Monitor Storage**: Large image collections use iCloud storage quota

---

## CloudKit Storage Considerations

### iCloud Storage Usage

- Each recipe with images: ~2-5 MB
- 100 recipes: ~200-500 MB
- 500 recipes: ~1-2.5 GB

Users with many high-resolution images may need to:
- Enable iCloud+ for additional storage
- Compress images before adding to recipes
- Use "Export without Images" for sharing large recipe books

### Sync Performance

- Initial sync after migration may take 10-30 minutes
- Incremental syncs are much faster
- External storage data syncs in background
- Large images may delay sync on slow connections

---

## Code References

### Key Files

- **Recipe.swift**: Model with `imageData` fields
- **RecipeImageMigrationService.swift**: Migration logic
- **RecipeImageMigrationView.swift**: User interface
- **Reczipes2App.swift**: Automatic restoration on launch
- **SettingsView.swift**: Navigation to migration view

### Important Functions

```swift
// Migrate images to SwiftData
RecipeImageMigrationService.migrateAllRecipeImages(modelContext:)

// Restore images from SwiftData
RecipeImageMigrationService.restoreAllRecipeImages(modelContext:)

// Check if restoration needed
RecipeImageMigrationService.needsImageRestoration(modelContext:)

// Ensure specific recipe has images
recipe.ensureImageFilesExist()
```

---

## Future Enhancements

Potential improvements:

1. **Progress Indicators**: Show X of Y recipes migrated
2. **Selective Migration**: Choose which recipes to migrate
3. **Image Compression**: Compress images before storing in SwiftData
4. **Background Migration**: Migrate in background over time
5. **Migration Verification**: Verify data integrity after migration

---

## Summary

✅ **Before this update**: Images lost on app deletion
✅ **After this update**: Images backed up in CloudKit and survive reinstall
✅ **User action required**: Run "Migrate Images to SwiftData" once
✅ **Automatic**: Images restore on app launch after reinstall
✅ **Backwards compatible**: Old recipes still work with file-based images

This update ensures your recipe images are safe and sync properly across all devices via CloudKit!
