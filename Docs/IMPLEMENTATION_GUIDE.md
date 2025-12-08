# Claude Recipe Extraction - Implementation Guide

## Overview
This implementation integrates Claude's vision API with your iOS recipe app to extract recipes from images of recipe cards, cookbooks, and handwritten notes. The system uses your existing `RecipeModel` structure and includes sophisticated image preprocessing for optimal OCR results.

## Files Created

1. **ImagePreprocessor.swift** - Enhances images for better OCR
2. **ClaudeAPIClient.swift** - Handles Claude API communication
3. **RecipeExtractorViewModel.swift** - Manages extraction state
4. **RecipeExtractorView.swift** - Main UI for image selection
5. **RecipeDetailView.swift** - Displays extracted recipes
6. **ImagePicker.swift** - Camera/photo library helper

## Setup Instructions

### 1. Add Files to Xcode Project

Drag all `.swift` files into your Xcode project. Ensure they're added to your app target.

### 2. Update Info.plist

Add these privacy descriptions:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to photograph recipe cards</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select recipe images</string>
```

### 3. API Key Management (CRITICAL)

**NEVER hardcode your API key in the source code.** Choose one of these secure methods:

#### Option A: Environment Variable (Development)
```swift
// In your app initialization
guard let apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"],
      !apiKey.isEmpty else {
    fatalError("CLAUDE_API_KEY not set")
}

let extractorView = RecipeExtractorView(apiKey: apiKey)
```

Set in Xcode: Edit Scheme → Run → Arguments → Environment Variables
- Name: `CLAUDE_API_KEY`
- Value: Your API key

#### Option B: Keychain Storage (Recommended for Production)

```swift
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// Usage
// First time: Store the key (perhaps during onboarding)
KeychainManager.shared.save(key: "claudeAPIKey", value: "your-api-key")

// Then retrieve it
if let apiKey = KeychainManager.shared.get(key: "claudeAPIKey") {
    let extractorView = RecipeExtractorView(apiKey: apiKey)
}
```

#### Option C: Backend Proxy (Most Secure for Production)

Create a backend service that proxies Claude API requests:

```swift
class ClaudeAPIProxy {
    let proxyURL = "https://your-backend.com/api/extract-recipe"
    
    func extractRecipe(imageData: Data) async throws -> RecipeModel {
        var request = URLRequest(url: URL(string: proxyURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "image": imageData.base64EncodedString()
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Your backend adds the API key server-side
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(RecipeModel.self, from: data)
    }
}
```

### 4. Integration into Your App

```swift
import SwiftUI

@main
struct Reczipes2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            // Your existing recipe browsing view
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
            
            // New recipe extraction view
            RecipeExtractorView(apiKey: getAPIKey())
                .tabItem {
                    Label("Extract", systemImage: "camera.fill")
                }
        }
    }
    
    private func getAPIKey() -> String {
        // Use one of the secure methods above
        return KeychainManager.shared.get(key: "claudeAPIKey") ?? ""
    }
}
```

## Usage

### Basic Usage
1. User taps "Camera" or "Library"
2. Selects/captures an image
3. Claude analyzes and extracts the recipe
4. User can view and save the extracted recipe

### Image Preprocessing
The system includes automatic image enhancement:
- **Grayscale conversion** - Reduces noise
- **Contrast enhancement** - Makes text clearer
- **Sharpening** - Improves character recognition
- **Noise reduction** - Cleans up old/faded images

Users can toggle preprocessing on/off and compare original vs processed images.

## Features

### Comprehensive Recipe Extraction
- **Multiple ingredient sections** (e.g., "For the dough", "For the filling")
- **Multiple instruction sections** (e.g., "Preparation", "Baking")
- **Metric conversions** when present
- **Recipe notes and tips** (tips, substitutions, warnings, timing)
- **Preparation details** (e.g., "finely chopped", "at room temperature")
- **Yield and servings**
- **References** (page numbers, sources)

### User Experience
- **Image comparison** view (original vs processed)
- **Loading indicators** with progress feedback
- **Error handling** with retry options
- **Share functionality** for extracted recipes
- **Detailed recipe display** with proper formatting

## API Costs

Claude Sonnet 4 pricing (as of Dec 2024):
- Input: $3 per million tokens
- Output: $15 per million tokens

Typical recipe extraction:
- ~2,000 input tokens (image + prompt)
- ~1,000 output tokens (recipe JSON)
- **Cost per recipe: ~$0.02**

## Best Practices

### Image Quality
For best results, ensure:
- Good lighting
- Clear focus
- Minimal shadows
- Text is legible
- Recipe card fills most of frame

### Preprocessing
- Enable for old/faded recipe cards
- Enable for handwritten recipes
- Disable for high-quality digital images
- Use comparison view to verify enhancement

### Error Handling
The system handles:
- Network failures
- API errors
- Invalid JSON responses
- Missing required fields

## Advanced Customization

### Modify Recipe Structure Prompt
Edit `ClaudeAPIClient.swift` if you need to:
- Add custom fields to recipes
- Change extraction logic
- Adjust JSON schema

### Adjust Image Preprocessing
Edit `ImagePreprocessor.swift` to:
- Fine-tune contrast levels
- Adjust sharpness
- Add custom filters

### Custom UI
Modify `RecipeExtractorView.swift` for:
- Different layouts
- Custom styling
- Additional features

## Troubleshooting

### "No recipe could be extracted"
- Image quality may be too poor
- Try enabling preprocessing
- Ensure text is legible in original
- Check API key is valid

### "API Error (401)"
- API key is invalid
- Check key is correctly stored
- Verify key has proper permissions

### "API Error (429)"
- Rate limit exceeded
- Implement request throttling
- Consider caching results

### Preprocessed image looks worse
- Try "Lightweight" preprocessing
- Disable preprocessing for high-quality images
- Adjust filter parameters in ImagePreprocessor

## Next Steps

1. **Save to Core Data**: Persist extracted recipes
2. **Edit functionality**: Allow users to correct extraction errors
3. **Batch processing**: Extract multiple recipes at once
4. **Recipe matching**: Compare against existing recipes
5. **OCR feedback**: Let users report extraction issues

## Security Checklist

- [ ] API key NOT in source code
- [ ] API key NOT in version control
- [ ] Using environment variables OR keychain OR proxy
- [ ] Info.plist privacy descriptions added
- [ ] API key rotation plan in place
- [ ] Consider rate limiting for production
- [ ] Monitor API usage costs

## Support

For issues with:
- **Claude API**: https://docs.anthropic.com
- **SwiftUI**: Apple Developer Documentation
- **This implementation**: Review inline code comments

---

Built with Claude Sonnet 4 - https://www.anthropic.com
