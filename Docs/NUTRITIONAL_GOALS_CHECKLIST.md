# Nutritional Goals - Quick Start Checklist

Use this checklist to integrate the Nutritional Goals system into your Reczipes app.

## ✅ Pre-Integration Checklist

- [ ] Review `NUTRITIONAL_GOALS_SUMMARY.md` for overview
- [ ] Read `MEDICAL_GUIDELINES_REFERENCE.md` to understand guidelines
- [ ] Check `NUTRITIONAL_GOALS_GUIDE.md` for detailed integration steps
- [ ] Verify all new files are added to your Xcode project:
  - [ ] NutritionalGoals.swift
  - [ ] NutritionalAnalyzer.swift
  - [ ] NutritionalGoalsView.swift
  - [ ] NutritionalBadge.swift
  - [ ] RecipeNutritionalSection.swift
- [ ] Verify modified files are updated:
  - [ ] UserAllergenProfile.swift (Schema V3.0.0)
  - [ ] VersionHistory.swift

## 🔧 Integration Steps

### 1. Profile Settings Integration
- [ ] Open `AllergenProfileView.swift`
- [ ] Add navigation link to `NutritionalGoalsView`:
```swift
Section("Daily Targets") {
    NavigationLink {
        NutritionalGoalsView(profile: $profile)
    } label: {
        HStack {
            Label("Nutritional Goals", systemImage: "heart.text.square.fill")
            Spacer()
            if profile.hasNutritionalGoals {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}
```

### 2. Recipe Detail Integration
- [ ] Open `RecipeDetailView.swift`
- [ ] Add query for profiles:
```swift
@Query private var allergenProfiles: [UserAllergenProfile]

private var activeProfile: UserAllergenProfile? {
    allergenProfiles.first { $0.isActive }
}
```
- [ ] Add nutritional section to recipe detail:
```swift
RecipeNutritionalSection(
    recipe: recipe,
    profile: activeProfile,
    servings: currentServings
)
```

### 3. Filter Mode Update
- [ ] Open file containing `RecipeFilterMode` enum
- [ ] Add new case:
```swift
case nutrition = "Nutrition"
```
- [ ] Add computed property:
```swift
var includesNutritionalFilter: Bool {
    self == .nutrition || self == .combined
}
```

### 4. ContentView Filtering
- [ ] Open `ContentView.swift`
- [ ] Add state variable:
```swift
@State private var cachedNutritionalScores: [UUID: NutritionalScore] = [:]
```
- [ ] Update `processFilter()` method:
```swift
// In Task.detached block, add:
var nutritionalScores: [UUID: NutritionalScore] = [:]

// Analyze for nutrition if needed
if await currentMode.includesNutritionalFilter,
   let profile = currentProfile,
   let goals = profile.nutritionalGoals {
    nutritionalScores = await NutritionalAnalyzer.shared.analyzeRecipes(
        recipesToProcess,
        goals: goals
    )
}

// In MainActor.run capture list, add nutritionalScores:
await MainActor.run { [filteredRecipes, allergenScores, diabetesScores, combinedScores, nutritionalScores] in
    cachedNutritionalScores = nutritionalScores
    // ... rest of code
}
```

### 5. Recipe List Badges
- [ ] In `ContentView.swift`, update `recipeRow()`:
```swift
// After existing badges
if (filterMode == .nutrition || filterMode == .combined),
   let score = cachedNutritionalScores[recipe.id] {
    NutritionalBadge(score: score, compact: true)
}
```

### 6. Filter Bar UI
- [ ] Open `RecipeFilterBar.swift` (if you have one)
- [ ] Add nutrition option to picker/segmented control
- [ ] Update UI to show when nutrition filter is active

## 🧪 Testing Checklist

### Basic Functionality
- [ ] Create a test profile
- [ ] Open nutritional goals settings
- [ ] Select a preset template (e.g., "Diabetes Management")
- [ ] Verify all fields populate with correct values
- [ ] Modify a few individual fields
- [ ] Save and verify changes persist

### Recipe Analysis
- [ ] Open a recipe with your profile active
- [ ] Verify nutritional section appears
- [ ] Check compatibility score displays
- [ ] Expand section to see details
- [ ] Verify percentage bars show correctly
- [ ] Check alerts appear for high-risk nutrients

### Filtering
- [ ] Enable nutrition filter mode
- [ ] Verify recipes sort by compatibility
- [ ] Check badges appear in recipe list
- [ ] Toggle "show only safe" option
- [ ] Verify filtering works correctly

### All Preset Templates
- [ ] Test "Weight Loss" preset
- [ ] Test "Diabetes Management" preset
- [ ] Test "Heart Health" preset
- [ ] Test "General Health" preset
- [ ] Test "Athletic Performance" preset

### Edge Cases
- [ ] Test with no goals set (should prompt user)
- [ ] Test with partially filled goals
- [ ] Test with custom goals
- [ ] Test serving size changes
- [ ] Test with estimated vs. actual nutrition

## 📱 UI/UX Verification

- [ ] Medical disclaimer displays in goals view
- [ ] Icons are consistent and meaningful
- [ ] Colors match severity levels (green/yellow/orange/red)
- [ ] Text is readable and concise
- [ ] Loading states work smoothly
- [ ] Navigation flows naturally
- [ ] Compact badges fit in list view
- [ ] Expanded view has good spacing
- [ ] Forms are easy to fill out
- [ ] Keyboard dismisses properly

## ☁️ CloudKit Sync Testing

- [ ] Set goals on device 1
- [ ] Wait for sync
- [ ] Verify goals appear on device 2
- [ ] Modify goals on device 2
- [ ] Verify changes sync back to device 1
- [ ] Test with poor/no internet connection

## 🎯 Performance Testing

- [ ] Test with 100+ recipes
- [ ] Verify filtering doesn't lag
- [ ] Check analysis completes quickly
- [ ] Monitor memory usage
- [ ] Test on older devices
- [ ] Verify UI remains responsive

## 📋 Pre-Release Checklist

### Code Review
- [ ] All TODOs addressed or documented
- [ ] No debug print statements in production code
- [ ] Comments are clear and helpful
- [ ] Code follows Swift style guidelines
- [ ] No force unwraps in critical paths

### Documentation
- [ ] README updated with new feature
- [ ] API documentation complete
- [ ] User guide updated
- [ ] Version history up to date

### Legal/Medical
- [ ] Medical disclaimer is prominent
- [ ] Source citations are accurate
- [ ] No medical advice claims
- [ ] Privacy policy updated if needed
- [ ] Terms of service reviewed

### Accessibility
- [ ] VoiceOver labels are descriptive
- [ ] Dynamic type works correctly
- [ ] Color contrast meets standards
- [ ] Navigation is logical
- [ ] Alerts are announced

### Localization (if applicable)
- [ ] All strings are localizable
- [ ] Number formatting respects locale
- [ ] Date formatting is localized
- [ ] Units are appropriate for region

## 🚀 Deployment Checklist

- [ ] Increment version number in Xcode
- [ ] Update VersionHistory.swift
- [ ] Build and archive
- [ ] Test on real devices
- [ ] Submit for TestFlight
- [ ] Get beta tester feedback
- [ ] Fix any reported issues
- [ ] Submit to App Store
- [ ] Prepare app store listing updates
- [ ] Plan marketing announcement

## 📞 Support Preparation

- [ ] FAQ prepared for new feature
- [ ] Support team trained
- [ ] Common issues documented
- [ ] Rollback plan if needed
- [ ] Monitoring setup for errors

## ✨ Post-Launch

- [ ] Monitor crash reports
- [ ] Check user reviews
- [ ] Gather usage analytics
- [ ] Plan future enhancements
- [ ] Document lessons learned

## 🔮 Future Enhancement Ideas

### Near-term (Next Version)
- [ ] Claude API integration for accurate nutrition
- [ ] Manual nutrition entry
- [ ] Nutrition fact label scanner

### Mid-term (3-6 months)
- [ ] USDA database integration
- [ ] Daily meal planning
- [ ] Progress tracking over time
- [ ] Recipe suggestions based on goals

### Long-term (6-12 months)
- [ ] Barcode scanning
- [ ] Apple Health integration
- [ ] Grocery list with nutrition totals
- [ ] Meal prep calculator

## 📝 Notes

Use this space for notes during integration:

```
Date: _______________
Developer: _______________

Issues encountered:
-
-
-

Solutions found:
-
-
-

Time spent: _______ hours

Additional considerations:
-
-
-
```

---

**Remember**: 
- Take your time with each step
- Test thoroughly before moving to the next
- Document any deviations from this checklist
- Ask for help if needed
- Celebrate when complete! 🎉

**Support Resources**:
- NUTRITIONAL_GOALS_GUIDE.md - Detailed integration guide
- MEDICAL_GUIDELINES_REFERENCE.md - Medical guideline reference
- NUTRITIONAL_GOALS_SUMMARY.md - Feature overview
- Code comments - Implementation notes
