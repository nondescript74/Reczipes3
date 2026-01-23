# Ghost Data Cleanup - User Flow Guide

## Visual Overview

This guide shows the complete user experience for detecting and cleaning up ghost/orphaned data in CloudKit.

---

## UI Location

```
Settings
  └─ Sharing & Community
       └─ Quick Actions Section
            ├─ Diagnostic & Cleanup Tools - Recipes
            │    ├─ Clean Up Ghost Recipes
            │    └─ Sync Recipe Sharing Status
            ├─ Diagnostic & Cleanup Tools - Recipe Books
            │    ├─ Clean Up Ghost Recipe Books
            │    └─ Sync Recipe Book Sharing Status
            └─ Community Sync
                 ├─ Sync Community Books
                 └─ Sync Community Recipes
```

---

## Problem: User Can't See Orphaned Data

### The Paradox

```
┌─────────────────────────────────────────────────────────────┐
│                    USER A's PERSPECTIVE                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  "My Shared Content"                                         │
│  ┌────────────────────────────────────────┐                 │
│  │ 🧑 My Shared Recipes: 2                │                 │
│  │    • Chocolate Cake                    │                 │
│  │    • Pasta Carbonara                   │                 │
│  └────────────────────────────────────────┘                 │
│                                                              │
│  ❌ Missing: "Apple Pie" & "Banana Bread"                   │
│     (Lost tracking after device switch)                      │
│                                                              │
│  "Browse Shared Recipes"                                     │
│  ┌────────────────────────────────────────┐                 │
│  │ 👥 Community Recipes:                  │                 │
│  │    • Jane's Cookies                    │                 │
│  │    • Bob's Pizza                       │                 │
│  └────────────────────────────────────────┘                 │
│                                                              │
│  ❌ Own recipes filtered out                                 │
│     (Can't see "Apple Pie" & "Banana Bread")                 │
│                                                              │
│  Result: NO WAY TO SEE OR DELETE ORPHANS                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    USER B's PERSPECTIVE                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  "Browse Shared Recipes"                                     │
│  ┌────────────────────────────────────────┐                 │
│  │ 👥 Community Recipes:                  │                 │
│  │    • Jane's Cookies                    │                 │
│  │    • Bob's Pizza                       │                 │
│  │    • User A: Chocolate Cake ✅         │                 │
│  │    • User A: Pasta Carbonara ✅        │                 │
│  │    • User A: Apple Pie 👻 GHOST        │                 │
│  │    • User A: Banana Bread 👻 GHOST     │                 │
│  └────────────────────────────────────────┘                 │
│                                                              │
│  ✅ Can see all of User A's recipes                         │
│  ⚠️ Including the orphaned ones User A can't see!          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Solution: Step-by-Step User Flow

### Step 1: Detect Issues (Sync)

```
User Action:
Settings → Sharing & Community → Quick Actions
  → Tap "Sync Recipe Sharing Status"

┌───────────────────────────────────────────────┐
│  Syncing sharing status...                    │
│  ⏳ Please wait...                            │
└───────────────────────────────────────────────┘

Console Output:
🔄 SYNC: Starting local recipe tracking sync...
🔄 SYNC: Found 4 of my recipes in CloudKit
🔄 SYNC: Found 2 local tracking records
⚠️ 🔄 SYNC: Recipe 'Apple Pie' is in CloudKit but not tracked locally
⚠️ 🔄 SYNC: Recipe 'Banana Bread' is in CloudKit but not tracked locally
🔄 SYNC: Found 2 CloudKit recipes not tracked locally
🔄 SYNC: Found 0 orphaned local tracking records
⚠️ 🔄   Recommendation: Run cleanupGhostRecipes() to remove these
✅ SYNC COMPLETE: Local recipe tracking is now synced
   - Deactivated 0 stale local records
   - Found 2 ghost recipes in CloudKit (need cleanup)

Result Message:
┌───────────────────────────────────────────────┐
│  ✅ Recipe sharing status synced!             │
│  Check Console logs for details.              │
│                                                │
│  [OK]                                          │
└───────────────────────────────────────────────┘
```

### Step 2: Clean Up Ghosts

```
User Action:
Settings → Sharing & Community → Quick Actions
  → Tap "Clean Up Ghost Recipes"

┌───────────────────────────────────────────────┐
│  Cleaning up ghost recipes...                 │
│  ⏳ Please wait...                            │
└───────────────────────────────────────────────┘

Console Output:
👻 GHOST CLEANUP: Starting ghost recipe detection...
👻 Found 4 of my recipes in CloudKit
👻 Found 2 active local tracking records
⚠️ 👻 Found ghost recipe: 'Apple Pie' (ID: abc-123)
⚠️ 👻 Found ghost recipe: 'Banana Bread' (ID: def-456)
👻 Found 2 ghost recipes
👻 Deleting 2 ghost recipes from CloudKit...
👻   Deleted 'Apple Pie'
👻   Deleted 'Banana Bread'
✅ GHOST CLEANUP COMPLETE: Deleted 2 ghost recipes, 0 failures

Result Message:
┌───────────────────────────────────────────────┐
│  ✅ Ghost recipe cleanup complete!            │
│  Check Console logs for details.              │
│                                                │
│  [OK]                                          │
└───────────────────────────────────────────────┘
```

### Step 3: Verify Results

```
User A's View - After Cleanup:
┌─────────────────────────────────────────┐
│  "My Shared Content"                    │
│  ┌──────────────────────────────────┐   │
│  │ 🧑 My Shared Recipes: 2          │   │
│  │    • Chocolate Cake              │   │
│  │    • Pasta Carbonara             │   │
│  └──────────────────────────────────┘   │
│                                          │
│  ✅ Accurately reflects CloudKit state  │
└─────────────────────────────────────────┘

User B's View - After Cleanup:
┌─────────────────────────────────────────┐
│  "Browse Shared Recipes"                │
│  ┌──────────────────────────────────┐   │
│  │ 👥 Community Recipes:            │   │
│  │    • Jane's Cookies              │   │
│  │    • Bob's Pizza                 │   │
│  │    • User A: Chocolate Cake ✅   │   │
│  │    • User A: Pasta Carbonara ✅  │   │
│  │                                  │   │
│  │ ✅ Ghost recipes are gone!       │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

## Same Flow for Recipe Books

The exact same flow works for recipe books:

```
Step 1: Sync Recipe Book Sharing Status
  → Detects orphaned books in CloudKit

Step 2: Clean Up Ghost Recipe Books
  → Deletes orphaned books from CloudKit

Step 3: Verify in Browse Shared Recipe Books
  → Ghost books no longer visible to other users
```

---

## Common Scenarios

### Scenario 1: After Device Switch

```
Timeline:
1. User shares recipes on iPad
2. User switches to iPhone (no local data yet)
3. User opens Settings → Sharing & Community
4. "My Shared Content" shows 0 recipes ❌
5. User runs "Sync Recipe Sharing Status"
6. Sync detects CloudKit recipes without local tracking
7. Choose ONE:
   a) ❌ Run cleanup → Deletes all recipes (BAD!)
   b) ✅ Wait 24h for iCloud sync → Tracking restored (GOOD!)
   c) ✅ Manually verify in Console logs first (GOOD!)
```

**Recommendation:** NEVER run cleanup immediately after device switch!

### Scenario 2: After App Reinstall

```
Timeline:
1. User reinstalls app (local data wiped)
2. CloudKit records still exist
3. User runs "Sync Recipe Sharing Status"
4. Sync detects missing local tracking
5. Wait for iCloud sync or manually re-track
6. Only run cleanup if recipes are truly unwanted
```

### Scenario 3: Regular Maintenance

```
Timeline:
1. User has been using app normally for months
2. Suspects some recipes are orphaned (other users report seeing them)
3. User runs "Sync Recipe Sharing Status"
4. Sync confirms: 2 ghost recipes detected
5. User runs "Clean Up Ghost Recipes"
6. Cleanup deletes the 2 orphaned recipes
7. Other users verify recipes are gone
```

**Recommendation:** Run sync monthly, cleanup only when needed

### Scenario 4: Network Issues Resolved

```
Timeline:
1. User tried to unshare recipes during network outage
2. Local tracking updated, but CloudKit deletion failed
3. Network restored
4. User runs "Sync Recipe Sharing Status"
5. Sync detects: CloudKit has recipes that are marked inactive locally
6. User runs "Clean Up Ghost Recipes"
7. Cleanup successfully removes failed deletions
```

---

## Decision Tree: When to Use Each Tool

```
                    START
                      |
                      v
          ┌──────────────────────────┐
          │ Having issues with       │
          │ shared content?          │
          └──────────┬───────────────┘
                     |
         ┌───────────┴───────────┐
         |                       |
    [DIAGNOSE]              [NO ISSUES]
         |                       |
         v                       v
  "Sync Status"            Continue normally
         |
         v
   Check Console Logs
         |
    ┌────┴────┐
    |         |
[GHOSTS]  [IN SYNC]
    |         |
    v         v
"Clean Up"   Done!
    |
    v
  Verify
    |
    v
  Done!


Detailed Flow:

1. Sync Status
   ├─ Found ghost recipes/books → Proceed to cleanup
   ├─ Found orphaned local records → Auto-fixed
   └─ Everything in sync → Done

2. Clean Up (only after sync)
   ├─ Deletes ghost recipes/books from CloudKit
   ├─ Logs each deletion
   └─ Reports success/failure count

3. Verify
   ├─ Check "My Shared Content" count
   ├─ Ask other users to check browse view
   └─ Run sync again to confirm
```

---

## Safety Checklist

Before running "Clean Up Ghost" operations:

```
┌────────────────────────────────────────────┐
│  ✅ Safety Checklist                       │
├────────────────────────────────────────────┤
│                                             │
│  ☑ Have you run "Sync Status" first?       │
│  ☑ Have you checked Console logs?          │
│  ☑ Are you on your primary device?         │
│  ☑ Has it been >24h since app install?     │
│  ☑ Have iCloud syncs completed?            │
│  ☑ Do you understand what will be deleted? │
│  ☑ Have you verified tracking records?     │
│                                             │
│  If all checked ✅ → Safe to clean up      │
│  If any ❌ → DON'T run cleanup yet         │
└────────────────────────────────────────────┘
```

---

## Error States

### Error: No CloudKit Access

```
┌────────────────────────────────────────────┐
│  ❌ Sharing Failed                         │
│                                             │
│  CloudKit is not available. Please check:  │
│  • You are signed in to iCloud             │
│  • iCloud Drive is enabled                 │
│  • Network connection is active            │
│                                             │
│  [Open Setup & Diagnostics]  [OK]          │
└────────────────────────────────────────────┘
```

### Error: Sync Failed

```
┌────────────────────────────────────────────┐
│  ⚠️ Sharing Status                         │
│                                             │
│  Failed to sync: Network error             │
│                                             │
│  Try again later when network is stable.   │
│                                             │
│  [OK]                                       │
└────────────────────────────────────────────┘
```

### Error: Cleanup Failed (Partial)

```
Console Output:
👻 Deleting 5 ghost recipes from CloudKit...
👻   Deleted 'Recipe 1'
👻   Deleted 'Recipe 2'
❌   Failed to delete 'Recipe 3': Network timeout
👻   Deleted 'Recipe 4'
❌   Failed to delete 'Recipe 5': Permission denied
✅ GHOST CLEANUP COMPLETE: Deleted 3 ghost recipes, 2 failures

User Message:
┌────────────────────────────────────────────┐
│  ⚠️ Ghost recipe cleanup complete!         │
│                                             │
│  3 recipes deleted successfully            │
│  2 recipes failed - check Console logs     │
│                                             │
│  You may need to run cleanup again.        │
│                                             │
│  [OK]                                       │
└────────────────────────────────────────────┘
```

---

## Quick Reference Card

### For Recipes

| Button | What It Does | When to Use |
|--------|-------------|-------------|
| 🔄 Sync Recipe Sharing Status | Detects orphaned recipes | Monthly or after device switch |
| ✨ Clean Up Ghost Recipes | Deletes orphaned recipes | Only when sync finds ghosts |

### For Recipe Books

| Button | What It Does | When to Use |
|--------|-------------|-------------|
| 🔄 Sync Recipe Book Sharing Status | Detects orphaned books | Monthly or after device switch |
| ✨ Clean Up Ghost Recipe Books | Deletes orphaned books | Only when sync finds ghosts |

### Safety Rules

1. ✅ Always sync before cleanup
2. ✅ Check Console logs
3. ✅ Verify on primary device
4. ❌ Never cleanup on new device immediately
5. ❌ Never cleanup without sync first
6. ❌ Never ignore Console warnings

---

## Summary

The ghost data cleanup system provides:

✅ **Detection** - Sync functions find orphaned data  
✅ **Diagnosis** - Console logs show what's wrong  
✅ **Cleanup** - Delete functions remove ghosts  
✅ **Verification** - Check results in browse views  

**Use regularly for best results:**
- Sync monthly
- Cleanup only when needed
- Always check logs first
- Never cleanup on new devices immediately

**Location:**  
Settings → Sharing & Community → Quick Actions
