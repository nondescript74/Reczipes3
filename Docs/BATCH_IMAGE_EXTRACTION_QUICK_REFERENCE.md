# Batch Image Extraction - Quick Reference Card

## 🎯 Feature Overview
Extract multiple recipes from Photos library images with optional per-image cropping, real-time progress, and batch processing (10 at a time).

## 📦 Files

| File | Purpose | Lines |
|------|---------|-------|
| `BatchImageExtractorView.swift` | Main UI | ~800 |
| `BatchImageExtractorViewModel.swift` | Business logic | ~350 |
| `BatchImageCropIntegration.swift` | Integration helper | ~150 |

## 🔌 Integration Point

```swift
// In RecipeExtractorView.swift
.sheet(isPresented: $showBatchImageExtraction) {
    BatchImageExtractorView(apiKey: apiKey, modelContext: modelContext)
}
```

## 🎨 UI Components

```
Empty State → Photo Selection → Configuration → Extraction Progress
     ↓              ↓                ↓                   ↓
"Select     Multi-select     Crop toggle      Stats, current image,
 Photos"     photos           + Start          queue, controls
```

## 🔄 User Flows

### Fast Mode (No Crop)
```
Select → Toggle OFF → Start → Process all → Done
```

### Crop Mode
```
Select → Toggle ON → Start → For each: Skip/Crop → Done
```

## 🎛️ Controls

| Button | Action | Available When |
|--------|--------|----------------|
| Select Photos | Open picker | Empty / Selection |
| Add More | Add to selection | Selection view |
| Start Extraction | Begin batch | Selection view |
| Pause | Halt processing | Extracting |
| Resume | Continue | Paused |
| Stop | Cancel batch | Extracting/Paused |
| Skip | Use original | Waiting for crop |
| Crop | Show crop UI | Waiting for crop |

## 📊 State Properties

### Published (UI updates on change)
- `isExtracting: Bool` - Main extraction active
- `isPaused: Bool` - Temporarily halted
- `isWaitingForCrop: Bool` - User decision pending
- `currentProgress: Int` - Images processed
- `totalToExtract: Int` - Total in batch
- `successCount: Int` - Successful extractions
- `failureCount: Int` - Failed extractions
- `currentImage: UIImage?` - Current preview
- `currentRecipe: RecipeModel?` - Extracted recipe
- `remainingAssets: [PHAsset]` - Queue
- `errorLog: [(Int, String)]` - Failures
- `showingCropForBatch: Bool` - Crop sheet
- `imageToCropInBatch: UIImage?` - Image to crop

## 🔧 Key Methods

### ViewModel
```swift
startBatchExtraction(assets:photoManager:shouldCrop:)
pause()
resume()
stop()
skipCropping()
showCropping()
handleCroppedImage(_:)
reset()
```

### Private
```swift
processBatch(photoManager:)
requestCrop(for:)
askToCrop()
extractRecipeFromImage(_:imageIndex:)
saveRecipe(_:withImage:)
```

## 💾 Data Storage

### Recipe
```swift
let recipe = Recipe(from: recipeModel)
recipe.imageName = "recipe_\(uuid).jpg"
modelContext.insert(recipe)
```

### Image
```swift
// Reduced to 500KB
let imageData = imagePreprocessor.reduceImageSize(image, maxSizeBytes: 500_000)
// Saved to Documents/recipe_\(uuid).jpg
```

### Assignment
```swift
let assignment = RecipeImageAssignment(recipeID: recipe.id, imageName: imageName)
modelContext.insert(assignment)
```

## 🔁 Processing Loop

```swift
for asset in assets {
    guard isExtracting else { break }
    while isPaused { wait }
    
    load image from asset
    if shouldCrop { ask user, optionally crop }
    extract recipe via API
    save recipe + image
    
    update progress
    if progress % 10 == 0 { brief pause }
}
show completion alert
```

## 🎨 Color Scheme

- **Orange** - Batch images theme (`Color.orange`)
- **Purple** - Progress indicators (`Color.purple`)
- **Blue** - Selections (`Color.blue`)
- **Green** - Success (`Color.green`)
- **Red** - Errors (`Color.red`)

## 🔍 Testing Scenarios

| Scenario | Images | Crop | Expected |
|----------|--------|------|----------|
| Happy path | 5 | OFF | All succeed |
| With cropping | 3 | ON | Show crop UI |
| Mixed results | 10 | OFF | Some fail, logged |
| Pause/resume | 15 | OFF | Resumes correctly |
| Stop early | 20 | OFF | Saves partial |
| Large batch | 50 | OFF | No memory issues |

## 📱 Platform Support

- ✅ iOS 17+
- ✅ iPhone (all sizes)
- ✅ iPad (adapted layout)
- ✅ SwiftUI
- ✅ SwiftData
- ✅ PhotoKit

## ⚡ Performance

- **Memory**: 1 image at a time (~10MB peak)
- **Speed**: 10-30 sec/image (API dependent)
- **Batch Size**: Unlimited (processes 10 at a time)
- **Network**: Sequential API calls

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| "Failed to load" | Photo in iCloud, wait for download |
| "API error" | Check internet, may be rate limited |
| Permission denied | Grant in Settings → Privacy → Photos |
| All fail | Verify API key, test single extraction |

## 📚 Documentation

- `BATCH_IMAGE_EXTRACTION_GUIDE.md` - Developer guide
- `BATCH_IMAGE_EXTRACTION_USER_GUIDE.md` - User manual
- `BATCH_IMAGE_EXTRACTION_WORKFLOWS.md` - Flow diagrams
- `BATCH_IMAGE_EXTRACTION_SUMMARY.md` - Implementation summary
- `BATCH_IMAGE_EXTRACTION_CHECKLIST.md` - Testing checklist
- `BatchImageCropIntegration.swift` - Integration examples

## 🚀 Quick Start

1. **Add to project**: Already integrated in `RecipeExtractorView`
2. **Grant permission**: Photos → Read & Write
3. **Test**: Select 3 images, extract without crop
4. **Verify**: Check recipes saved, images on disk

## 🎯 Success Metrics

- ✅ Can select and extract 1 image
- ✅ Can extract 10+ images in one batch
- ✅ Cropping works for each image
- ✅ Pause/resume works correctly
- ✅ Errors don't stop batch
- ✅ All recipes and images saved
- ✅ Memory stays stable

## 💡 Tips

- Start with small batches (3-5) to learn
- Disable cropping for speed
- Use pause if battery low
- Review error log for failures
- Process when on WiFi for best speed
- Images auto-reduced to 500KB

## 🔮 Future Ideas

- Background processing
- Smart recipe detection
- Configurable batch sizes
- Retry failed items
- Export batch as PDF
- ML-based auto-cropping

## 📞 Support

Check documentation files for:
- Detailed architecture
- User workflows
- Troubleshooting
- Integration help
- Testing guidance

---

**Version**: 1.0.0  
**Created**: January 2026  
**Platform**: iOS 17+  
**Framework**: SwiftUI + SwiftData + PhotoKit
