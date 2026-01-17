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
    @State private var showingImport = false
    @State private var showingSearch = false
    @State private var showingSavedLinks = false
    @State private var filterMode: RecipeFilterMode = .none
    @State private var showOnlySafe = false
    @State private var isProcessingFilter = false
    @State private var cachedAllRecipes: [RecipeModel] = [] // NEW: Cache for all recipes
    @State private var cachedFilteredRecipes: [RecipeModel] = []
    @State private var cachedAllergenScores: [UUID: RecipeAllergenScore] = [:]
    @State private var cachedDiabetesScores: [UUID: DiabetesScore] = [:]
    @State private var cachedCombinedScores: [UUID: CombinedRecipeScore] = [:]
    @State private var cachedNutritionalScores: [UUID: NutritionalScore] = [:]
    
    // Content filter for showing mine/shared/all
    @State private var contentFilter: ContentFilterMode = .all
    @Query private var sharedRecipes: [SharedRecipe]
    
    // Active allergen profile
    private var activeProfile: UserAllergenProfile? {
        allergenProfiles.first { $0.isActive == true }
    }
    
    // Helper to get image name for a recipe
    private func imageName(for recipeID: UUID) -> String? {
        imageAssignments.first { $0.recipeID == recipeID }?.imageName
    }
    
    // Combined scores for recipes (now cached)
    private var combinedScores: [UUID: CombinedRecipeScore] {
        cachedCombinedScores
    }
    
    // All available recipe models - now returns cached version
    private var availableRecipesBeforeFilter: [RecipeModel] {
        cachedAllRecipes
    }
    
    // Filtered recipes based on filter settings (now uses cached results)
    private var availableRecipes: [RecipeModel] {
        let baseRecipes = filterMode != .none ? cachedFilteredRecipes : cachedAllRecipes
        
        // Apply content filter (mine/shared/all)
        return applyContentFilter(to: baseRecipes)
    }
    
    /// Applies the content filter (mine/shared/all) to recipes
    private func applyContentFilter(to recipes: [RecipeModel]) -> [RecipeModel] {
        switch contentFilter {
        case .mine:
            // Only show recipes that are NOT in the shared list
            let sharedRecipeIDs = Set(sharedRecipes.filter { $0.isActive }.map { $0.recipeID })
            return recipes.filter { !sharedRecipeIDs.contains($0.id) }
            
        case .shared:
            // Only show recipes from the shared list (shared by others)
            let sharedRecipeIDs = Set(sharedRecipes.filter { $0.isActive }.map { $0.recipeID })
            return recipes.filter { sharedRecipeIDs.contains($0.id) }
            
        case .all:
            // Show all recipes
            return recipes
        }
    }
    
    // MARK: - Recipe Loading
    
    /// Load and cache all recipes from SwiftData
    private func refreshRecipeCache() {
        logDebug("🔄 Refreshing recipe cache", category: "recipe")
        logDebug("Saved recipes count: \(savedRecipes.count)", category: "recipe")
        
        let allRecipes = RecipeCollection.shared.allRecipes(savedRecipes: savedRecipes)
        logDebug("Available recipes count: \(allRecipes.count)", category: "recipe")
        
        let recipes = allRecipes.map { recipe in
            // First check if the recipe model itself has an imageName (directly from Recipe object)
            if recipe.imageName != nil {
                return recipe
            }
            // Fallback to checking RecipeImageAssignment (for legacy support)
            else if let assignedImageName = imageName(for: recipe.id) {
                logDebug("Found image assignment '\(assignedImageName)' for '\(recipe.title)' (ID: \(recipe.id))", category: "recipe")
                return recipe.withImageName(assignedImageName)
            } else {
                return recipe
            }
        }
        logDebug("Total assignments in DB: \(imageAssignments.count)", category: "storage")
        
        // Update cache
        cachedAllRecipes = recipes
        
        // If not filtering, update filtered cache too
        if filterMode == .none {
            cachedFilteredRecipes = recipes
        }
    }
    
    // MARK: - Filter Processing
    
    /// Process filtering in background to avoid blocking UI
    private func processFilter() {
        // If no filter, just use all recipes
        guard filterMode != .none else {
            cachedFilteredRecipes = cachedAllRecipes
            cachedAllergenScores = [:]
            cachedDiabetesScores = [:]
            cachedCombinedScores = [:]
            return
        }
        
        // Show loading state
        isProcessingFilter = true
        
        // Capture values to use in task
        let recipesToProcess = cachedAllRecipes
        let shouldShowOnlySafe = showOnlySafe
        let currentMode = filterMode
        let currentProfile = activeProfile
        
        // Use regular Task instead of Task.detached to avoid sendability issues
        Task(priority: .userInitiated) {
            var allergenScores: [UUID: RecipeAllergenScore] = [:]
            var diabetesScores: [UUID: DiabetesScore] = [:]
            var combinedScores: [UUID: CombinedRecipeScore] = [:]
            var nutritionalScores: [UUID: NutritionalScore] = [:]
            
            // Analyze for allergens if needed
            if currentMode.includesAllergenFilter, let profile = currentProfile {
                allergenScores = AllergenAnalyzer.shared.analyzeRecipes(recipesToProcess, profile: profile)
            }
            
            // Analyze for diabetes if needed
            if currentMode.includesDiabetesFilter {
                diabetesScores = DiabetesAnalyzer.shared.analyzeRecipes(recipesToProcess)
            }
            
            if currentMode.includesNutritionalFilter,
               let profile = currentProfile,
               let goals = profile.nutritionalGoals {
                nutritionalScores = NutritionalAnalyzer.shared.analyzeRecipes(
                    recipesToProcess,
                    goals: goals
                )
            }
            
            // Create combined scores
            for recipe in recipesToProcess {
                let score = CombinedRecipeScore(
                    recipeID: recipe.id,
                    allergenScore: allergenScores[recipe.id],
                    diabetesScore: diabetesScores[recipe.id],
                    nutritionalScore: nutritionalScores[recipe.id],
                    filterMode: currentMode
                )
                combinedScores[recipe.id] = score
            }
            
            // Filter or sort based on settings
            let filteredRecipes: [RecipeModel]
            if shouldShowOnlySafe {
                // Show only safe recipes
                filteredRecipes = recipesToProcess.filter { recipe in
                    guard let score = combinedScores[recipe.id] else { return true }
                    return score.isSafe
                }
            } else {
                // Sort by safety score (safest first)
                filteredRecipes = recipesToProcess.sorted { recipe1, recipe2 in
                    let score1 = combinedScores[recipe1.id]?.overallScore ?? 0
                    let score2 = combinedScores[recipe2.id]?.overallScore ?? 0
                    return score1 < score2
                }
            }
            
            // Update UI on main thread
            await MainActor.run {
                cachedFilteredRecipes = filteredRecipes
                cachedAllergenScores = allergenScores
                cachedDiabetesScores = diabetesScores
                cachedCombinedScores = combinedScores
                cachedNutritionalScores = nutritionalScores
                isProcessingFilter = false
            }
        }
    }
    
    @MainActor
    private func shareRecipe(_ recipe: RecipeModel) async {
        do {
            _ = try await CloudKitSharingService.shared.shareRecipe(
                recipe,
                modelContext: modelContext
            )
            // Show success message
            logInfo("Successfully shared recipe: \(recipe.title)", category: "sharing")
        } catch {
            // Show error
            logError("Failed to share recipe: \(error)", category: "sharing")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Global batch extraction status bar
            BatchExtractionStatusBar(manager: BatchExtractionManager.shared)
            
            NavigationSplitView {
                VStack(spacing: 0) {
                    // Content filter picker (Mine/Shared/All) - ALWAYS visible
                    ContentFilterPicker(
                        selectedFilter: $contentFilter,
                        contentType: "Recipes"
                    )
                    
                    if availableRecipes.isEmpty {
                        // Empty state when no recipes exist (but filter picker still visible above)
                        emptyStateViewContent
                    } else {
                        // Recipe list when recipes are available
                        recipeListContent
                    }
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
                // Initialize recipe cache
                refreshRecipeCache()
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
                // Recipes changed, refresh cache and reprocess filter if needed
                refreshRecipeCache()
                if filterMode != .none {
                    processFilter()
                }
            }
            .onChange(of: selectedRecipe) { _, newRecipe in
                // Save selected recipe to app state when it changes
                appState.selectedRecipeId = newRecipe?.id
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateViewContent: some View {
        VStack {
            Spacer()
            
            ContentUnavailableView {
                Label(emptyStateTitle, systemImage: "book.closed")
            } description: {
                Text(emptyStateDescription)
            } actions: {
                if contentFilter != .mine {
                    Button {
                        contentFilter = .mine
                    } label: {
                        Label("Show My Recipes", systemImage: "person.fill")
                    }
                }
                
                Button {
                    showingRecipeExtractor = true
                } label: {
                    Label("Extract Recipe", systemImage: "plus.circle.fill")
                }
            }
            
            Spacer()
        }
        .navigationTitle("Recipes")
        .sheet(isPresented: $showingRecipeExtractor) {
            RecipeExtractorView(apiKey: getAPIKey())
        }
    }
    
    private var emptyStateTitle: String {
        switch contentFilter {
        case .mine:
            return "No Recipes Yet"
        case .shared:
            return "No Shared Recipes"
        case .all:
            return "No Recipes"
        }
    }
    
    private var emptyStateDescription: String {
        switch contentFilter {
        case .mine:
            return "Extract recipes from text or images using the Claude API to get started"
        case .shared:
            return "No recipes have been shared by the community yet. Check back later or create and share your own recipes!"
        case .all:
            return "No recipes found. Extract your first recipe to get started!"
        }
    }
    
    // MARK: - Recipe List View
    
    private var recipeListContent: some View {
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
                            
                            Button {
                                Task {
                                    await shareRecipe(recipe)
                                }
                            } label: {
                                Label("Share with Community", systemImage: "square.and.arrow.up")
                            }
                            
                            
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
    
    /// Returns the SharedRecipe entry for a recipe if it exists
    private func sharedRecipeEntry(for recipe: RecipeModel) -> SharedRecipe? {
        sharedRecipes.first { $0.recipeID == recipe.id && $0.isActive }
    }
    
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
                
                // Show who shared this recipe if it's shared
                if contentFilter != .mine, let sharedEntry = sharedRecipeEntry(for: recipe) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text("Shared by \(sharedEntry.sharedByUserName ?? "Someone")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
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
            if (filterMode == .nutrition || filterMode == .all),
               let score = cachedNutritionalScores[recipe.id] {
                NutritionalBadge(score: score, compact: true)
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


