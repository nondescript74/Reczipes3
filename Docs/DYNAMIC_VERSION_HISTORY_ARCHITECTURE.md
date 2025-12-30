# Dynamic Version History Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         VERSION HISTORY SYSTEM                          │
└─────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════
                            COMPONENT OVERVIEW
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│                         1. VersionHistory.swift                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ VersionHistoryManager (Singleton)                                │   │
│  │                                                                   │   │
│  │  DATA STORE:                                                      │   │
│  │  ┌──────────────────────────────────────────────────────────┐   │   │
│  │  │ versionHistory: [VersionHistoryEntry]                     │   │   │
│  │  │                                                            │   │   │
│  │  │  Entry 1: v2.1 (Build 5) - Latest                         │   │   │
│  │  │    • "✨ Added: Feature X"                                │   │   │
│  │  │    • "🐛 Fixed: Bug Y"                                    │   │   │
│  │  │                                                            │   │   │
│  │  │  Entry 2: v2.0 (Build 1) - Previous                       │   │   │
│  │  │    • "🎉 Initial Release"                                 │   │   │
│  │  │    • "📚 Export & Import"                                 │   │   │
│  │  └──────────────────────────────────────────────────────────┘   │   │
│  │                                                                   │   │
│  │  API METHODS:                                                     │   │
│  │  • getCurrentVersionEntry() → VersionHistoryEntry?               │   │
│  │  • getWhatsNew() → [String]                                      │   │
│  │  • shouldShowWhatsNew() → Bool                                   │   │
│  │  • markWhatsNewAsShown()                                         │   │
│  │  • getAllHistory() → [VersionHistoryEntry]                       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
┌──────────────────────┐  ┌──────────────────┐  ┌─────────────────────┐
│ LaunchScreenView     │  │ VersionHistory   │  │ Settings/Debug      │
│                      │  │ View             │  │                     │
│ Shows:               │  │                  │  │ • Reset tracking    │
│ • Current changes    │  │ Shows:           │  │ • View full history │
│ • Version/build      │  │ • All versions   │  │ • Export changelog  │
│ • Auto-dismisses     │  │ • Expandable     │  │                     │
└──────────────────────┘  └──────────────────┘  └─────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                               DATA FLOW
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│                           1. APP LAUNCH                                  │
└─────────────────────────────────────────────────────────────────────────┘

    ┌────────────────┐
    │ Reczipes2App   │
    │   .onAppear    │
    └────────┬───────┘
             │
             ▼
    ┌────────────────────────────┐
    │ AppStateManager            │
    │ .shouldShowLaunchScreen()  │
    └────────┬───────────────────┘
             │
             ▼
    ┌────────────────────────────┐
    │ VersionHistoryManager      │
    │ .shouldShowWhatsNew()      │
    │                            │
    │ Checks:                    │
    │ Current: "2.0 (1)"         │
    │ Last Shown: "1.9 (5)"      │
    │ → TRUE (new version!)      │
    └────────┬───────────────────┘
             │
             ▼
    ┌────────────────────────────┐
    │ Show LaunchScreenView      │
    └────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                      2. DISPLAY "WHAT'S NEW"                             │
└─────────────────────────────────────────────────────────────────────────┘

    ┌────────────────────────────┐
    │ LaunchScreenView           │
    │                            │
    │ latestFeatures = ...       │
    └────────┬───────────────────┘
             │
             ▼
    ┌────────────────────────────────────────┐
    │ VersionHistoryManager.shared           │
    │ .getWhatsNew()                         │
    │                                        │
    │ 1. Get currentVersion from Bundle      │
    │    → "2.0"                             │
    │                                        │
    │ 2. Get currentBuildNumber from Bundle  │
    │    → "1"                               │
    │                                        │
    │ 3. Find matching entry in database:    │
    │    versionHistory.first {              │
    │      $0.version == "2.0" &&            │
    │      $0.buildNumber == "1"             │
    │    }                                   │
    │                                        │
    │ 4. Return entry.changes[]              │
    └────────┬───────────────────────────────┘
             │
             ▼
    ┌────────────────────────────────────────┐
    │ Display on Launch Screen:              │
    │                                        │
    │ ┌────────────────────────────────┐   │
    │ │ 📚 Export & Import Books       │   │
    │ │ 🔄 Share Collections           │   │
    │ │ 🤖 AI Recipe Extraction        │   │
    │ │ ☁️ iCloud Sync Enabled         │   │
    │ │ ...                            │   │
    │ └────────────────────────────────┘   │
    └────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                       3. MARK AS SHOWN                                   │
└─────────────────────────────────────────────────────────────────────────┘

    ┌────────────────────────────┐
    │ LaunchScreenView           │
    │ .onComplete                │
    └────────┬───────────────────┘
             │
             ▼
    ┌─────────────────────────────────────────┐
    │ VersionHistoryManager.shared            │
    │ .markWhatsNewAsShown()                  │
    │                                         │
    │ UserDefaults.standard.set(              │
    │   "2.0 (1)",                            │
    │   forKey: "lastShownVersion"            │
    │ )                                       │
    └─────────────────────────────────────────┘
                     │
                     ▼
    ┌─────────────────────────────────────────┐
    │ Next Launch:                            │
    │                                         │
    │ Current: "2.0 (1)"                      │
    │ Last Shown: "2.0 (1)"                   │
    │ → FALSE (already seen)                  │
    │ → Don't show launch screen              │
    └─────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                         DEVELOPER WORKFLOW
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│                    ADDING A NEW VERSION                                  │
└─────────────────────────────────────────────────────────────────────────┘

STEP 1: Update Xcode Project
┌──────────────────────────────────────┐
│ Project Settings → General           │
│                                      │
│ Version: 2.0 → 2.1                   │
│ Build:   1   → 1                     │
└──────────────────────────────────────┘
              │
              ▼
STEP 2: Add Entry to VersionHistory.swift
┌──────────────────────────────────────────────────────────────┐
│ private let versionHistory = [                               │
│                                                              │
│   // ADD NEW ENTRY HERE (at top):                           │
│   VersionHistoryEntry(                                       │
│     version: "2.1",            ◀── Match Xcode              │
│     buildNumber: "1",           ◀── Match Xcode             │
│     releaseDate: Date(),                                     │
│     changes: [                                               │
│       "✨ Added: Recipe sharing",     ◀── Your changes      │
│       "🐛 Fixed: Crash on iOS 17",    ◀── Your fixes        │
│       "⚡️ Improved: Search speed",    ◀── Your improvements│
│     ]                                                        │
│   ),                                                         │
│                                                              │
│   // Previous versions below...                             │
│   VersionHistoryEntry(                                       │
│     version: "2.0",                                          │
│     ...                                                      │
│   ),                                                         │
│ ]                                                            │
└──────────────────────────────────────────────────────────────┘
              │
              ▼
STEP 3: Commit Changes
┌──────────────────────────────────────┐
│ git add VersionHistory.swift         │
│ git commit -m "Version 2.1:          │
│   Added recipe sharing, bug fixes"   │
│ git push                             │
└──────────────────────────────────────┘
              │
              ▼
STEP 4: Build & Test
┌──────────────────────────────────────┐
│ • Build app in Xcode                 │
│ • Launch app on device               │
│ • Launch screen shows automatically  │
│ • Verify changes display correctly   │
└──────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                         VERSION TRACKING
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│                        UserDefaults Storage                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  Key: "com.reczipes.lastShownVersion"                                    │
│  Value: "2.0 (1)"                                                        │
│                                                                           │
│  Updated:                                                                │
│  • After launch screen dismisses                                         │
│  • When user sees "What's New"                                           │
│                                                                           │
│  Checked:                                                                │
│  • Every app launch                                                      │
│  • To determine if launch screen should show                             │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                           VERSION COMPARISON
═══════════════════════════════════════════════════════════════════════════

Scenario 1: First Launch
┌────────────────────────────────────┐
│ Last Shown: nil                    │
│ Current:    "2.0 (1)"              │
│ Result:     SHOW ✅                │
└────────────────────────────────────┘

Scenario 2: Same Version
┌────────────────────────────────────┐
│ Last Shown: "2.0 (1)"              │
│ Current:    "2.0 (1)"              │
│ Result:     HIDE ❌                │
└────────────────────────────────────┘

Scenario 3: New Build
┌────────────────────────────────────┐
│ Last Shown: "2.0 (1)"              │
│ Current:    "2.0 (2)"              │
│ Result:     SHOW ✅                │
└────────────────────────────────────┘

Scenario 4: New Version
┌────────────────────────────────────┐
│ Last Shown: "2.0 (1)"              │
│ Current:    "2.1 (1)"              │
│ Result:     SHOW ✅                │
└────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                         EMOJI CATEGORIES
═══════════════════════════════════════════════════════════════════════════

┌─────────────┬──────────────────────────────────────────────────────────┐
│   EMOJI     │                      USAGE                               │
├─────────────┼──────────────────────────────────────────────────────────┤
│     ✨      │  New Feature - Major new functionality                   │
│     🎨      │  UI/Design - Visual improvements                         │
│     ⚡️     │  Performance - Speed improvements                        │
│     🐛      │  Bug Fix - Fixed bugs or issues                          │
│     🔒      │  Security - Security improvements                        │
│     📚      │  Books/Library - Collection features                     │
│     🔄      │  Sync/Cloud - iCloud, backup features                    │
│     🤖      │  AI/ML - Artificial intelligence features                │
│     🏷️      │  Organization - Tags, categories                         │
│     ⚠️      │  Health - Allergens, health warnings                     │
│     💉      │  Diabetes - Diabetes-related features                    │
│     🔍      │  Search - Search and filtering                           │
│     📸      │  Photos - Image and photo features                       │
│     👥      │  Social - Sharing and social features                    │
│     🔗      │  Integration - Third-party integrations                  │
└─────────────┴──────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                         TESTING & DEBUGGING
═══════════════════════════════════════════════════════════════════════════

Reset Version Tracking (Force Re-show Launch Screen)
┌───────────────────────────────────────────────────────────┐
│ VersionHistoryManager.shared.resetVersionTracking()       │
│                                                           │
│ • Clears UserDefaults                                     │
│ • Forces launch screen to show again                      │
│ • Useful for testing                                      │
└───────────────────────────────────────────────────────────┘

Check Current Version
┌───────────────────────────────────────────────────────────┐
│ print(VersionHistoryManager.shared.currentVersionString)  │
│ // Output: "2.0 (1)"                                      │
└───────────────────────────────────────────────────────────┘

Get Changes for Current Version
┌───────────────────────────────────────────────────────────┐
│ let changes = VersionHistoryManager.shared.getWhatsNew()  │
│ print(changes)                                            │
│ // ["📚 Export & Import", "🔄 Share Collections", ...]   │
└───────────────────────────────────────────────────────────┘

Check If Should Show
┌───────────────────────────────────────────────────────────┐
│ if VersionHistoryManager.shared.shouldShowWhatsNew() {    │
│   print("Will show launch screen")                        │
│ }                                                         │
└───────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                           FILE STRUCTURE
═══════════════════════════════════════════════════════════════════════════

Reczipes2/
│
├── Core/
│   └── VersionHistory.swift               ◀── Version database & manager
│
├── Views/
│   ├── LaunchScreenView.swift             ◀── Your beautiful launch screen
│   └── VersionHistoryView.swift           ◀── Optional full history view
│
├── Templates/
│   └── VersionEntryTemplate.swift         ◀── Copy-paste template
│
└── Documentation/
    ├── VERSION_HISTORY_GUIDE.md          ◀── Detailed guide
    └── DYNAMIC_VERSION_HISTORY_SUMMARY.md ◀── Quick reference


═══════════════════════════════════════════════════════════════════════════
                         QUICK REFERENCE
═══════════════════════════════════════════════════════════════════════════

✅ Add New Version
   1. Update version/build in Xcode
   2. Add entry to VersionHistory.swift
   3. Commit

✅ Test Launch Screen
   VersionHistoryManager.shared.resetVersionTracking()

✅ View Full History
   Add VersionHistoryView to Settings

✅ Export Changelog
   VersionHistoryManager.shared.getFormattedChangelog()

✅ Check Version
   VersionHistoryManager.shared.currentVersionString
```
