# FODMAP Analysis Implementation Guide

## Overview

The FODMAP analysis system in Reczipes provides comprehensive recipe analysis for users following a Low FODMAP diet, based on research from Monash University.

## What are FODMAPs?

**FODMAP** stands for:
- **F**ermentable
- **O**ligosaccharides (Fructans & GOS)
- **D**isaccharides (Lactose)
- **M**onosaccharides (Excess Fructose)
- **A**nd
- **P**olyols (Sugar Alcohols)

These are short-chain carbohydrates that can trigger digestive symptoms in sensitive individuals, particularly those with IBS (Irritable Bowel Syndrome).

## System Architecture

### 1. Core Components

#### `FODMAPAnalyzer.swift`
- Main analyzer class with Monash University-based FODMAP data
- Contains comprehensive high FODMAP food database
- Performs local keyword-based FODMAP detection
- Generates detailed Claude API prompts for enhanced analysis

#### `AllergenProfile.swift`
- Extended `FoodIntolerance` enum with comprehensive FODMAP keywords
- Includes 150+ FODMAP ingredient keywords organized by category
- Integrated with existing sensitivity system

#### `AllergenAnalyzer.swift`
- Updated to include FODMAP-specific analysis in Claude prompts
- Automatically detects when user has FODMAP sensitivity
- Provides Monash University-referenced analysis

#### `FODMAPAnalysisView.swift`
- Comprehensive UI for displaying FODMAP analysis results
- Shows category-by-category breakdown
- Displays low FODMAP alternatives
- Provides modification suggestions

### 2. FODMAP Categories

The system analyzes recipes across all four FODMAP categories:

#### Oligosaccharides (Fructans & GOS)
- **High FODMAP:** Wheat, rye, barley, onions, garlic, beans, lentils, chickpeas
- **Low FODMAP:** Rice, quinoa, oats, green onion tops (only), garlic-infused oil (strained)

#### Disaccharides (Lactose)
- **High FODMAP:** Milk, cream, yogurt, soft cheeses, ice cream
- **Low FODMAP:** Hard cheeses (cheddar, parmesan), lactose-free milk, butter

#### Monosaccharides (Excess Fructose)
- **High FODMAP:** Honey, agave, apples, pears, mangoes, high-fructose corn syrup
- **Low FODMAP:** Bananas, blueberries, strawberries, maple syrup, glucose

#### Polyols (Sugar Alcohols)
- **High FODMAP:** Sorbitol, mannitol, xylitol, apples, stone fruits, mushrooms, cauliflower
- **Low FODMAP:** Most vegetables without polyols, proper portion sizes

## Usage

### For Users

#### 1. Adding FODMAP Sensitivity

```swift
// In your allergen profile settings
let sensitivity = UserSensitivity(
    intolerance: .fodmap,
    severity: .moderate,
    notes: "Following Low FODMAP diet for IBS"
)
profile.addSensitivity(sensitivity)
```

#### 2. Analyzing Recipes

The system provides two levels of analysis:

**Basic Analysis (Local, Fast)**
```swift
let analyzer = FODMAPAnalyzer.shared
let result = analyzer.analyzeRecipe(recipe)

// Result includes:
// - Overall FODMAP score
// - Category breakdown
// - Detected high FODMAP foods
// - Low FODMAP alternatives
// - Recommendation (safe/caution/modify/avoid)
```

**Enhanced Analysis (with Claude AI)**
```swift
Task {
    let enhancedScore = try await AllergenAnalyzer.shared.analyzeFODMAP(
        recipe,
        apiKey: apiKey
    )
    
    // Enhanced score includes:
    // - All basic analysis data
    // - AI-detected hidden FODMAPs
    // - Portion-specific guidance
    // - Monash University references
    // - Detailed modification suggestions
}
```

#### 3. Displaying Results

```swift
// Show full FODMAP analysis
.sheet(item: $fodmapScore) { score in
    FODMAPAnalysisDetailView(score: score)
}

// Show quick badge on recipe list
FODMAPBadgeView(recommendation: result.recommendation)
```

### For Developers

#### Adding New FODMAP Foods

Add entries to `FODMAPFoodData.highFODMAPFoods`:

```swift
FODMAPFoodData(
    name: "food name",
    categories: [.oligosaccharides, .polyols],  // Can have multiple
    level: .high,
    servingSize: ">1/2 cup",  // or "any amount" or nil
    notes: "Additional guidance from Monash research"
)
```

#### Updating Keywords

Modify `FoodIntolerance.fodmap` case in `AllergenProfile.swift`:

```swift
case .fodmap:
    return [
        // Add new keywords here
        "new ingredient", "another ingredient"
    ]
```

#### Custom FODMAP Analysis

```swift
class MyFODMAPAnalyzer {
    func customAnalysis(recipe: RecipeModel) -> MyResult {
        // Use FODMAPFoodData.getFODMAPData(for:)
        // Combine with your own logic
    }
}
```

## Claude API Integration

### Prompt Structure

The system generates comprehensive prompts that include:

1. **Context**: Recipe title and ingredients
2. **Category Definitions**: All four FODMAP types explained
3. **Detection Guidelines**: 
   - Portion size considerations
   - Hidden FODMAPs
   - Green parts vs white parts (onions/leeks)
   - Infused oils vs solid ingredients
4. **Monash References**: Specific guidance from research
5. **Output Format**: Structured JSON response

### Response Format

```json
{
    "fodmapAnalysis": {
        "overallLevel": "moderate",
        "categoryBreakdown": {
            "oligosaccharides": {
                "level": "high",
                "ingredients": ["wheat pasta", "garlic"]
            },
            "disaccharides": {
                "level": "low",
                "ingredients": []
            },
            "monosaccharides": {
                "level": "low",
                "ingredients": []
            },
            "polyols": {
                "level": "moderate",
                "ingredients": ["mushrooms"]
            }
        },
        "detectedFODMAPs": [
            {
                "ingredient": "garlic",
                "categories": ["oligosaccharides"],
                "portionMatters": false,
                "lowFODMAPAlternative": "Use garlic-infused oil, strain out solids"
            }
        ],
        "modificationTips": [
            "Replace wheat pasta with rice pasta or gluten-free pasta",
            "Use only green tops of spring onions",
            "Limit mushroom portion to 1/4 cup or omit"
        ],
        "monashGuidance": "According to Monash University...",
        "overallGuidance": "This recipe can be made low FODMAP with modifications..."
    }
}
```

## UI Components

### 1. FODMAPAnalysisDetailView
Full-screen analysis with:
- Overall recommendation card
- Category-by-category breakdown
- Detected high FODMAP foods with details
- Low FODMAP alternatives
- Modification tips
- Monash University attribution

### 2. FODMAPBadgeView
Compact badge for recipe lists:
- Color-coded (green/yellow/orange/red)
- Shows recommendation level
- Icon indicates safety

### 3. FODMAPCategoryBreakdownView
Displays all four categories:
- Visual level indicator
- Detected ingredients per category
- Category descriptions

## Best Practices

### 1. Portion Awareness

Many foods are low FODMAP in small amounts but high in large amounts:

```swift
// Check if portion matters
if detected.portionConcern {
    // Show portion guidance to user
    // Display serving size from Monash data
}
```

### 2. Always Provide Context

```swift
// Good
"Garlic is high FODMAP. Use garlic-infused oil (strain out solids) instead."

// Better
"Garlic contains fructans (oligosaccharides) which are high FODMAP. According to Monash University, garlic-infused oil is low FODMAP when garlic solids are strained out, as FODMAPs are water-soluble, not fat-soluble."
```

### 3. Update Regularly

FODMAP research evolves. Check Monash University for updates:
- New foods tested
- Portion size changes
- Category reclassifications

### 4. Combine with Dietitian Guidance

Always include disclaimers:

```swift
MonashAttributionView() // Shows disclaimer and link to Monash
```

## Testing

### Unit Tests

```swift
@Test("High FODMAP detection")
func testHighFODMAPDetection() {
    let recipe = createTestRecipe(ingredients: ["garlic", "onion", "wheat flour"])
    let result = FODMAPAnalyzer.shared.analyzeRecipe(recipe)
    
    #expect(result.recommendation == .avoid)
    #expect(result.detectedFoods.count >= 3)
}

@Test("Low FODMAP alternatives")
func testLowFODMAPAlternatives() {
    let recipe = createTestRecipe(ingredients: ["milk"])
    let result = FODMAPAnalyzer.shared.analyzeRecipe(recipe)
    
    #expect(result.lowFODMAPAlternatives.contains { $0.contains("lactose-free") })
}

@Test("Category breakdown")
func testCategoryBreakdown() {
    let recipe = createTestRecipe(ingredients: ["milk", "garlic"])
    let result = FODMAPAnalyzer.shared.analyzeRecipe(recipe)
    
    #expect(result.categoryBreakdown[.oligosaccharides]?.level == .high)
    #expect(result.categoryBreakdown[.disaccharides]?.level == .high)
}
```

### UI Tests

```swift
@Test("FODMAP badge displays correctly")
func testFODMAPBadgeDisplay() {
    // Test badge colors
    // Test text content
    // Test accessibility labels
}
```

## Monash University Data Source

All FODMAP classifications are based on the Monash University Low FODMAP Diet research.

**Official Resources:**
- Website: https://www.monashfodmap.com
- App: Monash FODMAP Diet (iOS/Android)
- Research: Department of Gastroenterology, Monash University, Melbourne, Australia

**Important Notes:**
- Monash University owns the trademark for "Low FODMAP Diet"
- FODMAP data is continuously updated through ongoing research
- Users should consult with registered dietitians for personalized advice
- The official Monash FODMAP app provides the most current data

## Integration with Existing Allergen System

FODMAP integrates seamlessly with the existing allergen detection:

1. **Unified Profile**: FODMAP is treated as an intolerance alongside gluten, lactose, etc.
2. **Combined Analysis**: Claude analyzes all sensitivities in one request
3. **Shared UI Patterns**: Uses same badge/score system as allergen detection
4. **Cross-References**: Some allergens overlap (lactose is both an allergen sensitivity and a FODMAP)

## Common FODMAP Scenarios

### Scenario 1: Garlic and Onions
**Problem**: Core ingredients in many recipes, very high FODMAP
**Solution**: 
- Use garlic-infused oil (strain solids)
- Use green tops of spring onions only
- Use asafoetida (hing) powder for flavor

### Scenario 2: Wheat Products
**Problem**: Wheat contains fructans (oligosaccharides)
**Solution**:
- Use gluten-free alternatives
- Use sourdough spelt bread (properly fermented >4 hours)
- Consider small portions of sourdough wheat bread

### Scenario 3: Dairy
**Problem**: Contains lactose (disaccharide)
**Solution**:
- Use lactose-free milk/cream/yogurt
- Use hard cheeses (naturally low lactose)
- Use butter (very low lactose)

### Scenario 4: Beans and Legumes
**Problem**: High in GOS (oligosaccharides)
**Solution**:
- Use canned lentils, rinsed well (1/2 cup serving)
- Use firm tofu instead
- Use tempeh in small amounts

### Scenario 5: Fruits
**Problem**: Many fruits high in fructose or polyols
**Solution**:
- Choose low FODMAP fruits: bananas, blueberries, strawberries
- Respect portion sizes
- Avoid dried fruit (concentrated FODMAPs)

## Future Enhancements

### Planned Features

1. **Portion Calculator**: Calculate FODMAP load based on servings
2. **Reintroduction Tracker**: Track FODMAP reintroduction phase
3. **Recipe Modifier**: Auto-suggest recipe modifications
4. **Meal Planning**: Plan complete low FODMAP meals
5. **Monash API Integration**: Real-time data from official app (if API becomes available)

### Contribution Guidelines

When adding new FODMAP data:
1. ✅ Verify against Monash University research
2. ✅ Include portion size information
3. ✅ Document FODMAP categories
4. ✅ Provide low FODMAP alternatives
5. ✅ Update tests
6. ✅ Update documentation

## Support and Resources

### For Users
- Consult a registered dietitian specializing in FODMAPs
- Use the official Monash FODMAP app
- Join FODMAP support communities

### For Developers
- Reference Monash University publications
- Stay updated with FODMAP research
- Test with diverse recipes
- Validate against official Monash data

## License and Attribution

This FODMAP analysis implementation:
- ✅ Is based on publicly available Monash University research
- ✅ Clearly attributes data to Monash University
- ✅ Directs users to official Monash resources
- ✅ Recommends professional dietitian consultation
- ✅ Provides educational information only, not medical advice

---

**Last Updated**: December 17, 2025
**Based on**: Monash University FODMAP Research
**Version**: 1.0
