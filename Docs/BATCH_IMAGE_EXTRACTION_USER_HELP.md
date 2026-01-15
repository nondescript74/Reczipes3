# Batch Image Extraction - User Help Section

## 📚 Extract Multiple Recipes at Once

**What is it?**  
Batch Image Extraction lets you select and process multiple recipe photos from your Photos library all at once, saving you time when digitizing recipe collections.

**When to use it:**
- Converting a stack of recipe cards to digital
- Digitizing pages from a cookbook
- Processing saved recipe screenshots
- Adding multiple recipes quickly

---

## 🚀 Quick Start

### Fast Mode (No Cropping)

1. **Open Batch Extract**
   - Tap the Extract tab
   - Tap "Batch Extract Images" (orange button with photo stack icon)

2. **Select Photos**
   - Grant Photos library permission if asked
   - Tap "Select Photos"
   - Choose your recipe images (tap multiple photos)
   - Tap "Add (X)" when done

3. **Start Processing**
   - Make sure "Crop each image" is toggled OFF
   - Tap "Start Extraction"
   - Watch the progress!

4. **Review Results**
   - See success/failure counts
   - Check error log if any failed
   - All successful recipes are saved automatically

**Time:** ~10-30 seconds per image

---

## ✂️ With Cropping (More Control)

If your photos need adjusting (removing extra content, focusing on recipe):

1. **Enable Cropping**
   - After selecting photos
   - Toggle "Crop each image before extraction" to ON

2. **Process Each Image**
   - For each photo, you'll see:
     - Image preview
     - "Skip" button (use as-is)
     - "Crop" button (adjust the photo)
   
3. **Make Your Choice**
   - **Skip**: Process the original image (faster)
   - **Crop**: Adjust the frame to focus on the recipe
   
4. **Continue Through Queue**
   - Repeat for each image
   - Can pause anytime
   - Queue shows remaining images

---

## 🎛️ Controls During Extraction

### Pause
- Temporarily stop processing
- Current image will finish first
- Tap "Resume" to continue

### Resume
- Continue from where you paused
- Picks up with next image

### Stop
- Cancel the entire batch
- Recipes extracted so far are saved
- Remaining images are skipped

---

## 💡 Tips for Best Results

### Selecting Images
✅ **Do:**
- Choose clear, well-lit photos
- Include full recipe in frame
- Use landscape orientation for wide cards
- Mix different recipes (any order)

❌ **Avoid:**
- Very blurry photos
- Extreme angles
- Photos with mostly non-recipe content
- Very low resolution images

### Batch Size
- **Small batch (3-5 images)**: Quick test, learn the feature
- **Medium batch (10-20 images)**: Recommended size
- **Large batch (50+ images)**: Use pause/resume, process on WiFi

### When to Crop
**Use Cropping When:**
- Images have ads or headers
- Recipe is only part of photo
- You want precise framing
- Multiple recipes on one page

**Skip Cropping When:**
- Photos are already well-framed
- Want fastest processing
- Recipe fills entire photo
- Time is limited

---

## 📊 Understanding Progress

### The Queue
Images process **10 at a time**:
```
Images 1-10  →  Brief pause to show progress
Images 11-20 →  Brief pause to show progress
Images 21-30 →  And so on...
```

### What You'll See
- **Progress bar**: How many done / total
- **Success count**: Recipes extracted ✅
- **Failure count**: Images that failed ❌
- **Current image**: What's processing now
- **Current recipe**: What was just extracted
- **Remaining queue**: Next 10 images to process

---

## 🔧 If Something Goes Wrong

### Common Issues

**"Failed to load image"**
- Photo might be in iCloud
- Wait for it to download
- Try again with fewer images

**"API error"**
- Check internet connection
- You might be rate-limited (pause, wait, resume)
- Verify API key in Settings

**"All extractions failed"**
- Verify API key is working
- Test single extraction first
- Check image quality

### Error Log
- Shows which images failed
- Explains why each failed
- Can retry failed images individually later

---

## 📱 Step-by-Step Example

**Scenario:** You have 15 recipe cards to digitize

1. Take photos of all 15 cards with your phone
2. Open Reczipes app → Extract tab
3. Tap "Batch Extract Images"
4. Grant Photos permission (first time)
5. Tap "Select Photos"
6. Select all 15 photos
7. Tap "Add (15)"
8. Toggle "Crop each image" OFF (cards are full-frame)
9. Tap "Start Extraction"
10. Watch progress: 
    - Images 1-10 process
    - Brief pause
    - Images 11-15 process
11. See completion: "Extracted 15 recipes successfully!"
12. All 15 recipes are now in your collection!

**Total time:** ~5-10 minutes

---

## ⚙️ Settings

### Photos Permission
- **Required**: Yes
- **Type**: Read photos
- **Location**: Settings → Privacy → Photos → Reczipes
- **Note**: App never modifies your Photos library

### Processing Options
- **Crop toggle**: Choose per batch
- **Image quality**: Auto-reduced to 500KB
- **Processing**: Sequential (one at a time)

---

## 💾 What Gets Saved

For each successful extraction:
- ✅ Recipe data (ingredients, instructions, etc.)
- ✅ Recipe image (compressed to 500KB)
- ✅ Recipe title and details
- ✅ Any detected allergen information

**Storage:**
- Recipes: App database
- Images: Documents folder
- Everything stored locally on your device

---

## ❓ Frequently Asked Questions

**Q: How many images can I process at once?**  
A: Unlimited! But we recommend 10-20 at a time for best experience.

**Q: Does it work offline?**  
A: No, you need internet for the AI extraction. But you can select photos offline and extract when connected.

**Q: Can I do something else while it's processing?**  
A: You can pause and close the app, but extraction pauses. Best to let it finish.

**Q: What if some images fail?**  
A: The batch continues! Failed images are logged, and you can retry them individually later.

**Q: Do I need to crop every image?**  
A: No! Cropping is optional. Toggle it OFF for fastest processing.

**Q: How much does it cost?**  
A: About $0.02 per recipe using your Claude API key.

**Q: Can I cancel mid-extraction?**  
A: Yes! Tap "Stop" and recipes extracted so far will be saved.

**Q: What happens to my original photos?**  
A: They stay in your Photos library - the app makes copies for recipes.

---

## 🎯 Best Practices

### Before You Start
1. Organize photos in Photos app
2. Delete bad/duplicate photos
3. Test with 3-5 images first
4. Make sure you're on WiFi

### During Extraction
1. Don't close the app
2. Keep device unlocked
3. Have good internet connection
4. Review progress occasionally

### After Extraction
1. Check success/failure counts
2. Review error log
3. Verify recipes look good
4. Edit any mistakes
5. Retry failed images if needed

---

## 🚀 Getting Started Checklist

- [ ] Have Claude API key set up
- [ ] Grant Photos library permission
- [ ] Select 3-5 test images
- [ ] Try without cropping first
- [ ] Review extracted recipes
- [ ] Try larger batch (10-20 images)
- [ ] Test pause/resume
- [ ] Process your full collection!

---

## 📞 Need More Help?

- **Recipe Extraction**: See "Recipe Extraction" help topic
- **Image Quality**: See "Image Preprocessing" help topic
- **API Setup**: See "Claude API Key Setup" help topic
- **Allergens**: See "Allergen Analysis" help topic

---

## 💡 Pro Tips

- 📸 Take photos in good lighting for best results
- 📱 Process large batches when charging
- 🌐 Use WiFi to avoid data charges
- ⏸️ Pause if you need a break
- ✏️ Edit recipes after extraction to fix any errors
- 🔍 Start small, scale up as you get comfortable

---

**Remember:** Start with a small test batch to learn the workflow, then scale up to process your entire collection!
