# Recipe Extraction System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           User Interface                             │
│                                                                       │
│  ┌──────────────────┐        ┌─────────────────────────────────┐   │
│  │ RecipeExtractor  │───────▶│    RecipeDetailView            │   │
│  │      View        │        │  (Display extracted recipe)     │   │
│  │                  │        └─────────────────────────────────┘   │
│  │ • Camera         │                                                │
│  │ • Photo Library  │        ┌─────────────────────────────────┐   │
│  │ • Preprocessing  │───────▶│   ImageComparisonView          │   │
│  │   Toggle         │        │  (Original vs Processed)        │   │
│  └──────────────────┘        └─────────────────────────────────┘   │
└────────────┬──────────────────────────────────────────────────────┘
             │
             │ User Actions
             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        ViewModel Layer                               │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │          RecipeExtractorViewModel                           │    │
│  │                                                              │    │
│  │  @Published Properties:                                     │    │
│  │  • extractedRecipe: RecipeModel?                           │    │
│  │  • isLoading: Bool                                          │    │
│  │  • errorMessage: String?                                    │    │
│  │  • selectedImage: UIImage?                                  │    │
│  │  • processedImage: UIImage?                                 │    │
│  │  • usePreprocessing: Bool                                   │    │
│  │                                                              │    │
│  │  Methods:                                                    │    │
│  │  • extractRecipe(from: UIImage)                            │    │
│  │  • reset()                                                   │    │
│  │  • togglePreprocessing()                                    │    │
│  └──────────────────┬─────────────────────────────────────────┘    │
└─────────────────────┼──────────────────────────────────────────────┘
                      │
                      │ Delegates to
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Service Layer                                 │
│                                                                       │
│  ┌──────────────────┐              ┌───────────────────────────┐   │
│  │ ImagePreprocessor │              │   ClaudeAPIClient         │   │
│  │                   │              │                           │   │
│  │ • preprocessForOCR│              │ • extractRecipe()         │   │
│  │ • preprocessLight │              │ • Network requests        │   │
│  │ • Filters:        │              │ • JSON parsing            │   │
│  │   - Grayscale     │              │ • Error handling          │   │
│  │   - Contrast      │              │                           │   │
│  │   - Sharpening    │              │ Uses:                     │   │
│  │   - Noise reduce  │              │ • URLSession             │   │
│  └──────────────────┘              │ • JSONDecoder             │   │
│                                     └───────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                             │
                                             │ API Request
                                             ▼
                                  ┌──────────────────────┐
                                  │   Claude API         │
                                  │                      │
                                  │ • Vision processing  │
                                  │ • Recipe extraction  │
                                  │ • JSON generation    │
                                  └──────────────────────┘
                                             │
                                             │ JSON Response
                                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          Data Models                                 │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                    RecipeModel                              │    │
│  │  • id: UUID                                                 │    │
│  │  • title: String                                            │    │
│  │  • headerNotes: String?                                     │    │
│  │  • yield: String?                                           │    │
│  │  • ingredientSections: [IngredientSection]                 │    │
│  │  • instructionSections: [InstructionSection]               │    │
│  │  • notes: [RecipeNote]                                      │    │
│  │  • reference: String?                                       │    │
│  │  • imageName: String?                                       │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐    │
│  │IngredientSection │  │InstructionSection│  │  RecipeNote   │    │
│  │                  │  │                  │  │               │    │
│  │• title          │  │• title           │  │• type         │    │
│  │• ingredients[]  │  │• steps[]         │  │• text         │    │
│  │• transitionNote │  └──────────────────┘  └───────────────┘    │
│  └──────────────────┘                                               │
│                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐                        │
│  │   Ingredient     │  │ InstructionStep  │                        │
│  │                  │  │                  │                        │
│  │• quantity        │  │• stepNumber      │                        │
│  │• unit            │  │• text            │                        │
│  │• name            │  └──────────────────┘                        │
│  │• preparation     │                                               │
│  │• metricQuantity  │                                               │
│  │• metricUnit      │                                               │
│  └──────────────────┘                                               │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Image Selection Flow
```
User Action
    │
    ├─ Tap Camera ──────────▶ ImagePicker (camera)
    │                              │
    │                              ▼
    └─ Tap Library ─────────▶ ImagePicker (photoLibrary)
                                   │
                                   ▼
                            ViewModel receives UIImage
                                   │
                                   ▼
                            extractRecipe() triggered
```

### 2. Recipe Extraction Flow
```
extractRecipe(UIImage)
    │
    ├─ usePreprocessing? ───▶ YES ──▶ ImagePreprocessor
    │                                      │
    │                                      ▼
    │                                 preprocessForOCR()
    │                                      │
    │                                      ▼
    │                                 Enhanced Image Data
    │                                      │
    └─────────────────────────────────────┤
                                           ▼
                                  Convert to JPEG Data
                                           │
                                           ▼
                                  Encode as Base64
                                           │
                                           ▼
                                 ClaudeAPIClient.extractRecipe()
                                           │
                                           ▼
                              Build API Request with:
                              • Model: claude-sonnet-4
                              • System prompt (extraction rules)
                              • User prompt (JSON schema)
                              • Image data (base64)
                                           │
                                           ▼
                                  POST to api.anthropic.com
                                           │
                                           ▼
                                  Receive JSON Response
                                           │
                                           ▼
                                  Parse ClaudeResponse
                                           │
                                           ▼
                                  Extract text content
                                           │
                                           ▼
                                  Clean JSON (remove markdown)
                                           │
                                           ▼
                                  Decode RecipeResponse
                                           │
                                           ▼
                                  Convert to RecipeModel
                                           │
                                           ▼
                              Update ViewModel.extractedRecipe
                                           │
                                           ▼
                                  UI updates automatically
                                           │
                                           ▼
                              Navigate to RecipeDetailView
```

### 3. Error Handling Flow
```
Any Step in Flow
    │
    ▼
Error Occurs
    │
    ├─ Network Error ────────────────────▶ ClaudeAPIError.networkError
    │                                            │
    ├─ Invalid API Key ──────────────────▶ ClaudeAPIError.apiError(401)
    │                                            │
    ├─ Rate Limit ───────────────────────▶ ClaudeAPIError.apiError(429)
    │                                            │
    ├─ Invalid JSON ─────────────────────▶ ClaudeAPIError.invalidJSON
    │                                            │
    └─ No Recipe Found ──────────────────▶ ClaudeAPIError.noRecipeFound
                                                 │
                                                 ▼
                                  Update ViewModel.errorMessage
                                                 │
                                                 ▼
                                  Display Error in UI
                                                 │
                                                 ▼
                                  Show "Try Again" button
```

## Component Dependencies

```
RecipeExtractorView
    │
    ├─ depends on ──▶ RecipeExtractorViewModel
    │                     │
    │                     ├─ depends on ──▶ ClaudeAPIClient
    │                     │                     │
    │                     │                     └─ depends on ──▶ URLSession
    │                     │                     └─ depends on ──▶ RecipeModel
    │                     │
    │                     └─ depends on ──▶ ImagePreprocessor
    │                                           │
    │                                           └─ depends on ──▶ Core Image
    │
    ├─ depends on ──▶ ImagePicker
    │                     │
    │                     └─ depends on ──▶ UIImagePickerController
    │
    └─ navigates to ──▶ RecipeDetailView
                            │
                            └─ depends on ──▶ RecipeModel
```

## Key Design Patterns

### 1. MVVM (Model-View-ViewModel)
```
View (RecipeExtractorView)
    ↕ bindings
ViewModel (RecipeExtractorViewModel)
    ↕ calls
Model (RecipeModel) + Services (API, Preprocessor)
```

### 2. Repository Pattern
```
ViewModel
    ↓ uses
ClaudeAPIClient (Repository)
    ↓ abstracts
Claude API (External Service)
```

### 3. Factory Pattern
```
RecipeResponse.toRecipeModel()
    ↓ creates
RecipeModel with all nested objects
```

### 4. Strategy Pattern
```
ImagePreprocessor
    ├─ preprocessForOCR() (Full strategy)
    └─ preprocessLightweight() (Minimal strategy)
```

## State Management

### ViewModel State Machine
```
Initial State
    │
    ▼
Image Selected ──────────────┐
    │                        │
    ▼                        │
Preprocessing (optional)     │
    │                        │
    ▼                        │
Loading ─────────────────────┤
    │                        │
    ├─ Success ──▶ Extracted │──▶ Can Reset
    │                        │
    └─ Error ────▶ Error     │──▶ Can Retry
                             │
                             └──▶ Back to Initial
```

### Published Properties Flow
```
@Published var selectedImage: UIImage?
    │
    ▼ triggers
extractRecipe()
    │
    ▼ sets
@Published var isLoading = true
    │
    ▼ on completion, sets
@Published var extractedRecipe: RecipeModel?
OR
@Published var errorMessage: String?
    │
    ▼ triggers
@Published var isLoading = false
```

## Configuration Hierarchy

```
RecipeExtractorConfig (static defaults)
    │
    ├─ Image Settings
    │   ├─ imageCompressionQuality: 0.9
    │   ├─ contrastLevel: 1.5
    │   └─ sharpnessLevel: 0.7
    │
    ├─ API Settings
    │   ├─ claudeModel: "claude-sonnet-4-20250514"
    │   ├─ maxTokens: 8192
    │   └─ requestTimeout: 60s
    │
    └─ Feature Flags
        ├─ enablePreprocessingToggle: true
        ├─ enableImageComparison: true
        └─ autoExtractOnImageSelection: true

APIKeyStorage (configurable)
    │
    ├─ keychain (recommended)
    ├─ environment (development)
    └─ userDefaults (not recommended)
```

## Security Architecture

```
API Key Protection Layers:

1. Storage Layer
    ├─ Keychain ──────────────▶ Encrypted by iOS
    ├─ Environment ───────────▶ Not in source code
    └─ Never hardcoded ───────▶ Not in version control

2. Access Layer
    ├─ APIKeyHelper ──────────▶ Centralized access
    └─ KeychainManager ───────▶ Secure retrieval

3. Usage Layer
    ├─ ClaudeAPIClient ───────▶ Headers only
    └─ Never logged ──────────▶ Protected in debug
```

## Performance Considerations

### Image Processing
```
Input Image (2-5 MB)
    │
    ▼ Core Image Filters (GPU-accelerated)
Processed Image (~1 second)
    │
    ▼ JPEG Compression (0.9 quality)
Compressed Image (~500 KB)
    │
    ▼ Base64 Encoding
Base64 String (~700 KB)
```

### API Request
```
Request Size: ~700 KB (base64 image) + ~500 bytes (prompts)
Response Size: ~5-15 KB (JSON)
Network Time: 10-30 seconds (varies by API load)
```

### Memory Usage
```
UIImage in memory: ~5-15 MB
Processed CIImage: ~5-15 MB (temporary)
Base64 string: ~1 MB
JSON response: <100 KB
Total peak: ~20-35 MB per extraction
```

## Testing Strategy

```
Unit Tests
    ├─ ImagePreprocessor
    │   ├─ Filter applications
    │   └─ Image format handling
    │
    ├─ RecipeModel
    │   ├─ Codable conformance
    │   └─ Initialization
    │
    └─ KeychainManager
        ├─ Save/retrieve
        └─ Delete operations

Integration Tests
    ├─ ClaudeAPIClient
    │   ├─ Request formatting
    │   ├─ Response parsing
    │   └─ Error handling
    │
    └─ ViewModel
        ├─ State transitions
        └─ Published property updates

UI Tests
    ├─ Image selection flow
    ├─ Preprocessing toggle
    ├─ Recipe display
    └─ Error handling

Manual Tests
    ├─ Various recipe card types
    ├─ Different image qualities
    ├─ Edge cases (missing fields)
    └─ Performance benchmarks
```

---

## Summary

This architecture provides:

✅ **Separation of Concerns** - View, ViewModel, Service, Model layers  
✅ **Testability** - Each component can be tested independently  
✅ **Maintainability** - Clear responsibilities and dependencies  
✅ **Scalability** - Easy to add features (batch processing, editing, etc.)  
✅ **Security** - Proper API key management  
✅ **Performance** - Optimized image processing and network requests  
✅ **User Experience** - Responsive UI with proper error handling  

The system is production-ready and follows iOS best practices.
