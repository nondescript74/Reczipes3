# Quick Start Guide - Recipe Images

## 🚀 Quick Setup (5 minutes)

### 1. Add Your Images
- Open **Assets.xcassets** in Xcode
- Drag your recipe photos into the asset catalog
- Name them clearly (e.g., "lime-pickle", "tamarind-chutney")

### 2. Update Image List
Open `RecipeImageAssignmentView.swift` and find this line (around line 19):

```swift
@State private var availableImages: [String] = [
```

Replace the example names with your actual image names from Assets:

```swift
@State private var availableImages: [String] = [
    "lime-pickle",
    "tamarind-chutney", 
    "carrot-pickle",
    // ... add all your image names
]
```

### 3. Assign Images to Recipes
1. Run the app
2. Tap the 📷 **camera icon** in the toolbar
3. For each recipe:
   - Tap the **+ button**
   - Select an image from the grid
   - Done! ✅

That's it! Your recipes now have images.

---

## 📖 Using Images in Your Views

### Simple Thumbnail
```swift
RecipeImageView(imageName: recipe.imageName)
```

### Custom Size
```swift
RecipeImageView(
    imageName: recipe.imageName,
    size: CGSize(width: 200, height: 200),
    cornerRadius: 16
)
```

### In a List Row
```swift
HStack {
    RecipeImageView(
        imageName: recipe.imageName,
        size: CGSize(width: 60, height: 60),
        cornerRadius: 8
    )
    
    Text(recipe.title)
        .font(.headline)
}
```

---

## 🎯 Key Features

✅ **One image per recipe** - No duplicates  
✅ **Visual picker** - See before you select  
✅ **Search** - Find images quickly  
✅ **Persistent** - Assignments are saved  
✅ **Reusable** - RecipeImageView works everywhere  

---

## 🔧 Customization Tips

### Change Grid Size
In `ImagePickerSheet` (RecipeImageAssignmentView.swift), modify:
```swift
GridItem(.adaptive(minimum: 100), spacing: 16)
//                        ^^^
// Change 100 to your preferred size
```

### Change Thumbnail Size
In `RecipeImageRow`, modify:
```swift
.frame(width: 60, height: 60)
//           ^^        ^^
// Adjust these values
```

### Add More Metadata
Extend `RecipeImageAssignment` with additional properties:
```swift
@Model
final class RecipeImageAssignment {
    var recipeID: UUID
    var imageName: String
    var caption: String?        // Add this
    var dateAssigned: Date      // Add this
    var photographerCredit: String?  // Add this
    
    // Update initializer accordingly
}
```

---

## ❓ Common Questions

**Q: Can I assign the same image to multiple recipes?**  
A: No, by design. Each image can only be used once. This prevents confusion.

**Q: What happens if I delete an image from Assets?**  
A: The assignment remains, but you'll see a broken image. Remove the assignment and reassign a different image.

**Q: Can I use images from the photo library?**  
A: Not in the current implementation. All images must be in the Assets catalog. This could be extended to support photo library access.

**Q: Will this work with iCloud sync?**  
A: Yes! SwiftData automatically syncs if iCloud is configured for your app.

**Q: How do I remove all assignments?**  
A: Currently, you must remove them one by one using the X button. You could add a "Clear All" button if needed.

---

## 🐛 Troubleshooting

### Images Don't Appear
1. Check image names match exactly (case-sensitive!)
2. Verify images are in the main asset catalog
3. Ensure images are included in your app target

### App Crashes on Launch
1. Check that `RecipeImageAssignment.self` is in the Schema
2. Delete the app and reinstall (development only)
3. Check console for SwiftData errors

### Assignments Not Saving
1. Verify modelContext is properly injected
2. Check that you're calling `modelContext.insert()` or using `@Query`
3. Look for SwiftData errors in the console

---

## 📚 Files Reference

| File | Purpose |
|------|---------|
| `RecipeImageAssignment.swift` | SwiftData model for storing assignments |
| `RecipeImageAssignmentView.swift` | UI for managing image-recipe links |
| `RecipeImageView.swift` | Reusable component for displaying images |
| `RecipeModel.swift` | Updated with `imageName` property |
| `Recipe.swift` | SwiftData recipe model with `imageName` |
| `Extensions.swift` | Recipe definitions with `withImageName()` helper |
| `ContentView.swift` | Added toolbar button to access assignment view |
| `Reczipes2App.swift` | Updated schema to include `RecipeImageAssignment` |

---

## 🎨 Design Ideas

### Grid View for Recipe List
```swift
LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
    ForEach(recipes) { recipe in
        VStack {
            RecipeImageView(
                imageName: recipe.imageName,
                size: CGSize(width: 150, height: 150),
                cornerRadius: 12
            )
            Text(recipe.title)
                .font(.caption)
                .lineLimit(2)
        }
    }
}
```

### Card Style
```swift
VStack(alignment: .leading) {
    RecipeImageView(
        imageName: recipe.imageName,
        size: CGSize(width: 300, height: 200),
        cornerRadius: 12
    )
    
    VStack(alignment: .leading, spacing: 4) {
        Text(recipe.title)
            .font(.headline)
        Text(recipe.headerNotes ?? "")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
.background(Color(.systemBackground))
.cornerRadius(12)
.shadow(radius: 4)
```

---

## 🚀 Next Steps

1. ✅ Add images to Assets
2. ✅ Update available images list
3. ✅ Assign images to recipes
4. 📝 Integrate images in RecipeDetailView (see `RecipeDetailView+ImageExample.swift`)
5. 📝 Add thumbnails to recipe list in ContentView
6. 🎨 Customize the UI to match your app's style

---

## 📄 License & Attribution

This implementation uses only standard Apple frameworks:
- SwiftUI
- SwiftData
- Foundation

No external dependencies required!

---

**Need Help?** Check `IMPLEMENTATION_SUMMARY.md` for detailed technical documentation.
