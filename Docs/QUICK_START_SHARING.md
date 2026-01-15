# Quick Start: Implementing CloudKit Community Sharing

## Step-by-Step Implementation Checklist

### ✅ Step 1: Add Models to Schema (5 minutes)

In `Reczipes2App.swift`, update your ModelContainer to include the new models:

```swift
let container = try ModelContainer(
    for: Recipe.self,
        RecipeImageAssignment.self,
        UserAllergenProfile.self,
        CachedDiabeticAnalysis.self,
        SavedLink.self,
        RecipeBook.self,
        CookingSession.self,
        SharedRecipe.self,          // ADD THIS
        SharedRecipeBook.self,      // ADD THIS
        SharingPreferences.self,    // ADD THIS
    migrationPlan: Reczipes2MigrationPlan.self,
    configurations: cloudKitConfiguration
)
```

**Note**: Do this in BOTH places in the file where ModelContainer is created (CloudKit and local-only configurations).

---

### ✅ Step 2: Configure CloudKit Schema (10 minutes)

1. Visit [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select container: `iCloud.com.headydiscy.reczipes`
3. Go to **Schema** → **Record Types**
4. Click **+** to create new record type

#### Create "SharedRecipe" Record Type:

| Field Name | Field Type | Options |
|------------|-----------|---------|
| recipeData | String | Required |
| title | String | Queryable, Sortable |
| sharedBy | String | Queryable |
| sharedByName | String | |
| sharedDate | Date/Time | Queryable, Sortable |
| mainImage | Asset | |

#### Create "SharedRecipeBook" Record Type:

| Field Name | Field Type | Options |
|------------|-----------|---------|
| bookData | String | Required |
| name | String | Queryable, Sortable |
| sharedBy | String | Queryable |
| sharedByName | String | |
| sharedDate | Date/Time | Queryable, Sortable |
| coverImage | Asset | |

5. Click **Save** for each record type
6. Deploy to **Production** environment

---

### ✅ Step 3: Add Sharing to Settings (2 minutes)

In your `SettingsView.swift`, add this section:

```swift
Section("Community") {
    NavigationLink {
        SharingSettingsView()
    } label: {
        Label("Sharing & Community", systemImage: "person.3.fill")
    }
    
    NavigationLink {
        SharedRecipesBrowserView()
    } label: {
        Label("Browse Community Recipes", systemImage: "tray.full.fill")
    }
}
```

---

### ✅ Step 4: Implement Recipe Conversion (15 minutes)

You need to convert your SwiftData `Recipe` entity to `RecipeModel`. 

**Find your Recipe SwiftData model** (likely in a file called `Recipe.swift` or similar), and add this extension:

```swift
extension Recipe {
    /// Convert SwiftData Recipe to Codable RecipeModel for sharing
    func toRecipeModel() -> RecipeModel {
        // TODO: Map your Recipe properties to RecipeModel
        // This example assumes your Recipe entity has similar properties
        return RecipeModel(
            id: self.id,
            title: self.title,
            headerNotes: self.headerNotes,
            yield: self.yield,
            ingredientSections: self.ingredientSections,
            instructionSections: self.instructionSections,
            notes: self.notes,
            reference: self.reference,
            imageName: self.imageName,
            additionalImageNames: self.additionalImageNames,
            imageURLs: self.imageURLs
        )
    }
}
```

**Update the sharing service** in `SharingSettingsView.swift`:

Replace the TODO section in `shareAllRecipes()`:

```swift
private func shareAllRecipes() async {
    guard !allRecipes.isEmpty else { return }
    
    isSharing = true
    sharingStatus = "Sharing all recipes..."
    
    // Convert SwiftData Recipe to RecipeModel
    let recipeModels = allRecipes.map { $0.toRecipeModel() }
    
    let result = await sharingService.shareMultipleRecipes(recipeModels, modelContext: modelContext)
    
    // ... rest of the function
}
```

And in `shareRecipes()`:

```swift
private func shareRecipes(_ recipes: [Recipe]) async {
    isSharing = true
    let recipeModels = recipes.map { $0.toRecipeModel() }
    let result = await sharingService.shareMultipleRecipes(recipeModels, modelContext: modelContext)
    isSharing = false
    
    // Handle result...
}
```

---

### ✅ Step 5: Implement Recipe Import (10 minutes)

In `CloudKitSharingService.swift`, update the `importSharedRecipe` method:

```swift
func importSharedRecipe(_ cloudRecipe: CloudKitRecipe, modelContext: ModelContext) async throws {
    // Convert to your local Recipe entity
    let recipe = Recipe(
        id: UUID(), // New ID to avoid conflicts
        title: "\(cloudRecipe.title) (shared by \(cloudRecipe.sharedByUserName ?? "community"))",
        // ... map all other properties from cloudRecipe
    )
    
    modelContext.insert(recipe)
    try modelContext.save()
    
    logInfo("Imported shared recipe: \(cloudRecipe.title)", category: "sharing")
}
```

**Note**: You'll need to adjust this based on your actual Recipe initializer.

---

### ✅ Step 6: Add Context Menu to Recipes (5 minutes)

In your recipe list view (probably `ContentView.swift`), add a share button:

```swift
.contextMenu {
    // ... existing menu items ...
    
    Button {
        Task {
            await shareRecipe(recipe)
        }
    } label: {
        Label("Share with Community", systemImage: "square.and.arrow.up")
    }
}

// Add this method:
@MainActor
private func shareRecipe(_ recipe: Recipe) async {
    let recipeModel = recipe.toRecipeModel()
    
    do {
        _ = try await CloudKitSharingService.shared.shareRecipe(
            recipeModel,
            modelContext: modelContext
        )
        // Show success message
    } catch {
        // Show error
        print("Failed to share: \(error)")
    }
}
```

---

### ✅ Step 7: Test the Implementation (10 minutes)

1. **Build and run** the app
2. **Navigate to Settings** → Sharing & Community
3. **Check CloudKit status** - should show "Ready to Share"
4. **Share a recipe**:
   - Toggle "Share All Recipes" OR
   - Tap "Share Specific Recipes" and select one
5. **Browse community recipes**:
   - Tap "Browse Shared Recipes"
   - You should see your shared recipe
6. **Test with second account** (optional):
   - Sign in with different iCloud account
   - Browse community recipes
   - Import a recipe
   - Verify it appears in local collection

---

## Common Issues & Solutions

### ❌ "CloudKit unavailable"

**Solution**: 
- Sign in to iCloud on device/simulator
- Settings → Apple ID → iCloud → Enable iCloud Drive

### ❌ "Record type not found"

**Solution**:
- Verify record types exist in CloudKit Dashboard
- Deploy schema to Production environment
- Wait 5-10 minutes for changes to propagate

### ❌ "Recipe won't share"

**Solution**:
- Check console logs for specific error
- Verify Recipe → RecipeModel conversion is working
- Test with a simple recipe first

### ❌ "Shared recipes not appearing"

**Solution**:
- Tap refresh button in community browser
- Check CloudKit Dashboard → Data → Production
- Verify records were created

### ❌ Compilation errors

**Solution**:
- Ensure all new files are added to Xcode target
- Clean build folder (Cmd+Shift+K)
- Rebuild project

---

## Files Created

✅ **SharedContentModels.swift** - Data models for sharing  
✅ **CloudKitSharingService.swift** - Service layer for CloudKit operations  
✅ **SharingSettingsView.swift** - UI for sharing preferences  
✅ **SharedRecipesBrowserView.swift** - UI for browsing community recipes  
✅ **CLOUDKIT_SHARING_GUIDE.md** - Comprehensive documentation  
✅ **QUICK_START_SHARING.md** - This file  

---

## Next Steps After Basic Implementation

1. **Add share buttons** to recipe detail view
2. **Show share status** in recipe rows (badge showing "Shared")
3. **Add analytics** to track sharing usage
4. **Implement search filters** in community browser
5. **Add user profiles** to see all recipes from one user
6. **Implement ratings** for community recipes

---

## Verification Checklist

Before considering the feature complete:

- [ ] Can share individual recipes
- [ ] Can share individual recipe books
- [ ] Can toggle "Share All" for recipes
- [ ] Can toggle "Share All" for books
- [ ] Can view shared content in Settings
- [ ] Can browse community recipes
- [ ] Can search community recipes
- [ ] Can view recipe details from community
- [ ] Can import community recipe to local collection
- [ ] Can unshare previously shared content
- [ ] Images are shared with recipes
- [ ] User name appears correctly (or "Anonymous" if disabled)
- [ ] Works with multiple iCloud accounts
- [ ] Error handling shows helpful messages

---

## Performance Notes

- **First share**: May take 2-3 seconds (uploading to CloudKit)
- **Browsing community**: Fetches up to 200 recipes at once
- **Images**: Loaded on-demand when viewing recipe details
- **Caching**: Shared recipe list is cached until refresh

---

## Support

If you encounter issues:

1. Check `CLOUDKIT_SHARING_GUIDE.md` for detailed troubleshooting
2. Review CloudKit Dashboard for errors
3. Check Xcode console for detailed error messages
4. Test with fresh simulator/device

Happy sharing! 🎉
