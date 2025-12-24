# Diabetic-Friendly Recipe Analysis Integration Guide

## Overview

This guide explains how to integrate the diabetic-friendly recipe analysis feature into your Reczipes2 app. The implementation follows the same pattern as your existing FODMAP analysis, adapted for diabetes-specific nutritional information.

## Files Created

### 1. `DiabeticInfo.swift`
Contains all data models for diabetic analysis:
- **DiabeticInfo**: Main model containing all diabetic-relevant data
- **GlycemicLoad**: Glycemic load calculations and explanations
- **CarbInfo**: Carbohydrate breakdown (total, net, fiber)
- **GuidanceItem**: Actionable advice for diabetic users
- **IngredientSubstitution**: Healthier ingredient alternatives
- **VerifiedSource**: Medical source verification
- **ConsensusLevel**: Indicates agreement between sources

### 2. `DiabeticInfoView.swift`
Complete SwiftUI view implementation including:
- **DiabeticInfoView**: Main container view
- **GlycemicImpactCard**: Visual glycemic load indicator
- **CarbCountView**: Carbohydrate breakdown display
- **GuidanceCard**: Expandable guidance items
- **SubstitutionsSection**: Healthier alternatives
- **SourceVerificationFooter**: Source credibility display
- **MedicalDisclaimerBanner**: Required medical disclaimer

## Integration Steps

### Step 1: Create the API Service

Following your `FODMAPAnalyzer.swift` pattern, create `DiabeticAnalyzer.swift`:

```swift
import Foundation

// MARK: - Diabetic Analyzer Service

actor DiabeticAnalyzer {
    static let shared = DiabeticAnalyzer()
    
    private let claudeAPIKey: String
    private let apiEndpoint = "https://api.anthropic.com/v1/messages"
    
    private init() {
        // Load from your existing API key storage
        self.claudeAPIKey = // Your API key loading logic
    }
    
    /// Analyze a recipe for diabetic-friendly information
    func analyzeDiabeticInfo(for recipe: Recipe) async throws -> DiabeticInfo {
        let prompt = buildAnalysisPrompt(for: recipe)
        let response = try await callClaudeAPI(with: prompt)
        return try parseResponse(response)
    }
    
    private func buildAnalysisPrompt(for recipe: Recipe) -> String {
        """
        You are a medical nutrition expert analyzing recipes for diabetic-friendly information.
        
        CRITICAL INSTRUCTIONS:
        - Search only medical and institutional sources published 2023-2025
        - Prioritize: ADA (American Diabetes Association), Mayo Clinic, CDC, NIH, peer-reviewed journals
        - Cite URL for every claim
        - If sources conflict, explicitly note the disagreement
        - Calculate glycemic load using: GL = (GI × carbs per serving) / 100
        - Flag any ingredients with GI > 70 as high-impact
        - Return structured JSON with sources array
        
        RECIPE INFORMATION:
        Title: \(recipe.title)
        Servings: \(recipe.servings ?? 1)
        
        Ingredients:
        \(recipe.ingredients.map { "- \($0)" }.joined(separator: "\n"))
        
        Instructions:
        \(recipe.steps.map { "- \($0)" }.joined(separator: "\n"))
        
        REQUIRED OUTPUT (JSON):
        {
          "estimatedGlycemicLoad": {
            "value": <number>,
            "explanation": "<calculation details>"
          },
          "carbCount": {
            "totalCarbs": <grams>,
            "netCarbs": <grams>,
            "fiber": <grams>
          },
          "diabeticGuidance": [
            {
              "title": "<guidance title>",
              "summary": "<brief summary>",
              "detailedExplanation": "<full explanation>",
              "icon": "<SF Symbol name>",
              "practicalTips": ["<tip1>", "<tip2>"]
            }
          ],
          "substitutionSuggestions": [
            {
              "originalIngredient": "<ingredient>",
              "substitute": "<alternative>",
              "reason": "<why this is better>"
            }
          ],
          "sources": [
            {
              "title": "<source title>",
              "organization": "<e.g., ADA, Mayo Clinic>",
              "url": "<full URL>",
              "publishDate": "<YYYY-MM-DD>"
            }
          ],
          "consensusLevel": "<strongConsensus|moderateConsensus|limitedEvidence|needsReview>"
        }
        
        Analyze this recipe and provide diabetic-friendly information.
        """
    }
    
    private func callClaudeAPI(with prompt: String) async throws -> String {
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DiabeticAnalysisError.apiError
        }
        
        // Parse Claude response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let content = json["content"] as? [[String: Any]],
           let text = content.first?["text"] as? String {
            return text
        }
        
        throw DiabeticAnalysisError.invalidResponse
    }
    
    private func parseResponse(_ response: String) throws -> DiabeticInfo {
        // Extract JSON from response (Claude may wrap it in markdown)
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8) else {
            throw DiabeticAnalysisError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Parse the response into DiabeticInfo
        // You'll need to create a decodable wrapper that matches the JSON structure
        return try decoder.decode(DiabeticInfo.self, from: data)
    }
    
    private func extractJSON(from text: String) -> String {
        // Remove markdown code blocks if present
        let pattern = "```(?:json)?\\s*([\\s\\S]*?)```"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return text
    }
}

enum DiabeticAnalysisError: LocalizedError {
    case apiError
    case invalidResponse
    case invalidJSON
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .apiError: return "Failed to communicate with analysis service"
        case .invalidResponse: return "Received invalid response from analysis service"
        case .invalidJSON: return "Could not parse analysis results"
        case .missingAPIKey: return "API key not configured"
        }
    }
}
```

### Step 2: Add to Recipe Detail View

In your `RecipeDetailView.swift`, add the diabetic analysis section:

```swift
// Add state property
@State private var diabeticInfo: DiabeticInfo?
@State private var isLoadingDiabeticInfo = false
@State private var showDiabeticInfo = false

// Add to your view body, similar to FODMAP section
if showDiabeticInfo {
    Section {
        if let info = diabeticInfo {
            DiabeticInfoView(info: info)
        } else if isLoadingDiabeticInfo {
            ProgressView("Analyzing recipe...")
        } else {
            Button {
                Task {
                    await loadDiabeticInfo()
                }
            } label: {
                Label("Analyze for Diabetic-Friendly Info", systemImage: "heart.text.square")
            }
        }
    } header: {
        Text("Diabetic-Friendly Analysis")
    }
}

// Add the loading function
private func loadDiabeticInfo() async {
    isLoadingDiabeticInfo = true
    defer { isLoadingDiabeticInfo = false }
    
    do {
        diabeticInfo = try await DiabeticAnalyzer.shared.analyzeDiabeticInfo(for: recipe)
    } catch {
        // Handle error - show alert to user
        print("Failed to analyze: \(error.localizedDescription)")
    }
}
```

### Step 3: Add Caching (Optional but Recommended)

Since API calls are expensive and guidelines don't change frequently:

```swift
// Add to your SwiftData schema or UserDefaults
@Model
class CachedDiabeticAnalysis {
    @Attribute(.unique) let recipeId: UUID
    let analysisData: Data // Encoded DiabeticInfo
    let cachedAt: Date
    
    var isStale: Bool {
        // Cache for 30 days per your requirements
        Date().timeIntervalSince(cachedAt) > 30 * 24 * 60 * 60
    }
}

// Modify analyzer to check cache first
func analyzeDiabeticInfo(for recipe: Recipe) async throws -> DiabeticInfo {
    // Check cache
    if let cached = fetchCached(recipeId: recipe.id), !cached.isStale {
        return try JSONDecoder().decode(DiabeticInfo.self, from: cached.analysisData)
    }
    
    // Fresh analysis
    let info = try await performFreshAnalysis(for: recipe)
    
    // Cache result
    await cacheAnalysis(info, for: recipe.id)
    
    return info
}
```

### Step 4: Settings Integration

Add user preference in your Settings view:

```swift
Section {
    Toggle("Show Diabetic-Friendly Analysis", isOn: $showDiabeticAnalysis)
} header: {
    Text("Health Features")
} footer: {
    Text("Provides glycemic load, carb counting, and diabetic-specific guidance. This feature uses AI analysis and medical sources.")
}
```

## Medical Disclaimer Requirements

**IMPORTANT:** Always show the medical disclaimer:
1. In the view itself (already included)
2. In settings when enabling the feature
3. On first use

Example disclaimer text:
```
"The diabetic-friendly analysis is for informational purposes only and is not medical advice. 
Always consult your healthcare provider or registered dietitian before making dietary changes."
```

## Data Freshness

- **Cache Duration**: 30 days (adjustable)
- **Last Updated**: Always displayed to user
- **Manual Refresh**: Allow users to force refresh if needed
- **Source Dating**: Prefer sources from 2023-2025

## Source Quality Control

Prioritized sources (in order):
1. **High Priority**: ADA, Mayo Clinic, CDC, NIH, JAMA
2. **Medium Priority**: University hospitals, peer-reviewed journals
3. **Avoid**: Blogs, forums, commercial diet sites

The prompt instructs Claude to:
- Only cite institutional sources
- Reject low-quality sources
- Note conflicts between sources
- Calculate glycemic load using standard formula

## Privacy Considerations

✅ **Good Practices:**
- Feature is opt-in
- No personal health data stored
- No tracking of which recipes users analyze
- Works offline with cached data

❌ **Avoid:**
- Requiring users to disclose diabetic status
- Storing analysis history linked to user
- Sharing analysis data with third parties

## Testing Checklist

- [ ] API integration works correctly
- [ ] JSON parsing handles all response formats
- [ ] Error handling shows user-friendly messages
- [ ] Medical disclaimer is always visible
- [ ] Sources are displayed and tappable
- [ ] Cache respects 30-day expiration
- [ ] Loading states work smoothly
- [ ] Works offline with cached data
- [ ] Visual design matches app style
- [ ] Accessibility labels are present

## Cost Considerations

Each Claude API call costs approximately:
- Input: ~$3 per million tokens
- Output: ~$15 per million tokens
- Typical recipe analysis: ~1000 input + 2000 output tokens
- Cost per analysis: ~$0.03-0.05

**Recommendations:**
- Implement caching (saves 95%+ of costs)
- Consider rate limiting (e.g., 5 analyses per hour)
- Track API usage
- Budget accordingly for your user base

## Future Enhancements

1. **Offline Mode**: Pre-analyze popular recipes
2. **Batch Analysis**: Analyze meal plans or shopping lists
3. **Personalization**: Learn from user preferences (with consent)
4. **Integration**: Connect with FODMAP analysis for combined results
5. **Export**: Allow users to share analysis with healthcare providers

## Support Resources

- American Diabetes Association: https://diabetes.org
- Glycemic Index Foundation: https://glycemicindex.com
- USDA FoodData Central: https://fdc.nal.usda.gov

---

**Questions or Issues?**
This implementation follows your existing patterns from FODMAP analysis. The views are ready to use - you just need to create the `DiabeticAnalyzer` service following the pattern above.
