# Community Sharing Orphan & Duplicate Cleanup Guide

## Problem Summary

### Issues Identified
1. **Orphaned Recipes**: Recipes in CloudKit public database with no valid `sharedByUserID`
2. **Duplicate Databases**: Users may have multiple local SwiftData containers
3. **Incorrect Tab Filtering**: Recipes showing in wrong tabs (Mine vs Shared)

### Symptoms
- ✅ Recipes from "Unknown" users appearing in Community tab
- ✅ Recipe counts don't match expected values
- ✅ User's own shared recipes disappearing from "Mine" tab
- ✅ User's own shared recipes appearing in their "Shared" tab

## Solutions Implemented

### 1. Fixed Tab Filtering Logic ✅

**Location**: `ContentView.swift`, `RecipeBooksView.swift`

**Problem**: Filter was treating ALL entries in `SharedRecipe` the same, without checking ownership.

**Solution**: Updated `applyContentFilter(to:)` to distinguish between:
- Recipes the current user shared (`sharedByUserID == currentUserID`)
- Recipes others shared (`sharedByUserID != currentUserID`)

**Result**:
- **"Mine" tab**: Shows ALL user's recipes (including ones they've shared)
- **"Shared" tab**: Shows ONLY recipes shared by OTHER users
- **"All" tab**: Shows everything

### 2. Added Orphan Cleanup Function ✅

**Location**: `CloudKitSharingService.swift`

**New Function**: `removeOrphanedRecipes()`

This function:
1. Fetches all CloudKit public database records
2. Identifies records with missing or empty `sharedByUserID`
3. Deletes orphaned records in batches of 100
4. Logs results with count of orphans removed

```swift
func removeOrphanedRecipes() async throws {
    // Fetch all records
    let allRecords = try await fetchAllCloudKitRecords(type: CloudKitRecordType.sharedRecipe)
    
    // Identify orphans (no valid sharedByUserID)
    var orphanedRecords: [CKRecord.ID] = []
    for record in allRecords {
        guard let sharedBy = record["sharedBy"] as? String,
              !sharedBy.isEmpty else {
            orphanedRecords.append(record.recordID)
            continue
        }
    }
    
    // Delete in batches
    // ... (see implementation for details)
}
```

### 3. Enhanced Cleanup UI ✅

**Location**: `CommunitySharingCleanupView.swift`

Added third section: **"Remove Orphans"**

Features:
- Clear warning about permanent deletion
- Progress indicator during cleanup
- Results display with timing
- Confirmation dialog before execution

### 4. Improved Diagnostic Function ✅

**Location**: `CloudKitSharingService.swift`

Enhanced `diagnoseSharedRecipes()` to show:
- Total recipes in CloudKit
- Recipes grouped by user
- Duplicate detection by recipe ID
- Sample recipe titles

## How to Use

### For Users Experiencing Issues

#### Step 1: Run Diagnostic
1. Open app Settings
2. Navigate to **Community** → **Fix Sharing Issues**
3. Tap **"Run Diagnostic"** (Section 1)
4. Review results to identify:
   - How many recipes are in CloudKit
   - Which users shared recipes
   - If duplicates exist

#### Step 2: Remove Orphaned Recipes (if needed)
**Use this if**: You see recipes from "Unknown" users

1. In Fix Sharing Issues view
2. Scroll to **Section 3: Remove Orphans**
3. Tap **"Remove Orphaned Recipes"**
4. Confirm the action
5. Wait for completion
6. Check logs for results

#### Step 3: Clean Up & Resync (if needed)
**Use this if**: You see duplicate recipes or wrong counts

1. In Fix Sharing Issues view
2. Scroll to **Section 2: Cleanup & Resync**
3. Tap **"Clean Up & Resync"**
4. Confirm the action
5. Wait for completion (may take 30-60 seconds)
6. Verify recipe counts in Community tab

#### Step 4: Verify Results
1. Go to **Recipes** tab
2. Check **"Mine"** filter → should show all YOUR recipes
3. Check **"Shared"** filter → should show ONLY others' recipes
4. Check **"All"** filter → should show everything
5. Counts should be accurate with no duplicates

### Expected Behavior After Cleanup

**User A (who shared recipes)**:
- ✅ Their shared recipes STAY in "Mine" tab
- ✅ Their shared recipes do NOT appear in "Shared" tab
- ✅ All their recipes appear in "All" tab

**User B (viewing shared recipes)**:
- ✅ User A's recipes appear in "Shared" tab
- ✅ User A's recipes do NOT appear in "Mine" tab
- ✅ All recipes (own + shared) appear in "All" tab

### Multiple Databases Issue

**Problem**: Each user may have multiple local SwiftData containers

**Symptoms**:
- Recipes appear/disappear randomly
- Different counts on different devices
- Sync issues between devices

**Solution**:
1. Use **Settings** → **Developer Tools** → **Database Investigation**
2. Review all database locations
3. Use **Database Recovery** to consolidate data
4. Ensure iCloud sync is enabled and working

**Prevention**:
- Keep iCloud sync enabled
- Don't manually modify app data
- Use official import/export features only

## Technical Details

### CloudKit Record Structure

Each shared recipe record contains:
- `sharedBy` (String): User's CloudKit record ID (required)
- `sharedByName` (String): User's display name (optional)
- `recipeData` (String): JSON-encoded recipe
- `title` (String): Recipe title
- `sharedDate` (Date): When it was shared

### Orphan Detection Logic

A record is considered "orphaned" if:
- `sharedBy` field is `nil`
- `sharedBy` field is empty string
- `sharedBy` field exists but is invalid

### Local Tracking

`SharedRecipe` SwiftData model tracks:
- `recipeID`: Local recipe UUID
- `cloudRecordID`: CloudKit record ID
- `sharedByUserID`: Who shared it
- `sharedByUserName`: Display name
- `isActive`: Whether it's currently shared

### Filter Logic

```swift
let currentUserID = CloudKitSharingService.shared.currentUserID

switch contentFilter {
case .mine:
    // Exclude recipes shared by OTHERS
    let sharedByOthersIDs = Set(
        sharedRecipes
            .filter { $0.isActive && $0.sharedByUserID != currentUserID }
            .compactMap { $0.recipeID }
    )
    return recipes.filter { !sharedByOthersIDs.contains($0.id) }
    
case .shared:
    // Only show recipes shared by OTHERS
    let sharedByOthersIDs = Set(
        sharedRecipes
            .filter { $0.isActive && $0.sharedByUserID != currentUserID }
            .compactMap { $0.recipeID }
    )
    return recipes.filter { sharedByOthersIDs.contains($0.id) }
}
```

## Files Modified

### Core Functionality
1. **CloudKitSharingService.swift**
   - Added `removeOrphanedRecipes()`
   - Enhanced `diagnoseSharedRecipes()`

2. **ContentView.swift**
   - Fixed `applyContentFilter(to:)` logic
   - Added currentUserID comparison

3. **RecipeBooksView.swift**
   - Fixed `filteredBooks` computation
   - Added currentUserID comparison

### User Interface
4. **CommunitySharingCleanupView.swift**
   - Added orphan cleanup section
   - Added confirmation dialog
   - Added results display

### Documentation
5. **SHARING_TAB_FILTER_FIX.md** (new)
   - Documented filter fix
   - Explained expected behavior

6. **COMMUNITY_SHARING_ORPHAN_CLEANUP_GUIDE.md** (this file)
   - Comprehensive cleanup guide
   - User instructions
   - Technical details

## Testing Checklist

### Orphan Cleanup
- [ ] Run diagnostic shows orphaned records
- [ ] Remove orphans successfully deletes them
- [ ] No valid user records are deleted
- [ ] CloudKit public database is clean after cleanup
- [ ] No errors during batch deletion

### Filter Logic
- [ ] User A shares recipe → stays in User A's "Mine" tab
- [ ] User A shares recipe → does NOT appear in User A's "Shared" tab
- [ ] User B sees User A's recipe → appears in User B's "Shared" tab
- [ ] User B's own recipes → only in "Mine" tab
- [ ] "All" tab shows complete list for both users

### Edge Cases
- [ ] User with no shared recipes → "Shared" tab empty
- [ ] User with no personal recipes → "Mine" tab empty
- [ ] Multiple users sharing → each sees correct subset
- [ ] Unsharing recipe → removed from CloudKit, stays in local "Mine"
- [ ] Re-sharing recipe → new CloudKit record created

## Troubleshooting

### "No orphans found" but still seeing unknown recipes
**Cause**: Recipes may have valid but incorrect userID
**Solution**: Use "Clean Up & Resync" to rebuild tracking

### Cleanup fails with error
**Cause**: Network issue or CloudKit unavailable
**Solution**: 
1. Check internet connection
2. Verify iCloud account is signed in
3. Try again in a few minutes

### Recipes still showing in wrong tab after cleanup
**Cause**: Local cache not refreshed
**Solution**:
1. Force quit app
2. Reopen app
3. Pull to refresh in Recipes tab

### Different counts on different devices
**Cause**: Multiple local databases or sync issues
**Solution**:
1. Settings → Database Investigation
2. Settings → Database Recovery
3. Ensure iCloud sync is enabled

## Prevention Best Practices

### For Users
1. **Keep iCloud Sync On**: Prevents multiple databases
2. **Regular Cleanups**: Run diagnostic monthly
3. **Verify Sharing**: Check "Mine" tab after sharing
4. **Report Issues**: Use Fix Sharing Issues immediately

### For Developers
1. **Validate sharedByUserID**: Always set when creating records
2. **Test Cleanup**: Regularly test orphan detection
3. **Monitor CloudKit**: Check public database health
4. **Log Everything**: Use diagnostic logging for issues

## Future Enhancements

Potential improvements:
1. **Automatic Orphan Detection**: Weekly background check
2. **Pre-share Validation**: Verify userID before sharing
3. **Ownership Transfer**: Allow transferring recipes between users
4. **Batch Cleanup**: Clean up multiple issues at once
5. **Analytics**: Track cleanup success rates

## Support

If issues persist after cleanup:
1. Run diagnostic and save results
2. Check Settings → Advanced Diagnostics → Diagnostic Log
3. Use Settings → User Content Import/Export to backup data
4. Contact support with diagnostic log

---

## Quick Reference

### Cleanup Order
1. **Diagnostic** → Identify issues
2. **Remove Orphans** → Delete invalid records
3. **Clean Up & Resync** → Fix duplicates
4. **Verify** → Check tabs show correctly

### Safety Notes
- ⚠️ Orphan cleanup is PERMANENT
- ⚠️ Clean & Resync rebuilds local tracking
- ✅ Your actual recipes are safe (only tracking changes)
- ✅ CloudKit records owned by you are preserved

### Key Locations
- **Fix Issues**: Settings → Community → Fix Sharing Issues
- **Browse Shared**: Settings → Community → Browse Community Recipes
- **Diagnostics**: Settings → Advanced Diagnostics
- **Database**: Settings → Database Investigation

---

*Last Updated: January 18, 2026*
