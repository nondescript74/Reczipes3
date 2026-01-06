# Context-Aware Ingredient Matching Architecture

## System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                     Recipe Input Sources                          │
│  ┌────────────┐    ┌────────────┐    ┌────────────┐            │
│  │   Image    │    │    URL     │    │   Manual   │            │
│  │  (Camera)  │    │ (Web Page) │    │   Entry    │            │
│  └─────┬──────┘    └─────┬──────┘    └─────┬──────┘            │
└────────┼──────────────────┼──────────────────┼───────────────────┘
         │                  │                  │
         ▼                  ▼                  ▼
┌────────────────────────────────────────────────────────────┐
│              Claude API - Recipe Extraction                 │
│  ┌────────────────────────────────────────────────────┐   │
│  │  System Prompt (Enhanced):                         │   │
│  │  • Extract COMPLETE ingredient phrases             │   │
│  │  • Include quantity, unit, name, preparation       │   │
│  │  • "cream of tartar" ≠ "cream"                    │   │
│  │  • "coconut milk" ≠ "milk"                        │   │
│  │  • Preserve qualifiers (dairy-free, vegan, etc.)  │   │
│  └────────────────────────────────────────────────────┘   │
└────────────────────────┬───────────────────────────────────┘
                         │
                         ▼
                ┌─────────────────┐
                │  Recipe Model   │
                │  ┌───────────┐  │
                │  │"1 tsp     │  │
                │  │cream of   │  │
                │  │tartar"    │  │
                │  └───────────┘  │
                │  ┌───────────┐  │
                │  │"1 cup     │  │
                │  │heavy cream│  │
                │  └───────────┘  │
                └────────┬────────┘
                         │
        ┌────────────────┼────────────────┐
        │                                 │
        ▼                                 ▼
┌───────────────────┐           ┌─────────────────────┐
│  Local Analysis   │           │   Claude Analysis   │
│  (Immediate)      │           │   (Enhanced, Async) │
└───────┬───────────┘           └──────────┬──────────┘
        │                                  │
        ▼                                  ▼
```

## Local Analysis Flow (Immediate)

```
┌─────────────────────────────────────────────────────────────┐
│                   AllergenAnalyzer.analyzeRecipe()          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │ Extract all ingredient names │
        │ (name + preparation + unit)  │
        └─────────────┬────────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │  For each user sensitivity:  │
        │  findMatchingIngredients()   │
        └─────────────┬────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────────┐
│              intelligentMatch() Decision Tree                 │
│                                                               │
│  Ingredient: "cream of tartar"                               │
│  Keyword: "cream"                                            │
│                                                               │
│  ┌──────────────────┐                                        │
│  │ Exact match?     │  NO ──────────────────────┐           │
│  └────┬─────────────┘                            │           │
│       │ YES                                      │           │
│       ▼                                          ▼           │
│  ┌──────────────────┐            ┌──────────────────────┐  │
│  │ Word boundary    │            │ Check word boundary  │  │
│  │ match?           │            │ with regex           │  │
│  └────┬─────────────┘            └──────┬───────────────┘  │
│       │                                  │                  │
│       │ "cream" found as                 │ "cream" found    │
│       │ complete word                    │ in phrase        │
│       ▼                                  ▼                  │
│  ┌────────────────────────────────────────────────┐        │
│  │         isKnownException()?                     │        │
│  │                                                 │        │
│  │  Check dictionary:                              │        │
│  │  "cream": ["cream of tartar", "creamer"]       │        │
│  │                                                 │        │
│  │  Does "cream of tartar" match exception?       │        │
│  └──────────┬─────────────────────┬────────────────┘        │
│             │ YES                 │ NO                      │
│             ▼                     ▼                         │
│        ┌─────────┐           ┌──────────┐                  │
│        │ NO MATCH│           │  MATCH!  │                  │
│        │    ✅   │           │    ⚠️    │                  │
│        └─────────┘           └──────────┘                  │
└──────────────────────────────────────────────────────────────┘
```

## Claude Analysis Flow (Enhanced)

```
┌────────────────────────────────────────────────────────────┐
│        AllergenAnalyzer.analyzeRecipeWithClaude()          │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│         generateClaudeAnalysisPrompt()                      │
│  ┌──────────────────────────────────────────────────┐     │
│  │ Build comprehensive prompt with:                  │     │
│  │                                                    │     │
│  │ 1. Full ingredient context:                       │     │
│  │    "1 teaspoon cream of tartar"                  │     │
│  │    "1 cup heavy cream, cold"                     │     │
│  │                                                    │     │
│  │ 2. User sensitivities:                            │     │
│  │    "Dairy (moderate)"                             │     │
│  │                                                    │     │
│  │ 3. False positive examples:                       │     │
│  │    - "cream of tartar" is NOT dairy              │     │
│  │    - "coconut milk" is NOT dairy                 │     │
│  │    - [15+ examples]                               │     │
│  │                                                    │     │
│  │ 4. Analysis requirements:                         │     │
│  │    - Consider COMPLETE phrase                     │     │
│  │    - Provide confidence scores                    │     │
│  │    - Document false positives avoided             │     │
│  │    - Explain reasoning                            │     │
│  └──────────────────────────────────────────────────┘     │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│                    Claude API Call                          │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│              Claude's Analysis Process                      │
│  ┌──────────────────────────────────────────────────┐     │
│  │ For each ingredient, Claude considers:            │     │
│  │                                                    │     │
│  │ "cream of tartar"                                │     │
│  │   ├─ Contains word "cream"? YES                  │     │
│  │   ├─ Is it dairy cream? NO                       │     │
│  │   ├─ What is it? Potassium bitartrate           │     │
│  │   ├─ Action: Add to falsePositivesAvoided       │     │
│  │   └─ confidenceScore: N/A (not an allergen)     │     │
│  │                                                    │     │
│  │ "heavy cream"                                    │     │
│  │   ├─ Contains word "cream"? YES                  │     │
│  │   ├─ Is it dairy cream? YES                      │     │
│  │   ├─ User has dairy sensitivity? YES             │     │
│  │   ├─ Action: Add to detectedAllergens            │     │
│  │   ├─ confidenceScore: 0.95                       │     │
│  │   └─ reasoning: "Heavy cream is a dairy product" │     │
│  └──────────────────────────────────────────────────┘     │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│                    JSON Response                            │
│  ┌──────────────────────────────────────────────────┐     │
│  │ {                                                 │     │
│  │   "detectedAllergens": [                         │     │
│  │     {                                             │     │
│  │       "name": "dairy",                            │     │
│  │       "foundIn": ["heavy cream"],                │     │
│  │       "confidenceScore": 0.95,                   │     │
│  │       "reasoning": "Heavy cream is dairy"        │     │
│  │     }                                             │     │
│  │   ],                                              │     │
│  │   "falsePositivesAvoided": [                     │     │
│  │     {                                             │     │
│  │       "ingredient": "cream of tartar",           │     │
│  │       "whyNotAnAllergen": "Potassium bitartrate" │     │
│  │     }                                             │     │
│  │   ]                                               │     │
│  │ }                                                 │     │
│  └──────────────────────────────────────────────────┘     │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│              EnhancedAllergenScore                          │
│  Combines local + Claude results for best accuracy         │
└─────────────────────────────────────────────────────────────┘
```

## Comparison: Before vs After

### Before (Simple Substring Matching)
```
User has DAIRY sensitivity (keywords: ["cream", "milk", "butter"])

Recipe Ingredients:
├─ "cream of tartar"     → MATCH "cream"  ❌ FALSE POSITIVE
├─ "coconut milk"        → MATCH "milk"   ❌ FALSE POSITIVE
├─ "peanut butter"       → MATCH "butter" ❌ FALSE POSITIVE
├─ "heavy cream"         → MATCH "cream"  ✅ TRUE POSITIVE
└─ "flour"               → NO MATCH       ✅ TRUE NEGATIVE

Result: 4 matches (3 false positives!)
```

### After (Context-Aware Matching)
```
User has DAIRY sensitivity (keywords: ["cream", "milk", "butter"])

Recipe Ingredients:
├─ "cream of tartar"     → NO MATCH (exception)      ✅
├─ "coconut milk"        → NO MATCH (exception)      ✅
├─ "peanut butter"       → NO MATCH (exception)      ✅
├─ "heavy cream"         → MATCH "cream"             ✅
└─ "flour"               → NO MATCH                  ✅

Result: 1 match (0 false positives!)
```

## Data Flow Example

```
┌────────────────────────────────────────────────────────────┐
│ INPUT: Recipe for Chocolate Chip Cookies                   │
└────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│ EXTRACTION (Claude):                                        │
│  • "2 1/4 cups all-purpose flour"                         │
│  • "1 teaspoon cream of tartar"                            │
│  • "1 cup unsalted butter, softened"                       │
│  • "1/2 cup coconut milk"                                  │
│  • "2 large eggs"                                          │
│  • "2 cups chocolate chips"                                │
└────────────────────────────────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
        ▼                                 ▼
┌─────────────────────┐      ┌──────────────────────────┐
│ LOCAL ANALYSIS      │      │ CLAUDE ANALYSIS          │
│ (Instant)           │      │ (2-5 seconds)            │
├─────────────────────┤      ├──────────────────────────┤
│ Detected:           │      │ Detected:                │
│  ⚠️ butter          │      │  ⚠️ dairy (butter)       │
│  ⚠️ eggs            │      │  ⚠️ eggs                 │
│                     │      │                          │
│ NOT Detected:       │      │ Correctly Ignored:       │
│  ✅ cream (in cream │      │  ✅ cream of tartar      │
│     of tartar)      │      │     (not dairy)          │
│  ✅ milk (coconut)  │      │  ✅ coconut milk         │
│                     │      │     (plant-based)        │
└─────────────────────┘      └──────────────────────────┘
        │                                 │
        └────────────────┬────────────────┘
                         ▼
┌────────────────────────────────────────────────────────────┐
│ COMBINED RESULT:                                            │
│                                                             │
│ Recipe Status: ⚠️ CAUTION                                  │
│                                                             │
│ Detected Allergens:                                         │
│  • Dairy (from: unsalted butter)                           │
│  • Eggs (from: large eggs)                                 │
│                                                             │
│ Safe Alternatives:                                          │
│  • Use vegan butter instead of unsalted butter             │
│  • Use flax eggs instead of large eggs                     │
│                                                             │
│ Notes:                                                      │
│  ✓ Cream of tartar is safe (not dairy)                    │
│  ✓ Coconut milk is safe (dairy-free alternative)          │
└────────────────────────────────────────────────────────────┘
```

## Exception Dictionary Structure

```
exceptions: Dictionary<String, [String]>
│
├─ "cream" → ["cream of tartar", "cream of wheat", "creamer"]
│            │
│            └─ If ingredient contains any of these,
│               don't match keyword "cream"
│
├─ "milk" → ["coconut milk", "almond milk", "oat milk", 
│            "soy milk", "rice milk"]
│
├─ "butter" → ["peanut butter", "almond butter", 
│              "cashew butter", "cocoa butter", "butternut"]
│
└─ "egg" → ["eggplant", "nutmeg"]
```

## Performance Characteristics

```
┌──────────────────────────────────────────────────────────┐
│                     Processing Time                       │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  Recipe Extraction (Claude):   2-5 seconds               │
│  ████████████████████████████████████                    │
│                                                           │
│  Local Analysis:               < 1 millisecond           │
│  █                                                        │
│                                                           │
│  Claude Enhanced Analysis:     2-5 seconds               │
│  ████████████████████████████████████                    │
│                                                           │
└──────────────────────────────────────────────────────────┘

Memory Usage:
├─ Exception Dictionary:  ~2 KB
├─ Recipe Model:          ~10-50 KB per recipe
└─ Claude Response:       ~5-20 KB per analysis
```

## Summary

```
                    Context-Aware Matching

┌───────────────────────────────────────────────────────────┐
│  Key Innovation: Analyze COMPLETE ingredient phrases     │
└───────────────────────────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────────┐
│ Word         │   │ Exception    │   │ Full Context     │
│ Boundaries   │   │ Dictionary   │   │ to Claude        │
├──────────────┤   ├──────────────┤   ├──────────────────┤
│ "cream"      │   │ "cream of    │   │ "1 tsp cream     │
│ matches only │   │  tartar"     │   │  of tartar"      │
│ whole words  │   │ = exception  │   │ not just "cream" │
└──────────────┘   └──────────────┘   └──────────────────┘

Result: Fewer false positives, better user trust
```
