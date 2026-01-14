# Batch Recipe Extraction Integration

## Overview

Batch recipe extraction has been successfully integrated into the Extract view as a new extraction option. Users can now extract multiple recipes from saved links in a single automated session.

## What Was Added

### 1. New Extraction Source
- Added "Batch Extract" as a fourth option in the RecipeExtractorView
- Located alongside Camera, Library, and Web URL options
- Uses a purple theme to distinguish it from other extraction methods

### 2. BatchRecipeExtractorView
A new dedicated view for managing batch extraction with the following features:

#### UI Components:
- **Status Overview Card**: Shows total links ready to extract and real-time progress stats
- **Current Extraction Card**: Displays the currently extracting recipe with progress bar
- **Control Buttons**: Start, Pause/Resume, and Stop controls
- **Links Preview**: Shows up to 5 unprocessed links with current extraction highlighted
- **Error Log**: Displays any extraction failures with error details

#### Features:
- Real-time progress tracking
- Pause/Resume functionality
- Recipe preview as each extraction completes
- Detailed error logging
- Completion alert with success/failure summary

### 3. Integration Points

The batch extraction feature connects to existing infrastructure:
- Uses `BatchRecipeExtractorViewModel` for extraction logic
- Leverages SwiftData `@Query` for real-time link updates
- Integrates with existing retry mechanism (`ExtractionRetryManager`)
- Uses the same image download and storage pipeline
- Shares the same `RecipeExtractorViewModel` API client

## How to Use

### For Users:

1. **Save Links First**
   - Navigate to the saved links feature
   - Add recipe URLs you want to extract

2. **Start Batch Extraction**
   - Go to the Extract tab
   - Tap "Batch Extract" option
   - Review the list of unprocessed links
   - Tap "Start Batch Extraction"

3. **Monitor Progress**
   - Watch real-time progress updates
   - See each recipe as it's extracted
   - Pause/resume at any time
   - Stop if needed

4. **Review Results**
   - Completion alert shows success/failure counts
   - View error log for any failed extractions
   - Extracted recipes are automatically saved to your collection

### For Developers:

#### File Structure:
```
RecipeExtractorView.swift
  ├─ sourceSelectionSection (added Batch Extract button)
  └─ .sheet(isPresented: $showBatchExtraction)
      └─ BatchRecipeExtractorView

BatchRecipeExtractorView.swift (NEW)
  ├─ Uses BatchRecipeExtractorViewModel
  ├─ Displays extraction progress
  └─ Provides user controls

BatchRecipeExtractorViewModel.swift (EXISTING)
  ├─ Manages extraction state
  ├─ Processes links sequentially
  └─ Handles retries and errors
```

#### Key Changes to RecipeExtractorView:

1. **Added `ExtractionSource.batch`**
   ```swift
   enum ExtractionSource {
       case none, camera, library, url, batch
   }
   ```

2. **Stored apiKey for passing to batch view**
   ```swift
   private let apiKey: String
   
   init(apiKey: String) {
       self.apiKey = apiKey
       _viewModel = StateObject(wrappedValue: RecipeExtractorViewModel(apiKey: apiKey))
   }
   ```

3. **Added batch extraction button**
   - Purple-themed card in source selection
   - Icon: `square.stack.3d.up.fill`
   - Presents sheet when tapped

4. **Added sheet presentation**
   ```swift
   .sheet(isPresented: $showBatchExtraction) {
       BatchRecipeExtractorView(apiKey: apiKey, modelContext: modelContext)
   }
   ```

## Architecture

### Flow Diagram:
```
User taps "Batch Extract"
  ↓
RecipeExtractorView presents BatchRecipeExtractorView
  ↓
BatchRecipeExtractorView queries unprocessed SavedLinks
  ↓
User starts extraction
  ↓
BatchRecipeExtractorViewModel processes each link:
  1. Extract recipe via RecipeExtractorViewModel
  2. Download images via WebImageDownloader
  3. Save recipe to SwiftData
  4. Mark link as processed
  5. Wait interval (5 seconds)
  6. Repeat for next link
  ↓
Display completion alert
```

### State Management:
- `BatchRecipeExtractorViewModel` is the single source of truth
- Published properties update UI in real-time:
  - `isExtracting`: Controls UI state
  - `isPaused`: Pause/resume functionality
  - `currentLink`: Highlights current extraction
  - `currentRecipe`: Shows preview
  - `currentProgress`: Updates progress bar
  - `errorLog`: Collects failures

### Error Handling:
- Individual extraction failures don't stop the batch
- Errors are logged with link title and error message
- Failed links are marked as processed with error details
- Retry logic built into extraction (via ExtractionRetryManager)

## Configuration

### Extraction Settings (in BatchRecipeExtractorViewModel):
```swift
private let extractionInterval: TimeInterval = 5.0  // Time between extractions
private let maxBatchSize: Int = 50                   // Max recipes per batch
```

### Retry Configuration:
```swift
private let retryConfiguration = ExtractionRetryManager.RetryConfiguration.default
// - maxAttempts: 3
// - initialDelay: 2.0 seconds
// - maxDelay: 30.0 seconds
// - backoffMultiplier: 2.0
// - useJitter: true
```

## Testing

### Manual Testing Checklist:
- [ ] Batch extraction button appears in Extract view
- [ ] Empty state shows when no saved links exist
- [ ] Start button disabled when no unprocessed links
- [ ] Progress updates in real-time during extraction
- [ ] Pause/Resume works correctly
- [ ] Stop cancels extraction immediately
- [ ] Current recipe preview shows during extraction
- [ ] Error log displays failures
- [ ] Completion alert shows correct counts
- [ ] Extracted recipes appear in collection
- [ ] Images are downloaded and saved
- [ ] Link status updates correctly

### Edge Cases to Test:
- Network failures during extraction
- App backgrounding during batch extraction
- Very large batches (50+ links)
- Links with no images
- Links with multiple images
- Invalid/broken URLs
- API rate limiting

## Future Enhancements

Potential improvements:
1. **Scheduling**: Allow scheduled batch extraction (e.g., overnight)
2. **Filtering**: Extract only links from specific domains
3. **Priority**: Let users reorder extraction queue
4. **Notifications**: Alert when batch completes
5. **Analytics**: Track extraction success rates
6. **Export**: Export error log to CSV
7. **Parallel Extraction**: Process multiple links simultaneously (with rate limiting)
8. **Smart Retry**: Adaptive retry based on error type
9. **Resume After Close**: Persist batch state across app launches

## Performance Considerations

### Memory:
- Images are downloaded and saved one at a time
- Each image is compressed before storage (500KB max)
- Recipe models are lightweight

### Network:
- 5-second interval between extractions prevents rate limiting
- Sequential processing ensures stable network usage
- Retry logic handles transient network failures

### Storage:
- Images saved to Documents directory
- SwiftData handles recipe persistence
- Old/unused images should be cleaned up periodically

## Troubleshooting

### Common Issues:

**Extraction gets stuck**
- Check network connection
- Verify API key is valid
- Stop and restart extraction

**Images not downloading**
- Check image URLs in recipe data
- Verify network connectivity
- Look for errors in console logs

**Recipes not saving**
- Check SwiftData container status
- Verify model context is valid
- Check for save errors in logs

**High failure rate**
- Review error log for patterns
- Check if websites are blocking requests
- Verify Claude API is responding

## Related Files

- `BatchRecipeExtractorViewModel.swift` - Extraction logic
- `BatchRecipeExtractorView.swift` - UI (NEW)
- `RecipeExtractorView.swift` - Integration point (MODIFIED)
- `RecipeExtractorViewModel.swift` - Individual extraction
- `ExtractionRetryManager.swift` - Retry logic
- `WebImageDownloader.swift` - Image downloads
- `SavedLink.swift` - Data model
- `Recipe.swift` - Data model

## Summary

The batch extraction feature provides a seamless way to extract multiple recipes automatically. It integrates naturally into the existing Extract view while maintaining separation of concerns through a dedicated view and view model. The implementation leverages existing infrastructure for extraction, retry logic, and data persistence, ensuring consistency across the app.
