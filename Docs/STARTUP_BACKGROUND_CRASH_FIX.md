# Startup Background Crash Fix

## Problem

The app would crash if another app put it in the background during startup. This was caused by several initialization tasks that couldn't handle being interrupted:

1. **ModelContainerManager** started a health check Task in its `init()` that assumed it would complete
2. **Reczipes2App** had multiple `.task` and `.onAppear` modifiers starting async work without checking if the app was still active
3. Async initialization tasks (version history, CloudKit diagnostics, App Clip data) could get interrupted, leaving the app in an inconsistent state

## Solution

### 1. Added Startup State Tracking

Added state variables to track initialization progress:

```swift
@State private var isInitializing = true
@State private var initializationComplete = false
```

### 2. Structured Startup Initialization

Created a new `performStartupInitialization()` method that:
- Checks `scenePhase` before each async operation
- Exits gracefully if app moves to background
- Performs initialization in clear steps with phase checks between them
- Marks initialization as complete only when fully done

```swift
@MainActor
private func performStartupInitialization() async {
    isInitializing = true
    
    // Step 1: Quick, non-blocking operations
    checkForAppClipData()
    
    // Check scene phase
    guard scenePhase != .background else {
        isInitializing = false
        return
    }
    
    // Step 2: Version history (with phase check)
    await initializeVersionHistory()
    
    // Check scene phase again
    guard scenePhase != .background else {
        isInitializing = false
        return
    }
    
    // Step 3: CloudKit diagnostics (with phase check)
    if !hasCompletedOnboarding {
        await onboarding.runComprehensiveDiagnostics()
        // ... more phase checks
    }
    
    isInitializing = false
    initializationComplete = true
}
```

### 3. Enhanced Scene Phase Handling

Updated `handleScenePhaseChange()` to:
- Resume interrupted initialization when returning to active state
- Cancel initialization cleanly when backgrounded
- Only run task restoration after initialization is complete

```swift
case .active:
    // If we were interrupted during initialization, retry it
    if isInitializing && !initializationComplete {
        Task { @MainActor in
            await performStartupInitialization()
        }
    } else if oldPhase == .background && initializationComplete {
        // Normal background return handling
        taskRestoration.checkForTaskRestoration()
    }

case .background:
    // If we're still initializing, mark it as cancelled
    if isInitializing {
        isInitializing = false
    }
```

### 4. Made ModelContainerManager Health Check Non-Blocking

Updated the health check in ModelContainerManager to:
- Add a small delay before starting (lets app initialize first)
- Check for Task cancellation at multiple points
- Exit gracefully if cancelled due to backgrounding

```swift
Task { @MainActor in
    // Delay to let app initialize
    try? await Task.sleep(nanoseconds: 500_000_000)
    
    // Check if cancelled
    guard !Task.isCancelled else {
        return
    }
    
    // Perform health check
    let isHealthy = await self.verifyContainerHealth()
    
    // Check cancellation again
    guard !Task.isCancelled else {
        return
    }
    
    // Continue with recovery if needed
}
```

### 5. Deferred Non-Critical Initialization

Moved non-critical initialization out of `.onAppear`:
- App Clip data checking moved to structured initialization
- Version history moved to structured initialization
- Only UI-critical state (license, API key) set in `.onAppear`

## Benefits

1. **No More Startup Crashes**: App gracefully handles backgrounding at any point during startup
2. **Resumable Initialization**: If interrupted, initialization automatically resumes when app returns to foreground
3. **Better Logging**: Clear log messages show when initialization is cancelled, resumed, or completed
4. **Non-Blocking**: Health checks and diagnostics don't block the main thread or prevent UI from appearing

## Testing

To verify the fix works:

1. Launch the app
2. Immediately switch to another app (during startup)
3. Return to the app
4. Verify:
   - App doesn't crash
   - Initialization resumes and completes
   - All features work normally
   - Logs show "Initialization cancelled" and "Resuming interrupted initialization" messages

## Related Files

- `Reczipes2/Reczipes2App.swift` - Main app struct with startup logic
- `Reczipes2/Managers/ModelContainerManager.swift` - Container health check
- `Reczipes2/Managers/AppStateManager.swift` - Scene phase tracking

## Future Improvements

Consider adding:
1. Progress indicator during long initializations
2. Timeout handling for stuck initialization tasks
3. Retry limits to prevent infinite retry loops
4. More granular cancellation checking in long-running operations
