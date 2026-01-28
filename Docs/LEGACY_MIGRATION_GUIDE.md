# Legacy to New Model Migration Guide

## Overview

This guide explains the migration system for transitioning from legacy `Recipe` and `RecipeBook` models to the new unified `RecipeX` and `Book` models with automatic CloudKit synchronization.

## Why Migrate?

### Legacy Models
- **Recipe**: Local-only storage, no automatic sync
- **RecipeBook**: Local-only storage, manual sharing required
- **SharedRecipe**: Separate tracking for shared recipes
- **SharedRecipeBook**: Separate tracking for shared books

### New Unified Models
- **RecipeX**: Single model with built-in CloudKit sync
- **Book**: Single model with built-in CloudKit sync
- Automatic iCloud synchronization across devices
- Simplified data model (one source of truth)
- Better performance and reliability
- Future-proof architecture

## Migration Process

### 1. Automatic Detection

The app automatically detects if you have legacy data that needs migration:

```swift
let manager = LegacyToNewMigrationManager(modelContext: modelContext)
let needsMigration = await manager.needsMigration()
```

A badge appears in the toolbar when migration is available:
- Orange circular badge with count of legacy items
- Tapping opens the migration UI

### 2. Migration UI

Access via:
- **Toolbar Badge**: Tap the orange migration badge
- **More Menu**: Recipes tab → More (•••) → "Migrate to New Models"

The migration view shows:
- Current status (legacy vs new model counts)
- Migration progress
- Action buttons (Start Migration, Delete Legacy Data)

### 3. Migration Steps

When you tap "Start Migration":

1. **Copy Recipes** → RecipeX
   - Preserves all recipe data
   - Maintains recipe IDs (important for book references)
   - Migrates images from files to SwiftData
   - Marks for CloudKit sync

2. **Copy Books** → Book
   - Preserves all book data
   - Maintains recipe references
   - Marks for CloudKit sync

3. **Validate Migration**
   - Checks all recipes migrated
   - Checks all books migrated
   - Verifies no duplicate IDs
   - Confirms data integrity

4. **Save to SwiftData**
   - Commits all changes
   - Triggers CloudKit sync

### 4. Post-Migration

After successful migration:
- **Legacy data is preserved** (safe by default)
- New RecipeX and Book models are ready to use
- CloudKit sync begins automatically
- Switch to RecipeX tab to see new recipes

### 5. Cleanup (Optional)

After confirming everything works:
- Tap "Delete Legacy Data" button
- Confirm deletion
- Legacy Recipe and RecipeBook models are removed
- Frees up storage space

⚠️ **Warning**: Deletion is permanent. Only do this after verifying migration success.

## Migration Features

### Safety
- ✅ Non-destructive by default (legacy data kept)
- ✅ Full validation before marking complete
- ✅ Error handling and rollback support
- ✅ Detailed logging for troubleshooting

### Data Preservation
- ✅ All recipe content preserved
- ✅ All book content preserved
- ✅ Recipe-to-book relationships maintained
- ✅ Images migrated from files to SwiftData
- ✅ Timestamps preserved
- ✅ Metadata preserved

### CloudKit Integration
- ✅ Automatic marking for sync
- ✅ Owner attribution (your user ID)
- ✅ Device tracking
- ✅ Version tracking for conflict resolution

## Migration API

### LegacyToNewMigrationManager

Main class for handling migration:

```swift
@MainActor
class LegacyToNewMigrationManager {
    init(modelContext: ModelContext)
    
    // Check status
    func needsMigration() async -> Bool
    func getMigrationStats() async -> MigrationStats
    var isMigrationCompleted: Bool
    var migrationDate: Date?
    
    // Perform migration
    func performMigration(
        deleteLegacyData: Bool = false,
        skipCloudSync: Bool = false
    ) async throws -> MigrationResult
    
    // Manual migration
    func migrateRecipe(_ recipe: Recipe) async throws -> RecipeX
    func migrateBook(_ book: RecipeBook) async throws -> Book
    
    // Reset (for testing)
    func resetMigrationStatus()
}
```

### MigrationStats

Statistics about migration progress:

```swift
struct MigrationStats {
    let legacyRecipeCount: Int
    let legacyBookCount: Int
    let migratedRecipeCount: Int
    let migratedBookCount: Int
    
    var totalLegacyItems: Int
    var totalMigratedItems: Int
    var overallProgress: Double
    var summary: String
}
```

### MigrationResult

Result of migration operation:

```swift
struct MigrationResult {
    var recipesSuccess: Int
    var recipesSkipped: Int
    var recipesError: Error?
    
    var booksSuccess: Int
    var booksSkipped: Int
    var booksError: Error?
    
    var validation: MigrationValidation?
    var legacyDataDeleted: Bool
    
    var totalSuccess: Int
    var isSuccess: Bool
    var summary: String
}
```

## Usage Examples

### Check if Migration Needed

```swift
let manager = LegacyToNewMigrationManager(modelContext: modelContext)

if await manager.needsMigration() {
    print("Migration is needed!")
    let stats = await manager.getMigrationStats()
    print(stats.summary)
}
```

### Perform Migration

```swift
do {
    let result = try await manager.performMigration(
        deleteLegacyData: false,  // Keep legacy data for safety
        skipCloudSync: false       // Enable CloudKit sync
    )
    
    print(result.summary)
    
    if result.isSuccess {
        print("✅ Migration completed successfully!")
    } else {
        print("⚠️ Migration completed with issues")
        print(result.errorSummary)
    }
} catch {
    print("❌ Migration failed: \(error)")
}
```

### Get Migration Stats

```swift
let stats = await manager.getMigrationStats()

print("Legacy Recipes: \(stats.legacyRecipeCount)")
print("Legacy Books: \(stats.legacyBookCount)")
print("Migrated RecipeX: \(stats.migratedRecipeCount)")
print("Migrated Books: \(stats.migratedBookCount)")
print("Overall Progress: \(Int(stats.overallProgress * 100))%")
```

### Migrate Single Recipe

```swift
let recipe: Recipe = // your legacy recipe

do {
    let recipeX = try await manager.migrateRecipe(recipe)
    print("✅ Migrated '\(recipe.title)' to RecipeX")
} catch {
    print("❌ Failed to migrate recipe: \(error)")
}
```

## Migration Validation

After migration, the system validates:

1. **All recipes migrated**
   - Count matches
   - No missing IDs

2. **All books migrated**
   - Count matches
   - Recipe references intact

3. **No duplicate IDs**
   - RecipeX IDs unique
   - Book IDs unique

4. **Data integrity**
   - No nil IDs
   - No empty titles
   - All required fields present

Validation results are included in `MigrationResult`:

```swift
if let validation = result.validation {
    print(validation.summary)
    
    if !validation.isValid {
        print("Errors:")
        validation.errors.forEach { print("  • \($0)") }
    }
    
    if validation.hasWarnings {
        print("Warnings:")
        validation.warnings.forEach { print("  • \($0)") }
    }
}
```

## Troubleshooting

### Migration Not Appearing

**Problem**: No migration badge or option visible

**Solutions**:
1. Check if you have legacy data:
   ```swift
   let stats = await manager.getMigrationStats()
   print("Legacy items: \(stats.totalLegacyItems)")
   ```
2. Verify migration not already completed:
   ```swift
   print("Completed: \(manager.isMigrationCompleted)")
   ```
3. Reset migration status (if needed):
   ```swift
   manager.resetMigrationStatus()
   ```

### Migration Fails

**Problem**: Migration throws error or completes with errors

**Solutions**:
1. Check detailed error:
   ```swift
   if let error = result.recipesError {
       print("Recipe error: \(error)")
   }
   if let error = result.booksError {
       print("Book error: \(error)")
   }
   ```
2. Review validation results:
   ```swift
   print(result.validation?.detailedSummary ?? "No validation")
   ```
3. Try migrating individual items:
   ```swift
   for recipe in recipes {
       do {
           _ = try await manager.migrateRecipe(recipe)
       } catch {
           print("Failed: \(recipe.title) - \(error)")
       }
   }
   ```

### Duplicate Items

**Problem**: RecipeX or Book with same ID already exists

**Behavior**: Skipped during migration (not an error)

**Result**: `recipesSkipped` or `booksSkipped` count increases

### Data Loss Concerns

**Q**: Will I lose data during migration?

**A**: No. By default:
- Legacy data is **kept** (not deleted)
- Only **copies** are created as new models
- You must explicitly choose to delete legacy data
- Deletion requires confirmation

**Q**: What if migration fails halfway?

**A**: Transaction safety:
- Changes are saved only if migration succeeds
- Failed migration doesn't affect existing data
- You can retry migration safely

## Best Practices

1. **Backup First** ✅
   - iCloud backup enabled
   - Or export recipes before migration

2. **Test Migration** ✅
   - Review migration stats
   - Check validation results
   - Verify data in RecipeX tab

3. **Don't Delete Immediately** ✅
   - Keep legacy data for a few days
   - Verify everything works
   - Then delete when confident

4. **Monitor CloudKit Sync** ✅
   - Check CloudKit sync badge
   - Wait for initial sync to complete
   - Verify recipes appear on other devices

## Implementation Details

### Recipe Migration

```swift
// Legacy Recipe → RecipeX
let recipeX = RecipeX(from: recipe)

// Set CloudKit metadata
recipeX.needsCloudSync = true
recipeX.ownerUserID = currentUserID
recipeX.ownerDisplayName = currentDisplayName

// Migrate image files to SwiftData
if recipe.imageName != nil {
    // Load from Documents directory
    // Store in recipeX.imageData
}

// Insert into context
modelContext.insert(recipeX)
```

### Book Migration

```swift
// Legacy RecipeBook → Book
let book = Book(from: recipeBook)

// Set CloudKit metadata
book.needsCloudSync = true
book.ownerUserID = currentUserID
book.ownerDisplayName = currentDisplayName

// Recipe IDs are preserved
// (References remain valid)

// Insert into context
modelContext.insert(book)
```

### Image Migration

Legacy recipes stored images in Documents directory:
```
Documents/recipe_UUID.jpg
```

New RecipeX stores images in SwiftData:
```swift
recipeX.imageData: Data?  // Syncs via CloudKit
```

Migration automatically:
1. Loads file from Documents directory
2. Stores Data in `imageData` property
3. Marks for CloudKit sync
4. (Optional) Deletes file after confirmation

## CloudKit Sync After Migration

After migration, new models automatically sync:

1. **Background Service**
   - `RecipeXCloudKitSyncService` monitors `needsCloudSync`
   - Uploads to CloudKit Public Database
   - Updates `lastSyncedToCloud` timestamp

2. **Sync Process**
   - Creates CKRecord for each RecipeX/Book
   - Uploads to Public Database
   - Other users can discover via queries

3. **Cross-Device Sync**
   - Private Database sync (user's devices)
   - Automatic conflict resolution
   - Version tracking

## Migration Logging

All migration operations are logged:

```swift
// Category: "LegacyMigration"
logger.info("Starting migration...")
logger.info("Migrated \(count) recipes")
logger.error("Migration failed: \(error)")
```

View logs in Console.app:
```
subsystem: com.reczipes2
category: LegacyMigration
```

## Testing Migration

### Test Migration (Keep Legacy Data)

```swift
let result = try await manager.performMigration(
    deleteLegacyData: false,
    skipCloudSync: true  // Don't trigger CloudKit during testing
)
```

### Reset for Re-Testing

```swift
// Delete migrated data
let recipeXDescriptor = FetchDescriptor<RecipeX>()
let recipesX = try modelContext.fetch(recipeXDescriptor)
recipesX.forEach { modelContext.delete($0) }

// Reset migration status
manager.resetMigrationStatus()

// Try again
let result = try await manager.performMigration()
```

## FAQ

**Q: When should I migrate?**
A: As soon as convenient. New models offer better features and CloudKit sync.

**Q: Can I use both old and new models?**
A: Yes, but not recommended. Migrate completely for best experience.

**Q: What happens to my CloudKit shares?**
A: Legacy shares (SharedRecipe, SharedRecipeBook) are separate. New models use automatic public sharing.

**Q: Will migration use my iCloud storage?**
A: Yes, but efficiently. Images use CloudKit's external storage system.

**Q: How long does migration take?**
A: Depends on data size. Typical: 100 recipes in < 10 seconds.

**Q: Can I rollback migration?**
A: Yes, if you kept legacy data. Just switch back to legacy tab.

**Q: Will this sync to my other devices?**
A: Yes, via iCloud. May take a few minutes for initial sync.

## Summary

The migration system provides:
- ✅ Safe, non-destructive migration
- ✅ Full data preservation
- ✅ Automatic CloudKit integration
- ✅ Comprehensive validation
- ✅ Easy-to-use UI
- ✅ Detailed logging and error handling

Migration is **one-time** and **optional**, but recommended for:
- Better sync across devices
- Simplified data model
- Future feature support
- Improved performance

---

**Need Help?**
- Check logs in Console.app
- Review validation errors
- Test with individual items
- Contact support if issues persist
