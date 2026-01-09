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
    
    @State private var showingEditor = false
    @State private var selectedBook: RecipeBook?
    @State private var editingBook: RecipeBook?
    @State private var searchText = ""
    @State private var showingImport = false
    @State private var refreshID = UUID()
    
    // Grid layout
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
    ]
    
    private var filteredBooks: [RecipeBook] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { book in
                book.name.localizedCaseInsensitiveContains(searchText) ||
                book.bookDescription?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    emptyStateView
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
        ContentUnavailableView {
            Label("No Recipe Books", systemImage: "books.vertical")
        } description: {
            Text("Create a book to organize your recipes")
        } actions: {
            Button {
                showingEditor = true
            } label: {
                Label("Create Book", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Book Grid View
    
    private var bookGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredBooks) { book in
                    BookCardView(book: book, savedRecipes: savedRecipes)
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
