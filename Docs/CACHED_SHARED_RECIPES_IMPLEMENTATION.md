# Viewing Shared Recipes Without Permanent Import

## Updated Use Case

**Original Assumption:** Users only want to import recipes to own them permanently  
**Actual Need:** Users want to **view and cook from** shared recipes without importing

## The Solution: Temporary Recipe Cache

Create a lightweight system that allows users to:
- Browse shared recipes
- View full recipe details
- Use cooking mode
- Add to shopping list
- **WITHOUT** permanently importing to their collection

## Implementation Strategy

### 1. Cached Shared Recipe Model

Create a separate model for temporarily cached community recipes:

```swift
@Model
final class CachedSharedRecipe {
    var id: UUID = UUID() // CloudKit recipe ID
    var title: String = ""
    var headerNotes: String?
    var yield: String?
    var ingredientSections: [IngredientSection] = []
    var instructionSections: [InstructionSection] = []
    var notes: [RecipeNote] = []
    var reference: String?
    var imageName: String?
    var additionalImageNames: [String]?
    
    // Metadata
    var sharedByUserID: String = ""
    var sharedByUserName: String?
    var sharedDate: Date = Date()
    var cachedDate: Date = Date()
    var lastAccessedDate: Date = Date()
    
    // Distinguish from imported recipes
    var isTemporaryCache: Bool = true
    
    init(from cloudRecipe: CloudKitRecipe) {
        self.id = cloudRecipe.id
        self.title = cloudRecipe.title
        self.headerNotes = cloudRecipe.headerNotes
        self.yield = cloudRecipe.yield
        self.ingredientSections = cloudRecipe.ingredientSections
        self.instructionSections = cloudRecipe.instructionSections
        self.notes = cloudRecipe.notes
        self.reference = cloudRecipe.reference
        self.imageName = cloudRecipe.imageName
        self.additionalImageNames = cloudRecipe.additionalImageNames
        self.sharedByUserID = cloudRecipe.sharedByUserID
        self.sharedByUserName = cloudRecipe.sharedByUserName
        self.sharedDate = cloudRecipe.sharedDate
        self.cachedDate = Date()
        self.lastAccessedDate = Date()
    }
}
```

### 2. Sync Function for Viewing

Add to `CloudKitSharingService`:

```swift
/// Sync community recipes for viewing (not permanent import)
/// Similar to books sync, but with automatic cleanup
func syncCommunityRecipesForViewing(modelContext: ModelContext, limit: Int = 100) async throws {
    guard isCloudKitAvailable else {
        throw SharingError.cloudKitUnavailable()
    }
    
    logInfo("📖 SYNC: Syncing community recipes for viewing...", category: "sharing")
    
    // Fetch recent shared recipes from CloudKit
    let cloudRecipes = try await fetchSharedRecipes(excludeCurrentUser: true)
    let recentRecipes = Array(cloudRecipes.prefix(limit)) // Limit to prevent storage bloat
    
    logInfo("📖 SYNC: Found \(cloudRecipes.count) community recipes, caching \(recentRecipes.count)", category: "sharing")
    
    // Fetch existing cached recipes
    let existingCached = try modelContext.fetch(FetchDescriptor<CachedSharedRecipe>())
    var existingByID = [UUID: CachedSharedRecipe]()
    for cached in existingCached {
        existingByID[cached.id] = cached
    }
    
    // Track which recipes are still in CloudKit
    var currentCloudRecipeIDs = Set<UUID>()
    
    var addedCount = 0
    var updatedCount = 0
    
    // Process each CloudKit recipe
    for cloudRecipe in recentRecipes {
        currentCloudRecipeIDs.insert(cloudRecipe.id)
        
        if let existingCached = existingByID[cloudRecipe.id] {
            // Update existing cache
            existingCached.title = cloudRecipe.title
            existingCached.headerNotes = cloudRecipe.headerNotes
            existingCached.yield = cloudRecipe.yield
            existingCached.ingredientSections = cloudRecipe.ingredientSections
            existingCached.instructionSections = cloudRecipe.instructionSections
            existingCached.notes = cloudRecipe.notes
            existingCached.reference = cloudRecipe.reference
            existingCached.imageName = cloudRecipe.imageName
            existingCached.additionalImageNames = cloudRecipe.additionalImageNames
            existingCached.sharedByUserName = cloudRecipe.sharedByUserName
            existingCached.cachedDate = Date()
            updatedCount += 1
            logInfo("📖   Updated cached recipe: '\(cloudRecipe.title)'", category: "sharing")
        } else {
            // Create new cached recipe
            let newCached = CachedSharedRecipe(from: cloudRecipe)
            modelContext.insert(newCached)
            addedCount += 1
            logInfo("📖   Cached new recipe: '\(cloudRecipe.title)' by \(cloudRecipe.sharedByUserName ?? "Unknown")", category: "sharing")
        }
    }
    
    // Clean up cached recipes that are no longer available or old
    var removedCount = 0
    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    
    for cached in existingCached {
        let shouldRemove = !currentCloudRecipeIDs.contains(cached.id) || cached.lastAccessedDate < thirtyDaysAgo
        
        if shouldRemove {
            modelContext.delete(cached)
            removedCount += 1
            logInfo("📖   Removed cached recipe: '\(cached.title)'", category: "sharing")
        }
    }
    
    try modelContext.save()
    
    logInfo("✅ SYNC COMPLETE: Community recipes cached for viewing", category: "sharing")
    logInfo("   - Added: \(addedCount) recipes", category: "sharing")
    logInfo("   - Updated: \(updatedCount) recipes", category: "sharing")
    logInfo("   - Removed: \(removedCount) recipes", category: "sharing")
}

/// Update last accessed date for a cached recipe (prevents auto-cleanup)
func markCachedRecipeAsAccessed(_ recipeID: UUID, modelContext: ModelContext) throws {
    let descriptor = FetchDescriptor<CachedSharedRecipe>(
        predicate: #Predicate<CachedSharedRecipe> { $0.id == recipeID }
    )
    
    if let cached = try modelContext.fetch(descriptor).first {
        cached.lastAccessedDate = Date()
        try modelContext.save()
    }
}

/// Convert a cached recipe to permanent import
func importCachedRecipe(_ cachedRecipe: CachedSharedRecipe, modelContext: ModelContext) throws {
    let recipeModel = RecipeModel(
        id: UUID(), // New ID - independent copy
        title: cachedRecipe.title,
        headerNotes: cachedRecipe.headerNotes,
        yield: cachedRecipe.yield,
        ingredientSections: cachedRecipe.ingredientSections,
        instructionSections: cachedRecipe.instructionSections,
        notes: cachedRecipe.notes,
        reference: cachedRecipe.reference,
        imageName: cachedRecipe.imageName,
        additionalImageNames: cachedRecipe.additionalImageNames
    )
    
    let recipe = Recipe(from: recipeModel)
    modelContext.insert(recipe)
    try modelContext.save()
    
    logInfo("Imported cached recipe to permanent collection: \(cachedRecipe.title)", category: "sharing")
}
```

### 3. Update Recipes View

Modify your recipes view to include cached recipes:

```swift
struct RecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var myRecipes: [Recipe]
    @Query private var cachedSharedRecipes: [CachedSharedRecipe]
    
    @State private var contentFilter: ContentFilterMode = .all
    
    private var filteredRecipes: [RecipeDisplayItem] {
        var items: [RecipeDisplayItem] = []
        
        switch contentFilter {
        case .mine:
            // Only user's own recipes
            items = myRecipes.map { RecipeDisplayItem.owned($0) }
            
        case .shared:
            // Only cached community recipes
            items = cachedSharedRecipes.map { RecipeDisplayItem.cached($0) }
            
        case .all:
            // Both owned and cached
            items = myRecipes.map { RecipeDisplayItem.owned($0) } +
                    cachedSharedRecipes.map { RecipeDisplayItem.cached($0) }
        }
        
        return items
    }
    
    var body: some View {
        // ... your view implementation
    }
}

// Helper enum to handle both types
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
    
    var isCached: Bool {
        switch self {
        case .owned: return false
        case .cached: return true
        }
    }
}
```

### 4. Recipe Detail View Updates

Update your recipe detail view to work with both types:

```swift
struct RecipeDetailView: View {
    let displayItem: RecipeDisplayItem
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            // Display recipe content (works for both types)
            RecipeContentView(item: displayItem)
            
            // Show import button for cached recipes
            if displayItem.isCached {
                Button {
                    importToPermanentCollection()
                } label: {
                    Label("Add to My Recipes", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .navigationTitle(displayItem.title)
        .onAppear {
            // Mark as accessed to prevent cleanup
            if case .cached(let cached) = displayItem {
                try? CloudKitSharingService.shared.markCachedRecipeAsAccessed(cached.id, modelContext: modelContext)
            }
        }
    }
    
    private func importToPermanentCollection() {
        if case .cached(let cached) = displayItem {
            try? CloudKitSharingService.shared.importCachedRecipe(cached, modelContext: modelContext)
        }
    }
}
```

### 5. Cooking Mode Support

Your cooking mode should work transparently with both types:

```swift
struct CookingModeView: View {
    let displayItem: RecipeDisplayItem
    
    var ingredientSections: [IngredientSection] {
        switch displayItem {
        case .owned(let recipe): return recipe.ingredientSections
        case .cached(let cached): return cached.ingredientSections
        }
    }
    
    var instructionSections: [InstructionSection] {
        switch displayItem {
        case .owned(let recipe): return recipe.instructionSections
        case .cached(let cached): return cached.instructionSections
        }
    }
    
    // ... rest of cooking mode implementation
}
```

## Key Differences from Books

| Feature | Books | Recipes (Cached) |
|---------|-------|------------------|
| **Purpose** | Browse collections | View & cook |
| **Storage** | Permanent | Temporary (auto-cleanup) |
| **Limit** | All available | Recent 100 |
| **Cleanup** | Only when unshared | After 30 days unused |
| **Import option** | Auto-synced | Optional "Add to My Recipes" |
| **Updates** | Auto-sync | Refresh on access |

## Auto-Cleanup Rules

Cached recipes are removed if:
1. **No longer in CloudKit** (owner unshared)
2. **Not accessed in 30 days** (to free storage)
3. **Exceeds cache limit** (keep only 100 most recent)

Recipes are preserved if:
- User accesses them (resets 30-day timer)
- User imports to permanent collection

## Storage Management

```swift
// Clean up old cached recipes manually
func cleanupOldCachedRecipes(modelContext: ModelContext) throws {
    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    
    let descriptor = FetchDescriptor<CachedSharedRecipe>(
        predicate: #Predicate<CachedSharedRecipe> { recipe in
            recipe.lastAccessedDate < thirtyDaysAgo
        }
    )
    
    let oldRecipes = try modelContext.fetch(descriptor)
    
    for recipe in oldRecipes {
        modelContext.delete(recipe)
    }
    
    try modelContext.save()
    
    logInfo("Cleaned up \(oldRecipes.count) old cached recipes", category: "sharing")
}
```

## Benefits of This Approach

✅ **Users can cook from shared recipes** without importing  
✅ **Automatic storage management** (30-day cleanup)  
✅ **Still have import option** for permanent collection  
✅ **Works in cooking mode** transparently  
✅ **Prevents storage bloat** (limit 100 cached recipes)  
✅ **Clear distinction** between owned and cached  

## Implementation Checklist

- [ ] Create `CachedSharedRecipe` model
- [ ] Add `syncCommunityRecipesForViewing()` to CloudKitSharingService
- [ ] Update RecipesView to show both owned and cached
- [ ] Create `RecipeDisplayItem` enum
- [ ] Update RecipeDetailView to work with both types
- [ ] Add "Add to My Recipes" button for cached recipes
- [ ] Update CookingMode to support both types
- [ ] Add auto-sync on app launch or tab switch
- [ ] Implement 30-day cleanup
- [ ] Add manual cleanup function
- [ ] Add cache status indicator in UI

## UI Indicators

Show users which recipes are cached vs owned:

```swift
struct RecipeRowView: View {
    let item: RecipeDisplayItem
    
    var body: some View {
        HStack {
            Text(item.title)
            
            Spacer()
            
            if item.isCached {
                Label("Community", systemImage: "cloud")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

---

**Updated Decision:** Implement lightweight caching for shared recipes to enable viewing and cooking, with automatic cleanup to manage storage.
