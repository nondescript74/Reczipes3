//
//  INTEGRATION: Add Batch Image Extraction Help to ContextualHelp.swift
//
//  Follow these steps to integrate the help topic into your existing help system
//

/*
 ============================================================================
 STEP 1: Add the HelpTopic static property
 ============================================================================
 
 Add this after the existing extraction topics (around line 160-200):
 */

static let batchImageExtraction = HelpTopic(
    title: "Batch Image Extraction",
    icon: "photo.stack.fill",
    description: """
    Extract multiple recipes at once from images in your Photos library. Perfect for digitizing recipe collections quickly - process up to 10 images at a time with optional cropping.
    """,
    tips: [
        "Tap 'Batch Extract Images' from the Extract tab to get started",
        "Select multiple recipe photos from your Photos library",
        "Toggle 'Crop each image' ON to adjust each photo individually, or OFF for fastest processing",
        "The app processes images sequentially in batches of 10 with progress updates",
        "Use Pause to temporarily stop, Resume to continue, or Stop to cancel the entire batch",
        "Each extraction takes 10-30 seconds per image depending on complexity",
        "All successfully extracted recipes are automatically saved to your collection",
        "Review the error log if any images fail - you can retry them individually later",
        "Start with 3-5 images to learn the workflow before processing larger batches",
        "Best results on WiFi to avoid data charges and ensure stable connection"
    ],
    relatedTopics: ["Recipe Extraction", "Image Preprocessing", "Claude API", "Image Assignment"]
)

/*
 ============================================================================
 STEP 2: Add to allTopics dictionary
 ============================================================================
 
 In the allTopics dictionary (around line 600), add this entry under Image Features:
 */

// Image Features
"imageAssignment": imageAssignment,
"imagePreprocessing": imagePreprocessing,
"batchImageExtraction": batchImageExtraction,  // ← ADD THIS LINE

/*
 ============================================================================
 STEP 3: Add to categories array
 ============================================================================
 
 In the categories array (around line 650), add to "Main Features" or create 
 "Extraction Features" category:
 */

// Option A: Add to existing "Main Features" category
("Main Features", "star.fill", [
    recipesTab,
    extractTab,
    batchImageExtraction,  // ← ADD THIS LINE
    recipeDetail,
    recipeEditing
]),

// Option B: Create new "Extraction Features" category (recommended)
("Extraction Features", "camera.fill", [
    extractTab,
    batchImageExtraction,
    imagePreprocessing
]),

/*
 ============================================================================
 STEP 4: Add Help Button to BatchImageExtractorView
 ============================================================================
 
 In BatchImageExtractorView.swift, add to the NavigationStack's toolbar:
 */

.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Close") {
            if viewModel.isExtracting {
                viewModel.stop()
            }
            dismiss()
        }
    }
    
    // ADD THIS NEW ITEM:
    ToolbarItem(placement: .primaryAction) {
        Button {
            showingHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
        }
    }
}

/*
 ============================================================================
 STEP 5: Add State Variable and Sheet
 ============================================================================
 
 At the top of BatchImageExtractorView, add:
 */

@State private var showingHelp = false

/*
 Then add this sheet modifier after the other sheets:
 */

.sheet(isPresented: $showingHelp) {
    HelpDetailView(topic: AppHelp.batchImageExtraction)
}

/*
 ============================================================================
 STEP 6: Update HELP_TOPICS_QUICK_REFERENCE.md
 ============================================================================
 
 Add this section to the "Main Features" or create "Extraction Features":
 */

### 19. Batch Image Extraction 📚
**What:** Extract multiple recipes at once from Photos library  
**When to use:** Digitizing recipe collections, processing many photos  
**Key tips:**
- Process up to 10 images at a time
- Optional cropping for each image  
- Pause/resume/stop controls available
- Start small (3-5 images) to learn
- Use WiFi for best results
- Each extraction costs ~$0.02
- All successful recipes auto-saved
- Error log shows any failures

/*
 ============================================================================
 STEP 7: Update COMPLETE_APP_HELP_GUIDE.md
 ============================================================================
 
 Add the content from BATCH_IMAGE_EXTRACTION_USER_HELP.md to the 
 appropriate section in COMPLETE_APP_HELP_GUIDE.md
 */

/*
 ============================================================================
 STEP 8: Add to Help Search Terms (if applicable)
 ============================================================================
 
 If you have a search terms file, add these keywords:
 */

"batch", "multiple", "photos", "library", "queue", "pause", 
"resume", "bulk", "collection", "digitize", "many"

/*
 ============================================================================
 COMPLETE EXAMPLE
 ============================================================================
 
 Here's how it all fits together in ContextualHelp.swift:
 */

// In the AppHelp struct, after imagePreprocessing:

static let batchImageExtraction = HelpTopic(
    title: "Batch Image Extraction",
    icon: "photo.stack.fill",
    description: """
    Extract multiple recipes at once from images in your Photos library. Perfect for digitizing recipe collections quickly - process up to 10 images at a time with optional cropping.
    """,
    tips: [
        "Tap 'Batch Extract Images' from the Extract tab to get started",
        "Select multiple recipe photos from your Photos library",
        "Toggle 'Crop each image' ON to adjust each photo individually, or OFF for fastest processing",
        "The app processes images sequentially in batches of 10 with progress updates",
        "Use Pause to temporarily stop, Resume to continue, or Stop to cancel the entire batch",
        "Each extraction takes 10-30 seconds per image depending on complexity",
        "All successfully extracted recipes are automatically saved to your collection",
        "Review the error log if any images fail - you can retry them individually later",
        "Start with 3-5 images to learn the workflow before processing larger batches",
        "Best results on WiFi to avoid data charges and ensure stable connection"
    ],
    relatedTopics: ["Recipe Extraction", "Image Preprocessing", "Claude API", "Image Assignment"]
)

// Then in allTopics:
static let allTopics: [String: HelpTopic] = [
    // ... other topics ...
    
    // Image Features
    "imageAssignment": imageAssignment,
    "imagePreprocessing": imagePreprocessing,
    "batchImageExtraction": batchImageExtraction,
    
    // ... rest of topics ...
]

// Then in categories:
static let categories: [(name: String, icon: String, topics: [HelpTopic])] = [
    // ... other categories ...
    
    ("Extraction Features", "camera.fill", [
        extractTab,
        batchImageExtraction,
        imagePreprocessing,
        claudeAPI
    ]),
    
    // ... rest of categories ...
]

/*
 ============================================================================
 VERIFICATION CHECKLIST
 ============================================================================
 
 After integration, verify:
 
 [ ] Help topic appears in help browser
 [ ] Help icon shows in BatchImageExtractorView toolbar
 [ ] Tapping help icon opens the help detail
 [ ] All 10 tips display correctly
 [ ] Related topics link properly
 [ ] Icon displays correctly (photo.stack.fill)
 [ ] Search finds the topic (if search implemented)
 [ ] Topic appears in correct category
 [ ] HELP_TOPICS_QUICK_REFERENCE.md updated
 [ ] COMPLETE_APP_HELP_GUIDE.md has full section
 
 ============================================================================
 */
