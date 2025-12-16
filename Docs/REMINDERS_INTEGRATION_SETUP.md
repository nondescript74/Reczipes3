# Reminders Integration Setup Guide

This guide explains how to configure and use the Reminders integration feature in Reczipes2.

## Overview

The app now supports exporting recipe ingredients directly to the iOS Reminders app. When a user views a recipe in detail, they can tap a button to create a new reminder list with all the ingredients.

## Required Setup

### 1. Add Privacy Permission to Info.plist

You **must** add the following key to your `Info.plist` file:

**Key:** `NSRemindersUsageDescription`  
**Type:** String  
**Value:** "Reczipes needs access to Reminders to export your recipe ingredients as shopping lists."

#### How to add in Xcode:

1. Open your project in Xcode
2. Select the target (Reczipes2)
3. Go to the "Info" tab
4. Click the "+" button to add a new key
5. Type "Privacy - Reminders Usage Description" (it will autocomplete)
6. Enter the description text

Alternatively, you can edit the Info.plist file directly and add:

```xml
<key>NSRemindersUsageDescription</key>
<string>Reczipes needs access to Reminders to export your recipe ingredients as shopping lists.</string>
```

### 2. No Code Changes Required

All the necessary code has been added:
- `RemindersService.swift` - Handles all Reminders interactions
- `RecipeDetailView.swift` - Updated with the export button and UI

## How It Works

### User Experience

1. User opens a recipe detail view
2. User taps the "Add to Reminders" button in the toolbar (list.bullet.clipboard icon)
3. **First time only:** iOS shows a system permission dialog
   - If granted: Ingredients are added to Reminders
   - If denied: User sees a helpful error message explaining how to enable it in Settings
4. A new reminder list is created with the recipe title (prefixed with 🍳)
5. All ingredients are added as individual reminders
6. Section titles (if present) are added as separator reminders (prefixed with ▪️)
7. Success message shows how many ingredients were added

### Permission Handling

The app checks for permission **every time** before attempting to add reminders:
- If permission was previously granted, it proceeds immediately
- If permission was never requested or denied, it requests permission
- If the user denies permission, a graceful error message is shown with instructions

### Reminder List Format

Example for a recipe called "Chocolate Chip Cookies":

**List Name:** 🍳 Chocolate Chip Cookies

**Reminders:**
- ▪️ Dry Ingredients (section title if present)
- 2 cups flour, sifted
- 1 tsp baking soda
- ½ tsp salt
- ▪️ Wet Ingredients
- 1 cup butter, softened (230 g)
- ¾ cup sugar
- etc.

Each ingredient includes:
- Quantity
- Unit
- Name
- Preparation notes (if present)
- Metric conversions (if present)

### Error Handling

The integration handles several error cases gracefully:

1. **Permission Denied:** Shows a message explaining how to enable in Settings
2. **No Reminder Source:** Tells user to configure a reminder account
3. **Network Issues:** Displays a retry message
4. **Unknown Errors:** Shows the error description

All errors are displayed in a user-friendly alert dialog.

## Technical Details

### Files Modified/Created

1. **RemindersService.swift (NEW)**
   - `RemindersService` class with `@MainActor` annotation
   - Permission checking and requesting
   - Creating/finding reminder lists
   - Adding ingredients as reminders
   - Error types with localized descriptions

2. **RecipeDetailView.swift (MODIFIED)**
   - Added toolbar button for export
   - Added state variables for loading and alerts
   - Added `exportIngredientsToReminders()` function
   - Integration with RemindersService

### Dependencies

- **EventKit framework** - Apple's framework for accessing Reminders and Calendar
- No third-party dependencies required

### iOS Version Support

- Requires iOS 14.0+ (for EventKit async/await APIs)
- Works on iPhone and iPad
- Not available on macOS (different Reminders API)

## Testing Checklist

- [ ] Added `NSRemindersUsageDescription` to Info.plist
- [ ] First launch: Permission dialog appears when tapping export button
- [ ] Grant permission: Ingredients are successfully added
- [ ] Deny permission: Error message appears with helpful instructions
- [ ] Open Reminders app: Verify list was created with correct name
- [ ] Check reminders: All ingredients are present with correct formatting
- [ ] Export same recipe twice: Verify two separate lists are created
- [ ] Sections: Verify section titles appear as separators
- [ ] Metric conversions: Verify they're included when present

## Troubleshooting

### Permission Dialog Not Appearing

Make sure the Info.plist key is correctly added. Without it, the app will crash when requesting permission.

### "No Source Available" Error

The user needs at least one reminder account configured. This could be:
- iCloud (Settings > [Your Name] > iCloud > Reminders enabled)
- Local reminders (on-device only)

### Reminders Not Showing in App

Check:
1. Correct list is selected in Reminders app
2. The list name matches the recipe title (with 🍳 prefix)
3. User has the correct account selected if they have multiple

## Future Enhancements

Possible improvements for future versions:

- [ ] Option to append to existing list instead of creating new one
- [ ] Customize list name
- [ ] Add recipe title and instructions as notes
- [ ] Schedule reminders for specific dates
- [ ] Share list with others
- [ ] Export to different lists per recipe section
- [ ] Undo functionality
- [ ] Batch export multiple recipes
