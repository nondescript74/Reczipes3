# Debugging Image Display Issues

## Current Problem
Images are assigned in RecipeImageAssignmentView but don't show up in ContentView list or RecipeDetailView.

## Debugging Steps

### Step 1: Check if Assignments are Being Saved

1. Run the app
2. Assign an image to "Lime Pickle"
3. Tap the **🐜 ant icon** (Debug button) in the toolbar
4. Check the debug view:
   - Does it say "Total Assignments: 0" or a number > 0?
   - If 0: Assignments aren't being saved
   - If > 0: Assignments are saved, continue to Step 2

**If no assignments found:**
- Check that `RecipeImageAssignment` is in the schema (Reczipes2App.swift)
- Check that SwiftData isn't using `inMemoryOnly: true`
- Check console for SwiftData errors

### Step 2: Verify Image Names Match

In the debug view, check:
1. The "Image Name" shown (e.g., "AmNC")
2. Try to see if the image displays with the blue border
3. If image shows with broken icon: Image name doesn't exist in Assets

**Fix:**
- Go to Assets.xcassets
- Verify image exists with **exact** name (case-sensitive)
- Example: "AmNC" ≠ "amnc" ≠ "AMNC"

### Step 3: Verify Recipe IDs Match

1. In debug view, compare:
   - "Recipe ID" from assignments section
   - "Recipe ID" from "Recipe IDs from Extensions" section
   
2. Find "Lime Pickle" in both sections
3. Do the UUIDs match?

**If UUIDs don't match:**
This is the problem! The recipe instances are getting new UUIDs each time.

**Why this happens:**
- `RecipeModel.allRecipes` creates NEW instances each time
- Each instance gets a NEW UUID
- Assignment uses one UUID, display uses another
- They never match!

**Solution:**
We need to make recipe IDs stable/consistent.

### Step 4: Check ContentView Query

1. Stop the app
2. Open `ContentView.swift`
3. Verify these lines exist:

```swift
@Query private var imageAssignments: [RecipeImageAssignment]

private func imageName(for recipeID: UUID) -> String? {
    imageAssignments.first { $0.recipeID == recipeID }?.imageName
}

private var availableRecipes: [RecipeModel] {
    RecipeModel.allRecipes.map { recipe in
        if let assignedImageName = imageName(for: recipe.id) {
            return recipe.withImageName(assignedImageName)
        }
        return recipe
    }
}
```

If any are missing: The file didn't save properly

### Step 5: Verify RecipeImageView Exists

1. Open `RecipeImageView.swift`
2. Make sure it's in your Xcode project
3. Make sure it's in the target (check File Inspector)

### Step 6: Check RecipeModel Has Image Support

Open `RecipeModel.swift` and verify:

```swift
struct RecipeModel: Codable, Identifiable, Hashable {
    // ...
    var imageName: String?  // ← Must exist
    // ...
}
```

Also check for `withImageName` method in Extensions.swift:

```swift
func withImageName(_ imageName: String?) -> RecipeModel {
    RecipeModel(
        id: self.id,  // ← Important: Keeps same ID!
        // ...
        imageName: imageName
    )
}
```

## Most Likely Issues

### Issue #1: UUID Mismatch (Most Common)
**Symptom:** Assignments save but never appear
**Cause:** Recipe instances get new UUIDs each time
**Test:** Check debug view - UUIDs won't match
**Fix:** Make recipe IDs stable (see solution below)

### Issue #2: Missing SwiftData Schema
**Symptom:** Nothing saves at all
**Cause:** `RecipeImageAssignment` not in schema
**Test:** Debug view shows 0 assignments always
**Fix:** Add to `Reczipes2App.swift` schema

### Issue #3: Image Names Don't Match Assets
**Symptom:** Placeholder shows instead of image
**Cause:** Typo in image name
**Test:** Check Assets vs. `availableImages` array
**Fix:** Match names exactly (case-sensitive)

### Issue #4: Files Not in Target
**Symptom:** Build errors or crashes
**Cause:** New files not added to app target
**Fix:** Select file → File Inspector → Target Membership

## The UUID Problem Solution

The core issue is likely that `RecipeModel` instances from Extensions get NEW UUIDs each time, so assignments never match.

### Option A: Use Title as Key (Quick Fix)

Change `RecipeImageAssignment`:
```swift
@Model
final class RecipeImageAssignment {
    var recipeTitle: String  // Instead of recipeID
    var imageName: String
}
```

Then match by title instead of ID.

**Pros:** Works immediately
**Cons:** Breaks if recipe titles change

### Option B: Use Stable UUIDs in Extensions (Better)

In Extensions.swift, give each recipe a fixed UUID:

```swift
extension RecipeModel {
    static let limePickleID = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!
    
    static var limePickleExample: RecipeModel {
        RecipeModel(
            id: limePickleID,  // Fixed ID
            title: "Lime Pickle",
            // ...
        )
    }
}
```

**Pros:** Clean, proper solution
**Cons:** Need to define UUID for each recipe

### Option C: Singleton Recipe Collection (Best)

Create a single source of truth:

```swift
// RecipeCollection.swift
class RecipeCollection {
    static let shared = RecipeCollection()
    
    let all: [RecipeModel]
    
    private init() {
        // Create recipes once, never again
        self.all = [
            RecipeModel(id: UUID(), title: "Lime Pickle", ...),
            RecipeModel(id: UUID(), title: "Ambli ni Chutney", ...),
            // ...
        ]
    }
}

// Use everywhere:
RecipeCollection.shared.all
```

**Pros:** UUIDs created once, stable forever
**Cons:** Slight refactor needed

## Immediate Test

To confirm UUID mismatch is the issue:

1. Open debug view
2. Copy a Recipe ID from assignments
3. Compare to Recipe ID in Extensions list
4. If different → UUID mismatch is the problem

## Quick Workaround for Testing

Temporarily change matching to use title:

```swift
// In ContentView
private func imageName(for recipe: RecipeModel) -> String? {
    // Match by title instead of ID (temporary!)
    assignments.first { assignment in
        // Find recipe title from ID somehow...
        // This is hacky but proves the concept
        RecipeModel.allRecipes.first { $0.id == assignment.recipeID }?.title == recipe.title
    }?.imageName
}
```

This is inefficient but proves whether UUID mismatch is the problem.

## Next Steps

1. Run the app
2. Assign an image
3. Tap debug button (🐜)
4. Report back what you see:
   - How many assignments?
   - Do UUIDs match?
   - Do images display in debug view?

This will tell us exactly what's wrong!
