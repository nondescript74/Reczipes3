//
//  SimilarRecipesView.swift
//  Reczipes2
//
//  View for displaying similar recipes found on the web
//

import SwiftUI
import SwiftData

struct SimilarRecipesView: View {
    let originalRecipe: RecipeX
    let similarRecipes: [SimilarRecipe]
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedRecipe: SimilarRecipe?
    @State private var showingRecipeDetail = false
    @State private var savedRecipes: Set<String> = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Similar recipes list
                    ForEach(similarRecipes) { recipe in
                        SimilarRecipeCard(
                            recipe: recipe,
                            isSaved: savedRecipes.contains(recipe.sourceURL),
                            onTap: {
                                selectedRecipe = recipe
                                showingRecipeDetail = true
                            },
                            onSave: {
                                saveReferenceToRecipe(recipe)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Similar Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingRecipeDetail) {
                if let recipe = selectedRecipe {
                    SimilarRecipeDetailView(recipe: recipe)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Found \(similarRecipes.count) Similar Recipes")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Based on your recipe: \"\(originalRecipe.safeTitle)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Tap any recipe to view full details, ingredients, and instructions")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    // MARK: - Actions
    
    private func saveReferenceToRecipe(_ similarRecipe: SimilarRecipe) {
        // Add to saved set
        savedRecipes.insert(similarRecipe.sourceURL)
        
        // Format the reference entry
        let referenceEntry = """
        
        Similar Recipe: \(similarRecipe.title)
        Source: \(similarRecipe.source)
        URL: \(similarRecipe.sourceURL)
        Match: \(Int(similarRecipe.matchScore * 100))%
        """
        
        // Append to existing reference or create new one
        if let currentRef = originalRecipe.reference, !currentRef.isEmpty {
            originalRecipe.reference = currentRef + "\n" + referenceEntry
        } else {
            originalRecipe.reference = referenceEntry.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Mark recipe as modified
        originalRecipe.markAsModified()
        
        // Save context
        do {
            try modelContext.save()
            logInfo("Saved similar recipe reference: \(similarRecipe.title)", category: "enhancement")
        } catch {
            logError("Failed to save reference: \(error)", category: "enhancement")
        }
        
        // Download and save thumbnail if available
        if let imageURLString = similarRecipe.imageURL,
           let imageURL = URL(string: imageURLString) {
            Task {
                await downloadAndSaveThumbnail(from: imageURL, for: similarRecipe.title)
            }
        }
    }
    
    private func downloadAndSaveThumbnail(from url: URL, for title: String) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Verify it's valid image data
            guard let _ = UIImage(data: data) else {
                logWarning("Invalid image data from URL: \(url)", category: "enhancement")
                return
            }
            
            await MainActor.run {
                // Get existing additional images or create new array
                var additionalImages: [[String: Data]] = []
                if let existingData = originalRecipe.additionalImagesData,
                   let decoded = try? JSONDecoder().decode([[String: Data]].self, from: existingData) {
                    additionalImages = decoded
                }
                
                // Add new image with name
                let imageName = "Similar: \(title)"
                additionalImages.append(["name": imageName.data(using: .utf8)!, "data": data])
                
                // Save back to recipe
                if let encoded = try? JSONEncoder().encode(additionalImages) {
                    originalRecipe.additionalImagesData = encoded
                    originalRecipe.markAsModified()
                    
                    do {
                        try modelContext.save()
                        logInfo("Saved thumbnail for: \(title)", category: "enhancement")
                    } catch {
                        logError("Failed to save thumbnail: \(error)", category: "enhancement")
                    }
                }
            }
        } catch {
            logWarning("Failed to download thumbnail: \(error)", category: "enhancement")
        }
    }
}

// MARK: - Similar Recipe Card

struct SimilarRecipeCard: View {
    let recipe: SimilarRecipe
    let isSaved: Bool
    let onTap: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with image
                HStack(alignment: .top, spacing: 12) {
                    // Recipe image placeholder
                    if let imageURL = recipe.imageURL {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 80, height: 80)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, height: 80)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                            .frame(width: 80, height: 80)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Title and source
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recipe.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(recipe.source)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        // Match score
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text("\(Int(recipe.matchScore * 100))% Match")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                // Match reasons
                if !recipe.matchReasons.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why this matches:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ForEach(Array(recipe.matchReasons.prefix(3).enumerated()), id: \.offset) { _, reason in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                
                                Text(reason)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                
                // Quick info
                HStack(spacing: 16) {
                    if let time = recipe.totalTime {
                        Label(time, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let servings = recipe.servings {
                        Label(servings, systemImage: "person.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let cuisine = recipe.cuisine {
                        Label(cuisine, systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            }
            .buttonStyle(.plain)
            
            // Save button
            Button(action: onSave) {
                HStack {
                    Image(systemName: isSaved ? "checkmark.circle.fill" : "bookmark")
                    Text(isSaved ? "Saved to References" : "Save as Reference")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSaved ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(isSaved ? .green : .blue)
            }
            .buttonStyle(.plain)
            .disabled(isSaved)
        }
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Similar Recipe Detail View

struct SimilarRecipeDetailView: View {
    let recipe: SimilarRecipe
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Image
                    if let imageURL = recipe.imageURL {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 250)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 250)
                                    .clipped()
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.system(size: 80))
                                    .foregroundColor(.secondary)
                                    .frame(height: 250)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.2))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and source
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.title)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Button {
                                if let url = URL(string: recipe.sourceURL) {
                                    openURL(url)
                                }
                            } label: {
                                HStack {
                                    Text(recipe.source)
                                        .font(.subheadline)
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        
                        // Description
                        if let description = recipe.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Quick info
                        HStack(spacing: 20) {
                            if let prepTime = recipe.prepTime {
                                InfoBadge(icon: "timer", label: "Prep", value: prepTime)
                            }
                            if let cookTime = recipe.cookTime {
                                InfoBadge(icon: "flame", label: "Cook", value: cookTime)
                            }
                            if let servings = recipe.servings {
                                InfoBadge(icon: "person.2", label: "Serves", value: servings)
                            }
                        }
                        
                        Divider()
                        
                        // Match information
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                Text("Match Score: \(Int(recipe.matchScore * 100))%")
                                    .font(.headline)
                            }
                            
                            ForEach(recipe.matchReasons, id: \.self) { reason in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(reason)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        
                        Divider()
                        
                        // Ingredients
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ingredients")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(.blue)
                                        .padding(.top, 6)
                                    Text(ingredient)
                                        .font(.body)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Instructions")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                    
                                    Text(instruction)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Recipe Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

struct InfoBadge: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}
