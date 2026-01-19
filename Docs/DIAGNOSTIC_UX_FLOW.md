# Diagnostic System - User Experience Flow

## The Problem (Before)

**Scenario:** User's iCloud sync stops working

### What the user saw before:
```
[Console logs - user never sees these]
2026-01-19 14:23:45 ERROR: CloudKit container unavailable
2026-01-19 14:23:45 WARNING: Falling back to local storage
2026-01-19 14:23:46 INFO: ModelContainer recreated
```

**User experience:**
- 😕 No idea sync stopped
- 🤷‍♀️ Doesn't know why recipes aren't syncing
- 📧 Has to email support with "my recipes aren't syncing"
- ⏰ Waits for support response
- 😤 Frustrated experience

---

## The Solution (After)

### Visual Flow

```
┌─────────────────────────────────────────────────────┐
│  Settings                                      [⚙️]  │
├─────────────────────────────────────────────────────┤
│                                                      │
│  👤  Profile                                    →    │
│  🥜  Allergens                                  →    │
│                                                      │
│  Developer                                           │
│  🩺  Diagnostics                               ①    │  ← Badge shows "1"
│                                                      │
└─────────────────────────────────────────────────────┘
              ↓ User taps
┌─────────────────────────────────────────────────────┐
│  ← Diagnostics                              [...]   │
├─────────────────────────────────────────────────────┤
│  [Issues] [All Events] [Active]              ← Tabs │
├─────────────────────────────────────────────────────┤
│  [All] [☁️ CloudKit] [💾 Storage] [🌐 Network]      │  ← Category filters
├─────────────────────────────────────────────────────┤
│                                                      │
│  ⚠️  iCloud Sync Unavailable                    ˅   │  ← Expandable
│  2:23 PM                                             │
│                                                      │
│  You're not signed into iCloud. Your recipes        │
│  are saved locally.                                  │
│                                                      │
│  ⓘ Technical Details                                │
│  ┌────────────────────────────────────────────┐     │
│  │ CloudKit status: noAccount                 │     │
│  └────────────────────────────────────────────┘     │
│                                                      │
│  💡 Suggested Actions                               │
│                                                      │
│  ┌────────────────────────────────────────────┐     │
│  │ ⚙️  Sign Into iCloud               →       │  ← Tappable action
│  │     Go to Settings > [Your Name]           │
│  └────────────────────────────────────────────┘     │
│                                                      │
└─────────────────────────────────────────────────────┘
              ↓ User taps action
┌─────────────────────────────────────────────────────┐
│  Settings                                            │  ← Opens iOS Settings
│                                                      │
│  👤  Zahir's iPhone                                  │
│      iCloud, Media & Purchases                       │
│                                                      │
│      Sign in to your iPhone                          │
│                                                      │
│      [Continue with password]                        │
│                                                      │
└─────────────────────────────────────────────────────┘
              ↓ User signs in
              ↓ Returns to app
┌─────────────────────────────────────────────────────┐
│  ← Diagnostics                              [...]   │
├─────────────────────────────────────────────────────┤
│  [Issues] [All Events] [Active]                     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ℹ️  iCloud Sync Enabled                        ✓   │  ← New event, marked resolved
│  2:28 PM                                             │
│                                                      │
│  Your recipes will now sync across all your          │
│  devices.                                            │
│                                                      │
│  💡 Suggested Actions                               │
│                                                      │
│  ┌────────────────────────────────────────────┐     │
│  │ ⏳  Wait for Sync                   →       │
│  │     It may take a few moments for all      │
│  │     your data to sync                      │
│  └────────────────────────────────────────────┘     │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## Alternative Access Methods

### 1. Shake to Show (iOS)
```
┌─────────────────────────────────────────────────────┐
│  Recipes                                             │
│                                                      │
│  📖  Thai Curry                                      │
│  📖  Pasta Carbonara                                 │
│  📖  Chocolate Cake                                  │
│                                                      │
│          [User shakes device] 📱↔️                   │
│                    ↓                                 │
│          [Diagnostics view appears]                  │
└─────────────────────────────────────────────────────┘
```

### 2. Floating Button
```
┌─────────────────────────────────────────────────────┐
│  Recipes                                             │
│                                                      │
│  📖  Thai Curry                                      │
│  📖  Pasta Carbonara                                 │
│  📖  Chocolate Cake                                  │
│                                                      │
│                                                      │
│                                                      │
│                                        ┌──────┐     │
│                                        │ 🩺 1 │ ← Floating button
│                                        └──────┘     │
└─────────────────────────────────────────────────────┘
```

### 3. Toolbar Button
```
┌─────────────────────────────────────────────────────┐
│  ← Recipes                    [🩺¹] [+] [•••]      │
│                                  ↑                   │
│                            Badge shows               │
│                            1 failure                 │
└─────────────────────────────────────────────────────┘
```

---

## Export for Support

```
┌─────────────────────────────────────────────────────┐
│  ← Diagnostics                              [...]   │
│                                                      │
│                   Menu opened:                       │
│                  ┌──────────────────────┐           │
│                  │ 📤 Export Report     │  ← Tap    │
│                  ├──────────────────────┤           │
│                  │ ✓  Clear Resolved    │           │
│                  │ 🗑️  Clear All         │           │
│                  └──────────────────────┘           │
└─────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────┐
│  Share                                               │
│                                                      │
│  Reczipes Diagnostic Report                          │
│  Generated: January 19, 2026 at 2:30 PM             │
│  ═══════════════════════════════════════            │
│                                                      │
│  SUMMARY                                             │
│  ───────                                             │
│  Total Events: 5                                     │
│  Critical: 0                                         │
│  Errors: 0                                           │
│  Warnings: 1                                         │
│  Info: 4                                             │
│  ...                                                 │
│                                                      │
│  [📧 Mail] [💬 Messages] [📋 Copy]                  │
└─────────────────────────────────────────────────────┘
```

---

## Comparison Table

| Aspect | Before | After |
|--------|--------|-------|
| **User Awareness** | ❌ No idea problems exist | ✅ Clear notification with badge |
| **Understanding** | ❌ Cryptic error codes | ✅ Plain English explanations |
| **Next Steps** | ❌ "Contact support" | ✅ Specific, actionable steps |
| **Self-Service** | ❌ Can't fix anything | ✅ Can resolve most issues |
| **Support Quality** | ❌ "It's broken" emails | ✅ Complete diagnostic reports |
| **Developer Insight** | ❌ No visibility | ✅ See patterns in failures |
| **Technical Details** | ❌ Lost in logs | ✅ Available but hidden by default |
| **Resolution** | ❌ Unknown if fixed | ✅ Events marked as resolved |

---

## Real-World Scenarios

### Scenario 1: No Internet Connection

**User tries to extract recipe from website**

```
🔴 Network Error

Couldn't complete recipe extraction due to a 
network issue.

💡 Suggested Actions:

→ Check Your Connection
  Make sure you're connected to Wi-Fi or cellular
  
→ Try Again
  Retry the operation once you're back online
```

### Scenario 2: Storage Almost Full

**App detects low storage during save**

```
⚠️ Low Storage Space

Your device is running low on storage space. 
Recipes are still being saved, but performance 
may be affected.

💡 Suggested Actions:

→ Check Available Storage
  Make sure your device has enough free space
  
→ Clear Cache
  Free up space by clearing temporary files
```

### Scenario 3: CloudKit Sharing Failure

**User tries to share recipe, but CloudKit is restricted**

```
🔴 Sharing Failed

Can't share recipes because iCloud is restricted 
on this device.

💡 Suggested Actions:

→ Check Restrictions
  Go to Settings > Screen Time > Content & Privacy
  
→ Contact Support
  If you need help with this issue
```

### Scenario 4: Successful Operation

**Recipe successfully imported**

```
ℹ️ Recipe Imported

Successfully extracted recipe from AllRecipes.com.

✓ Added "Thai Basil Chicken" to your collection
```

---

## Benefits Summary

### For Users
- 🎯 **Know what's wrong** in plain English
- 🔧 **Fix it themselves** with guided steps  
- 🚀 **Stay productive** without waiting for support
- 💡 **Learn** about app functionality
- ✅ **See progress** as issues resolve

### For You (Developer)
- 📉 **Fewer support emails** - users self-serve
- 🐛 **Better bug reports** - complete diagnostics
- 📊 **Usage insights** - see common issues
- ⚡ **Faster debugging** - all context in one place
- 😊 **Happier users** - feel empowered, not frustrated

### For Support Team
- 📧 **Complete context** in reports
- ⏱️ **Faster resolution** - no back-and-forth
- 📚 **Knowledge base** - see common issues
- 🎯 **Better priorities** - see severity levels

---

## Next Steps

1. **Add `.diagnosticsCapable()` to your app** (1 minute)
2. **Add a DiagnosticButton somewhere** (2 minutes)  
3. **Test with a shake gesture** (instant gratification! 🎉)
4. **Start converting log messages** (ongoing improvement)

See `DiagnosticIntegrationGuide.swift` and `DiagnosticQuickReference.swift` for complete examples!
