# Claude Recipe Extractor - Quick Start Guide

## 📦 What You Got

A complete iOS SwiftUI implementation for extracting recipes from images using Claude's vision API.

### Files Created (9 total)

1. **ImagePreprocessor.swift** - Image enhancement for better OCR
2. **ClaudeAPIClient.swift** - Claude API integration  
3. **RecipeExtractorViewModel.swift** - State management
4. **RecipeExtractorView.swift** - Main UI
5. **RecipeDetailView.swift** - Recipe display
6. **ImagePicker.swift** - Camera/photo library
7. **RecipeExtractorConfig.swift** - Configuration & API key management
8. **ExampleAppIntegration.swift** - Full app integration example
9. **RecipeExtractorTests.swift** - Testing utilities

## 🚀 Quick Setup (5 minutes)

### 1. Add Files to Xcode
Drag all `.swift` files into your Xcode project.

### 2. Update Info.plist
```xml
<key>NSCameraUsageDescription</key>
<string>Take photos of recipe cards</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Select recipe images</string>
```

### 3. Configure API Key (Choose ONE)

**Option A - Keychain (Recommended)**
```swift
// First time setup
KeychainManager.shared.save(key: "claudeAPIKey", value: "sk-ant-api03-...")

// Use in app
if let apiKey = KeychainManager.shared.get(key: "claudeAPIKey") {
    RecipeExtractorView(apiKey: apiKey)
}
```

**Option B - Environment Variable (Development)**
```
Xcode → Edit Scheme → Run → Environment Variables
Name: CLAUDE_API_KEY
Value: sk-ant-api03-...
```

### 4. Add to Your App
```swift
TabView {
    RecipeListView()
        .tabItem { Label("Recipes", systemImage: "book.fill") }
    
    if let apiKey = APIKeyHelper.getAPIKey() {
        RecipeExtractorView(apiKey: apiKey)
            .tabItem { Label("Extract", systemImage: "camera.fill") }
    }
}
```

## 📱 How It Works

```
User selects image → Image preprocessed → Sent to Claude → 
Recipe extracted → Displayed in RecipeDetailView
```

### What Gets Extracted
✅ Recipe title & description  
✅ Multiple ingredient sections  
✅ Multiple instruction sections  
✅ Yield/servings  
✅ Metric conversions  
✅ Preparation notes  
✅ Recipe notes & tips  
✅ References  

### Image Preprocessing
- **Grayscale** - Reduces noise
- **Contrast** - Makes text clearer (+50%)
- **Sharpening** - Better character recognition
- **Noise Reduction** - Cleans faded images

## 🎯 Usage Examples

### Basic Integration
```swift
struct ContentView: View {
    var body: some View {
        if let apiKey = APIKeyHelper.getAPIKey() {
            RecipeExtractorView(apiKey: apiKey)
        }
    }
}
```

### With Save Functionality
```swift
struct MyRecipeExtractorView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    let apiKey: String
    
    var body: some View {
        RecipeExtractorView(apiKey: apiKey)
            .toolbar {
                Button("Save") {
                    // Save extracted recipe
                }
            }
    }
}
```

### Custom Configuration
```swift
// In RecipeExtractorConfig.swift
static let contrastLevel: Float = 1.8  // More contrast
static let sharpnessLevel: Float = 0.9  // More sharpening
static let autoExtractOnImageSelection = false  // Manual trigger
```

## 💰 Costs

**Claude Sonnet 4 Pricing:**
- ~$0.02 per recipe extraction
- Based on ~2,000 input tokens + ~1,000 output tokens

**Tips to Minimize Costs:**
- Cache commonly used recipes
- Batch process when possible
- Use preprocessing to reduce retries

## 🐛 Troubleshooting

### "No recipe could be extracted"
- ✅ Enable preprocessing
- ✅ Ensure text is legible
- ✅ Check image quality

### "API Error (401)"
- ✅ Verify API key is correct
- ✅ Check key starts with `sk-ant-`
- ✅ Ensure key is properly stored

### "API Error (429)"
- ✅ Rate limit hit
- ✅ Wait and retry
- ✅ Implement request throttling

### Preprocessing Makes It Worse
- ✅ Disable for high-quality images
- ✅ Try lightweight preprocessing
- ✅ Adjust contrast/sharpness levels

## 📊 Testing Your Integration

### Manual Test Checklist
```
[ ] Camera opens
[ ] Photo library opens
[ ] Image displays correctly
[ ] Preprocessing toggle works
[ ] Extraction completes
[ ] Recipe displays properly
[ ] Can save recipe
[ ] Error handling works
```

### Test Images
Use `TestImageGenerator.generateTestRecipeImage()` for basic testing.

### Performance Benchmarks
- Image preprocessing: < 2 seconds
- API request: 10-30 seconds
- Total extraction: 15-35 seconds

## 🔒 Security Checklist

```
[ ] API key NOT in source code
[ ] API key NOT in version control
[ ] Using Keychain or environment variable
[ ] Info.plist descriptions added
[ ] Rate limiting considered
[ ] Monitoring API usage
```

## 🎨 Customization Points

### 1. Preprocessing Levels
Edit `ImagePreprocessor.swift`:
```swift
filter.contrast = 1.8  // Adjust contrast
filter.sharpness = 0.9  // Adjust sharpness
```

### 2. Extraction Prompt
Edit `ClaudeAPIClient.swift` system prompt to:
- Add custom fields
- Change extraction rules
- Adjust JSON schema

### 3. UI Appearance
Modify `RecipeExtractorView.swift` and `RecipeDetailView.swift` for:
- Custom colors
- Different layouts
- Additional features

### 4. Recipe Model
Your existing `RecipeModel.swift` already supports:
- Multiple ingredient sections
- Multiple instruction sections
- Various note types
- Metric conversions
- All necessary fields

## 📝 Key Files Explained

### ImagePreprocessor.swift
Enhances images before sending to Claude. Two modes:
- `preprocessForOCR()` - Full enhancement (grayscale + contrast + sharpen)
- `preprocessLightweight()` - Color-preserving (contrast + sharpen)

### ClaudeAPIClient.swift
Handles API communication. Key methods:
- `extractRecipe()` - Main extraction method
- `extractJSON()` - Parses Claude's response
- Converts API response to `RecipeModel`

### RecipeExtractorViewModel.swift
Manages app state:
- Loading states
- Error handling
- Image selection
- Preprocessing toggle

### RecipeExtractorView.swift
Main UI with:
- Image picker integration
- Preprocessing controls
- Loading indicators
- Error displays
- Navigation to detail view

### RecipeDetailView.swift
Displays extracted recipe with:
- Formatted sections
- Ingredient lists
- Numbered instructions
- Color-coded notes
- Share functionality

## 🔧 Advanced Features

### Add Editing
```swift
struct EditableRecipeView: View {
    @State var recipe: RecipeModel
    @State var isEditing = false
    
    var body: some View {
        if isEditing {
            RecipeEditorView(recipe: $recipe)
        } else {
            RecipeDetailView(recipe: recipe)
        }
    }
}
```

### Batch Processing
```swift
func extractMultipleRecipes(_ images: [UIImage]) async -> [RecipeModel] {
    await withTaskGroup(of: RecipeModel?.self) { group in
        for image in images {
            group.addTask {
                try? await viewModel.extractRecipe(from: image)
            }
        }
        
        var recipes: [RecipeModel] = []
        for await recipe in group {
            if let recipe = recipe {
                recipes.append(recipe)
            }
        }
        return recipes
    }
}
```

### Add Core Data
```swift
extension RecipeModel {
    func toCoreData(context: NSManagedObjectContext) -> RecipeEntity {
        let entity = RecipeEntity(context: context)
        entity.id = self.id
        entity.title = self.title
        // ... map other fields
        return entity
    }
}
```

## 📚 Additional Resources

- **Claude API Docs**: https://docs.anthropic.com
- **SwiftUI**: https://developer.apple.com/xcode/swiftui/
- **Image Processing**: https://developer.apple.com/documentation/coreimage

## 🆘 Need Help?

Common issues and solutions are in:
- `IMPLEMENTATION_GUIDE.md` - Detailed setup
- `RecipeExtractorTests.swift` - Testing examples
- `ExampleAppIntegration.swift` - Integration patterns

## ✨ What's Next?

Enhance your implementation:
1. Add Core Data persistence
2. Implement recipe editing
3. Add recipe sharing
4. Create recipe collections
5. Add nutrition info extraction
6. Implement recipe search
7. Add favorites/ratings

---

**Built with Claude Sonnet 4**  
Questions? Check the implementation guide or visit https://docs.anthropic.com
