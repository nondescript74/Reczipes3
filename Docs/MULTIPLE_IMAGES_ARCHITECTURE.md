# Multiple Images Architecture Diagram

## Data Model Structure

```
┌─────────────────────────────────────────────────────────────┐
│                      Recipe (@Model)                         │
├─────────────────────────────────────────────────────────────┤
│ id: UUID                                                     │
│ title: String                                                │
│ imageName: String?           ← Main image (immutable in UI) │
│ additionalImageNames: [String]?  ← User-added images        │
│ ...                                                          │
├─────────────────────────────────────────────────────────────┤
│ Computed Properties:                                         │
│ • allImageNames: [String]    ← [imageName] + additional     │
│ • imageCount: Int            ← Total count of images        │
└─────────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────────┐
│                   RecipeModel (struct)                       │
├─────────────────────────────────────────────────────────────┤
│ id: UUID                                                     │
│ title: String                                                │
│ imageName: String?                                           │
│ additionalImageNames: [String]?                              │
│ ...                                                          │
├─────────────────────────────────────────────────────────────┤
│ Computed Properties:                                         │
│ • allImageNames: [String]                                    │
│ • imageCount: Int                                            │
└─────────────────────────────────────────────────────────────┘
```

## UI Component Hierarchy

```
RecipeImageAssignmentView
    │
    ├─── Permission/Loading States
    │
    └─── List
         │
         └─── ForEach(allRecipes)
              │
              └─── RecipePhotoRow
                   ├─── Main Image Display (60x60)
                   │    └─── "MAIN" badge overlay
                   │
                   ├─── Recipe Info VStack
                   │    ├─── Title
                   │    └─── "Main + X additional" text
                   │
                   ├─── [+] Button → Opens MultiPhotoPickerSheet
                   │
                   └─── Horizontal ScrollView (if additionalImageNames exists)
                        │
                        └─── ForEach(additionalImageNames)
                             └─── Image (50x50) with [X] button
```

## Multi-Selection Flow

```
User taps [+] button
        ↓
MultiPhotoPickerSheet presented
        ↓
┌─────────────────────────────────────────────┐
│  [Cancel]  Add Photos  [Add X]              │
├─────────────────────────────────────────────┤
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐              │
│  │ ☑️ │ │    │ │    │ │ ☑️ │  ← Grid      │
│  └────┘ └────┘ └────┘ └────┘              │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐              │
│  │    │ │ ☑️ │ │    │ │    │              │
│  └────┘ └────┘ └────┘ └────┘              │
├─────────────────────────────────────────────┤
│  3 photos selected        [Clear]           │
└─────────────────────────────────────────────┘
        ↓
User taps "Add 3"
        ↓
For each selected asset:
  1. Load full-resolution image
  2. Generate unique filename
  3. Save to Documents directory
  4. Add filename to recipe.additionalImageNames
        ↓
Save modelContext
        ↓
Dismiss sheet
        ↓
RecipePhotoRow updates automatically
```

## File System Organization

```
Documents/
│
├─── recipe_12345678-1234-5678-1234-567812345678.jpg
│    └─── Main image (set during extraction)
│
├─── recipe_12345678-1234-5678-1234-567812345678_additional_1702987654_1234.jpg
│    └─── Additional image #1 (user-added)
│
├─── recipe_12345678-1234-5678-1234-567812345678_additional_1702987890_5678.jpg
│    └─── Additional image #2 (user-added)
│
└─── recipe_87654321-4321-8765-4321-876543218765.jpg
     └─── Another recipe's main image
```

## State Management

```
┌─────────────────────────────────────────────────────────────┐
│                RecipeImageAssignmentView                     │
├─────────────────────────────────────────────────────────────┤
│ @Environment(\.modelContext)                                 │
│ @Query private var savedRecipes: [Recipe]  ← SwiftData      │
│ @StateObject private var photoLibrary: PhotoLibraryManager   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                     RecipePhotoRow                           │
├─────────────────────────────────────────────────────────────┤
│ let recipe: RecipeModel            ← For display             │
│ let recipeEntity: Recipe           ← For mutations           │
│ let modelContext: ModelContext     ← For saving              │
│ @State private var showingPhotoPicker: Bool                  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│               MultiPhotoPickerSheet                          │
├─────────────────────────────────────────────────────────────┤
│ let recipeEntity: Recipe                                     │
│ let modelContext: ModelContext                               │
│ @State private var selectedAssets: Set<String>  ← Selection │
└─────────────────────────────────────────────────────────────┘
```

## Image Lifecycle

### Adding Images
```
1. User taps [+] in RecipePhotoRow
   ↓
2. MultiPhotoPickerSheet appears
   ↓
3. User taps photos to select (Set<String> of identifiers)
   ↓
4. User taps "Add X"
   ↓
5. For each selected PHAsset:
   - Load UIImage at full resolution
   - Generate unique filename
   - Save JPEG (80% quality) to Documents
   - Add filename to array
   ↓
6. Update recipeEntity.additionalImageNames
   ↓
7. Save modelContext
   ↓
8. Sheet dismisses
   ↓
9. RecipePhotoRow observes change and refreshes
```

### Removing Images
```
1. User taps [X] on additional image
   ↓
2. removeAdditionalImage(at:) called
   ↓
3. Get filename from array
   ↓
4. Delete file from Documents directory
   ↓
5. Remove from recipeEntity.additionalImageNames array
   ↓
6. Save modelContext
   ↓
7. UI updates automatically
```

## Key Design Decisions

### 1. Main Image Immutability
- **Why**: Preserves the originally extracted image as the "canonical" representation
- **How**: Main image is only displayed, no edit/remove buttons in the UI
- **Benefit**: Users always have the original extraction context

### 2. Direct Recipe Entity Manipulation
- **Why**: Eliminates intermediate `RecipeImageAssignment` model complexity
- **How**: Pass both `RecipeModel` (for display) and `Recipe` (for mutations)
- **Benefit**: Simpler architecture, fewer models, direct relationship

### 3. Set-Based Selection
- **Why**: Efficient O(1) lookup for selection state
- **How**: `Set<String>` using asset.localIdentifier
- **Benefit**: Supports discontinuous selection with fast performance

### 4. Separate Main vs Additional
- **Why**: Different purposes and lifecycles
- **How**: Two separate properties in the model
- **Benefit**: Clear separation of concerns, easy to protect main image

### 5. Optional Array
- **Why**: Most recipes won't have additional images initially
- **How**: `additionalImageNames: [String]?` instead of `[String]`
- **Benefit**: Memory efficient, backwards compatible

## Migration Path

### From Old System
```
OLD:
RecipeImageAssignment
├─── recipeID: UUID
└─── imageName: String

Recipe
└─── imageName: String?  (sometimes unused)

NEW:
Recipe
├─── imageName: String?           (main image)
└─── additionalImageNames: [String]?  (user gallery)
```

### Compatibility
- Old recipes with `imageName` work as-is (becomes main image)
- Old `RecipeImageAssignment` entries can be migrated or ignored
- New field is optional, so no schema migration required
- Existing image files in Documents remain valid

## Performance Considerations

1. **Lazy Loading**: Images loaded on-demand as user scrolls
2. **Thumbnail Caching**: PhotoLibraryManager caches thumbnails
3. **Set Operations**: O(1) selection checks in multi-picker
4. **Async Image Loading**: All image operations use async/await
5. **Compression**: JPEG at 80% quality balances size and visual quality

## Security & Privacy

1. **Photo Library Access**: Respects iOS permission system
2. **Limited Photo Access**: Gracefully handles partial library access
3. **Sandboxed Storage**: All images in app's Documents directory
4. **No Cloud Sync**: Images remain on device (unless user has iCloud backup)
5. **Clean Deletion**: Files properly removed from filesystem when images deleted
