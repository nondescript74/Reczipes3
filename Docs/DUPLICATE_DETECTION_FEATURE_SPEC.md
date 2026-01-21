# Feature Specification: Duplicate Recipe Detection During Extraction

## 🎯 Overview

Add intelligent duplicate detection to prevent users from extracting the same recipe multiple times. The system will detect duplicates and provide appropriate user options based on the recipe's sharing/cookbook status.

## 📋 Requirements

### 1. Detection Points

**When to Check:**
- ✅ Before extraction begins (image hash comparison)
- ✅ After extraction completes (recipe content comparison)
- ✅ During batch extraction (for each image)

**What to Check:**
- Image file hash (perceptual hash for similar images)
- Recipe title (fuzzy matching)
- Ingredients list (similarity matching)
- Combined confidence score

### 2. Detection Logic

#### Level 1: Image Hash Detection (Fast)
```
Before extraction:
1. Generate perceptual hash of uploaded image
2. Compare with hashes of all existing recipe images
3. If match found (>95% similarity):
   → Flag as potential duplicate
   → Continue to Level 2
```

#### Level 2: Recipe Content Detection (After Extraction)
```
After extraction completes:
1. Compare extracted recipe title with existing recipes (fuzzy match)
2. Compare ingredient lists (70%+ overlap = likely duplicate)
3. Calculate overall confidence score
4. If confidence > 80%:
   → Show duplicate resolution dialog
```

### 3. User Decision Paths

#### Scenario A: Duplicate Found, Recipe NOT Shared/In Cookbook
**User Options:**
1. ✅ **Keep Both** - Save as new recipe with "(Copy)" suffix
2. ✅ **Replace Original** - Overwrite existing recipe with new extraction
3. ✅ **Keep Original** - Discard new extraction, keep existing
4. ✅ **Compare & Decide** - Show side-by-side comparison first

#### Scenario B: Duplicate Found, Recipe IS Shared
**User Options:**
1. ✅ **Keep Both** - Save as new recipe (original remains shared)
2. ❌ **Replace Original** - DISABLED (would affect shared recipe)
3. ✅ **Keep Original** - Discard new extraction
4. ✅ **Compare & Decide** - Show side-by-side comparison

**Alert Message:**
```
⚠️ Cannot Replace Shared Recipe

This recipe is currently shared with others. Replacing it would 
affect all users who have access.

You can:
• Keep both recipes (recommended)
• Keep the original and discard this extraction
• View a comparison to decide
```

#### Scenario C: Duplicate Found, Recipe IS In Cookbook
**User Options:**
1. ✅ **Keep Both** - Save as new recipe (original stays in cookbook)
2. ❌ **Replace Original** - DISABLED (would affect cookbook)
3. ✅ **Keep Original** - Discard new extraction
4. ✅ **Compare & Decide** - Show side-by-side comparison

**Alert Message:**
```
⚠️ Cannot Replace Recipe in Cookbook

This recipe is part of one or more cookbooks:
• Summer Favorites
• Family Recipes

Replacing it would affect these cookbooks.

You can:
• Keep both recipes (recommended)
• Keep the original and discard this extraction
• View a comparison to decide
```

## 🏗️ Architecture

### New Components

#### 1. DuplicateDetectionService
```swift
@MainActor
class DuplicateDetectionService {
    
    // Image hash detection
    func detectImageDuplicates(image: UIImage) async -> [Recipe]
    
    // Recipe content detection
    func detectRecipeDuplicates(recipe: RecipeModel) async -> [DuplicateMatch]
    
    // Calculate similarity score
    func calculateSimilarity(
        recipe1: RecipeModel, 
        recipe2: Recipe
    ) -> DuplicateMatchScore
}

struct DuplicateMatch {
    let existingRecipe: Recipe
    let confidence: Double // 0.0 to 1.0
    let matchType: MatchType
    let reasons: [String]
}

enum MatchType {
    case imageHash      // Image looks identical
    case titleMatch     // Title is same/similar
    case ingredientMatch // Ingredients are same/similar
    case combined       // Multiple factors match
}

struct DuplicateMatchScore {
    let titleSimilarity: Double
    let ingredientSimilarity: Double
    let imageSimilarity: Double
    let overall: Double
}
```

#### 2. ImageHashService
```swift
class ImageHashService {
    // Generate perceptual hash (resistant to minor edits)
    func generateHash(for image: UIImage) -> String
    
    // Compare two hashes
    func similarity(hash1: String, hash2: String) -> Double
    
    // Find similar images in database
    func findSimilarImages(hash: String, threshold: Double) async -> [Recipe]
}
```

#### 3. DuplicateResolutionView
```swift
struct DuplicateResolutionView: View {
    let existingRecipe: Recipe
    let newRecipe: RecipeModel
    let duplicateMatch: DuplicateMatch
    
    var isShared: Bool
    var isInCookbook: Bool
    var cookbookNames: [String]
    
    // User action callbacks
    var onKeepBoth: () -> Void
    var onReplaceOriginal: () -> Void
    var onKeepOriginal: () -> Void
    var onCompare: () -> Void
}
```

#### 4. RecipeComparisonView
```swift
struct RecipeComparisonView: View {
    let existingRecipe: Recipe
    let newRecipe: RecipeModel
    
    // Side-by-side comparison
    // Highlights differences
    // Allows selection of which to keep
}
```

## 🔄 User Flow

### Single Image Extraction

```
1. User selects image
   ↓
2. Image hash generated
   ↓
3. Check: Similar image exists?
   ├─ NO → Continue extraction
   └─ YES → Show "Potential Duplicate" alert
            ├─ Continue Anyway
            └─ Cancel
   ↓
4. Extraction completes
   ↓
5. Recipe content analysis
   ↓
6. Check: Similar recipe exists?
   ├─ NO → Save normally
   └─ YES → Show duplicate resolution dialog
            ↓
            Check: Is shared or in cookbook?
            ├─ YES → Limited options (no replace)
            └─ NO → Full options
            ↓
            User chooses action
            ↓
            Execute chosen action
```

### Batch Extraction

```
For each image:
1. Pre-extraction hash check (optional - can be slow)
   ├─ Skip duplicate images
   └─ Or queue for user decision later

2. Extract recipe

3. Post-extraction content check
   ├─ If duplicate and in background mode:
   │   └─ Auto-keep both with "(Copy)" suffix
   │   └─ Log for user review
   │
   └─ If duplicate and user is watching:
       └─ Show resolution dialog
       └─ Pause batch for user decision

4. Continue with next image

At end:
- Show summary of duplicates found
- List of auto-resolved duplicates
- Allow bulk review and cleanup
```

## 💾 Database Schema Updates

### Recipe Model
```swift
@Model
class Recipe {
    // ... existing properties ...
    
    // NEW: Store image hash for fast duplicate detection
    var imageHash: String?
    
    // NEW: Track extraction source
    var extractionSource: String? // "camera", "photos", "files"
    var originalFileName: String?
    
    // Existing: These are used for duplicate prevention
    var isShared: Bool = false
    var cookbooks: [Cookbook]? // Relationship
}
```

### DuplicateDetectionLog
```swift
@Model
class DuplicateDetectionLog {
    var id: UUID
    var detectedDate: Date
    var originalRecipeID: UUID
    var duplicateRecipeID: UUID?
    var confidence: Double
    var action: String // "kept_both", "replaced", "kept_original"
    var userNotes: String?
}
```

## 🎨 UI Components

### 1. Duplicate Alert (Simple)
```
⚠️ Potential Duplicate Found

This image may have been extracted before.

Existing recipe: "Chocolate Chip Cookies"
Confidence: 95%

[View Comparison]  [Continue Anyway]  [Cancel]
```

### 2. Duplicate Resolution Dialog (Full)
```
┌─────────────────────────────────────────┐
│  Duplicate Recipe Detected              │
├─────────────────────────────────────────┤
│                                         │
│  📊 Match Details:                      │
│  • Title similarity: 98%                │
│  • Ingredient match: 85%                │
│  • Image similarity: 92%                │
│  • Overall confidence: 91%              │
│                                         │
│  Existing Recipe:                       │
│  🍪 "Chocolate Chip Cookies"            │
│  📅 Added: Jan 15, 2026                 │
│  📚 In 2 cookbooks                      │
│                                         │
├─────────────────────────────────────────┤
│  What would you like to do?             │
│                                         │
│  ○ Keep Both Recipes                    │
│    New will be saved as "...Cookies (2)"│
│                                         │
│  ○ Replace Original                     │
│    ⚠️ DISABLED - Recipe is in cookbook  │
│                                         │
│  ○ Keep Original Only                   │
│    Discard new extraction               │
│                                         │
│  [Compare Side-by-Side]                 │
│                                         │
│  [Cancel]           [Continue]          │
└─────────────────────────────────────────┘
```

### 3. Comparison View
```
┌──────────────────────────────────────────┐
│  Recipe Comparison                       │
├──────────────────────────────────────────┤
│  Existing          |  New Extraction     │
├────────────────────┼─────────────────────┤
│  🍪 Chocolate Chip  │ 🍪 Chocolate Chip   │
│     Cookies        │    Cookies          │
│                    │                     │
│  📅 Jan 15, 2026   │ 📅 Jan 20, 2026     │
│                    │                     │
│  📸 [Image]        │ 📸 [Image]          │
│                    │                     │
│  Ingredients:      │ Ingredients:        │
│  • 2 cups flour    │ • 2 cups flour      │
│  • 1 cup sugar     │ • 1 cup sugar       │
│  • 1 cup butter    │ • 1 cup butter      │
│  • 2 eggs          │ • 2 eggs            │
│  • 1 tsp vanilla   │ • 1 tsp vanilla     │
│                    │ • ½ tsp salt  ← NEW │
│                    │                     │
│  Instructions:     │ Instructions:       │
│  (5 steps)         │ (6 steps)           │
│                    │                     │
├────────────────────┴─────────────────────┤
│  [Keep Existing]  [Keep Both]  [Keep New]│
└──────────────────────────────────────────┘
```

### 4. Batch Duplicate Summary
```
┌─────────────────────────────────────────┐
│  Batch Extraction Complete              │
├─────────────────────────────────────────┤
│  📊 Results:                            │
│  • 15 recipes extracted                 │
│  • 3 duplicates detected                │
│  • 12 new recipes added                 │
│                                         │
│  🔍 Duplicates Auto-Resolved:           │
│  1. "Apple Pie" → Saved as "Apple Pie (2)"│
│  2. "Banana Bread" → Saved as "Banana..." │
│  3. "Carrot Cake" → Saved as "Carrot..." │
│                                         │
│  [Review Duplicates]  [Done]            │
└─────────────────────────────────────────┘
```

## 🔧 Implementation Steps

### Phase 1: Core Detection (Week 1)
- [ ] Create `ImageHashService` with perceptual hashing
- [ ] Create `DuplicateDetectionService`
- [ ] Add `imageHash` field to Recipe model
- [ ] Implement title similarity matching
- [ ] Implement ingredient similarity matching
- [ ] Write unit tests for detection algorithms

### Phase 2: Single Image Flow (Week 2)
- [ ] Create `DuplicateResolutionView`
- [ ] Create `RecipeComparisonView`
- [ ] Integrate into `RecipeExtractorView`
- [ ] Handle "Keep Both" action
- [ ] Handle "Replace Original" action
- [ ] Handle "Keep Original" action
- [ ] Add shared/cookbook status checks

### Phase 3: Batch Flow (Week 3)
- [ ] Integrate into `BatchImageExtractorViewModel`
- [ ] Implement auto-resolution for background mode
- [ ] Create duplicate summary view
- [ ] Add pause/resume for duplicate decisions
- [ ] Create bulk duplicate review UI

### Phase 4: Polish & Testing (Week 4)
- [ ] Add analytics/logging
- [ ] Performance optimization
- [ ] User testing
- [ ] Documentation
- [ ] Help system updates

## 📊 Algorithms

### Title Similarity (Fuzzy Matching)
```swift
func titleSimilarity(title1: String, title2: String) -> Double {
    // Normalize: lowercase, trim whitespace
    let normalized1 = title1.lowercased().trimmingCharacters(in: .whitespaces)
    let normalized2 = title2.lowercased().trimmingCharacters(in: .whitespaces)
    
    // Exact match
    if normalized1 == normalized2 {
        return 1.0
    }
    
    // Levenshtein distance
    let distance = levenshteinDistance(normalized1, normalized2)
    let maxLength = max(normalized1.count, normalized2.count)
    let similarity = 1.0 - (Double(distance) / Double(maxLength))
    
    return similarity
}
```

### Ingredient Similarity
```swift
func ingredientSimilarity(ingredients1: [String], ingredients2: [String]) -> Double {
    // Normalize ingredients
    let set1 = Set(ingredients1.map { normalizeIngredient($0) })
    let set2 = Set(ingredients2.map { normalizeIngredient($0) })
    
    // Jaccard similarity
    let intersection = set1.intersection(set2).count
    let union = set1.union(set2).count
    
    guard union > 0 else { return 0.0 }
    
    return Double(intersection) / Double(union)
}

func normalizeIngredient(_ ingredient: String) -> String {
    // Remove quantities, units, common words
    // Extract main ingredient name
    // Example: "2 cups all-purpose flour" → "flour"
    return ingredient
        .lowercased()
        .replacingOccurrences(of: #"\d+\/?\d*"#, with: "", options: .regularExpression)
        .replacingOccurrences(of: #"\b(cup|cups|tbsp|tsp|oz|lb|g|kg)\b"#, with: "", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
```

### Image Perceptual Hash
```swift
func generatePerceptualHash(for image: UIImage) -> String {
    // 1. Resize to 8x8
    let resized = image.resized(to: CGSize(width: 8, height: 8))
    
    // 2. Convert to grayscale
    let grayscale = resized.grayscale()
    
    // 3. Calculate average pixel value
    let pixels = grayscale.getPixelData()
    let average = pixels.reduce(0, +) / pixels.count
    
    // 4. Generate hash based on pixels > average
    let hash = pixels.map { $0 > average ? "1" : "0" }.joined()
    
    return hash
}

func hammingDistance(hash1: String, hash2: String) -> Int {
    // Count differing bits
    zip(hash1, hash2).filter { $0 != $1 }.count
}
```

## 🧪 Testing Strategy

### Unit Tests
```swift
class DuplicateDetectionTests {
    func testExactTitleMatch()
    func testFuzzyTitleMatch()
    func testIngredientSimilarity()
    func testImageHashMatching()
    func testOverallConfidenceCalculation()
    func testSharedRecipeProtection()
    func testCookbookRecipeProtection()
}
```

### Integration Tests
```swift
class DuplicateFlowTests {
    func testSingleImageDuplicateDetection()
    func testBatchDuplicateHandling()
    func testKeepBothAction()
    func testReplaceAction()
    func testReplaceBlockedForShared()
    func testReplaceBlockedForCookbook()
}
```

### User Acceptance Tests
- [ ] Extract same image twice - detects duplicate
- [ ] Extract similar recipe - offers options
- [ ] Try to replace shared recipe - blocked
- [ ] Try to replace cookbook recipe - blocked
- [ ] Keep both - new recipe has "(Copy)" suffix
- [ ] Batch extraction - auto-resolves duplicates
- [ ] Review duplicates after batch

## 📝 Settings & Preferences

### User Preferences
```swift
@AppStorage("duplicateDetection.enabled") var duplicateDetectionEnabled = true
@AppStorage("duplicateDetection.autoResolve") var autoResolveDuplicates = false
@AppStorage("duplicateDetection.threshold") var detectionThreshold = 0.8
@AppStorage("duplicateDetection.imageHashEnabled") var imageHashEnabled = true
```

### Settings UI
```
Settings → Extraction Settings

Duplicate Detection
├─ Enable Duplicate Detection        [ON]
├─ Detection Sensitivity              [High | Medium | Low]
├─ Auto-resolve in Batch Mode         [OFF]
│  └─ When enabled, duplicates are automatically saved as "(Copy)"
├─ Image Hash Detection               [ON]
│  └─ Detect visually similar images before extraction
└─ Show Comparison by Default         [ON]
```

## 📚 Help Documentation Updates

### New Help Topics

**1. Duplicate Recipe Detection**
```
Icon: doc.on.doc
Title: "Duplicate Recipe Detection"

Description:
Automatically detects when you're about to extract a recipe 
you already have. Prevents accidental duplicates and helps 
keep your collection organized.

Tips:
- Detection works on images and recipe content
- Shared recipes cannot be replaced (protection)
- Cookbook recipes cannot be replaced (protection)
- Choose to keep both, replace, or keep original
- View side-by-side comparison before deciding
```

**2. Managing Duplicates**
```
Icon: arrow.triangle.merge
Title: "Managing Duplicates"

Description:
When a duplicate is found, you have several options depending 
on whether the recipe is shared or in a cookbook.

Tips:
- Keep Both: New recipe saved with "(Copy)" suffix
- Replace: Overwrites original (if not shared/in cookbook)
- Keep Original: Discards new extraction
- Compare: See differences side-by-side
```

## 🔒 Security & Privacy

### Data Handling
- ✅ All detection happens locally (no cloud)
- ✅ Image hashes stored in SwiftData
- ✅ No external API calls for detection
- ✅ User data never leaves device

### Protection Rules
- ✅ Cannot replace shared recipes (data integrity)
- ✅ Cannot replace cookbook recipes (consistency)
- ✅ User always has final decision
- ✅ Undo capability for accidental replacements

## 📈 Analytics (Optional)

Track (anonymously):
- Duplicate detection rate
- User action distribution (keep both / replace / keep original)
- False positive rate
- User satisfaction with detection

## ⚠️ Edge Cases

### Handle These Scenarios:
1. **Multiple matches found** → Show best match, list others
2. **Low confidence match** → Only alert if >80% confidence
3. **Partial ingredient match** → Show as "possibly related"
4. **Same title, different recipes** → Rely on ingredients
5. **Recipe updated over time** → Consider as separate
6. **Batch mode duplicates** → Auto-resolve or queue for review
7. **Network failure during extraction** → Retry, don't create partial

## 🎯 Success Metrics

### User Experience
- Duplicate detection accuracy > 90%
- False positive rate < 5%
- User satisfaction with resolution options
- Reduced accidental duplicates

### Performance
- Image hash generation < 100ms
- Recipe comparison < 50ms
- No noticeable delay in extraction flow
- Batch mode performance unaffected

---

**Status**: 📋 Specification Complete - Ready for Implementation
**Estimated Effort**: 4 weeks (1 developer)
**Priority**: High - Improves data quality and user experience
**Dependencies**: Existing extraction system, SwiftData models
