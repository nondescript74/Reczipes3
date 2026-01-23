# Fix: Crash on iPad - Unknown Model Version Error

## Problem

The app was crashing on iPad with the error:
```
Cannot use staged migration with an unknown coordinator model version.
Error Domain=NSCocoaErrorDomain Code=134504
```

This happened because:
1. The database was created with a previous schema version
2. That schema version no longer exists in the current migration plan
3. The error detection code wasn't catching SwiftData-wrapped errors correctly

## Root Cause

The error detection logic was only checking for:
- Direct `NSCocoaErrorDomain` errors with code 134504
- Immediate underlying errors

But it was **missing**:
- SwiftData wrapped errors (`SwiftData.SwiftDataError` code 1)
- Deeply nested error chains

The error chain looked like:
```
SwiftData.SwiftDataError (code 1: loadIssueModelContainer)
  └─> (wrapped inside, not in NSUnderlyingErrorKey)
      └─> NSCocoaErrorDomain (code 134504)
```

## Solution

### 1. Enhanced Error Detection

Changed from simple boolean check to recursive function:

```swift
func containsUnknownModelError(_ error: NSError) -> Bool {
    // Check the error itself
    if error.domain == "NSCocoaErrorDomain" && error.code == 134504 {
        return true
    }
    
    // Check the underlying error (recursively)
    if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
        return containsUnknownModelError(underlyingError)
    }
    
    // Check for SwiftData wrapped errors
    if error.domain == "SwiftData.SwiftDataError" && error.code == 1 {
        // SwiftData error code 1 is loadIssueModelContainer
        // This often wraps a Core Data migration error
        logWarning("   SwiftData loadIssueModelContainer error detected", category: "storage")
        return true
    }
    
    return false
}
```

### 2. Applied to Both Container Types

Fixed in **two** places:
1. `tryCreateCloudKitContainer()` - CloudKit-enabled container
2. `createLocalContainer()` - Local-only container

Both now use the same recursive error detection logic.

### 3. Fixed Duplicate Code

Removed duplicate `if isUnknownModelVersion {` statements that were causing compilation issues.

## What Happens Now

When the app launches and encounters this error:

1. ✅ **Detects** the error correctly (even when wrapped in SwiftData error)
2. ✅ **Logs** detailed diagnostic information
3. ✅ **Deletes** the incompatible database files:
   - `CloudKitModel.sqlite`
   - `CloudKitModel.sqlite-shm`
   - `CloudKitModel.sqlite-wal`
4. ✅ **Recreates** a fresh database with current schema
5. ✅ **Syncs** data back from iCloud (if CloudKit enabled)
6. ✅ **App continues** without crashing

## Testing

To test this fix:

### Scenario 1: First Launch After Update
- App detects incompatible database
- Deletes old files
- Creates new database
- Syncs from iCloud
- ✅ No crash

### Scenario 2: CloudKit Unavailable
- App tries CloudKit container → fails
- Falls back to local container
- Detects incompatible database in local container
- Deletes old files
- Creates new local database
- ✅ No crash

### Scenario 3: Clean Install
- No existing database
- Creates new database directly
- ✅ No issues

## Prevention

To prevent similar issues in the future:

1. **Always maintain migration paths** in `Reczipes2MigrationPlan`
2. **Never remove old schema versions** unless you're certain no users have them
3. **Test schema changes** on devices with existing data
4. **Monitor error logs** for database-related issues

## Related Files

- `ModelContainerManager.swift` - Fixed error detection in both container creation methods
- `Reczipes2MigrationPlan.swift` - Migration plan that defines schema versions
- `SchemaVersionManager.swift` - Schema version tracking

## User Impact

**Before Fix:**
- 💥 App crashed on launch
- ❌ Could not access recipes
- ❌ Required manual deletion/reinstall

**After Fix:**
- ✅ App launches successfully
- ✅ Automatically recovers from schema mismatch
- ✅ Data syncs back from iCloud
- ✅ No user intervention needed

## Technical Details

### Error Code 134504

From Apple's Core Data documentation:
- Domain: `NSCocoaErrorDomain`
- Code: `134504`
- Meaning: "Cannot use staged migration with an unknown coordinator model version"
- Cause: Database has a model version not in the current migration plan

### SwiftData Error Code 1

- Domain: `SwiftData.SwiftDataError`
- Code: `1`
- Type: `loadIssueModelContainer`
- Meaning: Failed to load the model container
- Often wraps underlying Core Data errors

## Logs to Watch For

Success:
```
⚠️ Database incompatible with current schema (unknown model version)
   SwiftData loadIssueModelContainer error detected
   Attempting to delete incompatible database and start fresh...
   ✅ Deleted: CloudKitModel.sqlite
   ✅ Deleted: CloudKitModel.sqlite-shm
   ✅ Deleted: CloudKitModel.sqlite-wal
   Deleted 3 database file(s), attempting to recreate...
✅ ModelContainer recreated successfully after database cleanup
   Note: Previous local data was lost, but CloudKit data should sync back
```

Failure (should not happen with this fix):
```
❌ All ModelContainer initialization attempts failed
   Final error: ...
Fatal error: Could not create ModelContainer: ...
```
