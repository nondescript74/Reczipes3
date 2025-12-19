# Web Image Extraction - Testing Checklist

## Basic Functionality Tests

### ✅ Happy Path - Recipe with Images
- [ ] Extract recipe from Serious Eats URL
- [ ] Verify image URLs are detected (check console logs: "🖼️ Found X image URL(s)")
- [ ] Verify "Select Recipe Image (X available)" button appears
- [ ] Tap button to open image picker sheet
- [ ] Verify images load in grid with AsyncImage
- [ ] Select an image (blue border should appear)
- [ ] Tap "Done" to confirm selection
- [ ] Verify selected image preview shows in recipe section
- [ ] Tap "Save to Collection"
- [ ] Verify "Downloading Image..." appears
- [ ] Verify success alert shows "recipe and its image have been added"
- [ ] Check that image is saved in documents directory
- [ ] Check that RecipeImageAssignment is created

### ✅ Skip Image Selection
- [ ] Extract recipe with images available
- [ ] Don't select any image
- [ ] Tap "Save to Collection" directly
- [ ] Verify recipe saves without image
- [ ] No crashes or errors

### ✅ Change Image Selection
- [ ] Extract recipe with images
- [ ] Select image #1
- [ ] Tap "Change Image" button
- [ ] Select image #2 instead
- [ ] Verify preview updates
- [ ] Save and verify correct image is saved

### ✅ Recipe Without Images
- [ ] Extract recipe from URL with no images (test with text-only blog)
- [ ] Verify no image picker button shows
- [ ] Verify normal save flow works
- [ ] Recipe saves successfully without image

## Error Handling Tests

### ⚠️ Network Errors
- [ ] Extract recipe with valid image URLs
- [ ] Turn off WiFi/cellular before downloading
- [ ] Tap "Save to Collection"
- [ ] Verify download fails gracefully
- [ ] Recipe should still save (without image)
- [ ] No crash or app freeze

### ⚠️ Invalid Image URLs
- [ ] Manually test with broken image URL (modify code temporarily)
- [ ] Verify 404 error is handled
- [ ] AsyncImage shows error state in picker
- [ ] Can still select other images
- [ ] Save works with valid image

### ⚠️ Image Download Timeout
- [ ] Test with very large image (>10MB)
- [ ] Verify 30-second timeout works
- [ ] Recipe saves even if timeout occurs

### ⚠️ Corrupted Image Data
- [ ] Test URL that returns HTML instead of image
- [ ] Verify error is caught
- [ ] Recipe saves without image

## UI/UX Tests

### 🎨 Visual States
- [ ] AsyncImage shows spinner while loading
- [ ] AsyncImage shows error icon if load fails
- [ ] Selected image has blue border and checkmark
- [ ] Download progress shows "Downloading Image..." with spinner
- [ ] Download button is disabled during download

### 🎨 Navigation
- [ ] Image picker sheet dismisses on "Skip"
- [ ] Image picker sheet dismisses on "Done"
- [ ] "Done" button is disabled if no image selected
- [ ] Can tap "Close" to exit without saving
- [ ] "Extract Another" resets all state properly

### 🎨 Layout
- [ ] Images display in 2-column grid
- [ ] Images scale properly (aspectRatio .fill)
- [ ] Grid scrolls if more than 4 images
- [ ] Works on different screen sizes (iPhone SE, Pro Max, iPad)

## Integration Tests

### 🔗 Different Recipe Websites
- [ ] Serious Eats (JSON-LD + multiple images)
- [ ] AllRecipes (JSON-LD)
- [ ] Food Network (og:image)
- [ ] Personal blog (img tags only)
- [ ] BBC Good Food
- [ ] NYT Cooking

### 🔗 Image Extraction Sources
- [ ] Verify JSON-LD images are found (Priority 1)
- [ ] Verify og:image is found if no JSON-LD (Priority 2)
- [ ] Verify img tags are found as last resort (Priority 3)
- [ ] Check console logs for extraction order

### 🔗 Image Formats
- [ ] JPEG images
- [ ] PNG images
- [ ] WebP images (if supported by UIImage)
- [ ] Verify SVG is filtered out
- [ ] Verify data URLs are filtered out

## Performance Tests

### ⚡ Large Websites
- [ ] Extract from site with 50+ images
- [ ] Verify only first 10 are considered
- [ ] App remains responsive

### ⚡ Memory Usage
- [ ] Load picker with 10 images
- [ ] Monitor memory usage
- [ ] Close picker and verify memory is released
- [ ] AsyncImage should handle caching automatically

### ⚡ Concurrent Downloads
- [ ] Open picker, see images loading
- [ ] Quickly select and save
- [ ] Verify single download happens, not multiple

## Data Persistence Tests

### 💾 SwiftData Integration
- [ ] Save recipe with web image
- [ ] Close app completely
- [ ] Reopen app
- [ ] Verify recipe shows with image
- [ ] Verify image file exists in documents directory
- [ ] Verify RecipeImageAssignment exists

### 💾 Image Filename Generation
- [ ] Check saved filename format: `recipe_{UUID}.jpg`
- [ ] Verify no filename conflicts
- [ ] Save multiple recipes with images
- [ ] Check all files are unique

## Edge Cases

### 🔍 Special Cases
- [ ] Recipe with 1 image only
  - [ ] Should still show picker (allows skip)
  - [ ] Or auto-select? (design decision)
- [ ] Recipe with 100+ images
  - [ ] Verify limited to 10
  - [ ] No performance issues
- [ ] Relative image URLs
  - [ ] Currently not handled (known limitation)
  - [ ] Document in notes
- [ ] HTTPS vs HTTP images
  - [ ] Verify both work
  - [ ] App Transport Security settings

### 🔍 User Actions
- [ ] Extract recipe, select image, then extract another recipe
  - [ ] Verify state resets properly
- [ ] Extract recipe, start downloading, then tap "Extract Another"
  - [ ] Verify download cancels or completes safely
- [ ] Rapidly tap "Save to Collection" multiple times
  - [ ] Should only save once
  - [ ] Button should be disabled during download

## Accessibility Tests

### ♿ VoiceOver
- [ ] Image picker is navigable with VoiceOver
- [ ] Selected state is announced
- [ ] Buttons have proper labels
- [ ] AsyncImage loading states are announced

### ♿ Dynamic Type
- [ ] Test with largest text size
- [ ] Labels don't truncate
- [ ] Layout remains usable

## Logging & Debugging

### 🐛 Console Output
- [ ] "🖼️ Extracting image URLs from HTML..."
- [ ] "🖼️ ✅ Found X image URL(s)"
- [ ] "🖼️   [1] https://..."
- [ ] "🖼️ ========== IMAGE DOWNLOAD START =========="
- [ ] "🖼️ ✅ Successfully downloaded image"
- [ ] "✅ Saved recipe image to: ..."
- [ ] "✅ Created image assignment for recipe: ..."

### 🐛 Error Logging
- [ ] "❌ Failed to download image: ..."
- [ ] "🖼️ ❌ Invalid URL"
- [ ] "🖼️ ❌ HTTP error: 404"
- [ ] Errors are logged but don't crash app

## Regression Tests

### 🔄 Existing Functionality
- [ ] Camera extraction still works
- [ ] Photo library extraction still works
- [ ] Image extraction (non-web) still works
- [ ] Image preprocessing toggle still works
- [ ] Recipes without images save normally
- [ ] Recipe list displays correctly
- [ ] Recipe detail view shows images

---

## Test Results Template

```
Date: _______________
Tester: _______________
Build: _______________

| Test Category | Pass | Fail | Notes |
|--------------|------|------|-------|
| Basic Functionality | ☐ | ☐ | |
| Error Handling | ☐ | ☐ | |
| UI/UX | ☐ | ☐ | |
| Integration | ☐ | ☐ | |
| Performance | ☐ | ☐ | |
| Data Persistence | ☐ | ☐ | |
| Edge Cases | ☐ | ☐ | |
| Accessibility | ☐ | ☐ | |

### Critical Issues Found:
1. 
2. 
3. 

### Minor Issues Found:
1. 
2. 
3. 

### Suggestions:
1. 
2. 
3. 
```

## Known Limitations (Document These)

1. **Relative URLs**: Currently not resolved against base URL
   - Needs URL base resolution implementation
   
2. **Image Quality**: No automatic quality detection
   - Could implement dimension checking
   
3. **Multiple Images**: Only one image per recipe
   - Future: Support image galleries
   
4. **CDN/Responsive Images**: srcset attributes not parsed
   - Could select optimal resolution
   
5. **Authentication**: No support for auth-protected images
   - Would need cookie/session handling

## Automated Testing Opportunities

Consider adding unit tests for:
- `extractImageURLs()` with mock HTML
- URL validation logic
- Image filename generation
- Error handling paths

Consider adding UI tests for:
- Basic extraction flow
- Image selection flow
- Error recovery
