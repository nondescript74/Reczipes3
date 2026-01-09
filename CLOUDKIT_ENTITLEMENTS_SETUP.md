# CloudKit Entitlements Setup for iCloud.com.headydiscy.reczipes

## Quick Setup Guide

Follow these steps in Xcode to enable CloudKit sync with your existing container.

---

## Step 1: Open Signing & Capabilities

1. Open your project in Xcode
2. Select the **Reczipes2** target (not the project)
3. Click the **Signing & Capabilities** tab at the top

---

## Step 2: Add iCloud Capability (if missing)

If you don't see an **iCloud** section:

1. Click **+ Capability** button (top left)
2. Search for **iCloud**
3. Double-click to add it

---

## Step 3: Enable CloudKit

In the **iCloud** section:

1. Check the box for **CloudKit**
2. Check the box for **iCloud Drive** (optional but recommended)

---

## Step 4: Add Container

Still in the **iCloud** section:

### If Container List is Empty:
1. Click the **+** button next to "Containers"
2. Select **Specify Custom Container**
3. Enter: `iCloud.com.headydiscy.reczipes`
4. Click **OK**
5. Make sure the checkbox next to the container is **checked**

### If Container Exists But Unchecked:
1. Check the box next to `iCloud.com.headydiscy.reczipes`

### If Wrong Container is Listed:
1. Uncheck any wrong containers
2. Click **+** to add the correct one: `iCloud.com.headydiscy.reczipes`
3. Check the box next to the correct container

---

## Step 5: Verify Entitlements File

Xcode should automatically create/update `Reczipes2.entitlements`.

### Check the File:

1. In Project Navigator, find **Reczipes2.entitlements**
2. Click to open it
3. Verify it contains these keys:

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
    <!-- Optional but recommended: -->
    <key>com.apple.developer.ubiquity-kvstore-identifier</key>
    <string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
</dict>
</plist>
```

### If Missing or Wrong:

**Option 1: Let Xcode Fix It**
1. Go back to Signing & Capabilities
2. Remove the iCloud capability (click X)
3. Re-add it (+ Capability → iCloud)
4. Re-add the container
5. Xcode will regenerate the entitlements

**Option 2: Edit Manually**
1. Right-click entitlements file → Open As → Source Code
2. Copy the XML above
3. Paste it in (replacing existing content)
4. Save

---

## Step 6: Clean Build

1. **Product → Clean Build Folder** (Cmd+Shift+K)
2. **Product → Build** (Cmd+B)

---

## Step 7: Test on Device

### Device Setup:
1. Go to **Settings** on iPhone/iPad
2. Tap your **name** at the top
3. Tap **iCloud**
4. Make sure you're **signed in**
5. Turn ON **iCloud Drive**

### Install App:
1. Connect device to Mac
2. Select device in Xcode
3. Click **Run** (installs over existing app - preserves data)

### Check Console:
Look for this message:
```
✅ ModelContainer created successfully with CloudKit sync enabled
   Container: iCloud.com.headydiscy.reczipes
```

**If you see this instead:**
```
⚠️ CloudKit ModelContainer creation failed
   Attempting fallback to local-only container...
```

Then something is still wrong. See troubleshooting below.

---

## Troubleshooting

### Issue 1: "Container not found" Error

**Symptom:**
```
CloudKit container iCloud.com.headydiscy.reczipes doesn't exist
```

**Cause:** Container not registered with Apple Developer

**Fix:**
1. Go to https://icloud.developer.apple.com/dashboard/
2. Sign in with your Apple Developer account
3. Look for `iCloud.com.headydiscy.reczipes`
4. If it doesn't exist:
   - Click **+** to create new container
   - Enter identifier: `iCloud.com.headydiscy.reczipes`
   - Save

### Issue 2: "No iCloud account" Error

**Symptom:**
```
CKAccountStatus: noAccount
```

**Cause:** Device not signed into iCloud

**Fix:**
1. Device Settings → Tap name at top
2. Sign in with Apple ID
3. Enable iCloud Drive

### Issue 3: "Permission denied" Error

**Symptom:**
```
CloudKit error: Permission failure
```

**Cause:** App not properly signed or entitlements missing

**Fix:**
1. Verify Signing & Capabilities has your Team selected
2. Verify entitlements file exists and is correct
3. Clean build folder and rebuild

### Issue 4: Still Falling Back to Local Mode

**Symptom:**
App works but Settings shows "CloudKit Not Active"

**Cause:** One of these:
- Entitlements not applied to build
- Container name typo
- Device not signed into iCloud

**Fix:**
1. Check console logs for specific error
2. Verify exact container name: `iCloud.com.headydiscy.reczipes` (no capitals, no spaces)
3. Verify device iCloud settings
4. Try on a different device to rule out device-specific issues

---

## Verification Checklist

Use this to verify everything is set up correctly:

### In Xcode:
- [ ] iCloud capability is present
- [ ] CloudKit is checked
- [ ] Container `iCloud.com.headydiscy.reczipes` is in the list and checked
- [ ] Entitlements file exists with correct keys
- [ ] Clean build succeeds without errors

### On Device:
- [ ] Signed into iCloud (Settings → Your Name)
- [ ] iCloud Drive is ON
- [ ] Device has internet connection

### In App:
- [ ] Console shows "✅ ModelContainer created successfully with CloudKit sync enabled"
- [ ] Settings → CloudKit Diagnostics shows "CloudKit Enabled: Yes"
- [ ] Can create recipes
- [ ] Recipes sync to other devices (wait 5-10 minutes)

---

## Testing Multi-Device Sync

Once CloudKit is working on one device:

### Setup:
1. Install app on Device 1 (iPhone)
2. Install app on Device 2 (iPad)
3. **Both devices must use the same Apple ID**
4. Both devices must be signed into iCloud
5. Both devices must have iCloud Drive enabled

### Test:
1. On Device 1: Create a new recipe called "Test Sync"
2. Wait 5 minutes
3. On Device 2: Pull to refresh recipe list
4. Recipe "Test Sync" should appear

### Expected Behavior:
- ✅ New recipes sync within 5-10 minutes
- ✅ Edits to recipes sync
- ✅ Deleted recipes sync (may take longer)
- ✅ Recipe images sync

### If Sync Doesn't Work:
1. Check both devices are signed into same Apple ID
2. Check both devices have iCloud Drive enabled
3. Check both devices have network connection
4. Force close app and reopen
5. Check CloudKit Dashboard for sync activity

---

## Important Notes

### Container Name:
- **Must use:** `iCloud.com.headydiscy.reczipes`
- **Cannot use:** `.automatic` (would create different container)
- **Why:** Your existing data is in this specific container

### Bundle ID:
- Your bundle ID can be anything (e.g., `com.headydiscy.Reczipes2`)
- Container name does NOT have to match bundle ID
- They are separate identifiers

### Data Safety:
- Existing local data is preserved when CloudKit is enabled
- No need to delete app
- First sync uploads local data to iCloud
- Other devices download and merge data

### Testing:
- Always test on real devices, not just simulator
- Simulator can have iCloud issues
- Use TestFlight for beta testing

---

## Visual Guide

Here's what you should see in Xcode:

```
┌─────────────────────────────────────────┐
│ Signing & Capabilities                  │
├─────────────────────────────────────────┤
│                                         │
│ 📦 iCloud                               │
│    ☑ CloudKit                           │
│    ☐ CloudKit and Core Data (legacy)   │
│    ☐ iCloud Drive                       │
│    ☐ iCloud Documents                   │
│                                         │
│    Containers:                          │
│    ☑ iCloud.com.headydiscy.reczipes     │
│        └─ [+] [-]                       │
│                                         │
└─────────────────────────────────────────┘
```

The container should be:
- ✅ Listed under "Containers"
- ✅ Checked (enabled)
- ✅ Exact spelling: `iCloud.com.headydiscy.reczipes`

---

## Next Steps After Setup

Once CloudKit is working:

1. **Test thoroughly** on multiple devices
2. **Monitor CloudKit Dashboard** for sync activity
3. **Set up TestFlight** for beta testing
4. **Enable CloudKit Development environment** for testing
5. **Deploy schema to Production** before App Store release

---

## Getting Help

If you're still stuck:

### Check Console Logs:
Run the app and look for CloudKit-related messages. Copy them for debugging.

### Use Built-In Diagnostics:
1. Open app
2. Go to Settings
3. Look for "CloudKit Diagnostics" or "Persistent Container Info"
4. Tap to see detailed status

### Common Error Messages:

| Error | Meaning | Fix |
|-------|---------|-----|
| `CKAccountStatus: noAccount` | Not signed into iCloud | Sign in to iCloud on device |
| `Container doesn't exist` | Container not in entitlements | Add to Xcode capabilities |
| `Permission failure` | Entitlements issue | Check entitlements file |
| `Network error` | No internet | Check device connectivity |
| `Schema error` | Model incompatibility | Already fixed in `CLOUDKIT_SCHEMA_FIX.md` |

---

## Summary

**Required Setup:**
1. Xcode: Add iCloud capability with CloudKit
2. Xcode: Add container `iCloud.com.headydiscy.reczipes`
3. Verify entitlements file is correct
4. Device: Sign into iCloud with iCloud Drive enabled
5. Test and verify sync works

**Result:**
- ✅ CloudKit sync enabled
- ✅ Recipes sync across devices
- ✅ Users see "CloudKit Enabled: Yes" in Settings

