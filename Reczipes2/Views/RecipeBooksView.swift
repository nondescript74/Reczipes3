//
//  RecipeBooksView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import SwiftUI
import SwiftData

struct RecipeBooksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecipeBook.dateModified, order: .reverse) private var books: [RecipeBook]
    @Query private var savedRecipes: [Recipe]
    @Query private var sharedBooks: [SharedRecipeBook]
    
    @State private var showingEditor = false
    @State private var selectedBook: RecipeBook?
    @State private var editingBook: RecipeBook?
    @State private var searchText = ""
    @State private var showingImport = false
    @State private var refreshID = UUID()
    @State private var contentFilter: ContentFilterMode = .all
    @State private var lastSyncDate: Date?
    
    // Sync interval: 5 minutes
    private let syncInterval: TimeInterval = 300
    
    // Grid layout
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
    ]
    
    /// Returns the SharedRecipeBook entry for a book if it exists
    private func sharedBookEntry(for book: RecipeBook) -> SharedRecipeBook? {
        sharedBooks.first { $0.bookID == book.id && $0.isActive }
    }
    
    private var filteredBooks: [RecipeBook] {
        var result = books
        let currentUserID = CloudKitSharingService.shared.currentUserID
        
        // Apply content filter (mine/shared/all)
        switch contentFilter {
        case .mine:
            // Show ALL user's own books (including ones they've shared)
            // Filter OUT books shared by OTHER users
            let sharedByOthersIDs = Set(
                sharedBooks
                    .filter { $0.isActive && $0.sharedByUserID != currentUserID }
                    .compactMap { $0.bookID }
            )
            result = result.filter { !sharedByOthersIDs.contains($0.id) }
            
        case .shared:
            // Only show books shared by OTHER users
            let sharedByOthersIDs = Set(
                sharedBooks
                    .filter { $0.isActive && $0.sharedByUserID != currentUserID }
                    .compactMap { $0.bookID }
            )
            result = result.filter { sharedByOthersIDs.contains($0.id) }
            
        case .all:
            // Show all books (user's own + shared by others)
            break
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { book in
                book.name.localizedCaseInsensitiveContains(searchText) ||
                book.bookDescription?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Deduplicate books by ID (just in case)
        var seenIDs = Set<UUID>()
        result = result.filter { book in
            if seenIDs.contains(book.id) {
                logWarning("⚠️ Duplicate book ID detected: \(book.id) (\(book.name))", category: "book")
                return false
            }
            seenIDs.insert(book.id)
            return true
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content filter picker (Mine/Shared/All) - ALWAYS visible
                ContentFilterPicker(
                    selectedFilter: $contentFilter,
                    contentType: "Books"
                )
                .onChange(of: contentFilter) { oldValue, newValue in
                    // Sync community books when switching to "Shared" tab
                    if newValue == .shared {
                        Task {
                            await syncCommunityBooksIfNeeded()
                        }
                    }
                }
                
                // Main content
                if filteredBooks.isEmpty {
                    if books.isEmpty {
                        emptyStateView
                    } else {
                        // Books exist but none match the filter
                        emptyFilterStateView
                    }
                } else {
                    bookGridView
                }
            }
            .navigationTitle("Recipe Books")
            .searchable(text: $searchText, prompt: "Search books")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingEditor = true
                        } label: {
                            Label("New Book", systemImage: "plus")
                        }
                        
                        Button {
                            showingImport = true
                        } label: {
                            Label("Import Book", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                RecipeBookEditorView(book: editingBook)
                    .onDisappear {
                        editingBook = nil
                        // Force refresh to ensure images reload
                        refreshID = UUID()
                    }
            }
            .sheet(isPresented: $showingImport) {
                RecipeBookImportView()
            }
            .sheet(item: $selectedBook) { book in
                // Use different views for own books vs. shared books
                if let sharedEntry = sharedBookEntry(for: book),
                   sharedEntry.sharedByUserID != CloudKitSharingService.shared.currentUserID {
                    // Shared by someone else - use read-only view
                    ReadOnlyRecipeBookDetailView(book: book, sharedEntry: sharedEntry)
                } else {
                    // Own book or not shared - use full editor
                    RecipeBookDetailView(book: book)
                }
            }
            .onChange(of: refreshID) { oldValue, newValue in
                // When UI refreshes (e.g., after sync), check if selected book still exists
                if let selected = selectedBook {
                    let selectedID = selected.id
                    let descriptor = FetchDescriptor<RecipeBook>(
                        predicate: #Predicate<RecipeBook> { book in
                            book.id == selectedID
                        }
                    )
                    
                    do {
                        let fetchedBooks = try modelContext.fetch(descriptor)
                        if fetchedBooks.isEmpty {
                            // Book was deleted (likely by sync), dismiss sheet gracefully
                            logInfo("📚 Dismissing sheet - book '\(selected.name)' was deleted", category: "book")
                            selectedBook = nil
                        }
                    } catch {
                        // If fetch fails, also dismiss to prevent crashes
                        logError("❌ Failed to verify book existence: \(error)", category: "book")
                        selectedBook = nil
                    }
                }
            }
            .onAppear {
                // Sync community books when view appears to catch any unshared books
                Task {
                    await syncCommunityBooksIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            
            ContentUnavailableView {
                Label(emptyStateTitle, systemImage: "books.vertical")
            } description: {
                Text(emptyStateDescriptionText)
            } actions: {
                if contentFilter != .mine {
                    Button {
                        contentFilter = .mine
                    } label: {
                        Label("Show My Books", systemImage: "person.fill")
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                }
                
                if contentFilter != .mine {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("Create Book", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("Create Book", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
        }
    }
    
    private var emptyStateTitle: String {
        switch contentFilter {
        case .mine:
            return "No Recipe Books"
        case .shared:
            return "No Shared Books"
        case .all:
            return "No Books"
        }
    }
    
    private var emptyStateDescriptionText: String {
        switch contentFilter {
        case .mine:
            return "Create a book to organize your recipes"
        case .shared:
            return "No books have been shared by the community yet. Check back later or create and share your own books!"
        case .all:
            return "Create your first book to get started"
        }
    }
    
    private var emptyFilterStateView: some View {
        VStack {
            Spacer()
            
            ContentUnavailableView {
                Label("No Books Found", systemImage: "books.vertical")
            } description: {
                Text(emptyFilterDescription)
            } actions: {
                Button {
                    contentFilter = .all
                } label: {
                    Label("Show All Books", systemImage: "square.grid.2x2.fill")
                }
                .buttonStyle(BorderedProminentButtonStyle())
            }
            
            Spacer()
        }
    }
    
    private var emptyFilterDescription: String {
        if !searchText.isEmpty {
            return "No books match your search"
        }
        
        switch contentFilter {
        case .mine:
            return "You don't have any personal books yet"
        case .shared:
            return "No books have been shared with you"
        case .all:
            return "No books found"
        }
    }
    
    // MARK: - Book Grid View
    
    private var bookGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { index, book in
                    BookCardView(
                        book: book,
                        savedRecipes: savedRecipes,
                        sharedEntry: sharedBookEntry(for: book),
                        showSharedInfo: contentFilter != .mine
                    )
                        .id("\(book.id)-\(refreshID)-\(index)")
                        .onTapGesture {
                            selectedBook = book
                        }
                        .contextMenu {
                            Button {
                                editingBook = book
                                showingEditor = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                deleteBook(book)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteBook(_ book: RecipeBook) {
        withAnimation {
            // Delete all recipes in this book
            let recipeIDsToDelete = book.recipeIDs
            logInfo("Deleting recipe book '\(book.name)' and \(recipeIDsToDelete.count) associated recipes", category: "book")
            
            // Fetch and delete each recipe
            for recipeID in recipeIDsToDelete {
                let descriptor = FetchDescriptor<Recipe>(
                    predicate: #Predicate<Recipe> { recipe in
                        recipe.id == recipeID
                    }
                )
                
                if let recipes = try? modelContext.fetch(descriptor),
                   let recipe = recipes.first {
                    logDebug("Deleting recipe '\(recipe.title)' (ID: \(recipeID))", category: "book")
                    modelContext.delete(recipe)
                }
            }
            
            // Delete cover image file if it exists
            if let coverImage = book.coverImageName {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsPath.appendingPathComponent(coverImage)
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            // Delete the book itself
            modelContext.delete(book)
            
            // Save changes
            do {
                try modelContext.save()
                logInfo("Successfully deleted book '\(book.name)' and its recipes", category: "book")
            } catch {
                logError("Failed to save after deleting book: \(error)", category: "book")
            }
        }
    }
    
    /// Sync community books from CloudKit to local SwiftData
    /// Only syncs if enough time has passed since the last sync
    private func syncCommunityBooksIfNeeded() async {
        // Check if we need to sync
        if let lastSync = lastSyncDate {
            let timeSinceLastSync = Date().timeIntervalSince(lastSync)
            if timeSinceLastSync < syncInterval {
                logInfo("📚 Skipping sync - last synced \(Int(timeSinceLastSync))s ago", category: "sharing")
                return
            }
        }
        
        logInfo("📚 Syncing community books to local SwiftData...", category: "sharing")
        
        do {
            try await CloudKitSharingService.shared.syncCommunityBooksToLocal(modelContext: modelContext)
            
            await MainActor.run {
                lastSyncDate = Date()
                refreshID = UUID() // Force UI refresh
                logInfo("✅ Community books sync completed successfully", category: "sharing")
            }
        } catch {
            logError("❌ Failed to sync community books: \(error)", category: "sharing")
            // Log the error but don't show it to the user
            // The sync will automatically retry next time they switch tabs
        }
    }
}

// MARK: - Book Card View

struct BookCardView: View {
    let book: RecipeBook
    let savedRecipes: [Recipe]
    let sharedEntry: SharedRecipeBook?
    let showSharedInfo: Bool
    
    // Cache book data on init to avoid faults
    private let bookID: UUID
    private let cachedCoverImageName: String?
    private let cachedCoverImageData: Data?
    private let cachedBookName: String
    private let cachedRecipeCount: Int
    private let cachedBookDescription: String?
    private let cachedBookColor: String?
    
    init(book: RecipeBook, savedRecipes: [Recipe], sharedEntry: SharedRecipeBook?, showSharedInfo: Bool) {
        self.book = book
        self.savedRecipes = savedRecipes
        self.sharedEntry = sharedEntry
        self.showSharedInfo = showSharedInfo
        
        // Cache book properties to avoid faults when object is deleted
        self.bookID = book.id
        self.cachedCoverImageName = book.coverImageName
        self.cachedCoverImageData = book.coverImageData
        self.cachedBookName = book.name
        self.cachedRecipeCount = book.recipeIDs.count
        self.cachedBookDescription = book.bookDescription
        self.cachedBookColor = book.color
    }
    
    // Use cached properties instead of accessing the book object directly
    private var coverImageName: String? {
        cachedCoverImageName
    }
    
    private var coverImageData: Data? {
        cachedCoverImageData
    }
    
    private var bookName: String {
        cachedBookName
    }
    
    private var recipeCount: Int {
        cachedRecipeCount
    }
    
    private var bookDescription: String? {
        cachedBookDescription
    }
    
    private var bookColor: Color {
        if let colorHex = cachedBookColor {
            return Color(hex: colorHex) ?? .blue
        }
        return .blue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image or placeholder
            ZStack {
                if coverImageName != nil || coverImageData != nil {
                    RecipeImageView(
                        imageName: coverImageName,
                        imageData: coverImageData,
                        size: CGSize(width: 160, height: 220),
                        cornerRadius: 12
                    )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [bookColor, bookColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 220)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.white)
                                
                                Text(bookName)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .padding(.horizontal, 8)
                            }
                        }
                }
                
                // Recipe count badge
                VStack {
                    HStack {
                        Spacer()
                        Text("\(recipeCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(8)
                    }
                    Spacer()
                }
            }
            .frame(height: 220)
            
            // Book name (if we have cover image)
            if coverImageName != nil || coverImageData != nil {
                Text(bookName)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // Show who shared this book if it's shared
            if showSharedInfo, let sharedEntry = sharedEntry {
                HStack(spacing: 4) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("Shared by \(sharedEntry.sharedByUserName ?? "Someone")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Description
            if let description = bookDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


#Preview {
    RecipeBooksView()
        .modelContainer(for: [RecipeBook.self, Recipe.self], inMemory: true)
}
