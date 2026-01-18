# Sharing Tab Filter Fix

## Problem
When a user shared a recipe or book, it would:
- ❌ Disappear from the user's "Mine" tab
- ❌ Appear in the user's "Shared" tab
- ❌ The user who shared it would see their own shared items in the "Shared" tab

**Expected behavior:**
- ✅ User's own recipes/books should ALWAYS show in "Mine" tab (whether shared or not)
- ✅ "Shared" tab should ONLY show recipes/books shared by OTHER users
- ✅ "All" tab shows everything (user's own + shared by others)

## Root Cause
The filter logic in both `ContentView.swift` and `RecipeBooksView.swift` was treating ALL entries in the `SharedRecipe`/`SharedRecipeBook` tables the same, without distinguishing between:
1. Items the **current user** shared (where `sharedByUserID == currentUserID`)
2. Items **other users** shared (where `sharedByUserID != currentUserID`)

### Old Logic (INCORRECT)
```swift
switch contentFilter {
case .mine:
    // Filter OUT all shared items (including user's own shared items!)
    let sharedRecipeIDs = Set(sharedRecipes.filter { $0.isActive }.map { $0.recipeID })
    return recipes.filter { !sharedRecipeIDs.contains($0.id) }
    
case .shared:
    // Show all shared items (including user's own shared items!)
    let sharedRecipeIDs = Set(sharedRecipes.filter { $0.isActive }.map { $0.recipeID })
    return recipes.filter { sharedRecipeIDs.contains($0.id) }
}
```

## Solution
Updated the filter logic to check `sharedByUserID` and compare it against the current user's ID from `CloudKitSharingService.shared.currentUserID`.

### New Logic (CORRECT)
```swift
let currentUserID = CloudKitSharingService.shared.currentUserID

switch contentFilter {
case .mine:
    // Show ALL user's own recipes (including ones they've shared)
    // Filter OUT recipes shared by OTHER users
    let sharedByOthersIDs = Set(
        sharedRecipes
            .filter { $0.isActive && $0.sharedByUserID != currentUserID }
            .compactMap { $0.recipeID }
    )
    return recipes.filter { !sharedByOthersIDs.contains($0.id) }
    
case .shared:
    // Only show recipes shared by OTHER users
    let sharedByOthersIDs = Set(
        sharedRecipes
            .filter { $0.isActive && $0.sharedByUserID != currentUserID }
            .compactMap { $0.recipeID }
    )
    return recipes.filter { sharedByOthersIDs.contains($0.id) }
    
case .all:
    // Show all recipes (user's own + shared by others)
    return recipes
}
```

## Files Modified

### 1. ContentView.swift
**Function:** `applyContentFilter(to:)`
- Added `let currentUserID = CloudKitSharingService.shared.currentUserID`
- Updated `.mine` case to exclude only recipes shared by OTHER users
- Updated `.shared` case to show only recipes shared by OTHER users
- Added clarifying comments

### 2. RecipeBooksView.swift
**Property:** `filteredBooks`
- Added `let currentUserID = CloudKitSharingService.shared.currentUserID`
- Updated `.mine` case to exclude only books shared by OTHER users
- Updated `.shared` case to show only books shared by OTHER users
- Added clarifying comments

## Testing Checklist

### User A (Sharer)
- [x] Share a recipe → Recipe STAYS in "Mine" tab
- [x] Share a recipe → Recipe does NOT appear in "Shared" tab
- [x] Share a recipe → Recipe still appears in "All" tab
- [x] Unshare a recipe → Recipe still appears in "Mine" tab

### User B (Viewer)
- [x] See User A's shared recipe → Appears in "Shared" tab
- [x] See User A's shared recipe → Does NOT appear in "Mine" tab
- [x] See User A's shared recipe → Appears in "All" tab
- [x] Own recipes → Only appear in "Mine" tab

### Edge Cases
- [x] User with no shared recipes → "Shared" tab shows empty state
- [x] User with no personal recipes → "Mine" tab shows empty state
- [x] Multiple users sharing → Each user only sees others' shares in "Shared" tab

## Key Insight
The `SharedRecipe` and `SharedRecipeBook` tables serve dual purposes:
1. **Tracking what the user has shared** (`sharedByUserID == currentUserID`)
2. **Tracking what others have shared** (`sharedByUserID != currentUserID`)

The filter must differentiate between these two types of entries using the `sharedByUserID` field.

## Benefits
- ✅ Intuitive user experience: "Mine" always shows user's own content
- ✅ Clear separation: "Shared" only shows content from the community
- ✅ No confusion: Users don't see their own shares in "Shared" tab
- ✅ Complete view: "All" tab shows everything at once
