# Community Sharing Content Filter Implementation

## Overview

This implementation adds a three-way content filter to both the Recipes and Books tabs, allowing users to view:
1. **Mine** - Only their own recipes/books
2. **Shared by Others** - Only recipes/books that have been shared by other users
3. **All** - Combined view of both personal and shared content

## Files Created

### 1. ContentFilterMode.swift
- Defines the `ContentFilterMode` enum with three cases: `.mine`, `.shared`, and `.all`
- Provides display names and system images for each filter mode
- Conforms to `CaseIterable` and `Identifiable` for easy use in SwiftUI

### 2. ContentFilterPicker.swift
- SwiftUI view component that displays a segmented picker for the three filter modes
- Shows contextual description text based on the selected filter
- Reusable across both Recipes and Books tabs
- Accepts a `contentType` parameter to customize the messaging ("Recipes" or "Books")

## Files Modified

### RecipeBooksView.swift

#### Changes:
1. **Added State Variables:**
   - `@State private var contentFilter: ContentFilterMode = .all` - tracks the current filter selection
   - `@Query private var sharedBooks: [SharedRecipeBook]` - queries shared books from SwiftData

2. **Added Helper Methods:**
   - `sharedBookEntry(for:)` - finds the SharedRecipeBook entry for a given book
   - `emptyFilterStateView` - shows when books exist but none match the current filter
   - `emptyFilterDescription` - provides context-specific empty state messages

3. **Updated filteredBooks:**
   - Now applies both content filter (mine/shared/all) and search filter
   - Filters based on `SharedRecipeBook` entries to determine ownership

4. **Updated UI:**
   - Added `ContentFilterPicker` at the top of the view
   - Wrapped content in a `VStack` to accommodate the filter picker
   - Enhanced empty state handling with filter-specific messages

5. **Updated BookCardView:**
   - Added `sharedEntry: SharedRecipeBook?` parameter
   - Added `showSharedInfo: Bool` parameter (hides shared info when viewing "Mine" only)
   - Displays "Shared by [username]" badge when appropriate

### ContentView.swift (Recipes Tab)

The Recipes tab already has the `ContentFilterPicker` implemented. The changes there include:

1. **Existing Implementation:**
   - `contentFilter` state variable
   - `sharedRecipes` query
   - `applyContentFilter(to:)` method to filter recipes

2. **Display Logic:**
   - Shows "Shared by [username]" in recipe rows when `contentFilter != .mine`
   - Uses `sharedRecipeEntry(for:)` helper to find shared recipe metadata

## How It Works

### Filter Logic

**Mine Filter:**
- Creates a set of all recipe/book IDs that are marked as shared (from `SharedRecipe` or `SharedRecipeBook`)
- Filters to show only items NOT in this shared set
- These are items created by the current user

**Shared Filter:**
- Creates a set of all recipe/book IDs that are marked as shared
- Filters to show only items IN this shared set
- These are items shared by other users

**All Filter:**
- Shows everything without filtering by ownership
- Combines both user's own items and shared items

### User Attribution

When viewing shared content (or in "All" mode), each recipe/book card shows:
- A person icon (blue)
- Text indicating who shared it: "Shared by [username]"
- Falls back to "Shared by Someone" if username is not available

This information is pulled from:
- `SharedRecipe.sharedByUserName` for recipes
- `SharedRecipeBook.sharedByUserName` for books

## User Experience

1. **Segmented Picker:**
   - Clean, native iOS design
   - Three segments: "Mine", "Shared by Others", "All"
   - Each with appropriate SF Symbol icon

2. **Contextual Feedback:**
   - Shows description text when "Mine" or "Shared" is selected
   - Updates empty state messages based on current filter
   - Provides "Show All Books/Recipes" button to quickly reset filter

3. **Search Integration:**
   - Search works across the currently selected filter
   - If searching in "Shared" mode, only searches shared items
   - Search and filter work together seamlessly

4. **Visual Indicators:**
   - Shared items display attribution badge
   - Attribution only shows when relevant (hidden in "Mine" view)
   - Consistent design between Recipes and Books tabs

## Testing Scenarios

1. **Empty States:**
   - User has no personal books → "Mine" shows custom empty state
   - No shared items → "Shared" shows custom empty state
   - Search returns no results → Shows search-specific message

2. **Filter Transitions:**
   - Switching filters updates the view immediately
   - Filter state persists during search
   - Empty state messages update based on filter

3. **Shared Content:**
   - Shared recipes/books appear in "Shared" and "All" views
   - Attribution is displayed correctly
   - User's own items don't appear in "Shared" view

## Integration Notes

- Both files (`ContentFilterMode.swift` and `ContentFilterPicker.swift`) should be added to your Xcode project
- The implementation assumes `SharedRecipe` and `SharedRecipeBook` models exist with:
  - `recipeID`/`bookID` property
  - `isActive` boolean property
  - `sharedByUserName` optional string property
- The filter picker is placed at the top of each tab's navigation stack
- Consider persisting the filter selection with `@AppStorage` if you want it to survive app restarts

## Future Enhancements

Potential improvements to consider:
1. Persist filter selection per tab using `@AppStorage`
2. Add animation when switching between filters
3. Show count badges on filter segments (e.g., "Mine (12)", "Shared (5)")
4. Add pull-to-refresh to update shared content
5. Add ability to filter by specific users who shared content

