# Multiple Images Quick Reference Guide

## For Developers

### Adding Additional Images to a Recipe

```swift
// Get the recipe entity
guard let recipeEntity = savedRecipes.first(where: { $0.id == recipeID }) else { return }

// Initialize array if needed
var additionalImages = recipeEntity.additionalImageNames ?? []

// Add new image filename
additionalImages.append("recipe_\(recipeID)_additional_\(timestamp)_\(random).jpg")

// Update the recipe
recipeEntity.additionalImageNames = additionalImages

// Save
try? modelContext.save()
```

### Removing an Additional Image

```swift
// Get the recipe entity
guard let recipeEntity = savedRecipes.first(where: { $0.id == recipeID }),
      var additionalImages = recipeEntity.additionalImageNames,
      index < additionalImages.count else { return }

// Get the filename
let filename = additionalImages[index]

// Delete the file
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let fileURL = documentsPath.appendingPathComponent(filename)
try? FileManager.default.removeItem(at: fileURL)

// Remove from array
additionalImages.remove(at: index)
recipeEntity.additionalImageNames = additionalImages.isEmpty ? nil : additionalImages

// Save
try? modelContext.save()
```

### Displaying All Images

```swift
// Option 1: Use the computed property on Recipe
let allImages = recipe.allImageNames
// Returns: [String] with main image first, then additional

// Option 2: Manual concatenation
var images: [String] = []
if let main = recipe.imageName {
    images.append(main)
}
if let additional = recipe.additionalImageNames {
    images.append(contentsOf: additional)
}
```

### Loading an Image from Documents

```swift
func loadImageFromDocuments(_ filename: String) -> UIImage? {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsPath.appendingPathComponent(filename)
    
    guard let data = try? Data(contentsOf: fileURL) else {
        return nil
    }
    
    return UIImage(data: data)
}
```

## For Users

### How to Add Multiple Images to a Recipe

1. **Open Recipe Images**
   - Tap the settings or photos icon in your app
   - Select "Recipe Images"

2. **Select a Recipe**
   - Find the recipe you want to add images to
   - You'll see the main image (marked with "MAIN" badge)

3. **Add More Images**
   - Tap the blue **[+]** button next to the recipe
   - Tap any photos you want to add (they'll show a blue border and checkmark)
   - You can select multiple photos at once
   - Tap photos again to deselect them

4. **Confirm Your Selection**
   - Tap **"Add X"** at the top right (where X is the number selected)
   - The photos will be saved and appear below the main image

5. **Remove Images**
   - Tap the **[X]** button on any additional image to remove it
   - The main image cannot be removed (it was set when you first extracted the recipe)

### Tips

- **Main Image**: The main image is automatically set when you extract a recipe. It cannot be changed from the Recipe Images screen.

- **Multiple Selection**: You don't have to select photos next to each other. Tap any photos you want, even if they're scattered throughout your library.

- **Scrolling**: If a recipe has many additional images, you can scroll horizontally to see them all.

- **No Limit**: You can add as many additional images as you want to a recipe.

## Model Properties Reference

### Recipe (@Model)

```swift
// Main image (set during extraction, immutable in UI)
var imageName: String?

// Additional images (user-added, mutable)
var additionalImageNames: [String]?

// Computed properties
var allImageNames: [String]        // Combined array
var imageCount: Int                 // Total count
```

### RecipeModel (struct)

```swift
// Main image
var imageName: String?

// Additional images
var additionalImageNames: [String]?

// Computed properties
var allImageNames: [String]        // Combined array
var imageCount: Int                 // Total count
```

## File Naming Conventions

### Main Image
```
recipe_<UUID>.jpg
```
Example:
```
recipe_12345678-1234-5678-1234-567812345678.jpg
```

### Additional Images
```
recipe_<UUID>_additional_<timestamp>_<random>.jpg
```
Example:
```
recipe_12345678-1234-5678-1234-567812345678_additional_1702987654_1234.jpg
```

## Common Tasks

### Check if Recipe Has Images

```swift
// Check for main image
let hasMainImage = recipe.imageName != nil

// Check for additional images
let hasAdditionalImages = recipe.additionalImageNames?.isEmpty == false

// Get total count
let totalImageCount = recipe.imageCount
```

### Display Image Count in UI

```swift
Text("Main image + \(recipe.additionalImageNames?.count ?? 0) more")
```

### Create Image Gallery View

```swift
ScrollView(.horizontal) {
    HStack {
        ForEach(recipe.allImageNames, id: \.self) { imageName in
            if let image = loadImageFromDocuments(imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
        }
    }
}
```

## SwiftData Query Examples

### Get All Recipes with Images

```swift
@Query(filter: #Predicate<Recipe> { 
    $0.imageName != nil 
}) var recipesWithImages: [Recipe]
```

### Get Recipes with Multiple Images

```swift
// Note: Cannot use complex array checks in SwiftData predicates
// Filter in code instead:
let recipesWithMultiple = savedRecipes.filter { 
    $0.imageCount > 1 
}
```

### Get Recipes Without Images

```swift
@Query(filter: #Predicate<Recipe> { 
    $0.imageName == nil 
}) var recipesWithoutImages: [Recipe]
```

## Migration Scenarios

### Existing Recipe Without Images (Pre-Refactor)
- `imageName` = nil
- `additionalImageNames` = nil (SwiftData auto-adds this field)
- ✅ **Can add images**: When user adds first image, array is created automatically
- No migration code needed

### Existing Recipe With Main Image Only (Pre-Refactor)
- `imageName` = "recipe_XXX.jpg" (exists from before refactor)
- `additionalImageNames` = nil (SwiftData auto-adds this field)
- ✅ **Can add additional images**: Array created on first add
- Main image remains unchanged and protected

### New Recipe Created After Refactor
- `imageName` = set during extraction
- `additionalImageNames` = nil initially
- Array is populated when user adds images

### How It Works Automatically

When you access an old recipe:

```swift
// SwiftData automatically adds the new field with default value (nil)
let oldRecipe: Recipe  // Saved before refactor
print(oldRecipe.additionalImageNames)  // nil (not an error!)

// When user adds first image:
var additional = oldRecipe.additionalImageNames ?? []  // Creates empty array
additional.append("new_image.jpg")
oldRecipe.additionalImageNames = additional  // Sets the array
try? modelContext.save()  // Recipe is now "upgraded"

// Next time you load this recipe:
print(oldRecipe.additionalImageNames)  // [new_image.jpg]
```

**Key Point**: SwiftData's schema evolution automatically handles the new optional property without requiring migration code or breaking existing data.

## Troubleshooting

### Images Not Appearing

1. **Check file exists**:
```swift
let fileURL = documentsPath.appendingPathComponent(imageName)
print("File exists: \(FileManager.default.fileExists(atPath: fileURL.path))")
```

2. **Check filename is correct**:
```swift
print("Image filename: \(recipe.imageName ?? "nil")")
print("Additional images: \(recipe.additionalImageNames ?? [])")
```

3. **Check Documents directory**:
```swift
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
print("Documents path: \(documentsPath)")
```

### Images Not Saving

1. **Check JPEG conversion**:
```swift
guard let data = image.jpegData(compressionQuality: 0.8) else {
    print("❌ Failed to convert image to JPEG")
    return false
}
```

2. **Check write permissions**:
```swift
do {
    try data.write(to: fileURL)
    print("✅ Image saved successfully")
} catch {
    print("❌ Error saving image: \(error)")
}
```

3. **Check modelContext save**:
```swift
do {
    try modelContext.save()
    print("✅ Context saved")
} catch {
    print("❌ Error saving context: \(error)")
}
```

## Performance Tips

1. **Use Thumbnails for Lists**: Load full-resolution images only when needed
2. **Lazy Loading**: Use `LazyVGrid` and `LazyHStack` for large image collections
3. **Async Loading**: Always load images asynchronously to avoid blocking UI
4. **Cache Thumbnails**: The `PhotoLibraryManager` already caches thumbnails
5. **Compression**: Use 0.8 quality for JPEG to balance size and quality

## Security Considerations

1. **Photo Library Permissions**: Always check authorization status
2. **Sandboxed Storage**: Images stored in app's Documents directory
3. **File Cleanup**: Remove files when images are deleted from recipes
4. **No External Access**: Images not shared outside the app unless user exports
## Backward Compatibility

### Why Old Recipes Work Automatically

SwiftData's **schema evolution** handles the new `additionalImageNames` property automatically:

1. **Adding Optional Properties**: When you add an optional property to a `@Model` class, SwiftData automatically adds it to existing records with a `nil` default value.

2. **No Breaking Changes**: Existing recipes continue to work because:
   - The new field is **optional** (`[String]?`)
   - All code uses **nil-coalescing** (`?? []` or `?? 0`)
   - SwiftData handles the schema update transparently

3. **Gradual Upgrade**: Recipes are "upgraded" only when the user adds images:
   ```swift
   Before user adds image:  additionalImageNames = nil
   After user adds image:   additionalImageNames = ["image1.jpg"]
   ```

### Testing Backward Compatibility

To verify old recipes work:

```swift
// Simulate old recipe (pre-refactor)
let oldRecipe = Recipe(
    id: UUID(),
    title: "Old Recipe",
    // ... other required fields
    // DON'T set additionalImageNames - simulates old data
)
modelContext.insert(oldRecipe)
try? modelContext.save()

// Later, try to add images through RecipeImageAssignmentView
// Should work without errors
```

### What If SwiftData Schema Migration Fails?

In the rare case of schema migration issues:

```swift
// Add explicit default value in Recipe init
init(id: UUID = UUID(),
     title: String,
     // ... other parameters
     additionalImageNames: [String]? = nil) {  // ← Explicit default
    // ...
    self.additionalImageNames = additionalImageNames
}
```

This is already in place, so backward compatibility is guaranteed.

### Migration from RecipeImageAssignment

If you were previously using the `RecipeImageAssignment` model:

```swift
// Optional: Migrate old assignments to new schema
func migrateOldAssignments() {
    let assignments = try? modelContext.fetch(FetchDescriptor<RecipeImageAssignment>())
    
    for assignment in assignments ?? [] {
        guard let recipe = savedRecipes.first(where: { $0.id == assignment.recipeID }) else {
            continue
        }
        
        // If recipe doesn't have the image set, set it as main
        if recipe.imageName == nil {
            recipe.imageName = assignment.imageName
        } else if recipe.imageName != assignment.imageName {
            // Different image - add as additional
            var additional = recipe.additionalImageNames ?? []
            additional.append(assignment.imageName)
            recipe.additionalImageNames = additional
        }
        
        // Delete old assignment
        modelContext.delete(assignment)
    }
    
    try? modelContext.save()
}
```

**Note**: This migration is optional. The new code doesn't depend on `RecipeImageAssignment` at all.

