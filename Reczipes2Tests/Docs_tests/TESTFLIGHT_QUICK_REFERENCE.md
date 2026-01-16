# TestFlight Release Quick Reference Card

## Pre-Upload Checklist ✓

### 1. Run Automated Tests (5 min)
```bash
./run_testflight_tests.sh
```
**Must see**: ✅ ALL TESTS PASSED

### 2. CloudKit Dashboard (2 min)
- [ ] Visit: https://icloud.developer.apple.com/dashboard/
- [ ] Container: `iCloud.com.headydiscy.reczipes` ✓
- [ ] Production schema deployed ✓
- [ ] `SharedRecipe` type exists ✓
- [ ] `SharedRecipeBook` type exists ✓
- [ ] `OnboardingTest` type exists ✓

### 3. Physical Device Test (5 min)
- [ ] iCloud signed in ✓
- [ ] Share 1 recipe → Success ✓
- [ ] Browse shared content → Works ✓
- [ ] Export diagnostics → Readable ✓

### 4. Edge Case Test (3 min)
- [ ] Sign out of iCloud → Graceful error ✓
- [ ] Airplane mode → Feature disabled ✓
- [ ] Share button shows correct state ✓

---

## Test Suite Quick Access

| Suite | Command | Tests | Time |
|-------|---------|-------|------|
| All | `./run_testflight_tests.sh` | 135 | ~5m |
| Setup | `-only-testing:TestFlightReleaseTests` | 30 | ~1m |
| Production | `-only-testing:TestFlightProductionReadinessTests` | 35 | ~1m |
| Experience | `-only-testing:TestFlightTesterExperienceTests` | 40 | ~2m |
| Emergency | `-only-testing:TestFlightEmergencyScenarioTests` | 30 | ~1m |

---

## Success Criteria

**Ready for TestFlight when**:
- ✅ 135/135 automated tests pass
- ✅ CloudKit Production schema deployed
- ✅ Can share on physical device
- ✅ Graceful error when iCloud unavailable
- ✅ Diagnostics export works

**NOT ready when**:
- ❌ Any automated test fails
- ❌ Schema not in Production
- ❌ Sharing crashes on device
- ❌ Error messages are technical jargon
- ❌ App crashes without iCloud

---

## Emergency Commands

### All Tests Failing?
```bash
# Clean build
rm -rf DerivedData
xcodebuild clean -scheme Reczipes2

# Retry
./run_testflight_tests.sh
```

### Need Diagnostics?
```swift
// In app
let service = CloudKitOnboardingService.shared
await service.runComprehensiveDiagnostics()
let json = service.exportDiagnostics()
print(json)
```

### Validate Container?
```swift
let result = await CloudKitContainerValidator.validateContainer(
    identifier: "iCloud.com.headydiscy.reczipes"
)
await CloudKitContainerValidator.printValidationReport(result)
```

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Tests timeout | Expected! They test timeout handling. Should pass. |
| "CloudKit unavailable" | Expected in test env. Tests should PASS anyway. |
| Script permission denied | `chmod +x run_testflight_tests.sh` |
| Can't find tests | Add files to test target in Xcode |
| Schema not in Production | CloudKit Dashboard → Deploy Schema |

---

## Build Upload Steps

1. ✅ All tests pass
2. ✅ Manual checks complete
3. **Archive**: Product → Archive
4. **Upload**: Organizer → Distribute
5. **Configure**: Add build notes (see template)
6. **Invite**: Select testers
7. **Monitor**: Check feedback daily

---

## Release Notes Template

Copy this to TestFlight "What to Test":

```
🎉 Community Sharing Beta

NEW:
• Share recipes with community
• Browse shared recipes
• Share recipe books

FIRST TIME?
1. App guides you through setup
2. Sign into iCloud
3. Grant CloudKit permissions

ISSUES?
Settings → Community Sharing → Setup & Diagnostics

FEEDBACK:
Please report via TestFlight feedback!
```

---

## Support Response Templates

### "Sharing doesn't work"
```
Please try:
1. Settings → Community Sharing
2. Tap "Setup & Diagnostics"
3. Screenshot checklist
4. Send via TestFlight feedback
```

### "Need iCloud"
```
To share:
1. Settings app → [Your Name]
2. Sign in with Apple ID
3. Enable iCloud Drive
4. Return to app
5. Try again
```

### "CloudKit restricted"
```
CloudKit may be restricted:
1. Settings → Screen Time
2. Content & Privacy Restrictions
3. Check iCloud permissions
4. Ask Screen Time organizer if needed
```

---

## Metrics to Track

### Onboarding
- % completed successfully: Target >90%
- Average time to complete: Target <1 min
- % who see errors: Target <10%

### Sharing
- % successful shares: Target >85%
- Average share time: Target <5 sec
- % who retry after error: Track

### Support
- % who use diagnostics: Track
- % who can self-service: Target >95%
- % who contact support: Target <5%

---

## File Locations

```
📁 Project Root
├── 📄 TESTFLIGHT_RELEASE_CHECKLIST.md (original)
├── 📄 TESTFLIGHT_TEST_SUITE_SUMMARY.md (overview)
├── 📄 TESTFLIGHT_TESTS_README.md (full docs)
├── 📄 TESTFLIGHT_TEST_RESULTS_TEMPLATE.md (manual)
├── 📄 TESTFLIGHT_QUICK_REFERENCE.md (this!)
├── 🔧 run_testflight_tests.sh (runner)
└── 📁 Tests
    ├── TestFlightReleaseTests.swift
    ├── TestFlightProductionReadinessTests.swift
    ├── TestFlightTesterExperienceTests.swift
    └── TestFlightEmergencyScenarioTests.swift
```

---

## Day of TestFlight Upload

**Morning of upload**:
```bash
# Fresh start
git pull
rm -rf DerivedData

# Run all tests
./run_testflight_tests.sh

# If all pass:
# 1. Archive build
# 2. Upload to TestFlight
# 3. Configure build
# 4. Notify testers
# 5. Monitor feedback
```

**Evening of upload**:
- Check for crashes in TestFlight
- Review initial feedback
- Monitor diagnostics exports
- Prepare fixes for next build if needed

**Next day**:
- Respond to tester questions
- Track success metrics
- Plan iteration based on feedback

---

## Red Flags 🚩

**DO NOT UPLOAD** if you see:
- ❌ Any test failures
- ❌ App crashes on device
- ❌ Schema only in Development (not Production)
- ❌ "Bad container" errors
- ❌ Error messages say "CKError" or technical terms
- ❌ Can't export diagnostics

**PROCEED** if you see:
- ✅ All tests pass
- ✅ Sharing works on device
- ✅ Graceful errors when CloudKit unavailable
- ✅ Clear, helpful error messages
- ✅ Diagnostics export successfully

---

## Version

**Version**: 1.0  
**Date**: January 16, 2026  
**Status**: Production Ready  
**Tests**: 135 passing  

---

**Print this card and keep it handy during TestFlight releases! 📄✅**
