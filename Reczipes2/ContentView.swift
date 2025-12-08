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
    
    @State private var selectedRecipe: RecipeModel?
    @State private var showingImageAssignment = false
    @State private var showingDebug = false
    
    // Helper to get image name for a recipe
    private func imageName(for recipeID: UUID) -> String? {
        imageAssignments.first { $0.recipeID == recipeID }?.imageName
    }
    
    // All available recipe models merged from bundled recipes and SwiftData
    // SwiftData recipes take precedence (user-edited versions)
    // Merged with image assignments for real-time updates
    private var availableRecipes: [RecipeModel] {
        let allRecipes = RecipeCollection.shared.allRecipes(savedRecipes: savedRecipes)
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

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedRecipe) {
                Section {
                    ForEach(availableRecipes) { recipe in
                        Button {
                            selectedRecipe = recipe
                        } label: {
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
                                
                                // Show indicator if recipe has been saved/edited
                                if isRecipeSaved(recipe) {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundStyle(.blue)
                                        .help("Edited & Saved")
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if isRecipeSaved(recipe) {
                                Button(role: .destructive) {
                                    deleteRecipe(recipe)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .contextMenu {
                            if isRecipeSaved(recipe) {
                                Button(role: .destructive) {
                                    deleteRecipe(recipe)
                                } label: {
                                    Label("Delete Saved Version", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text("All Recipes (\(availableRecipes.count))")
                } footer: {
                    if savedRecipes.isEmpty {
                        Text("Tap any recipe to view details. Use the save button to keep your changes.")
                    } else {
                        Text("\(savedRecipes.count) recipe(s) have been saved with your edits")
                    }
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
#else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingImageAssignment = true
                    } label: {
                        Label("Assign Images", systemImage: "photo.on.rectangle")
                    }
                }
#endif
            }
            .sheet(isPresented: $showingImageAssignment) {
                RecipeImageAssignmentView()
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
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, RecipeImageAssignment.self], inMemory: true)
}
