# Quick Reference: Background Batch Extraction

## What It Does
Batch extraction continues in the background when you navigate away (if cropping is disabled). Recipes appear in "Recipes Mine" tab as they're extracted.

## The Key Feature
```
User starts extraction → Closes view → Extraction continues → Recipes appear in Mine tab
```

## Visual Indicators

### During Extraction (No Cropping)
```
┌─────────────────────────────────────────────┐
│ 🔄 Extraction will continue if you close    │
│    this screen                              │
└─────────────────────────────────────────────┘
```

### Close Alert
```
⚠️ Extraction in Progress

You can let it continue in the background,
or stop it now.

[Continue in Background] [Stop and Close] [Cancel]
```

## User Flow

### Without Cropping (Background Mode)
1. Select images
2. Ensure "Crop each image" is OFF
3. Tap "Start Extraction"
4. Tap "Close"
5. Choose "Continue in Background"
6. Navigate to "Recipes Mine"
7. ✨ Watch recipes appear automatically

### With Cropping (Foreground Only)
1. Select images
2. Enable "Crop each image"
3. Tap "Start with Cropping"
4. Crop each image
5. Tap "Close"
6. Extraction stops immediately

## Code Changes

### BatchImageExtractorViewModel.swift
```swift
// NEW: Background mode detection
private var isUsingBackgroundExtraction = false

// UPDATED: Smart extraction start
func startBatchExtraction(...) {
    if !shouldCrop {
        isUsingBackgroundExtraction = true
        startBackgroundExtractionFromImages(...) // NEW method
    } else {
        // Foreground with cropping
    }
}

// NEW: Background extraction methods
private func startBackgroundExtractionFromImages(...)
private func startBackgroundExtractionFromAssets(...)
private func startBackgroundExtractionWithProcessedImages(...)

// NEW: View dismissal support
func prepareForBackgroundDismissal() { ... }
```

### BatchImageExtractorView.swift
```swift
// NEW: Alert state
@State private var showingBackgroundExtractionAlert = false

// NEW: Smart close handler
private func handleCloseButton() {
    if viewModel.isExtracting && !shouldCropImages {
        showingBackgroundExtractionAlert = true // Show background option
    } else if viewModel.isExtracting {
        viewModel.stop() // Stop (cropping mode)
        dismiss()
    } else {
        dismiss() // Just close
    }
}

// NEW: Background alert
.alert("Extraction in Progress", isPresented: $showingBackgroundExtractionAlert) {
    Button("Continue in Background") {
        viewModel.prepareForBackgroundDismissal()
        dismiss()
    }
    Button("Stop and Close", role: .destructive) {
        viewModel.stop()
        dismiss()
    }
    Button("Cancel", role: .cancel) { }
}

// NEW: Background indicator in progress view
if !shouldCropImages && viewModel.isExtracting {
    HStack {
        Image(systemName: "arrow.triangle.2.circlepath")
        Text("Extraction will continue if you close this screen")
    }
}
```

## Test It

### Quick Test
```bash
1. Clean build (⇧⌘K)
2. Select 3 images from Files
3. Disable cropping
4. Start extraction
5. Tap "Close" → "Continue in Background"
6. Go to "Recipes Mine" tab
7. ✅ See recipes appearing!
```

### Verify Logs
```
[batch] Starting background extraction from 3 images
[batch] Handing off 3 images to background extraction
[ui] User tapped close during background-capable extraction
[batch] User chose to continue extraction in background
[batch] View dismissing, extraction will continue in background
[batch] Successfully extracted recipe: Chocolate Cake
[batch] Background extraction progress: 1/3
[batch] Successfully extracted recipe: Apple Pie
[batch] Background extraction progress: 2/3
...
```

## Why It Works

### Task Lifecycle
```swift
// Task created in ViewModel (not view)
extractionTask = Task {
    await startBackgroundExtractionWithProcessedImages(...)
}

// Task continues even when view dismisses
// Because: Not cancelled, ModelContext still valid
```

### Recipe Visibility
```swift
// Each recipe saved immediately after extraction
modelContext.insert(recipe)
try modelContext.save()

// SwiftData @Query in RecipesListView updates automatically
// User sees new recipe appear without refreshing
```

## Decision Matrix

| Scenario | Cropping? | Background? | Close Behavior |
|----------|-----------|-------------|----------------|
| Photos, no crop | ❌ | ✅ | Alert with options |
| Photos, with crop | ✅ | ❌ | Stop immediately |
| Files, no crop | ❌ | ✅ | Alert with options |
| Files, with crop | ✅ | ❌ | Stop immediately |
| Not extracting | N/A | N/A | Just close |

## Common Scenarios

### Scenario 1: "I want to extract while doing other things"
✅ Disable cropping → Start extraction → Close → Continue in Background

### Scenario 2: "I want to crop each image carefully"
✅ Enable cropping → Start extraction → Stay on screen (required)

### Scenario 3: "I started extraction but changed my mind"
✅ Tap Close → Stop and Close (or Cancel to continue)

### Scenario 4: "Can I pause and still use background?"
✅ Yes! Tap Pause → Close → Continue in Background → Remains paused

## Files Changed
1. **BatchImageExtractorViewModel.swift** - Background extraction logic
2. **BatchImageExtractorView.swift** - Smart close handling + alerts

## Documentation
- **BATCH_EXTRACTION_BACKGROUND_SUPPORT.md** - Complete technical guide
- **QUICK_REF_BACKGROUND_EXTRACTION.md** - This file

---

**TL;DR**: No cropping = Can run in background. With cropping = Must stay foreground.
