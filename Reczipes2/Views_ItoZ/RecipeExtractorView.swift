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
    @EnvironmentObject private var appState: AppStateManager
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showImageCrop = false
    @State private var imageToCrop: UIImage?
    @State private var showImageComparison = false
    @State private var showingSaveConfirmation = false
    @State private var showURLInput = false
    @State private var showWebImagePicker = false
    @State private var selectedWebImageURLs: [String] = []
    @State private var downloadedWebImages: [UIImage] = []
    @State private var isDownloadingImage = false
    @State private var extractionSource: ExtractionSource = .none
    @State private var extractionProgress: Double = 0.0
    @State private var showPendingExtractionAlert = false
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
                    // Source Selection Section (hide when loading)
                    if !viewModel.isLoading && imageToCrop == nil {
                        sourceSelectionSection
                    }
                    
                    // Preparing image indicator (between picker and crop)
                    if imageToCrop != nil && !showImageCrop {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Preparing image...")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    }
                    
                    // URL Input (if URL source selected and not loading)
                    if extractionSource == .url && !viewModel.isLoading {
                        urlInputSection
                    }
                    
                    // Preprocessing Toggle (only for images and not loading)
                    if viewModel.selectedImage != nil && extractionSource != .url && !viewModel.isLoading {
                        preprocessingToggle
                    }
                    
                    // Image Preview (hide during loading to keep focus on spinner)
                    if let image = viewModel.selectedImage, extractionSource != .url && !viewModel.isLoading {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloudKitSyncBadge()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.extractedRecipe != nil {
                        // nothing for now

                    } else {
                        Text("No recipe")
                            .onAppear {
                                logWarning("No recipe available to save", category: "ui")
                            }
                    }
                }
            }
            .alert("Recipe Saved!", isPresented: $showingSaveConfirmation) {
                Button("View in Collection") {
                    // Verify the recipe was saved with image before dismissing
                    if let recipe = viewModel.extractedRecipe {
                        // Capture the UUID value to avoid Sendable issues
                        let recipeID = recipe.id
                        
                        // Query to check if recipe exists in context
                        let descriptor = FetchDescriptor<Recipe>(
                            predicate: #Predicate { $0.id == recipeID }
                        )
                        if let savedRecipe = try? modelContext.fetch(descriptor).first {
                            logInfo("Verified recipe in DB: '\(savedRecipe.title)'", category: "storage")
                            logInfo("Recipe imageName in DB: '\(savedRecipe.imageName ?? "nil")'", category: "storage")
                        } else {
                            logWarning("Could not find recipe in DB after save", category: "storage")
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
                ImagePicker(
                    sourceType: .photoLibrary,
                    onImageSelected: { image in
                        logInfo("Image selected from library, size: \(image.size)", category: "ui")
                        // Store the image and wait for sheet to dismiss before showing crop
                        imageToCrop = image
                        // Delay to ensure sheet dismisses before fullScreenCover presents
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            logInfo("Presenting crop view", category: "ui")
                            showImageCrop = true
                        }
                    },
                    onCancel: {
                        logInfo("Image picker cancelled", category: "ui")
                        // User cancelled, do nothing
                    }
                )
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(
                    sourceType: .camera,
                    onImageSelected: { image in
                        // Store the image and wait for sheet to dismiss before showing crop
                        imageToCrop = image
                        // Delay to ensure sheet dismisses before fullScreenCover presents
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            showImageCrop = true
                        }
                    },
                    onCancel: {
                        // User cancelled, do nothing
                    }
                )
            }
            .fullScreenCover(isPresented: $showImageCrop) {
                if let image = imageToCrop {
                    ImageCropView(
                        image: image,
                        onCrop: { croppedImage in
                            // After cropping, proceed with extraction
                            viewModel.selectedImage = croppedImage
                            
                            // Save input data for task restoration
                            if let imageData = croppedImage.jpegData(compressionQuality: 0.8) {
                                let inputData = ExtractionInputData(
                                    imageData: imageData,
                                    textInput: nil,
                                    timestamp: Date()
                                )
                                if let encoded = try? JSONEncoder().encode(inputData) {
                                    appState.startTask(type: .extraction, inputData: encoded)
                                }
                            }
                            
                            showImageCrop = false
                            imageToCrop = nil
                            
                            Task {
                                await viewModel.extractRecipe(from: croppedImage)
                            }
                        },
                        onCancel: {
                            // User cancelled cropping
                            showImageCrop = false
                            imageToCrop = nil
                        }
                    )
                }
            }
            .sheet(isPresented: $showImageComparison) {
                if let original = viewModel.selectedImage,
                   let processed = viewModel.processedImage {
                    ImageComparisonView(original: original, processed: processed)
                }
            }
            .onAppear {
                checkForPendingExtraction()
            }
            .trackTask(
                type: .extraction,
                progress: extractionProgress,
                isActive: viewModel.isLoading
            )
            .alert("Resume Extraction?", isPresented: $showPendingExtractionAlert) {
                Button("Resume") {
                    resumeExtraction()
                }
                Button("Cancel", role: .cancel) {
                    appState.completeTask()
                }
            } message: {
                Text("You have an extraction in progress. Would you like to resume where you left off?")
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
                // Save input data for task restoration
                let inputData = ExtractionInputData(
                    imageData: nil,
                    textInput: viewModel.recipeURL,
                    timestamp: Date()
                )
                if let encoded = try? JSONEncoder().encode(inputData) {
                    appState.startTask(type: .extraction, inputData: encoded)
                }
                
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
        ExtractionLoadingView(
            extractionType: extractionSource == .url ? .url : .image
        )
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
                    // Save input data for task restoration
                    let inputData = ExtractionInputData(
                        imageData: nil,
                        textInput: viewModel.recipeURL,
                        timestamp: Date()
                    )
                    if let encoded = try? JSONEncoder().encode(inputData) {
                        appState.startTask(type: .extraction, inputData: encoded)
                    }
                    
                    Task {
                        await viewModel.extractRecipe(from: viewModel.recipeURL)
                    }
                } else if let image = viewModel.selectedImage {
                    // Save input data for task restoration
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        let inputData = ExtractionInputData(
                            imageData: imageData,
                            textInput: nil,
                            timestamp: Date()
                        )
                        if let encoded = try? JSONEncoder().encode(inputData) {
                            appState.startTask(type: .extraction, inputData: encoded)
                        }
                    }
                    
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
            logInfo("INLINE Save button tapped", category: "ui")
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
        logInfo("Save button tapped", category: "recipe")
        
        guard let recipeModel = viewModel.extractedRecipe else {
            logError("No recipe to save", category: "recipe")
            return
        }
        
        logInfo("Saving recipe: \(recipeModel.title)", category: "recipe")
        
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
        if !imagesToSave.isEmpty {
            let imageName = "recipe_\(recipeModel.id.uuidString).jpg"
            recipe.imageName = imageName  // ✅ Set the image name directly on the Recipe object
            logInfo("Will save \(imagesToSave.count) image(s), main image: \(imageName)", category: "recipe")
            logInfo("Recipe.imageName is now: \(recipe.imageName ?? "nil")", category: "recipe")
        }
        
        // Insert into SwiftData context
        modelContext.insert(recipe)
        logDebug("Recipe inserted into context", category: "storage")
        logDebug("Recipe ID: \(recipe.id)", category: "storage")
        logDebug("Recipe imageName before save: \(recipe.imageName ?? "nil")", category: "storage")
        
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
            logInfo("Set recipe.additionalImageNames to \(additionalImageFilenames.count) images: \(additionalImageFilenames)", category: "storage")
        }
        
        // Save the context
        do {
            try modelContext.save()
            logInfo("Recipe saved successfully to SwiftData", category: "storage")
            logDebug("Recipe ID: \(recipe.id)", category: "storage")
            logDebug("Recipe Title: \(recipe.title)", category: "storage")
            logDebug("Recipe imageName (after context save): \(recipe.imageName ?? "nil")", category: "storage")
            
            // Verify the image file exists
            if let imageName = recipe.imageName {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsPath.appendingPathComponent(imageName)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    logInfo("Image file verified to exist at: \(fileURL.path)", category: "storage")
                } else {
                    logWarning("Image file NOT found at: \(fileURL.path)", category: "storage")
                }
            } else {
                logWarning("Recipe has no imageName after save", category: "storage")
            }
            
            // Small delay to ensure SwiftData propagates the change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingSaveConfirmation = true
            }
        } catch {
            logError("Failed to save recipe: \(error)", category: "storage")
            logError("Error details: \(error.localizedDescription)", category: "storage")
            // Optionally show an error alert here
        }
    }
    
    // MARK: - Image Management
    
    private func saveImageToDisk(_ image: UIImage, filename: String) {
        // Reduce image size to 500KB max before saving
        let preprocessor = ImagePreprocessor()
        guard let imageData = preprocessor.reduceImageSize(image, maxSizeBytes: 500_000) else {
            logError("Failed to reduce image size", category: "storage")
            return
        }
        
        logInfo("Saving image with size: \(imageData.count) bytes", category: "storage")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            logInfo("Saved recipe image to: \(fileURL.path)", category: "storage")
        } catch {
            logError("Error saving recipe image: \(error)", category: "storage")
        }
    }
    
    private func saveRecipeImage(_ image: UIImage, for recipeID: UUID, isMainImage: Bool = false, imageIndex: Int = 0) {
        // Generate a unique filename
        let filename: String
        if isMainImage {
            filename = "recipe_\(recipeID.uuidString).jpg"
        } else {
            filename = "recipe_\(recipeID.uuidString)_\(imageIndex).jpg"
        }
        
        // Reduce image size to 500KB max before saving
        let preprocessor = ImagePreprocessor()
        guard let imageData = preprocessor.reduceImageSize(image, maxSizeBytes: 500_000) else {
            logError("Failed to reduce image size", category: "storage")
            return
        }
        
        logInfo("Saving image with size: \(imageData.count) bytes", category: "storage")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            logInfo("Saved recipe image to: \(fileURL.path)", category: "storage")
            
            // Create image assignment (only for main image to maintain compatibility)
            if isMainImage {
                let assignment = RecipeImageAssignment(recipeID: recipeID, imageName: filename)
                modelContext.insert(assignment)
                logDebug("Created image assignment for recipe: \(recipeID)", category: "storage")
            } else {
                logDebug("Saved additional image \(imageIndex) for recipe: \(recipeID)", category: "storage")
                
                // ✅ FIX: Add the filename to the recipe's additionalImageNames array
                // Find the recipe we just inserted
                let descriptor = FetchDescriptor<Recipe>(
                    predicate: #Predicate { $0.id == recipeID }
                )
                if let recipe = try? modelContext.fetch(descriptor).first {
                    var additionalImages = recipe.additionalImageNames ?? []
                    additionalImages.append(filename)
                    recipe.additionalImageNames = additionalImages
                    logInfo("Added '\(filename)' to recipe.additionalImageNames (now \(additionalImages.count) additional images)", category: "storage")
                } else {
                    logError("Could not find recipe \(recipeID) to update additionalImageNames", category: "storage")
                }
            }
            
        } catch {
            logError("Error saving recipe image: \(error)", category: "storage")
        }
    }
    
    // MARK: - Task Restoration
    
    private func checkForPendingExtraction() {
        // Check if there's a pending extraction task
        if let task = appState.activeTask,
           task.taskType == .extraction {
            logInfo("Found pending extraction task with progress: \(task.progress)", category: "state")
            showPendingExtractionAlert = true
        }
    }
    
    private func resumeExtraction() {
        // Resume from saved progress
        guard let task = appState.activeTask else { return }
        
        logInfo("Resuming extraction from progress: \(task.progress)", category: "state")
        extractionProgress = task.progress
        
        // If we have saved input data, try to restore it
        if let inputData = task.inputData,
           let extractionInput = try? JSONDecoder().decode(ExtractionInputData.self, from: inputData) {
            
            // Restore image if available
            if let imageData = extractionInput.imageData,
               let image = UIImage(data: imageData) {
                viewModel.selectedImage = image
                extractionSource = .library
                
                // Resume extraction
                Task {
                    await viewModel.extractRecipe(from: image)
                }
            }
            
            // Restore URL if available
            if let textInput = extractionInput.textInput, !textInput.isEmpty {
                viewModel.recipeURL = textInput
                extractionSource = .url
                
                // Resume extraction
                Task {
                    await viewModel.extractRecipe(from: textInput)
                }
            }
        } else {
            // No input data saved - just show the UI state
            logWarning("No input data available to resume extraction", category: "state")
            appState.completeTask()
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
