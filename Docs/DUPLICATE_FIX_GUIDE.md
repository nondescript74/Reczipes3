# Duplicate Recipe Fix - Implementation Guide

## ✅ What Was Fixed

### 1. **Renamed CloudKitDuplicateMonitor**
- Fixed redeclaration error by renaming `CloudKitSyncMonitor 2.swift` → `CloudKitDuplicateMonitor.swift`
- This class monitors CloudKit sync resets and detects duplicates

### 2. **Enhanced Recipe Model**
Added to `Recipe.swift`:
- `@Attribute(.unique) var id: UUID` - Enforces unique IDs in SwiftData
- `var dateCreated: Date?` - CloudKit creation timestamp (for keeping oldest copy)
- `var contentFingerprint: String` - Computed property for duplicate detection based on title + ingredients + instructions hash

### 3. **Created New Tools**
- `DuplicateRecipeDetectorView.swift` - Interactive UI to find and delete duplicates
- `OrphanedDataCleanupUtility.swift` - Utility functions for cleanup
- `DatabaseMaintenanceView.swift` - Comprehensive maintenance dashboard

## 📋 Implementation Steps

### Step 1: Update Your Schema Version (REQUIRED)

Since we added `dateCreated` to the Recipe model, you need to add a new schema version.

Add to `SchemaMigration.swift`:

```swift
// MARK: - Schema Version 5 (with Duplicate Detection)

enum SchemaV5: VersionedSchema {
    static nonisolated(unsafe) var versionIdentifier = Schema.Version(5, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            Recipe.self,
            RecipeImageAssignment.self,
            UserAllergenProfile.self,
            CachedDiabeticAnalysis.self,
            SavedLink.self,
            RecipeBook.self,
            CookingSession.self,
        ]
    }
}
```

Then update your `MigrationPlan`:

```swift
enum RecipeSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self, SchemaV5.self]
    }
    
    static var stages: [MigrationStage] {
        [
            // Existing migrations...
            migrateV4toV5, // Add this
        ]
    }
    
    static let migrateV4toV5 = MigrationStage.lightweight(
        fromVersion: SchemaV4.self,
        toVersion: SchemaV5.self
    )
}
```

### Step 2: Initialize CloudKitDuplicateMonitor

In your App struct (or wherever you initialize your ModelContainer):

```swift
import SwiftUI
import SwiftData

@main
struct Reczipes2App: App {
    @StateObject private var duplicateMonitor = CloudKitDuplicateMonitor.shared
    
    let modelContainer: ModelContainer
    
    init() {
        // Your existing ModelContainer setup...
        self.modelContainer = // ... your container
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .monitorDuplicates()  // Add this modifier
                .onAppear {
                    // Configure the monitor with context
                    duplicateMonitor.configure(with: modelContainer.mainContext)
                }
        }
    }
}
```

### Step 3: Add to Settings Menu

Add a navigation link to `DatabaseMaintenanceView` in your Settings:

```swift
// In your SettingsView or similar
Section("Database") {
    NavigationLink("Database Maintenance") {
        DatabaseMaintenanceView()
    }
    
    NavigationLink("Duplicate Detector") {
        DuplicateRecipeDetectorView()
    }
}
```

## 🚀 How to Use

### Immediate Actions (On iPad):

1. **Run Duplicate Detection**
   - Open Settings → Database Maintenance
   - Tap "Analyze Database"
   - Review the report

2. **Clean Up Duplicates**
   - Open Settings → Duplicate Detector
   - It will auto-scan on appear
   - Review duplicate groups
   - Tap "Delete All Duplicates" to clean up automatically
   - Or tap individual groups to review and delete manually

3. **Clean Up Orphaned Assignments**
   - Open Settings → Database Maintenance
   - Tap "Clean Up Orphaned Assignments"
   - This removes the 84+ orphaned image assignments

### Expected Results:

**Before:**
- 292 recipes (wrong)
- 208 image assignments
- ~35 duplicate recipes (292 - 257 = 35)

**After:**
- ~257 recipes (correct)
- ~208 image assignments (or fewer if orphaned)
- 0 duplicates

## 🔄 How It Works

### Automatic Detection:
When CloudKit sync token expires and resets:
1. `CloudKitDuplicateMonitor` detects the reset
2. Waits 5 seconds for sync to complete
3. Automatically scans for duplicates
4. Shows an alert if duplicates found
5. User can tap "View & Clean Up" to go to the detector

### Manual Detection:
You can also manually run the detector anytime from Settings.

### Duplicate Resolution:
When duplicates are found:
- Groups recipes by `contentFingerprint` (title + ingredients + instructions hash)
- Sorts by `dateCreated` (or `dateAdded` if not available)
- **Keeps the oldest copy** (first created)
- **Deletes newer copies** (duplicates from sync)

## 📊 Monitoring

The system logs everything to console:

```
⚠️ CloudKit sync will reset - change token expired
✅ CloudKit sync reset complete
🔍 Checking for duplicates after sync...
📊 Total recipes: 292
⚠️ Found 5 duplicate groups containing 35 extra recipes
💡 Open Settings → Duplicate Detector to clean up
```

## ⚠️ Important Notes

1. **Schema Migration**: The app will automatically migrate existing recipes to add `dateCreated` field (will default to `dateAdded` for existing recipes)

2. **Unique ID Constraint**: The `@Attribute(.unique)` on Recipe.id helps prevent future duplicates at the SwiftData level

3. **Backup**: Before running full cleanup, make sure you have an iCloud backup or device backup

4. **Testing**: Test on one device first, then let CloudKit sync propagate the changes

## 🐛 Troubleshooting

### "Duplicates keep coming back"
- Make sure CloudKit sync has finished before running cleanup
- Check that the `@Attribute(.unique)` constraint is in place
- Verify the monitor is properly configured with `modelContext`

### "Wrong count after cleanup"
- Run "Clean Up Orphaned Assignments" 
- Force quit and relaunch the app
- Check CloudKit sync status

### "Can't see Database Maintenance"
- Make sure you've added the navigation link to Settings
- Verify all new files are included in your Xcode target

## 📱 User Instructions (for your iPad device)

1. Open Settings
2. Tap "Database Maintenance"
3. Tap "Analyze Database"
4. Review the report
5. Tap "Duplicate Detector"
6. Review the duplicates found
7. Tap "Delete All Duplicates"
8. Confirm deletion
9. Go back and tap "Clean Up Orphaned Assignments"
10. Restart app to see correct count (257 recipes)
