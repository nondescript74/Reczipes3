# Debugging: Shared Recipe Book Not Appearing

## Issue Summary

**Symptom:** One user shared a recipe book (50 recipes), but another user cannot see it in:
1. **Books view → Shared tab**
2. **Settings → Browse Community Books**

## Quick Diagnosis Steps

I've added a diagnostic tool to help you identify the problem. Follow these steps:

### Step 1: Run Diagnostic on BOTH Devices

1. **On the device that shared the book (connected to Xcode):**
   - Open **Settings → Sharing & Community**
   - Scroll to **Quick Actions**
   - Tap **"Diagnose Shared Books"**
   - Check the **Xcode console** for output

2. **On the other device (iPad not connected to Xcode):**
   - Open **Settings → Sharing & Community**
   - Scroll to **Quick Actions**
   - Tap **"Diagnose Shared Books"**
   - Note what the alert says

### Step 2: Read the Diagnostic Output

The diagnostic will show you:

```
🔍 PART 1: Checking CloudKit Public Database...
🔍 CloudKit has X total recipe books
🔍   My books: Y
🔍   Others' books: Z

🔍 👤 (YOU) User 'Your Name' (...): Y books
🔍     - 'Book Name': 50 recipes, shared [date]

🔍 PART 2: Checking Local SwiftData...
🔍 Local SwiftData has A RecipeBook entities
🔍 Local SwiftData has B SharedRecipeBook tracking entries
🔍   Active: C
🔍   Inactive: D
🔍   My shared books (tracking): E
🔍   Others' shared books (tracking): F

🔍 PART 3: Recommendations
🔍 ✅ Everything looks good! OR
🔍 ⚠️ Problem: [description]
🔍 💡 Solution: [what to do]
```

### Step 3: Interpret Results

#### ✅ **GOOD Results (Device A - Sharer):**
```
🔍 CloudKit has 1 total recipe books
🔍   My books: 1
🔍   Others' books: 0
🔍 👤 (YOU) User 'Alice' (...): 1 books
🔍     - 'My Cookbook': 50 recipes, shared [date]
```

This means the book **was successfully uploaded to CloudKit** ✅

#### ✅ **GOOD Results (Device B - Viewer):**
```
🔍 CloudKit has 1 total recipe books
🔍   My books: 0
🔍   Others' books: 1
🔍 👥 User 'Alice' (...): 1 books
🔍     - 'My Cookbook': 50 recipes, shared [date]

🔍 Local SwiftData has 1 RecipeBook entities
🔍   Others' shared books (tracking): 1
🔍   - 'My Cookbook' by Alice [✅ Has RecipeBook]

🔍 ✅ Everything looks good! 1 books synced correctly
```

This means the book is **in CloudKit AND synced locally** ✅

#### ❌ **BAD Results (Device A - Sharer):**
```
🔍 CloudKit has 0 total recipe books
🔍   My books: 0
```

**Problem:** Book was NOT uploaded to CloudKit  
**Cause:** Sharing failed, CloudKit not available, or network error  
**Solution:** Try sharing the book again

#### ❌ **BAD Results (Device B - Viewer):**
```
🔍 CloudKit has 1 total recipe books
🔍   Others' books: 1

🔍 Local SwiftData has 0 RecipeBook entities
🔍   Others' shared books (tracking): 0

🔍 ⚠️ Problem: Books exist in CloudKit but not in local tracking
🔍 💡 Solution: Run 'Sync Community Books' to fix this
```

**Problem:** Book is in CloudKit but NOT synced to local device  
**Cause:** Sync hasn't run yet, or sync failed  
**Solution:** Run **"Sync Community Books"**

## Common Scenarios & Fixes

### Scenario 1: Book Not in CloudKit at All

**Device A Diagnostic Shows:**
- CloudKit has 0 books
- My books: 0

**Fix:**
1. On Device A, go to **Settings → Sharing & Community → Manage Shared Content**
2. Check if the book is listed there
3. If **NOT listed:** Share the book again
4. If **listed but has "⚠️ No CloudKit ID":** Run **"Repair Recipe Book CloudKit IDs"**
5. After repair, check console for success message
6. Run **"Diagnose Shared Books"** again

### Scenario 2: Book in CloudKit, but Not Syncing to Device B

**Device B Diagnostic Shows:**
- CloudKit has 1 book (from Device A)
- Local SwiftData has 0 RecipeBook entities
- Others' shared books (tracking): 0

**Fix:**
1. On Device B, verify CloudKit is available (green checkmark in Settings → Sharing & Community)
2. Run **"Sync Community Books"** manually
3. Wait for success alert
4. Check **Books → Shared tab**
5. If still not appearing, run **"Diagnose Shared Books"** again

### Scenario 3: Book Synced but Not Showing in UI

**Device B Diagnostic Shows:**
- CloudKit has 1 book
- Local SwiftData has 1 RecipeBook
- Others' shared books (tracking): 1
- ✅ Everything looks good!

**But:** Books → Shared tab is empty

**Fix:**
1. Check the `contentFilter` in RecipeBooksView
2. Make sure you're on the **"Shared"** tab, not "Mine"
3. Try switching away and back to Shared tab (triggers auto-sync)
4. Restart the app
5. Check if `sharedByUserID` is correctly set in the diagnostic output

### Scenario 4: iCloud/CloudKit Not Available

**Diagnostic Shows:**
- Failed to fetch books from CloudKit: [error]

**Fix:**
1. Go to iOS Settings → [Your Name] → iCloud
2. Verify you're signed in
3. Enable iCloud for this app
4. Check network connection
5. Try again after a few minutes

## Step-by-Step Fix Process

### On Device A (Sharer):

1. **Verify Sharing Status:**
   ```
   Settings → Sharing & Community → Manage Shared Content
   ```
   - Is the book listed?
   - Does it have a cloudRecordID? (no ⚠️ warning)

2. **Run Diagnostic:**
   ```
   Settings → Sharing & Community → Quick Actions → Diagnose Shared Books
   ```
   - Check Xcode console
   - Should show: CloudKit has 1 book, My books: 1

3. **If Book Not in CloudKit:**
   ```
   a. Run "Repair Recipe Book CloudKit IDs"
   b. If still nothing, try sharing the book again:
      - Go to Books view
      - Long press the book → Share
      - OR Settings → Share Specific Books
   c. Run diagnostic again
   ```

### On Device B (Viewer):

1. **Verify CloudKit Available:**
   ```
   Settings → Sharing & Community
   ```
   - Should show "Ready to Share" with green checkmark
   - If not, sign into iCloud

2. **Run Diagnostic:**
   ```
   Settings → Sharing & Community → Quick Actions → Diagnose Shared Books
   ```
   - Should show: CloudKit has 1 book, Others' books: 1

3. **If Book in CloudKit but Not Local:**
   ```
   Settings → Sharing & Community → Quick Actions → Sync Community Books
   ```
   - Wait for success alert
   - Run diagnostic again
   - Should show: Local SwiftData has 1 RecipeBook

4. **Check Books View:**
   ```
   Books tab → Shared filter
   ```
   - Book should now appear
   - If not, try switching away and back to trigger sync

## Advanced Troubleshooting

### Check CloudKit Dashboard

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Select container: `iCloud.com.headydiscy.reczipes`
3. Go to **Data → Public Database**
4. Select **SharedRecipeBook** record type
5. Look for your book record
6. Verify `sharedBy` field matches Device A's user ID

### Enable Verbose Logging

In the console, filter for:
- `📚` (book-related logs)
- `🔍` (diagnostic logs)
- `✅` (success messages)
- `❌` (errors)

### Check SwiftData Queries

In RecipeBooksView, the Shared filter uses:
```swift
let sharedByOthersIDs = Set(
    sharedBooks
        .filter { $0.isActive && $0.sharedByUserID != currentUserID }
        .compactMap { $0.bookID }
)
result = result.filter { sharedByOthersIDs.contains($0.id) }
```

This requires:
- `SharedRecipeBook` entry exists
- `isActive == true`
- `sharedByUserID != current user`
- `bookID` matches a `RecipeBook.id`

### Manual Verification

On Device B, after sync, you can manually check in the debugger:

```swift
// In RecipeBooksView or anywhere with modelContext
let allBooks = try? modelContext.fetch(FetchDescriptor<RecipeBook>())
print("Total RecipeBook: \(allBooks?.count ?? 0)")

let allTracking = try? modelContext.fetch(FetchDescriptor<SharedRecipeBook>())
print("Total SharedRecipeBook: \(allTracking?.count ?? 0)")

let active = allTracking?.filter { $0.isActive }
print("Active tracking: \(active?.count ?? 0)")

let currentUserID = CloudKitSharingService.shared.currentUserID
let others = active?.filter { $0.sharedByUserID != currentUserID }
print("Shared by others: \(others?.count ?? 0)")

for book in others ?? [] {
    print("  - \(book.bookName) by \(book.sharedByUserName ?? "Unknown")")
}
```

## Expected Timeline

### Immediate (Device A):
- Share button tapped
- CloudKit record created (~1-2 seconds)
- Local tracking created
- Console shows "Shared recipe book: [name]"

### Within 5 minutes (Device B):
- Open Browse Community Books → Auto-syncs
- OR Switch to Books → Shared tab → Auto-syncs (if >5 min since last sync)
- RecipeBook + SharedRecipeBook created locally
- Book appears in Shared tab

### Manual Sync (Device B):
- Tap "Sync Community Books" button
- Immediate sync
- Book appears within seconds

## Success Checklist

- [ ] **Device A:** Diagnostic shows book in CloudKit
- [ ] **Device A:** Book has cloudRecordID in Manage Shared Content
- [ ] **Device B:** CloudKit shows "Ready to Share"
- [ ] **Device B:** Diagnostic shows book in CloudKit (from Device A)
- [ ] **Device B:** After sync, diagnostic shows book in local SwiftData
- [ ] **Device B:** Books → Shared tab shows the book
- [ ] **Device B:** Can tap book to view details

## If All Else Fails

1. **Device A:**
   - Unshare the book (Manage Shared Content → swipe to delete)
   - Run "Clean Up Ghost Recipe Books"
   - Share the book again
   - Verify with diagnostic

2. **Device B:**
   - Delete all shared book data (use the diagnostic to identify)
   - Run "Sync Community Books"
   - Verify with diagnostic

3. **Both Devices:**
   - Ensure running same app version
   - Ensure both signed into iCloud with different accounts
   - Restart both apps
   - Check network connectivity

## Contact Support

If issue persists:
1. Run diagnostic on both devices
2. Copy console output from both
3. Take screenshots of:
   - Settings → Sharing & Community (CloudKit status)
   - Manage Shared Content (Device A)
   - Books → Shared tab (Device B)
4. Note app version and iOS version

---

**Last Updated:** January 25, 2026  
**Diagnostic Tool Added:** CloudKitSharingService.diagnoseSharedRecipeBooks()
