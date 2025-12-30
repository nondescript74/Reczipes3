//
//  LinkExtractionView.swift
//  Reczipes2
//
//  Created for extracting recipes from saved links
//

import SwiftUI
import SwiftData

struct LinkExtractionView: View {
    let link: SavedLink
    let apiKey: String
    let onExtractionComplete: (Bool, String?) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: RecipeExtractorViewModel
    @State private var showingSaveConfirmation = false
    @State private var selectedWebImageURLs: [String] = []
    @State private var downloadedWebImages: [UIImage] = []
    @State private var isDownloadingImage = false
    @State private var showWebImagePicker = false
    
    private let imageDownloader = WebImageDownloader()
    
    init(link: SavedLink, apiKey: String, onExtractionComplete: @escaping (Bool, String?) -> Void) {
        self.link = link
        self.apiKey = apiKey
        self.onExtractionComplete = onExtractionComplete
        _viewModel = StateObject(wrappedValue: RecipeExtractorViewModel(apiKey: apiKey))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Link info
                    linkInfoSection
                    
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
            .navigationTitle("Extract Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear {
                // Automatically start extraction when view appears
                Task {
                    await viewModel.extractRecipe(from: link.url)
                }
            }
            .alert("Recipe Saved!", isPresented: $showingSaveConfirmation) {
                Button("Done") {
                    onExtractionComplete(true, nil)
                    dismiss()
                }
            } message: {
                if let recipe = viewModel.extractedRecipe {
                    let imageCount = downloadedWebImages.count
                    if imageCount > 0 {
                        Text("\"\(recipe.title)\" and \(imageCount) image\(imageCount == 1 ? "" : "s") have been added to your recipe collection.")
                    } else {
                        Text("\"\(recipe.title)\" has been added to your recipe collection.")
                    }
                }
            }
            .sheet(isPresented: $showWebImagePicker) {
                if let recipe = viewModel.extractedRecipe,
                   let imageURLs = recipe.imageURLs {
                    MultiWebImagePickerView(
                        imageURLs: imageURLs,
                        selectedURLs: $selectedWebImageURLs
                    ) {
                        // Reset downloaded images when selection changes
                        self.downloadedWebImages = []
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var linkInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Extracting From:", systemImage: "link")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(link.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(link.url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var loadingSection: some View {
        ExtractionLoadingView(extractionType: .link)
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
                Task {
                    await viewModel.extractRecipe(from: link.url)
                }
            }
            .buttonStyle(.bordered)
            
            Button("Cancel") {
                onExtractionComplete(false, message)
                dismiss()
            }
            .buttonStyle(.borderless)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            // Report error but don't dismiss automatically
            logError("Extraction failed: \(message)", category: "extraction")
        }
    }
    
    private func extractedRecipeSection(recipe: RecipeModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            recipeSuccessHeader
            
            extractionSummary(recipe: recipe)
            
            if let imageURLs = recipe.imageURLs, !imageURLs.isEmpty {
                imageSelectionSection(imageURLs: imageURLs)
            }
            
            saveButton
            
            Divider()
            
            if !recipe.ingredientSections.isEmpty || !recipe.instructionSections.isEmpty {
                recipeQuickPreview(recipe: recipe)
            }
            
            Divider()
            
            recipeNavigationLink(recipe: recipe)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Recipe Section Sub-Views
    
    private var recipeSuccessHeader: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            Text("Recipe Extracted Successfully!")
                .font(.headline)
        }
    }
    
    private func extractionSummary(recipe: RecipeModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extracted:")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("• \(recipe.ingredientSections.count) ingredient section(s)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("• \(recipe.instructionSections.count) instruction section(s)")
                .font(.caption)
                .foregroundColor(.secondary)
            if let imageURLs = recipe.imageURLs {
                Text("• \(imageURLs.count) image(s) found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func imageSelectionSection(imageURLs: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            imageSelectionHeader(imageCount: imageURLs.count)
            
            if !selectedWebImageURLs.isEmpty {
                selectedImagesScrollView
            } else {
                selectImagesButton(imageCount: imageURLs.count)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func imageSelectionHeader(imageCount: Int) -> some View {
        HStack {
            Text("Recipe Images")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if !selectedWebImageURLs.isEmpty {
                Text("(\(selectedWebImageURLs.count) selected)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(selectedWebImageURLs.isEmpty ? "Select Images" : "Change Selection") {
                showWebImagePicker = true
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
    }
    
    private var selectedImagesScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(selectedWebImageURLs.enumerated()), id: \.offset) { index, url in
                    selectedImageThumbnail(url: url, index: index)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func selectedImageThumbnail(url: String, index: Int) -> some View {
        VStack(spacing: 4) {
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipped()
                        .cornerRadius(8)
                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                        )
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(ProgressView())
                @unknown default:
                    EmptyView()
                }
            }
            
            if index == 0 {
                Text("Main Image")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            } else {
                Text("Image \(index + 1)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func selectImagesButton(imageCount: Int) -> some View {
        Button {
            showWebImagePicker = true
        } label: {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                Text("Select Recipe Images (\(imageCount) available)")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var saveButton: some View {
        Button {
            logInfo("Save button tapped", category: "ui")
            // If there are selected web image URLs and we haven't downloaded them yet
            if !selectedWebImageURLs.isEmpty && downloadedWebImages.isEmpty {
                Task {
                    await downloadAndSaveRecipe(imageURLs: selectedWebImageURLs)
                }
            } else {
                saveRecipe()
            }
        } label: {
            if isDownloadingImage {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Downloading Images...")
                            .font(.headline)
                        Text("Please wait")
                            .font(.caption)
                            .opacity(0.9)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(12)
            } else {
                Label("Save to Collection", systemImage: "square.and.arrow.down.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .disabled(isDownloadingImage)
        .buttonStyle(.plain)
    }
    
    private func recipeQuickPreview(recipe: RecipeModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Preview")
                .font(.headline)
            
            if !recipe.ingredientSections.isEmpty {
                ingredientsPreview(recipe: recipe)
            }
            
            if !recipe.instructionSections.isEmpty {
                instructionsPreview(recipe: recipe)
            }
            
            Text("Tap recipe title below to view full details →")
                .font(.caption)
                .foregroundColor(.blue)
                .italic()
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func ingredientsPreview(recipe: RecipeModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(recipe.ingredientSections.prefix(1)) { section in
                ForEach(section.ingredients.prefix(3)) { ingredient in
                    HStack {
                        Text("•")
                        if let quantity = ingredient.quantity {
                            Text(quantity)
                        }
                        if let unit = ingredient.unit {
                            Text(unit)
                        }
                        Text(ingredient.name)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                if section.ingredients.count > 3 {
                    Text("... and \(section.ingredients.count - 3) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func instructionsPreview(recipe: RecipeModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(recipe.instructionSections.prefix(1)) { section in
                ForEach(section.steps.prefix(2)) { step in
                    HStack(alignment: .top) {
                        if let stepNumber = step.stepNumber {
                            Text("\(stepNumber).")
                                .fontWeight(.semibold)
                        } else {
                            Text("•")
                        }
                        Text(step.text)
                            .lineLimit(2)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                if section.steps.count > 2 {
                    Text("... and \(section.steps.count - 2) more steps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func recipeNavigationLink(recipe: RecipeModel) -> some View {
        NavigationLink {
            RecipeDetailView(
                recipe: recipe,
                isSaved: false,
                onSave: {},
                previewImage: downloadedWebImages.first
            )
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
    
    // MARK: - Save Recipe
    
    private func downloadAndSaveRecipe(imageURLs: [String]) async {
        isDownloadingImage = true
        var downloadedImages: [UIImage] = []
        
        for (index, imageURL) in imageURLs.enumerated() {
            do {
                logInfo("Downloading image \(index + 1)/\(imageURLs.count) from: \(imageURL)", category: "network")
                let image = try await imageDownloader.downloadImage(from: imageURL)
                downloadedImages.append(image)
            } catch {
                logError("Failed to download image \(index + 1): \(error)", category: "network")
                // Continue with other images
            }
        }
        
        await MainActor.run {
            self.downloadedWebImages = downloadedImages
            logInfo("Downloaded \(downloadedImages.count) images successfully", category: "network")
            self.saveRecipe()
            self.isDownloadingImage = false
        }
    }
    
    private func saveRecipe() {
        logInfo("Saving recipe from link", category: "recipe")
        
        guard var recipeModel = viewModel.extractedRecipe else {
            logError("No recipe to save", category: "recipe")
            return
        }
        
        logInfo("Saving recipe: \(recipeModel.title)", category: "recipe")
        
        // Add tips from the SavedLink as recipe notes (type: .tip)
        if let tips = link.tips, !tips.isEmpty {
            logInfo("Adding \(tips.count) tip(s) from saved link to recipe notes", category: "recipe")
            
            // Convert tips to RecipeNote objects
            let tipNotes = tips.map { tipText in
                RecipeNote(type: .tip, text: tipText)
            }
            
            // Append tips to existing notes
            recipeModel = RecipeModel(
                id: recipeModel.id,
                title: recipeModel.title,
                headerNotes: recipeModel.headerNotes,
                yield: recipeModel.yield,
                ingredientSections: recipeModel.ingredientSections,
                instructionSections: recipeModel.instructionSections,
                notes: recipeModel.notes + tipNotes,  // Append tips to existing notes
                reference: recipeModel.reference,
                imageName: recipeModel.imageName,
                additionalImageNames: recipeModel.additionalImageNames
            )
            
            logInfo("Total notes including tips: \(recipeModel.notes.count)", category: "recipe")
        }
        
        // Determine which images we'll save
        let imagesToSave = downloadedWebImages.isEmpty ? [] : downloadedWebImages
        
        // Convert RecipeModel to SwiftData Recipe first
        let recipe = Recipe(from: recipeModel)
        
        // Generate image filename for the first image (main thumbnail) and set it directly
        if !imagesToSave.isEmpty {
            let imageName = "recipe_\(recipeModel.id.uuidString).jpg"
            recipe.imageName = imageName
            logInfo("Will save \(imagesToSave.count) image(s), main image: \(imageName)", category: "recipe")
        }
        
        // Set reference to the original link URL
        recipe.reference = link.url
        
        // Insert into SwiftData context
        modelContext.insert(recipe)
        
        // Save all images and build additionalImageNames array
        var additionalImageFilenames: [String] = []
        for (index, image) in imagesToSave.enumerated() {
            let filename: String
            if index == 0 {
                // First image is the main thumbnail
                filename = "recipe_\(recipe.id.uuidString).jpg"
                saveImageToDisk(image, filename: filename)
                
                // Create image assignment for compatibility
                let assignment = RecipeImageAssignment(recipeID: recipe.id, imageName: filename)
                modelContext.insert(assignment)
            } else {
                // Additional images
                filename = "recipe_\(recipe.id.uuidString)_\(index).jpg"
                saveImageToDisk(image, filename: filename)
                additionalImageFilenames.append(filename)
            }
        }
        
        // Set additionalImageNames on the recipe BEFORE saving context
        if !additionalImageFilenames.isEmpty {
            recipe.additionalImageNames = additionalImageFilenames
            logInfo("Set recipe.additionalImageNames to \(additionalImageFilenames.count) images", category: "storage")
        }
        
        // Update the link to mark it as processed
        link.isProcessed = true
        link.extractedRecipeID = recipe.id
        link.processingError = nil
        
        // Save the context
        do {
            try modelContext.save()
            logInfo("Recipe saved successfully to SwiftData", category: "storage")
            
            // Small delay to ensure SwiftData propagates the change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingSaveConfirmation = true
            }
        } catch {
            logError("Failed to save recipe: \(error)", category: "storage")
            onExtractionComplete(false, error.localizedDescription)
        }
    }
    
    // MARK: - Image Management
    
    private func saveImageToDisk(_ image: UIImage, filename: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            logError("Failed to convert image to JPEG data", category: "storage")
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            logInfo("Saved recipe image to: \(fileURL.path)", category: "storage")
        } catch {
            logError("Error saving recipe image: \(error)", category: "storage")
        }
    }
}

// MARK: - Preview

#Preview {
    let link = SavedLink(
        title: "Chocolate Chip Cookies",
        url: "https://www.example.com/recipe/chocolate-chip-cookies"
    )
    
    return LinkExtractionView(
        link: link,
        apiKey: "test-api-key",
        onExtractionComplete: { _, _ in }
    )
    .modelContainer(for: [SavedLink.self, Recipe.self], inMemory: true)
}
