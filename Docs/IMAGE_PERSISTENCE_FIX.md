# Image Persistence Fix

## The Problem
Recipe images were being assigned in `RecipeImageAssignment` but weren't appearing after app restart.

## The Solution

### 1. Query Image Assignments in ContentView
Added `@Query` for `RecipeImageAssignment` to load all assignments:
```swift
@Query private var imageAssignments: [RecipeImageAssignment]
```

### 2. Merge Assignments with Static Recipes
The `availableRecipes` computed property now merges static recipe data with image assignments:
```swift
private var availableRecipes: [RecipeModel] {
    RecipeModel.allRecipes.map { recipe in
        if let assignedImageName = imageName(for: recipe.id) {
            return recipe.withImageName(assignedImageName)
        }
        return recipe
    }
}
```

### 3. Helper Method to Look Up Image Names
```swift
private func imageName(for recipeID: UUID) -> String? {
    imageAssignments.first { $0.recipeID == recipeID }?.imageName
}
```

### 4. Display Thumbnails in UI
Both "Available Recipes" and "Saved Recipes" sections now show:
- 50x50 thumbnail if image is assigned
- "Assign Image" placeholder if not

### 5. Save Image with Recipe
When saving a recipe to the database, the current image assignment is included:
```swift
private func saveRecipe(_ recipe: RecipeModel) {
    withAnimation {
        var recipeToSave = recipe
        if let assignedImage = imageName(for: recipe.id) {
            recipeToSave = recipe.withImageName(assignedImage)
        }
        
        let newRecipe = Recipe(from: recipeToSave)
        modelContext.insert(newRecipe)
    }
}
```

## How It Works

### Data Flow

1. **User assigns image** → Saved to `RecipeImageAssignment` table
2. **App loads** → SwiftData @Query loads all assignments
3. **Recipes display** → Static recipes merged with assignments
4. **UI shows** → Thumbnails for assigned images
5. **User saves recipe** → Image copied to `Recipe.imageName`

### Two Storage Locations

Images are stored in two places:

1. **RecipeImageAssignment** (primary source)
   - Stores assignments for ALL recipes (saved and unsaved)
   - Queried on every app launch
   - User can change these anytime

2. **Recipe.imageName** (snapshot)
   - Stored when recipe is saved to database
   - Snapshot of image at save time
   - Fallback if assignment is deleted

### Why This Works

- **Persistence**: `RecipeImageAssignment` is a SwiftData model, so assignments persist
- **Real-time**: `@Query` automatically updates when assignments change
- **Reactive**: SwiftUI re-renders when the query results change
- **Dual-source**: Saved recipes use `recipe.imageName` OR look up assignment

## Testing

1. Assign an image to a recipe
2. Close the app
3. Reopen the app
4. ✅ Image should still appear

## Edge Cases Handled

- **No assignment**: Shows "Assign Image" placeholder
- **Assignment deleted**: Saved recipes fall back to `recipe.imageName`
- **Recipe not saved**: Uses `RecipeImageAssignment` only
- **Recipe saved**: Uses both sources (assignment preferred)
