# Background Processing Crash Fix

## Problem Summary

The app was crashing when going into the background during batch recipe extraction. This was happening in the simulator and potentially on devices as well.

## Root Causes

### 1. **Incorrect Actor Isolation on BackgroundProcessingManager**
- The entire `BackgroundProcessingManager` class was marked with `@MainActor`
- Background tasks (`BGProcessingTask`) run on background threads
- Forcing these to run on `@MainActor` caused crashes when the main thread was suspended

### 2. **Thread-Safety Issues**
- Multiple properties were being accessed from different threads without synchronization
- `backgroundTask` identifier was being accessed from both main thread and background threads
- `pendingExtractions` array was being modified from multiple contexts

### 3. **Race Conditions During State Transitions**
- When the app transitions to background, the main thread can be suspended
- Calling `@MainActor` methods from background contexts caused deadlocks/crashes

## Changes Made

### BackgroundProcessingManager.swift

#### 1. **Removed Global `@MainActor` Annotation**
```swift
// Before:
@MainActor
class BackgroundProcessingManager: ObservableObject { ... }

// After:
class BackgroundProcessingManager: ObservableObject { ... }
```

#### 2. **Added Thread-Safe Property Access**
```swift
// Added NSLock for thread safety
private let backgroundTaskLock = NSLock()
private var _backgroundTask: UIBackgroundTaskIdentifier = .invalid
private var backgroundTask: UIBackgroundTaskIdentifier {
    get {
        backgroundTaskLock.lock()
        defer { backgroundTaskLock.unlock() }
        return _backgroundTask
    }
    set {
        backgroundTaskLock.lock()
        defer { backgroundTaskLock.unlock() }
        _backgroundTask = newValue
    }
}

private let queueLock = NSLock()
private var pendingExtractions: [(imageData: Data, index: Int)] = []
```

#### 3. **Isolated UI State Updates to Main Actor**
```swift
// Published properties now explicitly marked for main actor
@MainActor @Published var isBackgroundTaskActive = false
@MainActor @Published var backgroundProgress: Double = 0.0
```

#### 4. **Fixed Background Task Registration**
```swift
// Before:
Task { @MainActor in
    await self.handleBackgroundProcessing(task: task as! BGProcessingTask)
}

// After:
Task.detached {
    await self.handleBackgroundProcessing(task: task as! BGProcessingTask)
}
```
Now runs on background thread instead of forcing to main thread.

#### 5. **Updated Background Task Start/End**
```swift
func beginBackgroundTask(name: String = "Recipe Extraction") {
    endBackgroundTask()
    
    let newTask = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
        logWarning("Background task expired, cleaning up", category: "background")
        self?.endBackgroundTask()
    }
    
    backgroundTask = newTask
    
    if newTask != .invalid {
        Task { @MainActor in
            self.isBackgroundTaskActive = true
        }
        logInfo("Background task started: \(name)", category: "background")
    }
}
```
UI updates now happen explicitly on main actor.

#### 6. **Made Background Processing Thread-Safe**
```swift
private func handleBackgroundProcessing(task: BGProcessingTask) async {
    // Get pending extractions safely
    queueLock.lock()
    let extractionsToProcess = pendingExtractions
    queueLock.unlock()
    
    // ... process on background thread ...
    
    // Update UI on main actor
    await MainActor.run {
        self.backgroundProgress = progress
    }
    
    // Clear queue safely
    queueLock.lock()
    pendingExtractions.removeAll()
    queueLock.unlock()
}
```

#### 7. **Thread-Safe Queue Management**
```swift
func queueExtractions(images: [(data: Data, index: Int)]) {
    queueLock.lock()
    defer { queueLock.unlock() }
    
    let converted = images.map { (imageData: $0.data, index: $0.index) }
    pendingExtractions.append(contentsOf: converted)
}

var pendingCount: Int {
    queueLock.lock()
    defer { queueLock.unlock() }
    return pendingExtractions.count
}
```

### BatchImageExtractorViewModel.swift

#### Fixed Main Actor Coordination
```swift
private func startBackgroundExtractionWithProcessedImages(...) async {
    // Start background task on main thread (UI operation)
    await MainActor.run {
        backgroundManager.beginBackgroundTask(name: "Batch Recipe Extraction")
    }
    
    // ... processing ...
    
    // End background task on main thread
    await MainActor.run {
        backgroundManager.endBackgroundTask()
    }
}
```

## Testing Recommendations

### 1. **Simulator Testing**
- Test batch extraction with 10+ images
- Send app to background (Cmd+Shift+H or Device > Home)
- Bring app back to foreground
- Verify extraction continues without crash

### 2. **Device Testing**
- Test on actual iOS device
- Start batch extraction
- Switch to another app
- Wait 30 seconds
- Return to app
- Verify no crash and state restored correctly

### 3. **Stress Testing**
- Start extraction with 50+ images
- Rapidly switch between foreground/background
- Force app termination (swipe up in app switcher)
- Restart app and verify state restoration

## Additional Considerations

### Info.plist Configuration
Ensure you have the background task identifier in Info.plist:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.yourapp.reczipes.backgroundExtraction</string>
</array>
```

### Background Modes
Ensure you have enabled necessary background modes in Xcode:
- **Processing** (for BGProcessingTask)
- **Background fetch** (optional, for periodic updates)

### Time Limits
- **UIApplication.shared.beginBackgroundTask**: ~30 seconds
- **BGProcessingTask**: Several minutes (system decides)
- Plan accordingly and save progress frequently

## Architecture Notes

### Thread Safety Pattern
```
┌─────────────────────────────────────────────┐
│         BackgroundProcessingManager         │
├─────────────────────────────────────────────┤
│                                             │
│  [Main Thread]         [Background Thread]  │
│                                             │
│  • UI Updates          • Image Processing   │
│  • Published vars      • API Calls          │
│  • State changes       • Data conversion    │
│                                             │
│         Synchronized via:                   │
│         • NSLock (data access)              │
│         • await MainActor.run (UI updates)  │
│                                             │
└─────────────────────────────────────────────┘
```

### Actor Isolation Strategy
1. **Main Actor**: UI updates, published properties, SwiftUI state
2. **Background Thread**: Image processing, API calls, data conversion
3. **Explicit Synchronization**: NSLock for shared data structures
4. **Explicit Main Actor Dispatch**: `await MainActor.run { }` for UI updates from background

## Known Limitations

1. **Background time is limited** - iOS gives ~30 seconds for foreground background tasks
2. **BGProcessingTask not guaranteed** - System may not schedule if battery low or user disabled
3. **Network required** - API calls need network connectivity
4. **State restoration** - Must properly save/restore state for app termination scenarios

## Future Improvements

1. **Add progress persistence** - Save extraction progress to disk
2. **Implement retry logic** - Handle failed extractions when app resumes
3. **Add user notifications** - Notify when background extraction completes
4. **Better error handling** - More granular error recovery for different failure modes
5. **Rate limiting** - Prevent API rate limit issues during batch processing

## Related Files

- `BackgroundProcessingManager.swift` - Background task management
- `BatchImageExtractorViewModel.swift` - Batch extraction UI logic
- `Reczipes2App.swift` - App lifecycle and scene phase handling
- `BatchExtractionManager.swift` - (Review for similar issues)

## Date Fixed
February 1, 2026
