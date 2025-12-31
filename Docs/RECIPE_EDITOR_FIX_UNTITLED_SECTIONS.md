# Fix: "Untitled Section" Display Issue

## Problem

When navigating to ingredient or instruction sections that don't have explicit titles (which are optional), the list was showing "Untitled Section" as a placeholder. This was confusing because:

1. Section titles are optional by design
2. Many recipes don't need section titles (especially single-section recipes)
3. "Untitled Section" doesn't provide useful context

## Solution

Implemented **contextual section naming** that provides meaningful labels based on the recipe structure:

### Smart Section Titles

#### Single Section
When a recipe has only one ingredient or instruction section (the most common case):
- **Display**: "Ingredients" or "Instructions"
- **Rationale**: No need to show a section number when there's only one section

#### Multiple Sections
When a recipe has multiple sections without titles:
- **Display**: "Section 1", "Section 2", "Section 3", etc.
- **Rationale**: Numbered sections provide clear differentiation and ordering

#### Named Sections
When a user has provided a custom title:
- **Display**: The custom title (e.g., "Dry Ingredients", "For the Sauce")
- **Rationale**: User's explicit naming takes precedence

## Implementation

### Before
```swift
Text(section.title.isEmpty ? "Untitled Section" : section.title)
```

### After
```swift
// Use enumerated array to track index
ForEach(Array($sections.enumerated()), id: \.element.id) { index, $section in
    Text(sectionTitle(for: section, at: index))
}

// Helper function
private func sectionTitle(for section: EditableIngredientSection, at index: Int) -> String {
    if !section.title.isEmpty {
        return section.title
    }
    
    if sections.count == 1 {
        return "Ingredients"  // or "Instructions"
    }
    
    return "Section \(index + 1)"
}
```

## Examples

### Example 1: Simple Recipe (One Section)
```
Chocolate Chip Cookies
├── Ingredients (not "Untitled Section")
│   ├── 2 cups flour
│   ├── 1 cup sugar
│   └── ...
└── Instructions (not "Untitled Section")
    ├── Step 1: Mix dry ingredients
    └── ...
```

### Example 2: Complex Recipe (Multiple Sections)
```
Layered Cake
├── Section 1 (no title provided)
│   ├── 3 cups flour
│   └── ...
├── Section 2 (no title provided)
│   ├── 4 eggs
│   └── ...
└── Frosting (user provided title)
    ├── 2 cups butter
    └── ...
```

### Example 3: All Sections Named
```
Beef Stew
├── For the Meat (user provided title)
│   ├── 2 lbs beef
│   └── ...
├── Vegetables (user provided title)
│   ├── 3 carrots
│   └── ...
└── Sauce (user provided title)
    ├── 2 cups broth
    └── ...
```

## Benefits

1. ✅ **Better UX**: More meaningful labels for users
2. ✅ **Context-Aware**: Adapts to recipe structure
3. ✅ **Backward Compatible**: Works with all existing recipes
4. ✅ **Consistent**: Applied to both ingredients and instructions
5. ✅ **Intuitive**: Users don't see confusing "Untitled" labels

## Files Modified

- `RecipeEditorView.swift`
  - Updated `IngredientsEditorView` with smart section naming
  - Updated `InstructionsEditorView` with smart section naming
  - Added helper functions to both views

## Testing Notes

Test the following scenarios:
- ✅ Recipe with single ingredient section (no title)
- ✅ Recipe with single instruction section (no title)
- ✅ Recipe with multiple sections, none titled
- ✅ Recipe with multiple sections, some titled, some not
- ✅ Recipe with all sections titled
- ✅ Editing section titles and seeing labels update
- ✅ Reordering sections and seeing numbers update

## User Impact

Users will now see:
- More natural labels for single-section recipes
- Clear numbering for multi-section recipes
- Custom titles when they've provided them
- No more confusing "Untitled Section" labels
