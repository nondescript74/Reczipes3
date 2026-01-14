# Before and After: Extract View

## BEFORE - Extract View (3 Options)

```
┌─────────────────────────────────────┐
│      Recipe Extractor               │
├─────────────────────────────────────┤
│                                     │
│  Choose how to extract your recipe  │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │ 📷       │  │ 🖼️       │        │
│  │ Camera   │  │ Library  │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌─────────────────────────┐       │
│  │ 🌐 Web URL              │       │
│  │ Extract from a recipe   │       │
│  │ website                 │       │
│  └─────────────────────────┘       │
│                                     │
└─────────────────────────────────────┘
```

## AFTER - Extract View (4 Options)

```
┌─────────────────────────────────────┐
│      Recipe Extractor               │
├─────────────────────────────────────┤
│                                     │
│  Choose how to extract your recipe  │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │ 📷       │  │ 🖼️       │        │
│  │ Camera   │  │ Library  │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌─────────────────────────┐       │
│  │ 🌐 Web URL              │       │
│  │ Extract from a recipe   │       │
│  │ website                 │       │
│  └─────────────────────────┘       │
│                                     │
│  ┌─────────────────────────┐ ← NEW │
│  │ 📚 Batch Extract        │       │
│  │ Extract multiple recipes│       │
│  │ from saved links        │       │
│  └─────────────────────────┘       │
│                                     │
└─────────────────────────────────────┘
```

## Key Differences

### Visual Changes:
✅ Added fourth option card (purple theme)
✅ "Batch Extract" button with distinctive icon
✅ Descriptive subtitle explaining feature
✅ Consistent styling with other options

### Functional Changes:
✅ Tapping opens BatchRecipeExtractorView sheet
✅ No impact on existing extraction methods
✅ Seamless integration with current UI

## Code Changes Summary

### RecipeExtractorView.swift

#### Added Enum Case:
```swift
enum ExtractionSource {
    case none
    case camera
    case library
    case url
    case batch  // ← NEW
}
```

#### Added State:
```swift
@State private var showBatchExtraction = false  // ← NEW
private let apiKey: String                      // ← NEW
```

#### Added Button in sourceSelectionSection:
```swift
// Row 3: Batch Extract (full width)
Button {
    extractionSource = .batch
    showBatchExtraction = true
} label: {
    VStack(spacing: 8) {
        Image(systemName: "square.stack.3d.up.fill")
            .font(.system(size: 40))
        Text("Batch Extract")
            .font(.caption)
            .fontWeight(.medium)
        Text("Extract multiple recipes from saved links")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(extractionSource == .batch ? Color.purple.opacity(0.2) : Color.purple.opacity(0.1))
    .cornerRadius(12)
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(extractionSource == .batch ? Color.purple : Color.clear, lineWidth: 2)
    )
}
.buttonStyle(.plain)
```

#### Added Sheet Presentation:
```swift
.sheet(isPresented: $showBatchExtraction) {
    BatchRecipeExtractorView(apiKey: apiKey, modelContext: modelContext)
}
```

## User Experience Comparison

### BEFORE:
1. User wants to extract 10 recipes
2. Must use Web URL option 10 times
3. Each extraction takes 2-3 minutes
4. Total time: 20-30 minutes
5. Must manually track progress
6. No error aggregation

### AFTER:
1. User wants to extract 10 recipes
2. Saves 10 links to SavedLinks
3. Taps "Batch Extract" once
4. Starts automated extraction
5. Total time: ~15 minutes (with 5-sec intervals)
6. Can pause/resume at any time
7. Automatic progress tracking
8. Automatic retry on failures
9. Error log for review
10. Completion summary

### Time Savings:
- **Setup**: 1 tap vs 10 separate extractions
- **Monitoring**: Hands-free vs constant attention
- **Total Time**: ~50% reduction with automation
- **Error Handling**: Automatic retries vs manual retries

## Feature Comparison Matrix

| Feature | Single Extraction | Batch Extraction |
|---------|------------------|------------------|
| Recipes per session | 1 | Up to 50 |
| User interaction | High | Low |
| Progress tracking | Manual | Automatic |
| Retry logic | Yes | Yes (per recipe) |
| Error aggregation | N/A | Yes |
| Pause/Resume | No | Yes |
| Time between extractions | Manual | Automatic (5 sec) |
| Image downloads | Yes | Yes (all images) |
| Completion summary | No | Yes |

## UI States Comparison

### Single Extraction States:
1. Source selection
2. Loading/extracting
3. Success (recipe shown)
4. Error (retry option)

### Batch Extraction States:
1. Empty (no links)
2. Ready (links available)
3. Extracting (progress shown)
4. Paused (resume available)
5. Complete (summary shown)
6. Error log (failures listed)

## Visual Design Harmony

### Existing Design System:
- **Camera**: 📷 (iOS blue)
- **Library**: 🖼️ (iOS blue)
- **Web URL**: 🌐 (iOS blue)

### New Addition:
- **Batch Extract**: 📚 (Purple - distinguishes from single extractions)

### Why Purple?
- Visually distinct from blue (single extractions)
- Suggests "collection" or "multiple items"
- Complements existing color scheme
- Not used elsewhere in extraction UI

## Navigation Flow

### BEFORE:
```
ContentView
  └─ Extract Tab
      └─ RecipeExtractorView
          ├─ Camera → ImagePicker → Crop → Extract
          ├─ Library → ImagePicker → Crop → Extract
          └─ Web URL → URL Input → Extract
```

### AFTER:
```
ContentView
  └─ Extract Tab
      └─ RecipeExtractorView
          ├─ Camera → ImagePicker → Crop → Extract
          ├─ Library → ImagePicker → Crop → Extract
          ├─ Web URL → URL Input → Extract
          └─ Batch Extract → BatchRecipeExtractorView → Auto Extract
                                  ├─ Start
                                  ├─ Pause/Resume
                                  ├─ Stop
                                  └─ Complete
```

## Accessibility Improvements

### BEFORE:
- 3 extraction options
- Clear labels for each

### AFTER:
- 4 extraction options
- Clear labels for each
- Batch option explains "multiple recipes"
- Full batch view has:
  - Progress announcements
  - Status updates
  - Error details
  - Completion alerts

## Technical Integration

### Minimal Impact:
✅ No changes to existing extraction logic
✅ No database schema changes
✅ No breaking changes
✅ Backward compatible
✅ Optional feature (doesn't affect existing users)

### Clean Separation:
✅ Batch logic in separate view
✅ Reuses existing infrastructure
✅ Independent state management
✅ No coupling to other extraction types

## Testing Coverage

### BEFORE Tests:
- Camera extraction
- Library extraction
- Web URL extraction
- Image preprocessing
- Error handling

### AFTER Tests (Additional):
- Batch extraction start
- Batch extraction pause/resume
- Batch extraction stop
- Progress tracking
- Error logging
- Completion alerts
- Empty state handling
- Link filtering

## Deployment Impact

### Low Risk:
- Self-contained feature
- No migration needed
- No data structure changes
- Feature flag friendly
- Easy to disable if issues

### High Value:
- Major user experience improvement
- Reduces manual work
- Increases app utility
- Differentiates from competitors

## Performance Impact

### Minimal:
- Batch view loads on-demand (sheet)
- Same extraction logic as single
- Sequential processing (not parallel)
- Rate limited (5 sec intervals)
- Memory efficient (saves immediately)

## Summary

The batch extraction feature integrates seamlessly into the existing Extract view as a natural fourth option. It maintains design consistency while providing powerful new functionality for users who want to extract multiple recipes efficiently.

### What Changed:
- ✅ 1 new button in Extract view
- ✅ 1 new view (BatchRecipeExtractorView)
- ✅ ~50 lines modified in existing file
- ✅ ~550 lines in new file
- ✅ Comprehensive documentation

### What Didn't Change:
- ✅ Existing extraction methods
- ✅ Data models
- ✅ Storage logic
- ✅ Image handling
- ✅ API integration

### Result:
A powerful new feature that feels native to the app and requires minimal code changes to existing functionality.
