# Recipe Image Assignment - Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              USER INTERFACE                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌────────────────┐         ┌──────────────────────────────────────┐   │
│  │  ContentView   │────────▶│  RecipeImageAssignmentView           │   │
│  │                │  Button │                                       │   │
│  │  - Recipe List │  📷     │  ┌────────────────────────────────┐  │   │
│  │  - Toolbar     │         │  │  RecipeImageRow                │  │   │
│  └────────────────┘         │  │  ┌───────┐  Recipe Title       │  │   │
│         │                   │  │  │ Image │  Current: "img.jpg"  │  │   │
│         │                   │  │  │ [60x] │  [✕] [✎]            │  │   │
│         ▼                   │  │  └───────┘                      │  │   │
│  ┌────────────────┐         │  └────────────────────────────────┘  │   │
│  │ RecipeDetail   │         │                                       │   │
│  │  View          │         │         ┌──────────────────────┐     │   │
│  │                │         │         │ ImagePickerSheet     │     │   │
│  │ ┌───────────┐  │         │         │  ┌────┐ ┌────┐ ┌────┐    │   │
│  │ │RecipeImage│  │         │         │  │img1│ │img2│ │img3│    │   │
│  │ │   View    │  │         │         │  └────┘ └────┘ └────┘    │   │
│  │ └───────────┘  │         │         │  ┌────┐ ┌────┐ ┌────┐    │   │
│  │  Title...      │         │         │  │img4│ │img5│ │img6│    │   │
│  │  Instructions  │         │         │  └────┘ └────┘ └────┘    │   │
│  └────────────────┘         │         └──────────────────────┘     │   │
│         │                   └──────────────────────────────────────┘   │
│         │                                    │                          │
└─────────┼────────────────────────────────────┼──────────────────────────┘
          │                                    │
          │                                    │
┌─────────▼────────────────────────────────────▼──────────────────────────┐
│                            BUSINESS LOGIC                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                       RecipeModel                                 │   │
│  │  - id: UUID                                                       │   │
│  │  - title: String                                                  │   │
│  │  - imageName: String?  ◄───── NEW!                               │   │
│  │  - ingredientSections: [IngredientSection]                        │   │
│  │  - instructionSections: [InstructionSection]                      │   │
│  │                                                                    │   │
│  │  func withImageName(_ name: String?) -> RecipeModel               │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                            │                                              │
│                            │ Used by                                      │
│                            ▼                                              │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    Extensions.swift                               │   │
│  │                                                                    │   │
│  │  static var limePickleExample: RecipeModel { ... }                │   │
│  │  static var ambliNiChutney: RecipeModel { ... }                   │   │
│  │  static var carrotPickle: RecipeModel { ... }                     │   │
│  │  ...                                                               │   │
│  │                                                                    │   │
│  │  static var allRecipes: [RecipeModel] {                           │   │
│  │    [ .limePickleExample, .ambliNiChutney, ... ]                   │   │
│  │  }                                                                 │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │
┌───────────────────────────────────▼───────────────────────────────────────┐
│                          PERSISTENCE LAYER                                │
│                             (SwiftData)                                   │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌──────────────────────────┐      ┌─────────────────────────────────┐  │
│  │  Recipe (@Model)         │      │  RecipeImageAssignment (@Model) │  │
│  │  ├─ id: UUID             │      │  ├─ recipeID: UUID              │  │
│  │  ├─ title: String         │      │  └─ imageName: String           │  │
│  │  ├─ imageName: String?    │      │                                 │  │
│  │  ├─ ingredientSections... │      │  ONE-TO-ONE RELATIONSHIP        │  │
│  │  └─ instructionSections...│      │  • Each recipe → one image      │  │
│  │                           │      │  • Each image → one recipe      │  │
│  │  Used for saved recipes   │      │  • No duplicates allowed        │  │
│  └──────────────────────────┘      └─────────────────────────────────┘  │
│           │                                      │                        │
│           │                                      │                        │
│           └──────────────────┬───────────────────┘                        │
│                              │                                            │
│                              ▼                                            │
│                     ┌────────────────┐                                    │
│                     │ ModelContainer │                                    │
│                     │                │                                    │
│                     │ Schema([       │                                    │
│                     │   Recipe.self, │                                    │
│                     │   RecipeImage  │                                    │
│                     │   Assignment   │                                    │
│                     │   .self        │                                    │
│                     │ ])             │                                    │
│                     └────────────────┘                                    │
│                              │                                            │
└──────────────────────────────┼────────────────────────────────────────────┘
                               │
                               ▼
                      ┌─────────────────┐
                      │   SQLite DB     │
                      │  (Local Store)  │
                      └─────────────────┘
                               │
                               ▼
                      ┌─────────────────┐
                      │  iCloud Sync    │
                      │   (Optional)    │
                      └─────────────────┘


═══════════════════════════════════════════════════════════════════════════
                           DATA FLOW DIAGRAM
═══════════════════════════════════════════════════════════════════════════

1. USER ASSIGNS IMAGE
   ┌──────────────────────────────────────────────────────────────────┐
   │ User taps camera button in ContentView                           │
   └────────────────────────┬─────────────────────────────────────────┘
                            ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │ RecipeImageAssignmentView opens                                  │
   │ - Loads all recipes from RecipeModel.allRecipes                  │
   │ - Queries RecipeImageAssignment for existing assignments         │
   └────────────────────────┬─────────────────────────────────────────┘
                            ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │ User selects a recipe and taps + button                          │
   └────────────────────────┬─────────────────────────────────────────┘
                            ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │ ImagePickerSheet shows available images                          │
   │ - Filters out already-assigned images                            │
   │ - Shows current image if one exists                              │
   └────────────────────────┬─────────────────────────────────────────┘
                            ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │ User taps an image                                               │
   └────────────────────────┬─────────────────────────────────────────┘
                            ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │ assignImage() is called                                          │
   │ 1. Delete existing assignment (if any)                           │
   │ 2. Create new RecipeImageAssignment                              │
   │ 3. Insert into modelContext                                      │
   │ 4. SwiftData persists automatically                              │
   └──────────────────────────────────────────────────────────────────┘


2. DISPLAYING IMAGES IN VIEWS
   ┌──────────────────────────────────────────────────────────────────┐
   │ View needs to show recipe image                                  │
   └────────────────────────┬─────────────────────────────────────────┘
                            ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │ Query RecipeImageAssignment for recipe.id                        │
   │ - Get imageName if exists                                        │
   └────────────────────────┬─────────────────────────────────────────┘
                            ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │ Pass imageName to RecipeImageView                                │
   │ - If imageName exists: Load image from Assets                    │
   │ - If nil: Show placeholder                                       │
   └──────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                           IMAGE AVAILABILITY LOGIC
═══════════════════════════════════════════════════════════════════════════

All Images in Assets:
┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐
│img1│ │img2│ │img3│ │img4│ │img5│ │img6│
└────┘ └────┘ └────┘ └────┘ └────┘ └────┘

Current Assignments:
Recipe A → img1
Recipe B → img3
Recipe C → img5

When editing Recipe A:
Available: [img1, img2, img4, img6]  ✅ Includes current (img1)
           ───  ───  ───  ───        ❌ Excludes others' (img3, img5)

When editing Recipe D (unassigned):
Available: [img2, img4, img6]        ❌ Only unassigned images
           ───  ───  ───

When user assigns img2 to Recipe D:
Recipe A → img1
Recipe B → img3
Recipe C → img5
Recipe D → img2  ✅ New assignment

Now when editing Recipe E:
Available: [img4, img6]              ❌ img2 now excluded
           ───  ───


═══════════════════════════════════════════════════════════════════════════
                              KEY COMPONENTS
═══════════════════════════════════════════════════════════════════════════

┌──────────────────────────────────────────────────────────────────────────┐
│ RecipeImageView (Reusable Component)                                     │
├──────────────────────────────────────────────────────────────────────────┤
│ Purpose: Display recipe image with fallback                              │
│ Input:   imageName (optional String)                                     │
│ Output:  Image or placeholder                                            │
│ Usage:   RecipeImageView(imageName: recipe.imageName)                    │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│ RecipeImageAssignment (Model)                                            │
├──────────────────────────────────────────────────────────────────────────┤
│ Purpose: Store recipe-to-image mappings                                  │
│ Storage: SwiftData (persisted, synced)                                   │
│ Constraint: Unique by recipeID                                           │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│ RecipeImageAssignmentView (Editor)                                       │
├──────────────────────────────────────────────────────────────────────────┤
│ Purpose: UI for managing assignments                                     │
│ Features: List, thumbnails, picker, search                               │
│ Access: Toolbar button in ContentView                                    │
└──────────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                          EXTENSION OPPORTUNITIES
═══════════════════════════════════════════════════════════════════════════

Future Enhancements:

1. Multiple Images per Recipe
   RecipeImageAssignment {
     recipeID: UUID
     imageName: String
     imageType: ImageType  // .hero, .step1, .step2, .final
     order: Int
   }

2. Photo Library Support
   - Add PHPickerViewController integration
   - Store photos in Documents directory
   - Reference by file path instead of asset name

3. Remote Images
   - Add imageURL property
   - Download and cache
   - Fallback to local assets

4. Image Metadata
   RecipeImageAssignment {
     recipeID: UUID
     imageName: String
     caption: String?
     photographer: String?
     dateAdded: Date
     tags: [String]
   }

5. Auto-matching
   - Fuzzy match image names with recipe titles
   - Suggest assignments
   - Batch assign button

6. Export/Import
   - Export assignments as JSON
   - Share between devices/users
   - Backup and restore
```
