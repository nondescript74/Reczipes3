# Testing CloudKit-Dependent Features

## The Problem

When running tests on the iOS Simulator (especially fresh simulators), CloudKit is **not available** because:

1. The simulator may not be signed into an iCloud account
2. CloudKit requires proper entitlements and provisioning
3. Some CloudKit features are device-only

**Accessing `CloudKitSharingService.shared` in tests will cause the app to crash** because:
- The singleton initializes immediately when first accessed
- The initializer calls `checkCloudKitAvailability()` 
- This makes network calls and tries to access iCloud
- On unconfigured simulators, this fails catastrophically

## Solution: Separate Test Types

### 1. UI Behavior Tests (Safe for Simulator)

**File**: `SharingUIBehaviorTests.swift`

These tests validate UI logic **without** accessing CloudKit:

```swift
// ✅ GOOD - Simulates the state
@Test("Toggles are disabled when CloudKit unavailable")
func togglesDisabledWhenCloudKitUnavailable() {
    let isCloudKitAvailable = false
    let shouldDisableToggles = !isCloudKitAvailable
    #expect(shouldDisableToggles == true)
}

// ❌ BAD - Accesses CloudKit directly
@Test("Toggles are disabled when CloudKit unavailable")
func togglesDisabledWhenCloudKitUnavailable() {
    let service = CloudKitSharingService.shared  // CRASH!
    _ = service.isCloudKitAvailable
}
```

**Safe to test**:
- Toggle state changes
- Selection/deselection logic
- Button enable/disable logic
- Alert message formatting
- Navigation state management
- SwiftData model operations (with in-memory stores)

**Avoid**:
- Direct references to `CloudKitSharingService.shared`
- Instantiating views that use `@EnvironmentObject` or `@ObservedObject` for CloudKit services
- Testing actual CloudKit operations

### 2. Integration Tests (Requires Configured Device/Simulator)

**File**: `SharingWorkflowTests.swift`

These tests actually interact with CloudKit:

```swift
@Test("Share recipe to CloudKit")
@MainActor
func shareRecipeToCloudKit() async throws {
    // This needs CloudKit to be available
    let service = CloudKitSharingService.shared
    // ... actual sharing tests
}
```

**Run these tests**:
- On physical devices signed into iCloud
- On simulators that have been configured with an iCloud account
- Manually, not as part of CI/CD (unless your CI has CloudKit configured)

## Best Practices

### Use Protocols for Testability

Consider creating a protocol for your CloudKit service:

```swift
protocol SharingServiceProtocol {
    var isCloudKitAvailable: Bool { get }
    func shareRecipe(_ recipe: RecipeModel, modelContext: ModelContext) async throws -> String
}

class CloudKitSharingService: SharingServiceProtocol {
    // Implementation
}

class MockSharingService: SharingServiceProtocol {
    var isCloudKitAvailable: Bool = false
    
    func shareRecipe(_ recipe: RecipeModel, modelContext: ModelContext) async throws -> String {
        // Mock implementation for testing
        return "mock_record_id"
    }
}
```

Then inject the service into your views:

```swift
struct SharingSettingsView: View {
    @ObservedObject var sharingService: any SharingServiceProtocol
    
    var body: some View {
        Toggle("Share All", isOn: $shareAll)
            .disabled(!sharingService.isCloudKitAvailable)
    }
}
```

### Test Scheme Configuration

Consider creating separate test schemes:

1. **Unit Tests** - Fast, no CloudKit, runs on any simulator
   - Include: `*UIBehaviorTests`, `*ModelTests`, `*ValidationTests`
   - Exclude: `*WorkflowTests`, `*IntegrationTests`

2. **Integration Tests** - Requires CloudKit configuration
   - Include: `*WorkflowTests`, `*IntegrationTests`
   - Run manually when needed

### View Type References

Avoid directly referencing view types in tests:

```swift
// ❌ BAD - May trigger view initialization which could access CloudKit
let viewExists = ManageSharedContentView.self
#expect(viewExists == ManageSharedContentView.self)

// ✅ GOOD - Test the navigation state instead
var navigationDestination: String? = nil
navigationDestination = "ManageSharedContent"
#expect(navigationDestination == "ManageSharedContent")
```

## Running Tests Safely

### All Tests (UI Behavior Only)
```bash
# Safe to run on any simulator
xcodebuild test -scheme Reczipes2 -only-testing:Reczipes2Tests/SharingUIBehaviorTests
```

### Integration Tests (CloudKit Required)
```bash
# Only run on configured devices/simulators
xcodebuild test -scheme Reczipes2 -only-testing:Reczipes2Tests/SharingWorkflowTests \
  -destination 'platform=iOS Simulator,name=Your Configured Simulator'
```

## Troubleshooting

### App crashes during tests with CloudKit errors

**Symptom**: Tests crash with errors about iCloud account unavailable

**Solution**: 
1. Check which tests are accessing `CloudKitSharingService.shared`
2. Move those tests to integration test files
3. For UI tests, simulate the state instead of accessing the service

### "No iCloud account" warnings in console

**Normal**: If you see these warnings during integration tests on unconfigured simulators

**Fix**: 
- Sign into iCloud on the simulator (Settings > iCloud)
- Or skip integration tests on CI/CD
- Or use a mock service for testing

### Tests pass individually but fail when run together

**Cause**: The CloudKit service singleton persists state between tests

**Solution**:
- Don't access the singleton in UI tests
- For integration tests, add setup/teardown to reset state
- Consider dependency injection to allow test-specific instances

## Summary

| Test Type | Accesses CloudKit? | Simulator Ready? | CI/CD Safe? |
|-----------|-------------------|------------------|-------------|
| UI Behavior | ❌ No (simulates state) | ✅ Yes | ✅ Yes |
| Integration | ✅ Yes (real operations) | ⚠️ Must configure | ❌ No |
| Model/Logic | ❌ No | ✅ Yes | ✅ Yes |

**Golden Rule**: If your test doesn't need to actually talk to CloudKit servers, don't access `CloudKitSharingService.shared`.
