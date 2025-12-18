# Reczipes2 - Complete User Guide

> **Your AI-Powered Recipe Collection & Dietary Management App**

Transform recipe cards into digital recipes, manage food allergies, and organize your complete recipe collection—all in one intelligent app.

---

## 📱 Table of Contents

1. [Getting Started](#getting-started)
2. [Main Features](#main-features)
3. [Recipe Extraction](#recipe-extraction)
4. [Allergen & Dietary Management](#allergen--dietary-management)
5. [Recipe Management](#recipe-management)
6. [Advanced Features](#advanced-features)
7. [Settings & Configuration](#settings--configuration)
8. [Tips & Best Practices](#tips--best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Getting Started

### First Launch

When you first open Reczipes2:

1. **Welcome Screen** displays with app logo and animation
2. **License Agreement** - Review and accept to continue
3. **API Key Setup** - Configure your Claude API key for recipe extraction

### What You'll Need

- **iOS Device** running iOS 17.0 or later
- **Claude API Key** (optional, but required for recipe extraction)
  - Get one at [console.anthropic.com](https://console.anthropic.com)
  - Costs approximately $0.02 per recipe extraction
  - Stored securely in iOS Keychain

---

## Main Features

### 🍳 The Three Main Tabs

#### 1. **Recipes** (📚)
Your personal recipe collection

**What you can do:**
- Browse all your saved recipes
- View recipe thumbnails (if images assigned)
- Filter by allergen safety
- Sort by dietary compatibility
- Quick delete with swipe gestures
- See recipe count at a glance

**Quick Tips:**
- Tap any recipe to view full details
- Swipe left to delete
- Use allergen filter bar at top for dietary filtering
- Green checkmarks = safe recipes for your dietary needs

#### 2. **Extract** (📸)
AI-powered recipe extraction from photos

**What you can do:**
- Take photos of recipe cards with your camera
- Select existing photos from your library
- Enhance old/faded recipe cards with preprocessing
- Extract structured recipe data automatically
- Preview extracted recipes before saving
- Images are automatically saved with recipes

**Quick Tips:**
- Enable preprocessing for old recipe cards
- Compare before/after preprocessing
- Extraction takes 15-30 seconds
- Review and edit before saving

#### 3. **Settings** (⚙️)
Configure app preferences

**What you can do:**
- Manage your Claude API key
- Toggle auto-extract on image selection
- Set default preprocessing preferences
- View license agreement
- Check app version and API status

---

## Recipe Extraction

### 📸 How to Extract a Recipe

#### Step 1: Select Your Image
```
Tap "Take Photo" → Camera opens → Capture recipe
   OR
Tap "Choose from Library" → Select existing photo
```

#### Step 2: Enhance (Optional)
- Toggle "Use Image Preprocessing" for:
  - Old, faded recipe cards
  - Low-contrast handwritten recipes
  - Yellowed or aged paper
- Tap "Compare Original vs Processed" to see the difference
- Preprocessing converts to grayscale and enhances contrast

#### Step 3: Extract
- Tap "Extract Recipe" button
- Claude AI processes your image (15-30 seconds)
- Structured recipe data appears

#### Step 4: Review & Save
- Review extracted information:
  - Recipe title
  - Ingredients (with quantities and units)
  - Step-by-step instructions
  - Notes and tips
  - Yield and serving information
  - Source reference
- Edit if needed
- Tap "Save Recipe" to add to collection

### What Gets Extracted

**Comprehensive Data:**
- ✅ Recipe title
- ✅ Yield/servings
- ✅ Multiple ingredient sections (e.g., "For the dough", "For the filling")
- ✅ Ingredients with quantities, units, and preparation notes
- ✅ Multiple instruction sections with numbered steps
- ✅ Recipe notes, tips, and warnings
- ✅ Cooking times and temperatures
- ✅ Source and page references
- ✅ The original photo (automatically assigned)

### Image Preprocessing Explained

**When to Use:**
- ✅ Old, faded recipe cards
- ✅ Handwritten recipes
- ✅ Low-contrast or yellowed paper
- ✅ Stained or marked recipe cards

**When to Skip:**
- ❌ Already clear, high-quality photos
- ❌ Colorful modern cookbook pages
- ❌ Digital recipe screenshots

**What It Does:**
1. Converts to grayscale (removes color noise)
2. Boosts contrast by 50% (makes text pop)
3. Sharpens text for clearer character recognition
4. Reduces noise and artifacts

### Extraction Tips

1. **Lighting**: Use good, even lighting when photographing
2. **Angle**: Hold camera parallel to recipe card (avoid shadows)
3. **Focus**: Ensure text is in focus before capturing
4. **Cropping**: Include entire recipe in frame
5. **Background**: Use a contrasting background (white paper on dark surface)
6. **Try Both**: Test with and without preprocessing to see which works better

### Cost Information

**Claude API Pricing:**
- ~$0.02 per recipe extraction
- Extract 100 recipes for ~$2
- Based on Claude Sonnet 4 pricing
- Input: ~2,000 tokens ($0.006)
- Output: ~1,000 tokens ($0.015)

---

## Allergen & Dietary Management

### 🛡️ Allergen Profiles

Create profiles to track your food allergies, sensitivities, and dietary restrictions.

#### Creating a Profile

1. **Access Profiles:**
   - Tap allergen filter bar in Recipes tab
   - OR tap your profile name to manage
   - OR go to Settings → Allergen Profiles (if added)

2. **Create New Profile:**
   - Tap "+" button
   - Enter profile name (e.g., "My Allergies", "Child", "Guest")
   - Tap "Create"

3. **Add Sensitivities:**
   - Tap "Add Sensitivity"
   - Choose from two tabs:
     - **Big 9 Allergens** (FDA-regulated)
     - **Intolerances** (common dietary restrictions)
   - Select allergen/intolerance
   - Set severity level
   - Add optional notes
   - Tap "Add"

4. **Activate Profile:**
   - Toggle "Active Profile" ON
   - Only one profile can be active at a time
   - Activating enables automatic recipe analysis

### Supported Allergens & Intolerances

#### Big 9 Allergens (FDA)
| Allergen | Icon | Common Sources |
|----------|------|----------------|
| Milk | 🥛 | Butter, cream, cheese, yogurt, whey, casein |
| Eggs | 🥚 | Egg whites, egg yolks, mayonnaise, meringue |
| Peanuts | 🥜 | Peanut butter, peanut oil, groundnuts |
| Tree Nuts | 🌰 | Almonds, cashews, walnuts, pecans, pistachios |
| Wheat | 🌾 | Flour, bread, pasta, couscous, baked goods |
| Soy | 🫘 | Tofu, soy sauce, miso, tempeh, edamame |
| Fish | 🐟 | Salmon, tuna, anchovy, fish sauce |
| Shellfish | 🦐 | Shrimp, crab, lobster, clams, mussels |
| Sesame | 🫘 | Sesame seeds, tahini, sesame oil |

#### Common Intolerances
| Intolerance | Icon | Common Sources |
|-------------|------|----------------|
| Gluten | 🌾 | Wheat, barley, rye, malt, beer |
| Lactose | 🥛 | Milk, cream, ice cream, soft cheeses |
| Caffeine | ☕️ | Coffee, tea, chocolate, energy drinks |
| Histamine | 🍷 | Aged cheese, wine, fermented foods |
| Salicylates | 🫐 | Berries, apples, tomatoes, spices |
| Sulfites | 🍇 | Wine, dried fruit, pickled foods |
| FODMAPs | 🧅 | Onions, garlic, wheat, beans (see FODMAP section) |

### Severity Levels

**Mild (⚠️)**
- Minor reactions or discomfort
- Score multiplier: ×1
- Example: Slight bloating from lactose

**Moderate (⚠️⚠️)**
- Noticeable symptoms requiring attention
- Score multiplier: ×2
- Example: Digestive upset from gluten

**Severe (🚫)**
- Serious reactions requiring complete avoidance
- Score multiplier: ×5
- Example: Anaphylaxis from peanuts

### 🔍 Allergen Analysis

Automatic recipe analysis based on your active profile.

#### How Analysis Works

1. **Keyword Detection**: Scans all ingredient names and preparations
2. **Hidden Allergen Detection**: Identifies allergens in compound ingredients
3. **Severity Weighting**: Calculates risk score based on severity levels
4. **Safety Assessment**: Assigns overall risk level

#### Risk Levels & Badges

| Badge | Risk Level | Score | Meaning |
|-------|------------|-------|---------|
| ✅ | Safe | 0 | No detected allergens |
| ⚠️ | Low Risk | < 5 | Minor allergens detected |
| ⚠️⚠️ | Medium Risk | 5-10 | Moderate concern |
| 🚫 | High Risk | > 10 | Severe allergens detected |

#### Viewing Analysis Results

**In Recipe List:**
- Badges appear next to recipe names
- Recipes sorted by safety score (safest first)
- Green checkmarks for completely safe recipes

**In Recipe Detail:**
- "Allergen Analysis" section
- Overall safety badge
- "View Detailed Analysis" button

**Detailed Analysis Sheet:**
- Overall score with circular gauge
- List of detected allergens
- Ingredients containing each allergen
- Matched keywords that triggered detection
- Recommendation text based on risk level

#### Filtering by Allergen Safety

**Filter Bar Controls:**
1. **Profile Button**: Tap to manage profiles
2. **Filter Toggle**: Enable/disable allergen-based filtering
3. **Safe Only Button**: Show only recipes with no detected allergens

**Filter Modes:**
- **Filter OFF**: Shows all recipes, no sorting
- **Filter ON**: Recipes sorted by safety score
- **Safe Only ON**: Shows only recipes with zero detected allergens

### 🧅 FODMAP Analysis

Specialized analysis for Low FODMAP diets based on Monash University research.

#### What are FODMAPs?

**FODMAP** = Fermentable Oligosaccharides, Disaccharides, Monosaccharides, And Polyols

Short-chain carbohydrates that can trigger digestive symptoms in sensitive individuals (IBS).

#### The Four FODMAP Categories

**1. Oligosaccharides (Fructans & GOS)**
- 🧅 **High FODMAP**: Wheat, rye, onions, garlic, beans, lentils, chickpeas
- ✅ **Low FODMAP**: Rice, quinoa, oats, green onion tops only

**2. Disaccharides (Lactose)**
- 🥛 **High FODMAP**: Milk, cream, yogurt, soft cheeses, ice cream
- ✅ **Low FODMAP**: Hard cheeses, lactose-free milk, butter

**3. Monosaccharides (Excess Fructose)**
- 🍯 **High FODMAP**: Honey, agave, apples, pears, mangoes
- ✅ **Low FODMAP**: Bananas, blueberries, strawberries, maple syrup

**4. Polyols (Sugar Alcohols)**
- 🍎 **High FODMAP**: Sorbitol, mannitol, apples, stone fruits, mushrooms
- ✅ **Low FODMAP**: Most vegetables without polyols

#### Using FODMAP Analysis

1. **Enable in Profile:**
   - Add "FODMAPs" to your allergen profile
   - Set severity level (usually Moderate or Severe)

2. **Automatic Detection:**
   - System checks 150+ FODMAP keywords
   - Organized by category
   - Detects high FODMAP ingredients

3. **View Analysis:**
   - Category-by-category breakdown
   - Detected high FODMAP foods
   - Low FODMAP alternatives
   - Modification suggestions

#### FODMAP-Specific Features

**Portion Size Guidance:**
- Many foods are low FODMAP in small amounts
- Analysis notes when portion size matters
- Serving size recommendations from Monash

**Common Substitutions:**
- Garlic → Garlic-infused oil (strain solids)
- Onions → Green tops of spring onions only
- Wheat → Gluten-free alternatives
- Milk → Lactose-free milk
- Honey → Maple syrup or glucose

**Important FODMAP Notes:**
- Green parts of onions = LOW FODMAP ✅
- White parts of onions = HIGH FODMAP ❌
- Garlic-infused oil (strained) = LOW FODMAP ✅
- Garlic solids = HIGH FODMAP ❌
- Hard cheeses = LOW FODMAP ✅
- Soft cheeses = HIGH FODMAP ❌

#### Enhanced FODMAP Analysis with Claude

For more accurate detection:
- Identifies hidden FODMAPs
- Provides Monash University references
- Suggests specific recipe modifications
- Notes portion-dependent FODMAPs

---

## Recipe Management

### 📖 Viewing Recipe Details

**Recipe Detail View includes:**
- Recipe image (if assigned)
- Title and header notes
- Yield/servings
- Ingredient sections with quantities
- Instruction sections with numbered steps
- Recipe notes (tips, warnings, timing)
- Source and page reference
- Allergen analysis (if profile active)

**Action Buttons:**
- **Save**: Add to collection (for extracted recipes)
- **Edit**: Modify recipe (for saved recipes)
- **Share**: Export recipe via share sheet
- **Export to Reminders**: Create shopping list
- **Print**: Print recipe

### ✏️ Editing Recipes

All saved recipes can be edited, regardless of how they were created.

#### Opening the Editor

1. Open recipe in detail view
2. Tap "Edit" button (pencil icon) in toolbar
3. Recipe editor opens in modal sheet

#### What You Can Edit

**Basic Information:**
- Recipe title (required)
- Header notes/description
- Yield/servings
- Source and page reference

**Ingredient Sections:**
- Add new sections
- Rename section titles
- Reorder sections
- Delete sections
- Add/remove/edit individual ingredients
- Ingredient details: quantity, unit, name, preparation

**Instruction Sections:**
- Add new sections
- Rename section titles
- Reorder sections
- Delete sections
- Add/remove/edit individual steps
- Step details: number, instruction text

**Recipe Notes:**
- Add/remove notes
- Set note types: General, Tip, Warning, Timing
- Edit note text

#### Editing Controls

**Adding Items:**
- Tap "+ Add [Item]" buttons at bottom of sections
- Fill in fields
- Fields auto-save when you move to next field

**Deleting Items:**
- Swipe left on item → Tap "Delete"
- OR: Tap "Edit" in section header → Tap red minus icon

**Reordering Items:**
- Tap "Edit" in section header
- Drag items using handle (≡) icon
- Tap "Done" when finished

**Saving Changes:**
- Tap "Save" in toolbar
- Changes persist immediately
- Recipe detail view updates automatically

**Canceling:**
- Tap "Cancel" in toolbar
- If changes made: Warning dialog appears
- Choose "Discard Changes" or "Keep Editing"
- If no changes: Dismisses immediately

### 🖼️ Managing Recipe Images

#### Automatic Image Assignment

When you extract a recipe from a photo:
- Source image is automatically saved
- Compressed as JPEG (80% quality)
- Stored in app's Documents folder
- Automatically assigned to recipe
- Filename pattern: `recipe_{UUID}.jpg`

#### Manual Image Management

**Access Image Manager:**
1. From Recipes tab toolbar: Tap "Assign Images" button
2. Browse all recipes

**Image Status Indicators:**
- ✅ Green checkmark = Image already assigned
- Gray icon = No image assigned

**Changing Images:**
1. Tap pencil icon next to recipe
2. Select new photo from library
3. Image updates everywhere immediately
4. Old image file is automatically deleted

**Where Images Appear:**
- Recipe list thumbnails (50×50 points)
- Recipe detail header (full width)
- Search results
- Share previews

### 📋 Exporting to Reminders

Create shopping lists from recipe ingredients.

#### How to Export

1. Open recipe in detail view
2. Tap "Export to Reminders" button
3. Grant Reminders access (first time only)
4. Ingredients are exported as checklist

**What Gets Exported:**
- Recipe title as list name
- All ingredients as reminder items
- Organized by ingredient sections
- Each item is checkable

**Using the List:**
- Open Reminders app
- Find list by recipe name
- Check off items while shopping
- Edit list as needed

---

## Advanced Features

### 🔐 API Key Management

**Setting Up Your API Key:**

1. **Get an API Key:**
   - Visit [console.anthropic.com](https://console.anthropic.com)
   - Create Anthropic account
   - Generate API key (starts with `sk-ant-api03-`)
   - Add credits to account

2. **Configure in App:**
   - Open Settings tab
   - Tap "Manage API Key"
   - Tap "Set API Key"
   - Paste your key
   - Tap "Save"

3. **Verify:**
   - Green checkmark = Configured ✅
   - Red X = Not set ❌

**Security:**
- Stored in iOS Keychain (encrypted)
- Never stored in plain text
- Not visible after saving
- Can be changed or removed anytime

**API Key Options:**
- **View**: See masked version of key
- **Edit**: Update to new key
- **Remove**: Delete key from keychain
- **Test**: Verify key works

### 💾 Data Storage & Privacy

**Where Data is Stored:**
- **Recipes**: SwiftData (local SQLite database)
- **Images**: Documents folder (JPEG files)
- **Image Assignments**: SwiftData
- **Allergen Profiles**: SwiftData
- **API Key**: iOS Keychain (encrypted)
- **Settings**: UserDefaults

**Privacy Guarantees:**
- ✅ All data stored locally on device
- ✅ No cloud sync (unless you add it)
- ✅ No data collection or analytics
- ✅ No personally identifiable information transmitted
- ✅ API key never leaves device except for Claude requests
- ✅ Recipe images never uploaded except during extraction

**Data Management:**
- Delete individual recipes anytime
- Clear all data by deleting app
- Export recipes (feature can be added)
- No automatic backups (use iOS device backup)

### 🎯 Recipe Organization

**Current Organization Features:**
- Chronological order (newest first)
- Allergen-based filtering
- Search by recipe name (can be enhanced)
- Visual identification via thumbnails

**Potential Enhancements:**
- Collections/folders
- Tags and categories
- Favorites/starred recipes
- Custom sorting options
- Advanced search filters

---

## Settings & Configuration

### ⚙️ Settings Tab Overview

**Recipe Extraction Section:**
- API Key Status indicator
- Manage API Key button
- Auto-Extract toggle (start extraction immediately after image selection)
- Image Preprocessing toggle (enable by default)

**Legal Section:**
- View License Agreement
- License acceptance date

**About Section:**
- App version
- Powered by Claude AI link

### Configuration Options

**Auto-Extract on Image Selection:**
- ON: Extraction starts immediately after choosing image
- OFF: Must tap "Extract Recipe" button manually

**Enable Image Preprocessing:**
- ON: Preprocessing enabled by default
- OFF: Preprocessing disabled by default
- Can still toggle per extraction

---

## Tips & Best Practices

### 📸 Photography Tips

**For Best Extraction Results:**

1. **Lighting**
   - Use bright, even lighting
   - Avoid shadows across text
   - Natural daylight works best
   - Avoid harsh overhead lights

2. **Camera Angle**
   - Hold camera parallel to recipe card
   - Avoid perspective distortion
   - Keep all text visible

3. **Focus**
   - Ensure text is sharp and in focus
   - Tap screen to focus on text
   - Use steady hands or surface

4. **Background**
   - Use contrasting background
   - White paper on dark table works well
   - Reduce clutter around recipe

5. **Framing**
   - Include entire recipe in frame
   - Leave small margin around edges
   - Don't crop off any text

### 🛡️ Allergen Management Tips

**Setting Up Profiles:**

1. **Be Complete**: Add all your sensitivities, even mild ones
2. **Be Accurate**: Set severity levels correctly (affects scoring)
3. **Add Notes**: Document reaction types for medical reference
4. **Multiple Profiles**: Create profiles for different scenarios
   - Personal
   - Family (combined allergens)
   - Guests
   - Elimination diet testing

**Using Analysis:**

1. **Review Details**: Always check detailed analysis for important recipes
2. **Trust But Verify**: System is helpful but not infallible
3. **Read Labels**: Always verify actual ingredient labels
4. **Consult Professionals**: Work with allergist or dietitian
5. **Update Keywords**: If detection misses something, note for improvement

**FODMAP-Specific:**

1. **Follow Monash**: Use official Monash FODMAP app alongside
2. **Portion Awareness**: Many foods are safe in small amounts
3. **Reintroduction Phase**: Track which FODMAPs you react to
4. **Work with Dietitian**: Low FODMAP is complex, get professional help

### 📝 Recipe Organization Tips

**Naming Conventions:**
- Use descriptive titles
- Include key ingredients
- Note special characteristics

**Adding Notes:**
- Document modifications you make
- Note family preferences
- Add timing tips
- Record source information

**Image Best Practices:**
- Assign images for visual identification
- Take photos of finished dishes
- Use consistent image quality
- Update images if recipe changes

---

## Troubleshooting

### Common Issues & Solutions

#### Recipe Extraction Problems

**"No recipe could be extracted"**
- ✅ Enable image preprocessing
- ✅ Ensure text is legible in photo
- ✅ Try better lighting and focus
- ✅ Retake photo with less glare
- ✅ Make sure entire recipe is in frame

**"API Error (401 Unauthorized)"**
- ✅ Check API key is correct
- ✅ Verify key starts with `sk-ant-api03-`
- ✅ Confirm key is properly saved in Settings
- ✅ Check account has credits at console.anthropic.com

**"API Error (429 Rate Limit)"**
- ✅ Wait a moment before retrying
- ✅ You've hit rate limit
- ✅ Try again in a few minutes

**Extraction is very slow**
- ✅ Normal processing time is 15-30 seconds
- ✅ Check internet connection
- ✅ Large or complex recipes take longer
- ✅ Wait at least 60 seconds before canceling

**Preprocessing makes image worse**
- ✅ Disable preprocessing for this image
- ✅ Works best for old/faded cards
- ✅ Not helpful for already-clear photos

#### Allergen Detection Issues

**No allergen badges showing**
- ✅ Create an allergen profile
- ✅ Add sensitivities to profile
- ✅ Toggle "Active Profile" ON
- ✅ Enable filtering in recipe list
- ✅ Ensure you have saved recipes

**Allergens not being detected**
- ✅ Check ingredient names match keywords
- ✅ System may not know regional ingredient names
- ✅ Consider using Claude AI for enhanced detection
- ✅ Note missing keywords for future improvement

**Too many false positives**
- ✅ Review keyword lists
- ✅ Adjust severity levels
- ✅ Use detailed analysis to verify matches
- ✅ Some ingredients may legitimately contain allergens

**Profile changes not reflected**
- ✅ Toggle filter off and on again
- ✅ Pull to refresh recipe list
- ✅ Close and reopen app
- ✅ Verify profile is marked as active

#### Image Issues

**Images not appearing**
- ✅ Check image was assigned in Recipe Images manager
- ✅ Look for green checkmark next to recipe
- ✅ Verify image file exists in Documents folder
- ✅ Try reassigning image

**Image quality is poor**
- ✅ Images are compressed to 80% quality
- ✅ Take higher quality original photos
- ✅ Compression balances quality and storage

**Can't change image**
- ✅ Ensure recipe is saved (not just extracted)
- ✅ Grant photo library access permission
- ✅ Select valid image file

#### General App Issues

**App is slow**
- ✅ Normal for large recipe collections
- ✅ Consider breaking into multiple collections (future feature)
- ✅ Close and reopen app
- ✅ Restart device

**Changes not saving**
- ✅ Ensure you tap "Save" button
- ✅ Don't force-close app during save
- ✅ Check device has available storage
- ✅ Try again - SwiftData handles retries

**Lost data after update**
- ✅ Data should persist across updates
- ✅ Check if iCloud backup restored older data
- ✅ Ensure app wasn't deleted (deletes all data)

#### Permission Issues

**Can't access camera**
- ✅ Go to Settings → Privacy → Camera
- ✅ Enable permission for Reczipes2
- ✅ Restart app

**Can't access photo library**
- ✅ Go to Settings → Privacy → Photos
- ✅ Enable "All Photos" access
- ✅ Restart app

**Can't access Reminders**
- ✅ Go to Settings → Privacy → Reminders
- ✅ Enable permission for Reczipes2
- ✅ Restart app

---

## Appendix

### Keyboard Shortcuts (macOS/iPad)

**Navigation:**
- `⌘+1` - Recipes tab
- `⌘+2` - Extract tab
- `⌘+3` - Settings tab

**Recipe Actions:**
- `⌘+N` - New recipe extraction
- `⌘+E` - Edit selected recipe
- `⌘+S` - Save recipe (in editor)
- `⌘+W` - Close editor/detail view
- `Delete` - Delete selected recipe

**Other:**
- `⌘+F` - Search (when implemented)
- `⌘+,` - Settings
- `⌘+?` - Help (when implemented)

### Accessibility Features

**VoiceOver Support:**
- All UI elements properly labeled
- Recipe content readable
- Buttons have descriptive labels

**Dynamic Type:**
- Text scales with system font size
- Supports all Dynamic Type sizes

**Color Contrast:**
- System colors used throughout
- High contrast mode support
- Color-blind friendly indicators

**Other:**
- Supports Dark Mode
- Keyboard navigation
- Reduce Motion support

### File Formats

**Recipe Data:**
- Stored as JSON in SwiftData
- Standard Swift Codable format
- Can be exported (feature to add)

**Images:**
- Format: JPEG
- Quality: 80%
- Naming: `recipe_{UUID}.jpg`
- Location: Documents directory

### System Requirements

**Minimum:**
- iOS 17.0 or later
- 100 MB available storage
- Internet connection (for extraction)

**Recommended:**
- iOS 17.1 or later
- 500 MB available storage
- WiFi connection for extraction
- Recent iPhone/iPad model

### Credits & Acknowledgments

**Built With:**
- SwiftUI (Apple)
- SwiftData (Apple)
- Claude Sonnet 4 (Anthropic)
- Core Image (Apple)

**Research Sources:**
- FDA Allergen Guidelines
- Monash University FODMAP Research
- Anthropic Claude API Documentation

### Version History

**Version 1.0.0** (Current)
- Initial release
- Recipe extraction from images
- Allergen detection and scoring
- FODMAP analysis
- Recipe editing
- Image assignment
- Export to Reminders

### Future Roadmap

**Planned Features:**
- Collections and folders
- Recipe search and filtering
- Nutrition information
- Meal planning
- Shopping list management
- Cloud sync
- Recipe sharing
- Barcode scanning
- Voice input for recipes
- Apple Watch companion

---

## Getting Help

### In-App Help

- Tap **?** icon in toolbars for contextual help
- Browse all help topics from help browser
- Quick reference cards for each feature

### Documentation

- `README.md` - Project overview
- `ALLERGEN_DETECTION_GUIDE.md` - Allergen system details
- `FODMAP_IMPLEMENTATION_GUIDE.md` - FODMAP features
- `RECIPE_EDITING_QUICKSTART.md` - Editing guide
- `AUTOMATIC_IMAGE_ASSIGNMENT.md` - Image system
- `COMPLETE_APP_HELP_GUIDE.md` - This document

### External Resources

- [Anthropic Console](https://console.anthropic.com) - API key management
- [Monash FODMAP](https://www.monashfodmap.com) - Official FODMAP information
- [FDA Allergen Info](https://www.fda.gov/food/food-labeling-nutrition/food-allergen-labeling) - Allergen regulations

---

## Legal & Privacy

### Data Privacy

- All data stored locally on your device
- No data collection or analytics
- No personally identifiable information transmitted
- API key stored in encrypted iOS Keychain
- Photos processed only during extraction
- HIPAA-compliant architecture

### Claude API Usage

- Recipe extraction uses Claude Sonnet 4
- Images sent to Anthropic servers during extraction
- Subject to Anthropic's privacy policy and terms
- Costs charged to your Anthropic account
- No data retention after processing

### License

- See License Agreement in Settings for complete terms
- App usage subject to license acceptance
- Code and documentation provided as-is

---

**Reczipes2** - Version 1.0.0  
Built with ❤️ using Claude Sonnet 4

*Last Updated: December 18, 2025*
