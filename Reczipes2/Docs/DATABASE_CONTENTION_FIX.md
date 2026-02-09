# Database Contention Fix

## Problem
The app was experiencing frequent "CoreData: debug: WAL checkpoint: Database busy" messages in the console, indicating database contention. This was causing performance issues and slowdowns.

## Root Causes

1. **Too-Frequent Auto-Sync**: Auto-sync was running every 20-60 seconds by default
2. **No Debouncing**: Multiple sync operations could run concurrently
3. **Excessive Logging**: Verbose debug logging was slowing down operations
4. **Frequent Database Saves**: Each sync performed multiple fetch and save operations

## Changes Made

### 1. Increased Minimum Sync Interval

**File**: `CloudKitSharingService.swift`

- Changed sync interval range from **20 seconds - 5 minutes** to **5 minutes - 30 minutes**
- Added minimum sync interval enforcement: `minimumSyncInterval = 300` (5 minutes)
- Updated default from 60 seconds to 300 seconds (5 minutes)

```swift
// Sync interval in seconds (5 minutes to 30 minutes)
@Published var syncInterval: TimeInterval

private let minimumSyncInterval: TimeInterval = 300 // 5 minutes minimum

// Default to 5 minutes if not set or too low
if self.syncInterval < minimumSyncInterval {
    self.syncInterval = 300 // 5 minutes
}
```

### 2. Added Sync Debouncing

**File**: `CloudKitSharingService.swift`

Added debounce mechanism to prevent syncs that are too close together:

```swift
private var lastSyncAttempt: Date?

private func performBackgroundSync(modelContext: ModelContext) async {
    // Debounce: prevent syncs that are too close together
    if let lastAttempt = lastSyncAttempt {
        let timeSinceLastSync = Date().timeIntervalSince(lastAttempt)
        if timeSinceLastSync < minimumSyncInterval {
            return
        }
    }

    lastSyncAttempt = Date()
    // ... sync logic
}
```

Manual syncs bypass the debounce to allow user-triggered refreshes.

### 3. Reduced Logging Verbosity

**Files**:
- `CloudKitSharingService.swift`
- `SharingSettingsView.swift`

Removed verbose emoji-heavy logging:
- Changed from detailed multi-line logs to concise single-line messages
- Removed unnecessary status logs that fired on every operation
- Kept essential error and completion messages

Before:
```swift
logInfo("🔄 AUTO-SYNC: Starting background sync...", category: "sharing")
logInfo("✅ AUTO-SYNC: Completed successfully in \(duration)s", category: "sharing")
```

After:
```swift
logInfo("Starting background sync", category: "sharing")
logInfo("Auto-sync completed in \(String(format: "%.1f", duration))s", category: "sharing")
```

### 4. Updated UI

**File**: `SharingSettingsView.swift`

Updated slider and footer text to reflect new intervals:

```swift
Slider(
    value: $sharingService.syncInterval,
    in: 300...1800,  // 5 min to 30 min
    step: 60
) {
    Text("Sync Interval")
} minimumValueLabel: {
    Text("5m")
} maximumValueLabel: {
    Text("30m")
}
```

Footer text updated to mention performance benefits:
> "Longer intervals reduce database load and improve app performance."

## Expected Results

### Performance Improvements
- **Reduced Database Contention**: Far fewer "Database busy" messages
- **Better Battery Life**: Less frequent background operations
- **Improved Responsiveness**: UI more responsive with less database locking
- **Lower Network Usage**: Fewer CloudKit API calls

### User Experience
- Auto-sync still works effectively (5-30 minute intervals are reasonable for community content)
- Manual sync button available for immediate updates
- Existing user settings will be automatically upgraded to 5-minute minimum

## Migration

No data migration required. The changes are backward compatible:

- If a user has `syncInterval < 300`, it will be automatically adjusted to 300 on next app launch
- Existing auto-sync preferences are preserved
- No changes to data models or CloudKit schema

## Testing Recommendations

1. **Monitor Console**: Check that "Database busy" messages are significantly reduced
2. **Test Auto-Sync**: Verify auto-sync still works at 5, 10, 15, 30 minute intervals
3. **Test Manual Sync**: Confirm manual sync button works immediately without debounce delay
4. **Check Performance**: App should feel snappier, especially when navigating between views

## Related Files

- `Reczipes2/Models/CloudKitSharingService.swift` - Auto-sync logic and debouncing
- `Reczipes2/Views/SharingSettingsView.swift` - UI controls for sync intervals
- `Reczipes2/Docs/DEBUG_LOGGING_CLEANUP.md` - Related debug logging cleanup

## Future Optimizations

If database contention continues to be an issue:

1. Consider batching multiple operations into single transactions
2. Implement background queue for non-critical database operations
3. Add more aggressive debouncing for user-triggered actions
4. Consider using `NSBatchUpdateRequest` for bulk updates
