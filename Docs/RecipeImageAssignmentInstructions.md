//
//  RecipeImageAssignmentInstructions.md
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

# Recipe Image Assignment System

This document explains how to use the Recipe Image Assignment system in Reczipes2.

## Overview

The app now supports associating images from your Assets catalog with recipes. Each recipe can have one image, and each image can only be assigned to one recipe at a time.

## Components

### 1. Updated Models

**RecipeModel** now includes:
- `imageName: String?` - Optional name of the image in Assets catalog

**Recipe** (SwiftData) now includes:
- `imageName: String?` - Persisted image name

**RecipeImageAssignment** (SwiftData):
- Stores the mapping between recipe IDs and image names
- Ensures each image is only assigned once

### 2. RecipeImageAssignmentView

A dedicated view for managing recipe-image associations with:
- Grid layout showing all recipes
- Current image thumbnail (if assigned)
- Buttons to add/change/remove images
- Image picker sheet with visual selection
- Search functionality for finding images

## How to Use

### Step 1: Add Your Images to Assets

1. Open your Assets catalog in Xcode
2. Add all recipe images
3. Note the names you give to each image

### Step 2: Update Available Images List

In `RecipeImageAssignmentView.swift`, update the `availableImages` array with your actual image names:

```swift
@State private var availableImages: [String] = [
    "lime-pickle",
    "tamarind-chutney",
    "carrot-pickle",
    // ... add all your image names here
]
```

### Step 3: Access the Assignment View

1. Launch the app
2. Tap the "Assign Images" button in the toolbar (camera icon)
3. You'll see a list of all recipes

### Step 4: Assign Images to Recipes

For each recipe:
1. Tap the **+** button (or pencil if already assigned) next to the recipe
2. Browse or search for the desired image
3. Tap an image to assign it
4. The image is now linked to that recipe and removed from other recipes' available options

### Step 5: Remove Image Assignments

To remove an image from a recipe:
1. Tap the **X** button next to the assigned image
2. The image becomes available for other recipes again

## Features

### Smart Image Availability
- Images are only shown as available if they're not already assigned to another recipe
- The currently assigned image (if any) always appears in the picker for that recipe
- Once you assign an image, it's immediately removed from other recipes' selection lists

### Visual Feedback
- Thumbnails show the currently assigned image
- Placeholders appear for recipes without images
- Selected images are highlighted with a blue border
- Image names are displayed below thumbnails

### Search
- Type in the search field to filter images by name
- Useful when you have many images

### Persistence
- All assignments are saved to SwiftData
- Assignments persist across app launches
- Works seamlessly with iCloud sync if enabled

## Integration with App

The image assignments are stored separately from the recipe definitions in Extensions.swift. This means:
- You can update Extensions.swift without affecting image assignments
- Image assignments are user-specific and stored locally
- The same recipe can have different images on different devices (if not using iCloud)

## Technical Details

### Data Flow

1. **RecipeModel** definitions in Extensions.swift (static data)
2. **RecipeImageAssignment** in SwiftData (user assignments)
3. When displaying recipes, the app merges:
   - Static recipe data from Extensions
   - Dynamic image assignments from SwiftData
   - Results in RecipeModel instances with imageName populated

### Model Schema

```swift
RecipeImageAssignment {
    recipeID: UUID     // Links to RecipeModel.id
    imageName: String  // Name in Assets catalog
}
```

Each assignment is unique by recipeID, ensuring one-to-one mapping.

## Tips

1. **Naming Convention**: Use consistent naming for images (e.g., "recipe-name" format)
2. **Image Quality**: Use high-resolution images (at least 2x for Retina displays)
3. **Aspect Ratio**: Square or 4:3 images work best for thumbnails
4. **File Format**: PNG for transparency, JPEG for photos

## Troubleshooting

**Images not appearing?**
- Verify image names in Assets match exactly (case-sensitive)
- Check that images are added to the correct target
- Ensure images are in the main asset catalog

**Assignment not saving?**
- Check that modelContext is properly configured
- Verify SwiftData schema includes RecipeImageAssignment

**Image shows for wrong recipe?**
- Each recipe has a unique UUID
- Assignments use recipe.id, which is stable
- If you see wrong images, check for duplicate recipe IDs
