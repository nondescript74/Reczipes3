# FODMAP Feature Integration Checklist

Use this checklist to integrate the FODMAP substitution feature into your app.

## ✅ Files Integration

### Core Files (Must Add)
- [ ] Add `FODMAPSubstitution.swift` to Xcode project
- [ ] Add `FODMAPSubstitutionView.swift` to Xcode project  
- [ ] Add `UserFODMAPSettings.swift` to Xcode project
- [ ] Add `FODMAPQuickReference.swift` to Xcode project (optional but recommended)
- [ ] Verify `RecipeDetailView.swift` was updated with FODMAP integration

### Test Files (Recommended)
- [ ] Add `FODMAPSubstitutionTests.swift` to test target
- [ ] Run tests to verify everything works
- [ ] Fix any test failures (shouldn't be any)

### Documentation (Reference)
- [ ] Review `FODMAP_FEATURE_SUMMARY.md` for overview
- [ ] Review `FODMAP_QUICKSTART.md` for quick start
- [ ] Review `FODMAP_SUBSTITUTION_GUIDE.md` for details
- [ ] Keep `FODMAP_UI_GUIDE.md` for UI reference

## ✅ App Settings Integration

### Add FODMAP Settings to Your Settings View

Find your app's settings screen and add:

```swift
Section("Dietary Preferences") {
    NavigationLink {
        FODMAPSettingsView()
    } label: {
        Label("FODMAP Settings", systemImage: "leaf.circle")
    }
}
```

Or if you have a different structure:

```swift
Button {
    // Navigate to FODMAPSettingsView
} label: {
    HStack {
        Image(systemName: "leaf.circle")
        Text("FODMAP Settings")
    }
}
```

- [x ] Added FODMAP Settings link/button to app settings
- [x ] Tested navigation to FODMAPSettingsView
- [x ] Verified toggle works and persists

## ✅ Optional Quick Reference Integration

### Add to Recipe Detail or Help Section

```swift
// In toolbar or help menu
Button {
    showingFODMAPGuide = true
} label: {
    Label("FODMAP Guide", systemImage: "book.circle")
}
.sheet(isPresented: $showingFODMAPGuide) {
    FODMAPQuickReferenceView()
}
```

- [ ] Added Quick Reference access point (optional)
- [ ] Tested Quick Reference view

## ✅ Build & Test

### Compile Check
- [ ] Project builds without errors
- [ ] No compiler warnings related to FODMAP files
- [ ] All imports resolve correctly

### Runtime Testing

#### Test Recipe 1: No High FODMAP
Create/find a recipe with only low FODMAP ingredients:
- Rice, chicken, carrots, tomatoes, lettuce

**Expected Result:**
- [ ] No FODMAP section appears
- [ ] No inline indicators on ingredients
- [ ] Recipe displays normally

#### Test Recipe 2: Some High FODMAP  
Create/find a recipe with some high FODMAP ingredients:
- Onion, garlic, rice, tomatoes

**Expected Result:**
- [ ] FODMAP section appears (when enabled)
- [ ] Shows 2 substitution cards (onion, garlic)
- [ ] Inline indicators appear (when enabled)
- [ ] Cards expand/collapse properly

#### Test Recipe 3: Many High FODMAP
Create/find a recipe with multiple high FODMAP ingredients:
- Onion, garlic, milk, honey, mushrooms, wheat flour

**Expected Result:**
- [ ] FODMAP section appears with all detected
- [ ] All ingredients have substitution cards
- [ ] Scrolling works smoothly
- [ ] Performance is good (no lag)

### Settings Testing
- [ ] Disabled: No FODMAP features appear anywhere
- [ ] Enabled, inline off: Section only, no indicators
- [ ] Enabled, inline on: Section + indicators
- [ ] Settings persist after app restart

### UI Testing
- [ ] Cards expand smoothly
- [ ] Cards collapse smoothly
- [ ] Inline buttons open detail sheets
- [ ] Detail sheets dismiss properly
- [ ] Colors look good in light mode
- [ ] Colors look good in dark mode
- [ ] Dynamic Type scaling works
- [ ] VoiceOver works (if you test accessibility)

## ✅ App Store Preparation (Optional)

If you want to highlight this feature:

### App Store Description
Add something like:
```
🍃 FODMAP-Friendly Recipe Support
For users with IBS or FODMAP sensitivities, get automatic 
ingredient substitution suggestions based on Monash University 
research. See low FODMAP alternatives for over 40 common 
high FODMAP ingredients.
```

- [ ] Updated App Store description (optional)
- [ ] Added to "What's New" section
- [ ] Mentioned in release notes

### Screenshots (Optional)
Consider showing:
- Recipe with FODMAP section visible
- Expanded substitution card
- FODMAP settings screen

- [ ] Created screenshot showing FODMAP feature (optional)

## ✅ User Documentation

### In-App Help
Consider adding to your help/FAQ:

**Q: What is the FODMAP feature?**
A: For users with IBS or FODMAP sensitivities, this feature automatically identifies high FODMAP ingredients in recipes and suggests low FODMAP alternatives based on Monash University research.

**Q: How do I enable FODMAP features?**
A: Go to Settings → FODMAP Settings and toggle "Enable FODMAP Features" ON.

**Q: What are FODMAPs?**
A: FODMAPs are types of carbohydrates that can trigger digestive symptoms. Tap the Quick Reference guide in FODMAP Settings to learn more.

- [ ] Added FAQ entries (optional)
- [ ] Updated user guide (optional)

## ✅ Medical/Legal Review (Important!)

### Disclaimer
Ensure your app includes appropriate disclaimers:

```
Medical Disclaimer: The FODMAP substitution feature provides 
general guidance based on published research. It is for 
educational and informational purposes only and is not 
medical advice. Users with digestive conditions should 
consult healthcare providers for personalized guidance.
```

- [ ] Added medical disclaimer to app
- [ ] Added to FODMAP settings screen
- [ ] Reviewed with legal/compliance (if required)
- [ ] Confirmed no medical claims made

## ✅ Performance Validation

- [ ] Recipe analysis is fast (< 10ms)
- [ ] Database lookup is fast (< 1ms)
- [ ] No memory leaks
- [ ] No excessive memory usage
- [ ] Smooth scrolling with many ingredients
- [ ] Smooth animations

## ✅ Final Quality Checks

### Code Quality
- [ ] No force unwraps that could crash
- [ ] Error handling in place
- [ ] Code follows project style guide
- [ ] Comments are clear and helpful

### User Experience
- [ ] Feature is discoverable
- [ ] Feature is easy to enable
- [ ] Feature is easy to understand
- [ ] Feature doesn't interfere when disabled

### Data Accuracy
- [ ] Spot-check 5-10 substitutions against Monash data
- [ ] Verify portion guidance is accurate
- [ ] Confirm FODMAP categories are correct

## ✅ Deployment

### Pre-Release
- [ ] Run all tests
- [ ] Test on multiple iOS versions (if applicable)
- [ ] Test on iPhone and iPad (if universal)
- [ ] Beta test with users (if you have beta program)
- [ ] Gather feedback and iterate

### Release
- [ ] Merge to main branch
- [ ] Tag release version
- [ ] Build and archive
- [ ] Submit to App Store (or deploy via TestFlight)
- [ ] Monitor for crash reports
- [ ] Monitor user feedback

## ✅ Post-Release

### Monitoring
- [ ] Check crash reports (should be none)
- [ ] Read user reviews mentioning FODMAP
- [ ] Monitor support requests
- [ ] Track usage analytics (if implemented)

### Maintenance
- [ ] Plan regular updates to FODMAP database
- [ ] Subscribe to Monash University updates
- [ ] Consider user feedback for improvements
- [ ] Add new ingredients as requested

## 🎯 Success Criteria

Your integration is successful when:

✅ Users can enable FODMAP mode in settings
✅ High FODMAP recipes show substitution section
✅ Low FODMAP recipes display normally
✅ All UI interactions work smoothly
✅ Feature is discoverable and easy to use
✅ No crashes or errors occur
✅ Performance is excellent
✅ Users with FODMAP sensitivity find it helpful

## 📞 Need Help?

If you encounter issues:

1. **Build Errors**: Check all files are added to correct targets
2. **Import Errors**: Verify all imports match your module name
3. **Runtime Errors**: Run tests to identify issues
4. **UI Issues**: Check constraints and layout code
5. **Data Issues**: Verify database entries are valid

## 🎉 Completion

When all items are checked:

- [ ] Feature is fully integrated
- [ ] All tests pass
- [ ] App is ready for release
- [ ] Documentation is complete
- [ ] Users can benefit from FODMAP support!

---

**Estimated Integration Time**: 30-60 minutes
**Complexity**: Low (all code is ready to use)
**Testing Time**: 15-30 minutes
**Total Time**: 1-2 hours max

**Good luck with your integration! 🚀**
