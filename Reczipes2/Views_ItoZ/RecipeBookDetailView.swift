//
//  RecipeBookDetailView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import SwiftUI
import SwiftData

struct RecipeBookDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var savedRecipes: [Recipe]
    
    let book: RecipeBook
    
    @State private var currentPage = 0
    @State private var showingRecipeSelector = false
    @State private var showingBookEditor = false
    @State private var showingExportOptions = false
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    @State private var exportError: Error?
    @State private var showingExportError = false
    
    // Get recipes in the book, maintaining order
    private var bookRecipes: [RecipeModel] {
        book.recipeIDs.compactMap { recipeID in
            savedRecipes.first { $0.id == recipeID }?.toRecipeModel()
        }
    }
    
    private var bookColor: Color {
        if let colorHex = book.color {
            return Color(hex: colorHex) ?? .blue
        }
        return .blue
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if bookRecipes.isEmpty {
                    emptyBookView
                } else {
                    recipePageView
                }
            }
            .navigationTitle(book.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingRecipeSelector = true
                        } label: {
                            Label("Add Recipes", systemImage: "plus")
                        }
                        
                        Button {
                            showingBookEditor = true
                        } label: {
                            Label("Edit Book", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button {
                            showingExportOptions = true
                        } label: {
                            Label("Export Book", systemImage: "square.and.arrow.up")
                        }
                        .disabled(bookRecipes.isEmpty)
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingRecipeSelector) {
                RecipeBookRecipeSelectorView(book: book)
            }
            .sheet(isPresented: $showingBookEditor) {
                RecipeBookEditorView(book: book)
            }
            .confirmationDialog("Export Recipe Book", isPresented: $showingExportOptions) {
                Button("Export with Images") {
                    Task {
                        await exportBook(includeImages: true)
                    }
                }
                
                Button("Export without Images") {
                    Task {
                        await exportBook(includeImages: false)
                    }
                }
                
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose whether to include images in the export. Files with images will be larger but more complete.")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Export Failed", isPresented: $showingExportError) {
                Button("OK") { }
            } message: {
                if let error = exportError {
                    Text(error.localizedDescription)
                }
            }
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Exporting Recipe Book...")
                                .font(.headline)
                        }
                        .padding(32)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }
    
    // MARK: - Empty Book View
    
    private var emptyBookView: some View {
        ContentUnavailableView {
            Label("Empty Book", systemImage: "book.closed")
        } description: {
            Text("Add recipes to \"\(book.name)\" to get started")
        } actions: {
            Button {
                showingRecipeSelector = true
            } label: {
                Label("Add Recipes", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(bookColor)
        }
    }
    
    // MARK: - Recipe Page View
    
    private var recipePageView: some View {
        VStack(spacing: 0) {
            // Page indicator
            HStack {
                Text("Recipe \(currentPage + 1) of \(bookRecipes.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Quick navigation
                if bookRecipes.count > 1 {
                    Button {
                        withAnimation {
                            currentPage = max(0, currentPage - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                    }
                    .disabled(currentPage == 0)
                    
                    Button {
                        withAnimation {
                            currentPage = min(bookRecipes.count - 1, currentPage + 1)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .disabled(currentPage == bookRecipes.count - 1)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Page turning view
            TabView(selection: $currentPage) {
                ForEach(Array(bookRecipes.enumerated()), id: \.element.id) { index, recipe in
                    RecipePageView(recipe: recipe, pageNumber: index + 1, bookColor: bookColor)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
    }
    
    // MARK: - Export
    
    private func exportBook(includeImages: Bool) async {
        isExporting = true
        exportError = nil
        
        do {
            let url = try await RecipeBookExportService.exportBook(
                book,
                recipes: bookRecipes,
                includeImages: includeImages
            )
            
            await MainActor.run {
                exportedFileURL = url
                isExporting = false
                showingShareSheet = true
            }
        } catch {
            await MainActor.run {
                exportError = error
                isExporting = false
                showingExportError = true
            }
            logError("Export failed: \(error)", category: "book-export")
        }
    }
}

// MARK: - Recipe Page View

struct RecipePageView: View {
    let recipe: RecipeModel
    let pageNumber: Int
    let bookColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Recipe image
                    if let imageName = recipe.imageName {
                        RecipeImageView(
                            imageName: imageName,
                            size: CGSize(width: geometry.size.width, height: 300),
                            cornerRadius: 0
                        )
                        .frame(height: 300)
                        .clipped()
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Page number decoration
                        HStack {
                            Rectangle()
                                .fill(bookColor)
                                .frame(width: 4, height: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Page \(pageNumber)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(recipe.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        // Header notes
                        if let headerNotes = recipe.headerNotes {
                            Text(headerNotes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Yield
                        if let recipeYield = recipe.yield {
                            HStack {
                                Image(systemName: "person.2")
                                    .foregroundStyle(bookColor)
                                Text(recipeYield)
                                    .font(.subheadline)
                            }
                        }
                        
                        Divider()
                        
                        // Ingredients
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Ingredients", systemImage: "list.bullet")
                                .font(.headline)
                                .foregroundStyle(bookColor)
                            
                            ForEach(recipe.ingredientSections, id: \.id) { section in
                                VStack(alignment: .leading, spacing: 8) {
                                    if let title = section.title {
                                        Text(title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    ForEach(section.ingredients, id: \.id) { ingredient in
                                        HStack(alignment: .top, spacing: 8) {
                                            Circle()
                                                .fill(bookColor.opacity(0.3))
                                                .frame(width: 6, height: 6)
                                                .padding(.top, 6)
                                            
                                            Text(ingredient.displayText)
                                                .font(.body)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Instructions", systemImage: "text.alignleft")
                                .font(.headline)
                                .foregroundStyle(bookColor)
                            
                            ForEach(recipe.instructionSections, id: \.id) { section in
                                VStack(alignment: .leading, spacing: 8) {
                                    if let title = section.title {
                                        Text(title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    ForEach(Array(section.steps.enumerated()), id: \.element.id) { index, step in
                                        HStack(alignment: .top, spacing: 12) {
                                            Text("\(index + 1)")
                                                .font(.body)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                                .frame(width: 28, height: 28)
                                                .background(bookColor, in: Circle())
                                            
                                            Text(step.text)
                                                .font(.body)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        if !recipe.notes.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Notes", systemImage: "note.text")
                                    .font(.headline)
                                    .foregroundStyle(bookColor)
                                
                                ForEach(recipe.notes, id: \.id) { note in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(note.type.rawValue.capitalized)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(note.text)
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        
                        // Reference
                        if let reference = recipe.reference {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Source", systemImage: "link")
                                    .font(.headline)
                                    .foregroundStyle(bookColor)
                                
                                Text(reference)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RecipeBook.self, Recipe.self, configurations: config)
    
    // Create a sample book
    let book = RecipeBook(
        name: "Favorites",
        bookDescription: "My favorite recipes",
        color: "FF6B6B"
    )
    
    container.mainContext.insert(book)
    
    return RecipeBookDetailView(book: book)
        .modelContainer(container)
}
//// MARK: - Share Sheet
//
//import UIKit
//
//struct ShareSheet: UIViewControllerRepresentable {
//    let items: [Any]
//    
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        let controller = UIActivityViewController(
//            activityItems: items,
//            applicationActivities: nil
//        )
//        return controller
//    }
//    
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
//        // No updates needed
//    }
//}

