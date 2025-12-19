# Web Recipe Image Extraction - User Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  User enters recipe URL                                          │
│  (e.g., https://www.seriouseats.com/salmon-wellington...)       │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  WebRecipeExtractor.fetchWebContent()                           │
│  - Downloads HTML from URL                                       │
│  - Returns full HTML content                                     │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  WebRecipeExtractor.extractImageURLs()                          │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Priority 1: JSON-LD structured data                       │ │
│  │   <script type="application/ld+json">                     │ │
│  │   { "@type": "Recipe", "image": "https://..." }           │ │
│  ├───────────────────────────────────────────────────────────┤ │
│  │ Priority 2: Open Graph metadata                           │ │
│  │   <meta property="og:image" content="https://...">        │ │
│  ├───────────────────────────────────────────────────────────┤ │
│  │ Priority 3: Image tags (filtered, limit 10)               │ │
│  │   <img src="https://...">                                 │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Returns: ["https://image1.jpg", "https://image2.jpg", ...]     │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  WebRecipeExtractor.cleanHTML()                                 │
│  - Preserves JSON-LD data                                       │
│  - Removes scripts, styles, comments                            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  ClaudeAPIClient.extractRecipe()                                │
│  - Sends cleaned HTML to Claude                                 │
│  - Returns RecipeModel with title, ingredients, instructions    │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  RecipeExtractorViewModel                                       │
│  - Combines recipe data + image URLs                            │
│  - Creates RecipeModel with imageURLs field populated           │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  RecipeExtractorView - Success State                            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ ✅ Recipe Extracted Successfully!                          │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │ Recipe Images Available                                    │ │
│  │ ┌────────────────────────────────────────────────────────┐ │ │
│  │ │ 📷 Select Recipe Image (3 available)                   │ │ │
│  │ └────────────────────────────────────────────────────────┘ │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │ [💾 Save to Collection]                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────────┘
                      │
        ┌─────────────┴──────────────┐
        │                            │
        ▼                            ▼
   User Skips                   User Taps
   Image Selection              "Select Recipe Image"
        │                            │
        │                            ▼
        │              ┌─────────────────────────────────────────┐
        │              │  WebImagePickerView (Sheet)             │
        │              │  ┌─────────────────────────────────────┐│
        │              │  │ [Image 1]  [Image 2]                ││
        │              │  │    ↓          ↓                      ││
        │              │  │ [AsyncLoad] [AsyncLoad]             ││
        │              │  │                                      ││
        │              │  │ [Image 3]  [Image 4]                ││
        │              │  └─────────────────────────────────────┘│
        │              │                                          │
        │              │  [Skip]              [Done] ✓            │
        │              └─────────────────┬────────────────────────┘
        │                                │
        │                                ▼
        │                  User selects Image 2
        │                  selectedWebImageURL = "https://..."
        │                                │
        └────────────────────────────────┘
                      │
                      ▼
        User taps "Save to Collection"
                      │
        ┌─────────────┴─────────────┐
        │                           │
        ▼                           ▼
   No image selected          Image selected
   Save immediately           Download first
        │                           │
        │                           ▼
        │              ┌─────────────────────────────────────────┐
        │              │  WebImageDownloader.downloadImage()     │
        │              │  ┌─────────────────────────────────────┐│
        │              │  │ 1. Validate URL                     ││
        │              │  │ 2. Create URLRequest                ││
        │              │  │ 3. Set User-Agent header            ││
        │              │  │ 4. Download data                    ││
        │              │  │ 5. Convert to UIImage               ││
        │              │  └─────────────────────────────────────┘│
        │              │                                          │
        │              │  Returns: UIImage or throws error        │
        │              └─────────────────┬────────────────────────┘
        │                                │
        └────────────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────────────────────────────────┐
        │  saveRecipe()                                            │
        │  1. Convert RecipeModel to SwiftData Recipe              │
        │  2. Insert into modelContext                             │
        │  3. Save image (downloadedWebImage ?? selectedImage)     │
        │     - Generate unique filename                           │
        │     - Save JPEG to documents directory                   │
        │     - Create RecipeImageAssignment                       │
        │  4. Save context                                         │
        └─────────────────┬───────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────────────────────────────┐
        │  Success Alert                                           │
        │  "Salmon Wellington and its image have been added to     │
        │   your recipe collection."                               │
        │                                                          │
        │  [View in Collection]  [Extract Another]                 │
        └─────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════
ERROR HANDLING PATHS
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  Image Download Fails                                            │
│  - Network error                                                 │
│  - 404 Not Found                                                 │
│  - 403 Forbidden                                                 │
│  - Invalid image data                                            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────────────────────────────────┐
        │  Fallback: Save recipe WITHOUT image                     │
        │  - Recipe data is preserved                              │
        │  - No crash or error shown to user                       │
        │  - Logs error for debugging                              │
        └─────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│  No Images Found                                                 │
│  - imageURLs is empty or nil                                     │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────────────────────────────────┐
        │  UI: Image selection section not shown                   │
        │  - User sees "Save to Collection" button only            │
        │  - Recipe saved without image                            │
        └─────────────────────────────────────────────────────────┘
```

## Key Components

### State Flow
```
RecipeExtractorView State:
├── showWebImagePicker: Bool          (controls sheet)
├── selectedWebImageURL: String?      (user's choice)
├── downloadedWebImage: UIImage?      (cached download)
└── isDownloadingImage: Bool          (loading state)
```

### Data Flow
```
HTML → Image URLs → RecipeModel.imageURLs → WebImagePickerView
                                          ↓
                                    User Selection
                                          ↓
                              WebImageDownloader.downloadImage()
                                          ↓
                                    UIImage saved
```

### Priority System
```
Image URL Extraction Priority:
1. JSON-LD (schema.org Recipe)     → Highest quality, structured
2. og:image meta tags               → Common, reliable
3. <img> tags (filtered)            → Last resort, noisy
```
