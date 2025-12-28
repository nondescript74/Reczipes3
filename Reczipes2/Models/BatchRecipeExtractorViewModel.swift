//
//  BatchRecipeExtractorViewModel.swift
//  Reczipes2
//
//  Created for automated batch recipe extraction from saved links
//

import SwiftUI
import SwiftData
import Combine

/// View model for managing automated batch extraction of recipes from saved links
@MainActor
class BatchRecipeExtractorViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isExtracting = false
    @Published var isPaused = false
    @Published var currentLink: SavedLink?
    @Published var currentRecipe: RecipeModel?
    @Published var currentProgress: Int = 0
    @Published var totalToExtract: Int = 0
    @Published var successCount: Int = 0
    @Published var failureCount: Int = 0
    @Published var currentStatus: String = ""
    @Published var errorLog: [(link: String, error: String)] = []
    
    // MARK: - Private Properties
    
    private let apiKey: String
    private let modelContext: ModelContext
    private let extractionInterval: TimeInterval = 5.0 // 5 seconds between extractions
    private let maxBatchSize: Int = 50 // Maximum recipes per batch
    private var extractionTask: Task<Void, Never>?
    private let webImageDownloader = WebImageDownloader()
    private let retryManager = ExtractionRetryManager()
    
    // Retry configuration - can be adjusted per user preference
    private let retryConfiguration = ExtractionRetryManager.RetryConfiguration.default
    
    // MARK: - Initialization
    
    init(apiKey: String, modelContext: ModelContext) {
        self.apiKey = apiKey
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Start batch extraction of all unprocessed links
    func startBatchExtraction(links: [SavedLink]) {
        guard !isExtracting else { return }
        
        let unprocessedLinks = links.filter { !$0.isProcessed }
        guard !unprocessedLinks.isEmpty else {
            logInfo("No unprocessed links to extract", category: "batch-extraction")
            return
        }
        
        // Limit to maxBatchSize recipes
        let linksToProcess = Array(unprocessedLinks.prefix(maxBatchSize))
        let remainingCount = unprocessedLinks.count - linksToProcess.count
        
        isExtracting = true
        isPaused = false
        currentProgress = 0
        totalToExtract = linksToProcess.count
        successCount = 0
        failureCount = 0
        errorLog = []
        
        if remainingCount > 0 {
            currentStatus = "Starting batch extraction (limited to \(maxBatchSize) recipes, \(remainingCount) will remain)..."
            logInfo("Starting batch extraction of \(totalToExtract) links (limited from \(unprocessedLinks.count))", category: "batch-extraction")
        } else {
            currentStatus = "Starting batch extraction..."
            logInfo("Starting batch extraction of \(totalToExtract) links", category: "batch-extraction")
        }
        
        extractionTask = Task {
            await extractLinks(linksToProcess)
        }
    }
    
    /// Pause the batch extraction
    func pause() {
        isPaused = true
        currentStatus = "Paused"
        logInfo("Batch extraction paused", category: "batch-extraction")
    }
    
    /// Resume the batch extraction
    func resume() {
        isPaused = false
        currentStatus = "Resuming..."
        logInfo("Batch extraction resumed", category: "batch-extraction")
    }
    
    /// Stop the batch extraction
    func stop() {
        extractionTask?.cancel()
        extractionTask = nil
        isExtracting = false
        isPaused = false
        currentLink = nil
        currentRecipe = nil
        currentStatus = "Stopped"
        logInfo("Batch extraction stopped", category: "batch-extraction")
    }
    
    /// Reset all counters and state
    func reset() {
        currentProgress = 0
        totalToExtract = 0
        successCount = 0
        failureCount = 0
        currentStatus = ""
        errorLog = []
        currentLink = nil
        currentRecipe = nil
    }
    
    // MARK: - Private Methods
    
    /// Extract recipes from a list of links with interval between each
    private func extractLinks(_ links: [SavedLink]) async {
        for (index, link) in links.enumerated() {
            // Check if task was cancelled
            guard !Task.isCancelled else {
                currentStatus = "Cancelled"
                logInfo("Batch extraction cancelled", category: "batch-extraction")
                break
            }
            
            // Wait while paused
            while isPaused && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            guard !Task.isCancelled else { break }
            
            currentLink = link
            currentProgress = index + 1
            currentStatus = "Extracting \(index + 1) of \(totalToExtract): \(link.title)"
            
            logInfo("Extracting link \(index + 1)/\(totalToExtract): \(link.title)", category: "batch-extraction")
            
            // Extract the recipe
            await extractSingleLink(link)
            
            // Wait for the interval before next extraction (except for last one)
            if index < links.count - 1 && !Task.isCancelled {
                currentStatus = "Waiting \(Int(extractionInterval)) seconds before next extraction..."
                logInfo("Waiting \(extractionInterval) seconds before next extraction", category: "batch-extraction")
                
                // Use a loop to check for pause/cancel during wait
                let intervalSteps = Int(extractionInterval * 2) // Check every 0.5 seconds
                for step in 0..<intervalSteps {
                    guard !Task.isCancelled else { break }
                    
                    while isPaused && !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                    }
                    
                    guard !Task.isCancelled else { break }
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    
                    // Update countdown status
                    let remaining = Int(extractionInterval) - (step / 2)
                    if remaining > 0 {
                        currentStatus = "Waiting \(remaining) seconds before next extraction..."
                    }
                }
            }
        }
        
        // Extraction complete
        if !Task.isCancelled {
            isExtracting = false
            currentStatus = "Complete! ✓ \(successCount) succeeded, ✗ \(failureCount) failed"
            logInfo("Batch extraction complete: \(successCount) succeeded, \(failureCount) failed", category: "batch-extraction")
        }
    }
    
    /// Extract a single recipe from a link with automatic retry on failure
    private func extractSingleLink(_ link: SavedLink) async {
        let operationID = "extract-\(link.id.uuidString)"
        
        // Extract values needed for the closure to avoid capturing non-Sendable link
        let linkID = link.id
        let linkURL = link.url
        let linkTitle = link.title
        
        do {
            // Wrap the entire extraction process in retry logic
            let (recipe, downloadedImages) = try await retryManager.withRetry(
                operationID: operationID,
                configuration: retryConfiguration
            ) {
                // This closure will be retried on transient failures
                try await self.performExtractionWithValues(linkID: linkID, url: linkURL, title: linkTitle)
            }
            
            // Save recipe to database (outside retry block - if this fails, we don't retry)
            currentStatus = "Saving recipe..."
            try await saveRecipe(recipe, images: downloadedImages, link: link)
            
            // Mark as success
            successCount += 1
            link.isProcessed = true
            link.processingError = nil
            
            // Get retry stats for logging
            let stats = await retryManager.getRetryStats(operationID: operationID)
            if stats.totalAttempts > 1 {
                logInfo("Successfully extracted '\(recipe.title)' after \(stats.totalAttempts) attempts", category: "batch-extraction")
            } else {
                logInfo("Successfully extracted and saved: \(recipe.title)", category: "batch-extraction")
            }
            
            // Clear retry history for this operation
            await retryManager.clearHistory(operationID: operationID)
            
        } catch {
            // All retries failed - mark as permanent failure
            failureCount += 1
            link.isProcessed = true
            link.processingError = error.localizedDescription
            errorLog.append((link: link.title, error: error.localizedDescription))
            
            let stats = await retryManager.getRetryStats(operationID: operationID)
            logError("Failed to extract '\(link.title)' after \(stats.totalAttempts) attempt(s): \(error)", category: "batch-extraction")
            
            // Clear retry history
            await retryManager.clearHistory(operationID: operationID)
        }
        
        // Save link status
        do {
            try modelContext.save()
        } catch {
            logError("Failed to save link status: \(error)", category: "batch-extraction")
        }
    }
    
    /// Perform the actual extraction (wrapped by retry logic)
    /// - Parameters:
    ///   - linkID: The UUID of the saved link
    ///   - url: The URL to extract from
    ///   - title: The title of the link (for logging)
    /// - Returns: Tuple of (recipe, downloaded images)
    /// - Throws: Any error during extraction
    private func performExtractionWithValues(linkID: UUID, url: String, title: String) async throws -> (RecipeModel, [UIImage]) {
        // Create extractor for this link
        let extractor = RecipeExtractorViewModel(apiKey: apiKey)
        
        // Extract recipe
        await extractor.extractRecipe(from: url)
        
        // Check if extraction was successful
        if let error = extractor.errorMessage {
            throw NSError(
                domain: "BatchExtraction",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: error]
            )
        }
        
        guard let recipe = extractor.extractedRecipe else {
            throw NSError(
                domain: "BatchExtraction",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No recipe extracted"]
            )
        }
        
        // Store the current recipe for display
        currentRecipe = recipe
        
        // Download images if available (with individual retry per image)
        var downloadedImages: [UIImage] = []
        if let imageURLs = recipe.imageURLs, !imageURLs.isEmpty {
            currentStatus = "Downloading \(imageURLs.count) image(s)..."
            logInfo("Downloading \(imageURLs.count) images for: \(recipe.title)", category: "batch-extraction")
            
            for (index, imageURL) in imageURLs.enumerated() {
                let imageOperationID = "image-\(linkID.uuidString)-\(index)"
                
                do {
                    // Retry image downloads too
                    let image = try await retryManager.withRetry(
                        operationID: imageOperationID,
                        configuration: .init(
                            maxAttempts: 2,  // Fewer retries for images
                            initialDelay: 1.0,
                            maxDelay: 5.0,
                            backoffMultiplier: 2.0,
                            useJitter: true
                        )
                    ) {
                        try await self.webImageDownloader.downloadImage(from: imageURL)
                    }
                    downloadedImages.append(image)
                    await retryManager.clearHistory(operationID: imageOperationID)
                } catch {
                    logWarning("Failed to download image after retries: \(error)", category: "batch-extraction")
                    await retryManager.clearHistory(operationID: imageOperationID)
                    // Continue with other images - don't fail the whole extraction
                }
            }
        }
        
        return (recipe, downloadedImages)
    }
    
    /// Save a recipe with its images to the database
    private func saveRecipe(_ recipeModel: RecipeModel, images: [UIImage], link: SavedLink) async throws {
        // Convert RecipeModel to SwiftData Recipe
        let recipe = Recipe(from: recipeModel)
        
        // Set reference to the original link URL
        recipe.reference = link.url
        
        // Save images and set image names
        var additionalImageFilenames: [String] = []
        for (index, image) in images.enumerated() {
            let filename: String
            if index == 0 {
                // First image is the main thumbnail
                filename = "recipe_\(recipe.id.uuidString).jpg"
                recipe.imageName = filename
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
        
        // Set additionalImageNames on the recipe
        if !additionalImageFilenames.isEmpty {
            recipe.additionalImageNames = additionalImageFilenames
            logInfo("Set recipe.additionalImageNames to \(additionalImageFilenames.count) images", category: "batch-extraction")
        }
        
        // Insert into SwiftData context
        modelContext.insert(recipe)
        
        // Update the link to mark it as processed
        link.extractedRecipeID = recipe.id
        
        // Save the context
        do {
            try modelContext.save()
            logInfo("Recipe saved successfully: \(recipe.title)", category: "batch-extraction")
        } catch {
            logError("Failed to save recipe to database: \(error)", category: "batch-extraction")
            throw error
        }
    }
    
    /// Save an image to disk
    private func saveImageToDisk(_ image: UIImage, filename: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            logError("Failed to convert image to JPEG data", category: "batch-extraction")
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            logInfo("Saved image: \(filename)", category: "batch-extraction")
        } catch {
            logError("Failed to save image \(filename): \(error)", category: "batch-extraction")
        }
    }
}
