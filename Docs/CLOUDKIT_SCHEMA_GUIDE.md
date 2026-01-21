# CloudKit Schema Management Guide

## Overview

When you add new properties to SwiftData models that sync with CloudKit, you need to understand how CloudKit schema management works. This guide covers the duplicate detection properties added in Schema V5.

## New Properties in Recipe (Schema V5)

```swift
var imageHash: String?
var extractionSource: String?
var originalFileName: String?
```

## CloudKit Schema Behavior

### Automatic Schema Creation ✅

**Good News:** CloudKit automatically creates schema for new properties when:

1. **First sync occurs** - When a device syncs a model with new properties
2. **Development environment** - CloudKit Development database auto-updates
3. **Optional properties** - All your new properties are optional, which CloudKit handles gracefully

### What Happens During First Sync

```
User Device (SwiftData)          CloudKit (Development)
─────────────────────           ──────────────────────
Recipe with:                     Recipe record type:
├─ imageHash: "abc123"    ──→   ├─ Creates "imageHash" field (String)
├─ extractionSource: "camera" ─→ ├─ Creates "extractionSource" field (String)  
└─ originalFileName: "IMG.jpg" → └─ Creates "originalFileName" field (String)

RESULT: CloudKit schema automatically updated! ✅
```

## Development vs Production Environment

### Development Environment 🔧

- **Auto-updates schema** when new fields appear
- **Safe for testing** - You can experiment freely
- **No approval needed** - Changes take effect immediately
- **Your current state** - All new properties will auto-create here

### Production Environment 🚀

- **Requires manual deployment** from Development to Production
- **Schema must be "promoted"** via CloudKit Dashboard
- **Can't auto-create fields** - Production is read-only for schema changes
- **Needs approval** - You deploy schema changes when ready

## Step-by-Step: What You Need to Do

### Option 1: Automatic (Recommended for Development)

**Do nothing!** 🎉

1. Run your app with the new code
2. Extract a recipe (triggering the new properties to be set)
3. Let CloudKit sync occur naturally
4. CloudKit Development automatically creates the new fields

**Timeline:** Immediate (first sync)

### Option 2: Manual (For Production Deployment)

When you're ready to ship to the App Store:

#### Step 1: Verify Development Schema

1. Open [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Select your app: `iCloud.com.headydiscy.reczipes`
3. Choose **Development** environment
4. Navigate to **Schema** → **Record Types**
5. Find `CD_Recipe` (SwiftData uses `CD_` prefix)
6. Verify new fields exist:
   - `CD_imageHash` (String)
   - `CD_extractionSource` (String)
   - `CD_originalFileName` (String)

#### Step 2: Deploy to Production

1. In CloudKit Dashboard, click **Schema** → **Deploy to Production**
2. Review changes (should show 3 new fields added)
3. Click **Deploy**
4. Wait for deployment (usually instant, can take minutes)

#### Step 3: Verify Production Schema

1. Switch to **Production** environment in dashboard
2. Navigate to **Schema** → **Record Types**
3. Confirm `CD_Recipe` has all three new fields

## CloudKit Field Naming

SwiftData automatically prefixes CloudKit fields with `CD_`:

| SwiftData Property | CloudKit Field Name | Type |
|-------------------|---------------------|------|
| `imageHash` | `CD_imageHash` | String |
| `extractionSource` | `CD_extractionSource` | String |
| `originalFileName` | `CD_originalFileName` | String |

## Indexes (Optional)

### Do You Need Indexes?

**For duplicate detection queries:** ⚠️ Maybe

If you query recipes by `imageHash` frequently:

```swift
// This query would benefit from an index
let descriptor = FetchDescriptor<Recipe>(
    predicate: #Predicate { $0.imageHash == "abc123" }
)
```

### How to Add Indexes

#### Via CloudKit Dashboard

1. Go to **Schema** → **Record Types** → `CD_Recipe`
2. Click **Indexes** tab
3. Click **+** to add new index
4. Select field: `CD_imageHash`
5. Index type: **QUERYABLE** (for queries) or **SORTABLE** (for sorting)
6. Save changes
7. Deploy to Production when ready

#### Performance Consideration

Without indexes:
- ✅ Queries still work (CloudKit scans all records)
- ⚠️ Slower for large datasets (1000+ recipes)
- ❌ May timeout on very large datasets (10,000+ recipes)

With indexes:
- ✅ Fast queries regardless of dataset size
- ✅ Recommended for fields used in predicates
- ⚠️ Slightly slower writes (index must be updated)

### Recommended Indexes

For your use case:

```
Field: CD_imageHash
Type: QUERYABLE
Reason: Used in duplicate detection queries
Priority: Medium (only if you have 1000+ recipes)
```

**You probably don't need indexes yet** unless you expect users to have thousands of recipes.

## Testing CloudKit Schema Changes

### Simulator Limitations

⚠️ **CloudKit may show "temporarily unavailable" in Simulator**

This is normal! CloudKit in Simulator:
- ❌ Doesn't reliably connect to iCloud
- ❌ May fail authentication
- ✅ Still creates schema when it does connect
- ✅ Fine for development testing

### Test on Real Device

For reliable CloudKit testing:

1. Build to a real iPhone/iPad
2. Ensure device is signed into iCloud
3. Settings → [Your Name] → iCloud → Reczipes → Enable
4. Extract a recipe with the new properties
5. Verify sync in CloudKit Dashboard

### Check Sync Status

```swift
// In your app, log when syncs occur
Task {
    let container = CKContainer(identifier: "iCloud.com.headydiscy.reczipes")
    let status = try await container.accountStatus()
    
    switch status {
    case .available:
        print("✅ CloudKit available")
    case .noAccount:
        print("❌ No iCloud account")
    case .restricted:
        print("⚠️ CloudKit restricted")
    case .couldNotDetermine:
        print("⚠️ CloudKit status unknown")
    case .temporarilyUnavailable:
        print("⚠️ CloudKit temporarily unavailable")
    @unknown default:
        print("❓ Unknown CloudKit status")
    }
}
```

## Migration Timeline

### What Happens to Existing Data?

**Existing recipes (before Schema V5):**
- `imageHash` = `nil` ✅
- `extractionSource` = `nil` ✅
- `originalFileName` = `nil` ✅

This is correct! Old recipes don't have these values.

**New recipes (after Schema V5):**
- `imageHash` = computed hash from image ✅
- `extractionSource` = "camera" / "photos" / "files" / "url" ✅
- `originalFileName` = filename if extracted from file ✅

### Syncing Between Devices

**Device A (updated to V5)** ←→ **Device B (still on V4)**

Device B will:
- ✅ Ignore unknown fields (CloudKit is forward-compatible)
- ✅ Preserve new fields when syncing back
- ⚠️ Not use duplicate detection (missing code)

**Solution:** Encourage users to update all devices

## Troubleshooting

### "Unknown field in CloudKit record"

**Cause:** Production schema not deployed

**Fix:**
1. Deploy schema from Development to Production
2. Or wait for automatic schema creation (Development only)

### "Query failed: field not indexed"

**Cause:** Large dataset without index

**Fix:**
1. Add index in CloudKit Dashboard
2. Or use in-memory filtering instead of predicates

### "Schema deployment failed"

**Cause:** Incompatible change (rare)

**Fix:**
1. Check CloudKit Dashboard for error details
2. Only adding optional fields is always safe
3. Removing/renaming fields requires migration

## Current Status Summary

### Your Schema V5 Changes

✅ **All changes are CloudKit-compatible:**
- All new properties are optional `String?`
- No breaking changes to existing schema
- Forward-compatible with older app versions
- Backward-compatible with existing data

### What You Should Do

**For Development:**
1. ✅ Nothing! Just run the app and let it sync
2. ✅ New fields will auto-create on first sync

**For Production (before App Store release):**
1. ⚠️ Deploy schema from Development to Production via CloudKit Dashboard
2. ⚠️ Test on a real device with Production environment
3. ⚠️ Verify schema deployment succeeded

**For Indexes:**
1. 🔷 Optional - Add later if performance becomes an issue
2. 🔷 Not needed for small-medium datasets (<1000 recipes)
3. 🔷 Recommended for large datasets (1000+ recipes)

## Additional Resources

- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
- [Apple: CloudKit Schema](https://developer.apple.com/documentation/cloudkit/managing_cloudkit_database_schema)
- [Apple: SwiftData with CloudKit](https://developer.apple.com/documentation/swiftdata/managing-model-data-in-icloud)

## Quick Reference Commands

### Check CloudKit Status in Code

```swift
let container = CKContainer(identifier: "iCloud.com.headydiscy.reczipes")
let status = try await container.accountStatus()
print("CloudKit Status: \(status)")
```

### Verify Schema in Dashboard

```bash
# Open CloudKit Dashboard
open https://icloud.developer.apple.com/dashboard

# Navigate to:
# Your App → Development → Schema → Record Types → CD_Recipe
```

### Force Schema Update (Development)

```swift
// Just save a record with new fields - schema auto-updates!
let recipe = Recipe(title: "Test")
recipe.imageHash = "test-hash"
recipe.extractionSource = "test"
modelContext.insert(recipe)
try? modelContext.save()
```

## Questions?

If you see any CloudKit errors during development:

1. Check if you're in Development or Production environment
2. Verify iCloud account is signed in
3. Check CloudKit Dashboard for schema status
4. Review logs for specific error codes
5. Remember: Simulator CloudKit is unreliable - test on device

---

**Last Updated:** January 20, 2026 (Schema V5 - Duplicate Detection)
