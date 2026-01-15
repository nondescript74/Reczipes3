# Batch Image Extraction Feature

## Overview

The Batch Image Extraction feature allows users to extract multiple recipes from images stored in their Photos library. This feature is designed to handle large batches efficiently while giving users control over the extraction process.

## Architecture

### Components

1. **BatchImageExtractorView** - Main UI for batch image extraction
2. **BatchImageExtractorViewModel** - Business logic and state management
3. **PhotoLibraryManager** - Interface with Photos framework
4. **PhotosPickerSheet** - Custom photo selection interface

### Key Features

#### 1. Photo Selection
- Users can select multiple images from their Photos library
- Visual grid interface with thumbnails
- Selection indicators showing which images are selected
- Ability to add more images after initial selection

#### 2. Crop Options
- **Optional Cropping**: Users decide upfront whether to crop images
- **Per-Image Cropping**: When enabled, users can crop each image individually
- **Skip Cropping**: For faster processing, users can skip cropping entirely
- **Inline Decision**: When cropping is enabled, users decide for each image whether to crop or skip

#### 3. Batch Processing
- **Batches of 10**: Images are processed in groups of 10
- **Queue Display**: Shows remaining images in the queue
- **Progress Tracking**: Real-time updates on extraction progress
- **Statistics**: Displays success count, failure count, and total progress

#### 4. Pause/Resume/Stop Controls
- **Pause**: Temporarily halt extraction
- **Resume**: Continue from where you left off
- **Stop**: Cancel the entire batch operation

#### 5. Error Handling
- Individual failures don't stop the batch
- Error log shows which images failed and why
- Failed images are counted separately

## User Flow

### Without Cropping

1. User taps "Batch Extract Images" from RecipeExtractorView
2. User grants Photos library permissions (if needed)
3. User selects multiple images from their library
4. User disables "Crop each image before extraction" toggle
5. User taps "Start Extraction"
6. App processes up to 10 images at a time
7. Progress updates show current image being processed
8. Queue updates after each batch of 10
9. Completion alert shows success/failure statistics

### With Cropping

1. User taps "Batch Extract Images" from RecipeExtractorView
2. User grants Photos library permissions (if needed)
3. User selects multiple images from their library
4. User enables "Crop each image before extraction" toggle
5. User taps "Start with Cropping"
6. For each image:
   - Image preview is shown
   - User chooses "Skip" or "Crop"
   - If "Crop", crop UI is presented (TODO: integrate with existing ImageCropView)
   - If "Skip", original image is used
7. After decision, extraction begins for that image
8. Process continues for remaining images
9. Queue updates showing remaining images
10. Completion alert shows final statistics

## Implementation Details

### State Management

The `BatchImageExtractorViewModel` manages:
- `isExtracting`: Whether batch extraction is running
- `isPaused`: Whether extraction is paused
- `isWaitingForCrop`: Whether waiting for user crop decision
- `currentProgress`: Number of images processed
- `totalToExtract`: Total images to process
- `successCount`: Successfully extracted recipes
- `failureCount`: Failed extractions
- `remainingAssets`: PHAssets still in queue
- `errorLog`: List of errors with image indices

### Batch Processing Algorithm

```swift
1. Load all selected PHAssets into queue
2. For each asset in queue:
   a. Check if extraction is stopped → break
   b. Wait while paused
   c. Load full resolution image from Photos
   d. If shouldCrop:
      - Show image preview
      - Wait for user decision (crop or skip)
      - If crop selected, show crop UI
   e. Extract recipe from image using Claude API
   f. Save recipe to SwiftData with image
   g. Mark asset as processed
   h. Update progress
   i. Every 10 images, brief pause to show progress
3. Show completion alert with statistics
```

### Integration with Existing Systems

#### Claude API Integration
- Uses existing `ClaudeAPIClient`
- Uses `ImagePreprocessor` to reduce image size
- Passes `usePreprocessing: true` for OCR enhancement

#### SwiftData Integration
- Creates `Recipe` instances from `RecipeModel`
- Saves images to Documents directory
- Creates `RecipeImageAssignment` for compatibility
- Uses existing `modelContext` from environment

#### Photos Framework Integration
- Uses `PhotoLibraryManager` to request permissions
- Loads thumbnails for preview
- Loads full resolution for extraction
- Uses `PHAsset.localIdentifier` for tracking

## UI Components

### Empty State
- Shows when no images selected
- Prominent "Select Photos" button
- Explanation of feature

### Selection View
- Selection summary card
- Crop options toggle
- Start button
- Grid of selected images with remove buttons

### Extraction Progress View
- Progress overview with statistics
- Current image preview
- Current recipe preview (when extracted)
- Pause/Resume/Stop controls
- Remaining queue preview (next 10 images)
- Error log (if any failures)

### Supporting Views
- **SelectedAssetThumbnail**: Shows selected image with remove button
- **QueuedAssetThumbnail**: Shows upcoming image in queue
- **PhotosPickerSheet**: Full-screen photo selection interface
- **PhotoAssetCell**: Individual photo cell in picker grid

## Future Enhancements

### 1. Crop Integration
Currently marked as TODO - integrate with existing `ImageCropView`:
```swift
// When user chooses to crop
if let croppedImage = await showCropView(for: image) {
    imageToProcess = croppedImage
}
```

### 2. Batch Size Configuration
Allow users to configure batch size:
- Default: 10 images
- Options: 5, 10, 20, 50

### 3. Background Processing
- Continue extraction when app is backgrounded
- Show notification when complete
- Use Background Tasks framework

### 4. Smart Image Detection
- Automatically detect recipe images
- Filter out non-recipe images
- Suggest which images to select

### 5. Export Results
- Export all extracted recipes as PDF
- Share multiple recipes at once
- Bulk tag or categorize

## Error Scenarios

### Common Errors
1. **Photo loading failed**: Unable to load image from Photos library
2. **API failure**: Claude API error during extraction
3. **Image processing failed**: Unable to reduce image size
4. **Save failed**: Database error when saving recipe

### Error Recovery
- Errors are logged but don't stop batch
- User can review error log after completion
- Failed images can be retried individually
- Error messages are user-friendly

## Performance Considerations

### Image Size Reduction
- All images reduced to 500KB before API call
- Uses JPEG compression
- Maintains aspect ratio

### Memory Management
- Only current image kept in memory
- Thumbnails cached by PhotoKit
- Processed images released immediately

### API Rate Limiting
- Sequential processing (one at a time)
- Brief pause after each batch of 10
- Pause/resume for user control

## Testing Checklist

- [ ] Select 1 image and extract
- [ ] Select 5 images and extract
- [ ] Select 20+ images and extract
- [ ] Test with crop enabled
- [ ] Test with crop disabled
- [ ] Test pause/resume functionality
- [ ] Test stop functionality
- [ ] Test with some failing images
- [ ] Test with all failing images
- [ ] Verify all recipes saved to database
- [ ] Verify all images saved to disk
- [ ] Check memory usage with large batches
- [ ] Test Photos permission denied scenario
- [ ] Test with no internet connection

## Code Organization

```
BatchImageExtractorView.swift
├── Main View
├── Empty State View
├── Image Selection View
│   ├── Selection Summary Card
│   ├── Crop Option Card
│   └── Selected Images Grid
├── Extraction Progress View
│   ├── Progress Overview Card
│   ├── Current Image Card
│   ├── Control Buttons
│   ├── Remaining Queue Section
│   └── Error Log Section
└── Supporting Views
    ├── SelectedAssetThumbnail
    ├── QueuedAssetThumbnail
    ├── PhotosPickerSheet
    └── PhotoAssetCell

BatchImageExtractorViewModel.swift
├── State Properties
├── Initialization
├── Public Methods
│   ├── startBatchExtraction()
│   ├── pause()
│   ├── resume()
│   ├── stop()
│   ├── skipCropping()
│   ├── showCropping()
│   └── reset()
└── Private Methods
    ├── processBatch()
    ├── askToCrop()
    ├── extractRecipeFromImage()
    └── saveRecipe()
```

## Usage Example

```swift
// From RecipeExtractorView
.sheet(isPresented: $showBatchImageExtraction) {
    BatchImageExtractorView(apiKey: apiKey, modelContext: modelContext)
}
```

## Dependencies

- SwiftUI
- SwiftData
- Photos (PhotoKit)
- Foundation (FileManager)
- ClaudeAPIClient
- ImagePreprocessor
- PhotoLibraryManager
- Recipe, RecipeModel, RecipeImageAssignment

## Logging

All significant events are logged with appropriate categories:
- `category: "batch"` - Batch processing events
- Includes: start, pause, resume, stop, progress, completion
- Error logging for failures

## Accessibility

- All buttons have descriptive labels
- Images have proper roles
- Progress is announced
- Error messages are clear
- Color is not sole indicator (uses icons)
