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
        
        // Apply content filter (mine/shared/all)
        switch contentFilter {
        case .mine:
            // Only show books that are NOT in the shared list
            let sharedBookIDs = Set(sharedBooks.filter { $0.isActive }.map { $0.bookID })
            result = result.filter { !sharedBookIDs.contains($0.id) }
            
        case .shared:
            // Only show books from the shared list (shared by others)
            let sharedBookIDs = Set(sharedBooks.filter { $0.isActive }.map { $0.bookID })
            result = result.filter { sharedBookIDs.contains($0.id) }
            
        case .all:
            // Show all books
            break
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { book in
                book.name.localizedCaseInsensitiveContains(searchText) ||
                book.bookDescription?.localizedCaseInsensitiveContains(searchText) == true
            }
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
                RecipeBookDetailView(book: book)
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
                ForEach(filteredBooks) { book in
                    BookCardView(
                        book: book,
                        savedRecipes: savedRecipes,
                        sharedEntry: sharedBookEntry(for: book),
                        showSharedInfo: contentFilter != .mine
                    )
                        .id("\(book.id)-\(refreshID)")
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
            // Delete cover image if it exists
            if let coverImage = book.coverImageName {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsPath.appendingPathComponent(coverImage)
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            modelContext.delete(book)
            try? modelContext.save()
        }
    }
}

// MARK: - Book Card View

struct BookCardView: View {
    let book: RecipeBook
    let savedRecipes: [Recipe]
    let sharedEntry: SharedRecipeBook?
    let showSharedInfo: Bool
    
    // Use computed properties to ensure we get fresh data
    private var coverImageName: String? {
        book.coverImageName
    }
    
    private var bookName: String {
        book.name
    }
    
    private var recipeCount: Int {
        book.recipeCount
    }
    
    private var bookDescription: String? {
        book.bookDescription
    }
    
    private var bookColor: Color {
        if let colorHex = book.color {
            return Color(hex: colorHex) ?? .blue
        }
        return .blue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image or placeholder
            ZStack {
                if let coverImageName = coverImageName {
                    RecipeImageView(
                        imageName: coverImageName,
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
            if coverImageName != nil {
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
