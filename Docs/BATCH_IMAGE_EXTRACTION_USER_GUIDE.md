# Batch Image Extraction - Quick Start Guide

## What is Batch Image Extraction?

Batch Image Extraction allows you to extract multiple recipes from images stored in your Photos library at once, saving you time when you have many recipe photos to process.

## How to Use

### Basic Workflow (No Cropping)

1. **Open Recipe Extractor**
   - Tap the "+" button or "Extract Recipe" in your app
   
2. **Select Batch Image Extract**
   - Tap "Batch Extract Images" (orange button with photo stack icon)
   
3. **Grant Photos Permission**
   - If prompted, allow the app to access your Photos library
   
4. **Select Images**
   - Tap "Select Photos" 
   - Choose multiple recipe images from your library
   - Tap "Add (X)" to confirm selection
   
5. **Configure Options**
   - Toggle OFF "Crop each image before extraction" for fastest processing
   
6. **Start Extraction**
   - Tap "Start Extraction"
   - Watch as the app processes up to 10 images at a time
   
7. **Monitor Progress**
   - See real-time updates as each recipe is extracted
   - View success/failure counts
   - See remaining queue
   
8. **Review Results**
   - Completion alert shows total success/failure
   - All recipes are saved to your collection
   - Failed extractions are logged with error details

### Advanced Workflow (With Cropping)

1. **Follow steps 1-4 above**

2. **Enable Cropping**
   - Toggle ON "Crop each image before extraction"
   
3. **Start Extraction**
   - Tap "Start with Cropping"
   
4. **For Each Image**
   - View image preview
   - Choose "Skip" to use as-is OR "Crop" to adjust
   - If Crop:
     - Adjust crop area
     - Tap "Crop" to confirm or "Cancel" to skip
   - Extraction begins automatically after decision
   
5. **Continue Through Queue**
   - Repeat for each image
   - Can pause/resume at any time
   - Queue updates showing remaining images

## Controls During Extraction

### Pause
- Temporarily halt processing
- Current image completes first
- Tap "Resume" to continue

### Stop
- Cancel entire batch operation
- Recipes extracted so far are saved
- Remaining images are not processed

### Skip (During Crop)
- Use original image without cropping
- Faster than cropping each image

## Tips for Best Results

### Image Selection
- ✅ Select clear, well-lit recipe photos
- ✅ Include full recipe in frame
- ✅ Avoid blurry or angled shots
- ✅ Can mix different recipes

### Batch Size
- 📱 1-10 images: Quick and simple
- 📸 10-20 images: Recommended size
- 🎯 20+ images: Use pause/resume if needed

### Cropping Decision
- **Use Cropping When:**
  - Images have extra content (ads, headers)
  - Recipe is only in part of photo
  - Want precise framing
  
- **Skip Cropping When:**
  - Images are already well-framed
  - Want fastest processing
  - Recipe fills entire photo

## Understanding the Queue

The app processes images in batches of 10:
- **First 10**: Processed immediately
- **After 10**: Brief pause to show progress
- **Next 10**: Continue processing
- **And so on**: Until all complete

### Queue Display
- Shows next 10 images in line
- Updates as each image is processed
- Removed images are marked as processed

## Error Handling

### If an Image Fails
- Batch continues with next image
- Failure is logged with reason
- Can review error log after completion
- Retry failed images individually later

### Common Issues
1. **"Failed to load image"**
   - Photo may be in iCloud
   - Wait for download to complete
   
2. **"API error"**
   - Check internet connection
   - May be rate limited (pause and resume)
   
3. **"Failed to process image"**
   - Image may be corrupted
   - Try different compression

## After Extraction

### Viewing Recipes
- All successful extractions saved automatically
- Find in main recipe collection
- Each has associated image
- Can edit, tag, or delete as needed

### Reviewing Errors
- Error log shows failed images
- Click to see specific error
- Can manually extract failed ones later

### Statistics
- Success count: Recipes extracted
- Failure count: Images that failed
- Progress: Current position in queue

## Example Scenarios

### Scenario 1: Recipe Book Pages
**Goal:** Extract 20 pages from a cookbook

1. Take 20 photos of cookbook pages
2. Select all 20 in batch extractor
3. Disable cropping (pages are full frame)
4. Start extraction
5. Wait ~5-10 minutes
6. 20 recipes in your collection!

### Scenario 2: Mixed Recipe Cards
**Goal:** Extract 15 recipe cards with varying quality

1. Select all 15 images
2. Enable cropping
3. Crop clear cards, skip blurry ones
4. Pause if needed to review
5. Check error log for failures
6. Retry failed ones individually

### Scenario 3: Social Media Screenshots
**Goal:** Extract recipes from saved Instagram posts

1. Select screenshot images
2. Enable cropping
3. Crop to remove UI elements
4. Extract recipe content only
5. Save with reference URLs

## Troubleshooting

### "No Photos Available"
- Grant Photos permission in Settings
- Check Photos library has images
- Restart app if needed

### "Extraction Stuck"
- Check internet connection
- Pause and resume
- Stop and restart batch

### "All Extractions Failed"
- Verify API key is valid
- Check image quality
- Try smaller batch size
- Test single extraction first

## Performance Notes

### Processing Time
- ~10-30 seconds per image
- Depends on image size and complexity
- Network speed affects API calls

### Memory Usage
- One image in memory at a time
- Thumbnails cached by system
- Safe for large batches

### Battery Impact
- Moderate during active extraction
- Can pause to save battery
- Process when charging for large batches

## Privacy & Storage

### Photos Access
- Read-only permission required
- App never modifies your Photos
- Selected images copied to app storage

### Data Storage
- Images saved to app Documents
- Reduced to ~500KB each
- Recipes stored in app database
- Not uploaded anywhere

## Keyboard Shortcuts (iPad)

- ⌘N: Start new extraction
- ⌘P: Pause/Resume
- ⌘.: Stop extraction
- ⌘W: Close batch extractor

## Accessibility

- VoiceOver supported
- Dynamic Type respected
- Color-independent indicators
- Progress announcements
- Button labels are descriptive

## Next Steps

After batch extraction:
1. Review extracted recipes
2. Edit any errors or missing info
3. Add tags or categories
4. Share favorites
5. Delete unwanted recipes

## Getting Help

If you encounter issues:
1. Check error log for details
2. Try extracting problematic images individually
3. Verify Photos permissions
4. Check internet connection
5. Restart app if persistent issues

---

**Pro Tip:** Start with a small batch (3-5 images) to test the feature and understand the workflow before processing larger batches!
