# Quick Start: Implementing Duplicate Detection

## 🎯 Overview
This guide provides the essential code snippets to implement duplicate recipe detection during extraction.

## 📦 Step 1: Add Image Hash Service

Create `ImageHashService.swift`:

```swift
import UIKit
import CryptoKit

class ImageHashService {
    
    /// Generate perceptual hash for duplicate detection
    func generateHash(for image: UIImage) -> String? {
        guard let resized = resizeImage(image, to: CGSize(width: 8, height: 8)),
              let pixels = getGrayscalePixels(from: resized) else {
            return nil
        }
        
        let average = pixels.reduce(0, +) / pixels.count
        let hash = pixels.map { $0 > average ? "1" : "0" }.joined()
        
        return hash
    }
    
    /// Calculate similarity between two hashes (0.0 to 1.0)
    func similarity(hash1: String, hash2: String) -> Double {
        guard hash1.count == hash2.count else { return 0.0 }
        
        let matches = zip(hash1, hash2).filter { $0 == $1 }.count
        return Double(matches) / Double(hash1.count)
    }
    
    // MARK: - Private Helpers
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }
    
    private func getGrayscalePixels(from image: UIImage) -> [UInt8]? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 1
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = bytesPerRow * height
        
        var pixels = [UInt8](repeating: 0, count: totalBytes)
        
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return pixels
    }
}
```

## 📦 Step 2: Add Duplicate Detection Service

Create `DuplicateDetectionService.swift`:

```swift
import SwiftUI
import SwiftData

@MainActor
class DuplicateDetectionService {
    
    private let imageHashService = ImageHashService()
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Image-Based Detection
    
    /// Find recipes with similar images
    func findSimilarByImage(_ image: UIImage, threshold: Double = 0.95) async -> [Recipe] {
        guard let imageHash = imageHashService.generateHash(for: image) else {
            return []
        }
        
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate { recipe in
                recipe.imageHash != nil
            }
        )
        
        guard let allRecipes = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        let similar = allRecipes.filter { recipe in
            guard let existingHash = recipe.imageHash else { return false }
            let similarity = imageHashService.similarity(hash1: imageHash, hash2: existingHash)
            return similarity >= threshold
        }
        
        return similar
    }
    
    // MARK: - Content-Based Detection
    
    /// Find recipes with similar content
    func findSimilarByContent(_ recipe: RecipeModel, threshold: Double = 0.8) async -> [DuplicateMatch] {
        let descriptor = FetchDescriptor<Recipe>()
        
        guard let allRecipes = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        var matches: [DuplicateMatch] = []
        
        for existingRecipe in allRecipes {
            let score = calculateSimilarity(newRecipe: recipe, existingRecipe: existingRecipe)
            
            if score.overall >= threshold {
                let match = DuplicateMatch(
                    existingRecipe: existingRecipe,
                    confidence: score.overall,
                    matchType: determineMatchType(score: score),
                    reasons: generateReasons(score: score)
                )
                matches.append(match)
            }
        }
        
        return matches.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Similarity Calculation
    
    func calculateSimilarity(newRecipe: RecipeModel, existingRecipe: Recipe) -> DuplicateMatchScore {
        let titleSim = titleSimilarity(newRecipe.title, existingRecipe.title)
        let ingredientSim = ingredientSimilarity(newRecipe: newRecipe, existingRecipe: existingRecipe)
        
        // Weighted average: title 40%, ingredients 60%
        let overall = (titleSim * 0.4) + (ingredientSim * 0.6)
        
        return DuplicateMatchScore(
            titleSimilarity: titleSim,
            ingredientSimilarity: ingredientSim,
            imageSimilarity: 0.0, // Set separately if needed
            overall: overall
        )
    }
    
    private func titleSimilarity(_ title1: String, _ title2: String) -> Double {
        let normalized1 = title1.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized2 = title2.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if normalized1 == normalized2 {
            return 1.0
        }
        
        // Simple Levenshtein-based similarity
        let distance = levenshteinDistance(normalized1, normalized2)
        let maxLength = max(normalized1.count, normalized2.count)
        guard maxLength > 0 else { return 0.0 }
        
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    private func ingredientSimilarity(newRecipe: RecipeModel, existingRecipe: Recipe) -> Double {
        let newIngredients = extractIngredients(from: newRecipe)
        let existingIngredients = extractIngredients(from: existingRecipe)
        
        let set1 = Set(newIngredients.map { normalizeIngredient($0) })
        let set2 = Set(existingIngredients.map { normalizeIngredient($0) })
        
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        
        guard union > 0 else { return 0.0 }
        
        return Double(intersection) / Double(union)
    }
    
    private func extractIngredients(from recipe: RecipeModel) -> [String] {
        recipe.ingredientSections.flatMap { section in
            section.ingredients.map { $0.text }
        }
    }
    
    private func extractIngredients(from recipe: Recipe) -> [String] {
        recipe.ingredientSections.flatMap { section in
            section.ingredients.map { $0.text }
        }
    }
    
    private func normalizeIngredient(_ ingredient: String) -> String {
        ingredient
            .lowercased()
            .replacingOccurrences(of: #"\d+\.?\d*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\b(cup|cups|tbsp|tsp|oz|lb|g|kg|ml|l)\b"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)
        var dist = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)
        
        for i in 0...s1.count {
            dist[i][0] = i
        }
        
        for j in 0...s2.count {
            dist[0][j] = j
        }
        
        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1[i-1] == s2[j-1] ? 0 : 1
                dist[i][j] = min(
                    dist[i-1][j] + 1,
                    dist[i][j-1] + 1,
                    dist[i-1][j-1] + cost
                )
            }
        }
        
        return dist[s1.count][s2.count]
    }
    
    private func determineMatchType(score: DuplicateMatchScore) -> MatchType {
        if score.titleSimilarity > 0.9 && score.ingredientSimilarity > 0.7 {
            return .combined
        } else if score.titleSimilarity > 0.9 {
            return .titleMatch
        } else if score.ingredientSimilarity > 0.8 {
            return .ingredientMatch
        } else {
            return .combined
        }
    }
    
    private func generateReasons(score: DuplicateMatchScore) -> [String] {
        var reasons: [String] = []
        
        if score.titleSimilarity > 0.9 {
            reasons.append("Title is very similar (\(Int(score.titleSimilarity * 100))%)")
        }
        
        if score.ingredientSimilarity > 0.7 {
            reasons.append("Ingredients match (\(Int(score.ingredientSimilarity * 100))%)")
        }
        
        if score.imageSimilarity > 0.9 {
            reasons.append("Image looks identical (\(Int(score.imageSimilarity * 100))%)")
        }
        
        return reasons
    }
}

// MARK: - Supporting Types

struct DuplicateMatch {
    let existingRecipe: Recipe
    let confidence: Double
    let matchType: MatchType
    let reasons: [String]
}

enum MatchType {
    case imageHash
    case titleMatch
    case ingredientMatch
    case combined
}

struct DuplicateMatchScore {
    let titleSimilarity: Double
    let ingredientSimilarity: Double
    let imageSimilarity: Double
    let overall: Double
}
```

## 📦 Step 3: Update Recipe Model

Add to `Recipe.swift`:

```swift
@Model
class Recipe {
    // ... existing properties ...
    
    // NEW: For duplicate detection
    var imageHash: String?
    var extractionSource: String? // "camera", "photos", "files"
    var originalFileName: String?
    
    // ... rest of model ...
}
```

## 📦 Step 4: Create Duplicate Resolution View

Create `DuplicateResolutionView.swift`:

```swift
import SwiftUI
import SwiftData

struct DuplicateResolutionView: View {
    let existingRecipe: Recipe
    let newRecipe: RecipeModel
    let duplicateMatch: DuplicateMatch
    
    @Environment(\.dismiss) private var dismiss
    
    var onKeepBoth: () -> Void
    var onReplaceOriginal: () -> Void
    var onKeepOriginal: () -> Void
    
    @State private var showingComparison = false
    
    var isShared: Bool {
        existingRecipe.isShared
    }
    
    var isInCookbook: Bool {
        !(existingRecipe.cookbooks?.isEmpty ?? true)
    }
    
    var cookbookNames: [String] {
        existingRecipe.cookbooks?.map { $0.name } ?? []
    }
    
    var canReplace: Bool {
        !isShared && !isInCookbook
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Match Details
                    matchDetailsSection
                    
                    // Existing Recipe Info
                    existingRecipeSection
                    
                    // Warning if shared/in cookbook
                    if !canReplace {
                        warningSection
                    }
                    
                    Divider()
                    
                    // Action Options
                    actionOptionsSection
                }
                .padding()
            }
            .navigationTitle("Duplicate Detected")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingComparison) {
                RecipeComparisonView(
                    existingRecipe: existingRecipe,
                    newRecipe: newRecipe,
                    onKeepExisting: {
                        showingComparison = false
                        onKeepOriginal()
                        dismiss()
                    },
                    onKeepBoth: {
                        showingComparison = false
                        onKeepBoth()
                        dismiss()
                    },
                    onKeepNew: {
                        showingComparison = false
                        if canReplace {
                            onReplaceOriginal()
                        }
                        dismiss()
                    },
                    canReplaceExisting: canReplace
                )
            }
        }
    }
    
    private var matchDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Match Details", systemImage: "chart.bar.fill")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                matchDetail("Overall Confidence", value: duplicateMatch.confidence)
                
                ForEach(duplicateMatch.reasons, id: \.self) { reason in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(reason)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func matchDetail(_ label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("\(Int(value * 100))%")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
    
    private var existingRecipeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Existing Recipe", systemImage: "book.fill")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(existingRecipe.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if let date = existingRecipe.dateCreated {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Added: \(date.formatted(date: .abbreviated, time: .omitted))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                if isInCookbook {
                    HStack {
                        Image(systemName: "books.vertical.fill")
                        Text("In \(cookbookNames.count) cookbook\(cookbookNames.count == 1 ? "" : "s")")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                if isShared {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Shared with others")
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var warningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(isShared ? "Cannot Replace Shared Recipe" : "Cannot Replace Recipe in Cookbook")
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
            .font(.headline)
            
            Text(warningMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var warningMessage: String {
        if isShared && isInCookbook {
            return "This recipe is shared with others AND part of \(cookbookNames.count) cookbook(s). Replacing it would affect all users and cookbooks."
        } else if isShared {
            return "This recipe is currently shared with others. Replacing it would affect all users who have access."
        } else {
            let names = cookbookNames.prefix(3).joined(separator: ", ")
            let more = cookbookNames.count > 3 ? " and \(cookbookNames.count - 3) more" : ""
            return "This recipe is part of: \(names)\(more). Replacing it would affect these cookbooks."
        }
    }
    
    private var actionOptionsSection: some View {
        VStack(spacing: 16) {
            Text("What would you like to do?")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Option 1: Keep Both
            actionButton(
                title: "Keep Both Recipes",
                subtitle: "New will be saved as \"\(newRecipe.title) (2)\"",
                icon: "doc.on.doc.fill",
                color: .green
            ) {
                onKeepBoth()
                dismiss()
            }
            
            // Option 2: Replace (if allowed)
            actionButton(
                title: "Replace Original",
                subtitle: canReplace ? "Update existing recipe with new extraction" : "Not available for shared/cookbook recipes",
                icon: "arrow.triangle.2.circlepath",
                color: .blue,
                disabled: !canReplace
            ) {
                onReplaceOriginal()
                dismiss()
            }
            
            // Option 3: Keep Original
            actionButton(
                title: "Keep Original Only",
                subtitle: "Discard new extraction",
                icon: "xmark.circle.fill",
                color: .red
            ) {
                onKeepOriginal()
                dismiss()
            }
            
            Divider()
            
            // Comparison button
            Button {
                showingComparison = true
            } label: {
                Label("Compare Side-by-Side", systemImage: "square.split.2x1")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
        }
    }
    
    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(disabled ? .gray : color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(disabled ? .gray : .primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if disabled {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(disabled ? Color(.systemGray5) : Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }
}
```

## 📦 Step 5: Integrate into RecipeExtractorViewModel

Update `RecipeExtractorViewModel.swift`:

```swift
@MainActor
class RecipeExtractorViewModel: ObservableObject {
    // ... existing properties ...
    
    @Published var showingDuplicateResolution = false
    @Published var duplicateMatch: DuplicateMatch?
    
    private var duplicateDetectionService: DuplicateDetectionService?
    private let imageHashService = ImageHashService()
    
    // ... existing code ...
    
    func saveRecipe() {
        guard let recipe = extractedRecipe else { return }
        
        // Check for duplicates
        Task {
            let service = DuplicateDetectionService(modelContext: modelContext)
            let duplicates = await service.findSimilarByContent(recipe, threshold: 0.8)
            
            if let firstMatch = duplicates.first {
                // Show duplicate resolution
                duplicateMatch = firstMatch
                showingDuplicateResolution = true
            } else {
                // No duplicates, save normally
                saveRecipeDirectly(recipe)
            }
        }
    }
    
    private func saveRecipeDirectly(_ recipeModel: RecipeModel) {
        let recipe = Recipe(from: recipeModel)
        
        // Generate and store image hash
        if let image = selectedImage,
           let hash = imageHashService.generateHash(for: image) {
            recipe.imageHash = hash
        }
        
        recipe.extractionSource = "camera" // or "photos" or "files"
        
        // ... rest of save logic ...
        
        modelContext.insert(recipe)
        try? modelContext.save()
    }
    
    func handleKeepBoth() {
        guard let recipe = extractedRecipe else { return }
        
        // Modify title to add (2)
        var modifiedRecipe = recipe
        modifiedRecipe.title = "\(recipe.title) (2)"
        
        saveRecipeDirectly(modifiedRecipe)
    }
    
    func handleReplaceOriginal() {
        guard let newRecipe = extractedRecipe,
              let match = duplicateMatch else { return }
        
        let existingRecipe = match.existingRecipe
        
        // Update existing recipe with new data
        existingRecipe.title = newRecipe.title
        existingRecipe.ingredientSections = newRecipe.ingredientSections.map { IngredientSection(from: $0) }
        existingRecipe.instructionSections = newRecipe.instructionSections.map { InstructionSection(from: $0) }
        // ... update other fields ...
        
        try? modelContext.save()
    }
    
    func handleKeepOriginal() {
        // Just dismiss, don't save
        extractedRecipe = nil
    }
}
```

## ✅ Quick Integration Checklist

- [ ] Add `ImageHashService.swift`
- [ ] Add `DuplicateDetectionService.swift`
- [ ] Add `imageHash` field to Recipe model
- [ ] Add `DuplicateResolutionView.swift`
- [ ] Update `RecipeExtractorViewModel` to check duplicates before saving
- [ ] Test with duplicate images
- [ ] Test with shared recipes (verify replace is blocked)
- [ ] Test with cookbook recipes (verify replace is blocked)

## 🧪 Quick Test

```swift
// Test duplicate detection
let service = DuplicateDetectionService(modelContext: modelContext)

// Test image hash
let image = UIImage(named: "test")!
let hash = ImageHashService().generateHash(for: image)

// Test finding similar recipes
Task {
    let duplicates = await service.findSimilarByContent(testRecipe)
    print("Found \(duplicates.count) duplicates")
}
```

---

**Next Steps**: See `DUPLICATE_DETECTION_FEATURE_SPEC.md` for complete implementation details.
