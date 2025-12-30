# Image Crop View - User Guide

## How to Use the Crop Feature

### Starting the Crop

1. **From Camera**:
   - Tap "Camera" button in Recipe Extractor
   - Take a photo of your recipe
   - Crop view automatically appears

2. **From Photo Library**:
   - Tap "Photo Library" button in Recipe Extractor
   - Select an existing photo
   - Crop view automatically appears

### Using the Crop View

```
┌─────────────────────────────────────┐
│  "Drag corners to crop"             │
├─────────────────────────────────────┤
│                                     │
│    ⬛ (dimmed area)                 │
│    ┌─────────────────────┐         │
│    │ ◯               ◯   │         │
│    │                     │         │
│    │    YOUR IMAGE       │         │
│    │    (bright area)    │         │
│    │    with grid lines  │         │
│    │                     │         │
│    │ ◯               ◯   │         │
│    └─────────────────────┘         │
│    ⬛ (dimmed area)                 │
│                                     │
├─────────────────────────────────────┤
│  [↻ Reset]  [Cancel] [Skip] [Crop] │
└─────────────────────────────────────┘
```

### Controls

#### Gestures

**1. Drag Corners (◯)**
- Touch any white circle at the corners
- Drag to resize the crop area
- All four corners are draggable
- Crop area stays within image bounds

**2. Drag Rectangle**
- Touch inside the white rectangle (not on corners)
- Drag to move entire crop area
- Useful for repositioning without resizing

**3. Pinch to Zoom**
- Use two fingers to pinch in/out
- Zooms the underlying image
- Helps with precise crop selection

**4. Pan Image**
- After zooming, drag with one finger
- Moves the image around
- Crop rectangle stays in place

#### Buttons

**Reset (↻)**
- Returns crop to default position
- Resets zoom to 1:1
- Recenters image
- Crop area returns to 80% of image

**Cancel**
- Exits crop view
- Returns to recipe extractor
- No extraction happens

**Skip**
- Uses the original uncropped image
- Proceeds directly to extraction
- Good for images that don't need cropping

**Crop & Use** (Primary action)
- Applies the current crop selection
- Proceeds to recipe extraction
- Saves cropped image

### Visual Indicators

**Grid Lines**
Displays a 3×3 grid (rule of thirds) to help with composition:
```
┌───┬───┬───┐
│   │   │   │
├───┼───┼───┤
│   │   │   │
├───┼───┼───┤
│   │   │   │
└───┴───┴───┘
```

**Dimmed Overlay**
- Area outside crop rectangle is darkened (60% black)
- Crop area remains bright and clear
- Easy to see what will be included/excluded

**Corner Handles**
- White circles at each corner
- 15pt visible diameter
- 30pt touch target (easier to grab)
- Black outline for contrast

### Tips for Best Results

1. **Zoom Before Cropping**
   - Pinch to zoom in on the recipe
   - Helps exclude unwanted content (ads, headers)
   - Use pan gesture to position correctly

2. **Use Grid Lines**
   - Align recipe title/image with grid lines
   - Follow rule of thirds for better composition
   - Helps keep text straight

3. **Include All Important Info**
   - Make sure all ingredients are visible
   - Include full instructions
   - Don't cut off measurement units

4. **Remove Distractions**
   - Crop out advertisements
   - Remove page numbers if not needed
   - Exclude irrelevant surrounding content

5. **When to Skip**
   - Recipe already fills entire image
   - No unnecessary content to remove
   - In a hurry (can always retake later)

### Common Scenarios

#### Cookbook Page
```
Before:                  After Crop:
┌──────────────┐        ┌────────────┐
│ Page Header  │        │ Recipe     │
│──────────────│   →    │ Title      │
│ Recipe Title │        ├────────────┤
│──────────────│        │ Ingred...  │
│ Ingredients  │        │ - Flour    │
│ - Flour      │        │ - Sugar    │
│ - Sugar      │        │ - Eggs     │
│ - Eggs       │        ├────────────┤
│──────────────│        │ Instruct.. │
│ Instructions │        │ 1. Mix...  │
│ 1. Mix flour │        │ 2. Bake... │
│ 2. Bake...   │        └────────────┘
│──────────────│
│ Page Footer  │
│ Page 42      │
└──────────────┘
```

#### Recipe Card with Background
```
Before:                  After Crop:
┌──────────────┐        ┌─────────┐
│              │        │ RECIPE  │
│  Background  │        │─────────│
│  ┌────────┐  │   →    │ - Item1 │
│  │ RECIPE │  │        │ - Item2 │
│  │────────│  │        │ - Item3 │
│  │ Ingred │  │        │─────────│
│  │────────│  │        │ Steps:  │
│  └────────┘  │        │ 1...    │
│              │        └─────────┘
└──────────────┘
```

#### Website Screenshot
```
Before:                  After Crop:
┌──────────────┐        ┌────────┐
│ Site Header  │        │ Lasagna│
│──────────────│        ├────────┤
│ [Ad Banner]  │        │ Ingr:  │
│──────────────│   →    │ - ...  │
│ Recipe:      │        ├────────┤
│ Lasagna      │        │ Steps: │
│ Ingredients: │        │ 1. ... │
│ - ...        │        │ 2. ... │
│──────────────│        └────────┘
│ [Comments]   │
│ [More Ads]   │
└──────────────┘
```

### Minimum Crop Size

The crop area has a minimum size of **100 points** to ensure:
- Recipe content remains readable
- Claude API can extract text accurately
- Image quality is sufficient for OCR

If you try to make the crop smaller, it will stop at this limit.

### Technical Notes

**Image Quality**
- Cropping uses original image resolution
- No quality loss from crop operation
- JPEG compression applied at 80% quality after crop

**Coordinate Handling**
- Automatically handles different screen sizes
- Adjusts for image aspect ratios
- Maintains correct proportions on crop

**Orientation**
- Respects original image orientation
- Works with portrait and landscape
- Handles rotated images correctly

### Troubleshooting

**Problem**: Can't see the entire image
**Solution**: Pinch to zoom out, then adjust crop

**Problem**: Crop handle is hard to grab
**Solution**: Touch target is larger than visible circle - aim near it

**Problem**: Image is sideways
**Solution**: Cancel and rotate in Photos app first, then re-import

**Problem**: Crop is too restrictive
**Solution**: Use "Skip" button to use original image

**Problem**: Need to start over
**Solution**: Press "Reset" button or "Cancel" and try again

### Keyboard Shortcuts (iPad)

When crop view is active:
- **ESC**: Cancel crop
- **Enter**: Apply crop and extract
- **Space**: Toggle between crop and original
- **R**: Reset crop to default

*Note: Keyboard shortcuts require external keyboard*

---

**For More Help**: See IMAGE_CROP_FEATURE_SUMMARY.md for technical details
