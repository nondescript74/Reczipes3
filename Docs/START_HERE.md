# 🚀 START HERE - CookingMode Integration

## Welcome!

You're about to add a professional dual-recipe cooking mode to your reczipes2-imageextract iOS app. This feature lets users view and work with two recipes simultaneously - side-by-side on iPad/Mac, swipeable on iPhone.

## 📦 What You Have

Inside the **CookingMode** folder:

### Core Files (Add to Xcode)
- **KeepAwakeManager.swift** - Keeps screen awake
- **CookingSession.swift** - Saves recipe selection
- **CookingViewModel.swift** - Manages state
- **CookingView.swift** - Main view
- **RecipePanel.swift** - Recipe display
- **RecipePickerSheet.swift** - Recipe selector
- **RecipeDetailView.swift** - Full recipe view

### Documentation (Read as needed)
- **README.md** - Feature overview
- **INTEGRATION_GUIDE.md** - Detailed steps
- **QUICK_START.md** - Fast checklist

### Helper Files (In parent outputs folder)
- **XCODE_INTEGRATION_STEPS.md** - Visual guide with screenshots descriptions
- **Example_AppFile_Update.swift** - Shows app file changes
- **Example_ContentView_Update.swift** - Shows tab addition
- **RecipeModelCompatibilityCheck.swift** - Verify your Recipe model
- **INTEGRATION_SUMMARY.md** - This overview

## ⚡ Fast Track (5 Minutes)

### Step 1: Add to Xcode (2 min)
1. Open your `reczipes2-imageextract.xcodeproj`
2. Drag **CookingMode** folder into project
3. Check ✅ "Copy items if needed"
4. Check ✅ Your app target

### Step 2: Update App File (1 min)
Find your app file (e.g., `reczipes2_imageextractApp.swift`):

```swift
// ADD THIS:
try ModelContainer(for: Recipe.self, CookingSession.self)
//                                   ^^^^^^^^^^^^^^^^^^
```

### Step 3: Add Tab (1 min)
In your `ContentView.swift` TabView:

```swift
CookingView()
    .tabItem {
        Label("Cooking", systemImage: "flame.fill")
    }
```

### Step 4: Build & Run (1 min)
- Press ⌘B to build
- Press ⌘R to run
- Look for 🔥 Cooking tab

## 📱 Test It

**iPhone:**
- Tap Cooking tab
- Select a recipe
- Swipe left → select another
- Toggle keep awake (eye icon)

**iPad:**
- See both recipes side-by-side
- Select different recipes in each panel
- Both visible simultaneously

## ❓ Need Help?

**Read these in order:**

1. **Having trouble?** → XCODE_INTEGRATION_STEPS.md (most detailed)
2. **Want quick reference?** → QUICK_START.md
3. **Need full docs?** → INTEGRATION_GUIDE.md
4. **Recipe model different?** → RecipeModelCompatibilityCheck.swift

## 🔧 Common Issues

### "Cannot find CookingSession"
→ Add `CookingSession.self` to ModelContainer

### "Cannot find Recipe"
→ Check if your Recipe properties match requirements
→ See RecipeModelCompatibilityCheck.swift

### Build works but crashes
→ Check both models in ModelContainer
→ Look at console for SwiftData errors

### Cooking tab is blank
→ Make sure you have recipes in your database
→ Check target membership of all files

## ✨ Modern Code Quality

This uses the latest patterns:
- ✅ `@Observable` (not ObservableObject)
- ✅ `@Query` for SwiftData
- ✅ iOS 17+ features
- ✅ Full CloudKit sync support
- ✅ Adaptive layouts
- ✅ Accessibility built-in

## 🎯 What Your Users Get

- Work with 2 recipes at once
- iPad: Side-by-side view
- iPhone: Swipeable interface
- Keep screen awake option
- Auto-scale ingredients
- Check off cooking steps
- Session saves automatically

## 🚀 Ready?

1. Start with **XCODE_INTEGRATION_STEPS.md** for detailed walkthrough
2. Or jump in with the Fast Track above
3. Share your Recipe model if you need customization

**Estimated time:** 5-10 minutes for complete integration

## 💬 Questions?

If your Recipe model has different property names or structure, just share it and I'll adjust the code to match perfectly!

---

**Let's get cooking!** 🔥👨‍🍳
