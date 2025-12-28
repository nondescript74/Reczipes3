# Recipe Book Export/Import - Integration Checklist

## ✅ Pre-Integration Checklist

Before you build, make sure you have:

### 1. Add ZIPFoundation Package ⚠️ REQUIRED
- [ ] Open Xcode project
- [ ] Go to **File → Add Package Dependencies**
- [ ] Search for: `https://github.com/weichsel/ZIPFoundation`
- [ ] Select version 0.9.0 or later
- [ ] Add to your app target
- [ ] Build to verify package is added

### 2. Verify Your Recipe Model
Check if your `Recipe` SwiftData model matches the expected structure:

```swift
@Model
class Recipe {
    var id: UUID
    var title: String
    var recipeData: String  // JSON storage of RecipeModel
    var imageName: String?
    var additionalImageNames: [String]?
    var dateCreated: Date
    var dateModified: Date
    // ... other properties
}
```

- [ ] Recipe model has these properties
- [ ] If different, update `Recipe+RecipeModel.swift` to match your model

### 3. Verify RecipeImageView Exists
- [ ] You have a `RecipeImageView` component
- [ ] It accepts `imageName`, `size`, and `cornerRadius` parameters
- [ ] If not, use the reference implementation in `RecipeImageView_Reference.swift`

## 📝 Integration Steps

### Step 1: Add Files to Xcode Project
All new files are created. Add them to your Xcode project:

**Core Implementation:**
- [ ] `RecipeBookExportModel.swift`
- [ ] `RecipeBookExportService.swift`
- [ ] `RecipeBookImportView.swift`
- [ ] `Recipe+RecipeModel.swift`
- [ ] `Color+Hex.swift`
- [ ] `LoggingHelpers.swift`

**Documentation (optional but recommended):**
- [ ] `RECIPE_BOOK_EXPORT_GUIDE.md`
- [ ] `IMPLEMENTATION_NOTES.md`
- [ ] `README_EXPORT_IMPORT.md`

**Modified Files:**
- [ ] `RecipeBookDetailView.swift` (already modified)
- [ ] `RecipeBookEditorView.swift` (check if it matches - should already have cover images)

### Step 2: Register .recipebook File Type
Add to your `Info.plist` to handle `.recipebook` files:

```xml
<key>UTImportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeIdentifier</key>
        <string>com.yourcompany.recipebook</string>
        <key>UTTypeDescription</key>
        <string>Recipe Book</string>
        <key>UTTypeConformsTo</key>
        <array>
            <string>public.data</string>
            <string>public.composite-content</string>
        </array>
        <key>UTTypeTagSpecification</key>
        <dict>
            <key>public.filename-extension</key>
            <array>
                <string>recipebook</string>
            </array>
        </dict>
    </dict>
</array>
```

- [ ] Add `UTImportedTypeDeclarations` to Info.plist
- [ ] Replace `com.yourcompany` with your bundle identifier prefix

### Step 3: Add Import Button to Books List
Open your main books list view (probably `RecipeBooksView.swift`) and add:

```swift
// Add state variable
@State private var showingImport = false

// In toolbar
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Menu {
            Button("New Book") { 
                showingNewBook = true 
            }
            
            Button("Import Book") { 
                showingImport = true 
            }
        } label: {
            Image(systemName: "plus")
        }
    }
}

// Add sheet
.sheet(isPresented: $showingImport) {
    RecipeBookImportView()
}
```

- [ ] Add import state variable
- [ ] Add import button to menu
- [ ] Add sheet for RecipeBookImportView

### Step 4: Build and Test
- [ ] Build project (Cmd+B)
- [ ] Fix any compilation errors
- [ ] Run on simulator/device
- [ ] Test export feature
- [ ] Test import feature

## 🧪 Testing Checklist

### Export Tests
- [ ] Open a recipe book with recipes
- [ ] Tap "•••" → "Export Book"
- [ ] Choose "Export with Images"
- [ ] Verify share sheet appears
- [ ] Share via AirDrop to another device
- [ ] Share via Files app
- [ ] Try "Export without Images"
- [ ] Verify smaller file size

### Import Tests
- [ ] Open books list
- [ ] Tap "Import" button
- [ ] Select a `.recipebook` file
- [ ] Wait for import to complete
- [ ] Verify success alert shows
- [ ] Open imported book
- [ ] Verify recipes are present
- [ ] Verify images are visible
- [ ] Verify colors/themes match

### Edge Cases
- [ ] Try exporting empty book (should be disabled)
- [ ] Try importing corrupted file
- [ ] Try importing same book twice
- [ ] Check behavior with large books (20+ recipes)
- [ ] Test with low storage space

## 🔍 Troubleshooting

### Build Errors

**"Cannot find 'ZIPFoundation' in scope"**
- Solution: Add ZIPFoundation package (see Step 1)

**"Cannot find 'Recipe' in scope"**
- Solution: Ensure Recipe model is imported/accessible

**"Value of type 'Recipe' has no member 'toRecipeModel'"**
- Solution: Add `Recipe+RecipeModel.swift` extension

**"Cannot find 'RecipeImageView' in scope"**
- Solution: Either use your existing RecipeImageView or add the reference implementation

### Runtime Errors

**Export fails with "Access denied"**
- Check: File permissions in Documents directory
- Check: Available storage space

**Import fails with "Invalid format"**
- Check: File has `.recipebook` extension
- Check: File is not corrupted
- Check: File was created with this system

**Images not showing after import**
- Check: Images exist in Documents directory
- Check: Image file names match in manifest
- Check: Sufficient storage for images

### Console Logs

To see detailed logs:
1. Open **Console.app** on Mac
2. Connect your iOS device or select simulator
3. Filter by process: Your app name
4. Filter by category: `book-export` or `book-import`

## 📱 Device Testing

Test on:
- [ ] iPhone (iOS 17+)
- [ ] iPad (iPadOS 17+)
- [ ] Simulator
- [ ] Different iOS versions

## 🎯 Success Criteria

You'll know it's working when:
- ✅ No build errors
- ✅ Export menu appears in book detail view
- ✅ Export creates `.recipebook` file
- ✅ Share sheet works
- ✅ Import button appears in books list
- ✅ Import successfully adds book
- ✅ Images are preserved
- ✅ No crashes or errors

## 📚 Next Steps

After successful integration:
1. [ ] Test thoroughly with real data
2. [ ] Share with beta testers
3. [ ] Consider additional features (see documentation)
4. [ ] Update app documentation
5. [ ] Submit to App Store (if applicable)

## 🎨 Customization Ideas

Consider customizing:
- Export button icon/label
- Import view appearance
- Color themes
- Progress indicator styles
- Success/error messages
- File naming convention

## 🆘 Need Help?

If you encounter issues:
1. Check Console logs (category: "book-export" or "book-import")
2. Review `RECIPE_BOOK_EXPORT_GUIDE.md`
3. Check `IMPLEMENTATION_NOTES.md`
4. Verify all files are added to project
5. Ensure ZIPFoundation is properly added
6. Check file permissions

## ✨ Optional Enhancements

After basic implementation works:
- [ ] Add iCloud export option
- [ ] Add batch export (multiple books)
- [ ] Add export history
- [ ] Add import from URL
- [ ] Add PDF export option
- [ ] Add sharing analytics
- [ ] Add export templates

---

**Ready to integrate?** Follow the steps above in order, and you'll have a fully functional export/import system!

**Estimated Time:** 30-45 minutes for basic integration and testing

**Good luck!** 🚀
