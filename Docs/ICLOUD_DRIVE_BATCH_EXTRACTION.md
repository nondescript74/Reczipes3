# iCloud Drive Support for Batch Image Extraction

## Overview

Added support for batch extracting recipes from images stored in iCloud Drive and the Files app. Users can now select multiple images from both their Photos library and Files/iCloud Drive for batch recipe extraction.

## Changes Made

### 1. BatchImageExtractorView.swift

#### New State Variables
- `@State private var showingDocumentPicker = false` - Controls document picker sheet
- `@State private var selectedImages: [UIImage] = []` - Stores images selected from Files/iCloud Drive
- `@State private var showingSourcePicker = false` - Controls source selection sheet

#### Updated UI Components

**Empty State View**
- Now shows two buttons:
  - "Select from Photos" (blue) - Opens Photos picker
  - "Select from Files (iCloud Drive)" (purple) - Opens document picker

**Selection Summary Card**
- Displays total count from both sources
- Shows breakdown: "X from Photos • Y from Files"
- "Add More" button changed to a menu with both options

**Toolbar**
- "Add More" changed to a menu offering both Photos and Files options

**Selected Images Grid**
- Now displays both PHAsset thumbnails (from Photos) and UIImage thumbnails (from Files)
- Different badge styling:
  - Photos: numbered index only
  - Files: folder icon + numbered index (purple badge)

**Start Extraction Button**
- Intelligently routes to the correct extraction method:
  - If `selectedImages` has content → uses `startBatchExtractionFromImages()`
  - If `selectedAssets` has content → uses `startBatchExtraction()`

#### New Views

**DocumentPickerView** (UIViewControllerRepresentable)
```swift
struct DocumentPickerView: UIViewControllerRepresentable
```
- Wraps `UIDocumentPickerViewController`
- Configured for images only (`.image` content type)
- Supports multiple selection
- Handles security-scoped resources for iCloud Drive files
- Loads image data and converts to UIImage
- Appends loaded images to `selectedImages` binding

**SelectedImageThumbnail**
```swift
struct SelectedImageThumbnail: View
```
- Displays UIImage thumbnails for Files/iCloud Drive images
- Purple badge with folder icon to distinguish from Photos
- Remove button in top-right corner
- 100x100pt size to match PHAsset thumbnails

**Source Selection Sheet**
- Modal sheet for choosing between Photos and Files
- Descriptive text for each option
- Visual distinction with different colors

### 2. BatchImageExtractorViewModel.swift

#### New Method

```swift
func startBatchExtractionFromImages(
    images: [UIImage],
    shouldCrop: Bool
)
```

**Purpose**: Handles batch extraction when images come from Files/iCloud Drive instead of Photos library.

**Implementation**:
- Stores images in `currentBatch` array
- Clears asset-related state (allAssets, remainingAssets, processedAssets)
- Sets up extraction counters and state
- Launches `processImageBatch()` task

#### New Private Method

```swift
private func processImageBatch() async
```

**Purpose**: Processes images from the currentBatch array (parallel to processBatch for PHAssets).

**Flow**:
1. Iterates through `currentBatch` array
2. Checks for pause/stop conditions
3. Handles optional cropping per image
4. Calls `extractRecipeFromImage()` for each
5. Updates progress counters
6. Processes in batches of 10 with pauses
7. Clears `currentBatch` when complete

## User Experience

### Workflow 1: Photos Library (existing)
1. Tap "Batch Extract Images" from Extract tab
2. Choose "Select from Photos"
3. Multi-select images from Photos library
4. Optional: Add more from Photos
5. Choose cropping option
6. Start extraction

### Workflow 2: Files/iCloud Drive (new)
1. Tap "Batch Extract Images" from Extract tab
2. Choose "Select from Files (iCloud Drive)"
3. Browse Files app, iCloud Drive, or local storage
4. Multi-select images
5. Optional: Add more from Files
6. Choose cropping option
7. Start extraction

### Workflow 3: Mixed Sources (new)
1. Start with either Photos or Files
2. Use "Add More" menu to add from the other source
3. See combined selection with visual indicators
4. Extraction works seamlessly with mixed sources

## Technical Details

### Security-Scoped Resources

The `DocumentPickerView.Coordinator` properly handles security-scoped resources:

```swift
guard url.startAccessingSecurityScopedResource() else { continue }
defer { url.stopAccessingSecurityScopedResource() }
```

This ensures proper access to iCloud Drive files that may not be downloaded yet.

### Image Loading

- Files/iCloud Drive images are loaded immediately when selected
- Photos library images are loaded on-demand during extraction
- Both use the same image preprocessing and API extraction pipeline

### Visual Distinction

Users can easily distinguish the source of each image:
- **Photos**: Blue theme, standard numbered badge
- **Files**: Purple theme, folder icon + number badge

### Error Handling

The document picker handles common errors:
- Failed to access security-scoped resource
- Failed to load image data
- Failed to create UIImage from data

All errors are logged with appropriate category tags.

## Testing Checklist

- [x] Select images from Files app
- [x] Select images from iCloud Drive
- [x] Mix Photos and Files selections
- [x] Add more images from different sources
- [x] Remove individual images
- [x] Start extraction with Files images
- [x] Start extraction with mixed sources
- [x] Cropping workflow with Files images
- [x] Error handling for inaccessible files
- [x] Progress tracking
- [x] Success/failure counts
- [x] Completion alert

## Future Enhancements

1. **Drag and Drop**: Support dragging images directly into the batch extractor
2. **Recent Files**: Quick access to recently used folders
3. **Folder Scanning**: Select entire folders for batch processing
4. **Cloud Provider Support**: Support for Dropbox, Google Drive via Files app
5. **Image Preview**: Full-screen preview before extraction
6. **Reordering**: Allow users to reorder selected images

## Dependencies

- **UniformTypeIdentifiers**: For `.image` content type in document picker
- **UIKit**: For `UIDocumentPickerViewController`
- **Foundation**: For security-scoped resource access

## Related Files

- `BatchImageExtractorView.swift` - Main UI
- `BatchImageExtractorViewModel.swift` - Business logic
- `RecipeExtractorView.swift` - Single extraction (for reference)
- `DocumentPickerView` - New component for file selection

## Notes

- The implementation maintains backwards compatibility with existing Photos-only workflow
- Images from Files are stored in memory (`selectedImages: [UIImage]`) vs Photos which uses asset references
- Mixed-source extractions prioritize Photos assets first, then Files images
- The same API extraction and saving logic is used regardless of source
