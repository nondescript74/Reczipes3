# RecipeX Integration Guide

## Overview

This guide explains how to integrate the new `RecipeX` model alongside your existing `Recipe` model, with a selector to switch between them in the Recipes tab.

## Current Status

✅ **What's Done:**
- Added `RecipeX` model to your project (RecipeX.swift)
- Added `RecipeModelType` enum with `.legacy` and `.recipeX` cases
- Added `RecipeModelTypePicker` UI component
- Updated `ContentView` to query both `Recipe` and `RecipeX`
- Added logic to switch between model types in `refreshRecipeCache()`

## What You Need to Do

### Step 1: Add RecipeX to ModelContainer Schema

**File:** Find `ModelContainerManager.swift` or wherever your schema is defined

You need to add `RecipeX.self` to your schema configuration. Look for code like this:

```swift
// Example of what you're looking for:
let schema = Schema([
    Recipe.self,
    RecipeBook.self,
    RecipeImageAssignment.self,
    UserAllergenProfile.self,
    SavedLink.self,
    SharedRecipe.self,
    SharedRecipeBook.self,
    SharingPreferences.self,
    CookingSession.self,
    CachedSharedRecipe.self,
    Book.self
    // ADD THIS LINE:
    RecipeX.self  // ← Add this!
])
```

**Important:** Adding a new model to SwiftData schema will trigger a lightweight migration. Your existing data will be preserved.

### Step 2: Test the Selector

1. Build and run the app
2. Go to the Recipes tab
3. You should see a segmented picker at the top:
   - **Recipe (Legacy)** - Shows your current recipes
   - **RecipeX (New)** - Shows RecipeX recipes (will be empty initially)

### Step 3: Populate RecipeX with Data (Optional)

**Option A: Start Fresh**
- Just start using the new extraction flow with RecipeX
- Your old recipes will still be available in the "Legacy" view

**Option B: Migrate Existing Recipes**

Create a migration utility to copy Recipe → RecipeX:

```swift
// MigrationService.swift
import SwiftData
import Foundation

@MainActor
class RecipeMigrationService {
    
    /// Migrates all Recipe models to RecipeX
    static func migrateRecipesToRecipeX(modelContext: ModelContext) async throws {
        // Fetch all legacy recipes
        let descriptor = FetchDescriptor<Recipe>()
        let recipes = try modelContext.fetch(descriptor)
        
        logInfo("Starting migration: \(recipes.count) recipes to migrate", category: "migration")
        
        var migratedCount = 0
        var errorCount = 0
        
        for recipe in recipes {
            do {
                // Create RecipeX from Recipe
                let recipeX = RecipeX(from: recipe)
                
                // Insert into context
                modelContext.insert(recipeX)
                
                migratedCount += 1
                
                // Save in batches of 10
                if migratedCount % 10 == 0 {
                    try modelContext.save()
                    logInfo("Migrated \(migratedCount)/\(recipes.count) recipes", category: "migration")
                }
            } catch {
                logError("Failed to migrate recipe '\(recipe.title ?? "Unknown")': \(error)", category: "migration")
                errorCount += 1
            }
        }
        
        // Final save
        try modelContext.save()
        
        logInfo("✅ Migration complete: \(migratedCount) migrated, \(errorCount) errors", category: "migration")
    }
}
```

Then add a button in Settings to trigger migration:

```swift
// In SettingsView.swift
Section("Data Migration") {
    Button("Migrate Recipes to RecipeX") {
        Task {
            do {
                try await RecipeMigrationService.migrateRecipesToRecipeX(
                    modelContext: modelContext
                )
                // Show success alert
            } catch {
                // Show error alert
            }
        }
    }
}
```

## How It Works

### Model Switching Logic

When you switch between "Recipe (Legacy)" and "RecipeX (New)":

1. **`selectedModelType`** (stored in UserDefaults) changes
2. **`onChange(of: selectedModelType)`** triggers
3. **`refreshRecipeCache()`** runs with a switch statement:
   ```swift
   switch selectedModelType {
   case .legacy:
       // Uses @Query var savedRecipes: [Recipe]
       allRecipes = RecipeCollection.shared.allRecipes(savedRecipes: savedRecipes)
   
   case .recipeX:
       // Uses @Query var savedRecipesX: [RecipeX]
       allRecipes = savedRecipesX.compactMap { $0.toRecipeModel() }
   }
   ```
4. UI updates to show the selected model's recipes

### Data Storage

Both models store data independently in the same SwiftData database:

- **Recipe** → Legacy model (your current recipes)
- **RecipeX** → New unified model (future recipes with auto-sync)

They don't interfere with each other. You can:
- Keep both models indefinitely
- Migrate all data from Recipe → RecipeX
- Delete Recipe model once migration is complete

## Important Notes

### Will RecipeX Auto-Populate on Next Launch?

**No.** Here's why:

1. `RecipeX` is a separate SwiftData model
2. It has its own table in the database
3. New recipe extractions still use `Recipe` by default
4. You need to either:
   - **Migrate existing data** (see Step 3, Option B above)
   - **Update RecipeExtractorView** to save as `RecipeX` instead of `Recipe`

### Updating Recipe Extraction to Use RecipeX

If you want **new recipes** to save as `RecipeX`:

**File:** `RecipeExtractorView.swift` (or wherever recipes are saved)

Find the save logic:

```swift
// OLD (saves as Recipe):
let newRecipe = Recipe(from: recipeModel)
modelContext.insert(newRecipe)

// NEW (saves as RecipeX):
let newRecipeX = RecipeX(from: recipeModel)
modelContext.insert(newRecipeX)
```

**Or make it conditional:**

```swift
@AppStorage("selectedRecipeModelType") private var selectedModelType: RecipeModelType = .legacy

// In save method:
switch selectedModelType {
case .legacy:
    let newRecipe = Recipe(from: recipeModel)
    modelContext.insert(newRecipe)
case .recipeX:
    let newRecipeX = RecipeX(from: recipeModel)
    modelContext.insert(newRecipeX)
}
```

## Testing Checklist

- [ ] App builds without errors
- [ ] Recipes tab shows model type picker
- [ ] Switching to "Recipe (Legacy)" shows current recipes
- [ ] Switching to "RecipeX (New)" shows empty state (or migrated recipes)
- [ ] Filters and search work with both model types
- [ ] Creating new recipes saves to the selected model type
- [ ] Recipe details display correctly for both types
- [ ] Deletion works for both model types

## Future Enhancements

Once RecipeX is stable, you can:

1. **Make RecipeX the default** for new recipes
2. **Add a "Migrate All" button** in Settings
3. **Remove Recipe model** after confirming all data is migrated
4. **Enable CloudKit auto-sync** for RecipeX recipes
5. **Add RecipeX-specific features** (version history, conflict resolution, etc.)

## Rollback Plan

If you need to revert:

1. Remove `RecipeX.self` from schema
2. Remove the model type picker from UI
3. Keep `Recipe` as the only model
4. Delete any RecipeX records from the database (or keep them dormant)

## Questions?

- **Q: Can I have both models active at once?**  
  A: Yes! That's exactly what this implementation does. You can switch between them.

- **Q: Will CloudKit sync both models?**  
  A: Yes, if both are in your schema and CloudKit is enabled. However, RecipeX is designed for better CloudKit compatibility.

- **Q: What happens if I delete a recipe in one model?**  
  A: Nothing. They're independent. A Recipe and RecipeX with the same ID are separate database records.

- **Q: Should I migrate all my data now?**  
  A: Test with a few recipes first. Make sure RecipeX works as expected before mass migration.

