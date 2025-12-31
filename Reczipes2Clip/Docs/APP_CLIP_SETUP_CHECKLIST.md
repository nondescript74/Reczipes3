# App Clip Setup Checklist for Reczipes2

## Quick Start Guide

Follow these steps in order to add an App Clip to your Reczipes2 app.

---

## ✅ Step 1: Create App Clip Target

1. Open your Reczipes2 project in Xcode
2. Select your project in the Project Navigator
3. At the bottom of the targets list, click the **"+"** button
4. Scroll down and select **"App Clip"** (under iOS Application Extension)
5. Configure the App Clip:
   - **Product Name**: `Reczipes2Clip`
   - **Team**: Select your development team
   - **Bundle Identifier**: `com.headydiscy.reczipes.Clip`
   - **Language**: Swift
   - **User Interface**: SwiftUI
6. Click **"Finish"**
7. When prompted to activate scheme, click **"Activate"**

---

## ✅ Step 2: Add Files to App Clip Target

1. Locate the files you created:
   - `Reczipes2ClipApp.swift`
   - `AppClipContentView.swift`

2. For each file:
   - Select the file in Project Navigator
   - Open the File Inspector (right sidebar)
   - Under **"Target Membership"**:
     - ✅ Check `Reczipes2Clip`
     - ❌ Uncheck `Reczipes2` (main app)

3. Add `AppClipDataHandler.swift` to MAIN app only:
   - Select the file
   - Under **"Target Membership"**:
     - ✅ Check `Reczipes2` (main app)
     - ❌ Uncheck `Reczipes2Clip`

---

## ✅ Step 3: Create App Group

App Groups allow your App Clip and main app to share data.

### In Xcode:

1. Select your **main app target** (Reczipes2)
2. Go to **"Signing & Capabilities"** tab
3. Click **"+ Capability"**
4. Search for and add **"App Groups"**
5. Click **"+"** under App Groups
6. Enter: `group.com.headydiscy.reczipes`
7. Click **"OK"**

8. Now select your **App Clip target** (Reczipes2Clip)
9. Repeat steps 2-7 to add the SAME App Group

### In Apple Developer Portal:

1. Go to [developer.apple.com](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **"Identifiers"**
4. Find or create App Group: `group.com.headydiscy.reczipes`
5. Ensure both your app ID and App Clip ID are enabled for App Groups

---

## ✅ Step 4: Add Associated Domains

Associated Domains link your App Clip to your website/URLs.

### In Xcode (App Clip target):

1. Select **Reczipes2Clip** target
2. Go to **"Signing & Capabilities"**
3. Click **"+ Capability"**
4. Add **"Associated Domains"**
5. Click **"+"** under Domains
6. Add domains in this format:
   ```
   appclips:yourdomain.com
   applinks:yourdomain.com
   ```
   
   Example if you own `reczipes.app`:
   ```
   appclips:reczipes.app
   appclips:www.reczipes.app
   ```

### In Xcode (Main app target - optional but recommended):

1. Select **Reczipes2** target
2. Add same Associated Domains capability
3. Add:
   ```
   applinks:yourdomain.com
   ```

---

## ✅ Step 5: Configure Info.plist for App Clip

1. Locate the App Clip's `Info.plist` file (in Reczipes2Clip folder)
2. Add these entries:

**Option A: Using Xcode's plist editor:**
- Right-click in the plist editor
- Select **"Add Row"**
- Key: `NSAppClip` (type: Dictionary)
- Expand `NSAppClip` and add:
  - `NSAppClipRequestEphemeralUserNotification` (Boolean): `YES`
  - `NSAppClipRequestLocationConfirmation` (Boolean): `NO`

**Option B: Using Source Code editor:**
- Right-click `Info.plist`
- Choose **"Open As > Source Code"**
- Add this inside the main `<dict>`:

```xml
<key>NSAppClip</key>
<dict>
    <key>NSAppClipRequestEphemeralUserNotification</key>
    <true/>
    <key>NSAppClipRequestLocationConfirmation</key>
    <false/>
</dict>
```

---

## ✅ Step 6: Share Required Code

Some code needs to be available to both targets. Create a shared framework or link files to both targets.

### Files that should be shared:

Create a new group called "Shared" and move these files (if they exist):
- Logging utilities (if you have them)
- Recipe extraction models
- API client code
- Helper utilities

### How to share files:

**Method 1: Multi-target membership (simple)**
1. Select each shared file
2. In File Inspector, check BOTH targets under Target Membership

**Method 2: Shared Framework (better for large projects)**
1. Create new framework target: `ReczipesShared`
2. Move shared code to framework
3. Link framework to both app and App Clip targets

⚠️ **Important**: Don't share SwiftData models directly - App Clips have limited persistence.

---

## ✅ Step 7: Update App Icon for App Clip

1. In Project Navigator, find `Assets.xcassets` in the App Clip folder
2. Add an **AppClip.appiconset** with the following sizes:
   - 1024x1024 (App Store)
   - Plus standard iOS icon sizes

Tip: Your App Clip icon should be similar to your main app icon, but can have a visual indicator that it's a "lite" version.

---

## ✅ Step 8: Configure Build Settings

1. Select App Clip target
2. Go to **Build Settings**
3. Verify these settings:

**Deployment Info:**
- iOS Deployment Target: Same as main app (e.g., iOS 16.0)
- Supported Destinations: iPhone, iPad

**Linking:**
- Enable Bitcode: NO (deprecated)
- Strip Debug Symbols During Copy: YES (for Release)
- Dead Code Stripping: YES

**Size Optimization:**
- Optimization Level (Release): `-Os` (Optimize for Size)
- Strip Swift Symbols: YES
- Make Strings Read-Only: YES

---

## ✅ Step 9: Set Up Apple-App-Site-Association File

You need to host this file on your web server at:
```
https://yourdomain.com/.well-known/apple-app-site-association
```

### File contents:

Replace `TEAMID` with your actual 10-character Team ID from Apple Developer Portal:

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
        "paths": ["*"]
      },
      {
        "appID": "TEAMID.com.headydiscy.reczipes.Clip",
        "paths": ["/clip/*", "/extract/*"]
      }
    ]
  }
}
```

### Server requirements:
- MUST be served over HTTPS
- MUST be at exact path: `/.well-known/apple-app-site-association`
- Content-Type: `application/json` (recommended) or no extension
- NO redirect chains
- Accessible without authentication

### Validation:
Test your file at: https://search.developer.apple.com/appsearch-validation-tool/

---

## ✅ Step 10: Test Locally

### Method 1: Using Environment Variables

1. In Xcode, select **Reczipes2Clip** scheme
2. Click scheme name > **"Edit Scheme..."**
3. Select **"Run"** > **"Arguments"**
4. Under **"Environment Variables"**, add:
   - Name: `_XCAppClipURL`
   - Value: `https://yourdomain.com/clip/extract`
5. Click **"Close"**
6. Run the App Clip scheme (Cmd+R)

### Method 2: Local Experiences (iOS 16+)

1. On your test device:
   - Open **Settings**
   - Go to **Developer** (if visible) or **Privacy & Security**
   - Tap **"Local Experiences"**
2. In Xcode:
   - Select **Product > Register Local Experience...**
   - Enter test URL: `https://yourdomain.com/clip/extract`
   - Choose your App Clip target
3. Create QR code pointing to that URL
4. Scan QR code with Camera app on test device

---

## ✅ Step 11: Verify Size Constraints

App Clips must be < 15 MB uncompressed.

1. Build your App Clip (Release configuration)
2. Check size:
   ```bash
   # Archive the App Clip
   xcodebuild archive -scheme Reczipes2Clip -configuration Release
   
   # Or check in Xcode Organizer after archiving
   ```

3. In Xcode **Organizer**:
   - Window > Organizer
   - Select your archive
   - View **App Thinning Size Report**
   - Look for App Clip size (must be < 15 MB)

### If over 15 MB:

- Remove unused assets from Asset Catalog
- Use On-Demand Resources for optional content
- Check linked frameworks (remove unnecessary ones)
- Ensure you're building Release (not Debug)
- Consider using shared framework (doesn't count twice)

---

## ✅ Step 12: Archive and Upload to App Store Connect

1. Select **Any iOS Device** as destination
2. Select **Reczipes2** (main app) scheme
3. **Product > Archive**
4. When archive completes, Organizer opens
5. Click **"Distribute App"**
6. Choose **"App Store Connect"**
7. Follow prompts to upload

**Important**: Your App Clip is embedded in the main app bundle. You upload them together!

---

## ✅ Step 13: Configure in App Store Connect

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app (Reczipes2)
3. Go to the version in preparation
4. Scroll to **"App Clip"** section
5. Click **"+"** to add App Clip experience

### Choose Experience Type:

**Advanced Experience** (recommended for testing):
- Specific URL triggers the App Clip
- Example: `https://yourdomain.com/clip/extract`
- Good for sharing, QR codes

**Default Experience**:
- Works with any URL on your domain
- Good for general discovery

### Fill in App Clip Card:

1. **Title** (max 18 chars): `"Extract Recipe"`
2. **Subtitle** (max 43 chars): `"Save recipes instantly"`
3. **Header Image**: Upload 3000x2000 px image
4. **Call to Action**: Choose "VIEW" or "OPEN"
5. **URL**: Enter exact URL: `https://yourdomain.com/clip/extract`

---

## ✅ Step 14: Test with TestFlight

1. In App Store Connect, go to **TestFlight**
2. Add internal or external testers
3. Enable App Clip testing
4. Testers receive link like:
   ```
   https://appclip.apple.com/id?p=ABC123DEF456
   ```
5. Testers can scan QR code or tap link to test

---

## ✅ Step 15: Submit for Review

1. Complete all app metadata
2. Answer App Clip-specific questions:
   - "Where will users discover this App Clip?"
   - "What value does it provide?"
3. Submit for App Review
4. Monitor review status in App Store Connect

---

## 🧪 Troubleshooting

### App Clip won't launch:
- ✅ Verify bundle ID: `com.headydiscy.reczipes.Clip`
- ✅ Check Associated Domains capability is enabled
- ✅ Verify AASA file is accessible
- ✅ Test URL matches App Clip experience in ASC

### App Clip exceeds 15 MB:
- Remove debug symbols (Release build)
- Strip unused code
- Reduce asset catalog size
- Don't include large frameworks

### Associated domain not working:
- Verify AASA file is served over HTTPS
- No redirects to AASA file
- Team ID matches in AASA file
- Wait 24 hours for Apple's CDN to cache

### Data not shared between app and clip:
- Both targets have same App Group capability
- App Group ID matches exactly
- Both provisioning profiles include App Groups

---

## 📋 Pre-Submission Checklist

Before submitting to App Store:

- [ ] App Clip builds and runs without crashes
- [ ] Size is < 15 MB (verify in Organizer)
- [ ] Associated domains configured correctly
- [ ] AASA file is live and valid
- [ ] App Clip provides clear value in < 30 seconds
- [ ] Smooth transition to full app
- [ ] Privacy policy covers App Clip data usage
- [ ] App Clip card looks good (title, subtitle, image)
- [ ] Tested on multiple devices
- [ ] Tested all entry points (QR, link, NFC)
- [ ] Main app handles imported data correctly

---

## 🎯 Next Steps After Approval

1. **Create QR Codes**:
   - Use a QR code generator
   - Point to your App Clip experience URL
   - Add to marketing materials

2. **Physical Distribution**:
   - Print QR codes on recipe cards
   - Add to cookbook back covers
   - Place in cooking stores

3. **Digital Marketing**:
   - Share App Clip link on social media
   - Add to email newsletters
   - Include in website

4. **Monitor Usage**:
   - Check App Analytics in App Store Connect
   - Track conversion from App Clip to full app
   - Iterate based on user behavior

---

## 📚 Additional Resources

- [App Clips Documentation](https://developer.apple.com/app-clips/)
- [Associated Domains Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_associated-domains)
- [AASA Validator](https://search.developer.apple.com/appsearch-validation-tool/)
- [App Clip Size Guidelines](https://developer.apple.com/documentation/app_clips/creating_an_app_clip_with_xcode)

---

**Questions or issues?** Refer to `APP_CLIP_IMPLEMENTATION_GUIDE.md` for detailed explanations.
