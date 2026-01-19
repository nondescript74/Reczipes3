# Batch Recipe Extraction User Guide

## How to Extract Recipes from iCloud Drive Images

### Getting Started

The Batch Image Extraction feature now supports selecting recipe images from multiple sources:

- 📱 **Photos Library** - Images saved to your device
- 📁 **Files/iCloud Drive** - Images stored in the cloud or other file providers

### Step-by-Step Instructions

#### Option 1: Extract from Photos Library

1. Open the app and tap the **Extract** tab
2. Tap **Batch Extract Images**
3. Tap **Select from Photos**
4. Multi-select recipe images from your Photos library
   - Tap each image to select/deselect
   - Selected images show a blue checkmark
5. Tap **Done** when finished selecting
6. Review your selection
7. Choose whether to crop each image (optional)
8. Tap **Start Extraction**

#### Option 2: Extract from Files/iCloud Drive

1. Open the app and tap the **Extract** tab
2. Tap **Batch Extract Images**
3. Tap **Select from Files (iCloud Drive)**
4. Browse to your recipe images:
   - **iCloud Drive** folder
   - **On My iPhone/iPad**
   - **Third-party cloud storage** (Dropbox, Google Drive, etc.)
5. Multi-select images (tap each one)
6. Tap **Open** when finished
7. Review your selection (images show purple folder badge)
8. Choose whether to crop each image (optional)
9. Tap **Start Extraction**

#### Option 3: Mix Both Sources

You can combine images from both Photos and Files!

1. Start by selecting from either Photos or Files
2. Tap the **+** menu button (top-right)
3. Choose the other source to add more images
4. Your selection will show:
   - Blue badges for Photos images
   - Purple badges with folder icon for Files images
5. Continue extraction as normal

### Understanding the Interface

#### Empty State Screen

When you first open Batch Extract, you'll see:

```
┌─────────────────────────────┐
│    [photo.stack icon]       │
│                             │
│  Select Images to Extract   │
│                             │
│ Choose multiple recipe      │
│ images from Photos or Files │
│                             │
│ [Select from Photos]        │  ← Blue button
│ [Select from Files]         │  ← Purple button
│                             │
└─────────────────────────────┘
```

#### Selection Summary

Once you've selected images:

```
┌─────────────────────────────────────┐
│ [📸]  Images Selected         [+]   │  ← Tap + to add more
│       5 images ready                │
│       3 from Photos • 2 from Files  │
└─────────────────────────────────────┘
```

#### Image Grid

Your selected images appear in a grid:

```
┌─────┐ ┌─────┐ ┌─────┐
│ [X] │ │ [X] │ │ [X] │  ← Tap X to remove
│     │ │     │ │     │
│ [1] │ │ [2] │ │[📁3]│  ← Folder icon = Files
└─────┘ └─────┘ └─────┘
```

- **Numbers only** = Photos library image
- **Folder + number** = Files/iCloud Drive image

### Cropping Options

Before extraction begins, you can choose:

**Option A: Crop Each Image**
- You'll be prompted for each image: "Crop" or "Skip"
- Allows precise framing of recipe content
- Takes more time but improves accuracy

**Option B: Skip Cropping (Faster)**
- All images processed as-is
- Faster batch processing
- Best for pre-cropped or well-framed images

### During Extraction

#### Progress Screen

```
┌─────────────────────────────────────┐
│ Extracting Recipes                  │
│ Processing image 3 of 10            │
│                                     │
│ ████████░░░░░░░░░░░░░░░░░░░░ 30%  │
│                                     │
│ Progress: 3/10                      │
│ Success: 2    Failed: 1             │
│                                     │
│ [Pause]            [Stop]           │
└─────────────────────────────────────┘
```

#### Controls

- **Pause** - Temporarily stop extraction (can resume later)
- **Resume** - Continue after pausing
- **Stop** - Cancel the entire batch
- **Close** - Exit and stop extraction

### Batch Processing

The app processes images in batches of **10 at a time** to avoid overwhelming the API and maintain responsive performance.

Progress updates show:
- Current image being processed
- Total progress (X/Y)
- Success count
- Failure count (if any)

### Completion

When extraction finishes, you'll see:

```
┌─────────────────────────────────────┐
│ ✓ Batch Extraction Complete         │
│                                     │
│ Extracted 8 recipes successfully    │
│ with 2 failures                     │
│                                     │
│ [View Recipes]    [OK]              │
└─────────────────────────────────────┘
```

- **View Recipes** - Go to recipe collection to see results
- **OK** - Reset and extract another batch

### Tips for Best Results

#### Image Quality

✅ **Good Images:**
- Clear, well-lit photos
- Recipe text is legible
- Minimal background clutter
- Standard orientation

❌ **Problematic Images:**
- Blurry or out of focus
- Too dark or overexposed
- Text too small to read
- Heavily filtered or edited

#### File Organization

**For Files/iCloud Drive:**
- Keep recipe images in a dedicated folder
- Use descriptive filenames
- Ensure images are fully downloaded (not just placeholders)

**For Photos:**
- Create an album for recipe images
- Tag or favorite recipes for easy finding
- Consider using Photos search for "recipe" or "food"

#### Selection Strategy

1. **Start small** - Try 5-10 images first
2. **Check results** - Review extraction quality
3. **Adjust approach** - Enable cropping if needed
4. **Scale up** - Process larger batches once dialed in

### Troubleshooting

#### "Failed to load image from Files"

**Problem**: Image file couldn't be accessed  
**Solution**: 
- Ensure the file is downloaded to your device (not just in the cloud)
- Check you have permission to access the folder
- Try copying the image to a local folder first

#### "API error" during extraction

**Problem**: Recipe extraction failed  
**Solution**:
- Check your internet connection
- Verify API key is configured in Settings
- Image may not contain readable recipe text
- Try cropping to focus on recipe content

#### Images appear blank in grid

**Problem**: Thumbnails not loading  
**Solution**:
- Wait a moment for images to load
- Check file format is supported (JPG, PNG)
- Files images load from memory, Photos on-demand

### Privacy & Storage

- **Photos Access**: Requires Photos library permission
- **Files Access**: Operates through standard iOS file picker
- **iCloud Drive**: Respects iCloud sync settings
- **Local Storage**: Images not duplicated, references used when possible

### FAQ

**Q: Can I mix images from different sources?**  
A: Yes! Select from Photos, then use "Add More" → "From Files" to combine sources.

**Q: How many images can I extract at once?**  
A: There's no hard limit, but batches of 10-20 work best for performance and API limits.

**Q: What happens if I close the app during extraction?**  
A: Extraction will stop. Completed recipes are saved, but incomplete ones are lost.

**Q: Can I reorder the images?**  
A: Not currently. They process in the order selected.

**Q: Do I need internet for this feature?**  
A: Yes, the Claude API requires an internet connection for recipe extraction.

**Q: What image formats are supported?**  
A: JPG, PNG, HEIC, and most standard image formats.

### Advanced Usage

#### Processing Large Recipe Collections

For 50+ recipes:
1. Break into smaller batches (10-20 each)
2. Use cropping selectively (only when needed)
3. Process during good internet connectivity
4. Monitor success/failure rates

#### Optimizing for Speed

- **Disable cropping** for well-framed images
- **Batch size** of 10-15 for fastest processing
- **Pre-crop** images in Photos app before selecting

#### Handling Errors

Check the error log during extraction:
- Shows which image failed
- Displays error message
- Helps identify problematic images

### Support

If you encounter issues:
1. Check Settings → Developer Tools → Diagnostics
2. Review the batch extraction logs
3. Try extracting the problematic image individually
4. Contact support with diagnostic information

---

**Version**: 1.0  
**Last Updated**: January 2026  
**Feature**: Batch Image Extraction with iCloud Drive Support
