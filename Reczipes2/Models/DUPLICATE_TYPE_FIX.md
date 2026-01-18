# Fix: Duplicate CloudKit Manager Type Declarations

## Problem
The compiler was reporting "ambiguous for type lookup" errors for `CloudKitRecipeStatus` and `CloudKitRecipeManagerData` because these types were defined in two places:

1. `SharedContentModels.swift` - The correct, comprehensive definitions
2. `CloudKitRecipeManagerModels.swift` - Older duplicate definitions

Additionally, `CloudKitSharingService.swift` was using the old initializer signature that doesn't match the current type definitions.

## Errors Reported
```
error: 'CloudKitRecipeStatus' is ambiguous for type lookup in this context
error: 'CloudKitRecipeManagerData' is ambiguous for type lookup in this context
error: Invalid redeclaration of 'CloudKitRecipeStatus'
error: Invalid redeclaration of 'CloudKitRecipeManagerData'
```

## Solution

### 1. Deprecated `CloudKitRecipeManagerModels.swift`
Removed all duplicate type declarations and added a deprecation notice. This file is now effectively empty but kept for backwards compatibility.

**Before:**
```swift
struct CloudKitRecipeStatus: Identifiable {
    let id: UUID
    let recipe: CloudKitRecipe
    let cloudRecordID: String
    let isTrackedLocally: Bool  // ❌ Old signature
    let sharedDate: Date
    let localTrackingRecord: SharedRecipe?
    ...
}
```

**After:**
```swift
// All CloudKit manager types are now defined in SharedContentModels.swift
// This file is intentionally left empty to avoid duplicate declarations
```

### 2. Fixed `CloudKitSharingService.swift` Initializer
Updated the code that creates `CloudKitRecipeStatus` instances to use the correct initializer.

**Before:**
```swift
let status = CloudKitRecipeStatus(
    id: UUID(),                    // ❌ Not needed (auto-generated)
    recipe: cloudRecipe,
    cloudRecordID: cloudRecordID,
    isTrackedLocally: isTracked,   // ❌ Removed parameter
    sharedDate: sharedDate,
    localTrackingRecord: trackingRecord
)
```

**After:**
```swift
let status = CloudKitRecipeStatus(
    recipe: cloudRecipe,
    cloudRecordID: cloudRecordID,
    sharedDate: sharedDate,
    localTrackingRecord: trackingRecord  // ✅ isTracked is computed from this
)
```

### 3. Canonical Definitions in `SharedContentModels.swift`
All CloudKit manager types are now defined in one place:

- `CloudKitRecipeStatus` - Recipe status with computed `isTracked` property
- `CloudKitRecipeManagerData` - Aggregated recipe data
- `CloudKitRecipeBookStatus` - Recipe book status with computed `isTracked` property
- `CloudKitRecipeBookManagerData` - Aggregated book data

## Key Improvements

1. **No Duplicate Declarations**: Types are defined in exactly one place
2. **Computed Properties**: `isTracked` is computed from `localTrackingRecord != nil` instead of being a separate boolean parameter
3. **Consistent Interface**: Recipe and Recipe Book managers use the same pattern
4. **Better Design**: Removes redundant data that could get out of sync

## Files Modified
- `CloudKitRecipeManagerModels.swift` - Deprecated (emptied)
- `CloudKitSharingService.swift` - Fixed initializer calls
- `SharedContentModels.swift` - Already contains correct definitions (confirmed has SwiftUI import)

## Testing
After this change:
- ✅ No compilation errors
- ✅ CloudKitRecipeManagerView works correctly
- ✅ CloudKitRecipeBookManagerView works correctly
- ✅ Types are unambiguous throughout the codebase
