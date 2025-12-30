# Launch Screen Updates - December 30, 2024

## Changes Made

### 1. Launch Screen Now Shows Every Launch ✅

**Modified Files:**
- `AppStateManager.swift`
- `Reczipes2App.swift`
- `VersionHistory.swift`

**Changes:**
1. **AppStateManager.swift**
   - Updated `shouldShowLaunchScreen()` to return `true` always
   - This means the launch screen shows on every app launch

2. **Reczipes2App.swift**
   - Launch screen only shows after onboarding is complete
   - Checks for license acceptance and API key configuration
   - Shows launch screen with proper animation and z-index

3. **VersionHistory.swift**
   - Added `isNewVersion()` method to check if version changed
   - Added `shouldShowLaunchScreen()` that returns `true` by default
   - Kept existing `markWhatsNewAsShown()` functionality
   - Deprecated old `shouldShowWhatsNew()` in favor of clearer naming

### 2. Version History Added to Settings ✅

**Modified Files:**
- `SettingsView.swift`

**Changes:**
Added "About" section with:
- **Version History** link (shows full `VersionHistoryView`)
- **Current Version** display
- **Reset Version Tracking** button (DEBUG builds only)
- **Powered by Claude AI** link

The new "About" section looks like this:

```
About
├── Version History → VersionHistoryView
│   └── Displays: "2.0 (1)"
├── Current Version: 2.0 (1)
├── [DEBUG] Reset Version Tracking
└── Powered by Claude AI →
```

## How It Works Now

### Launch Screen Flow

```
App Launch
    ↓
License accepted? → NO → Show License Agreement
    ↓ YES
API Key set? → NO → Show API Key Setup
    ↓ YES
Show Launch Screen (2.2 seconds)
    ↓
Display "What's New" from VersionHistory
    ↓
Auto-dismiss
    ↓
Main App
```

### Version History in Settings

Users can now:
1. Tap Settings tab
2. Scroll to "About" section
3. Tap "Version History"
4. View all versions with expandable change lists
5. Share the changelog via share button

## Configuration Options

### To Show Launch Screen Only on Version Changes

In `VersionHistory.swift`, change line 155:

```swift
// Current (shows every time):
func shouldShowLaunchScreen() -> Bool {
    return true
}

// To show only on updates:
func shouldShowLaunchScreen() -> Bool {
    return isNewVersion()
}
```

### To Adjust Launch Screen Duration

In `LaunchScreenView.swift`, line 286:

```swift
// Current: 2.2 seconds
DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {

// To change: Adjust the number
DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {  // 3 seconds
```

## Testing

### Test Launch Screen

1. Run app
2. Complete onboarding (if needed)
3. Launch screen should appear automatically
4. Shows for 2.2 seconds with "What's New"
5. Auto-dismisses

### Test Version History

1. Open app
2. Go to Settings tab
3. Scroll to "About" section
4. Tap "Version History"
5. See version 2.0 (1) with all changes
6. Tap entry to expand/collapse
7. Use share button to export changelog

### Reset for Testing (DEBUG Only)

1. Go to Settings → About
2. Tap "Reset Version Tracking"
3. Close and relaunch app
4. Launch screen appears again

## Current Version Display

**Version:** 2.0
**Build:** 1

**What's New:**
- 📚 Export & Import Recipe Books
- 🔄 Share Collections with Friends
- 🤖 AI-Powered Recipe Extraction with Claude
- ☁️ iCloud Sync Enabled
- 🏷️ Recipe Image Assignment System
- ⚠️ Allergen Profile Tracking
- 💉 Diabetes Analysis for Recipes
- 🔍 Advanced Recipe Search & Filtering
- 📝 Recipe Books Organization
- 🔗 Save & Extract from URLs
- 📊 FODMAP Substitution Guide
- 🎨 Liquid Glass Design Elements
- 📱 State Preservation & Task Restoration

## Files Modified

```
✏️ AppStateManager.swift          - Changed shouldShowLaunchScreen() logic
✏️ Reczipes2App.swift              - Updated launch screen conditions
✏️ VersionHistory.swift            - Added isNewVersion(), shouldShowLaunchScreen()
✏️ SettingsView.swift              - Added Version History section
```

## Files Created (Previously)

```
✨ VersionHistory.swift             - Version management system
✨ VersionHistoryView.swift         - Full history display
✨ LaunchScreenView.swift           - Launch screen (updated to use dynamic data)
📄 VERSION_HISTORY_GUIDE.md        - Maintenance documentation
📄 DYNAMIC_VERSION_HISTORY_SUMMARY.md
📄 DYNAMIC_VERSION_HISTORY_ARCHITECTURE.md
```

## Next Steps

### To Add a New Version

1. Update version/build in Xcode
2. Open `VersionHistory.swift`
3. Add new entry at top of `versionHistory` array:

```swift
VersionHistoryEntry(
    version: "2.1",
    buildNumber: "1",
    releaseDate: Date(),
    changes: [
        "✨ Added: Your new feature",
        "🐛 Fixed: Your bug fix"
    ]
),
```

4. Commit and build
5. Launch screen automatically shows new changes

## Summary

✅ Launch screen now shows **every launch**
✅ Version History accessible from **Settings → About**
✅ Current version: **2.0 (1)**
✅ 13 features listed in "What's New"
✅ DEBUG reset button for testing
✅ Full changelog view with share functionality

Everything is working and ready to use!
