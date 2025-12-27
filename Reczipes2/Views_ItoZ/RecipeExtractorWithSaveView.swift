//
//  RecipeExtractorWithSaveView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/8/25.
//

import SwiftUI
import SwiftData

// MARK: - Enhanced Recipe Extractor Integration

/// Wrapper view that saves extracted recipes to SwiftData
struct RecipeExtractorWithSaveView: View {
    let apiKey: String
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: RecipeExtractorViewModel
    @State private var showingSaveConfirmation = false
    
    init(apiKey: String) {
        self.apiKey = apiKey
        _viewModel = StateObject(wrappedValue: RecipeExtractorViewModel(apiKey: apiKey))
    }
    
    var body: some View {
        RecipeExtractorView(apiKey: apiKey)
            .toolbar {
                if viewModel.extractedRecipe != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveRecipe()
                        }
                    }
                }
            }
            .alert("Recipe Saved", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    viewModel.reset()
                }
            } message: {
                Text("The recipe has been added to your collection")
            }
    }
    
    private func saveRecipe() {
        guard let recipeModel = viewModel.extractedRecipe else { return }
        
        // Convert RecipeModel to SwiftData Recipe
        let recipe = Recipe(from: recipeModel)
        
        // Insert into SwiftData context
        modelContext.insert(recipe)
        
        // Save the context
        do {
            try modelContext.save()
            showingSaveConfirmation = true
        } catch {
            print("Failed to save recipe: \(error)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)
    
    return RecipeExtractorWithSaveView(apiKey: "preview-api-key")
        .modelContainer(container)
}
