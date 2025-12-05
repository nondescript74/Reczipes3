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
    
    // All available recipe models from RecipeCollection (stable UUIDs!)
    // Merged with image assignments for real-time updates
    private var availableRecipes: [RecipeModel] {
        let recipes = RecipeCollection.shared.allRecipes.map { recipe in
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
                Section("Available Recipes") {
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
                                HStack(spacing: 12) {
                                    // Thumbnail or placeholder
                                    if let imageName = recipe.imageName ?? imageName(for: recipe.id) {
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
        savedRecipes.contains { $0.id == recipe.id }
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
        .modelContainer(for: [Recipe.self, RecipeImageAssignment.self], inMemory: true)
}
