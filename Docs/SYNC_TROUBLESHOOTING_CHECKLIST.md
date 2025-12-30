# CloudKit Sync Troubleshooting Checklist

## 🎯 Quick Reference - Use This When Helping Users

---

## Step 1: Quick Sync Check (2 minutes)

### On BOTH iPads:
1. Open app
2. Go to **Settings → Quick Sync Check** ⭐
3. Take a screenshot or note down:

**iPad A (Source - 192 recipes):**
```
✅ Status: Ready / Not Ready
📚 Recipes: ____
🔑 User ID: ____________...
👤 Account: ✅ Signed In / ❌ Not Signed In
```

**iPad B (Empty):**
```
✅ Status: Ready / Not Ready
📚 Recipes: ____
🔑 User ID: ____________...
👤 Account: ✅ Signed In / ❌ Not Signed In
```

### ⚠️ CRITICAL CHECK:
**Do the User IDs match?**
- [ ] YES → Continue to Step 2
- [ ] NO → Go to "Fix: Different Apple IDs" below

---

## Step 2: Verify Account Settings (3 minutes)

### On BOTH iPads:

1. **Check Apple ID:**
   - Settings → [Name at top]
   - Both show: __________________ (same email?)
   - [ ] YES, same email
   - [ ] NO, different emails

2. **Check iCloud Drive:**
   - Settings → [Name] → iCloud → iCloud Drive
   - [ ] ON for both iPads

3. **Check iCloud Storage:**
   - Settings → [Name] → iCloud
   - Available storage: _______
   - [ ] Has at least 500 MB free

---

## Step 3: Verify App Build Source (2 minutes)

### BOTH iPads must have app from SAME source:

**Check how app was installed:**
- [ ] Both from Xcode (Development)
- [ ] Both from TestFlight (Production)
- [ ] Both from App Store (Production)
- [ ] ⚠️ MIXED (one Xcode, one TestFlight) ← THIS WON'T WORK!

---

## Step 4: Start Sync Monitor (30 minutes)

### On Source iPad (192 recipes):
1. Settings → Sync Monitor
2. Keep this screen open
3. Plug into power
4. Stay on Wi-Fi
5. **Wait 20-30 minutes** without switching apps

### On Empty iPad:
1. Settings → Sync Monitor  
2. Keep this screen open
3. Watch the Activity Log
4. Look for: "✅ Downloaded X new recipe(s)"

---

## Step 5: Monitor Progress

### What You Should See:

**Source iPad Activity Log:**
```
ℹ️ Monitor started
ℹ️ Status refreshed: 192 recipes
[May be quiet for 20 minutes while uploading]
```

**Empty iPad Activity Log:**
```
ℹ️ Monitor started
ℹ️ Status refreshed: 1 recipe
[After 20-30 minutes:]
🔄 Remote data change detected
✅ Downloaded 10 new recipe(s)
✅ Downloaded 15 new recipe(s)
✅ Downloaded 12 new recipe(s)
[Continues until reaching 192]
```

---

## Common Issues & Fixes

### ❌ Issue: User IDs Don't Match

**Cause:** Different Apple IDs on each iPad

**Fix:**
1. Settings → [Name at top] → Sign Out (on one iPad)
2. Sign back in with the SAME Apple ID as other iPad
3. Enable iCloud Drive
4. Restart app on both iPads
5. Wait 5 minutes, then check Quick Sync Check again

---

### ❌ Issue: Not Signed Into iCloud

**Status shows: "❌ Not Signed In"**

**Fix:**
1. Settings app → Sign in at top
2. Use Apple ID credentials
3. Enable iCloud Drive
4. Restart app
5. Check Quick Sync Check again

---

### ❌ Issue: Mixed App Builds

**One iPad from Xcode, other from TestFlight**

**Fix:**
- Install app from SAME source on both iPads
- Recommended: Both from Xcode for testing
- Or: Both from TestFlight for production testing

---

### ⚠️ Issue: Sync Taking Too Long

**After 30 minutes, still no progress**

**Check:**
1. Is source iPad app in FOREGROUND?
   - [ ] YES → Check network
   - [ ] NO → Bring to foreground, wait another 20 min

2. Is Wi-Fi connected and stable?
   - [ ] YES → Check iCloud status
   - [ ] NO → Connect to Wi-Fi, wait 20 min

3. Any errors in Sync Monitor Activity Log?
   - [ ] NO errors → Just need more time
   - [ ] YES errors → Copy to clipboard and investigate

---

### ⚠️ Issue: Some Recipes Synced, Then Stopped

**Empty iPad shows X recipes, but not all 192**

**Fix:**
1. On source iPad: Pull down to refresh Sync Monitor
2. On empty iPad: Pull down to refresh Sync Monitor
3. Keep both apps in foreground for 10 more minutes
4. Check if count increases

---

## Advanced Troubleshooting

### If Basic Steps Don't Work:

1. **Run Advanced Diagnostics:**
   - Settings → Advanced Diagnostics
   - Tap "Run Full Diagnostics"
   - Copy results from both iPads
   - Look for specific errors

2. **Check Console Logs:**
   - Connect iPad to Mac with Xcode
   - Run app
   - Filter console for "CloudKit"
   - Look for errors

3. **Verify CloudKit Schema:**
   - https://icloud.developer.apple.com/dashboard/
   - Check that record types exist
   - Verify indexes are queryable

---

## Nuclear Option: Fresh Start

### Only if nothing else works:

1. **On both iPads:**
   - Delete the app completely
   - Settings → General → iPhone/iPad Storage
   - Find app → Delete App (removes all data)

2. **Rebuild and reinstall:**
   - Install fresh copy from Xcode on both
   - Sign into same Apple ID on both
   - Launch source iPad first
   - Keep in foreground for 30 minutes
   - Then launch empty iPad
   - Keep in foreground for 30 minutes

---

## Success Indicators

### ✅ You know sync is working when:

1. **User IDs match** on both iPads
2. **Activity log shows** download messages on empty iPad
3. **Recipe count increases** on empty iPad
4. **Test recipe** created on one iPad appears on other within 5 minutes
5. **No error messages** in Activity Log

---

## Testing Sync Is Working

### Quick Test (5 minutes):

1. **On empty iPad:**
   - Create new recipe: "SYNC TEST - [current time]"
   - Save it

2. **Wait 2-3 minutes**

3. **On source iPad:**
   - Pull to refresh recipe list
   - Search for "SYNC TEST"
   - **Found?** → Sync works! ✅
   - **Not found?** → Continue troubleshooting

---

## Timing Expectations

| Scenario | Expected Time |
|----------|--------------|
| Quick Sync Check | 30 seconds |
| Verify settings | 3 minutes |
| Source iPad upload (192 recipes) | 20-30 minutes |
| Empty iPad download (192 recipes) | 15-20 minutes |
| Test recipe sync | 2-5 minutes |
| Image sync (after recipes) | 30-60 minutes |

**Total initial sync:** 45-60 minutes with both apps in foreground

---

## Tools You Have

1. **Quick Sync Check** ⭐
   - Fast status overview
   - User ID verification
   - Recipe counts

2. **Sync Monitor**
   - Real-time activity log
   - Detailed status
   - Copy to clipboard

3. **Advanced Diagnostics**
   - Technical details
   - Network tests
   - Container access checks

**Use Quick Sync Check for 90% of cases!**

---

## When to Escalate

Contact developer (yourself) if:
- [ ] User IDs match but no sync after 1 hour
- [ ] All settings correct but sync not starting
- [ ] Error messages in Activity Log you don't understand
- [ ] CloudKit container issues
- [ ] Schema problems

---

## Quick Decision Tree

```
Start
  │
  ├─ User IDs match?
  │   ├─ NO → Fix: Sign in with same Apple ID
  │   └─ YES → Continue
  │
  ├─ Both signed into iCloud?
  │   ├─ NO → Fix: Sign in to iCloud
  │   └─ YES → Continue
  │
  ├─ Same build source?
  │   ├─ NO → Fix: Install from same source
  │   └─ YES → Continue
  │
  ├─ Waited 30+ minutes?
  │   ├─ NO → Fix: Wait longer, keep in foreground
  │   └─ YES → Continue
  │
  ├─ Any errors in Activity Log?
  │   ├─ YES → Fix: Address specific error
  │   └─ NO → Continue
  │
  └─ Nuclear option: Fresh install
```

---

## Summary

**Most common issues (90% of cases):**
1. ❌ Different Apple IDs → User IDs don't match
2. ⏳ Not enough time → Need 30+ minutes
3. 📱 App in background → Need foreground
4. 📡 Poor network → Need stable Wi-Fi

**The tools make it easy:**
- Quick Sync Check shows the problem in seconds
- Sync Monitor shows progress in real-time
- No Xcode needed!

**Your job is simple:**
1. Open Quick Sync Check on both iPads
2. Verify User IDs match
3. If yes: Wait 30 minutes
4. If no: Fix Apple ID issue

That's it! 🎉
