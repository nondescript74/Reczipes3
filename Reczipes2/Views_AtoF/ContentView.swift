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
    
    @EnvironmentObject private var appState: AppStateManager
    
    @State private var selectedRecipe: RecipeModel?
    @State private var showingImageAssignment = false
    @State private var showingDebug = false
    @State private var showingRecipeExtractor = false
    @State private var showingAllergenProfiles = false
    @State private var showingBackup = false
    @State private var showingSearch = false
    @State private var showingSavedLinks = false
    @State private var allergenFilterEnabled = false
    @State private var showOnlySafe = false
    @State private var isProcessingFilter = false
    @State private var cachedFilteredRecipes: [RecipeModel] = []
    @State private var cachedAllergenScores: [UUID: RecipeAllergenScore] = [:]
    
    // Active allergen profile
    private var activeProfile: UserAllergenProfile? {
        allergenProfiles.first { $0.isActive }
    }
    
    // Helper to get image name for a recipe
    private func imageName(for recipeID: UUID) -> String? {
        imageAssignments.first { $0.recipeID == recipeID }?.imageName
    }
    
    // Allergen scores for recipes (now cached)
    private var allergenScores: [UUID: RecipeAllergenScore] {
        cachedAllergenScores
    }
    
    // All available recipe models from SwiftData (Claude API-extracted)
    // Merged with image assignments for real-time updates
    private var availableRecipesBeforeFilter: [RecipeModel] {
        logDebug("Refreshing available recipes", category: "recipe")
        logDebug("Saved recipes count: \(savedRecipes.count)", category: "recipe")
        
        let allRecipes = RecipeCollection.shared.allRecipes(savedRecipes: savedRecipes)
        logDebug("Available recipes count: \(allRecipes.count)", category: "recipe")
        
        let recipes = allRecipes.map { recipe in
            // First check if the recipe model itself has an imageName (directly from Recipe object)
            if let existingImageName = recipe.imageName {
                logDebug("Recipe '\(recipe.title)' already has imageName: '\(existingImageName)' (ID: \(recipe.id))", category: "recipe")
                return recipe
            }
            // Fallback to checking RecipeImageAssignment (for legacy support)
            else if let assignedImageName = imageName(for: recipe.id) {
                logDebug("Found image assignment '\(assignedImageName)' for '\(recipe.title)' (ID: \(recipe.id))", category: "recipe")
                return recipe.withImageName(assignedImageName)
            } else {
                logWarning("No image for '\(recipe.title)' (ID: \(recipe.id))", category: "recipe")
                return recipe
            }
        }
        logDebug("Total assignments in DB: \(imageAssignments.count)", category: "storage")
        return recipes
    }
    
    // Filtered recipes based on allergen settings (now uses cached results)
    private var availableRecipes: [RecipeModel] {
        if allergenFilterEnabled {
            return cachedFilteredRecipes
        } else {
            return availableRecipesBeforeFilter
        }
    }
    
    // MARK: - Filter Processing
    
    /// Process allergen filtering in background to avoid blocking UI
    private func processAllergenFilter() {
        guard let profile = activeProfile else {
            cachedFilteredRecipes = availableRecipesBeforeFilter
            cachedAllergenScores = [:]
            return
        }
        
        // Show loading state
        isProcessingFilter = true
        
        // Capture values to use in detached task
        let recipesToProcess = availableRecipesBeforeFilter
        let shouldShowOnlySafe = showOnlySafe
        
        Task.detached(priority: .userInitiated) {
            // Analyze all recipes for allergens (this is the expensive operation)
            let scores = await AllergenAnalyzer.shared.analyzeRecipes(recipesToProcess, profile: profile)
            
            // Filter or sort based on settings
            let filteredRecipes: [RecipeModel]
            if shouldShowOnlySafe {
                filteredRecipes = await AllergenAnalyzer.shared.filterSafeRecipes(recipesToProcess, profile: profile)
            } else {
                // Sort by safety score
                filteredRecipes = await AllergenAnalyzer.shared.sortRecipesBySafety(recipesToProcess, profile: profile)
            }
            
            // Update UI on main thread
            await MainActor.run {
                cachedFilteredRecipes = filteredRecipes
                cachedAllergenScores = scores
                isProcessingFilter = false
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Global batch extraction status bar
            BatchExtractionStatusBar(manager: BatchExtractionManager.shared)
            
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
            .onAppear {
                restoreSelectedRecipe()
                // Initialize cached recipes
                cachedFilteredRecipes = availableRecipesBeforeFilter
            }
            .onChange(of: allergenFilterEnabled) { _, isEnabled in
                if isEnabled {
                    processAllergenFilter()
                } else {
                    // Clear cache when filter is disabled
                    cachedFilteredRecipes = availableRecipesBeforeFilter
                    cachedAllergenScores = [:]
                }
            }
            .onChange(of: showOnlySafe) { _, _ in
                if allergenFilterEnabled {
                    processAllergenFilter()
                }
            }
            .onChange(of: activeProfile?.id) { _, _ in
                if allergenFilterEnabled {
                    processAllergenFilter()
                }
            }
            .onChange(of: savedRecipes.count) { _, _ in
                // Recipes changed, update cache
                if allergenFilterEnabled {
                    processAllergenFilter()
                } else {
                    cachedFilteredRecipes = availableRecipesBeforeFilter
                }
            }
            .onChange(of: selectedRecipe) { _, newRecipe in
                // Save selected recipe to app state when it changes
                appState.selectedRecipeId = newRecipe?.id
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
            
            // Loading indicator when processing filter
            if isProcessingFilter {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing recipes...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
            }
            
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
                    Menu {
                        Button {
                            showingImageAssignment = true
                        } label: {
                            Label("Assign Images", systemImage: "photo.on.rectangle")
                        }
                        
                        Button {
                            showingSavedLinks = true
                        } label: {
                            Label("Saved Links", systemImage: "link.circle")
                        }
                        
                        Button {
                            showingBackup = true
                        } label: {
                            Label("Backup & Restore", systemImage: "arrow.up.arrow.down.circle")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloudKitSyncBadge()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSearch = true
                    } label: {
                        Label("Search Recipes", systemImage: "magnifyingglass")
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
                    CloudKitSyncBadge()
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingImageAssignment = true
                    } label: {
                        Label("Assign Images", systemImage: "photo.on.rectangle")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSavedLinks = true
                    } label: {
                        Label("Saved Links", systemImage: "link.circle")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingBackup = true
                    } label: {
                        Label("Backup & Restore", systemImage: "arrow.up.arrow.down.circle")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSearch = true
                    } label: {
                        Label("Search Recipes", systemImage: "magnifyingglass")
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
            .sheet(isPresented: $showingBackup) {
                RecipeBackupView()
            }
            .sheet(isPresented: $showingSearch) {
                RecipeSearchModalView(
                    recipes: .constant(availableRecipes),
                    selectedRecipe: $selectedRecipe
                )
            }
            .sheet(isPresented: $showingSavedLinks) {
                SavedLinksView()
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
    
    private func restoreSelectedRecipe() {
        // Restore selected recipe from app state if available
        if let recipeId = appState.selectedRecipeId {
            // Find the recipe in available recipes
            if let recipe = availableRecipes.first(where: { $0.id == recipeId }) {
                selectedRecipe = recipe
                logInfo("Restored selected recipe: \(recipe.title)", category: "state")
            } else {
                // Recipe no longer exists, clear the selection
                appState.selectedRecipeId = nil
            }
        }
    }
    
    private func isRecipeSaved(_ recipe: RecipeModel) -> Bool {
        RecipeCollection.shared.isRecipeSaved(recipe, savedRecipes: savedRecipes)
    }
    
    private func deleteRecipe(_ recipe: RecipeModel) {
        withAnimation {
            if let savedRecipe = savedRecipes.first(where: { $0.id == recipe.id }) {
                logInfo("Deleting recipe: \(savedRecipe.title) (ID: \(savedRecipe.id))", category: "recipe")
                
                // Delete associated image file if it exists
                if let imageName = savedRecipe.imageName {
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsPath.appendingPathComponent(imageName)
                    try? FileManager.default.removeItem(at: fileURL)
                    logInfo("Deleted image file: \(imageName)", category: "storage")
                }
                
                // Delete any RecipeImageAssignments for this recipe
                let assignmentsToDelete = imageAssignments.filter { $0.recipeID == recipe.id }
                for assignment in assignmentsToDelete {
                    modelContext.delete(assignment)
                    logDebug("Deleted image assignment for recipe", category: "storage")
                }
                
                // Delete the recipe itself
                modelContext.delete(savedRecipe)
                
                // Save the context to persist the deletion
                do {
                    try modelContext.save()
                    logInfo("Recipe deleted and changes saved", category: "recipe")
                } catch {
                    logError("Failed to save deletion: \(error)", category: "storage")
                }
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
            
            // Save the context
            do {
                try modelContext.save()
                logInfo("Recipe saved: \(newRecipe.title)", category: "recipe")
            } catch {
                logError("Failed to save recipe: \(error)", category: "storage")
            }
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
