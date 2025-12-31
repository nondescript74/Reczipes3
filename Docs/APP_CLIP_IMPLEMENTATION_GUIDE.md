# App Clip Implementation Guide for Reczipes2

## Overview

This guide covers implementing an App Clip for Reczipes2 that allows users to quickly extract a recipe from an image or URL without installing the full app. The App Clip will provide a lightweight, focused experience that showcases the core value proposition of your recipe extraction feature.

## What is an App Clip?

App Clips are lightweight, discoverable app experiences that are part of your app and allow users to start using your app quickly when and where they need it. They:
- Are limited to 15 MB uncompressed
- Launch instantly from QR codes, NFC tags, Safari App Banners, Messages, and Maps
- Can be promoted in App Store Connect for distribution
- Share code with the main app but have a separate bundle identifier

## App Clip Use Case for Reczipes2

**Scenario**: User sees a recipe on a website or has a photo of a recipe card. They scan a QR code or tap an NFC tag at a restaurant/cookbook store, which launches the Reczipes2 App Clip. The App Clip:
1. Lets them extract the recipe using Claude AI
2. Shows the extracted recipe details
3. Offers to save to the full app (which triggers installation if not present)

## Implementation Steps

### Step 1: Create App Clip Target in Xcode

1. In Xcode, select your project in the navigator
2. Click the "+" button at the bottom of the targets list
3. Choose "App Clip" under iOS
4. Name it "Reczipes2Clip"
5. Ensure the following:
   - Bundle Identifier: `com.headydiscy.reczipes.Clip`
   - Deployment Target: Same as main app (iOS 16.0+)
   - Language: Swift
   - User Interface: SwiftUI

### Step 2: Configure App Clip Capabilities

1. Select the App Clip target
2. Go to "Signing & Capabilities"
3. Add the following capabilities:
   - **Associated Domains** (required for App Clip experiences)
     - Add: `appclips:yourdomain.com`
     - Example: `appclips:reczipes.app`
   - **App Groups** (to share data with main app)
     - Use same group as main app: `group.com.headydiscy.reczipes`

### Step 3: Set Up Info.plist for App Clip

The App Clip needs specific Info.plist entries:

```xml
<key>NSAppClip</key>
<dict>
    <key>NSAppClipRequestEphemeralUserNotification</key>
    <true/>
    <key>NSAppClipRequestLocationConfirmation</key>
    <false/>
</dict>
```

### Step 4: Configure Associated Domains

Create or update your `.well-known/apple-app-site-association` file on your web server:

```json
{
  "appclips": {
    "apps": ["TEAMID.com.headydiscy.reczipes.Clip"]
  },
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.headydiscy.reczipes",
        "paths": ["/recipe/*", "/extract/*"]
      },
      {
        "appID": "TEAMID.com.headydiscy.reczipes.Clip",
        "paths": ["/clip/*", "/extract/*"]
      }
    ]
  }
}
```

Replace `TEAMID` with your actual Apple Developer Team ID.

### Step 5: Size Constraints

App Clips must be under 15 MB. To achieve this:

1. **Exclude unnecessary assets**:
   - Only include essential images and icons
   - Use SF Symbols instead of custom images where possible
   - Remove tutorial/onboarding assets

2. **Minimize dependencies**:
   - App Clips already include CloudKit by default
   - Consider removing or conditionally compiling features

3. **Shared frameworks**:
   - Extract common code into a shared framework
   - Both main app and App Clip can link to it
   - This doesn't count toward the 15 MB limit twice

### Step 6: Handle App Clip Invocation

App Clips can be invoked with URLs that contain parameters. Handle this in your App Clip:

```swift
.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
    guard let url = userActivity.webpageURL else { return }
    // Parse URL and extract recipe URL or identifier
    handleAppClipURL(url)
}
```

### Step 7: App Store Connect Configuration

1. **Create App Clip Experience**:
   - Go to App Store Connect
   - Select your app
   - Navigate to "App Clips" under the "Features" section
   - Click "+" to create a new App Clip experience
   - Choose "Advanced App Clip Experience"

2. **Configure App Clip Card**:
   - **Title**: "Extract Recipe" (up to 18 characters)
   - **Subtitle**: "Save recipes instantly" (up to 43 characters)
   - **Header Image**: 3000 x 2000 px image showcasing the feature
   - **URL**: The URL that triggers your App Clip
     - Example: `https://reczipes.app/clip/extract`

3. **Set Up App Clip Experience**:
   - **Default Experience**: Can be triggered from any URL matching your domain
   - **Advanced Experience**: Triggered from specific URLs
   - **Business Experience**: Tied to a physical location (Maps, Place Cards)

### Step 8: Testing App Clips

**Local Testing:**

1. **Environment Variable Method**:
   - Edit scheme for App Clip target
   - Add environment variable: `_XCAppClipURL` with your test URL
   - Example: `https://yourdomain.com/clip/extract?url=https://example.com/recipe`

2. **Local Experience URL Method**:
   - In Xcode, select "Register Local Experience"
   - Settings > Developer > Local Experiences
   - Create a test URL that launches your App Clip

**TestFlight Testing:**
- Upload build to App Store Connect
- Enable App Clip in TestFlight
- Share App Clip test link with testers
- Format: `https://appclip.apple.com/id?p=your-test-code`

### Step 9: Shared Code Architecture

Create a shared framework for code reuse:

1. Create a new "Framework" target named "ReczipesShared"
2. Move shared code to this framework:
   - Recipe model
   - API key helpers
   - Claude AI service
   - Recipe extraction logic
   - Image handling utilities

3. Link the framework to both:
   - Main app target
   - App Clip target

## Key Differences: App Clip vs Main App

### What App Clips CAN do:
- ✅ Use SwiftData (with limitations)
- ✅ Access Keychain (with App Group sharing)
- ✅ Request limited permissions (camera, photos - single use)
- ✅ Make network requests
- ✅ Store data temporarily (deleted after period of inactivity)
- ✅ Prompt for full app installation

### What App Clips CANNOT do:
- ❌ Use CloudKit sync (data is local only)
- ❌ Access main app's persistent data directly (use App Groups)
- ❌ Run in background (no background modes)
- ❌ Request push notification permissions
- ❌ Use HealthKit or other restricted APIs
- ❌ Be larger than 15 MB

## Implementation Files

### File 1: `Reczipes2ClipApp.swift`

See the separate file created in this project.

### File 2: `AppClipContentView.swift`

See the separate file created in this project.

### File 3: `SharedRecipeExtractor.swift` (in shared framework)

See the separate file created in this project.

## Data Sharing Between App Clip and Main App

Use App Groups to share data:

```swift
// In both App Clip and Main App
let sharedDefaults = UserDefaults(suiteName: "group.com.headydiscy.reczipes")

// Save extracted recipe
let encoder = JSONEncoder()
if let encoded = try? encoder.encode(recipe) {
    sharedDefaults?.set(encoded, forKey: "pendingRecipe")
}

// In main app, check for pending recipe
if let data = sharedDefaults?.data(forKey: "pendingRecipe"),
   let recipe = try? JSONDecoder().decode(Recipe.self, from: data) {
    // Add recipe to SwiftData
    modelContext.insert(recipe)
    sharedDefaults?.removeObject(forKey: "pendingRecipe")
}
```

## Marketing and Distribution

### QR Code Generation
Generate QR codes that point to your App Clip experience URL:
- `https://yourdomain.com/clip/extract`
- Add query parameters for specific recipes or sources

### Physical Distribution
Print QR codes or use NFC tags in:
- Cookbooks (on back cover or inside page)
- Recipe cards
- Restaurant menus
- Cooking equipment packaging
- Cooking class materials

### Digital Distribution
App Clips can be triggered from:
- Safari App Banners
- Messages (when sharing URL)
- Maps Place Cards
- QR codes in social media
- Email campaigns

## App Store Review Considerations

1. **Functionality**: App Clip must provide clear, immediate value
2. **Size**: Must be under 15 MB uncompressed
3. **No Paywalls**: Can't require payment before using
4. **API Key Handling**: For your use case, consider:
   - Providing a limited demo API key
   - Allowing users to enter their own key
   - Limiting extractions in App Clip (prompt for full app)

## Next Steps

1. ✅ Create App Clip target in Xcode
2. ✅ Implement basic App Clip UI (see provided files)
3. ✅ Extract shared code into framework
4. ✅ Test locally using local experiences
5. ✅ Configure associated domains
6. ✅ Set up App Groups for data sharing
7. ✅ Build and verify size < 15 MB
8. ✅ Test with TestFlight
9. ✅ Create App Clip experience in App Store Connect
10. ✅ Submit for review

## Troubleshooting

### App Clip Won't Launch
- Verify bundle identifier matches App Clip experience in ASC
- Check associated domains configuration
- Ensure AASA file is properly formatted and accessible
- Test URL format matches registered experience

### Size Exceeds 15 MB
- Remove unused assets from Asset Catalog
- Use shared framework for common code
- Remove debug symbols (Release build)
- Strip unused Swift libraries

### Data Not Shared with Main App
- Verify App Group is enabled on both targets
- Check App Group identifier matches exactly
- Ensure both targets are signed with same team

## Resources

- [Apple App Clips Documentation](https://developer.apple.com/app-clips/)
- [App Clip Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-clips)
- [Testing App Clips](https://developer.apple.com/documentation/app_clips/testing_your_app_clip_s_launch_experience)
- [App Store Connect Help - App Clips](https://help.apple.com/app-store-connect/#/dev49e3e4d63)

---

**Note**: This implementation focuses on a single-feature App Clip (recipe extraction). The modular architecture allows you to create multiple App Clip experiences in the future if needed.
