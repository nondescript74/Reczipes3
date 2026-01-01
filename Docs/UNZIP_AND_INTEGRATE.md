# After Unzipping - Quick Instructions

## 📁 You Just Unzipped

You should now have:
- **CookingMode/** folder (7 Swift files + 3 docs)
- **START_HERE.md** ← Read this first!
- **XCODE_INTEGRATION_STEPS.md** ← Step-by-step guide
- Several helper files

## 🚀 Integration in 3 Steps

### Step 1: Add CookingMode to Xcode (2 min)

1. Open `Reczipes2.xcodeproj` in Xcode
2. Drag the **CookingMode** folder into your project navigator
3. In the dialog:
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Select Reczipes2 target
   - Click "Finish"

### Step 2: Update Your App File (1 min)

Find your app file (likely `Reczipes2App.swift` or similar):

**Add `CookingSession.self` to your ModelContainer:**

```swift
@main
struct Reczipes2App: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Recipe.self,
                CookingSession.self  // ← ADD THIS
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

### Step 3: Add Cooking Tab (1 min)

In your `ContentView.swift`, add the new tab:

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            // Your existing tabs
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
            
            // NEW TAB ↓
            CookingView()
                .tabItem {
                    Label("Cooking", systemImage: "flame.fill")
                }
            
            // Other tabs...
        }
    }
}
```

## ✅ Build and Test

1. Press `⌘B` to build
2. Press `⌘R` to run
3. Look for the 🔥 Cooking tab
4. Test on iPhone and iPad simulators!

## 📖 Need More Help?

Read these files in order:
1. **START_HERE.md** - Quick overview
2. **XCODE_INTEGRATION_STEPS.md** - Detailed walkthrough
3. **INTEGRATION_SUMMARY.md** - Feature summary

## 🔧 If Your Recipe Model is Different

See **RecipeModelCompatibilityCheck.swift** to verify your Recipe properties match.
If not, let me know and I'll adjust the code!

## 💬 Questions?

The integration should take 5-10 minutes total.
If you hit any errors, check the troubleshooting section in XCODE_INTEGRATION_STEPS.md

---

**Ready to cook with dual recipes!** 🔥👨‍🍳
