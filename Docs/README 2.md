# Cooking Mode for Reczipes2

A dual-recipe cooking interface optimized for iOS and macOS, enabling users to view and work with two recipes simultaneously during cooking.

## Features

### 🍳 Dual-Recipe Display
- **iPad & Mac**: Side-by-side split view with both recipes visible
- **iPhone**: Swipeable interface with page indicators
- Persistent recipe selection across app launches

### 📱 Device-Adaptive Layout
- Automatic detection of device capabilities
- Optimized for different screen sizes and orientations
- Seamless experience across iPhone, iPad, and Mac

### 👁️ Keep Awake Mode
- Optional screen sleep prevention during cooking
- Toggle via toolbar button
- Preference persists across sessions

### 🔢 Smart Ingredient Scaling
- Adjust serving sizes with +/- controls
- Automatic ingredient quantity calculations
- Supports common measurements (cups, tbsp, tsp, oz, lb, g)

### ✅ Step Tracking
- Check off completed cooking steps
- Visual feedback with checkmarks
- Helps maintain progress through recipe

### 🔍 Advanced Recipe Selection
- Searchable recipe picker
- Filter by cuisine type
- Thumbnail preview support

## Architecture

### Modern SwiftUI Patterns
This implementation uses the latest iOS development patterns:

```
@Observable          → State management (not ObservableObject)
@Query              → SwiftData queries
SwiftData           → Data persistence
Environment values  → Dependency injection
Task lifecycle      → Async initialization
```

### Component Structure

```
CookingMode/
├── Models/
│   ├── CookingSession.swift       # SwiftData persistence
│   └── KeepAwakeManager.swift     # Screen wake management
├── ViewModels/
│   └── CookingViewModel.swift     # @Observable state container
└── Views/
    ├── CookingView.swift          # Main adaptive container
    ├── RecipePanel.swift          # Individual recipe display
    ├── RecipePickerSheet.swift    # Recipe selection UI
    └── RecipeDetailView.swift     # Recipe content renderer
```

### Data Flow

```
User Interaction
    ↓
CookingView (UI Layer)
    ↓
CookingViewModel (@Observable)
    ↓
SwiftData ModelContext
    ↓
CookingSession (Persistence)
    ↓
CloudKit Sync (Automatic)
```

## Requirements

- **iOS**: 17.0+
- **macOS**: 14.0+ (Catalyst or native)
- **Xcode**: 15.0+
- **Swift**: 5.9+

## Quick Start

### 1. Add Files to Project
Drag the `CookingMode` folder into your Xcode project.

### 2. Update Model Container
```swift
@main
struct YourApp: App {
    let container = try! ModelContainer(
        for: Recipe.self, CookingSession.self
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
```

### 3. Add to Tab View
```swift
TabView {
    CookingView()
        .tabItem {
            Label("Cooking", systemImage: "flame.fill")
        }
}
```

## Usage Examples

### Basic Usage
```swift
// User opens Cooking tab
// → Previous session restores automatically
// → Keep awake preference loads from last session

// User selects first recipe
// → Tap empty slot
// → Search/browse recipes
// → Recipe displays with full content

// User selects second recipe
// → Repeat for second slot
// → Both recipes now visible (iPad/Mac) or swipeable (iPhone)
```

### Programmatic Recipe Selection
```swift
// If you want to pre-populate cooking mode from elsewhere in your app:

@Environment(\.modelContext) var modelContext

func startCooking(with recipes: [Recipe]) {
    let session = CookingSession(
        primaryRecipeID: recipes[0].id,
        secondaryRecipeID: recipes.count > 1 ? recipes[1].id : nil
    )
    modelContext.insert(session)
    try? modelContext.save()
}
```

### Custom Keep Awake Logic
```swift
// Access keep awake manager directly if needed:
let keepAwake = KeepAwakeManager()

// Enable programmatically
keepAwake.enable()

// Check state
if keepAwake.isEnabled {
    print("Screen will stay awake")
}

// Disable
keepAwake.disable()
```

## Customization

### Adjust Serving Size Increments
```swift
// RecipeDetailView.swift - line ~180
servingMultiplier += 0.5  // Change to 0.25, 1.0, etc.
```

### Change Default Keep Awake State
```swift
// CookingSession.swift - init
var keepAwakeEnabled: Bool = true  // Change to false
```

### Modify Recipe Picker Sorting
```swift
// RecipePickerSheet.swift
@Query(sort: \Recipe.title) // Change sort descriptor
```

### Customize Empty State
```swift
// RecipePanel.swift - EmptyRecipeSlot
Image(systemName: "plus.circle.fill")
    .font(.system(size: 64))        // Icon size
    .foregroundStyle(.blue)         // Icon color
Text("Select a Recipe")
    .font(.title2.weight(.medium)) // Text style
```

## Advanced Features

### Ingredient Scaling Algorithm
The system automatically scales common measurements:
- Volume: cups, tbsp, tsp
- Weight: oz, lb, grams
- Maintains fractional precision

```swift
// Example: "2 cups flour" → "3 cups flour" (1.5x multiplier)
// Example: "1.5 tbsp salt" → "2.25 tbsp salt" (1.5x multiplier)
```

### Step Completion Tracking
- Tap circle icon to mark steps complete
- Completed steps show checkmark and strikethrough
- Visual feedback with background color change
- State resets when recipe changes

### Session Persistence
- Automatic save on every change
- Debounced to prevent excessive writes
- CloudKit sync enabled by default (via SwiftData)

## Performance Considerations

### Memory Management
- Recipe images loaded on-demand
- Only visible panels render full content
- SwiftData optimizes query performance

### Battery Impact
- Keep awake increases battery usage
- Disabled automatically when leaving cooking view
- User can manually toggle on/off

### Network Efficiency
- CloudKit sync batches updates
- Only changed fields synchronized
- Conflict resolution handled automatically

## Accessibility

### VoiceOver Support
All interactive elements have proper labels:
- "Select recipe" buttons
- "Change recipe" controls
- "Keep awake toggle"
- Step completion checkboxes

### Dynamic Type
- Respects user text size preferences
- Layout adapts to larger text
- Maintains readability at all sizes

### Color Contrast
- Meets WCAG AA standards
- High contrast mode compatible
- Color is not the only indicator

## Testing

### Manual Testing Checklist
- [ ] Recipe selection on iPhone
- [ ] Recipe selection on iPad
- [ ] Side-by-side display on iPad
- [ ] Swipe gestures on iPhone
- [ ] Keep awake toggle functionality
- [ ] Serving size adjustment
- [ ] Step completion tracking
- [ ] Session persistence
- [ ] Search functionality
- [ ] Cuisine filtering

### Unit Test Suggestions
```swift
func testServingScaling() {
    let viewModel = CookingViewModel(modelContext: context)
    // Test scaling logic
}

func testSessionPersistence() {
    // Create session
    // Kill app
    // Verify restoration
}

func testKeepAwake() {
    let manager = KeepAwakeManager()
    manager.enable()
    XCTAssertTrue(UIApplication.shared.isIdleTimerDisabled)
}
```

## Troubleshooting

### Recipes Not Appearing
- Verify Recipe model has required properties
- Check SwiftData container configuration
- Ensure recipes exist in database

### Keep Awake Not Working
- Check for conflicting idle timer settings
- Verify on actual device (not simulator)
- Test background app behavior

### Layout Issues
- Size classes may differ in previews
- Test on actual devices
- Check horizontal/vertical size class logic

### CloudKit Sync Issues
- Verify CloudKit entitlements
- Check network connectivity
- Review container permissions

## Contributing

When extending this module:
1. Maintain `@Observable` pattern (not `ObservableObject`)
2. Use SwiftData `@Query` for data fetching
3. Follow adaptive layout principles
4. Add accessibility labels
5. Support Dynamic Type
6. Test on multiple devices

## License

MIT License - feel free to use in your projects

## Support

For issues or questions:
1. Check INTEGRATION_GUIDE.md
2. Review code comments
3. Test on actual devices
4. Verify SwiftData configuration

---

**Built with modern SwiftUI for iOS 17+ and macOS 14+**
