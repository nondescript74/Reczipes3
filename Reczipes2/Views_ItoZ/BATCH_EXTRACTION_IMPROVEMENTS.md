# Batch Extraction Background Processing Improvements

## Overview
This document describes the major improvements made to the batch extraction system to enable background processing, prevent UI blocking, and provide enhanced progress tracking.

## Changes Made

### 1. New BatchExtractionManager (Singleton)

**File**: `BatchExtractionManager.swift` (NEW)

A new singleton manager that handles all batch extraction operations in the background:

- **Background Processing**: Uses `Task.detached(priority: .userInitiated)` to run extractions off the main thread
- **Persistent State**: As a singleton, state persists even when views are dismissed
- **Detailed Progress Tracking**: Tracks multiple levels of progress:
  - Overall extraction progress (N of M recipes)
  - Current step (fetching, analyzing, downloading images, saving)
  - Step-specific progress (e.g., image download progress)
  - Time tracking (elapsed time, estimated time remaining, average per recipe)

#### Key Features:

```swift
@MainActor
class BatchExtractionManager: ObservableObject {
    static let shared = BatchExtractionManager()
    
    // Published properties update UI automatically
    @Published var isExtracting: Bool
    @Published var currentStatus: ExtractionStatus?
    @Published var successCount: Int
    @Published var failureCount: Int
    @Published var recentlyExtracted: [RecipeModel]
    @Published var errorLog: [(link: String, error: String, timestamp: Date)]
    
    // Background extraction with full cancellation support
    func startBatchExtraction(links: [SavedLink])
    func pause()
    func resume()
    func stop()
}
```

#### Extraction Steps Tracked:
- `.fetching` - Fetching recipe page
- `.analyzing` - Analyzing with Claude AI
- `.downloadingImages` - Downloading images (with count)
- `.savingRecipe` - Saving recipe to database
- `.waiting` - Waiting between extractions
- `.complete` / `.failed` - Terminal states

### 2. Enhanced BatchExtractionView

**File**: `BatchExtractionView.swift` (UPDATED)

The view now connects to the singleton manager instead of creating its own instance:

#### Key Changes:

1. **Uses Singleton**: `@StateObject private var manager = BatchExtractionManager.shared`

2. **Auto-Dismisses on Start**: When "Start Batch Extraction" is clicked, the sheet dismisses and extraction continues in background

3. **Much More Detailed Progress Display**:
   - Overall progress bar with percentage
   - Current step indicator with custom icon and color
   - Image download progress (X of Y images)
   - Time statistics (elapsed time, average per recipe, estimated remaining)
   - Current link being processed with full details
   - Recently extracted recipes list (last 5)

4. **Enhanced Stats Display**:
   - Shows "Remaining" count during extraction (instead of "To Extract")
   - Success/Failed counts update in real-time
   - Error log includes timestamps

5. **Reconnection Support**: If user dismisses and reopens, the view automatically reconnects to the running extraction

#### Visual Improvements:

```swift
// Detailed progress section with step tracking
private func detailedProgressSection(status: ExtractionStatus) -> some View {
    // Overall progress bar
    // Current step with icon and progress
    // Image download counter
    // Time statistics
    // Current link info
}

// Recently extracted recipes
private var recentlyExtractedSection: some View {
    // Shows last 5 extracted recipes
}
```

### 3. SavedLinksView Integration

**File**: `SavedLinksView.swift` (UPDATED)

Added a persistent extraction progress banner that appears when batch extraction is active:

```swift
@StateObject private var extractionManager = BatchExtractionManager.shared

// Banner shown when extraction is active
private var batchExtractionBanner: some View {
    // Shows progress bar
    // Current extraction status
    // Tap to view full details
}
```

The banner:
- Appears at the top of SavedLinksView when extraction is running
- Shows current progress (X of Y recipes)
- Shows success count
- Is tappable to open the full BatchExtractionView
- Persists even if user navigates away and comes back

### 4. Configuration Changes

**File**: `BatchRecipeExtractorViewModel.swift` (UPDATED)

Updated the extraction parameters:
- **Interval**: Changed from 60 seconds (1 minute) to **5 seconds**
- **Max Batch Size**: Changed from 10 to **50 recipes**

These changes are reflected in both the old ViewModel (for backwards compatibility) and the new Manager.

## User Experience Flow

### Before:
1. User taps "Start Batch Extraction"
2. Modal stays open, blocking main UI
3. User must keep modal open to see progress
4. Only basic status messages shown
5. Limited to 10 recipes with 1-minute delays

### After:
1. User taps "Start Batch Extraction"
2. **Modal automatically dismisses**
3. Extraction continues in background
4. **Persistent banner** appears in SavedLinksView showing progress
5. User can navigate freely while extraction runs
6. **Tap banner** to see detailed progress anytime
7. **Much more information** during extraction:
   - Which step is running (fetching, analyzing, downloading, saving)
   - Image download progress
   - Time elapsed and estimated remaining
   - Last 5 successfully extracted recipes
   - Detailed error log with timestamps
8. Process up to **50 recipes** with only **5-second delays**

## Technical Benefits

### 1. Non-Blocking Architecture
- Uses `Task.detached` to move work off main thread
- UI remains responsive during extraction
- User can interact with app while processing continues

### 2. State Persistence
- Singleton pattern ensures state survives view dismissals
- No state loss when navigating away
- Can reconnect to in-progress extraction

### 3. Detailed Progress Tracking
- Multiple progress levels (overall, step, sub-step)
- Time estimation based on actual performance
- Rolling average for better ETA accuracy

### 4. Better Error Handling
- Comprehensive error log with timestamps
- Individual link failure doesn't stop batch
- Clear indication of what failed and why

### 5. Improved Performance
- 5-second intervals (vs. 60 seconds) = 12x faster
- 50 recipe limit (vs. 10) = 5x more per batch
- Combined: Can process 5x more recipes in 1/12 the time

## Implementation Details

### Background Task Management

The extraction runs in a detached task that:
1. Checks for cancellation regularly
2. Supports pause/resume
3. Updates UI via `@MainActor.run { ... }`
4. Persists state after each recipe

```swift
extractionTask = Task.detached(priority: .userInitiated) { [weak self] in
    await self?.performBatchExtraction(...)
}
```

### Progress Updates

Status updates happen at multiple points:
- Start of each recipe
- During each extraction step
- After image downloads
- On success/failure

### Error Recovery

- Individual failures don't stop the batch
- Failed links marked with error message
- Can retry failed links later
- Comprehensive error log maintained

## Testing Considerations

When testing:
1. Start extraction and immediately dismiss view
2. Navigate to other tabs
3. Return to SavedLinksView to see banner
4. Tap banner to view detailed progress
5. Test pause/resume functionality
6. Test stop confirmation
7. Verify state persists across view dismissals
8. Check error log for failed extractions

## Future Enhancements

Potential improvements:
1. **Background Refresh**: Allow extraction to continue even when app is backgrounded
2. **Notifications**: Send notification when batch completes
3. **Selective Extraction**: Pick specific links to extract in batch
4. **Scheduling**: Schedule extraction for later time
5. **Cloud Sync**: Sync extraction state across devices
6. **Better Throttling**: Dynamic delays based on API response times

## Migration Notes

The old `BatchRecipeExtractorViewModel` is still present for backwards compatibility but should not be used for new implementations. All new code should use `BatchExtractionManager.shared`.

To migrate existing code:
```swift
// Old
@State private var viewModel: BatchRecipeExtractorViewModel?

// New
@StateObject private var manager = BatchExtractionManager.shared
```

## Summary

These changes transform batch extraction from a blocking, modal operation into a smooth, background process that users can monitor at their convenience. The extraction is now:
- ✅ Non-blocking
- ✅ Background-capable
- ✅ Much faster (5 sec intervals, 50 recipe limit)
- ✅ More informative (detailed progress tracking)
- ✅ More resilient (survives view dismissals)
- ✅ More user-friendly (auto-dismiss, persistent banner)
