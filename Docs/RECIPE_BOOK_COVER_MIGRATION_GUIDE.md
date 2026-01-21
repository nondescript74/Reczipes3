# Recipe Book Cover Image Migration Guide

## Overview

This document describes the migration from file-based storage to SwiftData storage for recipe book cover images in Reczipes2.

## Background

### Old System (Pre-Migration)
- Book cover images were stored as **files in the Documents directory**
- Only the filename was stored in SwiftData (`coverImageName`)
- Images did **not sync via CloudKit/iCloud**
- Manual file management was required

### New System (Post-Migration)
- Book cover images are stored as **Data in SwiftData** (`coverImageData`)
- Images **sync automatically via CloudKit/iCloud**
- No manual file management needed
- Backwards compatible with old system

## Migration Process

### What Happens During Migration

1. **Automatic Detection**: On app launch, the migration service checks if migration is needed
2. **For Each Book**:
   - Checks if `coverImageData` already exists (skip if yes)
   - Checks if `coverImageName` exists (skip if no image)
   - Loads image file from Documents directory
   - Stores image data in `coverImageData` property
   - Updates `dateModified` timestamp
3. **Saves Changes**: All migrated books are saved to SwiftData
4. **Marks Complete**: Migration won't run again on subsequent launches

### Migration Triggers

The migration runs **automatically** when:
- App launches for the first time after update
- User has books with cover images stored as files
- Migration hasn't been completed yet

### What Gets Migrated

✅ **Migrated**:
- All book cover images that exist in Documents directory
- Image data is copied to SwiftData
- Original files are preserved (for safety)

⏭️ **Skipped**:
- Books that already have `coverImageData` (already migrated)
- Books without cover images (`coverImageName` is nil)
- Books where the image file is missing

❌ **Failed**:
- Books where image file cannot be read
- Books where image data is invalid/corrupted

## User Impact

### What Users Will Notice

1. **First Launch After Update**:
   - Brief "Migrating Book Covers" message may appear
   - Existing book covers will continue to work normally

2. **After Migration**:
   - Book covers now sync across devices via iCloud
   - Covers appear faster (no file I/O needed)
   - More reliable (stored in database, not separate files)

### What Users Won't Notice

- UI remains exactly the same
- Book covers display identically
- No action required from users
- Migration is completely automatic

## Technical Details

### Files Modified

1. **RecipeBook.swift**
   - Added `coverImageData: Data?` property
   - Updated initializer to accept `coverImageData`

2. **RecipeBookEditorView.swift**
   - Modified to save images as data instead of files
   - Updated to display images from both data and files
   - Maintains backwards compatibility

3. **RecipeBooksView.swift** (BookCardView)
   - Updated to pass `imageData` to `RecipeImageView`
   - Falls back to file-based loading if data not available

4. **RecipeBookImageMigrationService.swift** (NEW)
   - Handles the entire migration process
   - Includes error handling and logging
   - Provides migration statistics

5. **Reczipes2App.swift**
   - Added automatic migration call on app launch
   - Includes user diagnostics and error reporting

### Migration Service API

```swift
let service = RecipeBookImageMigrationService(modelContext: modelContext)

// Check if migration is needed
if service.needsMigration {
    // Perform migration
    let result = try await service.performMigration()
    print(result.summary)
    
    // Optional: Clean up old files
    let cleanup = try await service.cleanupOldImageFiles()
    print(cleanup.summary)
}
```

### Data Structure

**Before Migration**:
```swift
RecipeBook {
    coverImageName: "book_cover_ABC123.jpg"  // Filename
    coverImageData: nil                       // No data
}
```

**After Migration**:
```swift
RecipeBook {
    coverImageName: "book_cover_ABC123.jpg"  // Kept for reference
    coverImageData: <binary JPEG data>        // Image data
}
```

## File Cleanup (Optional)

### Why Keep Old Files?

The migration **does not delete** old image files by default because:
- Safety: Provides a backup if something goes wrong
- Testing: Allows verification that migration worked
- Rollback: Could revert to old system if needed

### When to Clean Up

You can safely delete old image files after:
1. Verifying migration was successful
2. Confirming books display correctly on all devices
3. Waiting for iCloud sync to complete

### How to Clean Up

**Automatic Cleanup** (uncomment in code):
```swift
// In RecipeBookImageMigrationService.migrateIfNeeded()
if result.failedCount == 0 && result.migratedCount > 0 {
    let cleanupResult = try await service.cleanupOldImageFiles()
    logInfo(cleanupResult.summary, category: "migration")
}
```

**Manual Cleanup** (from code):
```swift
let service = RecipeBookImageMigrationService(modelContext: modelContext)
let result = try await service.cleanupOldImageFiles()
// Freed: result.megabytesFreed MB
```

## Error Handling

### Common Errors

1. **Image File Not Found**
   - Cause: File was deleted or moved
   - Result: Book marked as "skipped"
   - Solution: User can re-add cover image in editor

2. **Invalid Image Data**
   - Cause: File is corrupted or not a valid image
   - Result: Book marked as "failed"
   - Solution: User needs to select new cover image

3. **Context Save Failure**
   - Cause: Database issue or insufficient storage
   - Result: Migration aborts
   - Solution: Check storage space and database integrity

### Logging and Diagnostics

All migration activity is logged with:
- **Console logs**: For developers (in Xcode console)
- **User diagnostics**: For end users (in Diagnostics view)
- **Migration summary**: Statistics on success/failure

Example logs:
```
[Migration] 🔄 Starting RecipeBook cover image migration...
[Migration] Found 5 recipe book(s) to check
[Migration] ✓ Migrated cover image for 'Italian Favorites' (245KB)
[Migration] Skipped 'Quick Meals': No cover image
[Migration] ✅ Migration complete: 3 migrated, 2 skipped, 0 failed
```

## Testing Migration

### Test Scenarios

1. **First-time Migration**
   - Fresh install with books that have file-based covers
   - Expected: All covers migrated successfully

2. **Partial Migration**
   - Some books already migrated, some not
   - Expected: Only unmigrated books are processed

3. **No Migration Needed**
   - All books already have `coverImageData`
   - Expected: Migration skipped entirely

4. **Missing Files**
   - Books reference files that don't exist
   - Expected: Books skipped, no errors

### Force Re-Migration (for Testing)

```swift
let service = RecipeBookImageMigrationService(modelContext: modelContext)
service.resetMigrationStatus()
// Migration will run again on next launch
```

## Rollback Plan

If migration causes issues:

1. **Immediate Rollback** (before cleanup):
   - Remove `coverImageData` assignment in `RecipeBookEditorView`
   - Revert to file-based loading only
   - Old files still exist, will work immediately

2. **After Cleanup** (files deleted):
   - No easy rollback
   - Users must re-add book covers manually
   - Recommendation: **Don't enable cleanup until confident**

## Future Considerations

### Schema Migration

If RecipeBook model changes significantly:
- Update `Reczipes2MigrationPlan` in `SchemaMigration.swift`
- Add migration stage for `coverImageData` property
- Current migration service can still run alongside

### CloudKit Sync

Book covers now sync via CloudKit automatically:
- Large images increase CloudKit usage
- Consider image compression (already at 0.8 quality)
- Monitor CloudKit storage limits

### Performance

Benefits of SwiftData storage:
- ✅ Faster loading (in-memory, no file I/O)
- ✅ Automatic CloudKit sync
- ✅ Transactional consistency
- ⚠️ Slightly larger database size

## Monitoring

### Success Metrics

Track these to verify migration success:
- Number of books migrated
- Number of books skipped
- Number of failures
- Disk space freed (after cleanup)
- User complaints about missing covers

### Example Success Result

```
Migration Summary:
- Total Books: 10
- Successfully Migrated: 8
- Skipped (no action needed): 2
- Failed: 0
- Success Rate: 80.0%
```

## FAQ

**Q: Will this affect my existing book covers?**
A: No, covers will continue to display normally. The migration copies data, doesn't remove it.

**Q: What if migration fails?**
A: The app continues to work normally. You can re-add covers manually in the book editor.

**Q: Will my covers sync to other devices?**
A: Yes! After migration, covers sync automatically via iCloud.

**Q: What happens to the old image files?**
A: They remain in Documents directory until manually cleaned up (optional).

**Q: Can I disable the migration?**
A: Not recommended, but you can comment out the migration call in `Reczipes2App.swift`.

**Q: How long does migration take?**
A: Usually instant (< 1 second). Depends on number of books and image sizes.

## Summary

✅ **Automatic**: Migration runs once on app launch  
✅ **Safe**: Original files preserved  
✅ **Fast**: Completes in seconds  
✅ **Logged**: Full diagnostics available  
✅ **CloudKit Ready**: Enables iCloud sync  
✅ **Backwards Compatible**: Works with old and new systems  

---

**Migration implemented**: January 20, 2026  
**Target version**: Reczipes2 v2.1+
