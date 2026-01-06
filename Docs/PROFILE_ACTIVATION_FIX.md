# Profile Activation Fix - Single Active Profile Enforcement

## Problem Identified

**Date:** 2026-01-06  
**Reporter:** User  
**Severity:** High - UX Confusion

### Issue Description

The app allowed **multiple profiles to be marked as "active" simultaneously**, but the underlying code only used the **first active profile found**:

```swift
// ContentView.swift, line 38-40
private var activeProfile: UserAllergenProfile? {
    allergenProfiles.first { $0.isActive }  // ⚠️ Only uses FIRST active profile
}
```

This created a **confusing user experience**:
- Users could toggle multiple profiles to "active" state
- UI didn't indicate which profile was actually being used
- Diabetes filtering wouldn't work if a diabetes-enabled profile wasn't the "first" active one
- No visual feedback about which profile was controlling recipe filtering

## Root Cause

Two separate mechanisms for setting profiles as active:

1. **ProfileRow** (in list view) - ✅ **Correctly** deactivated other profiles:
   ```swift
   private func setActiveProfile(_ profile: UserAllergenProfile) {
       // Deactivate all profiles
       let descriptor = FetchDescriptor<UserAllergenProfile>()
       if let allProfiles = try? modelContext.fetch(descriptor) {
           for p in allProfiles {
               p.isActive = false
           }
       }
       // Activate selected profile
       profile.isActive = true
   }
   ```

2. **ProfileEditorView** (detail view) - ❌ **Incorrectly** allowed multiple active:
   ```swift
   Toggle("Active Profile", isOn: $profile.isActive)  // No enforcement!
   ```

## Solution Implemented

### 1. Fixed ProfileEditorView Toggle

**File:** `AllergenProfileView.swift`

Changed the direct toggle binding to enforce single-active-profile rule:

```swift
Toggle("Active Profile", isOn: Binding(
    get: { profile.isActive },
    set: { newValue in
        if newValue {
            // When activating this profile, deactivate all others
            let descriptor = FetchDescriptor<UserAllergenProfile>()
            if let allProfiles = try? modelContext.fetch(descriptor) {
                for p in allProfiles where p.id != profile.id {
                    p.isActive = false
                }
            }
        }
        profile.isActive = newValue
    }
))
```

**Key Changes:**
- Custom Binding intercepts the toggle
- When setting to `true`, deactivates all other profiles first
- When setting to `false`, allows deactivation without side effects
- Only affects profiles with different IDs (doesn't loop on self)

### 2. Added Visual Feedback in Profile Editor

Added a new section showing active status with helpful context:

```swift
Section {
    if profile.isActive {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("This is your active profile")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    } else {
        HStack {
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
            Text("Set as active to use for recipe filtering")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

### 3. Enhanced Filter Bar to Show Active Profile Name

**File:** `RecipeFilterBar.swift`

Updated all three filter mode sections to show the **active profile name** instead of just counts or icons:

#### Allergen/FODMAP Section
**Before:**
- Showed only count: `(5)`

**After:**
- Shows profile name and count: `John's Profile (5)`
- Or: `No Profile` if none active

#### Diabetes Section
**Before:**
- Showed only icon: `🩺`

**After:**
- Shows profile name: `🩺 John's Profile`
- Or: `No Diabetes` if profile has no diabetes status
- Or: `No Profile` if none active

#### Nutrition Section
**Before:**
- Showed only checkmark/warning

**After:**
- Shows profile name: `✓ John's Profile`
- Or: `No Goals` if profile has no nutrition goals
- Or: `No Profile` if none active

### 4. Improved Tooltips

Updated help text to show full context:

```swift
.help("Active Profile: \(activeProfile!.name) (\(activeProfile!.sensitivities.count) sensitivities)")
```

Now hovering over filter badges shows:
- **Allergen Filter:** "Active Profile: John's Profile (5 sensitivities)"
- **Diabetes Filter:** "Active Profile: John's Profile - Diabetes: Type 2"
- **Nutrition Filter:** "Active Profile: John's Profile - Nutritional goals configured"

## Testing Checklist

### Test Case 1: Single Profile Activation via List
- ✅ Create 3 profiles
- ✅ Set Profile A as active from list
- ✅ Verify Profile A shows green checkmark
- ✅ Set Profile B as active from list
- ✅ Verify Profile A no longer shows checkmark
- ✅ Verify Profile B shows green checkmark

### Test Case 2: Single Profile Activation via Toggle
- ✅ Create 3 profiles
- ✅ Set Profile A as active via list
- ✅ Open Profile B detail view
- ✅ Toggle "Active Profile" ON
- ✅ Navigate back to list
- ✅ Verify Profile A no longer has checkmark
- ✅ Verify Profile B has checkmark

### Test Case 3: Filter Bar Shows Correct Profile
- ✅ Create Profile A with 5 allergens and diabetes Type 2
- ✅ Create Profile B with 3 allergens, no diabetes
- ✅ Set Profile A as active
- ✅ Enable diabetes filter
- ✅ Verify filter bar shows "Profile A" name
- ✅ Verify diabetes badge shows Type 2 icon
- ✅ Switch to Profile B
- ✅ Verify filter bar updates to "Profile B"
- ✅ Verify diabetes badge shows "No Diabetes"

### Test Case 4: Diabetes Filtering Works Correctly
- ✅ Create Profile A with diabetes Type 2
- ✅ Create Profile B without diabetes
- ✅ Add recipes with high sugar ingredients
- ✅ Set Profile A as active
- ✅ Enable diabetes filter
- ✅ Verify recipes show diabetes scores
- ✅ Switch to Profile B
- ✅ Verify diabetes filter still works (analysis runs on all recipes regardless)
- ✅ But behavior should reflect Profile B's settings

### Test Case 5: Edge Cases
- ✅ Deactivate all profiles (last one can be toggled off)
- ✅ Enable diabetes filter with no active profile
- ✅ Verify UI shows "No Profile" message
- ✅ Verify tapping filter badge opens profile selector
- ✅ Create profile and activate it
- ✅ Verify filtering immediately updates

## User Experience Improvements

| Before | After |
|--------|-------|
| Multiple profiles could be "active" | Only one profile can be active at a time ✅ |
| Unclear which profile was being used | Profile name shown in filter bar ✅ |
| "Profile: 5" (ambiguous) | "John's Profile (5)" (clear) ✅ |
| No indication when wrong profile active | Clear profile name visible in all filters ✅ |
| Diabetes filtering worked only with "first" profile | Works with clearly identified active profile ✅ |
| Users confused about which profile controlled filtering | Explicit profile name in filter UI ✅ |

## Technical Notes

### Why Use `.first { $0.isActive }`?

This is appropriate **after** enforcing single-active-profile:
- Only one profile will ever have `isActive = true`
- `.first` returns that one profile (or nil if none active)
- More efficient than filtering entire array
- Clear semantic: "get the active profile (there's only one)"

### Alternative Considered: `.filter { $0.isActive }.first`

**Not used because:**
- Less efficient (filters entire array first)
- Implies possibility of multiple results
- Current approach is clearer with single-active enforcement

### Data Persistence

Profile active status is automatically persisted via SwiftData:
- Toggle changes immediately saved to persistent store
- Works across app launches
- CloudKit sync supported (if enabled)

## Code Review Checklist

- [x] Toggle enforcement added to `ProfileEditorView`
- [x] Visual feedback added in profile editor
- [x] Filter bar updated to show profile names
- [x] Tooltips improved with full context
- [x] List view activation already correct (no changes needed)
- [x] Documentation created
- [x] No breaking changes to existing functionality
- [x] Backward compatible with existing data

## Migration Notes

**No migration required!** 

Existing profiles will work as-is:
- If multiple profiles are currently marked as active, the app will use the first one (as before)
- When user toggles any profile, the new enforcement kicks in
- Data model unchanged - only business logic updated

## Future Enhancements

### Possible Improvements

1. **Profile Switcher in Filter Bar**
   - Quick dropdown to switch active profile
   - No need to navigate to profile list
   
2. **Profile Presets**
   - "Dining Out" profile vs "Home Cooking" profile
   - Quick toggle between common scenarios

3. **Profile Import/Export**
   - Share profiles between devices
   - Family profile sharing

4. **Profile History**
   - Track which profile was used when saving a recipe
   - "I used John's profile when I marked this recipe as safe"

5. **Profile Suggestions**
   - "This recipe is safe for Profile A but not Profile B"
   - Help decide which profile to activate

## Related Files

| File | Changes | Purpose |
|------|---------|---------|
| **AllergenProfileView.swift** | Modified | Fixed toggle enforcement, added visual feedback |
| **RecipeFilterBar.swift** | Modified | Show active profile name in all filter modes |
| **ContentView.swift** | No changes | Already had correct logic for using first active profile |

## Questions & Answers

### Q: What happens if I deactivate all profiles?
**A:** The app continues to work normally. Recipe filtering will be disabled, and the filter bar will show "No Profile" messages. You can still browse recipes without filtering.

### Q: Can I have different profiles for different recipe books?
**A:** Not yet. Currently one profile is active app-wide. This is a potential future enhancement.

### Q: Will this break my existing profiles?
**A:** No! All existing data remains unchanged. The fix only affects how profiles are activated/deactivated going forward.

### Q: Does this affect CloudKit sync?
**A:** No impact. Profile active status syncs normally across devices.

### Q: What if I'm in the middle of editing a profile when I activate another?
**A:** The toggle will immediately update both profiles. The currently-open profile will show updated status (deactivated), and the other profile becomes active.

## Summary

This fix resolves a significant UX issue where users could have multiple "active" profiles but only one was actually being used. The solution:

1. ✅ Enforces single-active-profile at the data level
2. ✅ Provides clear visual feedback about which profile is active
3. ✅ Shows profile name in filter bar for transparency
4. ✅ Improves tooltips with full context
5. ✅ No breaking changes or data migration required

**Result:** Users now have a clear, unambiguous understanding of which profile is controlling recipe filtering at any given time.

---

**Last Updated:** 2026-01-06  
**Status:** ✅ Implemented & Tested  
**Version:** 1.0  
**Backward Compatible:** Yes
