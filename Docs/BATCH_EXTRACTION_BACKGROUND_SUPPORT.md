# Batch Extraction Background Support

## Overview
Batch recipe extraction now continues in the background when users navigate away from the extraction view, allowing them to perform other tasks while recipes are being extracted. Newly extracted recipes appear automatically in the "Recipes Mine" tab as they're processed.

## What Changed

### 1. Background Execution Support
- **Without Cropping**: Extraction continues in background when view is dismissed
- **With Cropping**: Extraction requires foreground (user interaction needed)

### 2. User Experience Improvements

#### Visual Indicators
```
✅ Purple banner during extraction: "Extraction will continue if you close this screen"
✅ Smart close button behavior
✅ Confirmation alert with three options
```

#### Close Button Behavior
When user taps "Close" during extraction:

**Without Cropping** (Background-Capable):
- Shows alert with 3 options:
  - **Continue in Background** - Dismisses view, extraction continues
  - **Stop and Close** - Stops extraction, dismisses view
  - **Cancel** - Returns to extraction view

**With Cropping** (Foreground-Only):
- Stops extraction immediately
- Dismisses view
- No background option (cropping requires user interaction)

### 3. Technical Implementation

#### Modified Files

**`BatchImageExtractorViewModel.swift`**
```swift
// New properties
private let batchManager = BatchExtractionManager.shared
private var isUsingBackgroundExtraction = false

// Updated extraction methods
func startBatchExtraction(...) {
    if !shouldCrop {
        isUsingBackgroundExtraction = true
        startBackgroundExtractionFromAssets(...)
    } else {
        isUsingBackgroundExtraction = false
        // Foreground extraction with cropping
    }
}

// New background extraction methods
private func startBackgroundExtractionFromImages(...)
private func startBackgroundExtractionFromAssets(...)
private func startBackgroundExtractionWithProcessedImages(...)

// View dismissal support
func prepareForBackgroundDismissal() { ... }
var canDismissView: Bool { ... }
```

**`BatchImageExtractorView.swift`**
```swift
// New state
@State private var showingBackgroundExtractionAlert = false

// Updated close button handler
private func handleCloseButton() {
    if viewModel.isExtracting && !shouldCropImages {
        // Show background continuation alert
        showingBackgroundExtractionAlert = true
    } else if viewModel.isExtracting {
        // Stop extraction (cropping mode)
        viewModel.stop()
        dismiss()
    } else {
        // Just close
        dismiss()
    }
}

// New alert
.alert("Extraction in Progress", isPresented: $showingBackgroundExtractionAlert) {
    Button("Continue in Background") { ... }
    Button("Stop and Close", role: .destructive) { ... }
    Button("Cancel", role: .cancel) { ... }
}

// Visual indicator in progress view
if !shouldCropImages && viewModel.isExtracting {
    HStack {
        Image(systemName: "arrow.triangle.2.circlepath")
        Text("Extraction will continue if you close this screen")
    }
}
```

## How It Works

### Flow Diagram

```
User Starts Extraction
        ↓
    Cropping?
    ↙     ↘
  Yes      No
   ↓        ↓
Foreground  Background
Extraction  Extraction
   ↓        ↓
User taps   User taps
"Close"     "Close"
   ↓        ↓
Stops &     Shows Alert
Dismisses   ↓
           ┌─────────────┬────────────┐
           ↓             ↓            ↓
      Continue       Stop & Close  Cancel
      in BG          & Dismiss     (stay)
      ↓
   View Dismisses
   Extraction Continues
      ↓
   Recipes Appear
   in "Mine" Tab
```

### Extraction Process

1. **Image Loading**
   - PHAssets → Load to UIImage
   - UIImages → Use directly

2. **Background Task Creation**
   - Task runs independently of view lifecycle
   - Not cancelled when view dismisses
   - Continues until completion or manual stop

3. **Recipe Saving**
   - Each recipe saved to SwiftData immediately
   - Recipes appear in "Mine" tab in real-time
   - No waiting for entire batch to complete

4. **Progress Tracking**
   - ViewModel updates progress
   - If view dismissed, progress continues silently
   - Can re-open view to check progress

## Usage Examples

### Example 1: Background Extraction from Files
```swift
// User flow:
1. Select 10 images from Files app
2. Disable "Crop each image" toggle
3. Tap "Start Extraction"
4. See first recipe being extracted
5. Tap "Close" button
6. Alert appears: "Extraction in Progress"
7. Tap "Continue in Background"
8. Navigate to "Recipes Mine" tab
9. See recipes appearing as they're extracted
```

### Example 2: Foreground Extraction with Cropping
```swift
// User flow:
1. Select 5 images from Photos
2. Enable "Crop each image" toggle
3. Tap "Start with Cropping"
4. Crop first image
5. See extraction progress
6. Tap "Close" button
7. Extraction stops immediately
8. View dismisses
```

## Technical Details

### Why Background Works

The extraction runs in a Swift `Task` that:
- Is created on `@MainActor` (BatchImageExtractorViewModel)
- Inherits actor context (avoids data races)
- Maintains strong reference to modelContext
- Not cancelled when view dismisses (unless explicitly stopped)

### Image Processing

Images are processed in batches:
```swift
for (index, image) in processedImages.enumerated() {
    // Check if stopped
    guard isExtracting else { break }
    
    // Wait while paused
    while isPaused && isExtracting {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
    
    // Extract recipe
    await extractRecipeFromImage(image, imageIndex: index)
    
    currentProgress += 1
    
    // Log progress every 5 images
    if currentProgress % 5 == 0 {
        logInfo("Progress: \(currentProgress)/\(totalToExtract)")
    }
}
```

### Recipe Saving

Each recipe is saved immediately after extraction:
```swift
private func saveRecipe(_ recipeModel: RecipeModel, withImage image: UIImage) async {
    // Convert to SwiftData Recipe
    let recipe = Recipe(from: recipeModel)
    
    // Save image to disk
    let imageName = "recipe_\(recipe.id.uuidString).jpg"
    recipe.imageName = imageName
    // ... save image data ...
    
    // Insert into SwiftData
    modelContext.insert(recipe)
    
    // Save immediately
    try modelContext.save()
    
    // Recipe now appears in "Mine" tab!
}
```

## Testing

### Test Case 1: Background Extraction
1. ✅ Clean build (⇧⌘K)
2. ✅ Select 5 images from Files app
3. ✅ Ensure cropping is OFF
4. ✅ Start extraction
5. ✅ Wait for 1st recipe to extract
6. ✅ Tap "Close"
7. ✅ Tap "Continue in Background"
8. ✅ Navigate to "Recipes Mine"
9. ✅ Verify recipes appear as extraction continues
10. ✅ All 5 recipes should appear

### Test Case 2: Stop During Extraction
1. ✅ Start extraction with 3 images
2. ✅ Wait for 1st recipe
3. ✅ Tap "Close"
4. ✅ Tap "Stop and Close"
5. ✅ Verify extraction stops
6. ✅ Only 1 recipe should be saved

### Test Case 3: Cropping Mode (No Background)
1. ✅ Select 3 images
2. ✅ Enable cropping
3. ✅ Start extraction
4. ✅ Crop first image
5. ✅ Tap "Close"
6. ✅ Verify no background alert appears
7. ✅ Verify extraction stops immediately

### Test Case 4: Pause/Resume in Background
1. ✅ Start extraction with 5 images
2. ✅ Tap "Pause"
3. ✅ Tap "Close" → "Continue in Background"
4. ✅ Extraction should remain paused
5. ✅ Re-open batch extraction view
6. ✅ Tap "Resume"
7. ✅ Extraction continues

## Expected Log Output

```
[batch] Starting batch image extraction from 5 UIImages (Files/iCloud Drive), shouldCrop: false
[batch] Starting background extraction from 5 images
[batch] Handing off 5 images to background extraction
[batch] Processing image 1 of 5...
[batch] Successfully extracted recipe: Chocolate Chip Cookies
[batch] Background extraction progress: 1/5
[ui] User tapped close during background-capable extraction
[batch] User chose to continue extraction in background
[batch] View dismissing, extraction will continue in background
[ui] User closed BatchImageExtractorView
[batch] Processing image 2 of 5...
[batch] Successfully extracted recipe: Apple Pie
[batch] Background extraction progress: 2/5
...
[batch] Background extraction progress: 5/5
[batch] Background extraction complete: 5 success, 0 failures
```

## Benefits

### For Users
✅ Can perform other tasks while extracting
✅ No need to wait on extraction screen
✅ See results appear in real-time
✅ More efficient workflow
✅ Better multitasking

### For App
✅ Better resource management
✅ Consistent extraction behavior
✅ Proper task lifecycle
✅ Clean cancellation handling
✅ SwiftData-friendly architecture

## Limitations

### Current Constraints
⚠️ Cropping mode requires foreground (user interaction)
⚠️ No system-level background task (terminates on app exit)
⚠️ Progress lost if app force-quit during extraction

### Future Enhancements (Potential)
- System background task support (survives app termination)
- Notification on extraction completion
- Widget showing extraction progress
- Batch extraction history

## Related Files
- `BatchImageExtractorView.swift` - Main UI with background support
- `BatchImageExtractorViewModel.swift` - Extraction logic with background mode
- `BatchExtractionManager.swift` - Singleton manager (for future link-based extraction)
- `Recipe.swift` - SwiftData model
- `RecipeModel.swift` - Extraction model

## Key Learning

**Background extraction works because:**
1. Task not tied to view lifecycle
2. ModelContext remains valid
3. `@MainActor` ensures thread safety
4. Recipes saved immediately (visible in other views)

**Cropping requires foreground because:**
1. User must interact with crop UI
2. Cannot present fullScreenCover without visible view
3. Synchronous user decision needed (skip/crop)

## Migration Notes

### Before
```swift
// Always stopped on view dismiss
func startBatchExtraction(...) {
    extractionTask = Task {
        await processBatch(...)
    }
}

// Close button
Button("Close") {
    viewModel.stop()
    dismiss()
}
```

### After
```swift
// Smart background detection
func startBatchExtraction(...) {
    if !shouldCrop {
        isUsingBackgroundExtraction = true
        startBackgroundExtractionFromImages(...)
    } else {
        extractionTask = Task {
            await processBatch(...)
        }
    }
}

// Smart close button
Button("Close") {
    handleCloseButton() // Shows alert or stops based on mode
}
```

---

**Last Updated**: January 20, 2026
**Status**: ✅ Implemented & Tested
