# Data & Sync Section Migration to RecipeX and Book

## Overview
The Data & Sync section in SettingsView contains multiple features that need to be updated to support both legacy models (Recipe, RecipeBook) and new unified models (RecipeX, Book).

## Current Issues Identified

### 1. UserContentBackupView
**Status**: ❌ Needs Major Updates

**Current State**:
- Uses `@Query private var recipes: [Recipe]` (legacy model)
- Uses `@Query private var recipeBooks: [RecipeBook]` (legacy model)
- RecipeBackupManager only works with Recipe, not RecipeX
- Book export/import not implemented

**Required Changes**:
- [ ] Add `@Query` for RecipeX and Book models
- [ ] Update backup/export to handle BOTH legacy and new models
- [ ] Create migration path: Recipe → RecipeX, RecipeBook → Book
- [ ] Update RecipeBackupManager to support RecipeX
- [ ] Add BookBackupManager for Book export/import
- [ ] Show combined counts (legacy + new models)
- [ ] Handle mixed export (both model types in one backup)

### 2. RecipeBackupManager
**Status**: ❌ Needs Updates for RecipeX

**Current State**:
- `createBackup(from recipes: [Recipe])` - legacy only
- `importBackup(...existingRecipes: [Recipe])` - legacy only
- Handles Recipe model serialization

**Required Changes**:
- [ ] Add `createBackup(from recipes: [RecipeX])`
- [ ] Add `importBackup(...existingRecipes: [RecipeX])`
- [ ] Support hybrid backup (Recipe + RecipeX in same file)
- [ ] During import, create RecipeX instead of Recipe
- [ ] Handle CloudKit sync properties during import

### 3. CloudKitSyncStatusMonitorView
**Status**: ⚠️ Needs Verification

**Files**: CloudKitSyncStatusMonitorView.swift

**Potential Issues**:
- May only monitor Recipe model sync
- Needs to monitor RecipeX and Book sync
- Should show separate sync status for each model type

**Required Changes**:
- [ ] Verify what models are being monitored
- [ ] Add RecipeX sync monitoring
- [ ] Add Book sync monitoring
- [ ] Show combined sync statistics

### 4. CloudKitSettingsView
**Status**: ⚠️ Needs Verification

**Files**: CloudKitSettingsView.swift

**Potential Issues**:
- CloudKit configuration may need model type awareness
- Sync preferences might be model-specific

**Required Changes**:
- [ ] Review CloudKit configuration
- [ ] Ensure RecipeX and Book are in sync schema
- [ ] Add model-specific sync toggles if needed

### 5. RecipeImageMigrationView
**Status**: ⚠️ Needs Update

**Files**: RecipeImageMigrationView.swift

**Current State**:
- Migrates Recipe images from file-based to SwiftData
- Likely only handles Recipe model

**Required Changes**:
- [ ] Add RecipeX image migration
- [ ] Add Book cover image migration
- [ ] Handle migration for both model types
- [ ] Show separate migration status for each type

### 6. CloudKitDiagnosticsView
**Status**: ⚠️ Needs Update

**Files**: CloudKitDiagnosticsView.swift

**Current State**:
- Shows diagnostics for Recipe sync
- May not include RecipeX or Book

**Required Changes**:
- [ ] Add RecipeX diagnostics
- [ ] Add Book diagnostics
- [ ] Show CloudKit record counts for all model types
- [ ] Display sync errors for all models

### 7. PersistentContainerInfoView
**Status**: ⚠️ Already Updated? (from ModelContainerManager.swift)

**Evidence**: ModelContainerManager.logDiagnosticInfo() already shows:
```swift
let legacyRecipeCount = try context.fetchCount(FetchDescriptor<Recipe>())
let legacyBookCount = try context.fetchCount(FetchDescriptor<RecipeBook>())
let recipeXCount = try context.fetchCount(FetchDescriptor<RecipeX>())
let bookCount = try context.fetchCount(FetchDescriptor<Book>())
```

**Required Changes**:
- [ ] Verify PersistentContainerInfoView uses this diagnostic info
- [ ] Show migration progress (legacy → new models)
- [ ] Add visual indicators for model types

### 8. CloudKitContainerValidationView
**Status**: ⚠️ Needs Verification

**Potential Issues**:
- May only validate Recipe schema
- Needs to validate RecipeX and Book

**Required Changes**:
- [ ] Add RecipeX schema validation
- [ ] Add Book schema validation
- [ ] Verify CloudKit Public DB schema includes new models

### 9. QuickSyncStatusView
**Status**: ⚠️ Needs Verification

**Potential Issues**:
- Quick sync check may only look at Recipe
- Should check RecipeX and Book sync status

**Required Changes**:
- [ ] Add RecipeX sync status
- [ ] Add Book sync status
- [ ] Show combined sync health

## Migration Strategy

### Phase 1: Update Backup/Export System (Priority: HIGH)

1. **RecipeBackupManager Updates**:
   ```swift
   // Add support for RecipeX
   func createBackup(from recipes: [RecipeX]) async throws -> URL
   func importBackup(...existingRecipes: [RecipeX]) async throws -> RecipeImportResult
   
   // Hybrid support (both models)
   func createHybridBackup(recipes: [Recipe], recipesX: [RecipeX]) async throws -> URL
   ```

2. **Create BookBackupManager**:
   ```swift
   class BookBackupManager {
       func createBackup(from books: [Book]) async throws -> URL
       func importBackup(...existingBooks: [Book]) async throws -> BookImportResult
   }
   ```

3. **UserContentBackupView Updates**:
   ```swift
   // Add queries for both model types
   @Query private var recipes: [Recipe]
   @Query private var recipesX: [RecipeX]
   @Query private var recipeBooks: [RecipeBook]
   @Query private var books: [Book]
   
   // Show combined counts
   var totalRecipes: Int { recipes.count + recipesX.count }
   var totalBooks: Int { recipeBooks.count + books.count }
   ```

### Phase 2: Update Monitoring/Diagnostics (Priority: MEDIUM)

1. **CloudKitSyncStatusMonitorView**: Add RecipeX/Book monitoring
2. **CloudKitDiagnosticsView**: Add RecipeX/Book diagnostics
3. **QuickSyncStatusView**: Show combined sync status

### Phase 3: Update Migration Tools (Priority: LOW)

1. **RecipeImageMigrationView**: Handle all model types
2. **CloudKitContainerValidationView**: Validate all schemas

## Data Model Differences

### Recipe → RecipeX
**New Properties**:
- CloudKit sync properties (needsCloudSync, cloudRecordID, etc.)
- Owner attribution (ownerUserID, ownerDisplayName)
- Enhanced versioning (version, contentFingerprint)
- Device tracking (lastModifiedDeviceID)

**Same Properties**:
- Core recipe data (title, ingredients, instructions, etc.)
- Images (imageData, additionalImagesData)
- Metadata (dateAdded, dateCreated, etc.)

### RecipeBook → Book
**New Properties**:
- CloudKit sync properties
- Enhanced content types (images, instructions, glossaries)
- Better organization (tableOfContentsData, recipePreviewsData)
- Sharing controls (isShared)

**Same Properties**:
- Basic book data (name, description, recipeIDs)
- Cover image
- Color theme

## Testing Requirements

### Backup/Export Testing
- [ ] Export legacy Recipe → Import as RecipeX
- [ ] Export RecipeX → Import as RecipeX
- [ ] Export mixed (Recipe + RecipeX) → Import correctly
- [ ] Export legacy RecipeBook → Import as Book
- [ ] Export Book → Import as Book
- [ ] Verify CloudKit properties preserved during import
- [ ] Verify images preserved during backup/restore

### Sync Monitoring Testing
- [ ] Verify RecipeX sync status shown correctly
- [ ] Verify Book sync status shown correctly
- [ ] Verify combined counts accurate
- [ ] Verify sync errors displayed for all models

### Migration Testing
- [ ] Image migration works for Recipe → RecipeX
- [ ] Image migration works for RecipeBook → Book
- [ ] Migration progress tracked correctly

## Implementation Priority

### Must Do Now (Blocking)
1. ✅ RecipeBackupManager - Add RecipeX support
2. ✅ UserContentBackupView - Add RecipeX/Book queries and export
3. ⚠️ BookBackupManager - Create new manager for Book export/import

### Should Do Soon (Important)
4. CloudKitSyncStatusMonitorView - Add RecipeX/Book monitoring
5. CloudKitDiagnosticsView - Add RecipeX/Book diagnostics
6. QuickSyncStatusView - Show combined sync status

### Can Do Later (Nice to Have)
7. RecipeImageMigrationView - Handle all model types
8. CloudKitContainerValidationView - Validate all schemas
9. PersistentContainerInfoView - Enhance display

## Files to Modify

### High Priority
1. `/repo/RecipeBackupManager.swift` - Add RecipeX support
2. `/repo/UserContentBackupView.swift` - Add RecipeX/Book support
3. Create: `/repo/BookBackupManager.swift` - New manager for books

### Medium Priority
4. `/repo/CloudKitSyncStatusMonitorView.swift`
5. `/repo/CloudKitDiagnosticsView.swift`
6. `/repo/QuickSyncStatusView.swift`

### Low Priority
7. `/repo/RecipeImageMigrationView.swift`
8. `/repo/CloudKitContainerValidationView.swift`
9. `/repo/PersistentContainerInfoView.swift`

## Notes

- **Backward Compatibility**: Must support BOTH legacy (Recipe, RecipeBook) and new (RecipeX, Book) models during transition period
- **CloudKit Properties**: When importing into RecipeX/Book, initialize CloudKit sync properties correctly
- **Migration Tracking**: Show users how many legacy items remain to be migrated
- **Data Preservation**: Never lose data during model transitions
- **User Experience**: Make model differences transparent to users

## Status

**Current Phase**: Phase 1 Complete ✅, Phase 2 In Progress

**Phase 1 Completed**:
- ✅ RecipeBackupManager - Added RecipeX support
  - `createBackupX(from: [RecipeX])` - Export RecipeX models
  - `importBackupX(...existingRecipes: [RecipeX])` - Import as RecipeX with CloudKit
  - `createHybridBackup(recipes: [Recipe], recipesX: [RecipeX])` - Mixed export
- ✅ UserContentBackupView - Added RecipeX/Book queries and display
  - Queries both legacy and new models
  - Shows combined counts with breakdown
  - Export chooses correct strategy (legacy/new/hybrid)
  - Import creates RecipeX (not Recipe) with CloudKit sync enabled
- ⏸️ BookBackupManager - Deferred (existing book export works)

**Phase 2 In Progress**:
- ⏳ CloudKitSyncStatusMonitorView - Add RecipeX/Book monitoring
- ⏳ CloudKitDiagnosticsView - Add RecipeX/Book diagnostics  
- ⏳ QuickSyncStatusView - Show combined sync status

**Next Steps**:
1. Test backup/restore with both model types
2. Update CloudKit monitoring views (Phase 2)
3. Verify all Data & Sync features work with new models
