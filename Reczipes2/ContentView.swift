//
//  ContentView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.dateAdded, order: .reverse) private var savedRecipes: [Recipe]
    @Query private var imageAssignments: [RecipeImageAssignment]
    @Query private var allergenProfiles: [UserAllergenProfile]
    
    @State private var selectedRecipe: RecipeModel?
    @State private var showingImageAssignment = false
    @State private var showingDebug = false
    @State private var showingRecipeExtractor = false
    @State private var showingAllergenProfiles = false
    @State private var allergenFilterEnabled = false
    @State private var showOnlySafe = false
    
    // Active allergen profile
    private var activeProfile: UserAllergenProfile? {
        allergenProfiles.first { $0.isActive }
    }
    
    // Helper to get image name for a recipe
    private func imageName(for recipeID: UUID) -> String? {
        imageAssignments.first { $0.recipeID == recipeID }?.imageName
    }
    
    // Allergen scores for recipes
    private var allergenScores: [UUID: RecipeAllergenScore] {
        guard let profile = activeProfile, allergenFilterEnabled else {
            return [:]
        }
        return AllergenAnalyzer.shared.analyzeRecipes(availableRecipesBeforeFilter, profile: profile)
    }
    
    // All available recipe models from SwiftData (Claude API-extracted)
    // Merged with image assignments for real-time updates
    private var availableRecipesBeforeFilter: [RecipeModel] {
        print("🔄 Refreshing available recipes...")
        print("📊 Saved recipes count: \(savedRecipes.count)")
        
        let allRecipes = RecipeCollection.shared.allRecipes(savedRecipes: savedRecipes)
        print("📊 Available recipes count: \(allRecipes.count)")
        
        let recipes = allRecipes.map { recipe in
            if let assignedImageName = imageName(for: recipe.id) {
                print("✅ Found image '\(assignedImageName)' for '\(recipe.title)' (ID: \(recipe.id))")
                return recipe.withImageName(assignedImageName)
            } else {
                print("❌ No image for '\(recipe.title)' (ID: \(recipe.id))")
                return recipe
            }
        }
        print("📊 Total assignments in DB: \(imageAssignments.count)")
        return recipes
    }
    
    // Filtered recipes based on allergen settings
    private var availableRecipes: [RecipeModel] {
        guard let profile = activeProfile, allergenFilterEnabled else {
            return availableRecipesBeforeFilter
        }
        
        let recipes = availableRecipesBeforeFilter
        
        if showOnlySafe {
            return AllergenAnalyzer.shared.filterSafeRecipes(recipes, profile: profile)
        } else {
            // Sort by safety score
            return AllergenAnalyzer.shared.sortRecipesBySafety(recipes, profile: profile)
        }
    }

    var body: some View {
        NavigationSplitView {
            if availableRecipes.isEmpty {
                // Empty state when no recipes exist
                emptyStateView
            } else {
                // Recipe list when recipes are available
                recipeListView
            }
        } detail: {
            if let recipe = selectedRecipe {
                RecipeDetailView(
                    recipe: recipe,
                    isSaved: isRecipeSaved(recipe),
                    onSave: { saveRecipe(recipe) }
                )
                .id("\(recipe.id)-\(recipe.imageName ?? "no-image")")  // Force view refresh when recipe or image changes
            } else {
                ContentUnavailableView(
                    "Select a Recipe",
                    systemImage: "book.closed",
                    description: Text("Choose a recipe from the list to view its details")
                )
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Recipes Yet", systemImage: "book.closed")
        } description: {
            Text("Extract recipes from text or images using the Claude API to get started")
        } actions: {
            Button {
                showingRecipeExtractor = true
            } label: {
                Label("Extract Recipe", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Recipes")
        .sheet(isPresented: $showingRecipeExtractor) {
            RecipeExtractorView(apiKey: getAPIKey())
        }
    }
    
    // MARK: - Recipe List View
    
    private var recipeListView: some View {
        VStack(spacing: 0) {
            // Allergen filter bar
            AllergenFilterBar(
                filterEnabled: $allergenFilterEnabled,
                showOnlySafe: $showOnlySafe,
                activeProfile: activeProfile,
                onProfileTap: {
                    showingAllergenProfiles = true
                }
            )
            
            List(selection: $selectedRecipe) {
                Section {
                    ForEach(availableRecipes) { recipe in
                        Button {
                            selectedRecipe = recipe
                        } label: {
                            recipeRow(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteRecipe(recipe)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteRecipe(recipe)
                            } label: {
                                Label("Delete Recipe", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    if allergenFilterEnabled && showOnlySafe {
                        Text("Safe Recipes (\(availableRecipes.count))")
                    } else if allergenFilterEnabled {
                        Text("Recipes Sorted by Safety (\(availableRecipes.count))")
                    } else {
                        Text("All Recipes (\(availableRecipes.count))")
                    }
                } footer: {
                    Text("\(savedRecipes.count) recipe(s) in your collection")
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
#endif
            .navigationTitle("Recipes")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingImageAssignment = true
                    } label: {
                        Label("Assign Images", systemImage: "photo.on.rectangle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingRecipeExtractor = true
                    } label: {
                        Label("Extract Recipe", systemImage: "plus.circle")
                    }
                }
#else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingImageAssignment = true
                    } label: {
                        Label("Assign Images", systemImage: "photo.on.rectangle")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingRecipeExtractor = true
                    } label: {
                        Label("Extract Recipe", systemImage: "plus.circle")
                    }
                }
#endif
            }
            .sheet(isPresented: $showingImageAssignment) {
                RecipeImageAssignmentView()
            }
            .sheet(isPresented: $showingRecipeExtractor) {
                RecipeExtractorView(apiKey: getAPIKey())
            }
            .sheet(isPresented: $showingAllergenProfiles) {
                AllergenProfileView()
            }
        }
    }
    
    // MARK: - Recipe Row
    
    private func recipeRow(recipe: RecipeModel) -> some View {
        HStack(spacing: 12) {
            // Thumbnail or placeholder
            if let imageName = recipe.imageName {
                RecipeImageView(
                    imageName: imageName,
                    size: CGSize(width: 50, height: 50),
                    cornerRadius: 6
                )
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("Assign\nImage")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let headerNotes = recipe.headerNotes {
                    Text(headerNotes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Allergen badge
            if let score = allergenScores[recipe.id] {
                RecipeAllergenBadge(score: score, compact: true)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isRecipeSaved(_ recipe: RecipeModel) -> Bool {
        RecipeCollection.shared.isRecipeSaved(recipe, savedRecipes: savedRecipes)
    }
    
    private func deleteRecipe(_ recipe: RecipeModel) {
        withAnimation {
            if let savedRecipe = savedRecipes.first(where: { $0.id == recipe.id }) {
                modelContext.delete(savedRecipe)
            }
        }
    }
    
    private func saveRecipe(_ recipe: RecipeModel) {
        withAnimation {
            // Include the current image name (if any) when saving
            var recipeToSave = recipe
            if let assignedImage = imageName(for: recipe.id) {
                recipeToSave = recipe.withImageName(assignedImage)
            }
            
            let newRecipe = Recipe(from: recipeToSave)
            modelContext.insert(newRecipe)
        }
    }
    
    private func getAPIKey() -> String {
        // Get API key from keychain, or return empty string
        // The RecipeExtractorView will handle the case when API key is missing
        return APIKeyHelper.getAPIKey() ?? ""
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, RecipeImageAssignment.self, UserAllergenProfile.self], inMemory: true)
}
