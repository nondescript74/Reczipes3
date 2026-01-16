# TestFlight Release Checklist for Community Sharing

## Pre-Release Checklist

Before sending a TestFlight build with community sharing:

### CloudKit Dashboard Setup

- [ ] **Logged into CloudKit Dashboard**
  - Go to: https://icloud.developer.apple.com/dashboard/
  - Container: `iCloud.com.headydiscy.reczipes`

- [ ] **Record Types Created in PRODUCTION**
  - [ ] `SharedRecipe` with all fields
  - [ ] `SharedRecipeBook` with all fields
  - [ ] `OnboardingTest` for diagnostics

- [ ] **Indexes Created** (if needed for queries)
  - [ ] `sharedDate` (descending) on both types
  - [ ] `sharedBy` on both types

- [ ] **Permissions Set Correctly**
  - [ ] World Readable: Enabled
  - [ ] Authenticated Users Can Write: Enabled

- [ ] **Schema Deployed to Production**
  - [ ] Development schema is complete
  - [ ] Deployed to Production
  - [ ] Deployment confirmed successful

### App Configuration

- [ ] **Entitlements File Verified**
  - [ ] Contains `iCloud.com.headydiscy.reczipes`
  - [ ] CloudKit capability enabled
  - [ ] iCloud Drive enabled (optional)

- [ ] **Build Configuration**
  - [ ] Archive build (not Debug)
  - [ ] Signing & Capabilities shows CloudKit
  - [ ] Container identifier correct

- [ ] **Code Integration**
  - [ ] `CloudKitOnboardingService.swift` added to target
  - [ ] `CloudKitOnboardingView.swift` added to target
  - [ ] Onboarding triggered on first launch
  - [ ] Settings includes "Setup & Diagnostics"
  - [ ] Share buttons check CloudKit status first

### Testing Before TestFlight

- [ ] **Test on Local Device (Development)**
  - [ ] Can share a recipe
  - [ ] Can share a recipe book
  - [ ] Can browse shared content
  - [ ] Onboarding shows "ready"

- [ ] **Test Archive Build Locally**
  - [ ] Create Archive build
  - [ ] Export for Development
  - [ ] Install via Xcode on device
  - [ ] Test sharing works
  - [ ] Test onboarding works

### TestFlight Upload

- [ ] **Upload Build**
  - [ ] Archive created
  - [ ] Uploaded to App Store Connect
  - [ ] Processing complete

- [ ] **Configure Build**
  - [ ] Build number incremented
  - [ ] What to Test notes added (see template below)
  - [ ] Internal testers selected

- [ ] **Release Notes Template**
```
🎉 Community Sharing Beta

NEW FEATURES:
• Share your recipes with the community
• Browse recipes shared by others
• Share entire recipe books

FIRST-TIME SETUP:
If this is your first time using community sharing:
1. The app will guide you through a quick setup
2. Make sure you're signed into iCloud
3. Grant CloudKit permissions when prompted

TROUBLESHOOTING:
If sharing doesn't work:
1. Go to Settings → Community Sharing
2. Tap "Setup & Diagnostics"
3. Follow the on-screen instructions

Known Issues:
• [List any known issues here]

Feedback:
Please report any issues with sharing via TestFlight feedback!
```

## First Tester Onboarding

### What to Tell Your First Testers

Send this message with the TestFlight invite:

```
Hi! Thanks for testing community sharing!

IMPORTANT FIRST STEPS:
1. Install the app from TestFlight
2. Launch the app
3. If you see a "Community Sharing Setup" screen, follow it
4. Go to Settings → Community Sharing to verify it says "Ready to share"

WHAT TO TEST:
1. Share one of your recipes to the community
2. Try browsing community recipes (once others have shared)
3. Import a community recipe
4. Share a recipe book

WHAT TO REPORT:
• Does sharing work on first try?
• Did you see the setup screen?
• Any error messages?
• Does it show your name on shared recipes?

TROUBLESHOOTING:
If you get errors:
1. Settings → Community Sharing → Setup & Diagnostics
2. Screenshot the checklist
3. Send via TestFlight feedback

Thanks! 🙏
```

## Common Issues to Watch For

### Issue: "Sharing fails immediately"

**Diagnosis:**
- User not signed into iCloud
- Container permissions not granted

**Fix:**
- User runs Setup & Diagnostics
- Follows prompts to sign in / grant permissions

### Issue: "Works in Development, fails in TestFlight"

**Diagnosis:**
- Schema not deployed to Production
- Record types missing in Production

**Fix:**
- Go to CloudKit Dashboard
- Deploy schema to Production
- Tell testers to reinstall app

### Issue: "Some users work, others don't"

**Diagnosis:**
- Device-specific CloudKit restrictions
- Different iCloud account states

**Fix:**
- Each user runs Setup & Diagnostics
- Identify specific issues per device
- May need different fixes per user

### Issue: "Onboarding never completes"

**Diagnosis:**
- CloudKit container not accessible
- Network issues
- Entitlements missing

**Fix:**
- Verify entitlements in archive
- Check CloudKit Dashboard permissions
- Try on different network

## Monitoring TestFlight Feedback

### Questions to Ask in Follow-Up

After first beta round:

1. **How many saw the onboarding screen?**
   - If 100%: Expected for first launch
   - If 0%: Onboarding not triggering

2. **How many completed onboarding successfully?**
   - If <80%: Onboarding flow needs improvement
   - If 100%: Great!

3. **How many can successfully share?**
   - If <90%: CloudKit setup issues
   - If 100%: Ship it!

4. **What errors are most common?**
   - Guides next round of fixes

### Analytics to Add

Consider tracking:

```swift
// Track onboarding results
logAnalytics("onboarding_state", [
    "state": onboarding.onboardingState.description,
    "timestamp": Date()
])

// Track sharing attempts
logAnalytics("share_attempted", [
    "type": "recipe", // or "book"
    "success": true/false
])

// Track common errors
logAnalytics("share_error", [
    "error": error.localizedDescription,
    "code": error.code
])
```

## Production Readiness

Before submitting to App Store:

### Required

- [ ] 90%+ of testers can share successfully
- [ ] Onboarding flow tested on 10+ devices
- [ ] All CloudKit record types in Production
- [ ] Schema deployed to Production
- [ ] No blocking bugs in sharing flow

### Recommended

- [ ] Tested on iPhone and iPad
- [ ] Tested on iOS 17 and iOS 18
- [ ] Tested with multiple iCloud accounts
- [ ] Tested with Screen Time restrictions
- [ ] Tested with poor network conditions
- [ ] Error messages are user-friendly
- [ ] Onboarding can be re-triggered if needed
- [ ] Support documentation written

### Nice to Have

- [ ] In-app help for common sharing issues
- [ ] Video tutorial for sharing
- [ ] FAQ section in app
- [ ] Community guidelines shown before first share
- [ ] Ability to report inappropriate content

## Emergency Rollback Plan

If sharing breaks in production:

### Option 1: Disable Feature Server-Side

If you implement a feature flag system:

```swift
// Check remote config
if FeatureFlags.shared.isCommunitySharingEnabled {
    // Show sharing features
} else {
    // Hide sharing features
}
```

### Option 2: Submit Emergency Update

- Remove sharing buttons from UI
- Keep data intact
- Submit expedited review
- Re-enable after fix

### Option 3: Graceful Degradation

```swift
// Show warning but don't block
if case .ready = onboarding.onboardingState {
    // Full sharing features
} else {
    // Show "Coming soon" or "Setup required"
    // Don't crash, just disable
}
```

## Post-Release Monitoring

### Week 1 After TestFlight

- [ ] Monitor crash reports for CloudKit errors
- [ ] Check TestFlight feedback daily
- [ ] Respond to tester questions
- [ ] Track onboarding completion rate
- [ ] Track successful shares vs failures

### Week 2-4

- [ ] Identify patterns in failures
- [ ] Release fixes for common issues
- [ ] Update onboarding flow if needed
- [ ] Consider adding more diagnostics

### Before App Store Submission

- [ ] All critical bugs fixed
- [ ] Onboarding flow refined
- [ ] Error messages polished
- [ ] Support documentation complete
- [ ] App Store screenshots show sharing

## Success Metrics

Define success criteria:

- ✅ **>90% onboarding completion** - Most users can get set up
- ✅ **>85% successful shares** - Once set up, sharing works reliably
- ✅ **<5% support requests** - Issues are self-service fixable
- ✅ **<1% crashes** - Sharing doesn't crash the app
- ✅ **Positive feedback** - Users like the feature

## Final Checklist Before App Store

- [ ] All TestFlight issues resolved
- [ ] Success metrics met
- [ ] App Store screenshots ready
- [ ] App Store description mentions sharing
- [ ] Privacy policy updated (if collecting shared data)
- [ ] Terms of service updated (community guidelines)
- [ ] Support email ready to handle questions
- [ ] CloudKit quota monitored (unlikely to hit limits but check)

---

## Quick Reference: CloudKit Dashboard URLs

- **Main Dashboard**: https://icloud.developer.apple.com/dashboard/
- **Container**: Select `iCloud.com.headydiscy.reczipes`
- **Schema Development**: Dashboard → Schema → Development
- **Schema Production**: Dashboard → Schema → Production
- **Deploy**: Dashboard → Schema → Deploy Schema Changes

## Quick Reference: Common Support Responses

### "Sharing doesn't work"

```
Please try this:
1. Open Reczipes app
2. Go to Settings → Community Sharing
3. Tap "Setup & Diagnostics"
4. Screenshot the checklist and send back
5. Follow any prompts shown

This will identify exactly what needs fixing.
```

### "Setup says I need iCloud"

```
To use community sharing, you need to be signed into iCloud:
1. Open Settings app (not Reczipes)
2. Tap your name at the top
3. Sign in with Apple ID
4. Enable iCloud Drive
5. Return to Reczipes
6. Run Setup & Diagnostics again
```

### "Setup says CloudKit is restricted"

```
CloudKit might be restricted by Screen Time or parental controls:
1. Open Settings → Screen Time
2. Tap Content & Privacy Restrictions
3. Make sure iCloud is allowed
4. If you don't control Screen Time, ask the organizer
5. Return to Reczipes and try again
```

---

**Good luck with your TestFlight release! 🚀**
