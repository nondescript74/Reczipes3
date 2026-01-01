# Quick Integration Checklist

## ✅ Step-by-Step Integration

### 1. Add Files to Xcode
- [ ] Create "CookingMode" group in Xcode project navigator
- [ ] Drag all 7 Swift files into the group
- [ ] Verify target membership is checked

### 2. Update Your App File
```swift
import SwiftData

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
            fatalError("Could not initialize ModelContainer: \(error)")
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

### 3. Add to Your TabView
```swift
struct ContentView: View {
    var body: some View {
        TabView {
            // Your existing tabs...
            
            CookingView()  // ← ADD THIS
                .tabItem {
                    Label("Cooking", systemImage: "flame.fill")
                }
        }
    }
}
```

### 4. Build and Test
- [ ] Build project (⌘B)
- [ ] Run on iPhone simulator
- [ ] Run on iPad simulator
- [ ] Test recipe selection
- [ ] Test keep awake toggle
- [ ] Test serving adjustment
- [ ] Test step tracking

## 🔧 If You Get Errors

### "Cannot find 'Recipe' in scope"
Your Recipe model needs these properties at minimum:
- `id: UUID`
- `title: String`
- `ingredients: [String]`
- `instructions: [String]`

Optional but recommended:
- `cuisine: String?`
- `servings: Int?`
- `prepTime: String?`
- `notes: String?`
- `imageData: Data?`

### SwiftData Container Error
Make sure you're adding `CookingSession.self` to the container:
```swift
try ModelContainer(for: Recipe.self, CookingSession.self)
```

### Keep Awake Not Working
This is normal in the simulator. Test on actual device.

## 🎯 Testing Scenarios

### iPhone Testing
1. Open Cooking tab
2. Tap empty slot → select recipe
3. Swipe left to second slot
4. Tap empty slot → select different recipe
5. Swipe between recipes
6. Toggle keep awake
7. Close app and reopen → should restore recipes

### iPad Testing
1. Open Cooking tab
2. See side-by-side layout immediately
3. Select recipe in left panel
4. Select different recipe in right panel
5. Both should be visible simultaneously
6. Toggle keep awake
7. Rotate device → layout adjusts

## 📝 Customization Quick Wins

### Change Serving Increments
File: `RecipeDetailView.swift` (line ~180)
```swift
servingMultiplier += 0.5  // Change to 0.25, 1.0, etc.
```

### Default Keep Awake On
File: `CookingSession.swift` (line ~20)
```swift
var keepAwakeEnabled: Bool = true  // Already default
```

### Sort Recipes Differently
File: `RecipePickerSheet.swift` (line ~22)
```swift
@Query(sort: \Recipe.title) // Change to .createdAt, etc.
```

## 🚀 Ready to Ship?

- [ ] Tested on iPhone
- [ ] Tested on iPad
- [ ] Tested session persistence
- [ ] Tested with real recipe data
- [ ] Verified keep awake works
- [ ] Checked accessibility (VoiceOver)
- [ ] Tested with Dynamic Type enabled

## 💡 Next Steps

After basic integration works, consider adding:
- Timer integration for recipe steps
- Voice control via Siri shortcuts
- Shopping list generation
- Recipe sharing
- Print formatting

---

**Questions?** Check the full README.md and INTEGRATION_GUIDE.md
