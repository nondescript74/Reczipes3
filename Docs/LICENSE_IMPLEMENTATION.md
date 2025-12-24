# License Agreement Implementation

## Overview

This document describes the license agreement system implemented for Reczipes2, which requires users to accept responsibility for content and images they use and share.

## Components

### 1. LicenseHelper.swift

A helper struct that manages the license acceptance state using `UserDefaults`. 

**Key Features:**
- Tracks whether the user has accepted the license
- Stores the date of acceptance
- Supports versioning (can require re-acceptance if terms change)
- Provides the full license text with specific focus on:
  - User responsibility for content and images
  - Copyright and intellectual property considerations
  - AI extraction disclaimers
  - Privacy and data handling
  - Liability limitations

**Key Properties:**
- `hasAcceptedLicense`: Boolean indicating current acceptance status
- `currentLicenseVersion`: Version number (update when terms change)
- `licenseText`: The full agreement text

### 2. LicenseAgreementView.swift

A full-screen view that presents the license agreement to users.

**User Experience Features:**
- Users must scroll to the bottom to read the entire agreement
- Scroll indicator shows when user hasn't reached the bottom
- Checkbox acknowledgment required before accepting
- Visual feedback with haptic notifications
- Cannot be dismissed without accepting or declining
- Decline option exits the app
- Accept option records acceptance and continues to app

**Technical Features:**
- Uses preference keys to detect scroll position
- Platform-specific haptic feedback (iOS)
- Smooth animations for UI state changes
- Text selection enabled for copying terms

### 3. Integration into Reczipes2App.swift

The main app struct now presents the license agreement before anything else.

**Flow:**
1. App launches
2. If license not accepted → Show License Agreement
3. After license accepted → Check if API key configured
4. If API key not configured → Show API Key Setup
5. Finally → Show main app interface

This creates a proper onboarding flow: License → API Key → App

### 4. Settings Integration

The Settings view now includes a "Legal" section where users can:
- View the license agreement at any time
- See when they accepted the license
- Review all terms post-acceptance

## License Terms Summary

The license specifically addresses:

1. **No Medical, Dietary, or Nutritional Advice** - Clear statement that app provides information only, not professional guidance
2. **User Responsibility for Content** - Users assume full responsibility for all recipes, text, and images
3. **Content Usage and IP** - Users must have rights to use and share content
4. **AI-Powered Extraction** - Disclaimers about AI accuracy in recipe extraction
5. **Allergen Detection and Food Safety** - Warnings about limitations of allergen detection
6. **Diabetic-Friendly Analysis and Nutritional Information** - Comprehensive disclaimers about:
   - Informational nature only (not medical advice)
   - AI-generated analysis limitations
   - Glycemic load and carbohydrate calculation accuracy
   - Individual metabolic response variations
   - Need for healthcare professional consultation
   - 30-day caching policy
   - Source transparency and verification responsibility
7. **Privacy and Data** - How data is handled (locally + Claude API), including diabetic analysis caching
8. **No Warranty** - App provided "as is", including nutritional analysis features
9. **Limitation of Liability** - Developer not liable for content issues, health complications, or blood sugar management issues
10. **Third-Party Content and Sources** - Disclaimers about recipe sources and medical source aggregation
11. **Acceptance** - Clear acknowledgment of all terms including health-related features

## Testing

To test the license flow:

1. First launch: License appears immediately
2. Accept: User can proceed to API key setup and then the app
3. Decline: App exits
4. Settings: View license anytime via Settings → Legal → View License Agreement

To reset for testing:
```swift
// In debug builds, you could add a developer option:
LicenseHelper.resetLicenseAcceptance()
```

## Version Management

If license terms need to be updated:

1. Update `LicenseHelper.licenseText` with new terms
2. Update `LicenseHelper.currentLicenseVersion` (e.g., "2.1" for diabetic analysis additions, "2.2" for next update)
3. Update the "Last Updated" date in the license text
4. Users will be prompted to re-accept on next launch

**Version History:**
- **v1.0** - Initial license with recipe extraction, allergen detection
- **v2.0** - Enhanced medical disclaimers and IP protections
- **v2.1** - Added diabetic-friendly analysis comprehensive disclaimers and guidelines compliance

## Platform Support

The implementation works on both iOS and macOS with platform-specific features:
- iOS: Haptic feedback on interactions
- macOS: Standard UI behaviors
- Both: Full keyboard and accessibility support
