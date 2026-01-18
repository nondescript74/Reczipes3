# Community Sharing Cleanup Guide

## ⚠️ CRITICAL: Check Local Database First!

### Console shows 421 recipes but only 208 are real?

**YOU MUST FIX LOCAL DATABASE DUPLICATES BEFORE RUNNING CLOUDKIT CLEANUP!**

```
Saved recipes count: 421  ❌ WRONG!
Available recipes count: 421
Total assignments in DB: 208  ✅ Correct
```

This means you have **213 duplicate Recipe records** in your local SwiftData database.

### Fix Order (MUST DO IN THIS ORDER):

#### ⚠️ STEP 0: Clean Local Database First
**Location:** Settings → Developer Tools → Database Recovery

1. **Database Investigation** - See all duplicate recipes
2. **Run Database Recovery** - Consolidate duplicates
3. **Verify:** Console should show matching counts:
   ```
   Saved recipes count: 208 ✅
   Available recipes count: 208 ✅
   Total assignments in DB: 208 ✅
   ```

#### STEP 1: Then Run Diagnostic
**Location:** Settings → Community → Fix Sharing Issues → Run Diagnostic

Now you can safely check CloudKit status.

#### STEP 2: Then Run Cleanup
**Location:** Settings → Community → Fix Sharing Issues → Clean Up & Resync

Only after local database is clean!

---

## Quick Reference: Fixing Incorrect Recipe Counts

### Problem Symptoms
- ❌ "Mine" tab showing wrong count (e.g., 6 instead of 208)
- ❌ "Shared" tab showing inflated count (e.g., 421 instead of 208)
- ❌ Duplicate recipes appearing in community
- ❌ Missing recipes that should be shared

### Solution Path

#### 1️⃣ Run Diagnostic First (Always Start Here)
**Location:** Settings → Community → Fix Sharing Issues → Run Diagnostic

**What it does:**
- Fetches all CloudKit public database records
- Shows count per user
- Identifies duplicate recipe IDs
- No changes made to your data

**Check the logs for:**
```
🔍 DIAGNOSTIC: Successfully fetched X recipes from CloudKit
🔍 DIAGNOSTIC: User 'Name' (ID) shared X recipes
🔍 DIAGNOSTIC: Found X duplicate recipe IDs in CloudKit!
```

#### 2️⃣ Run Cleanup (Only If Needed)
**Location:** Settings → Community → Fix Sharing Issues → Clean Up & Resync

**⚠️ Warning:** This deletes duplicate CloudKit records!

**What it does:**
1. Removes ALL local `SharedRecipe` tracking
2. Fetches ALL CloudKit public database records
3. Identifies and deletes duplicates
4. Keeps newest record or user's own version
5. Rebuilds clean local tracking

**Expected logs:**
```
🧹 Step 1: Removing all local SharedRecipe tracking...
🧹 Step 2: Fetching all CloudKit public database records...
🧹 Step 3: Identifying stale and duplicate records...
🧹 Step 4: Deleting X stale/duplicate records from CloudKit...
🧹 Step 5: Rebuilding local SharedRecipe tracking...
✅ CLEANUP COMPLETE: Removed X duplicates, kept Y clean records
```

### Expected Results After Cleanup

#### User A (208 recipes shared):
- **Mine tab:** 208 recipes ✅
- **Shared tab:** 208 recipes ✅

#### User B (no recipes shared):
- **Mine tab:** 0 recipes ✅
- **Shared tab:** 208 recipes ✅ (from User A)

## Common Issues & Solutions

### Issue: Still seeing duplicates after cleanup
**Solution:** 
1. Check diagnostic logs for which user the duplicates belong to
2. That user needs to run cleanup on their device
3. Other users should see results after restarting app

### Issue: Cleanup fails with authentication error
**Solution:**
1. Settings → iCloud → verify signed in
2. Settings → Validate CloudKit Container
3. Check internet connection
4. Try again in a few minutes

### Issue: Different counts on different devices
**Solution:**
1. Run cleanup on the device with most recipes first
2. Wait 1-2 minutes for CloudKit to propagate
3. Restart other devices
4. Run diagnostic on other devices to verify

## Technical Details

### What causes duplicates?
1. **Multiple share operations** - Same recipe shared multiple times
2. **Failed tracking cleanup** - Local tracking not synced with CloudKit
3. **Interrupted operations** - App closed during share operation
4. **Network issues** - Share succeeded but confirmation failed

### Deduplication logic:
```swift
if (mine && other's) → Keep mine, delete other's
if (both mine) → Keep newer
if (both other's) → Keep newer
```

### CloudKit batch operations:
- Fetch: 100 records per batch with cursor pagination
- Delete: 100 records per batch
- Total capacity: Up to 400 recipes currently

## Developer Notes

### Key Files
- `CloudKitSharingService.swift` - Core sharing logic
- `CommunitySharingCleanupView.swift` - UI
- `SharedContentModels.swift` - Data models

### Key Functions
- `diagnoseSharedRecipes()` - Non-destructive diagnostic
- `cleanupAndResyncSharing()` - Nuclear cleanup option
- `shareRecipe()` - Now includes deduplication
- `fetchSharedRecipes()` - Cursor-based pagination

### Logging Categories
- `"sharing"` - All sharing operations
- `"analytics"` - Success/failure tracking

### Testing Checklist
- [ ] Run diagnostic on device with shared recipes
- [ ] Note current counts (Mine/Shared)
- [ ] Run cleanup
- [ ] Verify counts match expectations
- [ ] Check other device shows same counts
- [ ] Try sharing a new recipe (should not create duplicate)

## Support Scenarios

### Scenario 1: User reports "seeing 421 recipes instead of 208"
1. Ask: "How many recipes did you share?"
2. Guide them to Settings → Community → Fix Sharing Issues
3. Have them run diagnostic first
4. Check logs for duplicate count
5. Run cleanup if duplicates found
6. Verify new count

### Scenario 2: User reports "my recipes disappeared from Mine tab"
1. Run diagnostic
2. Check if recipes exist in CloudKit but aren't tracked locally
3. Run cleanup to rebuild tracking
4. If still missing, check actual Recipe count in local database
5. May need Database Recovery instead

### Scenario 3: Two users sharing - counts don't add up
1. Each user runs diagnostic separately
2. Compare CloudKit counts
3. User with most recipes runs cleanup first
4. Other user waits 2 minutes, then restarts app
5. Both verify counts match

## Last Updated
January 18, 2026 - Initial version with cleanup tools
