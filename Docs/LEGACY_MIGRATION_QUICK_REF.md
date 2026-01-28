# Legacy Migration Quick Reference

## Quick Start

```swift
// 1. Check if migration is needed
let manager = LegacyToNewMigrationManager(modelContext: modelContext)
let needsMigration = await manager.needsMigration()

// 2. Get statistics
let stats = await manager.getMigrationStats()
print("Legacy recipes: \(stats.legacyRecipeCount)")
print("Legacy books: \(stats.legacyBookCount)")

// 3. Perform migration
do {
    let result = try await manager.performMigration(
        deleteLegacyData: false,  // Keep legacy data (safe)
        skipCloudSync: false       // Enable CloudKit sync
    )
    
    if result.isSuccess {
        print("✅ Migration successful!")
        print("Recipes: \(result.recipesSuccess)")
        print("Books: \(result.booksSuccess)")
    }
} catch {
    print("❌ Migration failed: \(error)")
}
```

## Common Tasks

### Show Migration UI
```swift
@State private var showingMigration = false

Button("Migrate") {
    showingMigration = true
}
.sheet(isPresented: $showingMigration) {
    LegacyMigrationView()
}
```

### Check Migration Status
```swift
if manager.isMigrationCompleted {
    print("Migration completed on: \(manager.migrationDate)")
}
```

### Reset Migration (Testing)
```swift
manager.resetMigrationStatus()
```

### Migrate Single Item
```swift
let recipe: Recipe = // your recipe
let recipeX = try await manager.migrateRecipe(recipe)

let book: RecipeBook = // your book
let newBook = try await manager.migrateBook(book)
```

## API Reference

### LegacyToNewMigrationManager

| Method | Returns | Description |
|--------|---------|-------------|
| `needsMigration()` | `Bool` | Check if migration needed |
| `getMigrationStats()` | `MigrationStats` | Get counts of legacy/new items |
| `performMigration(deleteLegacyData:skipCloudSync:)` | `MigrationResult` | Perform full migration |
| `migrateRecipe(_:)` | `RecipeX` | Migrate single recipe |
| `migrateBook(_:)` | `Book` | Migrate single book |
| `resetMigrationStatus()` | `Void` | Reset for re-testing |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isMigrationCompleted` | `Bool` | Whether migration was completed |
| `migrationDate` | `Date?` | When migration was completed |
| `migrationVersion` | `Int` | Version of completed migration |

## Data Structures

### MigrationStats
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
```swift
struct MigrationResult {
    var recipesSuccess: Int          // Successfully migrated
    var recipesSkipped: Int          // Already existed
    var recipesError: Error?         // Error during migration
    
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

### MigrationValidation
```swift
struct MigrationValidation {
    var isValid: Bool
    var errors: [String]
    var warnings: [String]
    
    var hasWarnings: Bool
    var summary: String
    var detailedSummary: String
}
```

## Error Handling

```swift
do {
    let result = try await manager.performMigration()
    
    if result.hasErrors {
        print("Errors occurred:")
        if let error = result.recipesError {
            print("Recipes: \(error)")
        }
        if let error = result.booksError {
            print("Books: \(error)")
        }
    }
    
    if let validation = result.validation, !validation.isValid {
        print("Validation errors:")
        validation.errors.forEach { print("  • \($0)") }
    }
} catch {
    print("Migration failed: \(error)")
}
```

## UI Components

### Migration Badge
```swift
// Shows in toolbar when migration needed
MigrationBadgeView()
```

### Migration View
```swift
// Full migration UI
LegacyMigrationView()
```

## Logging

Category: `LegacyMigration`
Subsystem: `com.reczipes2`

```swift
// View logs in Console.app
// Filter: subsystem:com.reczipes2 category:LegacyMigration
```

## Testing

### Setup Test Data
```swift
// Create legacy recipes
let recipe1 = Recipe(title: "Test Recipe 1")
modelContext.insert(recipe1)

let recipe2 = Recipe(title: "Test Recipe 2")
modelContext.insert(recipe2)

// Create legacy book
let book = RecipeBook(
    id: UUID(),
    name: "Test Book",
    recipeIDs: [recipe1.id, recipe2.id]
)
modelContext.insert(book)

try modelContext.save()
```

### Run Migration
```swift
let manager = LegacyToNewMigrationManager(modelContext: modelContext)
let result = try await manager.performMigration(skipCloudSync: true)
```

### Verify Results
```swift
// Check RecipeX
let recipeXDesc = FetchDescriptor<RecipeX>()
let recipesX = try modelContext.fetch(recipeXDesc)
print("RecipeX count: \(recipesX.count)")

// Check Book
let bookDesc = FetchDescriptor<Book>()
let books = try modelContext.fetch(bookDesc)
print("Book count: \(books.count)")

// Verify recipe references in book
if let book = books.first {
    print("Book has \(book.recipeCount) recipes")
    print("Recipe IDs: \(book.recipeIDs ?? [])")
}
```

### Cleanup
```swift
// Delete migrated data
recipesX.forEach { modelContext.delete($0) }
books.forEach { modelContext.delete($0) }

// Reset migration status
manager.resetMigrationStatus()

try modelContext.save()
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Badge not showing | Check `needsMigration()` returns true |
| Migration fails | Check error in result, review logs |
| Duplicates skipped | Normal - already migrated |
| Validation errors | Review `validation.errors` array |
| CloudKit not syncing | Check `needsCloudSync` flag set |

## Best Practices

1. ✅ **Always test first**
   ```swift
   let stats = await manager.getMigrationStats()
   print(stats.summary)  // Review before migrating
   ```

2. ✅ **Keep legacy data initially**
   ```swift
   let result = try await manager.performMigration(
       deleteLegacyData: false  // Safe option
   )
   ```

3. ✅ **Check validation**
   ```swift
   if let validation = result.validation {
       guard validation.isValid else {
           print("Validation failed!")
           return
       }
   }
   ```

4. ✅ **Monitor CloudKit**
   ```swift
   // After migration, watch CloudKitSyncBadge
   // Verify recipes appear on other devices
   ```

5. ✅ **Delete legacy later**
   ```swift
   // After confirming everything works (days/weeks later)
   try await manager.performMigration(deleteLegacyData: true)
   ```

## SwiftUI Integration

### In ContentView
```swift
@State private var showingMigration = false

// In toolbar
Button {
    showingMigration = true
} label: {
    Label("Migrate", systemImage: "arrow.triangle.2.circlepath.circle")
}
.sheet(isPresented: $showingMigration) {
    LegacyMigrationView()
}

// Or use badge
MigrationBadgeView()
```

### In App Startup
```swift
// Reczipes2App.swift
.onAppear {
    Task {
        await checkLegacyMigration()
    }
}

private func checkLegacyMigration() async {
    let manager = LegacyToNewMigrationManager(modelContext: modelContext)
    let needsMigration = await manager.needsMigration()
    
    if needsMigration {
        logInfo("Legacy migration available", category: "migration")
    }
}
```

## Performance

- **Small datasets** (< 100 items): < 1 second
- **Medium datasets** (100-500 items): 1-5 seconds  
- **Large datasets** (500+ items): 5-10 seconds

Migration runs on background queue, UI remains responsive.

## CloudKit Sync

After migration:
- RecipeX models marked with `needsCloudSync = true`
- Background service picks up changes
- Uploads to CloudKit Public Database
- Syncs across user's devices
- Other users can discover shared recipes

## Further Reading

- **LEGACY_MIGRATION_GUIDE.md** - Comprehensive guide
- **LEGACY_MIGRATION_SUMMARY.md** - Implementation details
- **RecipeX.swift** - New recipe model
- **Book.swift** - New book model

---

**Questions?** Check the full guides or contact the developer.
