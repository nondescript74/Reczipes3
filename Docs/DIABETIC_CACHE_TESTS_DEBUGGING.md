# Diabetic Cache Tests Debugging Guide

## Current Status

The `DiabeticCacheTests` have been enhanced with comprehensive OSLog logging to help diagnose test failures.

## How to View Test Logs

### In Xcode

1. **Run Tests**: Press ⌘U or click the diamond next to the test name
2. **View Console**: Show the console pane (⌘⇧Y)
3. **Check Test Report**: Click on the test in the Test Navigator (⌘6)
4. **Look for Emoji Markers**: The logs use emojis for easy scanning

### In Console.app

1. Open `/Applications/Utilities/Console.app`
2. Select your Mac (for Simulator) or connected device
3. Filter by subsystem: `com.reczipes.tests`
4. Filter by category: `diabetic-cache`
5. Run tests and watch logs in real-time

## Log Emoji Guide

- 🧪 Test starting
- 📝 Creating/preparing data
- 🔨 Building objects
- ✅ Checkpoint reached/success
- 🔍 Checking/verifying condition
- 🔄 Updating/modifying data
- ⚠️ Warning (not a failure)
- ❌ Failure or unexpected result

## Test Structure

### Swift Testing Framework

These tests use the **new Swift Testing framework** (not XCTest):
- Tests are in `@Suite` structs
- Individual tests use `@Test` attribute
- Assertions use `#expect()` instead of `XCTAssert`
- Tests can be `async` and use actors

### Test Files Organization

Your tests should be in the **Reczipes2Tests** target. Check:

1. **Xcode Project Navigator** (⌘1)
2. Look for test files (they should have test badges)
3. **Test Navigator** (⌘6) to see all tests

## Common Test Failure Scenarios

### 1. Missing Types/Models

**Symptom**: Compilation errors about missing types like `DiabeticInfo`, `Ingredient`, `RecipeModel`

**Solution**: 
- These types must be accessible to the test target
- Check Target Membership in File Inspector (⌥⌘1)
- Ensure `@testable import Reczipes2` is working

### 2. Actor Isolation Issues

**Symptom**: Errors about main actor isolation

**Solution**:
- Some tests are marked `@MainActor` (they interact with SwiftData models)
- Some tests are `nonisolated` (they're pure computation)
- Check if test needs to create UI or data models (use `@MainActor`)

### 3. Async/Await Issues

**Symptom**: Tests timeout or hang

**Solution**:
- Check that `await` is used where needed
- Verify test function is marked `async throws`
- Look at logs to see where test stopped

### 4. Encoding/Decoding Failures

**Symptom**: Tests fail when creating or encoding data

**What to check**:
- Look for "Creating mock diabetic analysis" in logs
- Check if encoding succeeded (look for "Mock analysis created and encoded ✅")
- Verify all required fields in models are provided

### 5. Hash Calculation Issues

**Symptom**: Hash tests fail or hashes are empty

**What to check**:
- Look for "Hash 1:" and "Hash 2:" in logs
- Verify `SHA256` is working (from CryptoKit)
- Check if ingredients are being encoded properly

## Detailed Test Breakdown

### Test: `ingredientsHashConsistency`

**Purpose**: Verify that ingredient hashes are consistent regardless of order

**Key Points**:
- Creates two ingredient sets in different orders
- Calculates SHA256 hash of each
- Hashes should match (because sorting happens internally)

**Look for in logs**:
```
🧪 Starting ingredientsHashConsistency test
📝 Creating first ingredient set
✅ Hash 1: [long hex string]
📝 Creating second ingredient set (different order)
✅ Hash 2: [long hex string]
🔍 Comparing hashes...
✅ Test completed successfully
```

### Test: `recipeVersionIncrement`

**Purpose**: Verify that recipe version increments when ingredients change

**Key Points**:
- Creates a Recipe with initial version 1
- Updates ingredients
- Version should increment to 2
- Hash should change
- Modification date should update

**Look for in logs**:
```
🧪 Starting recipeVersionIncrement test
📝 Creating recipe
🔨 Creating Recipe from RecipeModel
✅ Initial state - Version: 1, Hash: [hash]
✅ Initial state verified
📝 Creating new ingredients
🔄 Updating recipe ingredients
✅ Updated state - Version: 2, Hash: [different hash]
🔍 Verifying version incremented: 1 -> 2
🔍 Verifying hash changed: [old] -> [new]
🔍 Verifying modification date is recent
✅ Test completed successfully
```

**If this test fails**, the logs will show exactly which verification failed.

### Test: `cacheDetectsVersionChange`

**Purpose**: Verify that cache correctly detects when ingredients have changed

**Key Points**:
- Creates a Recipe and CachedDiabeticAnalysis
- Cache should be valid initially
- Updates recipe ingredients
- Cache should become invalid
- Should detect ingredients are outdated

**Look for in logs**:
```
🧪 Starting cacheDetectsVersionChange test
📝 Creating recipe
✅ Recipe created - Version: 1, Hash: [hash]
📝 Creating mock diabetic analysis
✅ Mock analysis created and encoded
📝 Creating cached analysis
✅ Cache created - Version: 1, Hash: [hash]
🔍 Checking if cache is valid for unchanged recipe
   Result: VALID ✅
🔄 Updating recipe ingredients
✅ Recipe updated - New Version: 2, New Hash: [new hash]
🔍 Checking if cache is invalid after ingredient change
   Result: INVALID ✅
🔍 Checking if cache detects outdated ingredients
   Result: OUTDATED ✅
✅ Test completed successfully
```

**If cache stays valid after update**, look for:
- Version not incrementing
- Hash not changing
- `isValid(for:)` logic issue

## Debugging Steps

### Step 1: Find Which Test is Failing

1. Run all tests (⌘U)
2. Check Test Navigator (⌘6)
3. Look for red X next to failed tests
4. Note the test name

### Step 2: Read the Logs

1. Select the failed test in Test Navigator
2. Look at the console output
3. Find the last emoji before failure
4. This tells you where in the test it failed

### Step 3: Check the Failure Message

Swift Testing provides detailed failure messages:
```
Expected: true
Actual: false
Message: "Cache should be valid for unchanged recipe"
```

This tells you:
- What was expected
- What actually happened
- The assertion message

### Step 4: Verify Prerequisites

For cache tests, verify:

1. **Recipe model exists and is accessible**
   - Can you find `Recipe.swift`?
   - Is it in the main app target?
   - Does `@testable import Reczipes2` work?

2. **Ingredient types exist**
   - `Ingredient`
   - `IngredientSection`
   - `InstructionSection`
   - `RecipeModel`

3. **Diabetic types exist**
   - `DiabeticInfo`
   - `CachedDiabeticAnalysis`
   - `CarbInfo`, `FiberInfo`, `SugarBreakdown`

4. **CryptoKit is available**
   - SHA256 hashing should work
   - `String.sha256Hash()` extension exists

### Step 5: Check Test Target Settings

1. Open Project Settings (click project name in Navigator)
2. Select **Reczipes2Tests** target
3. Go to **Build Phases** tab
4. Check **Link Binary With Libraries**:
   - Should include `Testing.framework`
   - Should include `Foundation.framework`
   - Should include `CryptoKit.framework`

## Running Individual Tests

You can run tests in several ways:

1. **Single Test**: Click diamond next to test function
2. **Single Suite**: Click diamond next to `@Suite`
3. **All Tests**: Press ⌘U
4. **Test Navigator**: Right-click → Run

## Expected Test Output

When all tests pass, you should see:
```
✅ Test Suite 'DiabeticCacheTests' passed
   - ingredientsHashConsistency: 0.01s
   - ingredientsHashDifference: 0.01s
   - recipeVersionIncrement: 0.02s
   - cacheDetectsVersionChange: 0.03s
   - cacheDetectsHashChange: 0.02s
   - cacheExpiration: 0.01s
   - sha256HashStability: 0.01s
```

## Common Fixes

### Fix 1: Update Test Target Membership

If types are not found:
1. Select the source file (e.g., `Recipe.swift`)
2. Open File Inspector (⌥⌘1)
3. Check **Target Membership**
4. Make sure **Reczipes2** is checked (not the test target)
5. Use `@testable import` in test file

### Fix 2: Make Models Testable

In your models, ensure they're `public` or `internal` (not `private`):
```swift
// Good
@Model
final class Recipe { ... }

// Bad (won't be accessible to tests)
@Model
private final class Recipe { ... }
```

### Fix 3: Add Missing Imports

In `DiabeticCacheTests.swift`, you need:
```swift
import Testing
import Foundation
import OSLog
@testable import Reczipes2
```

## Still Stuck?

If tests are still failing after checking all above:

1. **Clean Build Folder**: ⌘⇧K then ⌘B
2. **Reset Simulator**: Device → Erase All Content and Settings
3. **Check for Multiple Test Targets**: You should only have one test target for unit tests
4. **Look for Compiler Errors**: Sometimes test failures are really build failures

## Understanding Test Organization

### Test Targets in Xcode

You likely have:
- **Reczipes2** - Main app target
- **Reczipes2Tests** - Unit tests (this is where `DiabeticCacheTests` lives)
- **Reczipes2UITests** - UI tests

Tests in **Reczipes2Tests** can access app code via `@testable import`.

Tests should NOT be in the main app target (that would include them in the production app).

## Viewing All Available Tests

In Test Navigator (⌘6), you should see a hierarchy:
```
Reczipes2Tests
  ├─ DiabeticCacheTests
  │   ├─ ingredientsHashConsistency
  │   ├─ ingredientsHashDifference
  │   ├─ recipeVersionIncrement
  │   ├─ cacheDetectsVersionChange
  │   ├─ cacheDetectsHashChange
  │   ├─ cacheExpiration
  │   └─ sha256HashStability
  └─ FODMAPSubstitutionTests
      └─ [other tests]
```

If you don't see this structure, the tests might not be compiled correctly.

## Next Steps

After adding the logging, run the tests again and:

1. **Look at the console** immediately after running
2. **Find the last log message** before failure
3. **Note the exact failure** message from Swift Testing
4. **Share that information** for more specific help

The logs will tell you exactly where the test is failing, making it much easier to fix!
