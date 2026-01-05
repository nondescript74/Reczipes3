# Backup Location Update

## Changes Made

Updated the recipe backup system to save and load backups from the **Files/Reczipes2** folder instead of temporary storage.

## What Changed

### 1. **RecipeBackupManager.swift**

#### Export Location
- **Before**: Backups were saved to `FileManager.default.temporaryDirectory`
- **After**: Backups are now saved to `Documents/Reczipes2/` folder
- The folder is automatically created if it doesn't exist
- Files are now persistent and accessible via the Files app

#### New Feature: List Available Backups
Added `listAvailableBackups()` method that:
- Scans the `Documents/Reczipes2/` folder for `.reczipes` files
- Returns an array of `BackupFileInfo` with file metadata
- Sorts backups by modification date (most recent first)

#### New Structure: BackupFileInfo
```swift
struct BackupFileInfo: Identifiable {
    let url: URL
    let fileName: String
    let fileSize: Int
    let creationDate: Date
    let modificationDate: Date
    var fileSizeFormatted: String  // Human-readable file size
    var displayName: String         // Clean display name
}
```

### 2. **RecipeBackupView.swift**

#### New UI Features
- Displays all available backups from the Reczipes2 folder
- Shows backup name, date, and file size for each backup
- Refresh button in section header to reload backup list
- Individual import buttons for each backup file
- "Import from Other Location" option for files from other sources

#### Import Workflow
1. **On Appear**: Automatically loads available backups from Reczipes2 folder
2. **Tap Backup**: Directly imports that specific backup file
3. **Manual Import**: Can still import from other locations via file picker

#### State Management
Added new state variables:
- `availableBackups: [BackupFileInfo]` - List of found backup files
- `selectedBackup: BackupFileInfo?` - Currently importing backup

## Benefits

### For Users
1. **Persistent Storage**: Backups are no longer deleted when temp files are cleared
2. **Files App Access**: Can manage backups through iOS/iPadOS Files app
3. **Easy Discovery**: Backups are automatically listed in the import view
4. **iCloud Sync**: If enabled, backups in Documents can sync via iCloud
5. **Better Organization**: All backups in one dedicated folder

### For Developers
1. **Better UX**: Users don't have to hunt for backup files
2. **Automatic Discovery**: App finds and displays available backups
3. **File Management**: Users can delete old backups via Files app
4. **Sharing**: Easier to share backups between devices

## File Locations

### iOS/iPadOS
- Full Path: `On My iPhone/Reczipes2/Reczipes2/`
- Accessible via: Files app → "On My [Device]" → "Reczipes2"

### Programmatic Path
```swift
let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let reczipesDirectory = documentsDirectory.appendingPathComponent("Reczipes2", isDirectory: true)
```

## File Naming Convention

Backups are named: `RecipeBackup_YYYY-MM-DD_HHmmss.reczipes`

Example: `RecipeBackup_2026-01-05_143022.reczipes`

Display Name: `2026-01-05_143022` (prefix and extension removed for cleaner UI)

## Testing Checklist

- [ ] Create a backup - verify it appears in Files app
- [ ] Check Reczipes2 folder is created automatically
- [ ] Verify backup list populates on import view
- [ ] Test importing from listed backup
- [ ] Test refresh button updates the list
- [ ] Test "Import from Other Location" still works
- [ ] Verify backups persist after app restart
- [ ] Test with multiple backups (sorting by date)
- [ ] Check file size formatting displays correctly

## Notes

- The app automatically creates the `Reczipes2` folder on first backup
- If no backups exist, shows "No backups found in Reczipes2 folder" message
- Users can delete old backups through the Files app
- The file picker is still available for importing from other locations
- All existing backup/restore functionality remains unchanged
