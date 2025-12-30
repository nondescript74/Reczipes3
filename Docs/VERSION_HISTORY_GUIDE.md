# Version History System - Maintenance Guide

## Overview

The version history system automatically tracks and displays "What's New" on your launch screen based on the current app version and build number. It maintains a complete changelog that persists across commits.

## Files Involved

1. **VersionHistory.swift** - Core system and version database
2. **LaunchScreenView.swift** - Displays current version's changes
3. **VersionHistoryView.swift** - Full version history view (optional, for Settings)

---

## How to Add Changes for a New Build

### Step 1: Update Your Version/Build Number

In Xcode:
1. Select your project in the Navigator
2. Select your target
3. Go to "General" tab
4. Update **Version** (e.g., "2.0" → "2.1") or **Build** (e.g., "1" → "2")

### Step 2: Add New Entry to VersionHistory.swift

Open `VersionHistory.swift` and add a new entry **AT THE TOP** of the `versionHistory` array:

```swift
private let versionHistory: [VersionHistoryEntry] = [
    // NEW ENTRY - ADD HERE
    VersionHistoryEntry(
        version: "2.1",           // Match your new version
        buildNumber: "2",          // Match your new build
        releaseDate: Date(),       // Today's date
        changes: [
            "✨ Added: Recipe sharing via Messages",
            "🐛 Fixed: Crash when deleting recipes",
            "⚡️ Improved: Search performance",
        ]
    ),
    
    // Previous version below
    VersionHistoryEntry(
        version: "2.0",
        buildNumber: "1",
        ...
    ),
]
```

### Step 3: Commit Your Changes

```bash
git add VersionHistory.swift
git commit -m "Version 2.1 (Build 2): Added recipe sharing, bug fixes"
```

That's it! The system automatically:
- Shows the new changes on the launch screen
- Only shows to users who haven't seen this version yet
- Maintains complete history for reference

---

## Emoji Guide for Changes

Use consistent emoji prefixes to categorize changes:

| Emoji | Category | Example |
|-------|----------|---------|
| ✨ | New Feature | "✨ Added: Recipe sharing" |
| 🎨 | UI/Design | "🎨 Redesigned: Recipe detail view" |
| ⚡️ | Performance | "⚡️ Improved: App launch speed" |
| 🐛 | Bug Fix | "🐛 Fixed: Crash on iOS 17" |
| 🔒 | Security | "🔒 Enhanced: Data encryption" |
| 📚 | Documentation | "📚 Updated: User guide" |
| 🔄 | Sync/Cloud | "🔄 Added: iCloud backup" |
| 🤖 | AI/ML | "🤖 Improved: AI recipe extraction" |
| 🏷️ | Organization | "🏷️ Added: Custom tags" |
| ⚠️ | Health | "⚠️ Added: Allergen warnings" |
| 🔍 | Search | "🔍 Enhanced: Search filters" |
| 📱 | Platform | "📱 Added: iPad optimization" |
| ♿️ | Accessibility | "♿️ Improved: VoiceOver support" |
| 📸 | Media | "📸 Added: Photo library import" |
| 👥 | Social | "👥 Added: Family sharing" |
| 🔗 | Integration | "🔗 Added: Shortcuts support" |

---

## Testing

### Test the Launch Screen

1. Run your app
2. The launch screen should show automatically
3. Verify it displays the correct version and changes

### Force Re-show Launch Screen (Testing)

Add this to a debug menu or settings:

```swift
Button("Reset Version History") {
    VersionHistoryManager.shared.resetVersionTracking()
}
```

This clears the "last shown version" so you can see the launch screen again.

---

## Adding Version History to Settings

To let users view the complete version history:

1. Open your Settings view
2. Add a navigation link:

```swift
NavigationLink(destination: VersionHistoryView()) {
    Label("Version History", systemImage: "clock.arrow.circlepath")
}
```

---

## Best Practices

### 1. Be Concise
- Keep each change to one line
- Use clear, user-friendly language
- Focus on user-visible changes

✅ Good: "✨ Added: Export recipes as PDF"
❌ Too technical: "✨ Implemented PDFKit rendering pipeline"

### 2. Group Related Changes
- Combine minor fixes into one line if appropriate
- Keep major features separate

✅ Good:
```swift
"🐛 Fixed: Multiple UI issues on iPad"
"✨ Added: Recipe sharing"
```

❌ Too granular:
```swift
"🐛 Fixed: Button alignment on iPad"
"🐛 Fixed: Label color on iPad"
"🐛 Fixed: Icon size on iPad"
```

### 3. Prioritize Changes
- Put most important changes first
- Users may only see the first 3-4 items

### 4. Limit to 10 Changes
- If you have more than 10 changes, consolidate
- Too many items overwhelms users

### 5. Update Regularly
- Add entry with every App Store submission
- Can skip internal/TestFlight builds if no user-facing changes

---

## Example Workflow

### Scenario: Fixing a Bug

1. Fix the bug in your code
2. Update build number: `1` → `2`
3. Open `VersionHistory.swift`
4. Add entry:

```swift
VersionHistoryEntry(
    version: "2.0",
    buildNumber: "2",
    releaseDate: Date(),
    changes: [
        "🐛 Fixed: App crash when viewing large recipes",
    ]
),
```

5. Commit and push

### Scenario: Major Feature Update

1. Complete your feature
2. Update version: `2.0` → `2.1`
3. Reset build to `1`
4. Open `VersionHistory.swift`
5. Add entry:

```swift
VersionHistoryEntry(
    version: "2.1",
    buildNumber: "1",
    releaseDate: Date(),
    changes: [
        "✨ Added: Meal planning calendar",
        "✨ Added: Shopping list generator",
        "⚡️ Improved: Recipe loading speed",
        "🐛 Fixed: Multiple stability issues",
    ]
),
```

6. Commit and push

---

## Troubleshooting

### Launch Screen Not Showing

Check:
1. Is `shouldShowLaunchScreen()` returning true in AppStateManager?
2. Is the version/build in VersionHistory.swift correct?
3. Try resetting: `VersionHistoryManager.shared.resetVersionTracking()`

### Wrong Version Showing

1. Verify Info.plist has correct version/build
2. Clean build folder (Cmd+Shift+K)
3. Delete app from device and reinstall

### No Changes Displayed

1. Check that `versionHistory` array has entry matching current version
2. Verify `changes` array is not empty
3. Check Console for any errors

---

## Architecture

```
VersionHistoryManager.shared
    │
    ├─ versionHistory: [VersionHistoryEntry]  // Complete changelog
    │   └─ Each entry has version, build, date, changes[]
    │
    ├─ getCurrentVersionEntry() → VersionHistoryEntry?
    ├─ getWhatsNew() → [String]  // Changes for current version
    ├─ shouldShowWhatsNew() → Bool  // Check if version changed
    └─ markWhatsNewAsShown()  // Save last shown version

LaunchScreenView
    │
    └─ Uses: VersionHistoryManager.shared.getWhatsNew()

VersionHistoryView (Optional)
    │
    └─ Uses: VersionHistoryManager.shared.getAllHistory()
```

---

## Quick Reference

### Add New Version
```swift
// In VersionHistory.swift, add to TOP of array:
VersionHistoryEntry(
    version: "X.Y",
    buildNumber: "Z",
    releaseDate: Date(),
    changes: [
        "✨ Added: Feature",
        "🐛 Fixed: Bug",
    ]
),
```

### Reset for Testing
```swift
VersionHistoryManager.shared.resetVersionTracking()
```

### Get Current Changes
```swift
let changes = VersionHistoryManager.shared.getWhatsNew()
```

---

## Future Enhancements

Possible improvements you could add:

1. **Remote Config**: Fetch version history from server
2. **Analytics**: Track which features users care about
3. **Ratings Prompt**: Ask for rating after showing major features
4. **Deep Links**: Link changes to feature tutorials
5. **Categories**: Filter changes by type (features, fixes, etc.)
6. **Images**: Add screenshots for major features

---

## Questions?

The system is designed to be simple and maintainable. Just remember:

1. Update version/build in Xcode
2. Add entry to VersionHistory.swift
3. Commit

That's it! The launch screen handles the rest automatically.
