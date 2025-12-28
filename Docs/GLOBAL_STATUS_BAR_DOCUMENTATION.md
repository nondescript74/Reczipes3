# Global Batch Extraction Status Bar

## Overview
A persistent, app-wide status bar that displays batch extraction progress at the top of any view, allowing users to monitor ongoing extractions without being confined to a modal window.

## Implementation

### New File: `BatchExtractionStatusBar.swift`

This file contains three main components:

#### 1. BatchExtractionStatusBar (Main Status Bar)
A compact, non-intrusive banner that appears at the top of views during batch extraction.

**Features:**
- Animated progress indicator
- Current progress (X/Y recipes)
- Success and failure counts
- Overall progress percentage
- Cancel button for quick stop
- Tappable to view detailed progress
- Thin progress bar showing visual progress

**Visual Design:**
```
┌────────────────────────────────────────────────┐
│ ◌ Extracting Recipes            75%    ✕      │
│   5/20 • 4 succeeded • 1 failed                │
│ ▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░                 │
└────────────────────────────────────────────────┘
```

**Interactions:**
- **Tap anywhere**: Opens detailed progress sheet
- **Tap X button**: Shows cancel confirmation alert

#### 2. BatchExtractionDetailsSheet
A full sheet showing comprehensive extraction details when the status bar is tapped.

**Sections:**
1. **Overall Progress**
   - Progress bar with percentage
   - Current step indicator with icon
   - Time elapsed and estimated remaining
   - Average time per recipe

2. **Current Recipe**
   - Recipe being extracted right now
   - Visual indicator with icon

3. **Recently Extracted**
   - Last 5 successfully extracted recipes
   - Quick visual confirmation of progress

4. **Statistics**
   - Success count with green indicator
   - Failure count with red indicator (if any)
   - Visual stat cards

5. **Error Log**
   - Shows first 3 errors inline
   - Indicates if more errors exist
   - Each error shows: link name, error message

**Toolbar Actions:**
- Close: Dismiss the sheet (extraction continues)
- Pause/Resume: Control extraction flow
- Stop: Permanently stop extraction (with confirmation)

#### 3. ViewModifier for Integration
A convenient view modifier for easy integration:

```swift
extension View {
    func batchExtractionStatusBar() -> some View {
        modifier(BatchExtractionStatusBarModifier())
    }
}
```

## Integration Points

### ContentView.swift
Added status bar at the top of the main content view:

```swift
var body: some View {
    VStack(spacing: 0) {
        // Global batch extraction status bar
        BatchExtractionStatusBar(manager: BatchExtractionManager.shared)
        
        NavigationSplitView {
            // ... existing content
        }
    }
}
```

**Result**: Status bar appears above the recipe list and detail view.

### SettingsView.swift
Added status bar at the top of settings:

```swift
var body: some View {
    VStack(spacing: 0) {
        // Global batch extraction status bar
        BatchExtractionStatusBar(manager: BatchExtractionManager.shared)
        
        NavigationView {
            // ... existing content
        }
    }
}
```

**Result**: Status bar appears even when browsing settings.

### SavedLinksView.swift
Removed local banner implementation since global one handles it:

**Changes:**
- Removed `@StateObject private var extractionManager`
- Removed local `batchExtractionBanner` view
- Simplified body to remove conditional banner display

**Result**: SavedLinksView now uses the global status bar like all other views.

## User Experience Flow

### Starting Extraction
1. User opens SavedLinksView
2. Taps "Batch Extract All Unprocessed"
3. BatchExtractionView sheet appears
4. User taps "Start Batch Extraction"
5. **Sheet automatically dismisses**
6. **Global status bar appears at top**

### During Extraction
1. User can navigate freely:
   - Browse recipes in ContentView
   - Add new recipes
   - Change settings
   - Open/close SavedLinksView
2. Status bar remains visible with live updates
3. Shows current progress, success/fail counts
4. Visual progress bar updates in real-time

### Monitoring Progress
User can tap status bar anytime to see:
- Detailed step-by-step progress
- Current recipe being processed
- Recently extracted recipes (last 5)
- Time statistics
- Full error log
- Controls: Pause, Resume, Stop

### Completing/Stopping
- **Natural Completion**: Bar disappears when done
- **User Stop**: Tap X → confirm → extraction stops
- **From Details**: Tap Stop button → confirm → stops

## Visual Design

### Status Bar (Collapsed)
- **Height**: ~50px (compact)
- **Background**: System background with subtle shadow
- **Typography**: 
  - Title: Subheadline, semibold
  - Stats: Caption, secondary color
- **Colors**:
  - Progress: Blue
  - Success: Green
  - Failure: Red
  - Background: Adaptive (light/dark mode)

### Progress Indicator
- **Type**: Thin bar (3px height)
- **Color**: Blue gradient
- **Animation**: Smooth transitions
- **Position**: Bottom edge of status bar

### Icons
- Loading: Animated spinner (system ProgressView)
- Success: `checkmark.circle.fill` (green)
- Failure: `xmark.circle.fill` (red)
- Cancel: `xmark.circle.fill` (secondary)

### Details Sheet
Full-screen modal with:
- Navigation bar (title, close, actions)
- Scrollable content area
- Rounded corner cards for sections
- Color-coded information
- System-standard spacing and padding

## Technical Details

### State Management
```swift
@StateObject private var manager = BatchExtractionManager.shared
```

Uses the singleton `BatchExtractionManager` which:
- Persists across view dismissals
- Updates UI via `@Published` properties
- Runs extraction in background task
- Thread-safe with `@MainActor`

### Conditional Display
```swift
if manager.isExtracting {
    BatchExtractionStatusBar(manager: manager)
}
```

Status bar only appears when `isExtracting == true`, ensuring it doesn't take up space when not needed.

### Performance
- **Lightweight**: Only renders when active
- **Efficient Updates**: Uses SwiftUI's automatic diffing
- **No Blocking**: All extraction work on background thread
- **Smooth Animations**: System-provided transitions

## Accessibility

### VoiceOver Support
- Status bar announces: "Extracting Recipes, 5 of 20, 4 succeeded"
- Cancel button: "Stop extraction"
- Progress updates announced periodically
- All stats readable by VoiceOver

### Dynamic Type
- All text scales with system font size
- Layout adapts to larger text
- Maintains readability at all sizes

### Color Contrast
- Meets WCAG AA standards
- Works in light and dark mode
- Color not sole indicator (uses icons too)

## Error Handling

### Network Failures
- Individual failures don't stop batch
- Failed recipes logged with details
- Error count shown in status bar
- Full error log available in details

### App Backgrounding
- Extraction continues in background (iOS permitting)
- State preserved if app terminates
- Can resume on next launch

### Edge Cases
- No recipes: Status bar doesn't appear
- All failed: Shows 0 succeeded, X failed
- Cancelled: Bar disappears immediately
- Paused: Shows pause indicator

## Future Enhancements

### Potential Improvements
1. **Rich Notifications**: 
   - Send notification when batch completes
   - Include success/failure summary
   - Deep link back to results

2. **Haptic Feedback**:
   - Success vibration per recipe
   - Error feedback on failures
   - Completion celebration

3. **Live Activities** (iOS 16.1+):
   - Show extraction progress on Lock Screen
   - Dynamic Island integration
   - Real-time updates without opening app

4. **Widgets**:
   - Home Screen widget showing current batch
   - Complications for Apple Watch
   - Quick actions to view progress

5. **Enhanced Analytics**:
   - Average extraction time trends
   - Success rate over time
   - Most common error types
   - Time-of-day performance

6. **Customization**:
   - User preference for status bar position
   - Compact/expanded view options
   - Auto-hide after X seconds
   - Sound/haptic preferences

7. **Batch Management**:
   - Multiple concurrent batches
   - Priority queuing
   - Scheduled extractions
   - Retry failed items automatically

## Testing Checklist

### Visual Testing
- [ ] Status bar appears on extraction start
- [ ] Progress bar animates smoothly
- [ ] Percentage updates correctly
- [ ] Success/fail counts update in real-time
- [ ] Bar disappears on completion/cancellation
- [ ] Works in light mode
- [ ] Works in dark mode
- [ ] Respects Dynamic Type settings

### Interaction Testing
- [ ] Tap bar opens details sheet
- [ ] Cancel button shows confirmation
- [ ] Confirmation works correctly
- [ ] Details sheet shows correct info
- [ ] Pause/resume buttons work
- [ ] Stop button works
- [ ] Can dismiss details and return

### Navigation Testing
- [ ] Bar visible in ContentView
- [ ] Bar visible in SettingsView
- [ ] Bar persists during navigation
- [ ] Bar updates across all views
- [ ] Can use app normally while extracting

### Edge Case Testing
- [ ] Handles 0 recipes
- [ ] Handles all failures
- [ ] Handles immediate cancellation
- [ ] Handles app backgrounding
- [ ] Handles rapid navigation
- [ ] Handles rotation (iPad)

### Performance Testing
- [ ] No lag when status bar appears
- [ ] Smooth progress updates
- [ ] No memory leaks
- [ ] Battery impact acceptable
- [ ] Background execution works

## Code Examples

### Using in a New View
```swift
struct MyNewView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Add status bar at top
            BatchExtractionStatusBar(manager: BatchExtractionManager.shared)
            
            // Your content here
            MyContent()
        }
    }
}
```

### Alternative: Using View Modifier
```swift
struct MyNewView: View {
    var body: some View {
        MyContent()
            .batchExtractionStatusBar()
    }
}
```

### Checking Extraction State
```swift
let manager = BatchExtractionManager.shared

if manager.isExtracting {
    print("Extraction in progress: \(manager.successCount) succeeded")
}
```

### Programmatic Control
```swift
let manager = BatchExtractionManager.shared

// Start extraction
manager.startBatchExtraction(links: myLinks)

// Pause
manager.pause()

// Resume
manager.resume()

// Stop
manager.stop()
```

## Summary

The global batch extraction status bar provides:
- ✅ Non-intrusive progress monitoring
- ✅ Works across all views
- ✅ Detailed progress on demand
- ✅ Quick cancellation option
- ✅ Beautiful, native design
- ✅ Accessible to all users
- ✅ Zero configuration needed

Users can now start a batch extraction and freely use the app while monitoring progress through the persistent status bar, significantly improving the user experience compared to the previous modal-only approach.
