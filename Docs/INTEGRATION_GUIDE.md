# Cooking Mode Integration Guide

## Overview
This cooking mode implementation provides a dual-recipe display optimized for different device sizes:
- **iPad & Mac**: Side-by-side recipe panels
- **iPhone**: Swipeable recipe views
- **Keep Awake**: Optional screen sleep prevention during cooking

## Files Included
1. `KeepAwakeManager.swift` - Screen wake management
2. `CookingSession.swift` - SwiftData persistence model
3. `CookingViewModel.swift` - State management with @Observable
4. `CookingView.swift` - Main adaptive view
5. `RecipePanel.swift` - Individual recipe display component
6. `RecipePickerSheet.swift` - Recipe selection interface
7. `RecipeDetailView.swift` - Recipe content display with scaling & step tracking

## Integration Steps

### Step 1: Add Files to Xcode Project
1. Create a new group called "CookingMode" in your project
2. Drag all `.swift` files into this group
3. Ensure they're added to your app target

### Step 2: Update SwiftData ModelContainer
Add `CookingSession` to your model container configuration:

```swift
// In your App file
import SwiftUI
import SwiftData

@main
struct Reczipes2App: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Recipe.self, CookingSession.self  // Add CookingSession here
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

### Step 3: Add Cooking Tab to Main TabView
Update your main `ContentView` to include the cooking tab:

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            // Your existing tabs
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
            
            // NEW: Cooking tab
            CookingView()
                .tabItem {
                    Label("Cooking", systemImage: "flame.fill")
                }
            
            // Your other tabs...
        }
    }
}
```

### Step 4: Verify Recipe Model Compatibility
Ensure your `Recipe` model has these properties (adjust if needed):

```swift
@Model
final class Recipe {
    var id: UUID
    var title: String
    var cuisine: String?
    var servings: Int?
    var prepTime: String?
    var ingredients: [String]
    var instructions: [String]
    var notes: String?
    var imageData: Data?
    
    // ... other properties
}
```

### Step 5: Test on Different Devices
1. **iPhone**: Test swipe gestures between recipes
2. **iPad**: Verify side-by-side display
3. **Mac Catalyst** (if enabled): Test window resizing

## Key Features

### 1. Keep Awake Toggle
- Prevents screen from sleeping during cooking
- Accessible via toolbar button (eye icon)
- State persists across app launches

### 2. Adaptive Layout
- Automatically detects device size class
- iPad/Mac: Split-screen with both recipes visible
- iPhone: Swipeable TabView with page indicator

### 3. Recipe Management
- Select recipes via search interface
- Change recipes without losing the other slot
- Clear individual recipe slots
- Filter by cuisine

### 4. Cooking Enhancements
- **Serving Adjustment**: Scale ingredients up/down
- **Step Tracking**: Check off completed steps
- **Ingredient Scaling**: Automatic quantity adjustments

### 5. Session Persistence
- Saves recipe selections automatically
- Restores last cooking session on app launch
- Preserves keep-awake preference

## Customization Options

### Adjust Serving Multiplier Increments
In `RecipeDetailView.swift`, modify the increment value:
```swift
// Current: 0.5x increments (0.5, 1.0, 1.5, 2.0...)
servingMultiplier += 0.5

// Change to 1.0x increments (1, 2, 3...)
servingMultiplier += 1.0
```

### Change Recipe Selection Sorting
In `RecipePickerSheet.swift`, modify the Query:
```swift
// Current: Alphabetical by title
@Query(sort: \Recipe.title) private var allRecipes: [Recipe]

// Change to most recent first
@Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]
```

### Modify Empty Slot Appearance
In `RecipePanel.swift`, customize `EmptyRecipeSlot`:
```swift
// Change icon size, colors, or text
Image(systemName: "plus.circle.fill")
    .font(.system(size: 64))  // Adjust size
    .foregroundStyle(.blue)    // Change color
```

## Troubleshooting

### Issue: "Cannot find 'Recipe' in scope"
**Solution**: Ensure your Recipe model is accessible. If it's in a different module:
```swift
import YourRecipeModule
```

### Issue: Recipes don't persist between launches
**Solution**: Verify `CookingSession` is added to ModelContainer:
```swift
try ModelContainer(for: Recipe.self, CookingSession.self)
```

### Issue: Keep Awake doesn't work
**Solution**: Check Info.plist has no conflicting idle timer settings. The implementation uses:
```swift
UIApplication.shared.isIdleTimerDisabled = true
```

### Issue: Layout doesn't adapt on iPad
**Solution**: Ensure you're testing on actual hardware or simulator. Size classes in previews may not match real devices.

## Future Enhancements (Easy to Add)

### Timer Integration
Add timer buttons to each instruction step:
```swift
// In RecipeDetailView.swift, add to instructionRow
Button {
    startTimer(for: instruction)
} label: {
    Image(systemName: "timer")
}
```

### Shopping List Export
Generate shopping list from selected recipes:
```swift
func generateShoppingList() -> [String] {
    let ingredients = selectedRecipes.compactMap { $0?.ingredients }.flatMap { $0 }
    return Array(Set(ingredients)).sorted()
}
```

### Recipe Scaling Presets
Add quick preset buttons (e.g., 2x, 3x, 4x):
```swift
HStack {
    ForEach([1.0, 2.0, 3.0, 4.0], id: \.self) { multiplier in
        Button("\(Int(multiplier))x") {
            servingMultiplier = multiplier
        }
    }
}
```

### Voice Control
Add Siri shortcuts for hands-free operation:
```swift
import AppIntents

struct NextStepIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Cooking Step"
    // Implementation
}
```

## Performance Notes
- Recipe images are loaded on-demand
- Session auto-saves on changes (debounced)
- SwiftData handles CloudKit sync automatically
- Keep awake only active when CookingView is visible

## Accessibility
- All buttons have proper labels
- VoiceOver support via native SwiftUI
- Dynamic Type supported throughout
- High contrast mode compatible

## Questions or Issues?
The code uses modern SwiftUI patterns:
- `@Observable` instead of `ObservableObject`
- `@Query` for SwiftData fetching
- Environment values for dependency injection
- Task-based lifecycle management

Let me know if you need help with any integration step!
