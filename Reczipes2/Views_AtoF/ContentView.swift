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
    @Query(sort: \RecipeBook.dateModified, order: .reverse) private var books: [RecipeBook]
    
    @EnvironmentObject private var appState: AppStateManager
    
    @State private var selectedRecipe: RecipeModel?
    @State private var showingImageAssignment = false
    @State private var showingDebug = false
    @State private var showingRecipeExtractor = false
    @State private var showingAllergenProfiles = false
    @State private var showingBackup = false
    @State private var showingImport = false
    @State private var showingSearch = false
    @State private var showingSavedLinks = false
    @State private var filterMode: RecipeFilterMode = .none
    @State private var showOnlySafe = false
    @State private var isProcessingFilter = false
    @State private var cachedFilteredRecipes: [RecipeModel] = []
    @State private var cachedAllergenScores: [UUID: RecipeAllergenScore] = [:]
    @State private var cachedDiabetesScores: [UUID: DiabetesScore] = [:]
    @State private var cachedCombinedScores: [UUID: CombinedRecipeScore] = [:]
    
    // Active allergen profile
    private var activeProfile: UserAllergenProfile? {
        allergenProfiles.first { $0.isActive }
    }
    
    // Helper to get image name for a recipe
    private func imageName(for recipeID: UUID) -> String? {
        imageAssignments.first { $0.recipeID == recipeID }?.imageName
    }
    
    // Combined scores for recipes (now cached)
    private var combinedScores: [UUID: CombinedRecipeScore] {
        cachedCombinedScores
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
            if recipe.imageName != nil {
                //logDebug("Recipe '\(recipe.title)' already has imageName: '\(recipe.imageName!)' (ID: \(recipe.id))", category: "recipe")
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
    
    // Filtered recipes based on filter settings (now uses cached results)
    private var availableRecipes: [RecipeModel] {
        if filterMode != .none {
            return cachedFilteredRecipes
        } else {
            return availableRecipesBeforeFilter
        }
    }
    
    // MARK: - Filter Processing
    
    /// Process filtering in background to avoid blocking UI
    private func processFilter() {
        // If no filter, just use all recipes
        guard filterMode != .none else {
            cachedFilteredRecipes = availableRecipesBeforeFilter
            cachedAllergenScores = [:]
            cachedDiabetesScores = [:]
            cachedCombinedScores = [:]
            return
        }
        
        // Show loading state
        isProcessingFilter = true
        
        // Capture values to use in detached task
        let recipesToProcess = availableRecipesBeforeFilter
        let shouldShowOnlySafe = showOnlySafe
        let currentMode = filterMode
        let currentProfile = activeProfile
        
        Task.detached(priority: .userInitiated) {
            var allergenScores: [UUID: RecipeAllergenScore] = [:]
            var diabetesScores: [UUID: DiabetesScore] = [:]
            var combinedScores: [UUID: CombinedRecipeScore] = [:]
            
            // Analyze for allergens if needed
            if await currentMode.includesAllergenFilter, let profile = currentProfile {
                allergenScores = await AllergenAnalyzer.shared.analyzeRecipes(recipesToProcess, profile: profile)
            }
            
            // Analyze for diabetes if needed
            if await currentMode.includesDiabetesFilter {
                diabetesScores = await DiabetesAnalyzer.shared.analyzeRecipes(recipesToProcess)
            }
            
            // Create combined scores and pre-compute safety values
            // We create a tuple with precomputed values to avoid accessing computed properties
            // in nonisolated context
            var safetyInfo: [UUID: (isSafe: Bool, overallScore: Double)] = [:]
            
            for recipe in recipesToProcess {
                let score = CombinedRecipeScore(
                    recipeID: recipe.id,
                    allergenScore: allergenScores[recipe.id],
                    diabetesScore: diabetesScores[recipe.id],
                    filterMode: currentMode
                )
                combinedScores[recipe.id] = score
                
                // Pre-compute the computed properties while we're still in a safe context
                safetyInfo[recipe.id] = await (isSafe: score.isSafe, overallScore: score.overallScore)
            }
            
            // Filter or sort based on settings using pre-computed values
            let recipesWithScores = recipesToProcess.map { recipe -> (RecipeModel, Bool, Double) in
                let safety = safetyInfo[recipe.id] ?? (isSafe: true, overallScore: 0)
                return (recipe, safety.isSafe, safety.overallScore)
            }
            
            let filteredRecipes: [RecipeModel]
            if shouldShowOnlySafe {
                // Show only safe recipes
                filteredRecipes = recipesWithScores
                    .filter { $0.1 } // Filter by isSafe boolean
                    .map { $0.0 }    // Extract recipe
            } else {
                // Sort by safety score (safest first)
                filteredRecipes = recipesWithScores
                    .sorted { $0.2 < $1.2 } // Sort by overallScore
                    .map { $0.0 }           // Extract recipe
            }
            
            // Update UI on main thread
            // Explicitly capture values in capture list to satisfy Swift 6 concurrency
            await MainActor.run { [filteredRecipes, allergenScores, diabetesScores, combinedScores] in
                cachedFilteredRecipes = filteredRecipes
                cachedAllergenScores = allergenScores
                cachedDiabetesScores = diabetesScores
                cachedCombinedScores = combinedScores
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
            .onChange(of: filterMode) { _, _ in
                processFilter()
            }
            .onChange(of: showOnlySafe) { _, _ in
                if filterMode != .none {
                    processFilter()
                }
            }
            .onChange(of: activeProfile?.id) { _, _ in
                if filterMode.includesAllergenFilter {
                    processFilter()
                }
            }
            .onChange(of: activeProfile?.diabetesStatus) { _, _ in
                if filterMode.includesDiabetesFilter {
                    processFilter()
                }
            }
            .onChange(of: savedRecipes.count) { _, _ in
                // Recipes changed, update cache
                if filterMode != .none {
                    processFilter()
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
            // Filter bar with 4-state selector
            RecipeFilterBar(
                filterMode: $filterMode,
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
                            // Add to Book submenu
                            Menu {
                                if books.isEmpty {
                                    Button {
                                        // Switch to books tab to create a book
                                        appState.currentTab = .books
                                    } label: {
                                        Label("Create First Book", systemImage: "plus.circle")
                                    }
                                } else {
                                    ForEach(books) { book in
                                        Button {
                                            toggleRecipeInBook(recipe, book: book)
                                        } label: {
                                            HStack {
                                                Text(book.name)
                                                Spacer()
                                                if book.recipeIDs.contains(recipe.id) {
                                                    Image(systemName: "checkmark")
                                                        .foregroundStyle(.blue)
                                                }
                                            }
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button {
                                        // Switch to books tab to create a new book
                                        appState.currentTab = .books
                                    } label: {
                                        Label("Create New Book", systemImage: "plus.circle")
                                    }
                                }
                            } label: {
                                Label("Add to Book", systemImage: "book.closed")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                deleteRecipe(recipe)
                            } label: {
                                Label("Delete Recipe", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    RecipeFilterStatusHeader(
                        filterMode: filterMode,
                        showOnlySafe: showOnlySafe,
                        totalRecipes: availableRecipesBeforeFilter.count,
                        filteredCount: availableRecipes.count
                    )
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
                        appState.currentTab = .books
                    } label: {
                        Label("View Books", systemImage: "books.vertical")
                    }
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
            .sheet(isPresented: $showingImport) {
                RecipeBookImportView()
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
                
                // Show books this recipe is in
                if !booksContaining(recipe).isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "book.closed.fill")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                        Text(bookBadgeText(for: recipe))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Combined badge (shows allergen, diabetes, or both based on filter mode)
            if filterMode != .none, let score = combinedScores[recipe.id] {
                CombinedRecipeBadge(score: score, compact: true)
            }
        }
    }
    
    // MARK: - Book Helper Methods
    
    /// Returns all books that contain the given recipe
    private func booksContaining(_ recipe: RecipeModel) -> [RecipeBook] {
        books.filter { $0.recipeIDs.contains(recipe.id) }
    }
    
    /// Returns a formatted string describing which books contain this recipe
    private func bookBadgeText(for recipe: RecipeModel) -> String {
        let containingBooks = booksContaining(recipe)
        if containingBooks.count == 1 {
            return "in \(containingBooks[0].name)"
        } else if containingBooks.count > 1 {
            return "in \(containingBooks.count) books"
        }
        return ""
    }
    
    /// Returns the primary color for a book, or a default color
    private func bookColor(for book: RecipeBook) -> Color {
        if let colorHex = book.color {
            return Color(hex: colorHex) ?? .purple
        }
        return .purple
    }
    
    // MARK: - Helper Methods
    
    private func toggleRecipeInBook(_ recipe: RecipeModel, book: RecipeBook) {
        withAnimation {
            if book.recipeIDs.contains(recipe.id) {
                // Remove from book
                book.removeRecipe(recipe.id)
                logInfo("Removed '\(recipe.title)' from book '\(book.name)'", category: "books")
            } else {
                // Add to book
                book.addRecipe(recipe.id)
                logInfo("Added '\(recipe.title)' to book '\(book.name)'", category: "books")
            }
            
            // Save the context
            do {
                try modelContext.save()
            } catch {
                logError("Failed to update book membership: \(error)", category: "books")
            }
        }
    }
    
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
        .modelContainer(for: [Recipe.self, RecipeImageAssignment.self, UserAllergenProfile.self, RecipeBook.self, SavedLink.self], inMemory: true)
        .environmentObject(AppStateManager.shared)
}
// MARK: - Recipe Book Badge View

/// A compact badge showing which books contain a recipe
struct RecipeBookBadge: View {
    let books: [RecipeBook]
    let compact: Bool
    
    init(books: [RecipeBook], compact: Bool = true) {
        self.books = books
        self.compact = compact
    }
    
    var body: some View {
        if books.isEmpty {
            EmptyView()
        } else if compact {
            compactBadge
        } else {
            expandedBadge
        }
    }
    
    private var compactBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "book.closed.fill")
                .font(.caption2)
                .foregroundStyle(.purple)
            
            if books.count == 1 {
                Text("in \(books[0].name)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("in \(books.count) books")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var expandedBadge: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("In Recipe Books", systemImage: "books.vertical.fill")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.purple)
            
            ForEach(books) { book in
                HStack(spacing: 6) {
                    Circle()
                        .fill(bookColor(for: book))
                        .frame(width: 6, height: 6)
                    
                    Text(book.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(book.recipeCount) recipes")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(8)
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func bookColor(for book: RecipeBook) -> Color {
        if let colorHex = book.color {
            return Color(hex: colorHex) ?? .purple
        }
        return .purple
    }
}


