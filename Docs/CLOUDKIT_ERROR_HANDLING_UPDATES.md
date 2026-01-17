# CloudKit Error Handling Updates

## Summary
Updated CloudKit sharing functionality to provide better error messages and guide users to the Setup & Diagnostics screen when CloudKit is not available.

## Changes Made

### 1. SharedContentModels.swift
**Updated `SharingError` enum:**
- Modified `cloudKitUnavailable` case to accept an optional custom message
- Added `canOpenOnboarding` computed property to determine if the error should show the onboarding option
- Errors like `cloudKitUnavailable` and `notAuthenticated` will now show an "Open Setup & Diagnostics" button

```swift
enum SharingError: LocalizedError {
    case notAuthenticated
    case cloudKitUnavailable(message: String? = nil)  // ← Now accepts custom message
    case recipeNotFound
    case bookNotFound
    case uploadFailed(Error)
    case downloadFailed(Error)
    case invalidData
    case imageUploadFailed(Error)
    
    var canOpenOnboarding: Bool {
        switch self {
        case .cloudKitUnavailable, .notAuthenticated:
            return true
        default:
            return false
        }
    }
}
```

### 2. CloudKitSharingService.swift
**Updated all CloudKit availability checks:**
- `shareRecipe(_:modelContext:)` 
- `shareRecipeBook(_:modelContext:)`
- `fetchSharedRecipes(limit:)`
- `fetchSharedRecipeBooks(limit:)`
- `unshareRecipe(cloudRecordID:modelContext:)`
- `unshareRecipeBook(cloudRecordID:modelContext:)`

All now throw a more helpful error message:

```swift
guard isCloudKitAvailable else {
    throw SharingError.cloudKitUnavailable(
        message: "CloudKit is not available. Please run Setup & Diagnostics in Settings."
    )
}
```

### 3. SharingSettingsView.swift
**Added error handling with onboarding support:**

Added state variables:
```swift
@State private var showingOnboarding = false
@State private var currentSharingError: SharingError?
```

Added new alert that can open the onboarding view:
```swift
.alert("Sharing Failed", isPresented: Binding(
    get: { currentSharingError != nil },
    set: { if !$0 { currentSharingError = nil } }
)) {
    if let error = currentSharingError, error.canOpenOnboarding {
        Button("Open Setup & Diagnostics") {
            showingOnboarding = true
            currentSharingError = nil
        }
    }
    Button("OK", role: .cancel) {
        currentSharingError = nil
    }
} message: {
    if let error = currentSharingError {
        Text(error.localizedDescription ?? "An unknown error occurred.")
    }
}
.sheet(isPresented: $showingOnboarding) {
    CloudKitOnboardingView()
}
```

Updated all sharing action methods to catch `SharingError` and set `currentSharingError`:
- `shareAllRecipes()`
- `shareAllBooks()`
- `shareRecipes(_:)`
- `shareBooks(_:)`

**Implemented `SharedRecipesBrowserView`:**
- Full-featured community recipes browser
- Proper error handling with onboarding option
- Swipe to import recipes
- Pull to refresh functionality

## User Experience Flow

### Before
1. User tries to share without CloudKit setup
2. Gets generic error: "CloudKit is not available. Check your iCloud settings."
3. User is left wondering what to do

### After
1. User tries to share without CloudKit setup
2. Gets helpful error: "CloudKit is not available. Please run Setup & Diagnostics in Settings."
3. Alert shows two buttons:
   - **"Open Setup & Diagnostics"** - Opens CloudKitOnboardingView directly
   - **"OK"** - Dismisses the alert
4. If user taps "Open Setup & Diagnostics", they see the comprehensive onboarding view with:
   - Current CloudKit status
   - What's working and what's not
   - Repair options
   - Detailed diagnostics

## Testing Checklist

- [ ] Test sharing a recipe when CloudKit is unavailable
- [ ] Test sharing a recipe book when CloudKit is unavailable
- [ ] Test browsing community recipes when CloudKit is unavailable
- [ ] Verify "Open Setup & Diagnostics" button appears
- [ ] Verify onboarding view opens when button is tapped
- [ ] Verify other errors (like upload failures) don't show the onboarding button
- [ ] Test on device with iCloud signed out
- [ ] Test on device with CloudKit restricted

## Related Files
- `CloudKitOnboardingService.swift` - The diagnostic service
- `CloudKitOnboardingView.swift` - The setup UI
- `SharedContentModels.swift` - Error definitions
- `CloudKitSharingService.swift` - Sharing implementation
- `SharingSettingsView.swift` - Settings UI with error handling

## Benefits

1. **Better User Experience**: Users are guided to the solution instead of being left confused
2. **Reduced Support Burden**: Clear path to fixing CloudKit issues
3. **Consistent Error Handling**: All CloudKit operations use the same pattern
4. **Informative Diagnostics**: Users can see exactly what's wrong and how to fix it
5. **Self-Service Repair**: Users can attempt to fix issues without contacting support
