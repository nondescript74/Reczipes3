# CloudKit Sharing Service Build Fix

## Issue Summary
The Xcode Cloud build failed with Swift macro expansion errors in `CloudKitSharingService.swift`. The errors occurred when the `@Predicate` macro tried to expand predicates that compared optional properties with non-optional values.

## Root Cause
The `SharedRecipe` and `SharedRecipeBook` models have optional properties:
- `SharedRecipe.recipeID: UUID?`
- `SharedRecipe.cloudRecordID: String?`
- `SharedRecipeBook.bookID: UUID?`
- `SharedRecipeBook.cloudRecordID: String?`

The predicates were attempting to capture these values directly from the surrounding scope, which caused type mismatches:
```swift
// ❌ This failed because recipe.id (UUID) doesn't match $0.recipeID (UUID?)
predicate: #Predicate { $0.recipeID == recipe.id && $0.isActive == true }
```

## Solution
The fix involves two key changes:

### 1. Capture values in local constants
By storing the value to compare in a local constant, we ensure the type is clearly defined:
```swift
let recipeIDToFind = recipe.id  // UUID
```

### 2. Use explicit parameter names in predicates
Instead of using `$0`, we use explicit parameter names to make the predicate clearer:
```swift
predicate: #Predicate<SharedRecipe> { sharedRecipe in
    sharedRecipe.recipeID == recipeIDToFind && sharedRecipe.isActive == true
}
```

## Fixed Locations

### 1. `shareRecipe(_:modelContext:)` - Line ~104
**Before:**
```swift
let existingDescriptor = FetchDescriptor<SharedRecipe>(
    predicate: #Predicate { $0.recipeID == recipe.id && $0.isActive == true }
)
```

**After:**
```swift
let recipeIDToFind = recipe.id
let existingDescriptor = FetchDescriptor<SharedRecipe>(
    predicate: #Predicate<SharedRecipe> { sharedRecipe in
        sharedRecipe.recipeID == recipeIDToFind && sharedRecipe.isActive == true
    }
)
```

### 2. `shareRecipeBook(_:modelContext:)` - Line ~182
**Before:**
```swift
let existingDescriptor = FetchDescriptor<SharedRecipeBook>(
    predicate: #Predicate { $0.bookID == book.id && $0.isActive == true }
)
```

**After:**
```swift
let bookIDToFind = book.id
let existingDescriptor = FetchDescriptor<SharedRecipeBook>(
    predicate: #Predicate<SharedRecipeBook> { sharedBook in
        sharedBook.bookID == bookIDToFind && sharedBook.isActive == true
    }
)
```

### 3. `unshareRecipe(cloudRecordID:modelContext:)` - Line ~387
**Before:**
```swift
let descriptor = FetchDescriptor<SharedRecipe>(
    predicate: #Predicate { $0.cloudRecordID == cloudRecordID }
)
```

**After:**
```swift
let recordIDToFind = cloudRecordID
let descriptor = FetchDescriptor<SharedRecipe>(
    predicate: #Predicate<SharedRecipe> { sharedRecipe in
        sharedRecipe.cloudRecordID == recordIDToFind
    }
)
```

### 4. `unshareRecipeBook(cloudRecordID:modelContext:)` - Line ~405
**Before:**
```swift
let descriptor = FetchDescriptor<SharedRecipeBook>(
    predicate: #Predicate { $0.cloudRecordID == cloudRecordID }
)
```

**After:**
```swift
let recordIDToFind = cloudRecordID
let descriptor = FetchDescriptor<SharedRecipeBook>(
    predicate: #Predicate<SharedRecipeBook> { sharedBook in
        sharedBook.cloudRecordID == recordIDToFind
    }
)
```

## Why This Works

1. **Type Clarity**: By extracting the value to compare into a local constant, the Swift compiler can better infer types in the predicate macro expansion.

2. **Explicit Generic Types**: Adding `<SharedRecipe>` and `<SharedRecipeBook>` to the `#Predicate` macro helps the compiler understand the context.

3. **Named Parameters**: Using explicit parameter names (`sharedRecipe`, `sharedBook`) instead of shorthand (`$0`) makes the macro expansion more reliable.

4. **Avoiding Capture Issues**: The macro expansion can more reliably capture local constants than it can capture values from complex expressions or property accesses.

## Testing
After this fix, the Xcode Cloud build should succeed. The predicates will correctly:
- Compare optional `UUID?` properties with non-optional `UUID` values
- Compare optional `String?` properties with non-optional `String` values
- Handle the conjunction of multiple conditions

## Related Documentation
- [Swift Data Predicate Documentation](https://developer.apple.com/documentation/foundation/predicate)
- [FetchDescriptor Documentation](https://developer.apple.com/documentation/swiftdata/fetchdescriptor)
- [Predicate Macro Best Practices](https://developer.apple.com/documentation/swiftdata/filtering-fetches-with-predicates)

---
**Date Fixed**: January 16, 2026
**Build Target**: Xcode Cloud - iOS Archive
**Related Commit**: "✅ Improved: Community sharing and management are now more secure and user-friendly"
