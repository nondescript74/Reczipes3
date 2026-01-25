# Troubleshooting Shared Recipe Books Not Appearing

## Problem
One user has shared a recipe book (50 recipes), but other users cannot see it in:
1. Books view → Shared tab
2. Settings → Browse Shared Recipe Books

## Step-by-Step Debugging

### On the SHARING Device (device that shared the book):

#### 1. Verify the book was actually uploaded to CloudKit

Run this in Xcode console or add a diagnostic function:

```swift
// In CloudKitSharingService.swift
func diagnoseMySharedBooks(modelContext: ModelContext) async {
    guard let currentUserID = currentUserID else {
        logError("No current user ID", category: "sharing")
        return
    }
    
    // Check local tracking
    let localTracking = try? modelContext.fetch(FetchDescriptor<SharedRecipeBook>())
    let mySharedBooks = localTracking?.filter { $0.sharedByUserID == currentUserID && $0.isActive }
    
    logInfo("📚 LOCAL TRACKING: Found \(mySharedBooks?.count ?? 0) shared books", category: "sharing")
    for book in mySharedBooks ?? [] {
        logInfo("  - '\(book.bookName)': cloudRecordID = \(book.cloudRecordID ?? "MISSING")", category: "sharing")
    }
    
    // Check CloudKit
    let cloudKitBooks = try? await fetchSharedRecipeBooks(excludeCurrentUser: false)
    let myCloudKitBooks = cloudKitBooks?.filter { $0.sharedByUserID == currentUserID }
    
    logInfo("📚 CLOUDKIT: Found \(myCloudKitBooks?.count ?? 0) shared books", category: "sharing")
    for book in myCloudKitBooks ?? [] {
        logInfo("  - '\(book.name)': \(book.recipeIDs.count) recipes, shared by \(book.sharedByUserName ?? "Unknown")", category: "sharing")
    }
}
```

**Expected Results:**
- Local tracking should show 1 book with a cloudRecordID
- CloudKit should show 1 book belonging to the current user

#### 2. Check for CloudKit ID

In Settings → Sharing & Community → Manage Shared Content:
- Do you see the book listed?
- Does it have a "⚠️ No CloudKit ID" warning?
- If yes, run "Repair Recipe Book CloudKit IDs"

#### 3. Verify CloudKit Record Type

The book must be saved with the correct record type: `SharedRecipeBook`

Check the `shareRecipeBook` function was called successfully:
```
Shared recipe book: [BookName]
Community share successful
```

### On the RECEIVING Device (other user trying to see the book):

#### 1. Check CloudKit Availability

In Settings → Sharing & Community:
- Does it show "Ready to Share" with a green checkmark?
- Is the user signed into iCloud?

#### 2. Try Manual Refresh

In Settings → Sharing & Community → Quick Actions:
- Tap **"Sync Community Books"**
- Check console logs for results

**Expected Log Output:**
```
📚 SYNC: Starting community books sync to local SwiftData...
📚 SYNC: Found X community books in CloudKit
📚   Created RecipeBook: 'BookName' by UserName
✅ SYNC COMPLETE: Community books synced
```

#### 3. Check Browse Community Books

In Settings → Browse Shared Recipe Books:
- The list should show immediately (fetches directly from CloudKit)
- If books don't appear here, the problem is CloudKit upload, not local sync

#### 4. Check Books View → Shared Tab

After syncing:
- Switch to Books tab
- Select "Shared" filter
- Books should appear

If they don't:
- Check filtering logic in `RecipeBooksView.swift`
- Verify `SharedRecipeBook` tracking entries were created

## Common Issues & Fixes

### Issue 1: Book Not in CloudKit
**Symptoms:** Browse Community Books shows nothing, even after refresh

**Cause:** Book was never uploaded to CloudKit, or upload failed

**Fix:**
1. On sharing device, check console for upload errors
2. Check iCloud account status
3. Try sharing the book again
4. Run "Clean Up Ghost Recipe Books" to remove stale tracking
5. Share again

### Issue 2: Book in CloudKit but Not Syncing Locally
**Symptoms:** Browse Community Books shows the book, but Books → Shared tab doesn't

**Cause:** Sync to local SwiftData failed

**Fix:**
1. Run "Sync Community Books" manually
2. Check console logs for sync errors
3. Verify `RecipeBook` entities are being created
4. Check SharedRecipeBook tracking entries

### Issue 3: Wrong User ID Filter
**Symptoms:** Book appears in Browse but disappears in Shared tab

**Cause:** Book might be attributed to the wrong user

**Fix:**
1. Check `sharedByUserID` in SharedRecipeBook tracking
2. Verify it's NOT the current user's ID
3. Run diagnostic: `await sharingService.diagnoseSharedRecipeBooks()`

### Issue 4: CloudKit Schema Issues
**Symptoms:** Query errors, "field not queryable" errors

**Cause:** CloudKit schema not configured properly

**Fix:**
1. Go to CloudKit Dashboard
2. Select your container: `iCloud.com.headydiscy.reczipes`
3. Check Schema → Indexes for `SharedRecipeBook` record type
4. Ensure fields are marked queryable
5. Deploy to Production

### Issue 5: Local Database Corruption
**Symptoms:** Books sync but don't appear in UI

**Cause:** SwiftData query issues or data corruption

**Fix:**
1. Check @Query in RecipeBooksView is working
2. Verify `sharedBooks` array contains the books
3. Check filtering logic in `filteredBooks`
4. Try restarting the app

## Diagnostic Commands

Add these to `SharingSettingsView.swift` for testing:

```swift
// In Quick Actions section
Button {
    Task {
        await diagnoseSharedBooks()
    }
} label: {
    Label("Diagnose Shared Books", systemImage: "stethoscope")
}

// Function
private func diagnoseSharedBooks() async {
    logInfo("🔍 DIAGNOSTIC: Checking shared books...", category: "sharing")
    
    // Check CloudKit
    do {
        let allBooks = try await sharingService.fetchSharedRecipeBooks(excludeCurrentUser: false)
        logInfo("🔍 CloudKit has \(allBooks.count) total books", category: "sharing")
        
        let grouped = Dictionary(grouping: allBooks) { $0.sharedByUserID }
        for (userID, books) in grouped {
            let userName = books.first?.sharedByUserName ?? "Unknown"
            logInfo("🔍   User '\(userName)' (\(userID)): \(books.count) books", category: "sharing")
            for book in books {
                logInfo("🔍     - '\(book.name)': \(book.recipeIDs.count) recipes", category: "sharing")
            }
        }
    } catch {
        logError("🔍 Failed to fetch books: \(error)", category: "sharing")
    }
    
    // Check local SwiftData
    let allLocalBooks = try? modelContext.fetch(FetchDescriptor<RecipeBook>())
    logInfo("🔍 Local SwiftData has \(allLocalBooks?.count ?? 0) RecipeBook entities", category: "sharing")
    
    let allTracking = try? modelContext.fetch(FetchDescriptor<SharedRecipeBook>())
    logInfo("🔍 Local SwiftData has \(allTracking?.count ?? 0) SharedRecipeBook tracking entries", category: "sharing")
    
    let currentUserID = sharingService.currentUserID
    let sharedByOthers = allTracking?.filter { $0.isActive && $0.sharedByUserID != currentUserID }
    logInfo("🔍 Shared by others: \(sharedByOthers?.count ?? 0) books", category: "sharing")
    for book in sharedByOthers ?? [] {
        logInfo("🔍   - '\(book.bookName)' by \(book.sharedByUserName ?? "Unknown")", category: "sharing")
    }
}
```

## Testing Checklist

- [ ] **On Device A (sharer):**
  - [ ] Book has cloudRecordID in Manage Shared Content
  - [ ] Console shows "Community share successful"
  - [ ] CloudKit Dashboard shows the record (optional)
  - [ ] Run "Diagnose Shared Books" - shows 1 book in CloudKit

- [ ] **On Device B (viewer):**
  - [ ] CloudKit Status shows "Ready to Share"
  - [ ] Browse Community Books shows the book immediately
  - [ ] Manual "Sync Community Books" succeeds
  - [ ] Books → Shared tab shows the book
  - [ ] Run "Diagnose Shared Books" - shows 1 book from Device A

## Expected Flow

### Successful Sharing (Device A)
1. User creates recipe book with 50 recipes
2. User shares the book → Settings → Share Specific Books
3. Console shows: `Shared recipe book: [BookName]`
4. `SharedRecipeBook` tracking entry created with `cloudRecordID`
5. CloudKit record created with type `SharedRecipeBook`

### Successful Viewing (Device B)
1. User opens Settings → Browse Shared Recipe Books
2. `fetchSharedRecipeBooks()` fetches from CloudKit
3. Auto-sync runs: `syncCommunityBooksToLocal()`
4. Creates `RecipeBook` entity in local SwiftData
5. Creates `SharedRecipeBook` tracking entry
6. Books → Shared tab shows the book

## Quick Fix Script

If books are in CloudKit but not syncing:

```swift
// Run on receiving device
Task {
    // Force refresh
    try? await CloudKitSharingService.shared.syncCommunityBooksToLocal(modelContext: modelContext)
    
    // Verify
    let books = try? modelContext.fetch(FetchDescriptor<RecipeBook>())
    let tracking = try? modelContext.fetch(FetchDescriptor<SharedRecipeBook>())
    
    logInfo("After sync: \(books?.count ?? 0) books, \(tracking?.count ?? 0) tracking", category: "sharing")
}
```

## Last Resort: Clean Slate

If nothing works, try this on the **receiving device**:

1. Delete all SharedRecipeBook tracking:
   ```swift
   let allTracking = try? modelContext.fetch(FetchDescriptor<SharedRecipeBook>())
   for book in allTracking ?? [] {
       modelContext.delete(book)
   }
   try? modelContext.save()
   ```

2. Delete all RecipeBook entities shared by others:
   ```swift
   let currentUserID = CloudKitSharingService.shared.currentUserID
   let sharedBooks = allTracking?.filter { $0.sharedByUserID != currentUserID && $0.isActive }
   for tracking in sharedBooks ?? [] {
       if let bookID = tracking.bookID,
          let book = try? modelContext.fetch(FetchDescriptor<RecipeBook>(predicate: #Predicate { $0.id == bookID })).first {
           modelContext.delete(book)
       }
   }
   try? modelContext.save()
   ```

3. Force fresh sync:
   ```swift
   try? await CloudKitSharingService.shared.syncCommunityBooksToLocal(modelContext: modelContext)
   ```

## Contact & Support

If issue persists after all these steps:
1. Check CloudKit Dashboard for the shared book record
2. Verify both devices are using the same CloudKit container
3. Ensure both users are signed into iCloud
4. Check iCloud sync is enabled for the app
5. Try with TestFlight or production build (not just debug)

---

**Last Updated:** January 25, 2026
