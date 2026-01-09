# Bundle ID Change Verification Guide
## From ImageExtract to com.headydiscy.reczipes2

Date: January 9, 2026  
Build: 74+  
Container: iCloud.com.headydiscy.reczipes (unchanged)

---

## What Changed

- **Old Bundle ID**: `com.headydiscy.ImageExtract`
- **New Bundle ID**: `com.headydiscy.reczipes2`
- **CloudKit Container**: `iCloud.com.headydiscy.reczipes` (SAME)
- **App Store Connect**: New app entry (different bundle ID = different app)

---

## ✅ Verification Checklist

### 1. Xcode Project Settings

#### Target Settings
- [ ] Open Xcode
- [ ] Select **Reczipes2** target
- [ ] **General** tab:
  - Bundle Identifier: `com.headydiscy.reczipes2` ✓
  - Version: Current version
  - Build: 74 or higher ✓

#### Signing & Capabilities
- [ ] **Signing & Capabilities** tab
- [ ] **Automatically manage signing** is checked
- [ ] Team is selected
- [ ] **iCloud** section exists:
  - [ ] ☑️ CloudKit is checked
  - [ ] Container `iCloud.com.headydiscy.reczipes` is listed
  - [ ] Container checkbox is **checked** (enabled)
  - [ ] No errors shown in the section

#### Entitlements File
- [ ] Look for `Reczipes2.entitlements` in Project Navigator
- [ ] Click on it
- [ ] Should contain:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.headydiscy.reczipes</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    <!-- Other entitlements may also be present -->
</dict>
</plist>
```

- [ ] File Inspector shows **Target Membership**: Reczipes2 ✓

### 2. Apple Developer Portal

#### App ID Registration
- [ ] Go to: https://developer.apple.com/account/resources/identifiers/list
- [ ] Find `com.headydiscy.reczipes2` in the list
- [ ] Click on it
- [ ] Verify:
  - [ ] **iCloud** capability is enabled
  - [ ] Under iCloud:
    - [ ] "Include CloudKit support (requires Xcode 6)" is checked
    - [ ] "Use default container" is selected OR
    - [ ] Container `iCloud.com.headydiscy.reczipes` is explicitly listed

If not found:
1. Click **+** (Add)
2. Select **App IDs** → Continue
3. Select **App** → Continue
4. Enter:
   - Description: `Reczipes2`
   - Bundle ID: `com.headydiscy.reczipes2` (Explicit)
5. Enable **iCloud** with CloudKit support
6. Register

#### Provisioning Profiles
- [ ] Go to **Profiles** section
- [ ] You should see new profiles for `com.headydiscy.reczipes2`
- [ ] If using automatic signing, Xcode creates these automatically
- [ ] If manual signing:
  - [ ] Create new Development profile
  - [ ] Create new Distribution profile
  - [ ] Both should include iCloud capability

### 3. CloudKit Dashboard

#### Container Configuration
- [ ] Go to: https://icloud.developer.apple.com/dashboard/
- [ ] Click on container: `iCloud.com.headydiscy.reczipes`
- [ ] Click **API Access** (or similar section showing connected apps)
- [ ] Verify `com.headydiscy.reczipes2` is listed
- [ ] If not, it will be added when you first run the app

#### Schema Verification
- [ ] Click **Schema** in CloudKit Dashboard
- [ ] Development environment should show:
  - [ ] Record Types: Recipe, RecipeImageAssignment, UserAllergenProfile, etc.
  - [ ] These should already exist from old bundle ID
  - [ ] **Same data, just different app accessing it**

### 4. App Store Connect

#### New App Entry
- [ ] Go to: https://appstoreconnect.apple.com/
- [ ] You should see **two apps**:
  - Old app (com.headydiscy.ImageExtract)
  - **New app** (com.headydiscy.reczipes2)
- [ ] Select the new app (Reczipes2)
- [ ] Go to **TestFlight** tab
- [ ] Verify Build 74 (or higher) is present
- [ ] Check status:
  - [ ] Processing → Ready to Test
  - [ ] Compliance status: Resolved
  - [ ] Available for Testing

### 5. Build Verification (Local)

#### After Archive
- [ ] Product → Archive
- [ ] Wait for completion
- [ ] Organizer opens
- [ ] Right-click archive → Show in Finder
- [ ] Right-click `.xcarchive` → Show Package Contents
- [ ] Navigate to: `Products/Applications/Reczipes2.app`

#### Check Bundle ID in Archive
In Terminal:

```bash
# Navigate to your archive (replace date/time with yours)
cd ~/Library/Developer/Xcode/Archives/2026-01-*/Reczipes2*

# Find the most recent
LATEST=$(find . -name "Reczipes2.app" -type d | sort -r | head -n 1)

# Check bundle ID
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$LATEST/Info.plist"
# Should output: com.headydiscy.reczipes2

# Check version
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$LATEST/Info.plist"
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$LATEST/Info.plist"
# Should show your current version and build 74+

# Check entitlements
codesign -d --entitlements :- "$LATEST"
# Should show iCloud.com.headydiscy.reczipes in container list
```

### 6. TestFlight Testing

#### Install on Devices
- [ ] On each test device:
  - [ ] **Completely delete old app** (com.headydiscy.ImageExtract)
  - [ ] Open **TestFlight** app
  - [ ] Find **Reczipes2** (new app)
  - [ ] Install Build 74+

#### First Launch Verification
- [ ] Open app
- [ ] Check console/logs for:
  ```
  Container: iCloud.com.headydiscy.reczipes
  Bundle ID: com.headydiscy.reczipes2
  ```
- [ ] App should show CloudKit sync working

#### Run CloudKit Validator
- [ ] Go to **Settings** in app
- [ ] Tap **Validate CloudKit Container**
- [ ] Tap **Run Validation**
- [ ] Should see:

```
✅ All checks passed - CloudKit should work!

📦 CONTAINER INFORMATION:
   Container ID: iCloud.com.headydiscy.reczipes
   Bundle ID: com.headydiscy.reczipes2  ← NEW BUNDLE ID
   Can Create Reference: ✅

👤 ICLOUD ACCOUNT:
   ✅ iCloud account available

🗄️  CONTAINER ACCESS:
   ✅ Container accessible
   Private Database: ✅ Accessible
   User Record ID: _[your user record ID]

🔐 ENTITLEMENTS CHECK:
   ⚠️ Entitlements cannot be read at runtime. Validation is based on actual CloudKit access test.
   
   💡 Real test: Can we access CloudKit? (See Container Access above)
      - If container access works → Entitlements are correct ✅
```

- [ ] **NO** false errors about missing entitlements
- [ ] **NO** debug messages about "ImageExtract"
- [ ] Bundle ID shows `com.headydiscy.reczipes2` ✓

### 7. Data Migration Verification

Since you kept the same CloudKit container, existing data should sync:

- [ ] Check recipe list
- [ ] Verify existing recipes appear
- [ ] Verify recipe books are present
- [ ] Check allergen profile settings
- [ ] Verify saved links
- [ ] Test creating new recipe
- [ ] Test editing existing recipe
- [ ] **Verify changes sync to other devices**

---

## 🚨 Common Issues After Bundle ID Change

### Issue 1: "Container not found" Error

**Symptoms:**
```
❌ Cannot access container's private database
Container identifier is invalid or doesn't exist
```

**Cause:** App ID not registered or not associated with container

**Fix:**
1. Go to Apple Developer Portal
2. Edit App ID `com.headydiscy.reczipes2`
3. Enable iCloud with CloudKit
4. Make sure container is associated
5. Clean and rebuild in Xcode
6. Re-archive and upload

### Issue 2: "Permission Denied" Error

**Symptoms:**
```
❌ Permission denied - check entitlements
```

**Cause:** Entitlements file not properly configured

**Fix:**
1. In Xcode: Signing & Capabilities
2. Remove iCloud capability
3. Re-add iCloud capability
4. Check CloudKit
5. Add container manually: `iCloud.com.headydiscy.reczipes`
6. Clean build
7. Archive again

### Issue 3: Two Apps in TestFlight

**Symptoms:** Users see both old and new app in TestFlight

**Expected:** This is normal! Different bundle IDs = different apps

**What to do:**
- Keep both for now
- Add note in TestFlight description:
  > "This is the new version of Reczipes. Please delete the old 'ImageExtract' version and install this one. Your data will sync automatically."
- Eventually archive the old app in App Store Connect

### Issue 4: Data Not Syncing

**Symptoms:** Old data doesn't appear in new app

**Cause:** Different iCloud account or container not accessible

**Fix:**
1. Verify same iCloud account signed in
2. Check CloudKit Dashboard shows container
3. Verify container has data (Development environment)
4. Run validator to check container access
5. Check console logs for sync errors

### Issue 5: TestFlight Shows Old Bundle ID

**Symptoms:** Validator shows `com.headydiscy.ImageExtract`

**Cause:** User installed old app instead of new one

**Fix:**
- Delete ALL versions of the app
- In TestFlight, make sure you're installing the new app
- Check app name carefully
- Verify build number (should be 74+)

---

## 📊 Before/After Comparison

### Before (Build 73 and earlier)
```
Bundle ID: com.headydiscy.ImageExtract
Container: iCloud.com.headydiscy.reczipes
App Store Connect: Old app entry
TestFlight: Old bundle
```

### After (Build 74+)
```
Bundle ID: com.headydiscy.reczipes2 ✨ NEW
Container: iCloud.com.headydiscy.reczipes ✓ SAME
App Store Connect: New app entry ✨ NEW
TestFlight: New bundle ✨ NEW
```

**Data:** Remains in CloudKit container, accessible by both old and new app (if both are signed in with same iCloud account)

---

## 🎯 Success Criteria

You'll know everything is working when:

✅ Xcode builds without errors  
✅ Archive completes successfully  
✅ TestFlight accepts the upload  
✅ Build 74+ appears in TestFlight as "Ready to Test"  
✅ App installs on test devices from TestFlight  
✅ App launches without crashes  
✅ CloudKit validator shows `com.headydiscy.reczipes2`  
✅ Validator shows "✅ All checks passed"  
✅ Existing recipes and data appear  
✅ New recipes can be created and synced  
✅ No false entitlements errors  

---

## 📱 Testing Matrix

Test on each device type:

| Device | OS Version | Delete Old App | Install Build | Run Validator | Check Data | Sync Test |
|--------|------------|----------------|---------------|---------------|------------|-----------|
| iPhone | iOS 17+    | ☐              | ☐             | ☐             | ☐          | ☐         |
| iPad   | iPadOS 17+ | ☐              | ☐             | ☐             | ☐          | ☐         |
| Device 3 | iOS/iPadOS | ☐            | ☐             | ☐             | ☐          | ☐         |

---

## 🔧 Quick Terminal Commands

```bash
# Check current bundle ID in built app
cd ~/Library/Developer/Xcode/DerivedData
find . -name "Reczipes2.app" -type d | while read app; do
    echo "Found: $app"
    /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app/Info.plist"
done

# Check entitlements in last archive
cd ~/Library/Developer/Xcode/Archives
LATEST=$(find . -name "*.xcarchive" -type d -print | sort -r | head -n 1)
echo "Checking: $LATEST"
codesign -d --entitlements :- "$LATEST/Products/Applications/Reczipes2.app" 2>&1 | grep -A 5 "icloud"

# Find all Reczipes2 archives
cd ~/Library/Developer/Xcode/Archives
find . -name "*Reczipes2*.xcarchive" -type d | sort -r
```

---

## 📞 Support

If you encounter issues:

1. Check this checklist again
2. Review console logs during app launch
3. Run CloudKit validator and copy output
4. Check CloudKit Dashboard for errors
5. Verify entitlements in archive before uploading

---

## ✨ Next Steps After Verification

Once everything is working:

1. **Update App Store listing** (when ready for production)
   - New screenshots
   - Updated description
   - Privacy policy if needed

2. **Deprecate old app** (optional)
   - Add note directing users to new app
   - Eventually remove from sale

3. **Monitor CloudKit usage**
   - Check dashboard for errors
   - Monitor sync performance
   - Watch for quota issues

4. **Update documentation**
   - Update any references to old bundle ID
   - Update API documentation if applicable
   - Update user-facing docs

---

**Last Updated:** January 9, 2026  
**Build:** 74+  
**Status:** Ready for verification ✅

