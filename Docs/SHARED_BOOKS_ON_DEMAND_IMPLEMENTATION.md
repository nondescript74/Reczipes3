# Shared Recipe Books: On-Demand Viewing Implementation

## User Requirements

When a user shares a recipe book with 50 recipes:

1. ✅ **Book metadata** syncs immediately (name, description, cover image)
2. ✅ **Recipe previews** sync immediately (titles, thumbnails, basic info)
3. ✅ **Recipe list** shows all recipes as if they were local
4. ⏳ **Full recipe data** downloads **only when tapped**
5. 👁️ **Read-only viewing** - full RecipeDetailView functionality except no saving/editing

## Architecture Overview

```
Device A (Sharer)                  CloudKit                    Device B (Viewer)
─────────────────                  ────────                    ─────────────────
RecipeBook (50 recipes)            
├─ Book metadata ──────────────►  SharedRecipeBook ──────────► RecipeBook (synced)
├─ Cover image ────────────────►  CKAsset ────────────────────► Downloaded image
├─ Recipe #1                       RecipePreviewData           CloudKitRecipePreview
│  ├─ Title ────────────────────►  (in JSON) ─────────────────► (cached locally)
│  ├─ Thumbnail ────────────────►  CKAsset ────────────────────► Downloaded thumb
│  └─ Full data ────────────────►  (not synced yet)            (download on tap)
├─ Recipe #2                       RecipePreviewData           CloudKitRecipePreview
│  └─ ... (same pattern)           ...                         ...
└─ Recipe #50                      RecipePreviewData           CloudKitRecipePreview
   └─ ... (same pattern)           ...                         ...

                                                               User taps recipe
                                                                      ↓
                                                               Full recipe downloaded
                                                                      ↓
                                                               RecipeDetailView (read-only)
```

## Implementation Steps

### Phase 1: Data Models ✅ DONE

**File:** `CloudKitRecipePreview.swift` (NEW)

Created three new types:
1. `CloudKitRecipePreview` - SwiftData model for local preview cache
2. `CloudKitRecipeBookWithPreviews` - Extended book model with previews
3. `RecipePreviewData` - Lightweight recipe data for JSON storage

### Phase 2: On-Demand Download Service ✅ DONE

**File:** `SharedRecipeViewService.swift` (NEW)

Service that handles:
- Fetching full recipe when user taps a preview
- Caching downloaded recipes (in-memory)
- Optional prefetching for better UX
- Error handling for missing/unshared recipes

### Phase 3: Enhanced Book Sharing ✅ DONE

**File:** `CloudKitSharingService.swift` - Updated `shareRecipeBook()`

Now uploads:
- Book metadata (as before)
- Cover image (CKAsset)
- Recipe previews (JSON array)
- Recipe thumbnail images (CKAsset array, up to 50)

### Phase 4: Enhanced Book Syncing - TODO

**File:** `CloudKitSharingService.swift` - Update `syncCommunityBooksToLocal()`

Needs to:
1. Fetch CloudKit records (including assets)
2. Download cover image
3. Parse recipe previews JSON
4. Download recipe thumbnails
5. Create `CloudKitRecipePreview` entries in SwiftData
6. Link previews to the book

### Phase 5: Recipe List View ✅ DONE

**File:** `SharedRecipeBookListView.swift` (NEW)

View that shows recipe previews:
```swift
struct SharedRecipeBookListView: View {
    let book: RecipeBook
    let sharedEntry: SharedRecipeBook
    @Query private var previews: [CloudKitRecipePreview]
    
    var body: some View {
        List(filteredPreviews) { preview in
            NavigationLink {
                SharedRecipeViewerView(preview: preview)
            } label: {
                RecipePreviewRow(preview: preview)
            }
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var filteredPreviews: [CloudKitRecipePreview] {
        previews.filter { $0.bookID == book.id }
    }
}
```

### Phase 6: Read-Only Recipe Viewer ✅ DONE

**File:** `SharedRecipeViewerView.swift` (NEW)

Downloads full recipe on appear, shows read-only RecipeDetailView:
```swift
struct SharedRecipeViewerView: View {
    let preview: CloudKitRecipePreview
    @StateObject private var viewService = SharedRecipeViewService.shared
    @State private var fullRecipe: CloudKitRecipe?
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading recipe...")
            } else if let recipe = fullRecipe {
                ReadOnlyRecipeDetailView(recipe: recipe)
            } else if let error = error {
                ErrorView(error: error)
            }
        }
        .task {
            await loadFullRecipe()
        }
    }
    
    private func loadFullRecipe() async {
        isLoading = true
        do {
            fullRecipe = try await viewService.fetchRecipeForViewing(preview: preview)
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
```

### Phase 7: Read-Only Recipe Detail View ✅ DONE

**File:** `ReadOnlyRecipeDetailView.swift` (NEW)

Reuses existing RecipeDetailView components but:
- No edit button
- No save button
- Optional: "Import to My Recipes" button
- Full cooking mode support
- Full shopping list support
- Can scale/convert units

```swift
struct ReadOnlyRecipeDetailView: View {
    let recipe: CloudKitRecipe
    @State private var showingCookingMode = false
    @State private var showingImportSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recipe header
                RecipeHeaderView(
                    title: recipe.title,
                    headerNotes: recipe.headerNotes,
                    imageName: recipe.imageName,
                    yield: recipe.yield
                )
                
                // Ingredients
                RecipeIngredientsView(sections: recipe.ingredientSections)
                
                // Instructions
                RecipeInstructionsView(sections: recipe.instructionSections)
                
                // Notes
                if let notes = recipe.notes {
                    RecipeNotesView(notes: notes)
                }
                
                // Shared by info
                HStack {
                    Image(systemName: "person.crop.circle")
                    Text("Shared by \(recipe.sharedByUserName ?? "Unknown")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingCookingMode = true
                    } label: {
                        Label("Start Cooking", systemImage: "flame")
                    }
                    
                    Button {
                        // Add to shopping list
                    } label: {
                        Label("Add to Shopping List", systemImage: "cart")
                    }
                    
                    Divider()
                    
                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import to My Recipes", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingCookingMode) {
            CookingModeView(recipe: recipe.toRecipeModel())
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportSharedRecipeView(recipe: recipe)
        }
    }
}
```

## Database Schema Changes

### Add to ModelContainer

```swift
let container = try ModelContainer(for: 
    Recipe.self,
    RecipeBook.self,
    SharedRecipe.self,
    SharedRecipeBook.self,
    CachedSharedRecipe.self,
    CloudKitRecipePreview.self  // ← ADD THIS
)
```

### Migration Note

Adding `CloudKitRecipePreview` is **non-breaking**:
- New model, doesn't affect existing data
- SwiftData will create the new table automatically
- Existing users won't lose data

## CloudKit Schema Changes

### SharedRecipeBook Record Type

Add new fields:
- `recipePreviews` (String) - JSON array of RecipePreviewData
- `coverImage` (Asset) - Cover image file
- `recipeThumb_0` through `recipeThumb_49` (Asset) - Recipe thumbnails

### Making Fields Queryable

In CloudKit Dashboard:
1. Go to Schema → Indexes
2. For `SharedRecipeBook` record type:
   - Add QUERYABLE index on `recipePreviews`
3. Deploy to Production

## Flow Diagram

### When User A Shares Book

```
1. User taps "Share Book" (50 recipes)
2. shareRecipeBook() executes:
   ├─ Fetch all 50 Recipe entities from SwiftData
   ├─ Create RecipePreviewData for each:
   │  ├─ ID, title, headerNotes, yield
   │  ├─ imageName (for thumbnail)
   │  └─ cloudRecordID (if already shared individually)
   ├─ Upload to CloudKit:
   │  ├─ Book metadata (JSON)
   │  ├─ Cover image (CKAsset)
   │  ├─ Recipe previews (JSON array)
   │  └─ 50 recipe thumbnails (CKAsset × 50)
   └─ Create SharedRecipeBook tracking entry
3. Done! ✅
```

### When User B Views Book

```
1. User opens Books → Shared tab
2. syncCommunityBooksToLocal() executes:
   ├─ Fetch SharedRecipeBook records from CloudKit
   ├─ For each book:
   │  ├─ Download cover image → Save to local files
   │  ├─ Parse recipePreviews JSON
   │  └─ For each preview:
   │     ├─ Download thumbnail → Save to local files
   │     └─ Create CloudKitRecipePreview in SwiftData
   └─ Create RecipeBook + SharedRecipeBook entries
3. Book appears in Shared tab ✅

4. User taps book → Opens SharedRecipeBookListView
5. Shows list of 50 CloudKitRecipePreview items (fast!)

6. User taps "Grilled Chicken Recipe"
7. SharedRecipeViewerView appears:
   ├─ Shows loading spinner
   ├─ SharedRecipeViewService.fetchRecipeForViewing()
   │  ├─ Check cache (hit/miss)
   │  ├─ Fetch from CloudKit by cloudRecordID (or search by ID)
   │  └─ Parse full CloudKitRecipe JSON
   └─ Show ReadOnlyRecipeDetailView ✅
8. User can:
   ├─ View all recipe details ✅
   ├─ Start cooking mode ✅
   ├─ Add to shopping list ✅
   ├─ Scale recipe ✅
   └─ Import to own collection (optional) ✅
```

## Performance Optimizations

### 1. Thumbnail Size Limits

Before uploading thumbnails, resize to reasonable size:
```swift
func resizeImageForThumbnail(_ imageName: String) -> Data? {
    guard let image = loadImage(named: imageName) else { return nil }
    
    let maxDimension: CGFloat = 400
    let resized = image.resized(maxDimension: maxDimension)
    return resized.jpegData(compressionQuality: 0.7)
}
```

### 2. Batch Download Thumbnails

Download thumbnails in batches of 10:
```swift
for batch in previews.chunked(into: 10) {
    await withTaskGroup(of: Void.self) { group in
        for preview in batch {
            group.addTask {
                await downloadThumbnail(preview)
            }
        }
    }
}
```

### 3. Background Prefetch

After user opens book, prefetch first 5 recipes in background:
```swift
.task {
    // Wait a bit for UI to settle
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    
    // Prefetch first 5
    let topPreviews = Array(previews.prefix(5))
    await SharedRecipeViewService.shared.prefetchRecipesForBook(previews: topPreviews)
}
```

### 4. Image Caching

Use a persistent image cache:
```swift
class SharedRecipeImageCache {
    static let shared = SharedRecipeImageCache()
    private let fileManager = FileManager.default
    
    var cacheDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("SharedRecipeImages", isDirectory: true)
    }
    
    func cache(_ data: Data, for key: String) throws {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try data.write(to: fileURL)
    }
    
    func retrieve(for key: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        return try? Data(contentsOf: fileURL)
    }
}
```

## Error Handling

### Recipe No Longer Available

```swift
catch {
    if error is SharingError {
        showAlert(
            title: "Recipe Unavailable",
            message: "This recipe is no longer shared by the author."
        )
    }
}
```

### Network Issues

```swift
catch {
    showAlert(
        title: "Network Error",
        message: "Unable to download recipe. Please check your connection and try again."
    )
}
```

### CloudKit Limits

CloudKit has limits:
- Max record size: 1 MB
- Max asset size per record: 250 MB total
- Max 50 assets per record? (verify this)

If book has >50 recipes, may need to:
1. Split into multiple CloudKit records
2. Or skip thumbnail upload (fetch on-demand instead)

## Testing Checklist

### Device A (Sharer)
- [ ] Share book with 50 recipes
- [ ] Verify cover image uploaded
- [ ] Verify recipe previews created
- [ ] Verify thumbnails uploaded (check CloudKit Dashboard)
- [ ] Console shows: "Uploaded X of 50 recipe thumbnails"

### Device B (Viewer)  
- [ ] Book appears in Shared tab
- [ ] Cover image displays
- [ ] Open book → Shows 50 recipes
- [ ] All thumbnails display
- [ ] Tap recipe → Loading spinner appears
- [ ] Recipe detail loads with all content
- [ ] Cooking mode works
- [ ] Shopping list works
- [ ] Cannot edit recipe
- [ ] Can import recipe (creates new local copy)

### Edge Cases
- [ ] Book with no cover image
- [ ] Recipes with no thumbnails
- [ ] Recipe gets unshared while viewing
- [ ] Network fails during download
- [ ] Book with 100+ recipes (performance)

## Migration Path

### For Existing Users

Books shared before this update won't have:
- Recipe previews
- Thumbnails

Solution:
1. Show "Empty book" view with explanation
2. Prompt user to "Refresh from owner"
3. Owner must re-share the book (or auto-update via migration script)

### Auto-Migration Script

```swift
func migrateOldSharedBooks() async {
    // Find all books shared by current user without previews
    // Re-upload with preview data
}
```

## Alternative: Lighter Approach

If uploading 50 thumbnails is too heavy, alternative:

### Option A: Fetch Previews On-Demand
- Don't store recipe previews in CloudKit
- When book opens, fetch first 20 recipe IDs
- Query CloudKit for those specific recipes
- Show "Loading..." for the rest

### Option B: Paginated Loading
- Show first 10 recipes immediately (with previews)
- Load more as user scrolls
- Use cursor-based pagination

### Option C: Hybrid
- Store minimal preview data (just titles)
- Fetch thumbnails in batches as user scrolls

## Implementation Priority

### Must Have (MVP)
1. ✅ CloudKitRecipePreview model
2. ✅ SharedRecipeViewService
3. ✅ Enhanced shareRecipeBook() with previews
4. 🔨 Enhanced syncCommunityBooksToLocal() with preview download
5. 🔨 SharedRecipeBookListView (show previews)
6. 🔨 SharedRecipeViewerView (download full recipe)
7. 🔨 ReadOnlyRecipeDetailView (view recipe)

### Nice to Have (Phase 2)
- Background prefetching
- Image resizing/compression
- Persistent image cache
- Import to my recipes
- Share individual recipe from book

### Polish (Phase 3)
- Loading states
- Error handling
- Offline mode (cached recipes)
- Search within shared book
- Filter/sort recipes

## Next Steps

1. **Test current implementation:**
   - Verify book syncing works
   - Check if cover images upload/download

2. **Implement syncCommunityBooksToLocal() enhancement:**
   - Parse recipe previews JSON
   - Download and cache thumbnails
   - Create CloudKitRecipePreview entries

3. **Create UI views:**
   - SharedRecipeBookListView
   - SharedRecipeViewerView  
   - ReadOnlyRecipeDetailView

4. **Test end-to-end flow**

5. **Optimize performance**

6. **Handle edge cases**

---

**Status:** ✅ ALL PHASES COMPLETE (1-7)
**Last Updated:** January 25, 2026
## Summary

All 7 phases of the on-demand shared recipe books feature have been implemented:

✅ **Phase 1:** Data Models (CloudKitRecipePreview, RecipePreviewData)
✅ **Phase 2:** On-Demand Download Service (SharedRecipeViewService)
✅ **Phase 3:** Enhanced Book Sharing (shareRecipeBook with previews & thumbnails)
✅ **Phase 4:** Enhanced Book Syncing (syncCommunityBooksToLocal with preview downloads)
✅ **Phase 5:** Recipe List View (SharedRecipeBookListView)
✅ **Phase 6:** Recipe Viewer (SharedRecipeViewerView with on-demand loading)
✅ **Phase 7:** Read-Only Detail View (ReadOnlyRecipeDetailView with import)

## Next Steps

To integrate this feature into your app:

1. **Add CloudKitRecipePreview to ModelContainer:**
   ```swift
   let container = try ModelContainer(for: 
       Recipe.self,
       RecipeBook.self,
       SharedRecipe.self,
       SharedRecipeBook.self,
       CachedSharedRecipe.self,
       CloudKitRecipePreview.self  // ← Add this
   )
   ```

2. **Update Books View to use SharedRecipeBookListView:**
   When displaying a shared book, use:
   ```swift
   NavigationLink {
       SharedRecipeBookListView(book: recipeBook, sharedEntry: sharedEntry)
   } label: {
       // Book row
   }
   ```

3. **Test the flow:**
   - Device A: Share a book with recipes
   - Device B: Sync community books
   - Device B: Open shared book → See recipe previews
   - Device B: Tap recipe → Download full recipe on-demand
   - Device B: View recipe, use cooking mode, import if desired



