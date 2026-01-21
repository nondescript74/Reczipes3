# Background Extraction Setup Guide

## Overview

This guide explains how background recipe extraction works in Reczipes2, a **pure SwiftUI app** (no UIKit AppDelegate needed).

## How It Works

When users select multiple images for extraction and the app goes to background, the extraction continues using a **hybrid approach**:

### 1. SwiftUI Scene Phase Changes (Already Working ✅)

```swift
.onChange(of: scenePhase) { oldPhase, newPhase in
    switch newPhase {
    case .background:
        // Trigger background processing
        BackgroundProcessingManager.shared.handleAppDidEnterBackground()
    case .active:
        BackgroundProcessingManager.shared.handleAppWillEnterForeground()
    }
}
```

### 2. UIKit Background Task (For Extended Background Time)

The `BackgroundProcessingManager` uses `UIApplication.shared.beginBackgroundTask()` to request ~30 seconds of background execution time. This is **completely fine to use in SwiftUI apps** - you don't need AppDelegate for this!

```swift
// In BackgroundProcessingManager.swift
func beginBackgroundTask(name: String = "Recipe Extraction") {
    backgroundTask = UIApplication.shared.beginBackgroundTask(withName: name) {
        // Task expiration handler
        self.endBackgroundTask()
    }
}
```

### 3. SwiftUI Background Task Modifier (New! ✅)

We've added the modern `.backgroundTask` modifier for system-scheduled background processing:

```swift
.backgroundTask(.appRefresh("recipe-extraction")) { 
    await handleBackgroundExtractionTask()
}
```

## Required Configuration

### Step 1: Update Info.plist

Add background modes to your `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
    <string>fetch</string>
</array>
```

### Step 2: Register Background Task Identifier

Add to your `Info.plist`:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>recipe-extraction</string>
</array>
```

### Step 3: Request User Notification Permission (Optional)

To notify users when background extraction completes, request notification permission in your `SettingsView` or during onboarding:

```swift
import UserNotifications

UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
    if granted {
        logInfo("Notification permission granted", category: "notifications")
    }
}
```

## How It Currently Works

### When User Selects Images Without Cropping

1. User selects multiple images in `BatchImageExtractorView`
2. User unchecks "Enable cropping" toggle
3. Extraction begins using `startBackgroundExtractionFromImages()`
4. `BackgroundProcessingManager.beginBackgroundTask()` is called
5. If user backgrounds the app:
   - Extraction continues for ~30 seconds (iOS background execution limit)
   - Remaining items are queued for later processing
   - A `BGProcessingTask` is scheduled for when the system allows

### When User Selects Images With Cropping

Cropping requires user interaction, so extraction **cannot continue in background**. The app will:
- Show "Resume extraction" prompt when user returns
- Use `TaskRestorationCoordinator` to restore state

## Testing Background Processing

### Test Extended Background Time

1. Start batch extraction with 20+ images (cropping disabled)
2. Press Home button (Cmd+Shift+H in Simulator)
3. Watch Xcode console - you'll see extraction continue for ~30 seconds
4. After 30 seconds, task expires and remaining items are queued

### Test Background Task Scheduling

Run this in Terminal to trigger background task immediately:

```bash
# For Simulator
e -l swift -- -c 'import BackgroundTasks; BGTaskScheduler.shared.debugScheduler.executeLaunchHandler(forTaskWithIdentifier: "recipe-extraction")'

# For Device (via Xcode)
# 1. Set breakpoint in handleBackgroundExtractionTask()
# 2. When app is in background, run in Xcode console:
#    e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"recipe-extraction"]
```

## Why We're NOT Using AppDelegate

**You asked: "Why are we using UIKit and AppDelegate when we are SwiftUI app?"**

**Answer: We're NOT!** 

- The app uses the modern SwiftUI `@main` app lifecycle
- No AppDelegate or SceneDelegate anywhere
- `UIApplication.shared.beginBackgroundTask()` can be called from **anywhere**, not just AppDelegate
- This is a common pattern in SwiftUI apps that need background processing

## Architecture

```
Reczipes2App.swift (SwiftUI @main)
    ↓
    ├─ Scene phase changes (.onChange)
    │   └─ BackgroundProcessingManager.handleAppDidEnterBackground()
    │
    ├─ Background task modifier (.backgroundTask)
    │   └─ handleBackgroundExtractionTask()
    │
    └─ BatchImageExtractorViewModel
        ├─ startBackgroundExtractionFromImages()
        └─ BackgroundProcessingManager.beginBackgroundTask()
```

## Current Status

✅ Scene phase monitoring enabled  
✅ Background task requests implemented  
✅ SwiftUI `.backgroundTask` modifier added  
⚠️ Needs Info.plist configuration (see Step 1 & 2 above)  
⚠️ Needs testing with real background scenarios  

## Debugging Tips

### Enable Background Task Logging

Add to scheme environment variables:
```
-BGTaskSchedulerDebug 1
```

### Check Background Time Remaining

Add to `BackgroundProcessingManager`:

```swift
func checkBackgroundTimeRemaining() {
    let timeRemaining = UIApplication.shared.backgroundTimeRemaining
    if timeRemaining != .infinity {
        logInfo("Background time remaining: \(timeRemaining) seconds", category: "background")
    }
}
```

## Next Steps

1. **Add Info.plist entries** (see Step 1 & 2)
2. **Test background extraction** with 50+ images
3. **Request notification permission** for completion alerts
4. **Monitor console logs** during background processing
5. **Consider chunking API requests** to fit within 30-second window

## FAQ

**Q: Will extraction continue if user force-quits the app?**  
A: No, force-quit terminates all background tasks. This is iOS system behavior.

**Q: How long can background tasks run?**  
A: About 30 seconds for `beginBackgroundTask()`, longer (but unpredictable timing) for `BGProcessingTask`.

**Q: What happens if API calls take longer than 30 seconds?**  
A: The `BackgroundProcessingManager` queues remaining items and schedules a `BGProcessingTask` for later. Users will get a notification when complete.

**Q: Why not just use `BGProcessingTask` alone?**  
A: `BGProcessingTask` is scheduled by the system at unpredictable times (could be hours later). `beginBackgroundTask()` gives immediate 30-second window when app backgrounds.

**Q: Do I need to add AppDelegate for this?**  
A: **NO!** Everything works with pure SwiftUI app lifecycle.
