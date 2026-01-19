# Database Recovery Fix - "Unknown Model Version" Error

## ✅ **SOLUTION APPLIED**

The app now has **automatic database cleanup** to handle incompatible databases from earlier versions.

## What Was Changed

### ModelContainerManager.swift
- Added error detection for code 134504 ("Cannot use staged migration with an unknown model version")
- When detected, automatically:
  1. Deletes old database files (.sqlite, .sqlite-shm, .sqlite-wal)
  2. Creates fresh database with current schema (V4)
  3. Allows CloudKit to sync data back if enabled

### Why Not SchemaV0?
Initially tried adding SchemaV0 to migration plan, but this caused:
```
'Duplicate version checksums across stages detected.'
```
SchemaV0 and SchemaV1 were identical, so SwiftData rejected them as duplicates.

## What To Do Now

### 1. Clean Build
```
Product → Clean Build Folder (⇧⌘K)
```

### 2. Delete Simulator App
- Long-press app icon → Delete App
- OR reset simulator

### 3. Rebuild and Run

### 4. Watch Console Output

**Expected output:**
```
[Schema]    Migration Stages: 3
📦 Attempting to create ModelContainer with CloudKit...
⚠️ Database incompatible with current schema (unknown model version)
   Attempting to delete corrupted database and start fresh...
   ✅ Deleted: CloudKitModel.sqlite
   ✅ Deleted: CloudKitModel.sqlite-shm  
   ✅ Deleted: CloudKitModel.sqlite-wal
   Deleted 3 database file(s), attempting to recreate...
✅ ModelContainer recreated successfully after database cleanup
```

## Impact on Users

### With CloudKit Enabled
✅ **No data loss** - Data syncs back from iCloud

### Without CloudKit (Local-Only)
⚠️ **Local data will be lost** - Unavoidable for incompatible databases

## Manual Cleanup (If Needed)

If automatic cleanup fails:

1. Find database path in console output
2. In Terminal:
   ```bash
   cd /path/to/Library/Application\ Support
   rm CloudKitModel.sqlite*
   ```
3. Rebuild and run

## Migration Plan Structure

Current migration plan:
- V1 → V2: Add diabetes status
- V2 → V3: Add nutritional goals  
- V3 → V4: Add CloudKit sharing models

Databases older than V1 cannot migrate and will be deleted automatically.
