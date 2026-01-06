# Profile Management Quick Reference

## 🎯 Key Principle

**Only ONE profile can be active at a time**

The active profile controls:
- ✅ Allergen filtering
- ✅ FODMAP analysis  
- ✅ Diabetes recommendations
- ✅ Nutritional goal tracking

## How to Set Active Profile

### Method 1: From Profile List
1. Open **Settings** → **Allergen Profiles**
2. Find the profile you want to use
3. Tap **"Set Active"** button
4. ✅ All other profiles automatically deactivate

### Method 2: From Profile Detail
1. Open **Settings** → **Allergen Profiles**
2. Tap on any profile to open details
3. Toggle **"Active Profile"** ON
4. ✅ All other profiles automatically deactivate

## Visual Indicators

### Profile List View
- **Green checkmark ✓** = Currently active profile
- **"Set Active" button** = Inactive profile, tap to activate

### Profile Detail View
- **Green checkmark + "This is your active profile"** = Active
- **Blue info icon + "Set as active to use for recipe filtering"** = Inactive

### Filter Bar (Top of Recipe List)

When you enable filters, you'll see the active profile name:

| Filter Type | Display |
|------------|---------|
| **Allergen/FODMAP** | `🧑 John's Profile (5)` |
| **Diabetes** | `❤️ 🩺 John's Profile` |
| **Nutrition** | `🍃 ✓ John's Profile` |
| **No Profile Active** | `⚠️ No Profile` |

## Filter Modes Explained

Tap the circular icons in the filter bar to activate:

| Icon | Mode | What It Does | Requires Active Profile? |
|------|------|--------------|------------------------|
| ⭕️ Gray | None | Shows all recipes unsorted | No |
| 🟠 Orange | Allergen/FODMAP | Filters by allergen safety | Yes - needs allergens set |
| 🔴 Red | Diabetes | Sorts by diabetes suitability | Yes - needs diabetes status |
| 🟢 Green | Nutrition | Sorts by nutritional goals | Yes - needs nutrition goals |
| 🟣 Purple | All | Applies all filters together | Yes - uses all profile data |

## Troubleshooting

### "Not seeing diabetes analysis"

**Checklist:**
1. ✅ Is diabetes filter mode selected? (Red heart icon should be filled)
2. ✅ Do you have an active profile? (Check for green checkmark in profile list)
3. ✅ Does that profile have diabetes status set? (Should not be "None")
4. ✅ Does filter bar show your profile name? (Should see profile name, not "No Profile")

**Common Issues:**
- ❌ Multiple profiles set to active → Now **fixed!** Only one can be active
- ❌ Wrong profile is active → Check profile name in filter bar, switch if needed
- ❌ Active profile has no diabetes status → Edit profile and set diabetes status
- ❌ Filter mode not selected → Tap the red heart icon in filter bar

### "Which profile is being used?"

**Answer:** The filter bar shows the active profile name!

Look at the filter bar when you have a filter enabled:
- You'll see the profile name displayed
- Example: "John's Profile (5)" for allergen filter
- If you see "No Profile", no profile is currently active

### "Can I use multiple profiles at once?"

**No.** Only one profile can be active at a time. This ensures:
- Clear understanding of which dietary restrictions apply
- Predictable filtering behavior
- Unambiguous recipe safety scores

**Tip:** Create different profiles for different scenarios:
- "John - Dining Out" (only severe allergies)
- "John - Home Cooking" (all sensitivities)
- Switch between them as needed

### "What if I deactivate all profiles?"

**That's okay!** The app still works:
- Recipe browsing continues normally
- Filtering will be disabled
- Filter bar shows "No Profile" messages
- Tap the filter badge to open profile selector and activate one

## Common Workflows

### Workflow 1: Switching Profiles
```
1. Tap filter badge in filter bar (shows profile name)
   → Opens profile list
2. Tap "Set Active" on desired profile
3. Automatically returns to recipe list
4. Filter bar updates to show new profile name
5. Recipes re-filter automatically
```

### Workflow 2: First-Time Setup
```
1. Go to Settings → Allergen Profiles
2. Tap "+" to create new profile
3. Name it (e.g., "John's Profile")
4. Add food sensitivities
5. Set diabetes status (if applicable)
6. Set nutritional goals (if applicable)
7. Toggle "Active Profile" ON
8. Go to Recipes tab
9. Select filter mode (allergen, diabetes, nutrition, or all)
10. See filtered/sorted recipes
```

### Workflow 3: Quick Profile Check
```
1. Look at filter bar at top of recipe list
2. If filter enabled, you'll see active profile name
3. Tap profile badge to change if needed
```

## Profile Data Reference

Each profile can contain:

| Data Type | Used By Filter | Required? |
|-----------|---------------|-----------|
| **Name** | All | Yes |
| **Food Sensitivities** | Allergen/FODMAP, All | No |
| **Diabetes Status** | Diabetes, All | No |
| **Nutritional Goals** | Nutrition, All | No |

**Note:** Filters only work if the active profile has the relevant data:
- Allergen filter needs sensitivities
- Diabetes filter needs diabetes status
- Nutrition filter needs nutritional goals

## Best Practices

### ✅ Do This
- Give profiles descriptive names ("John's Allergies", not "Profile 1")
- Set one profile as active before filtering
- Check filter bar to confirm which profile is active
- Update profile when dietary needs change

### ❌ Avoid This
- Don't try to activate multiple profiles (won't work anymore!)
- Don't filter without an active profile (results will be empty/unsorted)
- Don't forget to set diabetes status if you want diabetes filtering
- Don't assume the app remembers - check which profile is active

## Filter Bar States Reference

### No Filter Mode Selected
```
⭕️ ⭕️ ⭕️ ⭕️
None Allergen Diabetes Nutrition All
```
No profile info shown

### Allergen Filter Active
```
🟠 ⭕️ ⭕️ ⭕️
```
Shows: `🧑 John's Profile (5)` or `⚠️ No Profile`

### Diabetes Filter Active
```
⭕️ 🔴 ⭕️ ⭕️
```
Shows: `❤️ 🩺 John's Profile` or `⚠️ No Profile`

### Nutrition Filter Active
```
⭕️ ⭕️ 🟢 ⭕️
```
Shows: `🍃 ✓ John's Profile` or `⚠️ No Profile`

### All Filters Active
```
⭕️ ⭕️ ⭕️ 🟣
```
Shows all three badges with profile name

## Quick Tips

💡 **Profile name shows in filter bar** - No more guessing which profile is active!

💡 **One profile at a time** - This prevents confusion and ensures predictable results

💡 **Tap filter badge to switch profiles** - Quick access without navigating to settings

💡 **Green checkmark = active** - Easy visual confirmation in profile list

💡 **"Show Only Safe" toggle** - Further refine results to hide risky recipes

💡 **Profile changes apply immediately** - No need to refresh or reload

## Support

If you're still having issues:
1. Check which profile is active (look at filter bar)
2. Verify profile has the needed data (allergens, diabetes status, etc.)
3. Confirm filter mode is selected (icon should be filled/colored)
4. Try deactivating and reactivating the profile
5. Create a test profile with known data to verify filtering works

---

**Last Updated:** 2026-01-06  
**Related:** [PROFILE_ACTIVATION_FIX.md](PROFILE_ACTIVATION_FIX.md)
