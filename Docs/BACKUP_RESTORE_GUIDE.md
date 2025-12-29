# Recipe Backup & Restore - Quick Guide

## ✅ What's Ready

You now have a complete backup and restore system integrated into Settings!

**Location:** Settings → Backup & Restore

---

## 📤 How to Backup Your Recipes

### Before Reinstalling the App:

1. **Open the app** on your iPhone (the one with 45 recipes)
2. Go to **Settings** tab
3. Tap **"Backup & Restore"**
4. Tap **"Export All Recipes"**
5. Wait for export to complete (should take 10-30 seconds)
6. **Share the backup file:**
   - **Recommended:** Save to **iCloud Drive** → Files app → Reczipes folder
   - Or: AirDrop to yourself
   - Or: Email to yourself
   - Or: Save to another cloud service (Dropbox, Google Drive, etc.)

The backup file:
- Named: `RecipeBackup_YYYY-MM-DD_HHMMSS.reczipes`
- Contains: ALL recipes with ALL their images
- Format: JSON (readable) + embedded image data
- Size: Varies (depends on number and size of images)

---

## 📥 How to Restore Your Recipes

### After Reinstalling with CloudKit Fix:

1. **Install the new app** (with CloudKit fixes)
2. **Launch the app** (will be empty initially)
3. Go to **Settings** tab
4. Tap **"Backup & Restore"**
5. Choose **Import Mode:**
   - **Keep Both** (Recommended) - Imports everything, even duplicates
   - **Skip Existing** - Only imports recipes you don't have
   - **Overwrite** - Replaces any matching recipes
6. Tap **"Import Recipes"**
7. Navigate to where you saved the `.reczipes` file
8. Select it
9. Wait for import to complete (10-60 seconds depending on size)
10. **Success!** All 45 recipes are back with images!

---

## 🎯 The Complete Reinstall Process

### Step-by-Step:

1. **BACKUP FIRST** ⚠️
   - Settings → Backup & Restore → Export All Recipes
   - Save the `.reczipes` file to iCloud Drive or email it

2. **Delete the app** from iPhone

3. **Delete the app** from iPad

4. **Clean build** in Xcode (Cmd+Shift+K)

5. **Rebuild and install** on iPhone

6. **Verify CloudKit is enabled:**
   - Settings → Container Details
   - Should show: "CloudKit: Enabled" ✅

7. **Restore your recipes:**
   - Settings → Backup & Restore → Import Recipes
   - Select your backup file
   - Choose "Keep Both" mode
   - Wait for import

8. **Create a test recipe:**
   - Go to Recipes tab
   - Create: "SYNC TEST iPhone"
   - Save it

9. **Install on iPad:**
   - Build and install
   - Wait 2-3 minutes
   - Check if "SYNC TEST iPhone" appears

10. **SUCCESS!** 🎉
    - Both devices have CloudKit enabled
    - All 45 recipes are on iPhone
    - They're syncing to iPad
    - Any new recipes sync automatically

---

## 💡 Import Modes Explained

### Keep Both (Recommended)
- **What it does:** Imports ALL recipes from the backup
- **Duplicates:** Creates new copies with different IDs
- **Use when:** You want to make sure nothing is lost
- **After import:** You might have duplicates to clean up manually

### Skip Existing  
- **What it does:** Only imports recipes you don't already have
- **Duplicates:** Skips them (checks by Recipe ID)
- **Use when:** You already have some recipes and just want to add more
- **After import:** No duplicates, but existing recipes unchanged

### Overwrite
- **What it does:** Replaces existing recipes with backup versions
- **Duplicates:** Overwrites them (checks by Recipe ID)
- **Use when:** You want the backup to be the "source of truth"
- **After import:** Existing recipes replaced with backup versions

---

## 📊 What Gets Backed Up

✅ **Recipe Details:**
- Title, header notes, yield, reference
- All ingredient sections
- All instruction sections
- All notes
- Date added
- Recipe ID (for duplicate detection)

✅ **Images:**
- Main/primary image
- All additional images
- Full resolution (not compressed)

✅ **Metadata:**
- Export date
- Version info
- Recipe count

---

## ⚠️ Important Notes

### File Size
- **Without images:** Small (a few KB per recipe)
- **With images:** Larger (500KB - 5MB per recipe depending on photo quality)
- **45 recipes with images:** Probably 20-100MB total

### Storage Locations
- **iCloud Drive:** ✅ Best - syncs across devices
- **Files app:** ✅ Good - accessible anywhere
- **Email:** ✅ Good for one-time backup
- **AirDrop:** ✅ Good for transferring to another device
- **Local Files app only:** ⚠️ Lost if device is lost

### Security
- Backups are **NOT encrypted**
- Anyone with the file can see your recipes
- Store in secure location (iCloud Drive with 2FA is good)
- Don't share publicly if recipes are private/secret

---

## 🧪 Test It First!

Before the big reinstall:

1. **Create a test recipe** (just one)
2. **Export it** (Settings → Backup & Restore)
3. **Delete the test recipe**
4. **Import the backup**
5. **Verify the test recipe is back**

If this works, the full backup/restore will work too!

---

## 🐛 Troubleshooting

### Export fails
- **Check storage space** - Need enough for all images
- **Check permissions** - App needs file access
- **Try again** - Sometimes temporary glitch

### Import fails
- **Check file format** - Must be `.reczipes` file
- **Check file location** - If in iCloud, must be downloaded
- **Check storage space** - Need enough for all images
- **Try different import mode** - "Keep Both" is most forgiving

### Import seems stuck
- **Be patient** - Large backups (100+ recipes with images) can take a minute
- **Check console** - Look for progress logs
- **Don't force quit** - Let it finish

### Duplicates after import
- **Normal with "Keep Both" mode** - This is intentional for safety
- **Clean up manually** - Delete the duplicates you don't want
- **Next time use "Skip Existing"** - Won't create duplicates

---

## ✨ Tips

1. **Backup regularly** - Not just when reinstalling
2. **Keep multiple backups** - Weekly/monthly snapshots
3. **Test restores** - Make sure backups work before you need them
4. **Name your backups** - Add notes about what's in them
5. **Store safely** - Use iCloud Drive or other cloud storage

---

## 🎯 Ready!

You're all set to:
1. ✅ Backup your 45 recipes (with images)
2. ✅ Reinstall the app with CloudKit fix
3. ✅ Restore your recipes
4. ✅ Verify sync works between devices
5. ✅ Keep using the app with confidence

**Start by creating a backup NOW, then proceed with the reinstall!** 🚀
