# URGENT: Missing Recipes Troubleshooting Guide

## For Your User Who Lost Recipes

### Immediate Actions

#### Step 1: Use the Investigation Tool

1. **Open Settings** (gear icon)
2. **Scroll to "Developer Tools"**
3. **Tap "Database Investigation"** (marked with ⭐)
4. **Wait for the scan to complete**
5. **Take a screenshot** of the results
6. **Send me the screenshot**

This will show us:
- All database files on the device
- How many recipes are in each file
- Which file the app is currently reading from
- File sizes and modification dates

#### Step 2: Check What the Investigation Shows

The investigation will tell us one of these scenarios:

##### Scenario A: Recipes Found in Another Database
```
Current Database: CloudKitModel.sqlite (0 recipes)
Largest Database: default.store (127 recipes) ⚠️
```

**→ If you see this:** The recipes ARE there, just in the wrong file!
- Use "Database Recovery" to restore them
- The recovery will copy the old file to the new location

##### Scenario B: All Databases Are Empty
```
Current Database: CloudKitModel.sqlite (0 recipes)
All other databases: 0 recipes
```

**→ If you see this:** Something more serious happened
- Check if iCloud sync is enabled
- Check if recipes might be in iCloud
- Proceed to Step 3

##### Scenario C: Current Database Has Recipes
```
Current Database: CloudKitModel.sqlite (127 recipes)
```

**→ If you see this:** The database is fine, different issue
- The problem might be in the UI/filtering
- Check if any filters are applied
- Try restarting the app

### Step 3: Check iCloud Status

The recipes might still be in iCloud if sync was enabled:

1. **Settings → Data & Sync → Quick Sync Check**
2. **Look for:**
   - "iCloud Account: Signed In" ✅
   - "CloudKit Status: Available" ✅
   - Record count in cloud

3. **If iCloud shows recipes:**
   - The data is safe in iCloud
   - We need to trigger a sync to download them
   - Go to **Settings → iCloud Sync Settings**
   - Look for sync status and errors

### Step 4: Export the Investigation Report

In the Database Investigation view:

1. **Scroll to bottom**
2. **Tap "Export Investigation Report"**
3. **Send the report to me**

This gives me the technical details I need to help you.

### Step 5: Check Device Storage

Low storage can cause database corruption:

1. **Settings app (iOS) → General → iPhone Storage**
2. **Check available space**
3. **If less than 1 GB free:** Free up space and restart app

---

## What Might Have Happened

### Possibility 1: Database File Location Changed
- Previous version used `default.store`
- Current version uses `CloudKitModel.sqlite`
- Recipes still in old file, app reading from new empty file
- **Solution:** Database Recovery will fix this

### Possibility 2: Migration Failed Silently
- Schema migration V2 → V3 encountered an error
- App created new database instead of migrating
- Old database might still have data
- **Solution:** Investigation will reveal this

### Possibility 3: iCloud Sync Conflict
- Local and iCloud databases diverged
- Update chose wrong version
- Data might be in iCloud
- **Solution:** Force sync from iCloud

### Possibility 4: App Reinstall/Delete
- If app was deleted and reinstalled
- Local database is gone
- Need to restore from:
  - iCloud (if sync was enabled)
  - Backup file (if user made one)
  - Image restoration (from SwiftData external storage)

### Possibility 5: iOS Update Interference
- Recent iOS update
- App containers might have been reorganized
- Database file moved to different location
- **Solution:** Deep filesystem search (I can build this)

---

## For Me (Developer): Next Steps Based on Results

### If Investigation Shows Recipes in Another File

**Quick Fix:**
```swift
// In DatabaseRecoveryService, add manual file specification
static func recoverFromSpecificFile(fileName: String) async throws {
    let url = URL.applicationSupportDirectory.appendingPathComponent(fileName)
    // Copy this file to CloudKitModel.sqlite
}
```

### If All Local Databases Are Empty

**Check iCloud:**
```swift
// Add to investigation:
static func checkCloudKitForRecipes() async throws -> Int {
    // Query CloudKit directly
    // Return count of recipes in cloud
}
```

**Check External Storage:**
```swift
// Recipes' imageData might still exist
// Can reconstruct from image files if SwiftData external storage still has them
```

### If Database File Exists But Can't Be Read

**Check for corruption:**
```swift
// Try to open with sqlite3 directly
// Check integrity
// Attempt recovery
```

---

## Advanced Recovery Options (If Needed)

### Option 1: Manual Database Copy

Have user connect device to Mac:

1. **Open Finder → iPhone → Files**
2. **Navigate to Reczipes2 → Application Support**
3. **Copy ALL `.sqlite` and `.store` files to Mac**
4. **Send to me for analysis**

I can then:
- Open databases with DB Browser for SQLite
- Extract recipe data manually
- Create a recovery file

### Option 2: iCloud Dashboard Check

If user has iCloud sync enabled:

1. **Go to iCloud.com**
2. Unfortunately, CloudKit data isn't visible in consumer iCloud
3. But I can add a tool to **export directly from CloudKit**

### Option 3: Image-Based Recovery

If recipes had images:

1. **External storage might still have image data**
2. **Image data contains embedded metadata**
3. I can build a tool to:
   - Scan external storage directory
   - Extract image data
   - Reconstruct recipes from images using Claude
   - (Expensive but possible as last resort)

### Option 4: App Store Purchase/Download History

If this is a TestFlight build:
- User might have an older build installed
- Could download old version temporarily
- Export recipes
- Upgrade and import

---

## Prevention for Future

### Immediate Changes to Make

**1. Add Pre-Migration Validation:**
```swift
// Before creating ModelContainer
static func validateDatabaseBeforeMigration() {
    let existingDB = findExistingDatabase()
    if existingDB.recipeCount > 0 {
        UserDefaults.standard.set(existingDB.recipeCount, forKey: "expectedRecipeCount")
    }
}

// After migration
static func validateDatabaseAfterMigration() {
    let expectedCount = UserDefaults.standard.integer(forKey: "expectedRecipeCount")
    if currentRecipeCount == 0 && expectedCount > 0 {
        // ALERT USER IMMEDIATELY
        // Don't let them use the app until we fix it
    }
}
```

**2. Automatic Backup Before Updates:**
```swift
// On app launch, detect version change
if currentVersion != lastVersion {
    // Auto-create backup before proceeding
    await BackupService.createAutomaticBackup()
}
```

**3. Database Consistency Check:**
```swift
// Run on every app launch
static func healthCheck() async {
    let issues = await findDatabaseIssues()
    if !issues.isEmpty {
        // Show alert with recovery options
    }
}
```

---

## Questions for User

Please ask them:

1. **Was iCloud sync enabled before the update?**
   - Check Settings → Data & Sync → Quick Sync Check
   - Look for current status

2. **Did they delete and reinstall the app?**
   - Or just update through App Store/TestFlight?

3. **Do they remember approximately how many recipes they had?**
   - This helps validate if we find them

4. **Do they have an old device that might have a backup?**
   - iPad, old iPhone, etc.
   - Could export from there

5. **Did they ever use the Export feature?**
   - Settings → User Content Backup → Export Recipes
   - Might have backup files in Files app

---

## Technical Details for Investigation

### Where to Look for Database Files

**Primary location:**
```
/var/mobile/Containers/Data/Application/<UUID>/Library/Application Support/
```

**Possible file names:**
- `CloudKitModel.sqlite`
- `CloudKitModel.sqlite-wal`
- `CloudKitModel.sqlite-shm`
- `default.store`
- `default.store-wal`
- `default.store-shm`
- `Model.sqlite`
- `Reczipes2.sqlite`

**External storage (for imageData):**
```
/var/mobile/Containers/Data/Application/<UUID>/Library/Application Support/.default.store_SUPPORT/_EXTERNAL_DATA/
```

### Console Logging

Have user:
1. Connect iPhone to Mac
2. Open **Console.app**
3. Select their iPhone
4. Filter for "Reczipes" or "DATABASE"
5. Launch the app
6. Send me the console log

Look for:
- ModelContainer initialization logs
- Migration logs
- Recipe count after fetch
- Any errors

---

## Worst Case Scenario Plan

If we truly cannot recover the recipes:

1. **Apologize profusely** ❤️
2. **Offer to help them rebuild:**
   - Batch extraction from saved links (if they have them)
   - Priority support for re-entering recipes
3. **Implement better safeguards** (see Prevention section)
4. **Consider compensation** if this is a paid app
5. **Learn and document** to help prevent this for others

---

**Next Step: Please have your user run the Database Investigation tool and send you the results or screenshots.**

That will tell us exactly what's happening and guide our next move.
