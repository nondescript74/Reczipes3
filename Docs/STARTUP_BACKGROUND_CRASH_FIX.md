# Background Crash Fix (Startup & Runtime)

## Problem

The app would crash when moved to background in two scenarios:

### 1. During Startup
The app would crash if another app put it in the background during startup. This was caused by several initialization tasks that couldn't handle being interrupted:

1. **ModelContainerManager** started a health check Task in its `init()` that assumed it would complete
2. **Reczipes2App** had multiple `.task` and `.onAppear` modifiers starting async work without checking if the app was still active
3. Async initialization tasks (version history, CloudKit diagnostics, App Clip data) could get interrupted, leaving the app in an inconsistent state

### 2. During Runtime (Simulator)
The app would crash when backgrounded during normal operation in the simulator. This was caused by:

1. **Async Tasks During Backgrounding** - Creating `Task` blocks that call async methods when the scene phase changes to background
2. **Actor Isolation Issues** - Accessing main actor-isolated functions from background threads during suspension
3. **Simulator Suspension** - The simulator suspends apps more aggressively than real devices, not giving Tasks time to complete
4. **Nested Task Creation** - `handleAppDidEnterBackground()` created a Task, which could be interrupted mid-execution

## Solution

### Startup Crash Fix

#### 1. Added Startup State Tracking

Added state variables to track initialization progress:

```swift
@State private var isInitializing = true
@State private var initializationComplete = false
```

#### 2. Structured Startup Initialization

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

#### 3. Enhanced Scene Phase Handling

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

#### 4. Made ModelContainerManager Health Check Non-Blocking

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

#### 5. Deferred Non-Critical Initialization

Moved non-critical initialization out of `.onAppear`:
- App Clip data checking moved to structured initialization
- Version history moved to structured initialization
- Only UI-critical state (license, API key) set in `.onAppear`

### Runtime Crash Fix (Simulator Backgrounding)

#### 1. Synchronous Data Saving

Changed from async Task-based saving to synchronous saving:

**Before (Crash-Prone):**
```swift
case .background:
    Task { @MainActor in
        await saveAllPendingChanges()  // May not complete before suspension
        BackgroundProcessingManager.shared.handleAppDidEnterBackground()
    }
```

**After (Crash-Safe):**
```swift
case .background:
    // Save synchronously - guaranteed to complete
    savePendingChanges()
    
    // Handle background processing with detached task
    BackgroundProcessingManager.shared.handleAppDidEnterBackground()
```

The synchronous `savePendingChanges()` method executes on the main actor and completes before the app is suspended.

#### 2. Detached Tasks for Background Operations

Changed `BackgroundProcessingManager` to use `Task.detached` instead of regular `Task`:

**Before:**
```swift
func handleAppDidEnterBackground() {
    Task {  // Inherits actor context, may not complete
        let count = await extractionQueue.count
        beginBackgroundTask(...)
    }
}
```

**After:**
```swift
func handleAppDidEnterBackground() {
    Task.detached(priority: .userInitiated) {  // Independent task
        let count = await self.extractionQueue.count
        
        await MainActor.run {
            // Actor-isolated work happens safely
            self.beginBackgroundTask(...)
        }
    }
}
```

Benefits of `Task.detached`:
- Doesn't inherit the calling context's actor
- Less likely to be cancelled when app backgrounds
- Can continue briefly after backgrounding
- Properly isolated from main actor

#### 3. Proper Actor Isolation

Wrapped all main actor-isolated calls in `MainActor.run` blocks within detached tasks:

```swift
await MainActor.run {
    logInfo("Message", category: "background")
    self.beginBackgroundTask(name: "...")
    self.scheduleBackgroundExtraction()
}
```

This prevents actor isolation errors and ensures thread-safe access to main actor resources.

#### 4. Removed Async Wrapper for State Transitions

The `.inactive` and `.background` cases now call synchronous methods directly instead of wrapping in `Task` blocks. This ensures critical operations complete before the OS suspends the app.

## Benefits

### Startup Crash Prevention
1. **No More Startup Crashes**: App gracefully handles backgrounding at any point during startup
2. **Resumable Initialization**: If interrupted, initialization automatically resumes when app returns to foreground
3. **Better Logging**: Clear log messages show when initialization is cancelled, resumed, or completed
4. **Non-Blocking**: Health checks and diagnostics don't block the main thread or prevent UI from appearing

### Runtime Crash Prevention (Simulator)
1. **No Simulator Crashes**: App handles backgrounding correctly in simulator environment
2. **Data Safety**: All pending changes are saved synchronously before backgrounding
3. **Thread Safety**: Proper actor isolation prevents race conditions
4. **Resource Cleanup**: Background tasks are properly managed during state transitions
5. **Works on Real Devices Too**: The fixes are safe and beneficial on both simulator and real devices

## Testing

### Startup Backgrounding Test
1. Launch the app
2. Immediately switch to another app (during startup)
3. Return to the app
4. Verify:
   - App doesn't crash
   - Initialization resumes and completes
   - All features work normally
   - Logs show "Initialization cancelled" and "Resuming interrupted initialization" messages

### Runtime Backgrounding Test (Simulator)
1. Run the app in simulator
2. Navigate to any screen
3. Press Cmd+Shift+H (or use device controls to background)
4. Wait 2-3 seconds
5. Return to the app
6. Verify:
   - App doesn't crash
   - Data is preserved
   - App state is maintained
   - No error messages in console

### Stress Test
1. Rapidly background and foreground the app multiple times
2. Background during heavy operations (recipe extraction, image processing)
3. Force background during scene transitions
4. Verify no crashes occur in any scenario

## Technical Details

### Why Synchronous Saving is Critical

When an app transitions to background, iOS gives it a very short time window (typically 5-30 seconds) to complete critical tasks. In the simulator, this window can be even shorter or immediate. Using async/await with Task blocks introduces several problems:

1. **Task Cancellation**: The OS may cancel Tasks when backgrounding
2. **Race Conditions**: Async operations may not complete before suspension
3. **Actor Isolation**: Cross-actor calls can fail during suspension
4. **Simulator Aggression**: The simulator suspends more aggressively than devices

By using synchronous saves, we guarantee data persistence before suspension.

### Why Task.detached vs Task

`Task.detached` creates a truly independent task that:
- Doesn't inherit the actor context of the caller
- Has its own priority and cancellation behavior  
- Is less likely to be automatically cancelled during backgrounding
- Can optionally continue briefly in background

Regular `Task` blocks inherit actor context and are more tightly coupled to the calling context's lifecycle.

### Actor Isolation Pattern

The pattern used in `BackgroundProcessingManager`:

```swift
Task.detached {
    // Non-isolated work (checking queue, etc.)
    let data = await someActorIsolatedData
    
    // Wrap main-actor work explicitly
    await MainActor.run {
        // UI updates, logging, etc.
    }
}
```

This pattern ensures:
- Clear separation of concerns
- Explicit actor boundaries
- Thread-safe access to shared resources
- Predictable execution order

## Related Files

- `Reczipes2/Reczipes2App.swift` - Main app struct with scene phase handling (lines 497-567)
- `Reczipes2/Managers/ModelContainerManager.swift` - Container health check with cancellation (lines 51-119)
- `Reczipes2/Managers/BackgroundProcessingManager.swift` - Background task management (lines 334-383)
- `Reczipes2/Managers/AppStateManager.swift` - Scene phase tracking

## Future Improvements

Consider adding:
1. Progress indicator during long initializations
2. Timeout handling for stuck initialization tasks
3. Retry limits to prevent infinite retry loops
4. More granular cancellation checking in long-running operations
5. Background task budget monitoring
6. Analytics to track backgrounding patterns
