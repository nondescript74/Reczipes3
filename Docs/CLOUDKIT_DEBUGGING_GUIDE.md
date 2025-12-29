# CloudKit Recipe Sync Debugging Guide

## Problem: Recipes Don't Appear on a Different Device

This guide will help you debug why recipes created on one device aren't appearing on another device.

---

## 🔍 Quick Diagnostic Checklist

Before diving deep, verify these basics:

- [ ] Both devices signed into the **same Apple ID**
- [ ] iCloud Drive **enabled** on both devices
- [ ] **Network connectivity** on both devices
- [ ] App **installed from the same source** (both TestFlight, or both App Store)
- [ ] **Wait 5-10 minutes** after creating a recipe for initial sync

---

## 🛠️ Step-by-Step Debugging Process

### Step 1: Check iCloud Account Status

On **both devices**, open the app and navigate to:
**Settings → CloudKit Diagnostics → Run Full Diagnostics**

Look for:

✅ **Good Signs:**
```
✅ iCloud Account: Signed in and available
✅ CloudKit Container Access: Container accessible
✅ Network Connectivity: Connected to iCloud servers
```

❌ **Problem Signs:**
```
❌ iCloud Account: Sign in to iCloud to sync across devices
❌ CloudKit Container Access: Container not accessible
❌ Network Connectivity: Cannot reach iCloud
```

### Step 2: Check Console Logs

When launching the app, check the Xcode console or device logs for:

#### ✅ Successful CloudKit Setup:
```
✅ ModelContainer created successfully with CloudKit sync enabled
   Container: iCloud.com.headydiscy.reczipes
   Automatic lightweight migration enabled for schema changes
```

#### ❌ CloudKit Failure (Falls back to local):
```
⚠️ CloudKit ModelContainer creation failed: [error details]
   Attempting fallback to local-only container...
✅ ModelContainer created successfully (local-only, no CloudKit sync)
```

**If you see the second message**, CloudKit is NOT working on that device.

### Step 3: Verify Container Configuration

#### Check 1: Bundle Identifier
Your app's bundle identifier should be: `com.headydiscy.Reczipes2` (or similar)

#### Check 2: CloudKit Container
The container identifier is: `iCloud.com.headydiscy.reczipes`

This should match the pattern: `iCloud.` + `com.headydiscy.reczipes`

#### Check 3: Entitlements File
Your `Reczipes2.entitlements` should contain:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.headydiscy.reczipes</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

#### Check 4: CloudKit Dashboard
Go to: https://icloud.developer.apple.com/dashboard/

- [ ] Container `iCloud.com.headydiscy.reczipes` exists
- [ ] You're logged in with the correct Apple Developer account
- [ ] Schema is deployed (this happens automatically with SwiftData)

### Step 4: Check Recipe Count on Both Devices

Navigate to: **Settings → CloudKit Diagnostics**

Compare the **"Local Data"** section on both devices:
- Device A (where you created recipes): Shows recipe count
- Device B (where recipes don't appear): Should eventually show same count

**If counts differ after 10 minutes**, sync is not working.

---

## 🚨 Common Issues and Solutions

### Issue 1: "No iCloud Account"

**Symptom:** 
```
⚠️ No iCloud account found
```

**Solution:**
1. Open Settings app on the device
2. Sign in with your Apple ID at the top
3. Enable iCloud Drive
4. Restart the app

### Issue 2: Different Apple IDs

**Symptom:** One device has recipes, other doesn't, both say CloudKit is working

**Solution:**
1. Verify SAME Apple ID on both devices
2. Go to Settings → [Your Name] at top
3. Make sure the email addresses match exactly

### Issue 3: Container Identifier Mismatch

**Symptom:**
```
❌ CloudKit Container Access: Container not accessible
```

**Solution:**

The container `iCloud.com.headydiscy.reczipes` may not match your Apple Developer account.

**Option A:** Change to automatic container (recommended):

In `Reczipes2App.swift`, change line 44:
```swift
cloudKitDatabase: .private("iCloud.com.headydiscy.reczipes")
```
to:
```swift
cloudKitDatabase: .automatic
```

**Option B:** Create the container in CloudKit Dashboard:
1. Go to https://icloud.developer.apple.com/dashboard/
2. Click **+ New Container**
3. Name it: `iCloud.com.headydiscy.reczipes`
4. Ensure it's linked to your app's bundle ID

### Issue 4: Simulator vs Device

**Symptom:** Works in Simulator but not on device (or vice versa)

**Solution:**
- Simulator and physical devices may use different iCloud accounts
- Simulator: Check Settings in the simulator
- Device: Check Settings on the physical device
- Ensure both use the same Apple ID

### Issue 5: Development vs Production CloudKit Environment

**Symptom:** Works in Xcode but not in TestFlight/App Store

**Solution:**
- Development builds use CloudKit Development environment
- TestFlight/App Store use Production environment
- Data doesn't sync between environments
- You must deploy schema to production in CloudKit Dashboard

### Issue 6: Network Issues

**Symptom:**
```
❌ Network Connectivity: Cannot reach iCloud
```

**Solution:**
1. Check Wi-Fi/cellular connection
2. Turn off VPN if enabled
3. Check if other iCloud services work (Photos, Notes)
4. Try toggling iCloud Drive off and on

### Issue 7: Private Relay Interference

**Symptom:** Intermittent sync issues, works sometimes

**Solution:**
1. Go to Settings → [Your Name] → iCloud → Private Relay
2. Temporarily disable to test
3. If this fixes it, there may be network configuration issues

---

## 🧪 Testing Sync Manually

### Test 1: Create a Recipe on Device A

1. Open app on Device A
2. Create a new recipe (e.g., "Sync Test Recipe")
3. Save it
4. Note the time

### Test 2: Wait and Check Device B

1. Wait **5-10 minutes** (initial sync can be slow)
2. Open app on Device B
3. Pull to refresh on the recipe list
4. Check if "Sync Test Recipe" appears

### Test 3: Force Sync Check

On Device B:
1. Go to Settings → CloudKit Diagnostics
2. Tap **"Force Sync Check"**
3. Check console logs for sync activity

---

## 📊 Understanding Sync Timing

CloudKit sync is **not instant**. Here's what to expect:

| Scenario | Expected Time |
|----------|--------------|
| First sync ever | 5-10 minutes |
| Normal sync | 30 seconds - 2 minutes |
| Large dataset | 10-20 minutes |
| Background sync | Can take hours |

**Important:** CloudKit syncs more aggressively when:
- App is in foreground
- Device is on Wi-Fi
- Device is charging

---

## 🔧 Advanced Debugging

### Enable CloudKit Debug Logging

Add to your scheme's environment variables:
```
-com.apple.coredata.cloudkit.debug 1
```

This will show detailed CloudKit sync logs in the console.

### Check CloudKit Activity in Console

1. Open Console.app on Mac
2. Connect your iOS device
3. Filter for: `cloudkit` or `swiftdata`
4. Look for error messages

### Reset CloudKit Container (Nuclear Option)

⚠️ **WARNING: This deletes all synced data**

1. Go to CloudKit Dashboard
2. Select your container
3. Development → Reset Development Environment
4. Reinstall app on all devices

---

## 📝 Data to Collect for Support

If issues persist, collect this information:

1. **Device Information:**
   - Device model
   - iOS version
   - App version

2. **CloudKit Diagnostics:**
   - Run diagnostics on both devices
   - Tap "Copy Diagnostics to Clipboard"
   - Save the output

3. **Console Logs:**
   - Launch app with Xcode attached
   - Copy all logs starting with ✅, ⚠️, or ❌
   - Include any CloudKit-related errors

4. **Container Information:**
   - Bundle ID
   - Container ID
   - Apple ID used for testing

---

## ✅ Success Indicators

You'll know sync is working when:

1. ✅ Both devices show "iCloud sync is active" in Settings
2. ✅ Recipe counts match on both devices
3. ✅ Console shows "ModelContainer created successfully with CloudKit sync enabled"
4. ✅ Creating a recipe on one device appears on the other within 2-5 minutes
5. ✅ No error messages in CloudKit Diagnostics

---

## 🎯 Quick Fixes Summary

1. **Verify same Apple ID on both devices**
2. **Enable iCloud Drive on both devices**
3. **Wait 5-10 minutes for initial sync**
4. **Check network connectivity**
5. **Run CloudKit Diagnostics on both devices**
6. **Look for console error messages**
7. **Consider using `.automatic` for container**

---

## 📚 Additional Resources

- [CloudKit Setup Guide](./CLOUDKIT_SETUP_GUIDE.md)
- [CloudKit Sync Guide](./CLOUDKIT_SYNC_GUIDE.md)
- [Quick Fix Guide](./QUICK_FIX_CLOUDKIT.md)
- [Apple's CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [SwiftData Sync Documentation](https://developer.apple.com/documentation/swiftdata/syncing-data-across-devices-with-swiftdata-and-cloudkit)

---

## 💡 Key Insights

### Why Sync Might Be Slow

SwiftData with CloudKit uses a sophisticated syncing mechanism:

1. **Change Detection:** SwiftData tracks changes to your models
2. **Batching:** Changes are batched together for efficiency
3. **Network Optimization:** Sync happens when network is available
4. **Conflict Resolution:** Handles conflicts automatically
5. **Privacy:** All data is encrypted end-to-end

### Common Misconceptions

❌ **"Sync should be instant"**
✅ CloudKit sync can take several minutes, especially initially

❌ **"I need to trigger sync manually"**
✅ SwiftData handles sync automatically

❌ **"Data syncs between Development and Production"**
✅ These are completely separate environments

❌ **"I can use different Apple IDs"**
✅ Sync only works with the same Apple ID

---

## 🎬 Next Steps

1. Run the diagnostics tool on both devices
2. Compare the results
3. Follow the specific issue solutions above
4. Wait appropriate time for sync
5. Report findings if issues persist

Good luck debugging! 🚀
