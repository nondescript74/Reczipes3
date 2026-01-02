# Recipe Book Import Guide

This guide explains how to import recipe books that have been shared from other users' devices.

## Overview

The recipe book import system allows users to receive and import complete recipe books (with all their recipes and images) that have been exported from another device using the Reczipes app.

## Components

### 1. RecipeBookImportService

The main service that handles importing recipe books.

**Key Features:**
- Preview recipe books before importing
- Check for conflicts with existing books
- Multiple import modes for handling conflicts
- Image import handling
- Version validation

**Usage:**

```swift
// Preview a recipe book file
let package = try await RecipeBookImportService.shared.previewBook(from: fileURL)

// Check if a book already exists
let existingBook = try RecipeBookImportService.shared.checkForExistingBook(
    bookID: package.book.id,
    modelContext: modelContext
)

// Import the book
let result = try await RecipeBookImportService.shared.importBook(
    from: fileURL,
    modelContext: modelContext,
    importMode: .keepBoth  // or .replace, .merge
)

print("Imported: \(result.book.name)")
print("Summary: \(result.summary)")
```

### 2. RecipeBookImportView

A SwiftUI view that provides a complete user interface for importing recipe books.

**Features:**
- File picker integration
- Preview of book contents before import
- Conflict resolution UI
- Progress indicator
- Success/error feedback

**Usage:**

```swift
// Present the import view as a sheet
.sheet(isPresented: $showingImport) {
    RecipeBookImportView()
}

// Or in a navigation stack
NavigationLink("Import Recipe Book") {
    RecipeBookImportView()
}
```

### 3. Import Modes

Three modes are available for handling existing books:

#### Keep Both (`.keepBoth`)
- Creates a new book with a new ID
- Appends "(Imported)" to the book name
- All recipes are created as new recipes
- No existing data is modified
- **Use when:** User wants to keep both versions

#### Replace (`.replace`)
- Deletes the existing book with the same ID
- Creates the imported book with original ID
- Updates or creates all recipes
- **Use when:** User wants the imported version to replace their current version

#### Merge (`.merge`)
- Keeps the existing book
- Adds new recipes to the existing book
- Updates recipes that already exist
- Preserves the existing book's metadata (name, description, etc.)
- **Use when:** User wants to combine recipes from both books

## Error Handling

The import service provides detailed error information through `RecipeBookImportError`:

```swift
do {
    let result = try await RecipeBookImportService.shared.importBook(...)
} catch let error as RecipeBookImportError {
    switch error {
    case .invalidFile:
        // Handle invalid file
    case .decodingFailed(let underlyingError):
        // Handle decoding errors
    case .existingBookConflict(let name):
        // Handle conflicts
    case .unsupportedVersion(let version):
        // Handle version incompatibility
    // ... other cases
    }
}
```

## File Format

Recipe books are exported as `.recipebook` files, which are ZIP archives containing:

1. **book.json** - Metadata about the book, recipes, and images
2. **Image files** - All referenced images (book cover and recipe images)

### File Structure:
```
MyRecipeBook.recipebook/
├── book.json           # Recipe book metadata
├── cover_image.jpg     # Book cover (if exists)
├── recipe1_main.jpg    # Recipe images
├── recipe1_step1.jpg
└── recipe2_main.jpg
```

## Integration Example

Here's a complete example of integrating recipe book import into your app:

```swift
struct RecipeBooksListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [RecipeBook]
    
    @State private var showingImport = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(books) { book in
                    NavigationLink(book.name, value: book)
                }
            }
            .navigationTitle("Recipe Books")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            // Create new book
                        } label: {
                            Label("New Book", systemImage: "plus")
                        }
                        
                        Button {
                            showingImport = true
                        } label: {
                            Label("Import Book", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingImport) {
                RecipeBookImportView()
            }
        }
    }
}
```

## Best Practices

### 1. Always Preview First
Always use the preview feature before importing to show users what they're about to import:

```swift
// Show preview
let preview = try await RecipeBookImportService.shared.previewBook(from: url)

// Display preview to user
Text(preview.book.name)
Text("\(preview.recipes.count) recipes")
Text("\(preview.imageManifest.count) images")
```

### 2. Handle Conflicts Gracefully
Check for existing books and let users decide how to handle conflicts:

```swift
let existing = try RecipeBookImportService.shared.checkForExistingBook(
    bookID: preview.book.id,
    modelContext: modelContext
)

if existing != nil {
    // Show conflict resolution UI
    // Let user choose: keepBoth, replace, or merge
}
```

### 3. Provide Feedback
Always show progress and results to the user:

```swift
// Show loading state
ProgressView("Importing...")

// Show results
let result = try await service.importBook(...)
Text("Successfully imported: \(result.book.name)")
Text(result.summary)  // "5 new recipes, 12 images"
```

### 4. Clean Up Temporary Files
The service handles most cleanup, but ensure you remove any temp files:

```swift
defer {
    try? FileManager.default.removeItem(at: tempURL)
}
```

## Sharing Recipe Books Between Users

To share a recipe book:

1. **Export:** User A exports their recipe book using `RecipeBookExportService`
2. **Transfer:** The `.recipebook` file is shared via AirDrop, email, messaging, etc.
3. **Import:** User B receives the file and uses the import functionality
4. **Choose Mode:** User B decides how to handle any conflicts

## Advanced Usage

### Custom Import Logic

If you need custom import behavior, you can use the service directly:

```swift
// Custom import with special handling
let preview = try await RecipeBookImportService.shared.previewBook(from: url)

// Apply custom logic
let importMode: RecipeBookImportMode
if preview.recipes.count > 100 {
    importMode = .keepBoth  // Large books always create new
} else if existingBook != nil {
    importMode = .merge     // Small books merge by default
} else {
    importMode = .keepBoth
}

let result = try await RecipeBookImportService.shared.importBook(
    from: url,
    modelContext: modelContext,
    importMode: importMode
)
```

### Batch Import

To import multiple books:

```swift
func importMultipleBooks(_ urls: [URL]) async throws -> [RecipeBookImportResult] {
    var results: [RecipeBookImportResult] = []
    
    for url in urls {
        let result = try await RecipeBookImportService.shared.importBook(
            from: url,
            modelContext: modelContext,
            importMode: .keepBoth
        )
        results.append(result)
    }
    
    return results
}
```

## Troubleshooting

### Common Issues

**Issue:** "Invalid or corrupted backup file"
- **Cause:** File is not a valid .recipebook file
- **Solution:** Ensure the file was exported correctly and wasn't corrupted during transfer

**Issue:** "Unsupported version"
- **Cause:** The recipe book was exported from a newer version of the app
- **Solution:** Update the app to the latest version

**Issue:** "Failed to import images"
- **Cause:** Insufficient storage or file permissions
- **Solution:** Check available storage space and app permissions

**Issue:** Recipes appear but without images
- **Cause:** Images failed to copy
- **Solution:** Check the image manifest and verify files exist in the archive

## See Also

- `RecipeBookExportService` - For exporting recipe books
- `RecipeBackupManager` - For backing up individual recipes
- `RECIPE_BOOK_EXPORT_GUIDE.md` - Export functionality guide
