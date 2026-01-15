# Database Migration Recovery Guide

## 🚨 Critical Issue: Recipes Disappearing After Update

### The Problem

After updating to build 78, some users reported that all their recipes disappeared. This document explains what happened and how to fix it.

### Root Cause

The app was using **two different database file locations**:

1. **Old versions**: Used `default.store` (SwiftData's default location)
2. **Current version**: Uses `CloudKitModel.sqlite` (explicit CloudKit location)

When the ModelContainer initializes with a different database URL, SwiftData creates a **new empty database** instead of reading from the old one. The user's recipes are still there in the old file, but the app is reading from the wrong location!

### Why This Happened

```swift
// Current initialization in Reczipes2App.swift
let cloudKitURL = URL.applicationSupportDirectory.appending(path: "CloudKitModel.sqlite")
let cloudKitConfiguration = ModelConfiguration(
    url: cloudKitURL,
    cloudKitDatabase: .private("iCloud.com.headydiscy.reczipes")
)
```

If a previous version didn't specify a custom URL, SwiftData used its default location. The migration from SchemaV2 → SchemaV3 happens successfully, but on the **wrong database file**.

### Other Contributing Factors

1. **CloudKit fallback**: If CloudKit init fails, falls back to local config with different URL
2. **Schema migrations**: V1→V2→V3 migrations work, but might create new files
3. **No data validation**: App doesn't check if current database is suspiciously empty

## ✅ Solutions Implemented

### 1. Database Diagnostics (Build 78+)

Added `checkForMultipleDatabases()` in `Reczipes2App.swift`:

```swift
private func checkForMultipleDatabases() {
    // Scans for all possible database files
    // Logs which files exist, their sizes, and modification dates
    // Warns if multiple databases are detected
}
```

**What it does:**
- Scans Application Support directory for database files
- Reports size and modification date of each file
- Identifies the largest file (likely contains user data)
- Logs warnings if multiple databases exist

**Where to see output:**
- Xcode console when running from Xcode
- Console.app on macOS (search for "DATABASE FILE DIAGNOSTICS")

### 2. Database Recovery Service

Created `DatabaseRecoveryService.swift` with these capabilities:

```swift
// Check if recovery is needed
let migrationInfo = await DatabaseRecoveryService.checkForDatabaseMigration()

// Recover recipes from old database
let result = try await DatabaseRecoveryService.recoverFromOldDatabase(migrationInfo: info)

// Copy old database to current location
try DatabaseRecoveryService.copyOldDatabaseToCurrent(migrationInfo: info)
```

**Features:**
- Automatically detects old database files
- Compares file sizes to identify which has user data
- Creates backup before any operations
- Copies old database to current location
- Preserves WAL and SHM files

### 3. User-Facing Recovery UI

Created `DatabaseRecoveryView.swift`:

- ✅ Automatic detection of recovery opportunities
- ✅ Shows database file details (name, size)
- ✅ One-tap recovery process
- ✅ Clear success/error messaging
- ✅ Guidance to restart app after recovery

**Access:**
Settings → Developer Tools → Database Recovery

## 📋 For Users: How to Recover Your Recipes

### Quick Steps

1. **Open Settings** (gear icon in tab bar)
2. **Scroll to Developer Tools**
3. **Tap "Database Recovery"**
4. **Follow on-screen instructions**
5. **If recipes found**: Tap "Recover My Recipes"
6. **Restart the app** (completely quit and reopen)

### What You'll See

**If recovery is available:**
```
🔶 Recipes Found!

Old Database: default.store (2.4 MB)
Current Database: CloudKitModel.sqlite (48 KB)

[Recover My Recipes]
```

**After recovery:**
```
✅ Recovery Complete!

Successfully recovered:
• 127 recipes
• 5 recipe books
• 1 user profile

⚠️ Please restart the app to see your recovered recipes.
```

**If no recovery needed:**
```
✅ All Good!

No database recovery needed.
Your recipes are in the correct location.
```

## 🔧 For Developers: Technical Details

### Database File Locations

All database files are stored in:
```swift
URL.applicationSupportDirectory
// On iOS: /var/mobile/Containers/Data/Application/<UUID>/Library/Application Support/
```

**Possible file names:**
- `CloudKitModel.sqlite` - Current CloudKit-enabled database
- `default.store` - SwiftData's default location
- `Model.sqlite` - Alternative name used in some versions
- `Reczipes2.sqlite` - Custom name if ever specified

**Associated files:**
Each `.sqlite` file has two companions:
- `.sqlite-wal` - Write-Ahead Log
- `.sqlite-shm` - Shared Memory file

### Detection Logic

```swift
// Current database
let currentDB = appSupport.appendingPathComponent("CloudKitModel.sqlite")
let currentSize = getDatabaseSize(currentDB)
let currentIsEmpty = currentSize < 50_000 // Less than 50KB

// Old databases
if currentIsEmpty && oldDatabaseSize > 100_000 {
    // Recovery needed!
}
```

**Thresholds:**
- **Empty database**: < 50 KB (just schema, no user data)
- **Has data**: > 100 KB (contains recipes/books/etc)

### Recovery Process

1. **Scan** for database files
2. **Compare** sizes to identify data location
3. **Open** old database with ModelContainer
4. **Read** recipe count (validation)
5. **Backup** old database to timestamped file
6. **Copy** old database → current location
7. **Copy** WAL and SHM files
8. **Restart** app to use recovered database

### Code Integration

Add to SettingsView or any other location:

```swift
NavigationLink {
    DatabaseRecoveryView()
} label: {
    Label("Database Recovery", systemImage: "externaldrive.badge.exclamationmark")
}
```

### Migration Plan Compatibility

The recovery process works **with** the existing migration plan:

```swift
enum Reczipes2MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }
}
```

**Flow:**
1. User updates app (has V2 data in `default.store`)
2. App creates new V3 database in `CloudKitModel.sqlite`
3. Old V2 database remains in `default.store`
4. Recovery tool detects this situation
5. Copies `default.store` → `CloudKitModel.sqlite`
6. On next launch, migration V2→V3 happens **on the copied file**
7. User sees their data!

## 🛡️ Prevention Measures

### 1. Consistent Database URL

Always use the same database URL across versions:

```swift
// GOOD: Explicit and consistent
let cloudKitURL = URL.applicationSupportDirectory.appending(path: "CloudKitModel.sqlite")
let config = ModelConfiguration(url: cloudKitURL, cloudKitDatabase: .private(...))

// BAD: Relying on default (URL varies)
let config = ModelConfiguration(cloudKitDatabase: .private(...))
```

### 2. Database Validation

Check if database seems suspiciously empty:

```swift
// After container creation
let recipeCount = try modelContext.fetchCount(FetchDescriptor<Recipe>())
if recipeCount == 0 {
    print("⚠️  Warning: No recipes found. Check for migration issues.")
}
```

### 3. Migration Logging

Enhanced logging in `SchemaMigration.swift`:

```swift
static let migrateV2toV3 = MigrationStage.custom(
    fromVersion: SchemaV2.self,
    toVersion: SchemaV3.self,
    willMigrate: { context in
        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        print("🔄 Migrating \(recipes.count) recipes to V3")
    },
    didMigrate: { context in
        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        print("✅ Migration complete: \(recipes.count) recipes")
    }
)
```

### 4. User Data Backup

Encourage users to use the built-in backup system:
Settings → User Content Backup → Export Recipes

## 🐛 Known Issues & Limitations

### Issue 1: App Restart Required

**Problem:** After recovery, app must be restarted to see recipes

**Why:** ModelContainer is initialized once at app launch. Changing the underlying database file doesn't update the in-memory container.

**Workaround:** 
- Show clear message to restart
- Could implement container recreation (complex)

### Issue 2: CloudKit Sync Conflicts

**Problem:** If user had different data in iCloud vs local, recovery might cause conflicts

**Why:** Copying local database might overwrite CloudKit metadata

**Mitigation:**
- Recovery only runs if current database is empty
- CloudKit sync will eventually reconcile
- User should review data after recovery

### Issue 3: Multiple Old Databases

**Problem:** User might have 2+ old database files

**Current Behavior:** Uses the largest file (most data)

**Future Enhancement:** Let user choose which to recover

## 📊 Testing

### Manual Testing

1. **Simulate the problem:**
   ```swift
   // In ModelConfiguration, temporarily change URL
   let cloudKitURL = URL.applicationSupportDirectory.appending(path: "TestNewDB.sqlite")
   ```

2. **Add test recipes** to old database

3. **Change URL back** to trigger migration

4. **Run recovery tool** to restore

### Unit Testing

Create `DatabaseRecoveryTests.swift`:

```swift
@Test("Detect migration needed")
func detectMigration() async throws {
    // Create mock old database with data
    // Create mock new empty database
    // Verify checkForDatabaseMigration() returns migration info
}

@Test("Recovery copies database")
func recoverDatabase() async throws {
    // Create populated old database
    // Run recovery
    // Verify new database has data
    // Verify backup was created
}
```

## 📚 Related Documentation

- `SCHEMA_MIGRATION_GUIDE.md` - How migrations work
- `CLOUDKIT_SETUP_GUIDE.md` - CloudKit configuration
- `SchemaMigration.swift` - Migration plan implementation

## 🔮 Future Improvements

1. **Automatic recovery on app launch**
   - Detect situation silently
   - Recover without user interaction
   - Show subtle notification

2. **Better container management**
   - Single source of truth for database URL
   - Validation before container creation
   - Health checks after initialization

3. **iCloud sync awareness**
   - Detect if iCloud has newer data
   - Offer to pull from iCloud vs local recovery
   - Merge strategies for conflicts

4. **Analytics**
   - Track how many users hit this issue
   - Monitor recovery success rate
   - Identify patterns

## 💡 Key Takeaways

1. **Database URL matters**: Always be explicit, never rely on defaults
2. **Validate after migrations**: Check that data actually migrated
3. **Plan for failure**: Have recovery tools ready
4. **User communication**: Clear messaging when things go wrong
5. **Test migrations**: Test with real user data, not empty databases

---

**Last Updated:** January 15, 2026  
**Build:** 78+  
**Author:** AI Assistant
