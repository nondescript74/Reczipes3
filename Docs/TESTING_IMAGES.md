# Testing Image Display - Step by Step

## ✅ What Should Happen Now

### In ContentView (Recipe List)

**Before Assignment:**
```
┌─────────┐
│ Assign  │  Recipe Title
│  Image  │  Header notes...
└─────────┘
```

**After Assignment:**
```
┌─────────┐
│  [IMG]  │  Recipe Title
│  50x50  │  Header notes...
└─────────┘
```

### In RecipeDetailView

**Before Assignment:**
- Title at top
- No image shown

**After Assignment:**
- **Large image at top** (full width, 250px height)
- Title below image
- All other content follows

## 🧪 Test Steps

### 1. Verify Images Are in Assets
1. Open Assets.xcassets
2. Confirm you have these images:
   - AmNC
   - CaPi
   - CoCh
   - etc. (all the names from RecipeImageAssignmentView.swift)

### 2. Test Assignment Flow
1. Launch app
2. Tap **📷 camera icon** in toolbar
3. Find "Lime Pickle" recipe
4. Tap the **+** button next to it
5. Select "AmNC" image
6. Tap to assign
7. **Sheet dismisses**

### 3. Verify Immediate Display
**In Assignment View:**
- ✅ Should now show "AmNC" thumbnail next to Lime Pickle
- ✅ X button should appear (to remove)
- ✅ + button changes to pencil icon

**Tap Done to close sheet**

### 4. Check Recipe List
**In ContentView:**
- ✅ Lime Pickle should now show **AmNC thumbnail** (50x50)
- ✅ "Assign Image" placeholder should be **gone**

### 5. Check Recipe Detail
**Tap on Lime Pickle:**
- ✅ Large image should appear at **top of detail view**
- ✅ Image should be **full width** (~screen width - 32px)
- ✅ Image height should be **250px**
- ✅ Image has **shadow and rounded corners**

### 6. Test Persistence
1. Close app completely (swipe up from app switcher)
2. Relaunch app
3. ✅ Lime Pickle should **still have thumbnail**
4. ✅ Detail view should **still show image**

## 🔍 Troubleshooting

### Images Not Showing in List?

**Check 1: Query is loading**
```swift
// In ContentView, make sure this line exists:
@Query private var imageAssignments: [RecipeImageAssignment]
```

**Check 2: Merge is happening**
```swift
// availableRecipes should use .map to merge:
private var availableRecipes: [RecipeModel] {
    RecipeModel.allRecipes.map { recipe in
        if let assignedImageName = imageName(for: recipe.id) {
            return recipe.withImageName(assignedImageName)
        }
        return recipe
    }
}
```

**Check 3: UI uses recipe.imageName**
```swift
// In ForEach, should check recipe.imageName:
if let imageName = recipe.imageName {
    RecipeImageView(imageName: imageName, ...)
}
```

### Images Not Showing in Detail?

**Check 1: Import SwiftData**
```swift
import SwiftUI
import SwiftData  // ← Make sure this is here
```

**Check 2: Query exists**
```swift
@Query private var imageAssignments: [RecipeImageAssignment]
```

**Check 3: currentImageName is used**
```swift
if let imageName = currentImageName {  // ← Not recipe.imageName
    RecipeImageView(...)
}
```

### Images Not Persisting?

**Check 1: Schema includes RecipeImageAssignment**
In `Reczipes2App.swift`:
```swift
let schema = Schema([
    Recipe.self,
    RecipeImageAssignment.self,  // ← Must be here
])
```

**Check 2: SwiftData isn't in memory only**
```swift
// Should be false:
ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
```

### Image Names Don't Match?

**Check Assets:**
1. Image name in Assets is **case-sensitive**
2. Must match **exactly** what's in `availableImages` array
3. No spaces, special characters matter

**Example:**
```
Asset name: "AmNC" 
Array: "AmNC" ✅
Array: "amnc" ❌
Array: "Am NC" ❌
```

## 🎯 Expected Visual Result

### Recipe List View
```
┌────────────────────────────────────────┐
│ Available Recipes                      │
│                                        │
│ ┌──┐  Lime Pickle                     │
│ │📷│  Limes take approximately...     │
│ └──┘                                   │
│                                        │
│ ┌──┐  Ambli ni Chutney                │
│ │📷│  Tamarind Sauce                  │
│ └──┘                                   │
│                                        │
│ ┌───────┐  Carrot Pickle              │
│ │Assign │  Makes 1 to 1½ cups...      │
│ │Image  │                              │
│ └───────┘                              │
└────────────────────────────────────────┘
```

### Recipe Detail View
```
┌────────────────────────────────────────┐
│                                        │
│ ┌────────────────────────────────────┐│
│ │                                    ││
│ │        [Recipe Image]              ││
│ │         250px tall                 ││
│ │      Full width minus 16px         ││
│ │                                    ││
│ └────────────────────────────────────┘│
│                                        │
│ Lime Pickle                [Save]     │
│ Limes take approximately 15-30 days...│
│                                        │
│ 📊 Makes 2 quarts (2 L)               │
│ ─────────────────────────────────────  │
│                                        │
│ 📝 Ingredients                         │
│ ...                                    │
└────────────────────────────────────────┘
```

## 🚨 Common Issues

### Issue: "Cannot find 'RecipeImageView' in scope"
**Solution:** Make sure RecipeImageView.swift is in your target

### Issue: "Cannot find 'RecipeImageAssignment' in scope"  
**Solution:** Make sure RecipeImageAssignment.swift is in your target

### Issue: Image shows broken/missing
**Solution:** Image name doesn't exist in Assets - check spelling

### Issue: Changes don't appear
**Solution:** Clean build folder (⌘⇧K) and rebuild (⌘B)

## ✨ Success Criteria

When everything works:
1. ✅ Assign image → See thumbnail immediately in list
2. ✅ Tap recipe → See large image in detail
3. ✅ Close app → Reopen → Image still there
4. ✅ Assign different image → Updates immediately
5. ✅ Remove image → Placeholder appears immediately
