# Batch Recipe Extraction - Quick Reference Card

## 🚀 Quick Start (30 seconds)

1. **Save links** (Link tab)
2. **Tap "Extract"** (bottom navigation)
3. **Tap "Batch Extract"** (purple card)
4. **Tap "Start Batch Extraction"**
5. **Wait and watch!** ☕

## 📋 Prerequisites

✅ Have saved recipe links
✅ Internet connection
✅ Valid API key configured

## 🎯 When to Use Batch Extract

### Perfect For:
- ✅ 5+ recipes to extract
- ✅ Recipes from same website
- ✅ Building recipe collection
- ✅ Meal planning prep
- ✅ Holiday recipe gathering

### Not Ideal For:
- ❌ Single recipe (use Web URL)
- ❌ Recipes needing review first
- ❌ Testing/experimenting
- ❌ Poor internet connection

## 💡 Tips & Tricks

### Pro Tips:
1. **Start small**: Test with 3-5 links first
2. **Check links**: Preview links before batch
3. **Good timing**: Run when you won't need your device
4. **Monitor first batch**: Watch first few extractions
5. **Review errors**: Check error log if failures occur

### Time Estimates:
- 5 recipes: ~2-3 minutes
- 10 recipes: ~5-6 minutes
- 25 recipes: ~12-15 minutes
- 50 recipes: ~25-30 minutes

*Note: Includes 5-second intervals between extractions*

## 🎛️ Controls

| Button | What It Does | When Available |
|--------|-------------|----------------|
| **Start** | Begin batch extraction | Before starting |
| **Pause** | Pause after current recipe | During extraction |
| **Resume** | Continue from pause | While paused |
| **Stop** | Cancel batch, keep extracted | During extraction |
| **Close** | Exit (stops if running) | Anytime |

## 📊 Understanding Progress

### Status Bar Shows:
- **Progress**: Current position (e.g., 5/12)
- **Success**: ✓ Recipes extracted successfully
- **Failed**: ✗ Recipes that had errors

### Status Messages:
- "Fetching recipe page..." → Downloading website
- "Analyzing with Claude AI..." → Extracting recipe
- "Downloading images..." → Getting recipe photos
- "Saving recipe..." → Storing in your collection
- "Waiting 5 seconds..." → Rate limiting delay

## ⚠️ Common Issues & Solutions

### "No unprocessed links"
**Problem**: All links already extracted
**Solution**: Save new links or review existing recipes

### "Extraction failed"
**Problem**: Network, URL, or parsing error
**Solution**: Check error log, retry individual link with Web URL

### "Images not downloading"
**Problem**: Image URLs invalid or network issue
**Solution**: Recipe still saved, add images manually later

### Batch seems stuck
**Problem**: May be paused or waiting between recipes
**Solution**: Check if "Paused" - resume, or wait for interval

### High failure rate
**Problem**: Website blocking, API issues, or invalid links
**Solution**: Review error log, test problematic domain individually

## 🔍 Reading the Error Log

### Error Format:
```
Recipe Title
Error description
```

### Common Errors:
- **"Network timeout"** → Internet connection issue
- **"No recipe extracted"** → Page didn't contain recipe
- **"Invalid URL"** → Link malformed or broken
- **"Rate limit exceeded"** → Too many requests (retry later)

### What to Do:
1. Note which domains fail frequently
2. Try individual extraction with Web URL
3. Verify links are actual recipe pages
4. Check if website requires login

## 📱 Best Practices

### Before Starting:
- [ ] Review saved links
- [ ] Ensure good internet
- [ ] Close other heavy apps
- [ ] Plug in device (for large batches)

### During Extraction:
- [ ] Don't force-quit app
- [ ] Keep screen on (or use guided access)
- [ ] Monitor first few extractions
- [ ] Pause if you need to use device

### After Completion:
- [ ] Review completion summary
- [ ] Check error log
- [ ] Verify recipes in collection
- [ ] Delete processed links (optional)

## 🎨 What Gets Saved

### For Each Recipe:
✅ Title and description
✅ Ingredients (all sections)
✅ Instructions (all steps)
✅ Notes and tips
✅ Yield/servings
✅ Source URL (reference)
✅ All images (if available)

### Image Priority:
1st image → Main thumbnail
2nd+ images → Additional photos

## 🔄 Retry Logic

### Automatic Retries:
- **Recipe extraction**: Up to 3 attempts
- **Image downloads**: Up to 2 attempts per image
- **Exponential backoff**: Waits longer between retries
- **Jitter**: Randomized timing to prevent clustering

### When Retries Fail:
- Recipe marked as failed
- Error logged
- Batch continues to next recipe
- You can manually retry later

## 📈 Monitoring Progress

### Real-Time Updates:
- Current recipe title
- Progress bar (visual)
- Progress counter (numeric)
- Success/failure counts
- Current step description

### Current Recipe Preview:
- Recipe title (once extracted)
- Ingredient sections count
- Instruction sections count
- Image download progress

## 🎯 Success Metrics

### Good Batch:
- 80%+ success rate
- All images downloaded
- No API errors
- Recipes properly formatted

### Review Needed:
- <80% success rate
- Many image failures
- Repeated errors from same domain
- Recipes missing key sections

## 💾 Storage

### Where Recipes Go:
- **Recipes tab** → Main collection
- **Images** → Device storage
- **Metadata** → SwiftData database

### Storage Usage:
- Recipe data: ~5-10 KB each
- Images: ~200-500 KB each
- 50 recipes ≈ 10-25 MB total

## 🔐 Privacy & Network

### What Gets Sent:
- Recipe webpage content → Claude API
- API key → Authentication

### What Stays Local:
- Saved recipes
- Downloaded images
- Extraction history
- Error logs

### Network Usage:
- Recipe page fetch: 50-500 KB
- API request: 10-100 KB
- Image downloads: Variable (100 KB - 2 MB each)

## 🎓 Learning Curve

### First Time:
1. Read this guide (5 min)
2. Save 3-5 test links (2 min)
3. Run first batch (3 min)
4. Review results (2 min)
**Total: ~12 minutes**

### Subsequent Uses:
1. Save links (ongoing)
2. Run batch (1 tap)
3. Review results (optional)
**Total: <1 minute**

## 🆘 Getting Help

### Self-Service:
1. Check this guide
2. Review error log
3. Test single extraction
4. Verify network/API

### Still Stuck:
- Check app console logs
- Try with different website
- Restart app
- Contact support with error details

## 📋 Checklist: First Batch

Use this for your first batch extraction:

- [ ] Saved 3-5 test links
- [ ] Verified links are recipe pages
- [ ] Checked internet connection
- [ ] Tapped "Batch Extract"
- [ ] Reviewed link list
- [ ] Tapped "Start Batch Extraction"
- [ ] Watched first extraction complete
- [ ] Saw success count increment
- [ ] Waited for completion
- [ ] Reviewed completion alert
- [ ] Checked recipes in collection
- [ ] Verified images downloaded
- [ ] Reviewed any errors

## 🎉 Success!

You've successfully used batch extraction when:
- ✅ Most/all recipes extracted
- ✅ Images present
- ✅ Recipes appear in collection
- ✅ Error log is empty or minimal
- ✅ Time saved vs manual extraction

## 🔮 Future Features

Coming soon:
- Background extraction
- Scheduled batches
- Domain filtering
- Priority queue
- Export error log
- Retry failed recipes
- Progress notifications

## 📚 Related Features

### Also Useful:
- **Saved Links** → Manage link collection
- **Web URL Extract** → Single recipe extraction
- **Recipe Collection** → View all recipes
- **Search** → Find saved recipes

## Quick Stats Reference

| Metric | Value |
|--------|-------|
| Max batch size | 50 recipes |
| Interval between | 5 seconds |
| Retry attempts | 3 per recipe |
| Image retries | 2 per image |
| Max image size | 500 KB |
| Typical success rate | 85-95% |

---

## 🎯 Remember

**Batch extraction is for convenience, not speed.**

The 5-second interval ensures:
- Respectful scraping
- API rate limit compliance
- Stable performance
- Higher success rate

**Quality over speed!** 🚀
