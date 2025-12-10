//
//  RecipeExtractorView.swift
//  Reczipes2
//
//  Created for Claude-powered recipe extraction
//

import SwiftUI
import PhotosUI
import SwiftData

struct RecipeExtractorView: View {
    @StateObject private var viewModel: RecipeExtractorViewModel
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showImageComparison = false
    @State private var showingSaveConfirmation = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    init(apiKey: String) {
        _viewModel = StateObject(wrappedValue: RecipeExtractorViewModel(apiKey: apiKey))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image Selection Section
                    imageSelectionSection
                    
                    // Preprocessing Toggle
                    if viewModel.selectedImage != nil {
                        preprocessingToggle
                    }
                    
                    // Image Preview
                    if let image = viewModel.selectedImage {
                        imagePreviewSection(image: image)
                    }
                    
                    // Loading Indicator
                    if viewModel.isLoading {
                        loadingSection
                    }
                    
                    // Error Display
                    if let error = viewModel.errorMessage {
                        errorSection(message: error)
                    }
                    
                    // Extracted Recipe
                    if let recipe = viewModel.extractedRecipe {
                        extractedRecipeSection(recipe: recipe)
                    }
                }
                .padding()
            }
            .navigationTitle("Recipe Extractor")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let recipe = viewModel.extractedRecipe {
                        Button {
                            print("🔘 Save Recipe button tapped!")
                            saveRecipe()
                        } label: {
                            Text("Save Recipe")
                        }
                        .buttonStyle(.borderedProminent)
                        .onAppear {
                            print("✅ Save Recipe button is visible for: \(recipe.title)")
                        }
                    } else {
                        Text("No recipe")
                            .onAppear {
                                print("⚠️ No recipe available to save")
                            }
                    }
                }
            }
            .alert("Recipe Saved!", isPresented: $showingSaveConfirmation) {
                Button("View in Collection") {
                    // Dismiss and let the ContentView refresh
                    dismiss()
                }
                Button("Extract Another") {
                    viewModel.reset()
                }
            } message: {
                if let recipe = viewModel.extractedRecipe {
                    if viewModel.selectedImage != nil {
                        Text("\"\(recipe.title)\" and its image have been added to your recipe collection.")
                    } else {
                        Text("\"\(recipe.title)\" has been added to your recipe collection.")
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $viewModel.selectedImage, sourceType: .photoLibrary) { image in
                    Task {
                        await viewModel.extractRecipe(from: image)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $viewModel.selectedImage, sourceType: .camera) { image in
                    Task {
                        await viewModel.extractRecipe(from: image)
                    }
                }
            }
            .sheet(isPresented: $showImageComparison) {
                if let original = viewModel.selectedImage,
                   let processed = viewModel.processedImage {
                    ImageComparisonView(original: original, processed: processed)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var imageSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Select a recipe image to extract")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button {
                    showCamera = true
                } label: {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                        Text("Camera")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button {
                    showImagePicker = true
                } label: {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 40))
                        Text("Library")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var preprocessingToggle: some View {
        VStack(spacing: 8) {
            Toggle("Enhance Image for OCR", isOn: $viewModel.usePreprocessing)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            Text("Applies contrast enhancement and sharpening for better text recognition")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if viewModel.processedImage != nil {
                Button("Compare Original vs Processed") {
                    showImageComparison = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
        .onChange(of: viewModel.usePreprocessing) { _, _ in
            Task {
                await viewModel.togglePreprocessing()
            }
        }
    }
    
    private func imagePreviewSection(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Image")
                .font(.headline)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 400)
                .cornerRadius(12)
                .shadow(radius: 3)
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Claude is analyzing your recipe...")
                .font(.headline)
            Text("This may take a few moments")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func errorSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Error")
                    .font(.headline)
            }
            
            Text(message)
                .font(.body)
            
            Button("Try Again") {
                if let image = viewModel.selectedImage {
                    Task {
                        await viewModel.extractRecipe(from: image)
                    }
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func extractedRecipeSection(recipe: RecipeModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Recipe Extracted Successfully!")
                    .font(.headline)
            }
            
            // Save Button - Prominent and visible
            Button {
                print("🔘 INLINE Save button tapped!")
                saveRecipe()
            } label: {
                Label("Save to Collection", systemImage: "square.and.arrow.down.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Preview Navigation Link
            NavigationLink {
                RecipeDetailView(recipe: recipe, isSaved: false, onSave: {})
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(recipe.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if let yield = recipe.yield {
                            Text(yield)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Save Recipe
    
    private func saveRecipe() {
        print("🔘 Save button tapped!")
        
        guard let recipeModel = viewModel.extractedRecipe else {
            print("❌ No recipe to save!")
            return
        }
        
        print("💾 Saving recipe: \(recipeModel.title)")
        
        // Convert RecipeModel to SwiftData Recipe
        let recipe = Recipe(from: recipeModel)
        
        // Insert into SwiftData context
        modelContext.insert(recipe)
        print("📝 Recipe inserted into context")
        
        // Automatically save the extracted image and create assignment
        if let sourceImage = viewModel.selectedImage {
            saveRecipeImage(sourceImage, for: recipe.id)
        }
        
        // Save the context
        do {
            try modelContext.save()
            print("✅ Recipe saved successfully to SwiftData")
            print("📊 Recipe ID: \(recipe.id)")
            print("📊 Recipe Title: \(recipe.title)")
            
            // Small delay to ensure SwiftData propagates the change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingSaveConfirmation = true
            }
        } catch {
            print("❌ Failed to save recipe: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            // Optionally show an error alert here
        }
    }
    
    // MARK: - Image Management
    
    private func saveRecipeImage(_ image: UIImage, for recipeID: UUID) {
        // Generate a unique filename
        let filename = "recipe_\(recipeID.uuidString).jpg"
        
        // Save to documents directory
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to JPEG data")
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            print("✅ Saved recipe image to: \(fileURL.path)")
            
            // Create image assignment
            let assignment = RecipeImageAssignment(recipeID: recipeID, imageName: filename)
            modelContext.insert(assignment)
            print("✅ Created image assignment for recipe: \(recipeID)")
            
        } catch {
            print("❌ Error saving recipe image: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct ImageComparisonView: View {
    let original: UIImage
    let processed: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Original")
                            .font(.headline)
                        Image(uiImage: original)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Processed (Enhanced)")
                            .font(.headline)
                        Image(uiImage: processed)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Image Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RecipeExtractorView(apiKey: "test-api-key")
}
