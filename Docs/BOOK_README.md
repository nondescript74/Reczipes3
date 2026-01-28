# Book Model - Unified Book System for Reczipes2

## Overview

The `Book` model is a unified, CloudKit-compatible data structure that combines the functionality of `RecipeBook`, `SharedRecipeBook`, and CloudKit recipe book models into a single, powerful model with automatic iCloud sharing.

## Design Philosophy

### Local-First Architecture
- All books are stored locally in SwiftData
- Works offline with full functionality
- Changes sync to iCloud when online

### Auto-Sync to CloudKit
- Books automatically sync to iCloud Public Database
- Other users can discover and download shared books
- Recipes sync across user's devices via CloudKit

### Always Shareable
- Books can be toggled between shared and private
- Shared books are discoverable by all users
- Private books remain on the user's device only

### Simple & Unified
- One model, one source of truth
- No separate tracking models needed
- Automatic migration from legacy models

## Key Features

### Rich Content Support
Books can contain:
- **Recipes**: References to `RecipeX` models with lightweight previews
- **Images**: Standalone images with captions and descriptions
- **Instructions**: How-to guides, cooking techniques, equipment guides
- **Glossary**: Ingredient definitions, cooking terms, technique explanations
- **Custom Content**: Notes, stories, tips, warnings, and more
- **Table of Contents**: Organized sections for easy navigation

### Metadata & Organization
- Color themes for visual identification
- Tags for categorization
- Category and cuisine classification
- Version tracking for conflict resolution
- Content fingerprinting for duplicate detection

### Sharing & Attribution
- User attribution (owner, shared by)
- Download and view statistics
- Privacy levels (public, friends, private)
- Import tracking (distinguish owned vs. imported books)

### Sync Management
- Automatic change detection
- Retry logic for failed syncs
- Sync error tracking
- Manual sync triggering

## Usage Examples

### Creating a New Book

```swift
import SwiftData

// Basic book creation
let book = Book(
    name: "My Italian Cookbook",
    bookDescription: "Family recipes from Tuscany",
    color: "#FF5733",
    needsCloudSync: true,
    isShared: true
)

modelContext.insert(book)
try modelContext.save()
```

### Adding Content to a Book

```swift
// Add recipes
book.addRecipe(recipeID)

// Add images
var images = book.images
images.append(BookImage(
    id: UUID(),
    title: "Tuscan Countryside",
    caption: "Where these recipes come from",
    imageData: imageData,
    order: images.count,
    dateAdded: Date()
))
book.setImages(images)

// Add instruction guide
var instructions = book.instructions
instructions.append(BookInstruction(
    id: UUID(),
    title: "How to Make Fresh Pasta",
    content: "Step by step guide to making pasta from scratch...",
    imageData: pastaImageData,
    order: instructions.count,
    category: "Techniques",
    dateAdded: Date()
))
book.setInstructions(instructions)

// Add glossary entry
var glossary = book.glossary
glossary.append(BookGlossaryEntry(
    id: UUID(),
    term: "Al Dente",
    definition: "Cooked to be firm to the bite",
    imageData: nil,
    relatedTerms: ["Pasta", "Cooking"],
    order: glossary.count,
    dateAdded: Date()
))
book.setGlossary(glossary)
```

### Querying Books

```swift
import SwiftData

// Get all books
@Query var books: [Book]

// Get only user's own books
@Query(
    filter: #Predicate<Book> { book in
        book.isImported == false
    },
    sort: \Book.dateModified,
    order: .reverse
) var ownedBooks: [Book]

// Get shared books
@Query(
    filter: #Predicate<Book> { book in
        book.isShared == true
    }
) var sharedBooks: [Book]

// Get books needing sync
@Query(
    filter: #Predicate<Book> { book in
        book.needsCloudSync == true
    }
) var needsSyncBooks: [Book]

// Get books by category
@Query(
    filter: #Predicate<Book> { book in
        book.category == "Desserts"
    }
) var dessertBooks: [Book]
```

### Managing Sharing

```swift
// Toggle sharing
book.toggleSharing()
try modelContext.save()

// Check sharing status
if book.isShared == true {
    print("Book is shared to CloudKit")
}

if book.isSynced {
    print("Book is synced: \(book.cloudRecordID ?? "unknown")")
}

// Check if needs sync
if book.needsCloudSync == true {
    // Trigger sync via your sync service
    await bookSyncService.sync(book)
}
```

### Accessing Book Statistics

```swift
let stats = book.statistics

print("Recipes: \(stats.totalRecipes)")
print("Images: \(stats.totalImages)")
print("Instructions: \(stats.totalInstructions)")
print("Glossary: \(stats.totalGlossaryEntries)")
print("Size: \(stats.formattedSize)")
print("Views: \(stats.viewCount)")
print("Downloads: \(stats.downloadCount)")
```

### Working with Recipes

```swift
// Add recipe
book.addRecipe(recipeX.id ?? UUID())

// Remove recipe
book.removeRecipe(recipeID)

// Reorder recipes
book.moveRecipe(from: IndexSet(integer: 0), to: 5)

// Get recipe count
let count = book.recipeCount

// Access recipe previews
for preview in book.recipePreviews {
    print("\(preview.title) - \(preview.yield ?? "No yield")")
}
```

## Migration from Legacy Models

### Automatic Migration

Use `BookMigrationManager` to migrate from old models:

```swift
let migrationManager = BookMigrationManager(modelContext: modelContext)

// Check if migration needed
if migrationManager.needsMigration() {
    // Get migration stats
    let stats = migrationManager.getMigrationStats()
    print("Will migrate \(stats.totalLegacyBooks) books")
    
    // Perform migration
    let result = try await migrationManager.performMigration(deleteOldRecords: true)
    print(result.summary)
    
    // Validate migration
    let validation = try await migrationManager.validateMigration()
    print(validation.summary)
}
```

### Manual Migration

```swift
// Migrate single RecipeBook
let book = try migrationManager.migrateRecipeBook(recipeBook)

// Migrate single SharedRecipeBook
let importedBook = try migrationManager.migrateSharedRecipeBook(sharedBook)
```

## CloudKit Integration

### Converting to CloudKit Record

```swift
let record = book.toCloudKitRecord()
// Returns [String: Any] dictionary ready for CloudKit
```

### CloudKit-Compatible Structures

```swift
// Create CloudKit representation
let cloudBook = CloudKitBook(
    id: book.id ?? UUID(),
    name: book.name ?? "",
    bookDescription: book.bookDescription,
    color: book.color,
    recipeIDs: book.recipeIDs ?? [],
    recipePreviews: book.recipePreviews,
    images: book.images,
    instructions: book.instructions,
    glossary: book.glossary,
    customContent: book.customContent,
    tableOfContents: book.tableOfContents,
    category: book.category,
    cuisine: book.cuisine,
    tags: book.tags,
    version: book.version ?? 1,
    dateCreated: book.dateCreated ?? Date(),
    dateModified: book.dateModified ?? Date(),
    ownerUserID: book.ownerUserID ?? "",
    ownerDisplayName: book.ownerDisplayName,
    sharedDate: book.sharedDate ?? Date(),
    privacyLevel: book.privacyLevel ?? "public"
)
```

### Download Options

```swift
// Preview only (lightweight)
let previewOptions = BookDownloadOptions.preview

// Full download
let fullOptions = BookDownloadOptions.full

// Offline mode
let offlineOptions = BookDownloadOptions.offline

// Custom options
var customOptions = BookDownloadOptions()
customOptions.downloadFullRecipes = true
customOptions.downloadHighResImages = false
customOptions.maxImageSize = 5_000_000 // 5 MB
```

### Sharing Configuration

```swift
// Public sharing
let publicConfig = BookSharingConfiguration.public

// Friends only
let friendsConfig = BookSharingConfiguration.friends

// Minimal sharing (smaller file size)
let minimalConfig = BookSharingConfiguration.minimal

// Custom configuration
var customConfig = BookSharingConfiguration()
customConfig.shareFullRecipes = true
customConfig.includeHighResCover = true
customConfig.imageQuality = 0.9
customConfig.privacyLevel = .public
```

## Data Structures

### BookRecipePreview
Lightweight recipe data for quick display without loading full recipes.

```swift
struct BookRecipePreview: Codable, Identifiable {
    let id: UUID
    let title: String
    let thumbnailData: Data?
    let yield: String?
    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?
}
```

### BookImage
Standalone images in the book (not recipe photos).

```swift
struct BookImage: Codable, Identifiable {
    let id: UUID
    let title: String?
    let caption: String?
    let imageData: Data
    let order: Int
    let dateAdded: Date
}
```

### BookInstruction
How-to guides, techniques, equipment guides.

```swift
struct BookInstruction: Codable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let imageData: Data?
    let order: Int
    let category: String? // "Techniques", "Equipment", "Tips"
    let dateAdded: Date
}
```

### BookGlossaryEntry
Cooking terms and ingredient definitions.

```swift
struct BookGlossaryEntry: Codable, Identifiable {
    let id: UUID
    let term: String
    let definition: String
    let imageData: Data?
    let relatedTerms: [String]?
    let order: Int
    let dateAdded: Date
}
```

### BookContentItem
Custom content (notes, stories, tips, warnings).

```swift
struct BookContentItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let contentType: String // "note", "story", "tip", "warning"
    let content: String
    let imageData: Data?
    let order: Int
    let dateAdded: Date
}
```

### BookSection
Table of contents organization.

```swift
struct BookSection: Codable, Identifiable {
    let id: UUID
    let title: String
    let order: Int
    let itemType: String // "recipe", "image", "instruction", "glossary", "custom"
    let itemID: UUID
}
```

## Best Practices

### Performance

1. **Use Previews**: Store lightweight recipe previews instead of full recipes for better performance
2. **Compress Images**: Use appropriate image quality settings (0.7-0.8 is usually good)
3. **Lazy Loading**: Load content on demand rather than all at once
4. **External Storage**: Cover images use `@Attribute(.externalStorage)` automatically

### Data Management

1. **Mark Modified**: Always call `book.markModified()` after changes
2. **Mark Accessed**: Call `book.markAccessed()` when viewing to track usage
3. **Version Control**: Book version increments automatically on modifications
4. **Fingerprinting**: Content fingerprints help detect duplicates

### Sharing

1. **Set Owner Info**: Always set `ownerUserID` and `ownerDisplayName` when creating
2. **Privacy Levels**: Use appropriate privacy level for content
3. **Sharing Toggle**: Use `toggleSharing()` method to properly manage sharing state
4. **Sync Management**: Check `needsCloudSync` before uploading

### Migration

1. **Test First**: Use `needsMigration()` before performing migration
2. **Validate After**: Always validate migration with `validateMigration()`
3. **Backup**: Keep old records until migration is validated
4. **Incremental**: Consider migrating in batches for large datasets

## Error Handling

```swift
do {
    book.addRecipe(recipeID)
    try modelContext.save()
} catch {
    print("Failed to add recipe: \(error.localizedDescription)")
}

// Handle sync errors
if let syncError = book.lastSyncError {
    print("Sync error: \(syncError)")
    
    // Retry if needed
    if (book.syncRetryCount ?? 0) < 3 {
        // Trigger retry
    } else {
        // Give up after 3 retries
        print("Max retries exceeded")
    }
}
```

## SwiftUI Integration

See `BookExampleView.swift` for a complete working example including:
- Book list with filtering
- Book creation form
- Book detail view
- Content management
- Migration UI
- Sharing controls

## Files

- **Book.swift**: Core model definition
- **BookCloudKitModels.swift**: CloudKit structures and helpers
- **BookMigrationManager.swift**: Migration from legacy models
- **BookExampleView.swift**: Complete SwiftUI example

## Future Enhancements

Potential additions:
- Collaborative editing
- Book templates
- Export to PDF/ePub
- Book analytics dashboard
- Social features (comments, ratings)
- Book collections/series
- Advanced search and filtering
