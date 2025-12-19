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
    @State private var showURLInput = false
    @State private var showWebImagePicker = false
    @State private var selectedWebImageURLs: [String] = []
    @State private var downloadedWebImages: [UIImage] = []
    @State private var isDownloadingImage = false
    @State private var extractionSource: ExtractionSource = .none
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    private let imageDownloader = WebImageDownloader()
    
    enum ExtractionSource {
        case none
        case camera
        case library
        case url
    }
    
    init(apiKey: String) {
        _viewModel = StateObject(wrappedValue: RecipeExtractorViewModel(apiKey: apiKey))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Source Selection Section
                    sourceSelectionSection
                    
                    // URL Input (if URL source selected)
                    if extractionSource == .url {
                        urlInputSection
                    }
                    
                    // Preprocessing Toggle (only for images)
                    if viewModel.selectedImage != nil && extractionSource != .url {
                        preprocessingToggle
                    }
                    
                    // Image Preview
                    if let image = viewModel.selectedImage, extractionSource != .url {
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
                    // Verify the recipe was saved with image before dismissing
                    if let recipe = viewModel.extractedRecipe {
                        // Query to check if recipe exists in context
                        let descriptor = FetchDescriptor<Recipe>(
                            predicate: #Predicate { $0.id == recipe.id }
                        )
                        if let savedRecipe = try? modelContext.fetch(descriptor).first {
                            print("✅ Verified recipe in DB: '\(savedRecipe.title)'")
                            print("✅ Recipe imageName in DB: '\(savedRecipe.imageName ?? "nil")'")
                        } else {
                            print("⚠️ Could not find recipe in DB after save!")
                        }
                    }
                    // Dismiss and let the ContentView refresh
                    dismiss()
                }
                Button("Extract Another") {
                    viewModel.reset()
                    extractionSource = .none
                    selectedWebImageURLs = []
                    downloadedWebImages = []
                }
            } message: {
                if let recipe = viewModel.extractedRecipe {
                    let imageCount = downloadedWebImages.count + (viewModel.selectedImage != nil ? 1 : 0)
                    if imageCount > 0 {
                        Text("\"\(recipe.title)\" and \(imageCount) image\(imageCount == 1 ? "" : "s") have been added to your recipe collection.")
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
    
    private var sourceSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Choose how to extract your recipe")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                // Row 1: Camera and Library
                HStack(spacing: 20) {
                    Button {
                        extractionSource = .camera
                        showCamera = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                            Text("Camera")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(extractionSource == .camera ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(extractionSource == .camera ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        extractionSource = .library
                        showImagePicker = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 40))
                            Text("Library")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(extractionSource == .library ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(extractionSource == .library ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Row 2: Web URL (full width)
                Button {
                    extractionSource = .url
                    showURLInput = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 40))
                        Text("Web URL")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("Extract from a recipe website")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(extractionSource == .url ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(extractionSource == .url ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter Recipe URL")
                .font(.headline)
            
            TextField("https://example.com/recipe", text: $viewModel.recipeURL)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.URL)
                .textContentType(.URL)
            
            Button {
                Task {
                    await viewModel.extractRecipe(from: viewModel.recipeURL)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Extract Recipe from URL")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.recipeURL.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.recipeURL.isEmpty || viewModel.isLoading)
            .buttonStyle(.plain)
            
            Text("Enter the full URL of a recipe webpage. The app will fetch and analyze the page to extract the recipe.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
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
            if extractionSource == .url {
                Text("Claude is analyzing the webpage...")
                    .font(.headline)
                Text("This may take a few moments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Claude is analyzing your recipe...")
                    .font(.headline)
                Text("This may take a few moments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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
                if extractionSource == .url, !viewModel.recipeURL.isEmpty {
                    Task {
                        await viewModel.extractRecipe(from: viewModel.recipeURL)
                    }
                } else if let image = viewModel.selectedImage {
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
            recipeSuccessHeader
            
            recipeDebugInfo(recipe: recipe)
            
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
        .sheet(isPresented: $showWebImagePicker) {
            if let imageURLs = recipe.imageURLs {
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
    
    private func recipeDebugInfo(recipe: RecipeModel) -> some View {
        Group {
            if recipe.ingredientSections.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("No ingredients found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if recipe.instructionSections.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("No instructions found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
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
            print("🔘 INLINE Save button tapped!")
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
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Downloading Images...")
                }
                .font(.headline)
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
                previewImage: downloadedWebImages.first ?? viewModel.selectedImage
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
                print("🖼️ Downloading image \(index + 1)/\(imageURLs.count) from: \(imageURL)")
                let image = try await imageDownloader.downloadImage(from: imageURL)
                downloadedImages.append(image)
            } catch {
                print("❌ Failed to download image \(index + 1): \(error)")
                // Continue with other images
            }
        }
        
        await MainActor.run {
            self.downloadedWebImages = downloadedImages
            print("✅ Downloaded \(downloadedImages.count) images successfully")
            self.saveRecipe()
            self.isDownloadingImage = false
        }
    }
    
    private func saveRecipe() {
        print("🔘 Save button tapped!")
        
        guard let recipeModel = viewModel.extractedRecipe else {
            print("❌ No recipe to save!")
            return
        }
        
        print("💾 Saving recipe: \(recipeModel.title)")
        
        // Determine which images we'll save
        let imagesToSave: [UIImage]
        if !downloadedWebImages.isEmpty {
            imagesToSave = downloadedWebImages
        } else if let selectedImage = viewModel.selectedImage {
            imagesToSave = [selectedImage]
        } else {
            imagesToSave = []
        }
        
        // Convert RecipeModel to SwiftData Recipe first
        let recipe = Recipe(from: recipeModel)
        
        // Generate image filename for the first image (main thumbnail) and set it directly
        if let firstImage = imagesToSave.first {
            let imageName = "recipe_\(recipeModel.id.uuidString).jpg"
            recipe.imageName = imageName  // ✅ Set the image name directly on the Recipe object
            print("📸 Will save \(imagesToSave.count) image(s), main image: \(imageName)")
            print("📸 Recipe.imageName is now: \(recipe.imageName ?? "nil")")
        }
        
        // Insert into SwiftData context
        modelContext.insert(recipe)
        print("📝 Recipe inserted into context")
        print("📝 Recipe ID: \(recipe.id)")
        print("📝 Recipe imageName before save: \(recipe.imageName ?? "nil")")
        
        // Save all images
        for (index, image) in imagesToSave.enumerated() {
            if index == 0 {
                // First image is the main thumbnail
                saveRecipeImage(image, for: recipe.id, isMainImage: true)
            } else {
                // Additional images
                saveRecipeImage(image, for: recipe.id, imageIndex: index)
            }
        }
        
        // Save the context
        do {
            try modelContext.save()
            print("✅ Recipe saved successfully to SwiftData")
            print("📊 Recipe ID: \(recipe.id)")
            print("📊 Recipe Title: \(recipe.title)")
            print("📊 Recipe imageName (after context save): \(recipe.imageName ?? "nil")")
            
            // Verify the image file exists
            if let imageName = recipe.imageName {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsPath.appendingPathComponent(imageName)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    print("✅ Image file verified to exist at: \(fileURL.path)")
                } else {
                    print("❌ WARNING: Image file NOT found at: \(fileURL.path)")
                }
            } else {
                print("⚠️ WARNING: Recipe has no imageName after save!")
            }
            
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
    
    private func saveRecipeImage(_ image: UIImage, for recipeID: UUID, isMainImage: Bool = false, imageIndex: Int = 0) {
        // Generate a unique filename
        let filename: String
        if isMainImage {
            filename = "recipe_\(recipeID.uuidString).jpg"
        } else {
            filename = "recipe_\(recipeID.uuidString)_\(imageIndex).jpg"
        }
        
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
            
            // Create image assignment (only for main image to maintain compatibility)
            if isMainImage {
                let assignment = RecipeImageAssignment(recipeID: recipeID, imageName: filename)
                modelContext.insert(assignment)
                print("✅ Created image assignment for recipe: \(recipeID)")
            } else {
                print("✅ Saved additional image \(imageIndex) for recipe: \(recipeID)")
            }
            
        } catch {
            print("❌ Error saving recipe image: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct MultiWebImagePickerView: View {
    let imageURLs: [String]
    @Binding var selectedURLs: [String]
    let onSelectionChange: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempSelectedURLs: [String]
    
    init(imageURLs: [String], selectedURLs: Binding<[String]>, onSelectionChange: @escaping () -> Void) {
        self.imageURLs = imageURLs
        self._selectedURLs = selectedURLs
        self.onSelectionChange = onSelectionChange
        self._tempSelectedURLs = State(initialValue: selectedURLs.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !tempSelectedURLs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(tempSelectedURLs.count) image\(tempSelectedURLs.count == 1 ? "" : "s") selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("The first image will be used as the main thumbnail")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                            ImageSelectionCard(
                                url: url,
                                isSelected: tempSelectedURLs.contains(url),
                                selectionIndex: tempSelectedURLs.firstIndex(of: url),
                                onTap: {
                                    toggleSelection(url)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedURLs = tempSelectedURLs
                        onSelectionChange()
                        dismiss()
                    }
                    .disabled(tempSelectedURLs.isEmpty)
                }
            }
        }
    }
    
    private func toggleSelection(_ url: String) {
        if let index = tempSelectedURLs.firstIndex(of: url) {
            tempSelectedURLs.remove(at: index)
        } else {
            tempSelectedURLs.append(url)
        }
    }
}

struct ImageSelectionCard: View {
    let url: String
    let isSelected: Bool
    let selectionIndex: Int?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.red.opacity(0.2))
                            .frame(height: 150)
                            .overlay(
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.red)
                                    Text("Failed to load")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            )
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .overlay(ProgressView())
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 32, height: 32)
                        
                        if let index = selectionIndex, index == 0 {
                            Image(systemName: "star.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        } else if let index = selectionIndex {
                            Text("\(index + 1)")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        } else {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

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

#Preview("Multi Image Picker") {
    MultiWebImagePickerView(
        imageURLs: [
            "https://example.com/image1.jpg",
            "https://example.com/image2.jpg",
            "https://example.com/image3.jpg"
        ],
        selectedURLs: .constant([]),
        onSelectionChange: {}
    )
}

#Preview {
    RecipeExtractorView(apiKey: "test-api-key")
}
