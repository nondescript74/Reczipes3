# Next Steps: Integrating Cached Shared Recipes

## Quick Summary

You asked: "I need to view shared recipes for cooking, using the cooking tab, etc."

**Solution:** Created a temporary cache system for community recipes that:
- ✅ Allows viewing without permanent import
- ✅ Works in cooking mode
- ✅ Auto-cleans after 30 days
- ✅ Limits to 100 recipes (prevents bloat)
- ✅ Optional import to permanent collection

## What's Already Done ✅

1. ✅ Created `CachedSharedRecipe.swift` model
2. ✅ Added sync functions to `CloudKitSharingService.swift`
3. ✅ Added sync button to Settings
4. ✅ Implemented auto-cleanup logic

## What You Need to Do

### Step 1: Add Model to Container

**File:** Your App file (probably `Reczipes2App.swift` or wherever you configure ModelContainer)

```swift
let container = ModelContainer(for: [
    Recipe.self,
    RecipeBook.self,
    SharedRecipe.self,
    SharedRecipeBook.self,
    CachedSharedRecipe.self, // ⬅️ ADD THIS LINE
    // ... any other models you have
])
```

### Step 2: Update RecipesView (or Similar)

**Option A: Simple - Just Query Cached Recipes**

```swift
struct RecipesView: View {
    @Query private var myRecipes: [Recipe]
    @Query private var cachedRecipes: [CachedSharedRecipe] // ⬅️ ADD THIS
    
    @State private var contentFilter: ContentFilterMode = .all
    
    private var filteredRecipes: [Any] {
        switch contentFilter {
        case .mine:
            return myRecipes
        case .shared:
            return cachedRecipes // ⬅️ SHOW CACHED RECIPES
        case .all:
            return myRecipes + cachedRecipes // ⬅️ COMBINE BOTH
        }
    }
    
    // ... rest of view
}
```

**Option B: Better - Use Display Item Enum**

Create a file `RecipeDisplayItem.swift`:

```swift
enum RecipeDisplayItem: Identifiable {
    case owned(Recipe)
    case cached(CachedSharedRecipe)
    
    var id: UUID {
        switch self {
        case .owned(let recipe): return recipe.id
        case .cached(let cached): return cached.id
        }
    }
    
    var title: String {
        switch self {
        case .owned(let recipe): return recipe.title
        case .cached(let cached): return cached.title
        }
    }
    
    var ingredientSections: [IngredientSection] {
        switch self {
        case .owned(let recipe): return recipe.ingredientSections
        case .cached(let cached): return cached.ingredientSections
        }
    }
    
    var instructionSections: [InstructionSection] {
        switch self {
        case .owned(let recipe): return recipe.instructionSections
        case .cached(let cached): return cached.instructionSections
        }
    }
    
    var isCached: Bool {
        if case .cached = self { return true }
        return false
    }
    
    // Add other properties as needed
}
```

Then in RecipesView:

```swift
private var filteredRecipes: [RecipeDisplayItem] {
    var items: [RecipeDisplayItem] = []
    
    switch contentFilter {
    case .mine:
        items = myRecipes.map { .owned($0) }
    case .shared:
        items = cachedRecipes.map { .cached($0) }
    case .all:
        items = myRecipes.map { .owned($0) } +
                cachedRecipes.map { .cached($0) }
    }
    
    return items
}
```

### Step 3: Update Recipe Detail View

Add import option for cached recipes:

```swift
struct RecipeDetailView: View {
    let item: RecipeDisplayItem // Instead of just Recipe
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            // Your existing recipe content
            
            // Add import button for cached recipes
            if item.isCached {
                VStack {
                    Divider()
                    
                    Button {
                        importRecipe()
                    } label: {
                        Label("Add to My Recipes", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    
                    Text("This is a community recipe. Add it to your collection to keep it permanently.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .onAppear {
            // Update last accessed date
            if case .cached(let cached) = item {
                try? CloudKitSharingService.shared.markCachedRecipeAsAccessed(
                    cached.id, 
                    modelContext: modelContext
                )
            }
        }
    }
    
    private func importRecipe() {
        if case .cached(let cached) = item {
            do {
                try CloudKitSharingService.shared.importCachedRecipe(
                    cached, 
                    modelContext: modelContext
                )
                // Show success message
            } catch {
                // Show error
            }
        }
    }
}
```

### Step 4: Update Cooking Mode (if needed)

If your cooking mode takes a `Recipe` object, update it to accept `RecipeDisplayItem`:

```swift
struct CookingModeView: View {
    let item: RecipeDisplayItem // Instead of Recipe
    
    var ingredientSections: [IngredientSection] {
        item.ingredientSections // Works for both types
    }
    
    var instructionSections: [InstructionSection] {
        item.instructionSections // Works for both types
    }
    
    // Rest of cooking mode works the same!
}
```

### Step 5: Add Auto-Sync (Optional)

Add to RecipesView to auto-sync when switching to Shared tab:

```swift
.onChange(of: contentFilter) { oldValue, newValue in
    if newValue == .shared {
        Task {
            await syncCommunityRecipesIfNeeded()
        }
    }
}

// Add the sync function
private func syncCommunityRecipesIfNeeded() async {
    // Only sync once every 5 minutes to avoid excessive calls
    // (Similar to what we did for books)
    
    do {
        try await CloudKitSharingService.shared.syncCommunityRecipesForViewing(
            modelContext: modelContext,
            limit: 100
        )
    } catch {
        // Silently fail - manual sync still available
        logError("Auto-sync failed: \(error)", category: "sharing")
    }
}
```

## Testing Flow

1. **Add model to container** → Rebuild app
2. **Run app** → May see schema migration (normal)
3. **Go to Settings → Sync Community Recipes**
4. **Go to Recipes → Shared tab**
5. **Should see cached recipes** ✅
6. **Tap a recipe → Should see detail view** ✅
7. **Try cooking mode → Should work** ✅
8. **Tap "Add to My Recipes"** → Should import ✅

## Quick Test (5 Minutes)

```swift
// Minimal integration - add to RecipesView

@Query private var cachedRecipes: [CachedSharedRecipe]

// In your list/grid:
Section("Community Recipes") {
    ForEach(cachedRecipes) { cached in
        NavigationLink(cached.title) {
            // Pass cached to detail view
            RecipeDetailView(recipe: cached)
        }
    }
}
```

Then:
1. Settings → Sync Community Recipes
2. Check Recipes view
3. See community recipes section ✅

## Comparison: Books vs Recipes

**Books (Already Working):**
- Auto-syncs when viewing Browse Community Books ✅
- Shows in Books → Shared tab ✅
- Permanent storage ✅

**Recipes (After Integration):**
- Manual sync (for now) via Settings button
- Shows in Recipes → Shared tab ✅
- Temporary cache (30 days) ✅
- Can import to permanent collection ✅

## Common Issues

### Build Error: "Cannot find CachedSharedRecipe"
→ Did you add to ModelContainer?

### Schema Migration Error
→ Normal on first launch, just restart

### Recipes not appearing
→ Did you run sync? Check console logs

### Cooking mode not working
→ Update to accept RecipeDisplayItem or handle both types

## Files You Need to Modify

1. ✅ App file - Add to ModelContainer
2. ✅ RecipesView - Query and display cached recipes  
3. ✅ RecipeDetailView - Handle both types, add import button
4. ⚠️ CookingMode - Update if it's recipe-specific
5. ⚠️ Any other views that work with recipes

## Summary

**Minimum to get it working:**
1. Add `CachedSharedRecipe.self` to ModelContainer
2. Add `@Query` in RecipesView for cached recipes
3. Display them in "Shared" filter
4. Run sync from Settings

**For best experience:**
1. Create `RecipeDisplayItem` enum
2. Update views to handle both types
3. Add import button in detail view
4. Add auto-sync on tab switch
5. Show visual indicator for cached recipes

---

**Next Action:** Add `CachedSharedRecipe.self` to your ModelContainer and rebuild!
