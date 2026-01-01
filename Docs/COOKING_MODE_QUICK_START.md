# Quick Start: Using Cooking Mode

## Access Cooking Mode

### From Recipe Detail View
1. Open any recipe
2. Look for the **chef hat icon** (🧑‍🍳) in the toolbar (top right)
3. Tap to enter cooking mode

## Cooking Mode Features

### 1. Recipe Header
```
┌─────────────────────────────────────┐
│  Spaghetti Carbonara                │  ← Recipe title
│  🏴 Italian  👥 4 servings  ⏱️ 30 min │  ← Quick info
└─────────────────────────────────────┘
```

### 2. Serving Adjustment
```
┌─────────────────────────────────────┐
│  Adjust Servings                    │
│  ⊖         4         ⊕              │  ← Tap to adjust
│          servings                   │
└─────────────────────────────────────┘
```
- Tap **⊖** to decrease (minimum 0.5x)
- Tap **⊕** to increase (unlimited)
- Ingredient quantities scale automatically

### 3. Ingredients Section
```
┌─────────────────────────────────────┐
│  Ingredients                        │
│                                     │
│  • 1 lb spaghetti                   │  ← Auto-scaled
│  • 6 oz guanciale, diced            │
│  • 4 large eggs                     │
│  • 1 cup Pecorino Romano, grated    │
└─────────────────────────────────────┘
```
- All quantities adjust with serving size
- Includes preparation notes
- Grouped by sections (if recipe has them)

### 4. Instructions with Checkboxes
```
┌─────────────────────────────────────┐
│  Instructions                       │
│                                     │
│  ○ Step 1                           │  ← Tap to check
│    Bring water to boil...           │
│                                     │
│  ✓ Step 2                           │  ← Completed
│    Render the guanciale...          │  (strikethrough)
│                                     │
│  ○ Step 3                           │
│    Whisk eggs and cheese...         │
└─────────────────────────────────────┘
```
- Tap circles to mark steps complete
- Completed steps show green checkmark
- Text gets strikethrough when done
- Gray background indicates completion

### 5. Notes Section
```
┌─────────────────────────────────────┐
│  📝 Notes                            │
│                                     │
│  💡 Tip                              │
│  Work off heat to prevent scrambling│
│                                     │
│  🔄 Substitution                     │
│  Use fresh Pecorino Romano          │
└─────────────────────────────────────┘
```
- Shows tips, warnings, substitutions
- Color-coded by type
- Easy to spot important info

## Tips for Using Cooking Mode

### Best Practices
1. **Before Cooking**
   - Review all steps first
   - Adjust servings if needed
   - Gather ingredients

2. **While Cooking**
   - Check off steps as you complete them
   - Keep device in view (use stand if available)
   - Don't worry about missed steps - uncheck and recheck

3. **Exit Anytime**
   - Tap "Done" button (top left)
   - Returns to Recipe Detail View
   - Progress is NOT saved (intentional for reuse)

### Pro Tips
✅ **Scaling Works Smart**
- "1 1/2 cups" → "3 cups" when doubled
- Handles fractions automatically
- Preserves formatting

✅ **Multiple Sections Supported**
- Ingredient groups (e.g., "Sauce", "Pasta")
- Instruction groups (e.g., "Prep", "Cooking")

✅ **Notes Are Helpful**
- Read notes before starting
- They contain important tips
- May have timing or safety info

## Keyboard Shortcuts (iPad)
- **⌘W** - Close cooking mode
- **⌘[** - Decrease servings
- **⌘]** - Increase servings

## Troubleshooting

### "Chef hat icon doesn't appear"
- Make sure you're in Recipe Detail View
- Check toolbar (may be in overflow menu)
- Update app if using old version

### "Ingredient quantities don't change"
- Only numeric quantities scale
- "To taste" or "as needed" stay the same
- This is intentional behavior

### "Can't check off steps"
- Tap the circle icon (not the text)
- Try tapping again if it didn't register
- Should toggle instantly

### "Lost my progress"
- Progress resets when you close cooking mode
- This is intentional for recipe reuse
- Take notes if you need to remember changes

## Example: Making Recipe at Different Sizes

### Original Recipe (Serves 4)
```
Ingredients:
• 1 lb spaghetti
• 4 eggs
• 1 cup cheese
```

### Halved (Serves 2) - Set multiplier to 0.5x
```
Ingredients:
• 0.5 lb spaghetti
• 2 eggs
• 0.5 cup cheese
```

### Doubled (Serves 8) - Set multiplier to 2x
```
Ingredients:
• 2 lb spaghetti
• 8 eggs
• 2 cup cheese
```

## Integration Points

### Cooking Mode is Available From:
- ✅ Recipe Detail View (main integration point)
- 🔜 Recipe List (future enhancement)
- 🔜 Search Results (future enhancement)
- 🔜 Siri Shortcuts (future enhancement)

## Feature Comparison

| Feature | Recipe Detail View | Cooking Mode |
|---------|-------------------|--------------|
| View recipe | ✅ | ✅ |
| Edit recipe | ✅ | ❌ |
| Add tips | ✅ | ❌ |
| Scale servings | ❌ | ✅ |
| Check off steps | ❌ | ✅ |
| Allergen info | ✅ | ❌ |
| FODMAP info | ✅ | ❌ |
| Export to Reminders | ✅ | ❌ |
| Focused view | ❌ | ✅ |

**Use Detail View for:** Browsing, editing, analyzing
**Use Cooking Mode for:** Actually cooking the recipe

## Code Example

Want to add cooking mode to another view?

```swift
import SwiftUI

struct YourView: View {
    let recipe: RecipeModel
    @State private var showingCookingMode = false
    
    var body: some View {
        Button("Cook This Recipe") {
            showingCookingMode = true
        }
        .sheet(isPresented: $showingCookingMode) {
            NavigationStack {
                CookingModeView(recipe: recipe)
            }
        }
    }
}
```

## That's It!

Cooking mode is simple, focused, and effective. Just tap the chef hat and start cooking! 👨‍🍳
