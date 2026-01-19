//
//  BatchImageExtractorViewModel.swift
//  Reczipes2
//
//  Created for batch recipe extraction from Photos library
//

import SwiftUI
import SwiftData
import Photos
import Combine

/// ViewModel managing batch extraction workflow from Photos library images
@MainActor
class BatchImageExtractorViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isExtracting = false
    @Published var isPaused = false
    @Published var isWaitingForCrop = false
    
    @Published var currentProgress = 0
    @Published var totalToExtract = 0
    @Published var successCount = 0
    @Published var failureCount = 0
    
    @Published var currentImage: UIImage?
    @Published var currentRecipe: RecipeModel?
    @Published var currentStatus = "Ready"
    
    @Published var remainingAssets: [PHAsset] = []
    @Published var errorLog: [(imageIndex: Int, error: String)] = []
    
    // Crop integration properties
    @Published var showingCropForBatch = false
    @Published var imageToCropInBatch: UIImage?
    
    // MARK: - Private Properties
    
    private let apiKey: String
    private let modelContext: ModelContext
    private let apiClient: ClaudeAPIClient
    private let imagePreprocessor = ImagePreprocessor()
    
    private var allAssets: [PHAsset] = []
    private var processedAssets: Set<String> = []
    private var shouldCrop = false
    private var currentBatch: [UIImage] = []
    private var extractionTask: Task<Void, Never>?
    
    private var cropContinuation: CheckedContinuation<Bool, Never>?
    private var cropImageContinuation: CheckedContinuation<UIImage?, Never>?
    
    // MARK: - Computed Properties
    
    var remainingCount: Int {
        remainingAssets.count
    }
    
    // MARK: - Initialization
    
    init(apiKey: String, modelContext: ModelContext) {
        self.apiKey = apiKey
        self.modelContext = modelContext
        self.apiClient = ClaudeAPIClient(apiKey: apiKey)
    }
    
    // MARK: - Public Methods
    
    func startBatchExtraction(
        assets: [PHAsset],
        photoManager: PhotoLibraryManager,
        shouldCrop: Bool
    ) {
        guard !assets.isEmpty else { return }
        
        logInfo("Starting batch image extraction with \(assets.count) images, shouldCrop: \(shouldCrop)", category: "batch")
        
        self.allAssets = assets
        self.remainingAssets = assets
        self.shouldCrop = shouldCrop
        self.totalToExtract = assets.count
        self.currentProgress = 0
        self.successCount = 0
        self.failureCount = 0
        self.errorLog = []
        self.processedAssets = []
        self.isExtracting = true
        self.isPaused = false
        
        // Start extraction task
        extractionTask = Task {
            await processBatch(photoManager: photoManager)
        }
    }
    
    func startBatchExtractionFromImages(
        images: [UIImage],
        shouldCrop: Bool
    ) {
        guard !images.isEmpty else { return }
        
        logInfo("Starting batch image extraction from \(images.count) UIImages (Files/iCloud Drive), shouldCrop: \(shouldCrop)", category: "batch")
        
        self.currentBatch = images
        self.shouldCrop = shouldCrop
        self.totalToExtract = images.count
        self.currentProgress = 0
        self.successCount = 0
        self.failureCount = 0
        self.errorLog = []
        self.isExtracting = true
        self.isPaused = false
        
        // Clear asset-related state
        self.allAssets = []
        self.remainingAssets = []
        self.processedAssets = []
        
        // Start extraction task
        extractionTask = Task {
            await processImageBatch()
        }
    }
    
    func pause() {
        isPaused = true
        currentStatus = "Paused"
        logInfo("Batch extraction paused", category: "batch")
    }
    
    func resume() {
        isPaused = false
        currentStatus = "Resuming..."
        logInfo("Batch extraction resumed", category: "batch")
    }
    
    func stop() {
        extractionTask?.cancel()
        isExtracting = false
        isPaused = false
        isWaitingForCrop = false
        currentStatus = "Stopped"
        logInfo("Batch extraction stopped", category: "batch")
    }
    
    func skipCropping() {
        cropContinuation?.resume(returning: false)
        cropContinuation = nil
        isWaitingForCrop = false
    }
    
    func showCropping() {
        cropContinuation?.resume(returning: true)
        cropContinuation = nil
        isWaitingForCrop = false
    }
    
    func handleCroppedImage(_ image: UIImage?) {
        cropImageContinuation?.resume(returning: image)
        cropImageContinuation = nil
        imageToCropInBatch = nil
        showingCropForBatch = false
    }
    
    func reset() {
        currentImage = nil
        currentRecipe = nil
        currentProgress = 0
        totalToExtract = 0
        successCount = 0
        failureCount = 0
        remainingAssets = []
        allAssets = []
        processedAssets = []
        errorLog = []
        currentStatus = "Ready"
        isExtracting = false
        isPaused = false
        isWaitingForCrop = false
    }
    
    // MARK: - Private Methods
    
    private func requestCrop(for image: UIImage) async -> UIImage? {
        await withCheckedContinuation { continuation in
            self.cropImageContinuation = continuation
            self.imageToCropInBatch = image
            self.showingCropForBatch = true
        }
    }
    
    private func processBatch(photoManager: PhotoLibraryManager) async {
        logInfo("Processing batch of \(allAssets.count) images", category: "batch")
        
        for (index, asset) in allAssets.enumerated() {
            // Check if stopped
            guard isExtracting else {
                logInfo("Extraction stopped", category: "batch")
                break
            }
            
            // Wait while paused
            while isPaused && isExtracting {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            // Skip if already processed
            if processedAssets.contains(asset.localIdentifier) {
                continue
            }
            
            currentStatus = "Processing image \(index + 1) of \(totalToExtract)..."
            logInfo("Processing image \(index + 1) of \(totalToExtract)", category: "batch")
            
            // Load full resolution image
            guard let image = await photoManager.loadImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize
            ) else {
                logError("Failed to load image \(index + 1)", category: "batch")
                errorLog.append((imageIndex: index, error: "Failed to load image from Photos library"))
                failureCount += 1
                currentProgress += 1
                remainingAssets.removeFirst()
                continue
            }
            
            currentImage = image
            
            // Handle cropping if enabled
            var imageToProcess = image
            if shouldCrop {
                let shouldCropThisImage = await askToCrop()
                
                if shouldCropThisImage {
                    if let croppedImage = await requestCrop(for: image) {
                        imageToProcess = croppedImage
                        logInfo("Image cropped successfully for batch extraction", category: "batch")
                    } else {
                        logInfo("Crop cancelled, using original image", category: "batch")
                    }
                }
            }
            
            // Extract recipe from image
            await extractRecipeFromImage(imageToProcess, imageIndex: index)
            
            // Mark as processed and update queue
            processedAssets.insert(asset.localIdentifier)
            currentProgress += 1
            if !remainingAssets.isEmpty {
                remainingAssets.removeFirst()
            }
            
            // Process in batches of 10
            if currentProgress % 10 == 0 && currentProgress < totalToExtract {
                currentStatus = "Completed \(currentProgress) images. Continuing with next batch..."
                logInfo("Completed batch of 10, continuing...", category: "batch")
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second pause
            }
        }
        
        // Extraction complete
        currentStatus = "Complete! Extracted \(successCount) recipes."
        isExtracting = false
        logInfo("Batch extraction complete: \(successCount) success, \(failureCount) failures", category: "batch")
    }
    
    private func askToCrop() async -> Bool {
        await withCheckedContinuation { continuation in
            self.cropContinuation = continuation
            self.isWaitingForCrop = true
        }
    }
    
    private func extractRecipeFromImage(_ image: UIImage, imageIndex: Int) async {
        do {
            currentStatus = "Extracting recipe from image \(imageIndex + 1)..."
            
            // Reduce image size before sending
            guard let imageData = imagePreprocessor.reduceImageSize(image, maxSizeBytes: 500_000) else {
                throw NSError(
                    domain: "BatchExtraction",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to process image"]
                )
            }
            
            logInfo("Calling API for image \(imageIndex + 1), size: \(imageData.count) bytes", category: "batch")
            
            // Extract recipe using Claude API
            let recipe = try await apiClient.extractRecipe(
                from: imageData,
                usePreprocessing: true
            )
            
            currentRecipe = recipe
            
            // Save recipe to SwiftData
            await saveRecipe(recipe, withImage: image)
            
            successCount += 1
            logInfo("Successfully extracted recipe: \(recipe.title)", category: "batch")
            
        } catch let error as ClaudeAPIError {
            logError("API error for image \(imageIndex + 1): \(error.errorDescription ?? "unknown")", category: "batch")
            errorLog.append((imageIndex: imageIndex, error: error.errorDescription ?? "API error"))
            failureCount += 1
            currentRecipe = nil
            
        } catch {
            logError("Unexpected error for image \(imageIndex + 1): \(error.localizedDescription)", category: "batch")
            errorLog.append((imageIndex: imageIndex, error: error.localizedDescription))
            failureCount += 1
            currentRecipe = nil
        }
    }
    
    private func processImageBatch() async {
        logInfo("Processing batch of \(currentBatch.count) UIImages from Files/iCloud Drive", category: "batch")
        
        for (index, image) in currentBatch.enumerated() {
            // Check if stopped
            guard isExtracting else {
                logInfo("Extraction stopped", category: "batch")
                break
            }
            
            // Wait while paused
            while isPaused && isExtracting {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            currentStatus = "Processing image \(index + 1) of \(totalToExtract)..."
            logInfo("Processing UIImage \(index + 1) of \(totalToExtract)", category: "batch")
            
            currentImage = image
            
            // Handle cropping if enabled
            var imageToProcess = image
            if shouldCrop {
                let shouldCropThisImage = await askToCrop()
                
                if shouldCropThisImage {
                    if let croppedImage = await requestCrop(for: image) {
                        imageToProcess = croppedImage
                        logInfo("Image cropped successfully for batch extraction", category: "batch")
                    } else {
                        logInfo("Crop cancelled, using original image", category: "batch")
                    }
                }
            }
            
            // Extract recipe from image
            await extractRecipeFromImage(imageToProcess, imageIndex: index)
            
            currentProgress += 1
            
            // Process in batches of 10
            if currentProgress % 10 == 0 && currentProgress < totalToExtract {
                currentStatus = "Completed \(currentProgress) images. Continuing with next batch..."
                logInfo("Completed batch of 10, continuing...", category: "batch")
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second pause
            }
        }
        
        // Extraction complete
        currentStatus = "Complete! Extracted \(successCount) recipes."
        isExtracting = false
        currentBatch = []
        logInfo("Batch extraction from UIImages complete: \(successCount) success, \(failureCount) failures", category: "batch")
    }
    
    private func saveRecipe(_ recipeModel: RecipeModel, withImage image: UIImage) async {
        logInfo("Saving recipe: \(recipeModel.title)", category: "batch")
        
        // Convert to SwiftData Recipe
        let recipe = Recipe(from: recipeModel)
        
        // Generate filename and save image
        let imageName = "recipe_\(recipe.id.uuidString).jpg"
        recipe.imageName = imageName
        
        // Save image to disk
        if let imageData = imagePreprocessor.reduceImageSize(image, maxSizeBytes: 500_000) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(imageName)
            
            do {
                try imageData.write(to: fileURL)
                logInfo("Saved image to: \(fileURL.path)", category: "batch")
            } catch {
                logError("Failed to save image: \(error)", category: "batch")
            }
        }
        
        // Insert into SwiftData
        modelContext.insert(recipe)
        
        // Create image assignment for compatibility
        let assignment = RecipeImageAssignment(recipeID: recipe.id, imageName: imageName)
        modelContext.insert(assignment)
        
        // Save context
        do {
            try modelContext.save()
            logInfo("Recipe saved to database", category: "batch")
        } catch {
            logError("Failed to save recipe to database: \(error)", category: "batch")
        }
    }
}
