# Recipe Model Migration Guide

## Overview
This guide covers migration considerations for the Recipe model after adding CookingMode compatibility features.

## Changes Made

### New Properties Added (Optional)
- `version: Int?` - Tracks recipe version for cache invalidation
- `lastModified: Date?` - Timestamp of last modification
- `ingredientsHash: String?` - Hash for detecting ingredient changes

### New Computed Properties (Extension)
- `ingredients: [String]` - Flat array of formatted ingredients
- `instructions: [String]` - Flat array of instruction steps
- `servings: Int?` - Extracted from recipeYield string

## Migration Strategy

### ✅ Lightweight Migration (Recommended)
SwiftData supports **lightweight migration** automatically when you only:
- Add new optional properties
- Add computed properties via extensions
- Add new methods

**Your changes qualify for lightweight migration!**

#### Why Lightweight Migration Works:
1. All new stored properties (`version`, `lastModified`, `ingredientsHash`) are **optional**
2. SwiftData can set them to `nil` for existing recipes
3. Computed properties don't affect storage
4. Extensions don't modify the schema

#### What Happens During Lightweight Migration:
```swift
// Existing recipes before migration:
Recipe(
    id: UUID,
    title: "Old Recipe",
    // ... other existing properties
    // version: nil (doesn't exist yet)
    // lastModified: nil
    // ingredientsHash: nil
)

// Same recipe after migration:
Recipe(
    id: UUID,
    title: "Old Recipe",
    // ... other existing properties
    version: nil,           // ← Automatically set to nil
    lastModified: nil,      // ← Automatically set to nil
    ingredientsHash: nil    // ← Automatically set to nil
)
```

### How to Enable Lightweight Migration

#### Option 1: Default (Automatic)
SwiftData performs lightweight migration automatically. No code changes needed!

```swift
// Your existing ModelContainer setup:
let container = try ModelContainer(
    for: Recipe.self,
    // Lightweight migration happens automatically
)
```

#### Option 2: Explicit Configuration (Optional)
If you want to be explicit:

```swift
import SwiftData

let schema = Schema([Recipe.self])
let modelConfiguration = ModelConfiguration(schema: schema)

let container = try ModelContainer(
    for: schema,
    configurations: [modelConfiguration]
)
```

### Initializing New Properties for Existing Recipes

Even though lightweight migration works, you may want to initialize the new properties for existing recipes:

```swift
import SwiftData

@MainActor
func migrateExistingRecipes(modelContext: ModelContext) async throws {
    let descriptor = FetchDescriptor<Recipe>(
        predicate: #Predicate { $0.version == nil }
    )
    
    let recipesNeedingMigration = try modelContext.fetch(descriptor)
    
    for recipe in recipesNeedingMigration {
        // Initialize version
        recipe.version = 1
        
        // Initialize lastModified (use dateAdded as fallback)
        recipe.lastModified = recipe.dateAdded
        
        // Calculate ingredients hash
        if let ingredientsData = recipe.ingredientSectionsData {
            recipe.ingredientsHash = Recipe.calculateIngredientsHash(from: ingredientsData)
        }
    }
    
    try modelContext.save()
    print("Migrated \(recipesNeedingMigration.count) recipes")
}
```

#### When to Run Migration Code:
Add this to your app launch:

```swift
@main
struct Reczipes2App: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: Recipe.self)
            
            // Run migration on first launch after update
            Task { @MainActor in
                try? await migrateExistingRecipes(modelContext: container.mainContext)
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

## Testing Migration

### Before Deploying:
1. **Backup**: Always backup your data store
2. **Test on Copy**: Test migration on a copy of production data
3. **Verify**: Ensure existing recipes load correctly

### Test Checklist:
- [ ] App launches without crashes
- [ ] Existing recipes display correctly
- [ ] `ingredients` computed property works on old recipes
- [ ] `instructions` computed property works on old recipes
- [ ] New recipes get `version = 1` automatically
- [ ] CookingMode works with both old and new recipes

### Test Code:
```swift
func testMigration() async throws {
    let container = try ModelContainer(for: Recipe.self)
    let context = container.mainContext
    
    // Fetch all recipes
    let recipes = try context.fetch(FetchDescriptor<Recipe>())
    
    for recipe in recipes {
        // Test computed properties work
        print("Recipe: \(recipe.title)")
        print("Ingredients count: \(recipe.ingredients.count)")
        print("Instructions count: \(recipe.instructions.count)")
        print("Version: \(recipe.currentVersion)") // Uses computed property with fallback
        print("Last modified: \(recipe.modificationDate)") // Uses computed property with fallback
        
        // Verify CookingMode compatibility
        if recipe.isValidForCookingMode {
            print("✅ Ready for CookingMode")
        } else {
            print("❌ Missing: \(recipe.cookingModeMissingFields)")
        }
    }
}
```

## CloudKit Sync Considerations

If you're using CloudKit sync with SwiftData:

### ✅ Safe Changes (Your Changes)
- Adding optional properties: Safe
- Adding computed properties: Safe (not synced)
- Adding extensions: Safe (not synced)

### Migration Behavior:
1. **New installs**: Get full schema immediately
2. **Existing installs**: Migrate locally, then sync updates
3. **Multiple devices**: Each device migrates independently
4. **No conflicts**: Optional properties avoid sync conflicts

### CloudKit Notes:
```swift
// Your imageData properties use externalStorage
@Attribute(.externalStorage) var imageData: Data?
@Attribute(.externalStorage) var additionalImagesData: Data?

// This continues to work with migration
// CloudKit stores large data externally automatically
```

## Rollback Strategy (If Needed)

If you need to rollback (unlikely):

1. **Keep old code available**: Git tag before deploying
2. **Computed properties are safe**: They don't affect storage
3. **Optional properties won't break old code**: Old code ignores new properties

```swift
// Old version of app can still read new data store
// because new properties are optional and will be nil
```

## Performance Impact

### Minimal Performance Impact:
- ✅ No schema changes requiring full data rewrite
- ✅ Computed properties cache-friendly
- ✅ Hash calculation only on ingredient updates
- ✅ Version tracking is lightweight (Int)

### Tips:
```swift
// Computed properties decode on-demand
// Cache results if calling frequently:
class RecipeViewModel: ObservableObject {
    private var cachedIngredients: [String]?
    
    func getIngredients(for recipe: Recipe) -> [String] {
        if let cached = cachedIngredients {
            return cached
        }
        let ingredients = recipe.ingredients
        cachedIngredients = ingredients
        return ingredients
    }
}
```

## Summary

### ✅ You're Good to Go!
- **Migration Type**: Lightweight (automatic)
- **User Impact**: None (seamless)
- **Data Loss Risk**: None
- **Breaking Changes**: None
- **Action Required**: Optional initialization of new properties

### Deployment Steps:
1. ✅ Update code (already done)
2. ✅ Test on development device
3. ✅ (Optional) Add migration initialization code
4. ✅ Deploy to TestFlight
5. ✅ Verify on test devices
6. ✅ Deploy to App Store

### Files Changed:
- ✅ `Recipe.swift` - Added extensions and optional properties
- ✅ No migration code required (lightweight migration is automatic)
- ✅ No version number changes needed

### Backward Compatibility:
- ✅ Old recipes work with new code
- ✅ New computed properties return empty arrays for missing data
- ✅ `currentVersion` and `modificationDate` provide safe fallbacks
- ✅ CookingMode validates data before use

## Questions?

**Q: Do I need to increment a schema version?**
A: No, SwiftData handles this automatically for lightweight migrations.

**Q: Will existing recipes work with CookingMode?**
A: Yes! The computed properties decode your existing `ingredientSectionsData` and `instructionSectionsData`.

**Q: What if ingredient or instruction data is missing?**
A: Computed properties return empty arrays. Use `isValidForCookingMode` to check before entering CookingMode.

**Q: Should I run the migration initialization code?**
A: Optional but recommended. It sets proper values for `version`, `lastModified`, and `ingredientsHash` on existing recipes.

**Q: What about CloudKit?**
A: Your changes are CloudKit-safe. Optional properties sync without conflicts.
