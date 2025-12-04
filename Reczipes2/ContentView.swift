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
    
    @State private var selectedRecipe: RecipeModel?
    
    // All available recipe models from Extensions
    private let availableRecipes: [RecipeModel] = [
        .limePickleExample,
        .ambliNiChutney,
        .carrotPickle,
        .corianderChutney,
        .cucumberRaita,
        .dhokraChutney,
        .driedCarrots,
        .eggplantRaita,
        .garamMasala,
        .ghee
    ]

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedRecipe) {
                Section("Available Recipes") {
                    ForEach(availableRecipes) { recipe in
                        Button {
                            selectedRecipe = recipe
                        } label: {
                            HStack {
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
                                
                                if isRecipeSaved(recipe) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if !savedRecipes.isEmpty {
                    Section("Saved Recipes (\(savedRecipes.count))") {
                        ForEach(savedRecipes) { recipe in
                            Button {
                                if let recipeModel = recipe.toRecipeModel() {
                                    selectedRecipe = recipeModel
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recipe.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        Text("Added \(recipe.dateAdded, format: .dateTime.month().day().year())")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "bookmark.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteRecipes)
                    }
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
#endif
            .navigationTitle("Recipes")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
            }
        } detail: {
            if let recipe = selectedRecipe {
                RecipeDetailView(
                    recipe: recipe,
                    isSaved: isRecipeSaved(recipe),
                    onSave: { saveRecipe(recipe) }
                )
            } else {
                ContentUnavailableView(
                    "Select a Recipe",
                    systemImage: "book.closed",
                    description: Text("Choose a recipe from the list to view its details")
                )
            }
        }
    }
    
    private func isRecipeSaved(_ recipe: RecipeModel) -> Bool {
        savedRecipes.contains { $0.id == recipe.id }
    }
    
    private func saveRecipe(_ recipe: RecipeModel) {
        withAnimation {
            let newRecipe = Recipe(from: recipe)
            modelContext.insert(newRecipe)
        }
    }
    
    private func deleteRecipes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(savedRecipes[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
