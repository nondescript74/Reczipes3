# Allergen Detection & Scoring System

## Overview

The Reczipes2 app now includes a comprehensive allergen detection and scoring system that automatically analyzes recipes based on your food sensitivities and allergens. The system tracks the "Big 9" allergens plus common intolerances, provides safety scores, and helps you make informed decisions about which recipes are safe for you.

## Features

### 1. User Allergen Profiles
- Create multiple allergen profiles (e.g., "My Profile", "Child", "Guest")
- Set one profile as active for automatic recipe analysis
- Track sensitivities with three severity levels: Mild, Moderate, Severe

### 2. Supported Allergens & Intolerances

**Big 9 Allergens:**
- 🥛 Milk
- 🥚 Eggs
- 🥜 Peanuts
- 🌰 Tree Nuts (almonds, cashews, walnuts, etc.)
- 🌾 Wheat
- 🫘 Soy
- 🐟 Fish
- 🦐 Shellfish
- 🫘 Sesame

**Common Intolerances:**
- 🌾 Gluten
- 🥛 Lactose
- ☕️ Caffeine
- 🍷 Histamine
- 🫐 Salicylates
- 🍇 Sulfites
- 🧅 FODMAPs

### 3. Automatic Recipe Analysis

The system automatically:
- Scans all ingredient names for allergen keywords
- Checks ingredient preparations (e.g., "melted butter")
- Detects hidden allergens (e.g., whey in milk, gluten in soy sauce)
- Calculates a risk score based on severity levels
- Shows safety badges in the recipe list

### 4. Safety Scoring System

**Score Calculation:**
- Base: 1 point per matched ingredient
- Multiplied by severity: Mild (×1), Moderate (×2), Severe (×5)
- Total score determines risk level

**Risk Levels:**
- **Safe (0)**: No detected allergens ✅
- **Low Risk (< 5)**: Minor allergens detected ⚠️
- **Medium Risk (5-10)**: Moderate concern ⚠️⚠️
- **High Risk (> 10)**: Severe allergens detected 🚫

## How to Use

### Creating Your First Allergen Profile

1. **Access Allergen Profiles**
   - Open the app
   - Go to the Recipes tab
   - Tap the allergen filter bar at the top (shows "No Profile" initially)
   - Or navigate to Settings → Allergen Profiles

2. **Create a Profile**
   - Tap the "+" button
   - Enter a profile name (e.g., "My Allergies")
   - Tap "Create"

3. **Add Your Sensitivities**
   - In your new profile, tap "Add Sensitivity"
   - Choose between "Big 9 Allergens" or "Intolerances" tabs
   - Select the allergen/intolerance (e.g., Peanuts)
   - Set the severity level (Mild/Moderate/Severe)
   - Optionally add notes (e.g., "Anaphylactic reaction")
   - Tap "Add"

4. **Set as Active Profile**
   - Toggle "Active Profile" ON
   - This enables automatic recipe analysis

### Viewing Recipe Safety Scores

**In the Recipe List:**
- When a profile is active and filtering is enabled, you'll see:
  - ✅ Green checkmark + "Safe" for safe recipes
  - ⚠️ Yellow/Orange/Red triangle for recipes with allergens
  - Recipes are automatically sorted by safety score

**Filtering Options:**
- **Filter Toggle**: Enable/disable allergen filtering
- **Safe Only**: Show only recipes with no detected allergens

**In Recipe Details:**
- Recipes display an "Allergen Analysis" section showing:
  - Overall safety badge
  - Active profile name
  - "View Detailed Analysis" button (if allergens detected)

### Detailed Allergen Analysis

Tap "View Detailed Analysis" to see:
- Overall safety score with visual gauge
- Complete list of detected allergens
- Which ingredients contain each allergen
- Matched keywords that triggered detection
- Recommendation text based on risk level

Example:
```
Detected Allergens (2)

🥛 Milk - Severe
Found in:
• butter
• cream
• parmesan cheese
Matched keywords: butter, cream, cheese

🌾 Wheat - Moderate
Found in:
• all-purpose flour
• bread crumbs
Matched keywords: flour, bread
```

## Advanced Features

### Multiple Profiles

Create different profiles for various scenarios:
- **Personal**: Your own sensitivities
- **Family**: Combined family allergens
- **Guests**: Allergens for specific visitors
- **Test**: Experimenting with elimination diets

Only one profile can be active at a time. Switch between profiles by:
1. Opening any profile
2. Toggling "Active Profile" ON (automatically deactivates others)

### Severity Levels Explained

**Mild (⚠️)**
- Minor reactions or mild discomfort
- Score multiplier: ×1
- Example: Slight digestive discomfort from lactose

**Moderate (⚠️⚠️)**
- Noticeable symptoms requiring attention
- Score multiplier: ×2
- Example: Significant bloating from FODMAPs

**Severe (🚫)**
- Serious reactions requiring avoidance
- Score multiplier: ×5
- Example: Anaphylaxis from peanuts

### Keyword Detection System

The system uses an extensive keyword database to detect allergens:

**Milk Keywords:**
- Direct: milk, cream, butter, cheese, yogurt
- Hidden sources: whey, casein, lactose, ghee
- Preparations: sour cream, ice cream, buttermilk

**Gluten Keywords:**
- Grains: wheat, barley, rye, spelt, kamut
- Products: flour, bread, pasta, couscous
- Hidden sources: malt, brewer's yeast, semolina

**And many more...** (See `AllergenProfile.swift` for complete lists)

## Integration with Claude API

### Enhanced Analysis (Future Feature)

The system is designed to work with Claude for advanced detection:

```swift
// Generate a prompt for Claude API analysis
let prompt = AllergenAnalyzer.shared.generateClaudeAnalysisPrompt(
    recipe: recipe, 
    profile: profile
)
```

This allows Claude to:
- Detect hidden allergens in processed ingredients
- Suggest safe substitutions
- Provide context-aware risk assessment
- Identify cross-contamination risks

## Architecture

### Key Files

**Data Models:**
- `AllergenProfile.swift` - Allergen definitions and user profiles
- `Recipe.swift` - Extended to support allergen analysis
- `RecipeModel.swift` - Ingredient structure for parsing

**Analysis Engine:**
- `AllergenAnalyzer.swift` - Core detection and scoring logic

**User Interface:**
- `AllergenProfileView.swift` - Profile management UI
- `RecipeAllergenBadge.swift` - Badge and detail views
- `ContentView.swift` - Recipe list with filtering
- `RecipeDetailView.swift` - Recipe details with allergen info

### Data Flow

```
1. User creates profile with sensitivities
   ↓
2. Profile stored in SwiftData (UserAllergenProfile)
   ↓
3. Active profile queried by views
   ↓
4. AllergenAnalyzer scans recipe ingredients
   ↓
5. Keywords matched against sensitivity list
   ↓
6. Score calculated with severity multipliers
   ↓
7. Results displayed as badges and details
```

### SwiftData Models

**UserAllergenProfile:**
```swift
@Model
final class UserAllergenProfile {
    var id: UUID
    var name: String
    var isActive: Bool
    var sensitivitiesData: Data? // JSON array of UserSensitivity
    var dateCreated: Date
    var dateModified: Date
}
```

**UserSensitivity:**
```swift
struct UserSensitivity: Codable {
    let id: UUID
    let allergen: FoodAllergen?        // For Big 9
    let intolerance: FoodIntolerance?  // For other sensitivities
    let severity: SensitivitySeverity
    let notes: String?
}
```

## Best Practices

### For Users

1. **Be Specific**: Add all your sensitivities, even mild ones
2. **Set Accurate Severity**: This affects scoring and recommendations
3. **Add Notes**: Document reaction types or special circumstances
4. **Review Results**: Always check detailed analysis for important recipes
5. **Trust But Verify**: The system is helpful but not infallible - always read ingredient labels

### For Developers

1. **Extend Keywords**: Add region-specific ingredient names
2. **Customize Scoring**: Adjust multipliers based on user feedback
3. **Add More Allergens**: System is extensible for new categories
4. **Integrate with Claude**: Use AI for detecting hidden allergens
5. **Test Edge Cases**: Unusual ingredient names or preparations

## Troubleshooting

**Problem: No allergen badges showing**
- Ensure you have an active profile (toggle "Active Profile" ON)
- Enable filtering in the recipe list
- Check that your profile has sensitivities added

**Problem: Allergens not detected**
- Check if ingredient names use different terminology
- Add custom keywords to the sensitivity definition
- Consider using Claude API integration for better detection

**Problem: Too many false positives**
- Reduce severity levels for minor intolerances
- Review keyword lists for overly broad matches
- Use "Safe Only" filter to see truly safe recipes

**Problem: Profile changes not reflected**
- Swipe to refresh the recipe list
- Toggle filter off/on to force refresh
- Restart the app if issues persist

## Future Enhancements

Planned features:
1. **Custom Allergen Categories**: Add your own allergen types
2. **Ingredient Substitution Suggestions**: AI-powered alternatives
3. **Recipe Safety Score History**: Track changes over time
4. **Cross-Contamination Warnings**: Detect preparation risks
5. **Shareable Profiles**: Export/import profiles for family members
6. **Barcode Scanning**: Detect allergens in packaged ingredients
7. **Restaurant Integration**: Check menu items for allergens
8. **Meal Planning**: Plan safe meals for the week
9. **Nutrition Integration**: Combine with dietary goals
10. **Community Submissions**: Crowdsourced allergen data

## Privacy & Data

- All allergen profiles are stored locally on your device
- No allergen data is sent to external servers
- SwiftData ensures private, encrypted storage
- Profiles can be deleted at any time
- No personally identifiable health information is collected

## Support & Feedback

If you encounter issues or have suggestions:
1. Check this documentation
2. Review code comments in `AllergenProfile.swift` and `AllergenAnalyzer.swift`
3. Submit feedback through app settings
4. Contribute improvements via pull requests

---

## Quick Reference

### Allergen Icons
🥛 Milk | 🥚 Eggs | 🥜 Peanuts | 🌰 Tree Nuts | 🌾 Wheat/Gluten  
🫘 Soy/Sesame | 🐟 Fish | 🦐 Shellfish | ☕️ Caffeine | 🍷 Histamine  
🫐 Salicylates | 🍇 Sulfites | 🧅 FODMAPs

### Safety Badges
✅ Safe | ⚠️ Low Risk | ⚠️⚠️ Medium Risk | 🚫 High Risk

### Severity Levels
⚠️ Mild (×1) | ⚠️⚠️ Moderate (×2) | 🚫 Severe (×5)

---

*Last Updated: December 17, 2025*
