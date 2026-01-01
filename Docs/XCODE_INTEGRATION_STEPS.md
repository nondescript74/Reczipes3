# Visual Integration Guide for Xcode

## 🎯 Complete Integration in 5 Minutes

### Step 1: Download and Prepare Files
1. Download the entire `CookingMode` folder from outputs
2. Note where you saved it (e.g., `~/Downloads/CookingMode`)

### Step 2: Add Files to Xcode Project

**Method A: Drag and Drop (Easiest)**

1. Open `reczipes2-imageextract.xcodeproj` in Xcode
2. In Project Navigator (left sidebar), right-click on your project root
3. Select "New Group" → Name it "CookingMode"
4. Open Finder and navigate to your downloaded CookingMode folder
5. Select all 7 .swift files:
   - KeepAwakeManager.swift
   - CookingSession.swift
   - CookingViewModel.swift
   - CookingView.swift
   - RecipePanel.swift
   - RecipePickerSheet.swift
   - RecipeDetailView.swift
6. Drag them into the CookingMode group in Xcode
7. In the dialog that appears:
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Ensure your app target is selected
   - Click "Finish"

**Method B: Use File Menu**

1. In Xcode: File → Add Files to "reczipes2-imageextract"
2. Navigate to your CookingMode folder
3. Select all .swift files
4. ✅ Check "Copy items if needed"
5. ✅ Check "Create groups"
6. ✅ Select your app target
7. Click "Add"

### Step 3: Update SwiftData ModelContainer

Find your app file (probably named something like `reczipes2_imageextractApp.swift`):

**Before:**
```swift
@main
struct reczipes2_imageextractApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Recipe.self
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
```

**After:**
```swift
@main
struct reczipes2_imageextractApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Recipe.self,
                CookingSession.self  // ← ADD THIS LINE
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
```

### Step 4: Add Cooking Tab to ContentView

Find your `ContentView.swift` and add the new tab:

**Before:**
```swift
struct ContentView: View {
    var body: some View {
        TabView {
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
            // Maybe other tabs here
        }
    }
}
```

**After:**
```swift
struct ContentView: View {
    var body: some View {
        TabView {
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
            
            // NEW TAB ↓
            CookingView()
                .tabItem {
                    Label("Cooking", systemImage: "flame.fill")
                }
            
            // Your other tabs
        }
    }
}
```

### Step 5: Build and Run

1. Press `⌘B` to build
2. Fix any compiler errors (see Troubleshooting below)
3. Press `⌘R` to run
4. Look for new "Cooking" tab with flame icon 🔥

### Step 6: Test the Feature

**On iPhone Simulator:**
1. Tap "Cooking" tab
2. Tap empty slot
3. Search/select a recipe
4. Swipe left to second slot
5. Select another recipe
6. Swipe between them
7. Test keep awake toggle (eye icon)

**On iPad Simulator:**
1. Switch to iPad simulator
2. Run app again
3. Tap "Cooking" tab
4. See side-by-side layout
5. Select recipe in left panel
6. Select different recipe in right panel
7. Both should be visible simultaneously

## 🔧 Troubleshooting

### Error: "Cannot find 'CookingSession' in scope"

**Fix:** Make sure you added `CookingSession.self` to ModelContainer in your app file.

### Error: "Cannot find 'Recipe' in scope" (in CookingMode files)

**Possible causes:**
1. Recipe model is in different module/target
2. Recipe model has different property names

**Fix for cause 1:**
If your Recipe is in a different module, add import at top of files:
```swift
import YourRecipeModule
```

**Fix for cause 2:**
Check if your Recipe properties match (see Recipe_Model_Requirements.swift)

### Error: Building for iOS but recipe properties don't match

**Your Recipe might use different names:**
- Your code: `steps` vs Expected: `instructions`
- Your code: `servingSize` vs Expected: `servings`

**Solution:** Let me know your actual Recipe property names and I'll update the files!

### Build succeeds but app crashes on launch

**Check:**
1. SwiftData container has both Recipe.self and CookingSession.self
2. All files are in the correct target
3. Check console for specific error message

### Cooking tab appears but shows blank/error

**Debug:**
1. Check if you have any Recipe objects in your database
2. Add a test recipe first
3. Check console logs for SwiftData errors

## 📋 Verification Checklist

After integration, verify:
- [ ] ✅ Project builds without errors
- [ ] ✅ App launches successfully
- [ ] ✅ "Cooking" tab appears in TabView
- [ ] ✅ Can select first recipe
- [ ] ✅ Can select second recipe
- [ ] ✅ Can swap recipes
- [ ] ✅ Can clear recipes
- [ ] ✅ Keep awake toggle works
- [ ] ✅ Session persists (close/reopen app)

## 🎨 Customization After Integration

Once it's working, you can customize:

### Change Tab Icon Color
```swift
.tabItem {
    Label("Cooking", systemImage: "flame.fill")
}
.tint(.orange) // Add this to TabView
```

### Change Empty State Message
Edit `RecipePanel.swift`, find `EmptyRecipeSlot`:
```swift
Text("Select a Recipe")  // Change this text
```

### Adjust Serving Size Steps
Edit `RecipeDetailView.swift`, find serving controls:
```swift
servingMultiplier += 0.5  // Change to 0.25, 1.0, etc.
```

## 🆘 Need Help?

If you get stuck:
1. Check the error message in Xcode console
2. Verify all files are in the project navigator
3. Make sure target membership is correct
4. Try cleaning build folder (⌘⇧K)
5. Share the specific error with me and I'll help fix it!

## ✨ You're Done!

Your users can now:
- Cook with two recipes at once
- See both recipes side-by-side on iPad
- Swipe between recipes on iPhone
- Keep screen awake while cooking
- Scale ingredients automatically
- Track their progress through steps

Enjoy the new cooking mode! 🔥👨‍🍳
