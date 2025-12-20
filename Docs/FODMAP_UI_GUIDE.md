# FODMAP Substitution Feature - Visual Guide

## UI Components Overview

### 1. Recipe Detail View with FODMAP Section

When viewing a recipe with high FODMAP ingredients:

```
┌────────────────────────────────────────┐
│  Recipe: Pasta with Mushroom Sauce     │
│                                        │
│  [Recipe Image]                        │
│                                        │
│  ════════════════════════════════════ │
│                                        │
│  🍃 FODMAP Friendly Options    [Hide▲] │
│                                        │
│  ⚠️ 3 ingredients can be substituted   │
│                                        │
│  ┌────────────────────────────────┐   │
│  │ ⚠️ 1 medium onion          ▼  │   │
│  │ 🧅 Oligosaccharides           │   │
│  └────────────────────────────────┘   │
│                                        │
│  ┌────────────────────────────────┐   │
│  │ ⚠️ 3 cloves garlic          ▼  │   │
│  │ 🧅 Oligosaccharides           │   │
│  └────────────────────────────────┘   │
│                                        │
│  ┌────────────────────────────────┐   │
│  │ ⚠️ 1 cup mushrooms          ▼  │   │
│  │ 🍎 Polyols                    │   │
│  └────────────────────────────────┘   │
│                                        │
│  ════════════════════════════════════ │
│                                        │
│  📋 Ingredients                        │
│  • 1 medium onion ⚠️                  │
│    [🔄 FODMAP substitute available]   │
│  • 3 cloves garlic ⚠️                 │
│    [🔄 FODMAP substitute available]   │
│  • 1 cup mushrooms ⚠️                 │
│    [🔄 FODMAP substitute available]   │
└────────────────────────────────────────┘
```

### 2. Expanded Substitution Card

When user taps to expand a substitution:

```
┌────────────────────────────────────────┐
│  ⚠️ 1 medium onion              ▲     │
│  🧅 Oligosaccharides                   │
│                                        │
│  Onions are very high in fructans     │
│  (oligosaccharides). These substitutes│
│  provide similar flavor without       │
│  FODMAPs.                             │
│                                        │
│  📏 No safe portion - avoid onions    │
│     completely on low FODMAP diet     │
│                                        │
│  ────────────────────────────────────│
│                                        │
│  ➡️ Substitute with:                   │
│                                        │
│  ● Green tops of spring onions only   │
│    • Use green part only              │
│    • Recommended ✓                    │
│    "Discard white bulb which is high  │
│     FODMAP"                           │
│                                        │
│  ● Garlic-infused oil                 │
│    • 2-3 tbsp                         │
│    • Recommended ✓                    │
│    "Strain out any garlic solids -    │
│     FODMAPs don't transfer to oil"    │
│                                        │
│  ● Asafoetida powder (hing)           │
│    • ¼ tsp per onion                  │
│    • Recommended ✓                    │
│    "Indian spice with onion/garlic    │
│     flavor, naturally low FODMAP"     │
│                                        │
│  ● Chives                             │
│    • 2-3 tbsp chopped                 │
│    • Good Alternative                 │
│    "Low FODMAP in normal portions"    │
│                                        │
└────────────────────────────────────────┘
```

### 3. Inline Substitute Detail Sheet

When user taps inline "FODMAP substitute available" button:

```
┌────────────────────────────────────────┐
│            FODMAP Substitute     [Done]│
├────────────────────────────────────────┤
│                                        │
│  ⚠️ onion                              │
│  ┌──────┐  ┌─────────────────┐        │
│  │ 🧅  │  │ Oligosaccharides│        │
│  │      │  └─────────────────┘        │
│  └──────┘                              │
│                                        │
│  ─────────────────────────────────────│
│                                        │
│  ℹ️ Why Substitute?                    │
│                                        │
│  Onions are very high in fructans     │
│  (oligosaccharides). These substitutes│
│  provide similar flavor without       │
│  FODMAPs.                             │
│                                        │
│  ─────────────────────────────────────│
│                                        │
│  📏 Portion Guidance                   │
│                                        │
│  No safe portion - avoid onions       │
│  completely on low FODMAP diet        │
│                                        │
│  ─────────────────────────────────────│
│                                        │
│  🔄 Substitute Options                 │
│                                        │
│  ┌────────────────────────────────┐   │
│  │ Green tops of spring onions    │   │
│  │ • Use green part only          │   │
│  │ Recommended ✓                  │   │
│  │                                │   │
│  │ "Discard white bulb which is   │   │
│  │  high FODMAP"                  │   │
│  └────────────────────────────────┘   │
│                                        │
│  [3 more options...]                   │
│                                        │
└────────────────────────────────────────┘
```

### 4. FODMAP Settings Screen

```
┌────────────────────────────────────────┐
│  ◀️ Settings   FODMAP Settings          │
├────────────────────────────────────────┤
│                                        │
│  FODMAP Sensitivity                    │
│  ┌────────────────────────────────┐   │
│  │ Enable FODMAP Features    [ON] │   │
│  └────────────────────────────────┘   │
│  When enabled, recipes will show      │
│  FODMAP ingredient analysis and low   │
│  FODMAP substitution suggestions.     │
│                                        │
│  Display Options                       │
│  ┌────────────────────────────────┐   │
│  │ Show inline FODMAP           │   │
│  │ indicators              [ON] │   │
│  │                              │   │
│  │ Auto-expand substitutions    │   │
│  │                        [OFF] │   │
│  └────────────────────────────────┘   │
│  Inline indicators show a warning     │
│  next to high FODMAP ingredients.     │
│                                        │
│  ─────────────────────────────────────│
│                                        │
│  About FODMAP                          │
│  ┌────────────────────────────────┐   │
│  │ FODMAPs are types of           │   │
│  │ carbohydrates that can trigger │   │
│  │ digestive symptoms...          │   │
│  │                                │   │
│  │ 🧅 Oligosaccharides            │   │
│  │    Fructans & GOS              │   │
│  │                                │   │
│  │ 🥛 Disaccharides               │   │
│  │    Lactose                     │   │
│  │                                │   │
│  │ 🍯 Monosaccharides             │   │
│  │    Excess Fructose             │   │
│  │                                │   │
│  │ 🍎 Polyols                     │   │
│  │    Sugar Alcohols              │   │
│  └────────────────────────────────┘   │
│                                        │
└────────────────────────────────────────┘
```

### 5. Quick Reference View

```
┌────────────────────────────────────────┐
│         FODMAP Quick Reference   [Done]│
├────────────────────────────────────────┤
│                                        │
│  FODMAP Quick Reference                │
│  Common high FODMAP foods and their    │
│  low FODMAP alternatives               │
│                                        │
│  [🧅 Oligo] [🥛 Di] [🍯 Mono] [🍎 Poly]│
│    ^^^^^^^^ Selected                   │
│                                        │
│  ┌────────────────────────────────┐   │
│  │ 🧅 Oligosaccharides            │   │
│  │ Fructans & Galacto-            │   │
│  │ oligosaccharides (GOS)         │   │
│  │                                │   │
│  │ Common High FODMAP Foods:      │   │
│  │ [Onions] [Garlic] [Wheat]      │   │
│  │ [Legumes] [Cashews]            │   │
│  └────────────────────────────────┘   │
│                                        │
│  Substitution Guide                    │
│                                        │
│  ┌────────────────────────────────┐   │
│  │ ✗ onion                        │   │
│  │                                │   │
│  │ ✓ Substitute with:             │   │
│  │ • Green tops of spring onions  │   │
│  │ • Garlic-infused oil          │   │
│  │ + 2 more options               │   │
│  └────────────────────────────────┘   │
│                                        │
│  [More substitution cards...]          │
│                                        │
│  ─────────────────────────────────────│
│                                        │
│  💡 Helpful Tips                       │
│  ✓ Start with small portions when     │
│    testing new foods                  │
│  ✓ Read ingredient labels carefully   │
│  ✓ Green spring onion tops are safe   │
│  ✓ Garlic-infused oil is safe if      │
│    solids are strained out            │
│                                        │
└────────────────────────────────────────┘
```

### 6. FODMAP Cheat Sheet (Compact)

```
┌────────────────────────────────────┐
│  FODMAP Cheat Sheet                │
│                                    │
│  🧅 Onion/Garlic                   │
│     ✗ High FODMAP                  │
│     ✓ Spring onion greens,         │
│       garlic-infused oil           │
│                                    │
│  🍞 Wheat bread                    │
│     ✗ High FODMAP                  │
│     ✓ Gluten-free bread,           │
│       sourdough spelt              │
│                                    │
│  🥛 Regular milk                   │
│     ✗ High FODMAP                  │
│     ✓ Lactose-free milk,           │
│       almond milk                  │
│                                    │
│  🍯 Honey                          │
│     ✗ High FODMAP                  │
│     ✓ Maple syrup, table sugar    │
│                                    │
│  🍎 Apples                         │
│     ✗ High FODMAP                  │
│     ✓ Bananas, strawberries,      │
│       blueberries                  │
│                                    │
│  🍄 Mushrooms                      │
│     ✗ High FODMAP                  │
│     ✓ Eggplant, zucchini          │
│                                    │
└────────────────────────────────────┘
```

## Color Scheme

### FODMAP Levels
- 🟢 **Low FODMAP**: Green (#34C759)
- 🟠 **Moderate FODMAP**: Orange (#FF9500)
- 🔴 **High FODMAP**: Red (#FF3B30)

### Confidence Levels
- 🟢 **High Confidence**: Green (#34C759)
- 🟠 **Medium Confidence**: Orange (#FF9500)
- 🟡 **Low Confidence**: Yellow (#FFCC00)

### FODMAP Categories
- 🧅 **Oligosaccharides**: Orange theme
- 🥛 **Disaccharides**: Blue theme
- 🍯 **Monosaccharides**: Yellow theme
- 🍎 **Polyols**: Red theme

## Interactive Elements

### Tap Targets
- **Substitution card header**: Expands/collapses card
- **Inline "FODMAP substitute available"**: Opens detail sheet
- **Category badge**: Opens category education
- **Confidence indicator**: Shows confidence explanation

### Animations
- Card expand/collapse: 0.3s ease-in-out
- Selection highlight: 0.2s ease-in-out
- Sheet presentation: System default

### States
- **Default**: Collapsed cards, subtle borders
- **Expanded**: Full details, highlighted border
- **Selected**: Blue border, checkmark icon
- **Disabled**: Gray, reduced opacity

## Responsive Design

### iPhone (Compact)
- Single column layout
- Full-width cards
- Scrollable sections

### iPad (Regular)
- Two column layout option
- Side-by-side substitutions
- More visible at once

### Accessibility
- Dynamic Type scaling
- VoiceOver descriptions
- High contrast mode support
- Reduced motion respect

## User Flow Examples

### Flow 1: Discover FODMAP Issue
```
1. User opens recipe
2. Sees allergen warning or FODMAP section
3. Scrolls to FODMAP Friendly Options
4. Taps first substitution card
5. Card expands with details
6. User reads alternatives
7. Takes note for shopping
```

### Flow 2: Quick Check
```
1. User scans ingredient list
2. Sees ⚠️ next to "onion"
3. Taps "FODMAP substitute available"
4. Sheet opens with full details
5. User quickly reviews options
6. Taps Done
7. Continues reading recipe
```

### Flow 3: Learn About FODMAPs
```
1. User goes to Settings
2. Taps FODMAP Settings
3. Reads "About FODMAP" section
4. Taps "View Quick Reference"
5. Browses by category
6. Saves mental notes
7. Enables FODMAP features
```

## Edge Cases Handled

✅ Recipe with no high FODMAP ingredients → No section shown
✅ Recipe with all high FODMAP ingredients → Shows warning, all listed
✅ FODMAP mode disabled → Features completely hidden
✅ Ingredient with multiple categories → All badges shown
✅ Ingredient with no substitutes → Falls back gracefully
✅ Long ingredient names → Text wraps properly
✅ Many substitutes (>4) → Scrollable list
✅ Offline usage → All data is local

## Summary

The UI is designed to be:
- 📱 **Mobile-first**: Optimized for iPhone
- 🎨 **Beautiful**: Clean, modern design
- 🔍 **Informative**: Clear, helpful guidance
- ⚡ **Fast**: No loading states needed
- ♿ **Accessible**: VoiceOver and Dynamic Type
- 🎯 **Focused**: Only shows when relevant
- 🎓 **Educational**: Teaches while helping
