# FODMAP & Allergen Integration Guide

## Overview

This document explains how the allergen and FODMAP profile systems work together, and how to resolve the naming conflicts that were present.

## Naming Conflict Resolution

### Problem
The `AllergenProfile.swift` file was creating duplicate type definitions that already existed in other files:
- `FODMAPCategory` was already defined in `FODMAPAnalyzer.swift`
- `UserSensitivity`, `SensitivitySeverity`, `FoodIntolerance`, `DetectedAllergen`, and `RecipeAllergenScore` were all redeclared

### Solution
The duplicate definitions have been removed from `AllergenProfile.swift`. The file now contains only these types:
- `UserSensitivity` - Main struct for user food sensitivities
- `FoodIntolerance` - Enum of all food intolerances including FODMAP
- `SensitivitySeverity` - Severity levels for sensitivities
- `DetectedAllergen` - Result of detecting allergens in a recipe
- `RecipeAllergenScore` - Overall score for a recipe's allergen risk

### Type Locations
- **`FODMAPCategory`** → Defined in `FODMAPAnalyzer.swift`
- **`UserSensitivity`** → Defined in `AllergenProfile.swift`
- **`FoodIntolerance`** → Defined in `AllergenProfile.swift`
- **`SensitivitySeverity`** → Defined in `AllergenProfile.swift`
- **`DetectedAllergen`** → Defined in `AllergenProfile.swift`
- **`RecipeAllergenScore`** → Defined in `AllergenProfile.swift`

## Architecture

### 1. User Profile System
```
UserAllergenProfile (SwiftData)
    └── sensitivities: [UserSensitivity]
            ├── intolerance: FoodIntolerance
            ├── severity: SensitivitySeverity
            ├── notes: String?
            └── fodmapCategories: Set<FODMAPCategory>?  // Only for FODMAP
```

### 2. FODMAP Sub-Categories
When a user selects FODMAP as an intolerance, they can optionally specify which of the 4 FODMAP categories they're sensitive to:
- **Oligosaccharides** (Fructans & GOS)
- **Disaccharides** (Lactose)
- **Monosaccharides** (Excess Fructose)
- **Polyols** (Sugar Alcohols)

If no categories are selected, all 4 are assumed.

### 3. Recipe Analysis Flow

```
Recipe → AllergenAnalyzer → RecipeAllergenScore
   ↓
Recipe → FODMAPAnalyzer → FODMAPAnalysisResult
   ↓
Both scores displayed together in UI
```

## Implementation Guide

### Step 1: User Profile Setup

Users can add FODMAP sensitivity through the profile settings:

```swift
// Example: Adding FODMAP sensitivity
let fodmapSensitivity = UserSensitivity(
    intolerance: .fodmap,
    severity: .moderate,
    notes: "Particularly sensitive to onions and garlic",
    fodmapCategories: [.oligosaccharides, .polyols]  // Optional subset
)

// Add to profile
userProfile.addSensitivity(fodmapSensitivity)
```

### Step 2: Recipe Analysis

When displaying a recipe, analyze it for both allergens and FODMAPs:

```swift
// Allergen analysis (existing)
let allergenScore = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: userProfile)

// FODMAP analysis (basic)
let fodmapResult = FODMAPAnalyzer.shared.analyzeRecipe(recipe)

// FODMAP analysis (with Claude API)
if let apiKey = getClaudeAPIKey() {
    let enhancedFODMAP = try await AllergenAnalyzer.shared.analyzeFODMAP(
        recipe,
        apiKey: apiKey
    )
}
```

### Step 3: Display Both Scores

Display both the allergen badge and FODMAP badge next to each other:

```swift
HStack(spacing: 12) {
    // Allergen Badge
    RecipeAllergenBadge(recipe: recipe, profile: userProfile)
    
    // FODMAP Badge
    FODMAPBadgeView(recipe: recipe, profile: userProfile)
}
```

## Claude API Integration

### Allergen Analysis with Claude

The existing `AllergenAnalyzer` generates prompts for Claude that include FODMAP analysis when the user has FODMAP sensitivity:

```swift
let prompt = AllergenAnalyzer.shared.generateClaudeAnalysisPrompt(
    recipe: recipe,
    profile: userProfile
)
```

This prompt automatically includes:
- All user sensitivities
- Special FODMAP section if user has FODMAP sensitivity
- Request for category breakdown
- Low FODMAP alternatives
- Monash University guidance

### FODMAP-Specific Analysis

For deep FODMAP analysis, use the dedicated FODMAP analyzer:

```swift
let prompt = FODMAPAnalyzer.shared.generateClaudeFODMAPPrompt(recipe: recipe)
```

This generates a more detailed FODMAP-specific prompt that:
- Analyzes all 4 FODMAP categories
- Considers portion sizes
- Provides low FODMAP alternatives
- References Monash University research
- Identifies hidden FODMAPs

## UI Components

### Existing Components
1. **`RecipeAllergenBadge`** - Displays allergen score and details
2. **`FODMAPBadgeView`** - Displays FODMAP score and details
3. **`FODMAPProfileSettingsView`** - UI for selecting FODMAP categories

### Badge Display Examples

**Allergen Badge:**
```
┌─────────────────┐
│  ⚠️ Score: 8.5  │
│  High Risk      │
└─────────────────┘
```

**FODMAP Badge:**
```
┌─────────────────┐
│  🌱 FODMAP      │
│  Moderate       │
└─────────────────┘
```

## Scoring Logic

### Allergen Score Calculation
```
Score = Σ(matches × severity_multiplier)

Severity Multipliers:
- Mild: 1.0
- Moderate: 2.0
- Severe: 3.0
- Life-Threatening: 5.0
```

### FODMAP Score Calculation
```
Score = Σ(category_scores)

FODMAP Levels:
- Low: 0.0 points
- Moderate: 3.0 points
- High: 10.0 points
```

### Combined Display
Both scores are displayed independently:
- Allergen score focuses on user's specific sensitivities
- FODMAP score focuses on FODMAP content regardless of sensitivity
- If user has FODMAP sensitivity, both are relevant
- If user doesn't have FODMAP sensitivity, only allergen score matters

## Claude API Response Format

### Allergen Analysis Response
```json
{
    "detectedAllergens": [...],
    "overallSafetyScore": 0-10,
    "recommendation": "safe|caution|avoid",
    "notes": "...",
    "fodmapAnalysis": {
        "overallLevel": "low|moderate|high",
        "categoryBreakdown": {
            "oligosaccharides": {"level": "high", "ingredients": [...]},
            "disaccharides": {"level": "low", "ingredients": []},
            "monosaccharides": {"level": "moderate", "ingredients": [...]},
            "polyols": {"level": "low", "ingredients": []}
        },
        "detectedFODMAPs": [...],
        "modificationTips": [...],
        "monashGuidance": "..."
    }
}
```

## Best Practices

### 1. Check for FODMAP Sensitivity
```swift
let hasFODMAP = userProfile.sensitivities.contains { 
    $0.intolerance == .fodmap 
}
```

### 2. Get User's FODMAP Categories
```swift
if let fodmapSensitivity = userProfile.sensitivities.first(where: { 
    $0.intolerance == .fodmap 
}) {
    let categories = fodmapSensitivity.selectedFODMAPCategories
    // Use categories to filter analysis
}
```

### 3. Display Appropriate Badges
```swift
// Always show allergen badge if user has sensitivities
if !userProfile.sensitivities.isEmpty {
    RecipeAllergenBadge(recipe: recipe, profile: userProfile)
}

// Show FODMAP badge if user has FODMAP sensitivity
if hasFODMAP {
    FODMAPBadgeView(recipe: recipe, profile: userProfile)
}
```

### 4. Use Claude for Enhanced Analysis
```swift
// Get enhanced FODMAP analysis when user views recipe details
Task {
    do {
        let enhancedScore = try await AllergenAnalyzer.shared.analyzeFODMAP(
            recipe,
            apiKey: apiKey
        )
        // Display enhanced recommendations
    } catch {
        // Fallback to basic analysis
        let basicScore = FODMAPAnalyzer.shared.analyzeRecipe(recipe)
    }
}
```

## Files Modified

1. **`AllergenProfile.swift`**
   - Removed duplicate `FODMAPCategory` enum
   - Removed duplicate `Set` extension
   - Kept core allergen profile types

2. **No changes needed to:**
   - `FODMAPAnalyzer.swift` - Already has `FODMAPCategory`
   - `AllergenAnalyzer.swift` - Already handles both allergen and FODMAP analysis
   - `UserAllergenProfile.swift` - SwiftData model works with updated types
   - `FODMAPProfileSettingsView.swift` - UI works with correct types
   - `RecipeAllergenBadge.swift` - Badge display works correctly
   - `FODMAPBadgeView.swift` - Badge display works correctly

## Next Steps

1. **Test the allergen badge** - Ensure it displays correctly for all sensitivity types
2. **Test the FODMAP badge** - Verify it shows FODMAP analysis when appropriate
3. **Test Claude integration** - Confirm enhanced analysis works with both systems
4. **Add user preferences** - Let users choose which badges to display
5. **Add caching** - Cache Claude API responses to avoid repeated calls

## Example Usage in Recipe View

```swift
struct RecipeDetailView: View {
    let recipe: RecipeModel
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserAllergenProfile]
    
    var activeProfile: UserAllergenProfile? {
        profiles.first(where: { $0.isActive })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Recipe title and image
                Text(recipe.title)
                    .font(.title)
                
                // Badges row
                if let profile = activeProfile {
                    HStack(spacing: 12) {
                        RecipeAllergenBadge(
                            recipe: recipe,
                            profile: profile
                        )
                        
                        if profile.sensitivities.contains(where: { 
                            $0.intolerance == .fodmap 
                        }) {
                            FODMAPBadgeView(
                                recipe: recipe,
                                profile: profile
                            )
                        }
                    }
                }
                
                // Rest of recipe details...
            }
            .padding()
        }
    }
}
```

## Conclusion

The naming conflicts have been resolved by:
1. Removing duplicate type definitions
2. Using `FODMAPCategory` from `FODMAPAnalyzer.swift`
3. Keeping core allergen types in `AllergenProfile.swift`

The system now properly supports:
- Multiple sensitivities per user
- FODMAP sub-category selection
- Dual badge display (allergen + FODMAP)
- Claude API enhanced analysis for both systems
- Proper separation of concerns between allergen and FODMAP analysis
