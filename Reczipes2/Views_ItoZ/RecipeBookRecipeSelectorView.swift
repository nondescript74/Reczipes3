//
//  RecipeBookRecipeSelectorView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import SwiftUI
import SwiftData

struct RecipeBookRecipeSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var savedRecipes: [Recipe]
    
    let book: RecipeBook
    
    @State private var searchText = ""
    @State private var selectedRecipeIDs = Set<UUID>()
    
    // Filter recipes that aren't already in the book
    private var availableRecipes: [Recipe] {
        savedRecipes.filter { recipe in
            !book.recipeIDs.contains(recipe.id)
        }
    }
    
    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return availableRecipes
        } else {
            return availableRecipes.filter { recipe in
                recipe.title.localizedCaseInsensitiveContains(searchText)
            }
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
            Group {
                if availableRecipes.isEmpty {
                    emptyStateView
                } else {
                    recipeListView
                }
            }
            .navigationTitle("Add Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search recipes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedRecipeIDs.count))") {
                        addSelectedRecipes()
                    }
                    .disabled(selectedRecipeIDs.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Recipes Available", systemImage: "tray")
        } description: {
            if savedRecipes.isEmpty {
                Text("Save some recipes first to add them to books")
            } else {
                Text("All your recipes are already in this book")
            }
        }
    }
    
    // MARK: - Recipe List View
    
    private var recipeListView: some View {
        List(filteredRecipes) { recipe in
            RecipeSelectionRow(
                recipe: recipe,
                isSelected: selectedRecipeIDs.contains(recipe.id),
                bookColor: bookColor
            )
            .contentShape(Rectangle())
            .onTapGesture {
                toggleSelection(recipe.id)
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Helper Methods
    
    private func toggleSelection(_ recipeID: UUID) {
        if selectedRecipeIDs.contains(recipeID) {
            selectedRecipeIDs.remove(recipeID)
        } else {
            selectedRecipeIDs.insert(recipeID)
        }
    }
    
    private func addSelectedRecipes() {
        // Add the selected recipe IDs to the book
        for recipeID in selectedRecipeIDs {
            if !book.recipeIDs.contains(recipeID) {
                book.recipeIDs.append(recipeID)
            }
        }
        
        book.dateModified = Date()
        
        do {
            try modelContext.save()
            logInfo("Added \(selectedRecipeIDs.count) recipes to book: \(book.name)", category: "book")
            dismiss()
        } catch {
            logError("Failed to add recipes to book: \(error)", category: "book")
        }
    }
}

// MARK: - Recipe Selection Row

struct RecipeSelectionRow: View {
    let recipe: Recipe
    let isSelected: Bool
    let bookColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            ZStack {
                Circle()
                    .strokeBorder(isSelected ? bookColor : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Circle()
                        .fill(bookColor)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
            
            // Recipe thumbnail
            if let imageName = recipe.imageName {
                RecipeImageView(
                    imageName: imageName,
                    size: CGSize(width: 60, height: 60),
                    cornerRadius: 8
                )
                .frame(width: 60, height: 60)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.gray)
                    }
            }
            
            // Recipe info
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let headerNotes = recipe.headerNotes {
                    Text(headerNotes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
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
    
    // Create some sample recipes
    let recipe1 = Recipe(
        id: UUID(),
        title: "Chocolate Chip Cookies",
        headerNotes: "Classic homemade cookies",
        recipeYield: "24 cookies",
        reference: nil,
        dateAdded: Date(),
        imageName: nil
    )
    
    let recipe2 = Recipe(
        id: UUID(),
        title: "Apple Pie",
        headerNotes: "Traditional American dessert",
        recipeYield: "8 servings",
        reference: nil,
        dateAdded: Date(),
        imageName: nil
    )
    
    container.mainContext.insert(book)
    container.mainContext.insert(recipe1)
    container.mainContext.insert(recipe2)
    
    return RecipeBookRecipeSelectorView(book: book)
        .modelContainer(container)
}
