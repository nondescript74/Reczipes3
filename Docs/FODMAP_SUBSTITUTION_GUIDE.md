# FODMAP Substitution Feature - Integration Guide

## Overview

This feature provides comprehensive FODMAP ingredient substitution suggestions for users with FODMAP sensitivities. Based on Monash University FODMAP research, it identifies high FODMAP ingredients in recipes and suggests appropriate low FODMAP alternatives.

## Key Components

### 1. **FODMAPSubstitution.swift**
Core data models and substitution database.

**Main Classes:**
- `FODMAPSubstitution`: Model for a substitution with original ingredient and alternatives
- `SubstituteOption`: Individual substitute with confidence level and usage notes
- `RecipeFODMAPSubstitutions`: Complete analysis of a recipe's FODMAP content
- `FODMAPSubstitutionDatabase`: Database of 40+ common high FODMAP ingredients with substitutes

**Key Features:**
- Comprehensive database covering all 4 FODMAP categories (Oligosaccharides, Disaccharides, Monosaccharides, Polyols)
- Confidence ratings for each substitute (high/medium/low)
- Portion guidance for ingredients that are safe in small amounts
- Detailed explanations for why substitutions are needed

### 2. **FODMAPSubstitutionView.swift**
SwiftUI views for displaying substitutions.

**Main Views:**
- `FODMAPSubstitutionSection`: Main section showing all substitutions for a recipe
- `IngredientSubstitutionCard`: Expandable card for each high FODMAP ingredient
- `InlineSubstituteSuggestion`: Compact inline view next to ingredients
- `IngredientRowWithFODMAP`: Enhanced ingredient display with FODMAP indicators
- `SubstitutionDetailSheet`: Full-screen detail view for a substitution

**UI Features:**
- Expandable/collapsible substitution cards
- Color-coded confidence indicators (green=high, orange=medium, yellow=low)
- FODMAP category badges with emoji icons
- Inline indicators next to high FODMAP ingredients
- Detailed explanation sheets

### 3. **UserFODMAPSettings.swift**
User preferences for FODMAP functionality.

**Settings:**
- `isFODMAPEnabled`: Master toggle for FODMAP features
- `showInlineIndicators`: Show warning icons next to high FODMAP ingredients
- `autoExpandSubstitutions`: Automatically expand all substitution details

**Views:**
- `FODMAPSettingsView`: Settings screen for FODMAP preferences
- `FODMAPCategoryInfo`: Educational info about each FODMAP category

### 4. **RecipeDetailView.swift** (Updated)
Integrated FODMAP substitutions into recipe detail view.

**Changes:**
- Added `fodmapSettings` to track user preferences
- Added `fodmapAnalysis` computed property
- New FODMAP section appears before ingredients (when enabled and applicable)
- Ingredient rows now show FODMAP indicators inline
- Respects user settings to show/hide features

## Usage

### For Users

1. **Enable FODMAP Mode**
   - Go to Settings → FODMAP Settings
   - Toggle "Enable FODMAP Features" ON
   - Optionally enable inline indicators and auto-expand

2. **View Recipe with FODMAP Substitutions**
   - Open any recipe in RecipeDetailView
   - If recipe contains high FODMAP ingredients, a new section appears: "FODMAP Friendly Options"
   - Each high FODMAP ingredient is listed with:
     - Original ingredient with quantity
     - FODMAP category badges
     - Explanation of why it's problematic
     - Portion guidance (if applicable)
     - 1-4 substitute options with confidence ratings
   
3. **Inline Indicators** (if enabled)
   - High FODMAP ingredients show ⚠️ warning icon
   - Click "FODMAP substitute available" button for quick details
   - Opens detail sheet with full substitution information

### For Developers

#### Add New Substitutions

Edit `FODMAPSubstitution.swift`, add to `allSubstitutions` array:

```swift
FODMAPSubstitution(
    originalIngredient: "ingredient name",
    fodmapCategories: [.oligosaccharides], // or other categories
    substitutes: [
        SubstituteOption(
            name: "Substitute Name",
            quantity: "Amount to use",
            notes: "Usage notes and tips",
            confidence: .high // or .medium, .low
        ),
        // Add more options...
    ],
    explanation: "Why this ingredient is high FODMAP",
    portionNote: "Safe portion size if any (optional)"
)
```

#### Integrate in Other Views

```swift
// Analyze a recipe
let analysis = FODMAPSubstitutionDatabase.shared.analyzeRecipe(recipe)

// Check if recipe has high FODMAP ingredients
if analysis.hasSubstitutions {
    // Show substitution section
    FODMAPSubstitutionSection(analysis: analysis)
}

// Get substitution for specific ingredient
if let substitution = FODMAPSubstitutionDatabase.shared.getSubstitutions(for: ingredientName) {
    // Show inline indicator or detail
    InlineSubstituteSuggestion(substitution: substitution)
}
```

#### Access User Settings

```swift
@StateObject private var fodmapSettings = UserFODMAPSettings.shared

// Check if enabled
if fodmapSettings.isFODMAPEnabled {
    // Show FODMAP features
}

// Check inline indicators setting
if fodmapSettings.showInlineIndicators {
    // Show ⚠️ icons
}
```

## FODMAP Database Coverage

The system includes substitutions for:

### Oligosaccharides (Fructans & GOS)
- **Fructans**: wheat, rye, barley, onions, garlic, shallots, leeks, artichoke, asparagus, beetroot, Brussels sprouts, cabbage
- **GOS**: chickpeas, kidney beans, black beans, lentils, soybeans, cashews, pistachios

### Disaccharides (Lactose)
- milk, yogurt, ice cream, soft cheese, cream, custard

### Monosaccharides (Excess Fructose)
- honey, agave, apples, pears, mangoes, watermelon, figs

### Polyols (Sugar Alcohols)
- **Natural**: apples, apricots, avocado, blackberries, cherries, nectarines, peaches, pears, plums, prunes, mushrooms, cauliflower, snow peas, sweet corn
- **Artificial**: sorbitol, mannitol, xylitol, maltitol, isomalt

## Design Principles

1. **Non-Intrusive**: Features are hidden by default unless user enables FODMAP mode
2. **Educational**: Each substitution includes explanation of the FODMAP issue
3. **Practical**: Provides specific quantities and usage notes
4. **Flexible**: Multiple substitute options with confidence ratings
5. **Evidence-Based**: All guidance based on Monash University FODMAP research
6. **Portion-Aware**: Acknowledges that some ingredients are safe in small amounts

## User Experience Flow

```
1. User opens recipe
   ↓
2. System checks if FODMAP mode enabled
   ↓ (if yes)
3. Analyze recipe for high FODMAP ingredients
   ↓ (if found)
4. Show "FODMAP Friendly Options" section
   ↓
5. User can:
   - Expand/collapse substitution cards
   - View detailed explanations
   - See multiple substitute options
   - Check portion guidance
   - Tap inline indicators for quick info
```

## Future Enhancements

Potential additions:
- [ ] User can favorite specific substitutes
- [ ] Shopping list integration (auto-swap high FODMAP for chosen substitute)
- [ ] Recipe modification (create low FODMAP variant)
- [ ] Severity tracking (log which FODMAPs trigger symptoms)
- [ ] Custom substitutes (user adds their own)
- [ ] AI-powered substitution refinement using Claude
- [ ] Meal planning with FODMAP consideration
- [ ] Export modified recipe with substitutions applied

## Testing Recommendations

1. **Test with various recipes**:
   - Recipe with no high FODMAP ingredients
   - Recipe with 1-2 high FODMAP ingredients
   - Recipe with many high FODMAP ingredients
   - Recipe with ingredients from all 4 categories

2. **Test settings combinations**:
   - FODMAP disabled → No features show
   - FODMAP enabled, inline off → Section only
   - FODMAP enabled, inline on → Icons + section
   - Auto-expand on → All cards start open

3. **Test UI interactions**:
   - Expand/collapse cards
   - Inline indicator taps
   - Detail sheet presentation
   - Show/hide section toggle

## Performance Notes

- Substitution lookup is O(n) where n = database size (~40 items)
- Recipe analysis is O(m) where m = ingredient count
- All operations are synchronous and fast (<1ms typical)
- No network calls or heavy computation
- Database is loaded once at class initialization

## Accessibility

Views include:
- Semantic labels for screen readers
- High contrast color indicators
- Text alternatives for emoji icons
- Keyboard navigation support
- Dynamic Type support

## Related Files

- `FODMAPAnalyzer.swift` - Original FODMAP detection (basis for this feature)
- `AllergenAnalyzer.swift` - Similar pattern for allergen detection
- `UserAllergenProfile.swift` - Similar user profile pattern
- `RecipeModel.swift` - Recipe data structure

## Questions & Support

For questions about:
- **Medical FODMAP guidance**: Consult Monash University FODMAP resources or a dietitian
- **Technical implementation**: See code comments and SwiftUI documentation
- **Adding ingredients**: Follow patterns in `allSubstitutions` array
- **UI customization**: Modify views in `FODMAPSubstitutionView.swift`
