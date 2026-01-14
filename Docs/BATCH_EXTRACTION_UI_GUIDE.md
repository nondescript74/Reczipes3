# Batch Extraction UI Guide

## User Flow

### Step 1: Extract View - Source Selection
```
┌─────────────────────────────────────┐
│     Choose Recipe Extraction        │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │ 📷       │  │ 🖼️       │        │
│  │ Camera   │  │ Library  │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌─────────────────────────┐       │
│  │ 🌐 Web URL              │       │
│  │ Extract from website    │       │
│  └─────────────────────────┘       │
│                                     │
│  ┌─────────────────────────┐ ← NEW │
│  │ 📚 Batch Extract        │       │
│  │ Extract multiple from   │       │
│  │ saved links             │       │
│  └─────────────────────────┘       │
└─────────────────────────────────────┘
```

### Step 2: Batch Extraction View - Before Starting
```
┌─────────────────────────────────────┐
│ ← Batch Extract            Close    │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📚 Batch Extraction         │   │
│  │ 12 links ready to extract   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    ▶️ Start Batch Extract   │   │
│  └─────────────────────────────┘   │
│                                     │
│  Saved Links (12 unprocessed)      │
│  ┌─────────────────────────────┐   │
│  │ 🔗 Chocolate Chip Cookies   │   │
│  │    example.com/cookies      │   │
│  ├─────────────────────────────┤   │
│  │ 🔗 Banana Bread             │   │
│  │    recipes.com/banana       │   │
│  ├─────────────────────────────┤   │
│  │ 🔗 Pasta Carbonara          │   │
│  │    cooking.com/pasta        │   │
│  └─────────────────────────────┘   │
│  ... and 9 more                    │
└─────────────────────────────────────┘
```

### Step 3: During Extraction
```
┌─────────────────────────────────────┐
│ ← Batch Extract            Close    │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📚 Batch Extraction         │   │
│  │ 12 links ready to extract   │   │
│  │ ────────────────────────    │   │
│  │ 3/12    ✓ 2    ✗ 1         │   │
│  │ Progress Success Failed     │   │
│  └─────────────────────────────┘   │
│                                     │
│  Current Extraction:                │
│  ┌─────────────────────────────┐   │
│  │ ⬇️ Extracting...            │   │
│  │ Pasta Carbonara             │   │
│  │ cooking.com/pasta           │   │
│  │ ▓▓▓▓░░░░░░░░░░ 25%         │   │
│  │ Downloading 2 images...     │   │
│  │ ────────────────────────    │   │
│  │ ✓ Extracted: Pasta Carbonara│   │
│  │   ✓ 1 ingredient section    │   │
│  │   ✓ 1 instruction section   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │ ⏸️ Pause │  │ ⏹️ Stop  │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  Saved Links (9 unprocessed)       │
│  ┌─────────────────────────────┐   │
│  │ 🔗 Chocolate Chip Cookies   │   │
│  ├─────────────────────────────┤   │
│  │ 🔗 Banana Bread             │   │
│  ├─────────────────────────────┤   │
│  │ 🔗 Pasta Carbonara     ⏳   │ ← Current
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Step 4: Completion Alert
```
┌─────────────────────────────────────┐
│                                     │
│  ┌───────────────────────────┐     │
│  │ Batch Extraction Complete │     │
│  │                           │     │
│  │ Extracted 10 recipes      │     │
│  │ successfully with 2       │     │
│  │ failures.                 │     │
│  │                           │     │
│  │  ┌───────────────────┐    │     │
│  │  │  View Recipes     │    │     │
│  │  └───────────────────┘    │     │
│  │  ┌───────────────────┐    │     │
│  │  │       OK          │    │     │
│  │  └───────────────────┘    │     │
│  └───────────────────────────┘     │
└─────────────────────────────────────┘
```

### Step 5: Error Log (if failures occurred)
```
┌─────────────────────────────────────┐
│                                     │
│  Errors (2)                         │
│  ⚠️                                 │
│  ┌─────────────────────────────┐   │
│  │ Thai Green Curry            │   │
│  │ Network timeout error       │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Beef Wellington             │   │
│  │ No recipe extracted         │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Color Scheme

- **Purple**: Batch extraction theme color
- **Blue**: Currently extracting
- **Green**: Success states
- **Red**: Error states
- **Orange**: Pause state

## Icons Used

- `square.stack.3d.up.fill` - Batch extraction icon
- `link.circle.fill` - Saved link icon
- `arrow.down.circle.fill` - Currently extracting
- `checkmark.circle.fill` - Success
- `exclamationmark.triangle.fill` - Errors
- `play.fill` - Start/Resume
- `pause.fill` - Pause
- `stop.fill` - Stop

## Interaction Details

### Buttons:
1. **Start Batch Extract**
   - Disabled when no unprocessed links
   - Starts sequential extraction process
   
2. **Pause**
   - Pauses after current recipe completes
   - Changes to "Resume" button
   
3. **Resume**
   - Continues from where it paused
   - Changes back to "Pause" button
   
4. **Stop**
   - Immediately cancels extraction
   - Keeps already extracted recipes
   
5. **Close**
   - Stops extraction if running
   - Dismisses the view

### Progress Indicators:
- **Linear Progress Bar**: Shows overall progress (X/Y)
- **Stats Display**: Real-time success/failure counts
- **Current Recipe**: Shows what's being extracted now
- **Spinner**: Shown next to current link in list

### Status Messages:
- "Fetching recipe page..."
- "Analyzing with Claude AI..."
- "Downloading images..."
- "Saving recipe..."
- "Waiting 5 seconds before next extraction..."
- "Complete"
- "Paused"
- "Stopped"

## Responsive Behavior

### Empty State:
- Shown when no saved links exist
- Large icon and helpful message
- "Close" button to dismiss

### Small Batches (< 5 links):
- All links shown in preview

### Large Batches (> 5 links):
- First 5 links shown
- "... and X more" message

### During Extraction:
- Control buttons replace start button
- Current extraction card appears
- Progress stats shown
- Current link highlighted in list

### On Completion:
- Alert shown with summary
- "View Recipes" dismisses to collection
- "OK" stays in batch view (allows restart)

## Accessibility

- All buttons have clear labels
- Icons paired with text
- Progress communicated via text
- Colors not sole indicator of state
- VoiceOver friendly layout
- Dynamic Type support

## Performance Notes

- Links load via SwiftData @Query (automatic updates)
- Only first 5 links rendered in preview
- Recipe model is lightweight
- Images downloaded sequentially
- 5-second delay prevents rate limiting
- Cancellation is immediate
