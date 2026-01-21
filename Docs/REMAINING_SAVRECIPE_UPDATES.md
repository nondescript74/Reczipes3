# Remaining saveRecipe Methods to Update

Based on your Xcode search results screenshot, here are the files that still have `saveRecipe` methods that may need updating:

## Priority 1: Critical - Likely Have Image Saving Code ⚠️

### 1. RecipeExtractorView.swift
**Methods Found**:
- `await downloadAndSaveRecipe(imageURLs: selectedWebImageURLs)`
- `saveRecipe()`
- Multiple other `saveRecipe` variants

**Why Critical**: This is likely your **main single-image extraction view** - probably the most commonly used extraction method in your app!

**What to Check**:
- Does it save images to Documents directory?
- Does it use `saveImageToDisk()`?
- Does it set `recipe.imageName` directly?

**How to Update**:
```swift
// Find code like this:
let imageName = "recipe_\(uuid).jpg"
recipe.imageName = imageName
saveImageToDisk(image, filename: imageName)

// Replace with:
recipe.setImage(image, isMainImage: true)
```

### 2. RecipeExtractorViewModel.swift
**Methods Found**:
- `private func saveRecipe(_ recipeModel:, images: [UIImage], link: SavedLink, modelContext:) async throws`
- Similar signature to BatchExtractionManager

**Why Critical**: ViewModel for recipe extraction - handles the data layer

**What to Check**:
- Similar to BatchExtractionManager, probably has file-based image saving
- May have `saveImageToDisk()` helper method

**How to Update**:
- Follow the same pattern we used for `BatchExtractionManager.swift`
- Replace file writing with `recipe.setImage()`

### 3. RecipeExtractorWithImageView.swift
**Methods Found**:
- `private func saveRecipe(Image(_ image: UIImage, for recipeID: UUID, isMainImage: Bool = false, imageIndex: Int = 0))`

**Why Critical**: Specifically handles image saving!

**What to Check**:
- This is **definitely** saving images
- Probably writes to Documents directory

**How to Update**:
```swift
// OLD:
private func saveRecipe(Image(_ image: UIImage, for recipeID: UUID, isMainImage: Bool = false, imageIndex: Int = 0) {
    let imageName = "recipe_\(recipeID)_\(imageIndex).jpg"
    saveImageToDisk(image, filename: imageName)
}

// NEW:
private func saveRecipe(Image(_ image: UIImage, for recipe: Recipe, isMainImage: Bool = true) {
    recipe.setImage(image, isMainImage: isMainImage)
}
```

## Priority 2: Medium - May Have Image Code

### 4. RecipeDetailView.swift
**Methods Found**:
- `saveRecipeWithTips()`
- `private func saveRecipeDirectly(...)`
- `private func saveRecipeDirectly(modifiedRecipe:, modelContext:)`

**Why Medium**: Handles editing existing recipes, may add images

**What to Check**:
- Does it allow adding/changing recipe images?
- If yes, does it use file-based saving?

### 5. ContentView.swift
**Methods Found**:
- `onSave: { saveRecipe(recipe) }`

**Why Medium**: Might just be calling other save methods

**What to Check**:
- Is this calling another `saveRecipe` function?
- Or does it have its own image saving logic?

## Priority 3: Low - Probably Just References

### 6. RecipeSearchView.swift
**Methods Found**:
- `private func saveRecipe(_ recipe: RecipeModel)`

**Why Low**: Search view probably just inserts recipes, no images

### 7. RecipeExtractorWithSaveView.swift
**Status**: ✅ **Already checked - no image saving**

This is a simple wrapper that just inserts the recipe without handling images.

## How to Proceed

### Step 1: Check Each File

For each Priority 1 file, use Xcode's "Find" (Cmd+F) within that file to search for:

1. `FileManager.default.urls(for: .documentDirectory` - File writing
2. `recipe.imageName =` - Direct imageName assignment
3. `saveImageToDisk` - Old helper method
4. `.write(to: fileURL)` - Image file writing

### Step 2: Update Pattern

When you find image saving code, update it to:

```swift
// Main image
recipe.setImage(mainImage, isMainImage: true)

// Additional images
for image in additionalImages {
    recipe.setImage(image, isMainImage: false)
}
```

### Step 3: Test Each Method

After updating each file:

1. Build the project (Cmd+B)
2. Test that specific extraction method
3. Verify images appear
4. Check another device for CloudKit sync

## Detailed Update Instructions

### For RecipeExtractorView.swift (Most Important!)

This file likely has the **most commonly used** extraction code. Here's what to look for:

**Pattern 1: Download and Save from URL**
```swift
// OLD CODE:
await downloadAndSaveRecipe(imageURLs: selectedWebImageURLs) {
    for (index, imageURL) in imageURLs.enumerated() {
        let image = try await downloadImage(from: imageURL)
        let filename = "recipe_\(uuid)_\(index).jpg"
        saveImageToDisk(image, filename: filename)
    }
}

// NEW CODE:
await downloadAndSaveRecipe(imageURLs: selectedWebImageURLs) {
    for (index, imageURL) in imageURLs.enumerated() {
        let image = try await downloadImage(from: imageURL)
        if index == 0 {
            recipe.setImage(image, isMainImage: true)
        } else {
            recipe.setImage(image, isMainImage: false)
        }
    }
}
```

**Pattern 2: Save from Camera/Photos**
```swift
// OLD CODE:
func saveRecipe() {
    let recipe = Recipe(from: recipeModel)
    if let image = capturedImage {
        let filename = "recipe_\(recipe.id).jpg"
        recipe.imageName = filename
        saveImageToDisk(image, filename: filename)
    }
    modelContext.insert(recipe)
}

// NEW CODE:
func saveRecipe() {
    let recipe = Recipe(from: recipeModel)
    if let image = capturedImage {
        recipe.setImage(image, isMainImage: true)
    }
    modelContext.insert(recipe)
}
```

## Verification Checklist

After updating all files, verify:

- [ ] **RecipeExtractorView.swift** - Updated and tested
- [ ] **RecipeExtractorViewModel.swift** - Updated and tested
- [ ] **RecipeExtractorWithImageView.swift** - Updated and tested
- [ ] **RecipeDetailView.swift** - Checked (update if needed)
- [ ] **ContentView.swift** - Checked (update if needed)
- [ ] **RecipeSearchView.swift** - Checked (update if needed)
- [ ] All extraction methods work (camera, photos, files, URLs)
- [ ] Images display correctly in recipe list
- [ ] Images sync to second device via CloudKit
- [ ] No compiler errors or warnings

## Common Issues

### Issue: "Cannot find 'setImage' in scope"

**Solution**: Make sure you're calling it on a `Recipe` object:
```swift
recipe.setImage(image, isMainImage: true)  // ✅ Correct
self.setImage(image, isMainImage: true)     // ❌ Wrong
```

### Issue: Images not appearing after save

**Solution**: Make sure `modelContext.save()` is called after `setImage()`:
```swift
recipe.setImage(image, isMainImage: true)
modelContext.insert(recipe)
try modelContext.save()  // ✅ Must save!
```

### Issue: RecipeImageView still showing placeholders

**Solution**: Update RecipeImageView call sites to pass imageData:
```swift
// OLD:
RecipeImageView(imageName: recipe.imageName)

// NEW:
RecipeImageView(imageName: recipe.imageName, imageData: recipe.imageData)
```

## Need Help?

If you find a `saveRecipe` method that doesn't fit these patterns:

1. Copy the entire method
2. Note which file it's in
3. Ask for specific guidance on that method

The goal is to eliminate ALL file-based image saving and use `recipe.setImage()` everywhere!
