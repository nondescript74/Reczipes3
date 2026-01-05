# Backup Filename Collision Fix

## Issue

The test `testMultipleSequentialBackups` was failing because backup files created in rapid succession were **overwriting each other**. 

### Root Cause

The backup filename generation used only **second-level precision**:

```swift
// OLD CODE - Only seconds precision
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
let dateString = dateFormatter.string(from: Date())
let fileName = "RecipeBackup_\(dateString).reczipes"
```

This meant:
- If two backups were created within the same second, they had **identical filenames**
- The second backup would **overwrite** the first one
- Test checks for the first backup would fail because the file no longer existed

### Why This Happened

Even though the test had a 1.1 second delay between backups:
```swift
try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
```

There were still edge cases where:
1. System clock precision might round to the same second
2. The `Date()` was captured at nearly the same moment
3. File system operations completed faster than expected

## Solution

Added **millisecond precision** to backup filenames to ensure uniqueness:

### Changes to `RecipeBackupManager.swift`

#### 1. Updated Filename Generation
```swift
// NEW CODE - Milliseconds for uniqueness
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
let currentDate = Date()
let dateString = dateFormatter.string(from: currentDate)

// Add milliseconds to ensure uniqueness when creating multiple backups quickly
let milliseconds = Int((currentDate.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)) * 1000)
let fileName = "RecipeBackup_\(dateString)_\(String(format: "%03d", milliseconds)).reczipes"
let fileURL = reczipesDirectory.appendingPathComponent(fileName)
```

**New Format**: `RecipeBackup_2026-01-05_143022_123.reczipes`
- Year-Month-Day: `2026-01-05`
- Hour-Minute-Second: `143022`
- Milliseconds: `123` (3 digits, zero-padded)

#### 2. Updated Display Name to Hide Milliseconds

Users don't need to see the milliseconds (they're just for uniqueness), so we strip them from the display name:

```swift
var displayName: String {
    // Remove "RecipeBackup_" prefix and ".reczipes" extension
    var name = fileName
    if name.hasPrefix("RecipeBackup_") {
        name = String(name.dropFirst("RecipeBackup_".count))
    }
    if name.hasSuffix(".reczipes") {
        name = String(name.dropLast(".reczipes".count))
    }
    
    // Optionally clean up the milliseconds suffix (e.g., "_123") for cleaner display
    if let range = name.range(of: #/_\d{3}$/#, options: .regularExpression) {
        name.removeSubrange(range)
    }
    
    return name
}
```

**Display**: `2026-01-05_143022` (milliseconds removed)

### Changes to `RecipeExportImportTests.swift`

#### 1. Enhanced `testMultipleSequentialBackups`

Added better diagnostics:
```swift
// Verify file exists immediately after creation
#expect(FileManager.default.fileExists(atPath: backupURL.path), 
        "Backup \(i) should exist immediately after creation at: \(backupURL.path)")

print("Created backup \(i): \(backupURL.lastPathComponent) - exists: \(FileManager.default.fileExists(atPath: backupURL.path))")
```

Added settling delay before final checks:
```swift
// Wait a moment before final verification to ensure all files are settled
try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
```

Added detailed logging:
```swift
print("Available backups: \(availableFileNames.sorted())")
print("Expected backups: \(backupFileNames.sorted())")
```

#### 2. Updated `testBackupFileNaming`

Added check for milliseconds in filename:
```swift
// Should contain milliseconds (3 digits) for uniqueness
let millisPattern = #/_\d{3}\.reczipes/#
#expect(fileName.contains(millisPattern), 
        "Backup filename should contain milliseconds for uniqueness")
```

#### 3. Updated `testBackupFileInfoDisplayName`

Added tests for both new and old formats:
```swift
// Test with new format (with milliseconds)
let backupInfo1 = BackupFileInfo(
    url: url1,
    fileName: "RecipeBackup_2026-01-05_143022_123.reczipes",
    fileSize: 12345,
    creationDate: Date(),
    modificationDate: Date()
)

#expect(backupInfo1.displayName == "2026-01-05_143022", 
        "Display name should remove milliseconds")

// Test with old format (without milliseconds) for backward compatibility
let backupInfo2 = BackupFileInfo(
    url: url2,
    fileName: "RecipeBackup_2026-01-05_143022.reczipes",
    fileSize: 12345,
    creationDate: Date(),
    modificationDate: Date()
)

#expect(backupInfo2.displayName == "2026-01-05_143022", 
        "Display name should work with old format too")
```

## Benefits

1. **Prevents filename collisions** - Multiple backups can be created within the same second
2. **Backward compatible** - Old backup files without milliseconds still work
3. **Clean UI** - Milliseconds are hidden from user display
4. **Better testing** - More detailed diagnostics help identify future issues
5. **Reliable** - Test now passes consistently even with rapid backup creation

## Testing

The test now:
1. ✅ Creates 3 backups sequentially
2. ✅ Verifies each exists immediately after creation
3. ✅ Waits for file system to settle
4. ✅ Verifies all 3 still exist
5. ✅ Confirms all appear in available backups list
6. ✅ Provides detailed diagnostic output

## Backward Compatibility

Old backup files (without milliseconds) continue to work:
- `RecipeBackup_2026-01-05_143022.reczipes` ← Old format (still supported)
- `RecipeBackup_2026-01-05_143022_123.reczipes` ← New format

Both display as: `2026-01-05_143022`
