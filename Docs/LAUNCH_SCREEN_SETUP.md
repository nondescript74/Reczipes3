# Launch Screen Setup Guide

## Overview

Your app now includes a beautiful launch screen with a Liquid Glass effect that wipes left to right, revealing a recipe image from your asset catalog. The launch screen appears for 1.5 seconds when the app is first launched, but does not appear when returning to an already-running app.

## Features

✅ **Liquid Glass Effect**: Modern Apple design using the new `.glassEffect()` modifier  
✅ **Left-to-Right Wipe Animation**: Smooth 1.3-second wipe revealing the recipe image  
✅ **Smart Launch Detection**: Only shows on initial app launch, not when returning from background  
✅ **Tasteful Timing**: Displays for exactly 1.5 seconds total  
✅ **Fade-in Image**: Recipe image fades in gracefully as the glass wipes away  
✅ **Optional App Title**: "Reczipes" title that subtly fades as the wipe progresses  

## Setup Instructions

### 1. Add Your Recipe Image to Asset Catalog

1. Open your Xcode project
2. Navigate to your `Assets.xcassets` folder
3. Add a new image set (right-click → New Image Set)
4. Name it `launch_recipe_image` (or any name you prefer)
5. Add your recipe image to the image set
   - For best results, use a high-quality image (at least 2x resolution)
   - Recommended: Use a beautiful plated dish or handwritten recipe card

### 2. Update Image Name (if needed)

If you named your image something other than `launch_recipe_image`, update the reference in `LaunchScreenView.swift`:

```swift
Image("launch_recipe_image")  // Change this to your image name
    .resizable()
    .aspectRatio(contentMode: .fill)
```

### 3. Build and Run

That's it! The launch screen will automatically appear when you launch the app.

## Customization Options

### Change the Duration

To adjust how long the launch screen displays, modify the timing in `LaunchScreenView.swift`:

```swift
// Change the wipe animation duration (default: 1.3 seconds)
withAnimation(.easeInOut(duration: 1.3)) {  // Adjust this value
    wipeProgress = 1.0
}

// Change the total display time (default: 1.5 seconds)
DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {  // Adjust this value
    isComplete = true
    onComplete()
}
```

### Customize the Glass Tint

You can adjust the tint color and opacity of the Liquid Glass effect:

```swift
.glassEffect(.regular.tint(.white.opacity(0.2)))  // Try different colors/opacities
```

Examples:
- `.tint(.blue.opacity(0.3))` - Blue tinted glass
- `.tint(.white.opacity(0.4))` - More opaque white glass
- `.regular` - Default glass with no tint

### Modify or Remove the App Title

The "Reczipes" title is optional. To customize it:

```swift
Text("Reczipes")  // Change to your app name
    .font(.system(size: 48, weight: .bold, design: .rounded))
    .foregroundStyle(.white)
```

To remove it entirely, delete the `VStack` containing the title in `LaunchScreenView.swift`.

### Change Animation Style

Try different animation curves:

```swift
withAnimation(.easeInOut(duration: 1.3)) { }  // Smooth start and end
withAnimation(.easeOut(duration: 1.3)) { }    // Fast start, slow end
withAnimation(.spring(duration: 1.3)) { }     // Bouncy effect
withAnimation(.linear(duration: 1.3)) { }     // Constant speed
```

### Adjust Image Aspect Ratio

Change how the recipe image is displayed:

```swift
.aspectRatio(contentMode: .fill)  // Fills the screen (may crop)
.aspectRatio(contentMode: .fit)   // Fits entire image (may have letterboxing)
```

## How It Works

### Architecture

1. **App Launch**: `Reczipes2App.swift` sets `@State private var showLaunchScreen = true`
2. **Display**: A `ZStack` overlays `LaunchScreenView` on top of `MainTabView`
3. **Animation**: The glass effect wipes left to right over 1.3 seconds
4. **Completion**: After 1.5 seconds, `onComplete()` sets `showLaunchScreen = false`
5. **Background Return**: The `onChange(of: scenePhase)` modifier ensures the launch screen doesn't show when returning from background

### Key Components

- **`LaunchScreenView.swift`**: The launch screen UI and animations
- **`Reczipes2App.swift`**: Integration logic and scene phase detection
- **`@State showLaunchScreen`**: Controls launch screen visibility
- **`@Environment(\.scenePhase)`**: Detects app state changes

## Troubleshooting

### Launch Screen Not Showing

1. Verify `launch_recipe_image` exists in your asset catalog
2. Check that the image name matches in `LaunchScreenView.swift`
3. Clean build folder (Product → Clean Build Folder)
4. Rebuild the app

### Image Doesn't Look Right

- Try adjusting `aspectRatio(contentMode:)`
- Ensure your image is high resolution
- Consider cropping your image to match the screen aspect ratio

### Glass Effect Not Visible

- Make sure you're running on iOS 18 or later (Liquid Glass requires iOS 18+)
- Try increasing the tint opacity: `.tint(.white.opacity(0.5))`
- Check that the glass effect isn't being clipped by parent views

### Launch Screen Shows When Returning from Background

This shouldn't happen with the current implementation. If it does:
1. Verify the `onChange(of: scenePhase)` is working
2. Check that `showLaunchScreen` is being set to `false` properly

## Design Rationale

### Why Liquid Glass?

Liquid Glass is Apple's modern design language introduced across platforms. It provides:
- A sense of depth and layering
- Smooth, fluid interactions
- Contemporary aesthetic that feels native
- Visual feedback through material properties

### Why Left-to-Right Wipe?

- Natural reading direction for most Western languages
- Creates a sense of revelation and discovery
- Smooth transition from launch to main content
- Mimics turning a page or opening a book (fitting for recipes)

### Why 1.5 Seconds?

- Long enough to make an impression
- Short enough to not frustrate users
- Matches iOS Human Interface Guidelines for launch times
- Provides time for necessary app initialization

## Further Enhancements

Want to take it further? Here are some ideas:

1. **Add a loading indicator** if your app needs more initialization time
2. **Animate the app title** with a spring effect or fade-in
3. **Add sound effects** (subtle swoosh when glass wipes)
4. **Multiple recipe images** that randomly display on each launch
5. **Seasonal variations** (different images for different times of year)
6. **Particle effects** behind the glass as it wipes away

## References

- [Implementing Liquid Glass Design in SwiftUI](Apple Documentation)
- [SwiftUI View.glassEffect(_:in:isEnabled:)](https://developer.apple.com/documentation/SwiftUI/View/glassEffect(_:in:isEnabled:))
- [SwiftUI GlassEffectContainer](https://developer.apple.com/documentation/SwiftUI/GlassEffectContainer)
- [Human Interface Guidelines: Launch Screens](https://developer.apple.com/design/human-interface-guidelines/launching)

---

Enjoy your beautiful new launch screen! 🎉
