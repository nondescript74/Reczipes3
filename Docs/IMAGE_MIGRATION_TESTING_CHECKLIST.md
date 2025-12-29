# Quick Testing Checklist - Image Migration

## Pre-Test Setup

- [ ] Build and install app on iPhone
- [ ] Ensure you have recipes with images
- [ ] Verify iCloud is signed in (Settings → iCloud)
- [ ] Check CloudKit sync is working (App Settings → CloudKit Diagnostics)

---

## Test 1: Migration to SwiftData

### Steps

1. [ ] Open app → **Settings → Data & Sync → Image Migration**
2. [ ] Note "Current Status" counts:
   - Total Recipes: ______
   - With Images: ______
   - Migrated to SwiftData: ______ (should be 0 initially)
3. [ ] Tap **"Migrate Images to SwiftData"**
4. [ ] Wait for progress indicator
5. [ ] Verify "Migration complete!" message appears
6. [ ] Check "Migrated to SwiftData" count increased

### Expected Result

✅ All recipes with images should be migrated
✅ Images still display correctly in recipe list
✅ Opening a recipe shows images properly
✅ No errors in console

### Console Check

```
[image-migration] Starting recipe image migration to SwiftData
[image-migration] Migrated main image for 'Recipe Name'
[image-migration] Migrated 3 additional images for 'Recipe Name'
[image-migration] Image migration complete: X migrated, Y skipped, 0 errors
```

---

## Test 2: Wait for CloudKit Sync

### Steps

1. [ ] Go to **Settings → CloudKit Diagnostics**
2. [ ] Tap **"Check Sync Status"**
3. [ ] Wait 2-5 minutes
4. [ ] Check sync status shows "Synced" or "Up to date"
5. [ ] Look for "Last sync" timestamp

### Expected Result

✅ CloudKit shows "Synced"
✅ No sync errors
✅ Recent sync timestamp

---

## Test 3: Delete and Reinstall App

### ⚠️ IMPORTANT: Only do this after Tests 1 & 2 pass!

### Steps

1. [ ] **DELETE app from iPhone** (long press → Remove App → Delete App)
2. [ ] Verify app is completely removed
3. [ ] **Rebuild and install** from Xcode
4. [ ] Launch app
5. [ ] Accept license agreement
6. [ ] Set up API key (if needed)
7. [ ] Wait 30-60 seconds for initial CloudKit sync

### Expected Result - Automatic Restoration

✅ Recipes appear in list
✅ Images appear automatically (may take 10-30 seconds)
✅ Opening a recipe shows all images

### Console Check (Automatic)

```
[image-migration] Detected missing image files - attempting automatic restoration
[image-migration] Image restoration complete: X recipes restored
[image-migration] Successfully restored images from SwiftData
```

---

## Test 4: Manual Restoration (if automatic fails)

### Steps

1. [ ] If images don't appear automatically, go to **Settings → Image Migration**
2. [ ] Check if warning shows: "Some recipes are missing image files"
3. [ ] Tap **"Restore Images from SwiftData"**
4. [ ] Wait for progress
5. [ ] Verify "Restoration complete!" message

### Expected Result

✅ All images restored
✅ Recipes display images correctly
✅ Console shows restoration success

---

## Test 5: Verify Image Files Created

### Steps

1. [ ] Open any recipe with images
2. [ ] Verify main image displays
3. [ ] Verify additional images display (if any)
4. [ ] Try scrolling through recipe detail view
5. [ ] Check multiple recipes

### Expected Result

✅ All images display correctly
✅ No broken image icons
✅ Images load quickly
✅ No crashes

---

## Test 6: Second Device (Optional)

### Prerequisites

- Second iOS device with same iCloud account
- OR iOS Simulator with same iCloud account

### Steps

1. [ ] Install app on Device B
2. [ ] Sign in to same iCloud account
3. [ ] Launch app
4. [ ] Wait 1-2 minutes for CloudKit sync
5. [ ] Check recipes list

### Expected Result

✅ All recipes appear on Device B
✅ All images appear (may take longer for initial sync)
✅ Recipe details match Device A

---

## Troubleshooting

### Images Not Restoring Automatically

**Try:**
1. Check iCloud settings on device
2. Go to Settings → Image Migration → Manual "Restore"
3. Check CloudKit Diagnostics for errors
4. Try restarting app

### Migration Fails

**Try:**
1. Check available storage on device
2. Check available iCloud storage
3. Close other apps
4. Try again

### CloudKit Sync Stuck

**Try:**
1. Go to Settings → CloudKit Diagnostics
2. Tap "Force Sync"
3. Check account status
4. Verify internet connection

---

## Success Criteria

✅ **Migration**: All images stored in SwiftData
✅ **Sync**: CloudKit syncs successfully  
✅ **Delete**: App deleted completely
✅ **Reinstall**: App reinstalled and launches
✅ **Restoration**: Images automatically restored
✅ **Verification**: All images display correctly

---

## Known Issues / Edge Cases

### Large Image Collections

- Migration may take 5-10 minutes for 100+ recipes
- First sync after migration may take 10-30 minutes
- Restoration after reinstall may take 1-2 minutes

### Low Storage

- Migration may fail if device storage < 1GB free
- CloudKit won't sync if iCloud storage quota exceeded
- Consider compressing images or upgrading iCloud+

### Network Issues

- Slow/no internet delays sync
- Airplane mode blocks CloudKit
- VPN may interfere with iCloud

---

## Console Logs to Watch

### Good Signs ✅

```
✅ ModelContainer created successfully with CloudKit sync enabled
[image-migration] Starting recipe image migration to SwiftData
[image-migration] Image migration complete: 45 migrated, 0 skipped, 0 errors
[cloudkit] CloudKit sync completed successfully
[image-migration] Image restoration complete: 45 recipes restored
```

### Warning Signs ⚠️

```
⚠️ CloudKit account not available
⚠️ CloudKit sync delayed - waiting for network
⚠️ Image file not found: recipe_XYZ.jpg
```

### Error Signs ❌

```
❌ CloudKit sync failed: Network error
❌ Failed to migrate images: Cannot write to directory
❌ Image restoration failed: Missing imageData
```

---

## Post-Test Verification

After all tests pass:

- [ ] Take screenshots of working images
- [ ] Note any performance issues
- [ ] Document any errors encountered
- [ ] Test with a variety of recipes (different image counts)
- [ ] Verify backup/export still works (.reczipes files)

---

## Next Steps

After successful testing:

1. ✅ Update documentation
2. ✅ Inform users to run migration
3. ✅ Monitor CloudKit usage/quota
4. ✅ Consider adding in-app notification for migration
5. ✅ Plan for gradual rollout if needed

---

## Quick Command Reference

### Xcode Console Filtering

```
# Show only image migration logs
image-migration

# Show only CloudKit logs
cloudkit

# Show errors only
error
```

### Clean Build

```
Product → Clean Build Folder (⇧⌘K)
Product → Build (⌘B)
Product → Run (⌘R)
```

---

## Emergency Rollback

If migration causes critical issues:

1. Revert `Recipe.swift` changes (remove imageData fields)
2. Remove `RecipeImageMigrationService.swift`
3. Remove automatic restoration from `Reczipes2App.swift`
4. Clean build and reinstall
5. Images will fall back to file-based system

**Note**: Already migrated data will remain but not be used.

---

## Testing Complete! 🎉

Once all tests pass:
- ✅ Users' images are safe from app deletion
- ✅ Images sync via CloudKit
- ✅ Multi-device support works
- ✅ Automatic restoration works

Great job implementing this critical feature! 👍
