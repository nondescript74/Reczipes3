# FODMAP Integration Guide

## Overview

This guide explains how to integrate the FODMAP analysis system into your Reczipes app. The system allows users to:

1. **Set FODMAP preferences** in their user profile (select specific FODMAP categories)
2. **Analyze recipes** for FODMAP content using both local keyword matching and Claude AI
3. **Display badges** showing FODMAP scores alongside allergen scores
4. **View detailed analysis** with alternatives and modification suggestions

## File Structure

### Core Files

1. **AllergenProfile.swift** - Data models for sensitivities including FODMAP categories
2. **FODMAPAnalyzer.swift** - Local FODMAP analysis (already exists in your project)
3. **FODMAPProfileSettingsView.swift** - UI for selecting FODMAP categories
4. **FODMAPBadgeView.swift** - Badge display components
5. **AllergenAnalyzer+Claude.swift** - Claude AI integration (already exists)

## Step-by-Step Integration

### Step 1: Update User Profile Settings

Add FODMAP category selection to your user profile settings view:

```swift
import SwiftUI
import SwiftData

struct UserProfileSettingsView: View {
    @Bindable var profile: UserAllergenProfile
    @State private var showAddSensitivity = false
    @State private var editingSensitivity: UserSensitivity?
    
    var body: some View {
        Form {
            Section("Food Sensitivities") {
                ForEach(profile.sensitivities) { sensitivity in
                    SensitivityRow(sensitivity: sensitivity)
                        .onTapGesture {
                            editingSensitivity = sensitivity
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                profile.removeSensitivity(id: sensitivity.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                
                Button {
                    showAddSensitivity = true
                } label: {
                    Label("Add Sensitivity", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Profile Settings")
        .sheet(isPresented: $showAddSensitivity) {
            AddSensitivityView(profile: profile)
        }
        .sheet(item: $editingSensitivity) { sensitivity in
            EditSensitivityView(
                profile: profile,
                sensitivity: sensitivity
            )
        }
    }
}

// Sensitivity Row View
struct SensitivityRow: View {
    let sensitivity: UserSensitivity
    
    var body: some View {
        HStack {
            Text(sensitivity.intolerance.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(sensitivity.name)
                    .font(.headline)
                
                if sensitivity.isFODMAP {
                    // Show selected FODMAP categories
                    let categories = sensitivity.selectedFODMAPCategories
                    if categories.isEmpty || categories.count == FODMAPCategory.allCases.count {
                        Text("All FODMAP categories")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(categories.map { $0.shortName }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(sensitivity.severity.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// Add Sensitivity View
struct AddSensitivityView: View {
    let profile: UserAllergenProfile
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedIntolerance: FoodIntolerance = .gluten
    @State private var selectedSeverity: SensitivitySeverity = .moderate
    @State private var notes: String = ""
    @State private var selectedFODMAPCategories: Set<FODMAPCategory> = Set(FODMAPCategory.allCases)
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Intolerance", selection: $selectedIntolerance) {
                        ForEach(FoodIntolerance.allCases, id: \.self) { intolerance in
                            HStack {
                                Text(intolerance.icon)
                                Text(intolerance.name)
                            }
                            .tag(intolerance)
                        }
                    }
                }
                
                if selectedIntolerance == .fodmap {
                    // Show FODMAP category selection
                    Section {
                        NavigationLink("Select FODMAP Categories") {
                            FODMAPCategorySelectionView(
                                selectedCategories: $selectedFODMAPCategories
                            )
                        }
                        
                        if !selectedFODMAPCategories.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Selected:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                FlowLayout(spacing: 6) {
                                    ForEach(Array(selectedFODMAPCategories), id: \.self) { category in
                                        Text(category.shortName)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Section("Severity") {
                        Picker("Level", selection: $selectedSeverity) {
                            ForEach(SensitivitySeverity.allCases, id: \.self) { severity in
                                Text(severity.displayName).tag(severity)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Sensitivity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let sensitivity = UserSensitivity(
                            intolerance: selectedIntolerance,
                            severity: selectedSeverity,
                            notes: notes.isEmpty ? nil : notes,
                            fodmapCategories: selectedIntolerance == .fodmap ? selectedFODMAPCategories : nil
                        )
                        profile.addSensitivity(sensitivity)
                        dismiss()
                    }
                }
            }
        }
    }
}

// FODMAP Category Selection View
struct FODMAPCategorySelectionView: View {
    @Binding var selectedCategories: Set<FODMAPCategory>
    
    var body: some View {
        List {
            Section {
                Text("Select which FODMAP categories affect you")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                ForEach(FODMAPCategory.allCases, id: \.self) { category in
                    Button {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedCategories.contains(category) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedCategories.contains(category) ? .blue : .gray)
                            
                            Text(category.icon)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.fullName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(category.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section {
                Button("Select All") {
                    selectedCategories = Set(FODMAPCategory.allCases)
                }
                
                Button("Clear All") {
                    selectedCategories.removeAll()
                }
            }
        }
        .navigationTitle("FODMAP Categories")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

### Step 2: Analyze Recipes with FODMAP

In your recipe view model or detail view, add FODMAP analysis:

```swift
import SwiftUI
import SwiftData

@Observable
class RecipeDetailViewModel {
    var recipe: RecipeModel
    var allergenScore: RecipeAllergenScore?
    var fodmapScore: EnhancedFODMAPScore?
    var isAnalyzingAllergens = false
    var isAnalyzingFODMAP = false
    
    init(recipe: RecipeModel) {
        self.recipe = recipe
    }
    
    /// Analyze recipe for both allergens and FODMAP
    func analyzeRecipe(profile: UserAllergenProfile, apiKey: String) {
        // Check if user has FODMAP sensitivity
        let hasFODMAPSensitivity = profile.sensitivities.contains { $0.isFODMAP }
        
        // Basic allergen analysis (always do this)
        analyzeAllergens(profile: profile)
        
        // FODMAP analysis (only if user has FODMAP sensitivity)
        if hasFODMAPSensitivity {
            analyzeFODMAP(profile: profile, apiKey: apiKey)
        }
    }
    
    /// Basic allergen analysis (fast, local)
    private func analyzeAllergens(profile: UserAllergenProfile) {
        isAnalyzingAllergens = true
        
        Task {
            let score = AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
            
            await MainActor.run {
                self.allergenScore = score
                self.isAnalyzingAllergens = false
            }
        }
    }
    
    /// FODMAP analysis with Claude AI
    private func analyzeFODMAP(profile: UserAllergenProfile, apiKey: String) {
        isAnalyzingFODMAP = true
        
        Task {
            do {
                // This calls both local and Claude analysis
                let score = try await AllergenAnalyzer.shared.analyzeFODMAP(
                    recipe,
                    apiKey: apiKey
                )
                
                await MainActor.run {
                    self.fodmapScore = score
                    self.isAnalyzingFODMAP = false
                }
            } catch {
                print("FODMAP analysis error: \(error)")
                
                // Fallback to basic analysis
                let basicAnalysis = FODMAPAnalyzer.shared.analyzeRecipe(recipe)
                await MainActor.run {
                    self.fodmapScore = EnhancedFODMAPScore(
                        basicAnalysis: basicAnalysis,
                        claudeAnalysis: nil,
                        recipe: recipe
                    )
                    self.isAnalyzingFODMAP = false
                }
            }
        }
    }
}
```

### Step 3: Display Badges in Recipe Views

Add badges to your recipe card or detail view:

```swift
struct RecipeDetailView: View {
    let recipe: RecipeModel
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserAllergenProfile]
    @State private var viewModel: RecipeDetailViewModel
    @State private var showAllergenDetail = false
    @State private var showFODMAPDetail = false
    
    init(recipe: RecipeModel) {
        self.recipe = recipe
        self._viewModel = State(initialValue: RecipeDetailViewModel(recipe: recipe))
    }
    
    var activeProfile: UserAllergenProfile? {
        profiles.first { $0.isActive }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recipe image
                if let imageName = recipe.imageName {
                    // ... image view
                }
                
                // Title and header
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let headerNotes = recipe.headerNotes {
                        Text(headerNotes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // ✨ SENSITIVITY BADGES ✨
                if let profile = activeProfile {
                    VStack(alignment: .leading, spacing: 12) {
                        // Allergen Badge
                        if let allergenScore = viewModel.allergenScore {
                            Button {
                                showAllergenDetail = true
                            } label: {
                                AllergenBadgeView(score: allergenScore, compact: false)
                            }
                            .buttonStyle(.plain)
                        } else if viewModel.isAnalyzingAllergens {
                            StandardLoadingBadge()
                        }
                        
                        // FODMAP Badge (if user has FODMAP sensitivity)
                        if profile.sensitivities.contains(where: { $0.isFODMAP }) {
                            if let fodmapScore = viewModel.fodmapScore {
                                Button {
                                    showFODMAPDetail = true
                                } label: {
                                    FODMAPBadgeView(score: fodmapScore, compact: false)
                                }
                                .buttonStyle(.plain)
                            } else if viewModel.isAnalyzingFODMAP {
                                StandardLoadingBadge()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Rest of recipe content...
                // Ingredients, Instructions, etc.
            }
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Analyze recipe when view appears
            if let profile = activeProfile,
               let apiKey = APIKeyHelper.getAPIKey() {
                viewModel.analyzeRecipe(profile: profile, apiKey: apiKey)
            }
        }
        .sheet(isPresented: $showAllergenDetail) {
            if let score = viewModel.allergenScore {
                // Your existing allergen detail view
                // AllergenDetailView(score: score)
            }
        }
        .sheet(isPresented: $showFODMAPDetail) {
            if let score = viewModel.fodmapScore {
                FODMAPAnalysisDetailView(score: score)
            }
        }
    }
}
```

### Step 4: Add Badges to Recipe List/Grid

For recipe lists or grids, use compact badges:

```swift
struct RecipeCardView: View {
    let recipe: RecipeModel
    let allergenScore: RecipeAllergenScore?
    let fodmapScore: EnhancedFODMAPScore?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Recipe image
            // ...
            
            // Title
            Text(recipe.title)
                .font(.headline)
                .lineLimit(2)
            
            // Compact badges
            CombinedSensitivityBadgeView(
                allergenScore: allergenScore,
                fodmapScore: fodmapScore,
                compact: true
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}
```

### Step 5: Batch Analysis for Recipe Lists

For recipe lists, pre-analyze multiple recipes:

```swift
@Observable
class RecipeListViewModel {
    var recipes: [RecipeModel] = []
    var allergenScores: [UUID: RecipeAllergenScore] = [:]
    var fodmapScores: [UUID: EnhancedFODMAPScore] = [:]
    
    func analyzeAllRecipes(profile: UserAllergenProfile, apiKey: String) {
        // Analyze allergens for all recipes (fast)
        allergenScores = AllergenAnalyzer.shared.analyzeRecipes(recipes, profile: profile)
        
        // Check if FODMAP analysis is needed
        let hasFODMAP = profile.sensitivities.contains { $0.isFODMAP }
        guard hasFODMAP else { return }
        
        // Analyze FODMAP for each recipe (slower, uses API)
        Task {
            for recipe in recipes {
                do {
                    let score = try await AllergenAnalyzer.shared.analyzeFODMAP(
                        recipe,
                        apiKey: apiKey
                    )
                    
                    await MainActor.run {
                        fodmapScores[recipe.id] = score
                    }
                } catch {
                    // Fallback to basic analysis
                    let basicAnalysis = FODMAPAnalyzer.shared.analyzeRecipe(recipe)
                    await MainActor.run {
                        fodmapScores[recipe.id] = EnhancedFODMAPScore(
                            basicAnalysis: basicAnalysis,
                            claudeAnalysis: nil,
                            recipe: recipe
                        )
                    }
                }
            }
        }
    }
}
```

## Claude API Prompt Integration

The Claude API automatically includes FODMAP analysis when a user has FODMAP sensitivity. The prompt is generated in `AllergenAnalyzer.swift`:

```swift
func generateClaudeAnalysisPrompt(recipe: RecipeModel, profile: UserAllergenProfile) -> String {
    // ... existing allergen prompt ...
    
    // FODMAP-specific prompt is automatically added if user has FODMAP sensitivity
    let hasFODMAPSensitivity = profile.sensitivities.contains { $0.isFODMAP }
    
    if hasFODMAPSensitivity {
        // Adds comprehensive FODMAP analysis section
        // Includes all 4 categories with Monash University data
    }
}
```

The response includes:

```json
{
    "detectedAllergens": [...],
    "overallSafetyScore": 5.5,
    "recommendation": "caution",
    "notes": "...",
    "fodmapAnalysis": {
        "overallLevel": "moderate",
        "categoryBreakdown": {
            "oligosaccharides": {"level": "high", "ingredients": ["onion", "garlic"]},
            "disaccharides": {"level": "low", "ingredients": []},
            "monosaccharides": {"level": "low", "ingredients": []},
            "polyols": {"level": "moderate", "ingredients": ["mushrooms"]}
        },
        "detectedFODMAPs": [
            {
                "ingredient": "onion",
                "categories": ["oligosaccharides"],
                "portionMatters": false,
                "lowFODMAPAlternative": "Use green tops of spring onions only"
            }
        ],
        "modificationTips": [
            "Replace onions with spring onion greens",
            "Use garlic-infused oil instead of fresh garlic"
        ],
        "monashGuidance": "According to Monash University research..."
    }
}
```

## Testing

### Unit Tests

```swift
import Testing

@Test("FODMAP category selection")
func testFODMAPCategorySelection() {
    let sensitivity = UserSensitivity(
        intolerance: .fodmap,
        fodmapCategories: [.oligosaccharides, .polyols]
    )
    
    #expect(sensitivity.isFODMAP == true)
    #expect(sensitivity.selectedFODMAPCategories.count == 2)
    #expect(sensitivity.selectedFODMAPCategories.contains(.oligosaccharides))
}

@Test("FODMAP analysis")
func testFODMAPAnalysis() async throws {
    let recipe = RecipeModel(
        title: "Pasta with Garlic",
        ingredientSections: [
            IngredientSection(ingredients: [
                Ingredient(name: "pasta"),
                Ingredient(name: "garlic"),
                Ingredient(name: "olive oil")
            ])
        ],
        instructionSections: []
    )
    
    let analysis = FODMAPAnalyzer.shared.analyzeRecipe(recipe)
    
    #expect(analysis.detectedFoods.count > 0)
    #expect(analysis.recommendation != .safe)
}
```

## API Key Management

Make sure your API key helper is set up:

```swift
enum APIKeyHelper {
    static func getAPIKey() -> String? {
        // Load from UserDefaults, Keychain, or environment
        return UserDefaults.standard.string(forKey: "ClaudeAPIKey")
    }
    
    static func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "ClaudeAPIKey")
    }
}
```

## Performance Considerations

1. **Batch Analysis**: Analyze recipes in background for better UX
2. **Caching**: Consider caching FODMAP scores to avoid repeated API calls
3. **Progressive Loading**: Show local analysis first, then enhance with Claude
4. **Rate Limiting**: Respect Claude API rate limits

## Troubleshooting

### Issue: FODMAP categories not saving

**Solution**: Make sure `Set<FODMAPCategory>` conforms to `Codable` (included in `AllergenProfile.swift`)

### Issue: Claude not returning FODMAP data

**Solution**: Check that user has FODMAP sensitivity selected in their profile

### Issue: Badges not showing

**Solution**: Ensure `activeProfile` has `isActive = true` and contains sensitivities

## Resources

- [Monash University FODMAP](https://www.monashfodmap.com)
- [Claude API Documentation](https://docs.anthropic.com)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)

## Summary

You now have a complete FODMAP system integrated with:
- ✅ User profile FODMAP category selection
- ✅ Local keyword-based FODMAP analysis
- ✅ Claude AI-enhanced FODMAP scoring
- ✅ Badge display system
- ✅ Detailed analysis views with alternatives
- ✅ Monash University attribution

Users can select specific FODMAP categories they're sensitive to, and recipes will be intelligently analyzed and scored accordingly!
