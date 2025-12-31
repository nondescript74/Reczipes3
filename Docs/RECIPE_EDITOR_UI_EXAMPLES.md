# Recipe Editor UI Examples

This document shows what the new Recipe Editor interface looks like.

## Main Hub Screen

```
┌─────────────────────────────────────┐
│  ← Edit Recipe              ☁️ Save │
├─────────────────────────────────────┤
│                                     │
│  Chocolate Chip Cookies             │
│  ⚠️ You have unsaved changes        │
│                                     │
├─────────────────────────────────────┤
│  Edit your recipe by tapping on     │
│  any section below. Each part of    │
│  your recipe can be edited in its   │
│  own dedicated view.                │
├─────────────────────────────────────┤
│                                     │
│  ESSENTIAL DETAILS                  │
│                                     │
│  ┌────┐  Basic Information      ✓  │
│  │ ℹ️ │  Title, notes, yield,   >  │
│  └────┘  and reference             │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  WHAT YOU'LL NEED                   │
│                                     │
│  ┌────┐  Ingredients            ✓  │
│  │ 📋 │  15 ingredients in      >  │
│  └────┘  2 sections                │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  HOW TO MAKE IT                     │
│                                     │
│  ┌────┐  Instructions           ✓  │
│  │ 🔢 │  8 steps in 2          >  │
│  └────┘  sections                  │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ADDITIONAL INFORMATION             │
│                                     │
│  ┌────┐  Notes & Tips               │
│  │ 📝 │  3 notes               >   │
│  └────┘                            │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  VISUAL CONTENT                     │
│                                     │
│  ┌────┐  Images                 ✓  │
│  │ 🖼️ │  2 images              >   │
│  └────┘                            │
│                                     │
│  Add additional photos to           │
│  complement your recipe             │
│                                     │
└─────────────────────────────────────┘
```

## Basic Information View

```
┌─────────────────────────────────────┐
│  ← Basic Information         Done   │
├─────────────────────────────────────┤
│                                     │
│  RECIPE TITLE                       │
│  ┌─────────────────────────────┐   │
│  │ Chocolate Chip Cookies      │   │
│  └─────────────────────────────┘   │
│  Give your recipe a memorable name  │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  HEADER NOTES                       │
│  ┌─────────────────────────────┐   │
│  │ These are the best cookies  │   │
│  │ you'll ever make! Crispy    │   │
│  │ edges with chewy centers.   │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│  Add a brief description or         │
│  introduction to your recipe        │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  YIELD                              │
│  ┌─────────────────────────────┐   │
│  │ Makes 24 cookies            │   │
│  └─────────────────────────────┘   │
│  How many servings or portions      │
│  does this recipe make?             │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  REFERENCE                          │
│  ┌─────────────────────────────┐   │
│  │ Grandma's recipe book       │   │
│  └─────────────────────────────┘   │
│  Where did you find this recipe?    │
│                                     │
└─────────────────────────────────────┘
```

## Ingredients List View

```
┌─────────────────────────────────────┐
│  ← Ingredients        Edit  + Done  │
├─────────────────────────────────────┤
│                                     │
│  Dry Ingredients                    │
│  8 ingredients                   >  │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Wet Ingredients                    │
│  7 ingredients                   >  │
│                                     │
└─────────────────────────────────────┘
```

## Ingredient Section Detail View

```
┌─────────────────────────────────────┐
│  ← Edit Section         Edit  Done  │
├─────────────────────────────────────┤
│                                     │
│  SECTION TITLE                      │
│  ┌─────────────────────────────┐   │
│  │ Dry Ingredients             │   │
│  └─────────────────────────────┘   │
│  e.g., 'For the Dough', 'Sauce      │
│  Ingredients', or leave blank       │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  INGREDIENTS                        │
│                                     │
│  All-purpose flour               >  │
│  2 1/4 cups                         │
│                                     │
│  Baking soda                     >  │
│  1 teaspoon                         │
│                                     │
│  Salt                            >  │
│  1 teaspoon                         │
│                                     │
│  ➕ Add Ingredient                  │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  TRANSITION NOTE                    │
│  ┌─────────────────────────────┐   │
│  │ Mix dry ingredients and set │   │
│  │ aside                       │   │
│  └─────────────────────────────┘   │
│  Add a note that appears after this │
│  ingredient section                 │
│                                     │
└─────────────────────────────────────┘
```

## Individual Ingredient Detail View

```
┌─────────────────────────────────────┐
│  ← Edit Ingredient           Done   │
├─────────────────────────────────────┤
│                                     │
│  INGREDIENT NAME                    │
│  ┌─────────────────────────────┐   │
│  │ All-purpose flour           │   │
│  └─────────────────────────────┘   │
│  e.g., 'All-purpose flour',         │
│  'Eggs', 'Olive oil'                │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  QUANTITY                           │
│  ┌──────────┬──────────────────┐   │
│  │ 2 1/4    │  cups            │   │
│  └──────────┴──────────────────┘   │
│  Enter the amount and unit          │
│  (e.g., '2' 'cups')                 │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  PREPARATION                        │
│  ┌─────────────────────────────┐   │
│  │ sifted                      │   │
│  └─────────────────────────────┘   │
│  How should this ingredient be      │
│  prepared? (e.g., 'diced',          │
│  'beaten', 'at room temperature')   │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  METRIC CONVERSION (OPTIONAL)       │
│  ┌──────────┬──────────────────┐   │
│  │ 280      │  grams           │   │
│  └──────────┴──────────────────┘   │
│  Provide metric measurements for    │
│  international users                │
│                                     │
└─────────────────────────────────────┘
```

## Instructions List View (Empty State)

```
┌─────────────────────────────────────┐
│  ← Instructions       Edit  + Done  │
├─────────────────────────────────────┤
│                                     │
│                                     │
│            🔢                        │
│                                     │
│     No Instructions Yet             │
│                                     │
│  Tap the + button to add your       │
│  first instruction section          │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

## Instruction Section Detail View

```
┌─────────────────────────────────────┐
│  ← Edit Section         Edit  Done  │
├─────────────────────────────────────┤
│                                     │
│  SECTION TITLE                      │
│  ┌─────────────────────────────┐   │
│  │ Baking Instructions         │   │
│  └─────────────────────────────┘   │
│  e.g., 'Preparing the Dough',       │
│  'Baking Instructions'              │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  STEPS                              │
│                                     │
│  1  Preheat oven to 375°F.      >  │
│      Place rack in center...        │
│                                     │
│  2  Drop rounded tablespoons    >  │
│      of dough onto baking...        │
│                                     │
│  3  Bake for 9-11 minutes       >  │
│      until golden brown...          │
│                                     │
│  ➕ Add Step                         │
│                                     │
└─────────────────────────────────────┘
```

## Instruction Step Detail View

```
┌─────────────────────────────────────┐
│  ← Edit Step                 Done   │
├─────────────────────────────────────┤
│                                     │
│  STEP NUMBER                        │
│  ┌─────────────────────────────┐   │
│  │ 1                           │   │
│  └─────────────────────────────┘   │
│  Optional - Steps will be numbered  │
│  automatically if left blank        │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  INSTRUCTIONS                       │
│  ┌─────────────────────────────┐   │
│  │ Preheat oven to 375°F       │   │
│  │ (190°C). Position rack in   │   │
│  │ the center of the oven.     │   │
│  │                             │   │
│  │ Line two large baking       │   │
│  │ sheets with parchment       │   │
│  │ paper or silicone mats.     │   │
│  │                             │   │
│  │                             │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│  Describe what needs to be done     │
│  in this step. Be clear and         │
│  detailed.                          │
│                                     │
└─────────────────────────────────────┘
```

## Notes List View

```
┌─────────────────────────────────────┐
│  ← Notes & Tips       Edit  + Done  │
├─────────────────────────────────────┤
│                                     │
│  💡  TIP                            │
│      For extra chewy cookies,    >  │
│      chill the dough for 30...      │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ↔️  SUBSTITUTION                   │
│      You can use dark chocolate  >  │
│      chips instead of semi...       │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ⚠️  WARNING                        │
│      Don't overbake! Cookies     >  │
│      will look slightly...          │
│                                     │
└─────────────────────────────────────┘
```

## Note Detail View

```
┌─────────────────────────────────────┐
│  ← Edit Note                 Done   │
├─────────────────────────────────────┤
│                                     │
│  TYPE                               │
│                                     │
│  ○ 📝 General                       │
│  ● 💡 Tip                  ✓        │
│  ○ ↔️ Substitution                  │
│  ○ ⚠️ Warning                       │
│  ○ 🕐 Timing                        │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  NOTE CONTENT                       │
│  ┌─────────────────────────────┐   │
│  │ For extra chewy cookies,    │   │
│  │ chill the dough in the      │   │
│  │ refrigerator for 30 minutes │   │
│  │ before baking.              │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│  Helpful tips to improve the        │
│  recipe or technique                │
│                                     │
└─────────────────────────────────────┘
```

## Images View

```
┌─────────────────────────────────────┐
│  ← Images                    Done   │
├─────────────────────────────────────┤
│                                     │
│  The main recipe image is set       │
│  during extraction. You can add     │
│  additional photos here.            │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  MAIN IMAGE                         │
│                                     │
│    ┌─────────────────────────┐     │
│    │                         │     │
│    │    [Recipe Photo]       │     │
│    │                         │     │
│    │                         │     │
│    └─────────────────────────┘     │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ADDITIONAL IMAGES                  │
│                                     │
│   ┌──────────┐  ┌──────────┐      │
│   │  [Step   │  │  [Final  │      │
│   │   Photo] │  │  Result] │      │
│   └──────────┘  └──────────┘      │
│                                     │
└─────────────────────────────────────┘
```

## Color Scheme

### Section Icons and Colors
- **Basic Information** - Blue (ℹ️)
- **Ingredients** - Green (📋)
- **Instructions** - Orange (🔢)
- **Notes** - Purple (📝)
- **Images** - Pink (🖼️)

### Note Type Icons and Colors
- **General** - Blue (📝)
- **Tip** - Yellow (💡)
- **Substitution** - Green (↔️)
- **Warning** - Red (⚠️)
- **Timing** - Orange (🕐)

## Adaptive Layouts

### iPhone (Compact)
- Single column layout
- Full-width form fields
- Stacked navigation
- Bottom toolbar

### iPad (Regular)
- Wider form fields with max width
- More padding and spacing
- Potential for split view (future)
- Top toolbar

### Mac
- Native macOS styling
- Keyboard navigation support
- Menu bar integration
- Proper window sizing

## Interaction Patterns

### Navigation
- Tap any section row to drill into details
- Back button returns to previous level
- Done button completes editing and returns

### Editing
- Tap text fields to edit inline
- Long-press for additional options
- Swipe left on list items to delete
- Drag handles to reorder (in Edit mode)

### State Indicators
- Green checkmark for completed sections
- Orange warning for unsaved changes
- Blue info icons for help
- Red badges for errors/required fields

## Accessibility

All views include:
- Proper labels for VoiceOver
- Dynamic Type support
- High contrast mode support
- Reduced motion support
- Keyboard navigation (Mac)
- VoiceOver hints for actions
