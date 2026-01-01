# Cooking Mode Help Guide

## Overview

Comprehensive help system for Cooking Mode, including contextual help topics, quick start guide, tips sheet, and inline help components.

## Components Created

### 1. Help Topics in ContextualHelp.swift

Eight comprehensive help topics added to the existing help system:

#### Main Topics

1. **Cooking Mode** (`cookingMode`)
   - Overview of the dual-recipe cooking interface
   - Side-by-side viewing on iPad/Mac
   - Swipeable interface on iPhone
   - Auto-save session persistence
   - Keep Awake functionality

2. **Dual Recipe View** (`dualRecipeView`)
   - How to view two recipes simultaneously
   - Layout differences between iPad and iPhone
   - Use cases for dual viewing
   - Managing recipe slots independently

3. **Keep Awake Mode** (`keepAwakeMode`)
   - Preventing screen sleep during cooking
   - Toggle location and states
   - Battery management tips
   - Automatic cleanup on exit

4. **Recipe Panel Controls** (`recipePanelControls`)
   - Swap recipe button functionality
   - Clear recipe button
   - Floating control positioning
   - Independent panel management

5. **Recipe Selection** (`recipeSelection`)
   - Opening recipe picker from empty slots
   - Swapping existing recipes
   - Search and browse functionality
   - Automatic dismissal after selection

6. **Session Persistence** (`sessionPersistence`)
   - Automatic session saving
   - Recipe and settings preservation
   - Cross-launch persistence
   - Current page tracking on iPhone

7. **Cooking Mode Layouts** (`cookingModeLayouts`)
   - iPad/Mac side-by-side layout
   - iPhone portrait and landscape
   - Adaptive layout switching
   - Control consistency across layouts

8. **Empty Recipe Slots** (`emptyRecipeSlots`)
   - Empty slot appearance and behavior
   - Selection prompt design
   - Independent slot management
   - Single vs dual recipe usage

### 2. CookingView Integration

Added help button to CookingView toolbar:

```swift
ToolbarItem(placement: .cancellationAction) {
    if viewModel != nil {
        HelpButton(topicKey: "cookingMode")
    }
}
```

- Positioned in top-left (cancellationAction)
- Opens main Cooking Mode help topic
- Provides access to all related topics via links
- Integrated with existing help system

### 3. Quick Start Guide (CookingModeQuickStart.swift)

#### CookingModeQuickStart View
- 4-page onboarding experience
- Beautiful icon-based pages
- Progressive disclosure of features
- Skip or step through pages
- "Get Started" final action

**Pages:**
1. Welcome to Cooking Mode - Overview
2. Dual Recipe View - Layout explanation
3. Keep Awake - Screen sleep prevention
4. Easy Recipe Switching - Controls overview

#### CookingModeTips View
- Compact tips sheet
- 6 essential tips with icons
- Scrollable format
- Link to full help guide
- Quick reference design

**Tips Covered:**
- Getting Started (adding recipes)
- Keep Screen On (Keep Awake)
- Device Layouts (iPad vs iPhone)
- Swap Recipes (change selections)
- Clear Slots (remove recipes)
- Auto-Save (session persistence)

#### CookingModeHelpBanner
- Inline dismissible banner
- "New to Cooking Mode?" prompt
- Quick access to tips
- Non-intrusive design
- Animation support

### 4. Supporting Components

#### CookingTipCard
- Reusable tip card component
- Icon, title, and description
- Consistent styling
- Readable layout

#### QuickStartPageView
- Full-screen page template
- Large icon display
- Centered content
- Color theming support

## Integration Points

### Accessing Help

1. **From Cooking View**
   - Tap "?" button in top-left
   - Opens main Cooking Mode help topic
   - Navigate to related topics

2. **From Settings/Help Browser**
   - Navigate to "Cooking Mode" category
   - Browse all 8 topics
   - Search functionality

3. **Quick Start (Optional Integration)**
   - Can be shown on first launch
   - Accessible via help button
   - User preference for showing/hiding

4. **Tips Sheet (Optional Integration)**
   - Can be triggered from help menu
   - Quick reference without full help
   - Good for returning users

5. **Help Banner (Optional Integration)**
   - Show on first 3 launches
   - Dismissible by user
   - Stored in UserDefaults

## Help Topic Organization

### In Help Browser

Topics appear under new "Cooking Mode" category (🔥):
- Positioned between "Main Features" and "Images"
- Contains all 8 cooking-related topics
- Icon: `flame.fill`
- Color: Orange theme

### Topic Relationships

All topics are cross-linked via `relatedTopics`:
- Cooking Mode → All other cooking topics
- Each subtopic → Cooking Mode + relevant topics
- Creates natural navigation flow

## Usage Examples

### Show Main Help
```swift
// Already integrated in CookingView toolbar
HelpButton(topicKey: "cookingMode")
```

### Show Quick Start on First Launch
```swift
@AppStorage("hasSeenCookingQuickStart") private var hasSeenQuickStart = false

.sheet(isPresented: .constant(!hasSeenQuickStart)) {
    CookingModeQuickStart()
        .onDisappear {
            hasSeenQuickStart = true
        }
}
```

### Show Tips Sheet
```swift
@State private var showingTips = false

.sheet(isPresented: $showingTips) {
    CookingModeTips()
}
```

### Show Help Banner
```swift
@AppStorage("cookingModeLaunchCount") private var launchCount = 0
@State private var showHelpBanner = false

.onAppear {
    launchCount += 1
    showHelpBanner = launchCount <= 3
}

VStack {
    CookingModeHelpBanner(isVisible: $showHelpBanner) {
        showingTips = true
    }
    
    // Rest of cooking view content
}
```

## Content Coverage

### Features Documented

✅ Dual recipe viewing
✅ Keep Awake functionality  
✅ Recipe selection/swapping
✅ Session persistence
✅ Layout adaptation (iPad/iPhone)
✅ Empty slot management
✅ Recipe panel controls
✅ Auto-save behavior

### User Journeys Covered

1. **First-time user**: Quick Start → Tips → Help Topics
2. **Returning user**: Tips Sheet → Specific help topic
3. **Confused user**: Help button → Searchable topics
4. **Feature discovery**: Related topics links

## Design Philosophy

### Progressive Disclosure
- Quick Start: 4 key concepts
- Tips Sheet: 6 essential tips
- Help Topics: Complete documentation
- Related links: Deep dive options

### Multiple Entry Points
- Toolbar help button (always available)
- Optional quick start (first launch)
- Optional tips sheet (quick reference)
- Optional banner (early launches)

### Consistency
- Uses existing ContextualHelp system
- Follows app-wide help patterns
- Matches design language
- Integrated with help browser

## Best Practices

### For Users
- Start with Quick Start if new
- Use Help button for specific questions
- Browse Help category for deep dive
- Follow related topic links

### For Developers
- Keep help topics updated with features
- Add new topics for new features
- Update related topics when adding features
- Test help flows on both iPhone and iPad

## Future Enhancements

### Potential Additions
- [ ] Video tutorials (if app adds video support)
- [ ] Interactive help overlays
- [ ] Context-sensitive tips during first use
- [ ] Gesture tutorials for swipe navigation
- [ ] Voice control documentation (if added)
- [ ] Apple Watch companion help (if watch app added)

### Analytics Opportunities
- Track which help topics are viewed most
- Identify confusing features needing better UX
- A/B test Quick Start effectiveness
- Monitor help banner dismissal rates

## Testing Checklist

- [ ] Help button appears in CookingView toolbar
- [ ] Tapping help button opens correct topic
- [ ] All 8 topics appear in Help Browser
- [ ] Cooking Mode category is properly ordered
- [ ] Related topics links work correctly
- [ ] Quick Start pages swipe smoothly
- [ ] Tips sheet scrolls and displays all content
- [ ] Help banner dismisses correctly
- [ ] Topics are searchable in Help Browser
- [ ] All icons render correctly
- [ ] Text is readable on all devices
- [ ] Dark mode support works

## Localization Notes

All user-facing strings in help content should be localized:
- Help topic titles and descriptions
- All tips and guidance text
- Quick Start page content
- Button labels ("Next", "Get Started", "Done", etc.)
- Category name "Cooking Mode"

Key localization files:
- `ContextualHelp.swift` - All topic content
- `CookingModeQuickStart.swift` - Quick Start and Tips content
- No separate strings file needed (inline text)

## Summary

A comprehensive, multi-tiered help system for Cooking Mode that:
- Provides immediate help via toolbar button
- Offers optional onboarding for new users
- Includes quick reference tips
- Documents all features thoroughly
- Integrates seamlessly with existing help infrastructure
- Scales from brief tips to detailed documentation
- Supports discovery through related topics
- Adapts to user needs (new vs experienced)

The system is fully implemented and ready to use, requiring only optional integration of Quick Start, Tips, or Banner components based on desired user experience.
