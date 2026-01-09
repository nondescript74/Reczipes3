# Quick Bundle ID Change Checklist
## Build 74 - com.headydiscy.reczipes2

---

## 🚀 Immediate Actions (Do These Now)

### 1. Apple Developer Portal - Register New App ID
**Link:** https://developer.apple.com/account/resources/identifiers/list

- [ ] Click **+** to add identifier
- [ ] Select **App IDs** → **App** → Continue
- [ ] Description: `Reczipes2`
- [ ] Bundle ID: `com.headydiscy.reczipes2` (Explicit)
- [ ] Capabilities → Check **iCloud** ☑️
- [ ] iCloud: Include CloudKit support
- [ ] Register

### 2. Verify Container Association
**Link:** https://icloud.developer.apple.com/dashboard/

- [ ] Open container: `iCloud.com.headydiscy.reczipes`
- [ ] Verify it exists
- [ ] It will auto-associate with new bundle ID on first run

### 3. Check App Store Connect
**Link:** https://appstoreconnect.apple.com/

- [ ] Go to **My Apps**
- [ ] You should see new app: **Reczipes2**
- [ ] Go to **TestFlight** tab
- [ ] Find **Build 74**
- [ ] Wait for status: **Ready to Test**
- [ ] ⏱️ This can take 5-30 minutes

---

## 📱 Testing (After Build 74 is Ready)

### On Each Test Device:

#### Step 1: Clean Slate
- [ ] **Delete old app completely** (`ImageExtract` or old versions)
- [ ] Open **Settings** → Your Name → **iCloud**
- [ ] Verify signed in with correct Apple ID

#### Step 2: Install New Build
- [ ] Open **TestFlight** app
- [ ] Find new **Reczipes2** app
- [ ] Check build number: **74** or higher
- [ ] Tap **Install**

#### Step 3: Verify Installation
- [ ] Launch app
- [ ] Go to **Settings** in app
- [ ] Tap **Validate CloudKit Container**
- [ ] Tap **Run Validation**

#### Step 4: Expected Results
Should see:
```
✅ All checks passed - CloudKit should work!

📦 Container ID: iCloud.com.headydiscy.reczipes
    Bundle ID: com.headydiscy.reczipes2  ← VERIFY THIS

🗄️  Container accessible: ✅
    User Record ID: _[alphanumeric]

🔐 Entitlements cannot be read at runtime...
    💡 Container access works → Entitlements are correct ✅
```

Should **NOT** see:
- ❌ Bundle ID: com.headydiscy.ImageExtract
- ❌ CloudKit not enabled in entitlements
- ❌ Container not listed in entitlements
- ❌ Debug messages about "embedded entitlements"

#### Step 5: Data Verification
- [ ] Check recipes list
- [ ] Verify existing data synced from CloudKit
- [ ] Create a test recipe
- [ ] Verify it syncs to other devices

---

## 🔍 Troubleshooting

### If App Store Connect doesn't show Build 74:
1. Check Xcode Cloud workflow status
2. Build might still be processing
3. Check for upload errors in Xcode Cloud logs

### If Validator Shows Old Bundle ID:
1. You're running the old app - delete it
2. Make sure you installed from TestFlight
3. Check build number in Settings → About

### If "Container not found" error:
1. Go to Apple Developer Portal
2. Edit `com.headydiscy.reczipes2` identifier
3. Make sure iCloud is enabled
4. Make sure CloudKit is checked

### If Data Doesn't Appear:
1. Check you're signed into correct iCloud account
2. Wait 1-2 minutes for initial sync
3. Pull to refresh in recipes list
4. Check CloudKit Dashboard has data

---

## ✅ Success Criteria

You're done when:

- ✅ Build 74 appears in TestFlight as "Ready to Test"
- ✅ App installs successfully on test devices
- ✅ Validator shows `com.headydiscy.reczipes2` bundle ID
- ✅ Validator shows "✅ All checks passed"
- ✅ No false entitlements errors
- ✅ Existing data syncs and appears
- ✅ New recipes can be created and sync

---

## 📊 Quick Status Check

Current status (fill this in):

- [ ] Build 74 uploaded to App Store Connect
- [ ] Build 74 status: ⏱️ Processing / ✅ Ready to Test
- [ ] App ID registered in Developer Portal
- [ ] Tested on iPhone
- [ ] Tested on iPad  
- [ ] Tested on [other device]
- [ ] All validators show clean results
- [ ] Data syncing works

---

## 🎯 What Changed

| Item | Old | New |
|------|-----|-----|
| **Bundle ID** | com.headydiscy.ImageExtract | com.headydiscy.reczipes2 |
| **App Store** | Old app entry | New app entry |
| **Container** | iCloud.com.headydiscy.reczipes | iCloud.com.headydiscy.reczipes (SAME) |
| **Build** | 1-73 | 74+ |
| **Data** | In CloudKit | In CloudKit (SAME) |

**Key Point:** Same CloudKit container = same data accessible by new bundle ID!

---

## 📝 Notes

- The old `ImageExtract` app and new `Reczipes2` app are completely separate apps in App Store Connect
- They can coexist but share the same CloudKit data
- Users need to install the new app - it won't auto-update from old app
- Eventually you may want to deprecate the old app

---

**Created:** January 9, 2026  
**Build:** 74  
**Status:** Ready for testing after TestFlight processing completes

