# Keep Awake Feature Implementation

## Overview
Added a "Keep Awake" feature to prevent the device from sleeping during long recipe extraction operations. This is especially useful during batch extractions that can take several minutes.

## New File: KeepAwakeManager.swift

A simple singleton manager that controls the device's idle timer:

- **`enable()`** - Prevents the device from sleeping
- **`disable()`** - Restores normal sleep behavior
- **`toggle()`** - Toggles the keep awake state
- **`isKeepAwakeEnabled`** - Published property for UI binding

Uses `UIApplication.shared.isIdleTimerDisabled` to control the device sleep state.

## Integration Points

### 1. RecipeExtractorView (Extract Tab)

**Manual Control:**
- Added a toolbar button in the top-left corner
- Shows "moon.zzz" icon (filled when enabled, outline when disabled)
- Displays "Stay Awake" text when enabled
- Users can tap to toggle the keep awake state

**Location:** Navigation bar leading position

### 2. BatchImageExtractorView

**Automatic Control:**
- Keep awake is automatically enabled when batch extraction starts
- Automatically disabled when batch extraction completes or stops
- Disabled when the view disappears (if extraction is not running)

**Implementation:**
```swift
.onChange(of: viewModel.isExtracting) { oldValue, newValue in
    if newValue {
        keepAwakeManager.enable()
    } else if oldValue {
        keepAwakeManager.disable()
    }
}
```

### 3. BatchRecipeExtractorView

**Automatic Control:**
- Same automatic behavior as BatchImageExtractorView
- Enables during URL-based batch extraction
- Disables when complete or stopped

### 4. BatchExtractionStatusBar

**Visual Indicator:**
- Shows a blue "moon.zzz.fill" icon next to the extraction title when keep awake is active
- Provides visual feedback that the device will stay awake during the operation

## User Experience

### Manual Mode (Extract Tab)
1. User opens the Extract tab
2. User can tap the "moon.zzz" button to enable keep awake
3. Icon fills and text "Stay Awake" appears
4. Device will not sleep until user taps again or leaves the tab

### Automatic Mode (Batch Extraction)
1. User starts a batch extraction (images or URLs)
2. Keep awake is automatically enabled
3. Blue moon icon appears in the status bar
4. Device stays awake throughout the entire batch process
5. Keep awake automatically disables when batch completes

## Benefits

1. **Prevents Interruption**: Long batch extractions won't be interrupted by device sleep
2. **User Awareness**: Visual indicators show when keep awake is active
3. **Automatic Management**: No need to remember to enable it for batch operations
4. **Battery Consideration**: Only enabled during actual extraction work
5. **Graceful Cleanup**: Automatically disables when views disappear or operations complete

## Implementation Notes

- Uses `@MainActor` to ensure all operations are on the main thread
- Singleton pattern ensures consistent state across the app
- Logging included for debugging keep awake state changes
- No impact on app lifecycle or background processing
- Works alongside BackgroundProcessingManager for backgrounded operations

## Future Enhancements

Potential improvements:
1. Add a setting to disable automatic keep awake for batch operations
2. Show battery level warning if keep awake is used extensively
3. Add keep awake to single recipe extraction (currently manual only)
4. Provide haptic feedback when toggling keep awake
