# Nutritional Goals Integration Guide

## Overview

This guide explains how to integrate the new Nutritional Goals system into your Reczipes app. The system allows users to set daily nutritional targets (calories, sodium, fat, sugar, fiber, etc.) and see how recipes fit within those goals.

## Medical Sources

All nutritional guidelines are based on:
- **American Heart Association (AHA)** - Heart health, sodium, saturated fat
- **American Diabetes Association (ADA)** - Diabetes management, carbs, fiber
- **Centers for Disease Control and Prevention (CDC)** - General nutrition
- **Dietary Guidelines for Americans 2020-2025** - Comprehensive nutrition

## Files Created

1. **NutritionalGoals.swift** - Data model for daily goals
2. **NutritionalAnalyzer.swift** - Analyzes recipes against goals
3. **NutritionalGoalsView.swift** - UI for setting goals
4. **NutritionalBadge.swift** - Badge showing recipe compatibility
5. **Updated UserAllergenProfile.swift** - Schema V3.0.0 with goals support

## Integration Steps

### Step 1: Update Schema Migration

Add to your `SchemaMigration.swift` or schema configuration:

```swift
// Schema V3.0.0 - Adds nutritional goals to UserAllergenProfile
// The nutritionalGoalsData property is optional (Data?), so this is a lightweight migration
// Existing profiles will automatically work with nil values

// No migration code needed! SwiftData handles it automatically since:
// - nutritionalGoalsData is optional (Data?)
// - Has default value of nil
// - CloudKit compatible (stored as Data)
```

### Step 2: Add to AllergenProfileView

In your `AllergenProfileView.swift`, add a button to set nutritional goals:

```swift
Section {
    NavigationLink {
        NutritionalGoalsView(profile: $profile)
    } label: {
        HStack {
            Label("Nutritional Goals", systemImage: "heart.text.square.fill")
            
            Spacer()
            
            if profile.hasNutritionalGoals {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("Not set")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
} header: {
    Text("Daily Targets")
} footer: {
    Text("Set daily goals for calories, sodium, fat, sugar, and more based on medical guidelines")
}
```

### Step 3: Add Filtering to ContentView

Update your `ContentView.swift` to include nutritional filtering:

```swift
// Add state for nutritional scores
@State private var cachedNutritionalScores: [UUID: NutritionalScore] = [:]

// Update filter processing
private func processFilter() {
    // ... existing code ...
    
    // Analyze for nutritional goals if set
    if let profile = activeProfile, 
       let goals = profile.nutritionalGoals,
       await currentMode.includesNutritionalFilter {
        nutritionalScores = await NutritionalAnalyzer.shared.analyzeRecipes(recipesToProcess, goals: goals)
    }
    
    // ... rest of existing code ...
}
```

### Step 4: Update RecipeFilterMode

Add nutritional filtering to your filter modes:

```swift
enum RecipeFilterMode: String, CaseIterable {
    case none = "No Filter"
    case allergens = "Allergens"
    case diabetes = "Diabetes"
    case nutrition = "Nutrition" // NEW
    case combined = "All Health" // Updated to include nutrition
    
    var includesNutritionalFilter: Bool {
        self == .nutrition || self == .combined
    }
}
```

### Step 5: Show Badges in Recipe List

In your recipe row view, add the nutritional badge:

```swift
private func recipeRow(recipe: RecipeModel) -> some View {
    HStack(spacing: 12) {
        // ... existing thumbnail code ...
        
        VStack(alignment: .leading, spacing: 4) {
            // ... existing title/notes code ...
        }
        
        Spacer()
        
        // Show nutritional badge if goals are set and filtering is active
        if filterMode == .nutrition || filterMode == .combined,
           let score = cachedNutritionalScores[recipe.id] {
            NutritionalBadge(score: score, compact: true)
        }
    }
}
```

### Step 6: Add to RecipeDetailView

Show detailed nutritional analysis in recipe detail view:

```swift
// In RecipeDetailView
Section("Nutritional Information") {
    if let profile = activeProfile,
       let goals = profile.nutritionalGoals {
        let score = NutritionalAnalyzer.shared.analyzeRecipe(recipe, goals: goals)
        NutritionalBadge(score: score, compact: false)
    } else {
        VStack(alignment: .leading, spacing: 8) {
            Label("No nutritional goals set", systemImage: "heart.text.square")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            NavigationLink("Set up nutritional goals") {
                // Navigate to profile settings
            }
            .font(.caption)
        }
    }
}
```

## Usage Examples

### Setting Up Goals

```swift
// Create preset goals for diabetes management
var goals = NutritionalGoals.preset(for: .diabetesManagement)

// Or create custom goals
var customGoals = NutritionalGoals(
    dailyCalories: 2000,
    dailySodium: 1500,
    dailySugar: 25
)

// Save to profile
profile.nutritionalGoals = goals
```

### Analyzing Recipes

```swift
// Analyze a single recipe
let profile = activeProfile
if let goals = profile.nutritionalGoals {
    let score = NutritionalAnalyzer.shared.analyzeRecipe(recipe, goals: goals)
    
    print("Compatibility: \(score.compatibilityScore)%")
    print("Alerts: \(score.alerts.count)")
    
    // Show in UI
    NutritionalBadge(score: score, compact: false)
}
```

### Filtering Recipes

```swift
// Filter for compatible recipes
let compatibleRecipes = NutritionalAnalyzer.shared.filterCompatibleRecipes(
    recipes,
    goals: goals,
    minimumScore: 60.0 // 60% or better
)

// Sort by compatibility
let sortedRecipes = NutritionalAnalyzer.shared.sortRecipesByCompatibility(
    recipes,
    goals: goals
)
```

## Preset Goal Templates

The system includes 5 preset templates:

1. **Weight Loss** (1,500 cal)
   - Moderate calorie deficit
   - Balanced macros
   - Low sodium

2. **Diabetes Management** (1,800 cal)
   - Carb-controlled (180g)
   - High fiber (30g)
   - Low added sugar

3. **Heart Health** (2,000 cal)
   - Very low sodium (1,500mg)
   - Low saturated fat
   - High potassium (DASH diet)

4. **General Health** (2,000 cal)
   - Balanced nutrition
   - Moderate all nutrients
   - CDC guidelines

5. **Athletic Performance** (2,800 cal)
   - Higher calories
   - High protein (140g)
   - More carbs for energy

## Customization

### Custom Nutrition Extraction

Currently uses keyword matching. To improve:

```swift
// TODO: Integrate with Claude API
func extractNutritionFromClaude(recipe: RecipeModel) async -> RecipeNutrition {
    let prompt = """
    Analyze this recipe and provide detailed nutrition facts per serving:
    
    Title: \(recipe.title)
    Ingredients: \(recipe.ingredientSections)
    Servings: \(recipe.recipeYield ?? "Unknown")
    
    Please provide:
    - Calories
    - Protein (g)
    - Carbohydrates (g)
    - Total Fat (g)
    - Saturated Fat (g)
    - Sodium (mg)
    - Sugar (g)
    - Fiber (g)
    """
    
    // Send to Claude API
    // Parse structured response
    // Return RecipeNutrition object
}
```

### Adding Custom Alerts

Extend `NutritionalAnalyzer` to add custom alert logic:

```swift
extension NutritionalAnalyzer {
    func checkProteinIntake(_ recipe: RecipeModel, goals: NutritionalGoals) -> [NutritionAlert] {
        var alerts: [NutritionAlert] = []
        
        if let protein = nutrition.protein, let dailyProtein = goals.dailyProtein {
            let percentage = (protein / dailyProtein) * 100
            
            if percentage > 30 {
                alerts.append(NutritionAlert(
                    nutrient: "Protein",
                    severity: .positive,
                    message: "✅ High protein: \(Int(protein))g",
                    recommendation: "Great for muscle building and satiety"
                ))
            }
        }
        
        return alerts
    }
}
```

## Testing

### Unit Tests

```swift
import Testing

@Suite("Nutritional Goals Tests")
struct NutritionalGoalsTests {
    
    @Test("Preset goals have valid values")
    func testPresetGoals() {
        for goalType in GoalType.allCases {
            let goals = NutritionalGoals.preset(for: goalType)
            
            // Check critical values are set
            #expect(goals.dailyCalories != nil)
            #expect(goals.dailySodium != nil)
            #expect(goals.dailyTotalFat != nil)
        }
    }
    
    @Test("Recipe analysis produces valid scores")
    func testRecipeAnalysis() {
        let recipe = // ... create test recipe
        let goals = NutritionalGoals.preset(for: .generalHealth)
        
        let score = NutritionalAnalyzer.shared.analyzeRecipe(recipe, goals: goals)
        
        #expect(score.compatibilityScore >= 0)
        #expect(score.compatibilityScore <= 100)
    }
}
```

### Preview Testing

Use SwiftUI previews to test UI:

```swift
#Preview("Goals View - Diabetes") {
    @Previewable @State var profile = UserAllergenProfile(
        name: "Test User",
        isActive: true
    )
    profile.nutritionalGoals = .preset(for: .diabetesManagement)
    
    NutritionalGoalsView(profile: $profile)
}
```

## CloudKit Sync

The nutritional goals are stored as `Data?` in `UserAllergenProfile`, making them:
- ✅ CloudKit compatible (Data type syncs automatically)
- ✅ Optional (no migration needed)
- ✅ Backward compatible (old installs work fine)

## Medical Disclaimer

**IMPORTANT**: Always include this disclaimer in your UI:

```swift
Section {
    VStack(alignment: .leading, spacing: 8) {
        Label("Medical Disclaimer", systemImage: "info.circle.fill")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.orange)
        
        Text("These guidelines are based on recommendations from the American Heart Association, American Diabetes Association, and CDC. Always consult with your healthcare provider for personalized nutritional advice.")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}
```

## Future Enhancements

1. **Claude API Integration** - Extract accurate nutrition from recipes
2. **USDA Database** - Match ingredients to nutrition database
3. **Manual Entry** - Let users input nutrition facts
4. **Meal Planning** - Track daily totals across meals
5. **Progress Tracking** - Show adherence to goals over time
6. **Recipe Suggestions** - Recommend recipes to meet remaining goals
7. **Barcode Scanning** - Auto-populate from packaged ingredients

## Support

For questions or issues:
1. Check the medical sources for guideline details
2. Review the TODO comments in the code
3. Test with different goal types and recipes
4. Verify CloudKit sync is working

## Version History

- **V3.0.0** (Current) - Added nutritional goals system
- **V2.0.0** - Added diabetes status
- **V1.0.0** - Initial allergen profiles
