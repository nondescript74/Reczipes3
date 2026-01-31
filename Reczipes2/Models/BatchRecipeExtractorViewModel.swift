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
    @Published var currentRecipe: RecipeX?
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
        // Extract values needed to avoid capturing non-Sendable link
        let linkID = link.id
        let linkURL = link.url
        let linkTitle = link.title
        
        // Manual retry logic since we can't use retryManager with non-Sendable return types
        var attempt = 0
        let maxAttempts = retryConfiguration.maxAttempts
        
        while attempt < maxAttempts {
            attempt += 1
            
            do {
                // Perform the extraction
                let (recipe, downloadedImages) = try await performExtractionWithValues(
                    linkID: linkID,
                    url: linkURL,
                    title: linkTitle
                )
                
                // Save recipe to database
                currentStatus = "Saving recipe..."
                try await saveRecipe(recipe, images: downloadedImages, link: link)
                
                // Mark as success
                successCount += 1
                link.isProcessed = true
                link.processingError = nil
                
                if attempt > 1 {
                    logInfo("Successfully extracted '\(String(describing: recipe.title))' after \(attempt) attempts", category: "batch-extraction")
                } else {
                    logInfo("Successfully extracted and saved: \(String(describing: recipe.title))", category: "batch-extraction")
                }
                
                // Success - break out of retry loop
                break
                
            } catch {
                // Check if we should retry
                if attempt < maxAttempts {
                    let delay = calculateRetryDelay(attempt: attempt)
                    logWarning("Extraction attempt \(attempt) failed for '\(linkTitle)', retrying in \(delay)s: \(error)", category: "batch-extraction")
                    currentStatus = "Attempt \(attempt) failed, retrying in \(Int(delay))s..."
                    
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    // All retries exhausted
                    failureCount += 1
                    link.isProcessed = true
                    link.processingError = error.localizedDescription
                    errorLog.append((link: link.title, error: error.localizedDescription))
                    
                    logError("Failed to extract '\(link.title)' after \(attempt) attempt(s): \(error)", category: "batch-extraction")
                }
            }
        }
        
        // Save link status
        do {
            try modelContext.save()
        } catch {
            logError("Failed to save link status: \(error)", category: "batch-extraction")
        }
    }
    
    /// Calculate retry delay using exponential backoff
    private func calculateRetryDelay(attempt: Int) -> TimeInterval {
        let baseDelay = retryConfiguration.initialDelay
        let multiplier = retryConfiguration.backoffMultiplier
        let maxDelay = retryConfiguration.maxDelay
        
        var delay = baseDelay * pow(multiplier, Double(attempt - 1))
        delay = min(delay, maxDelay)
        
        // Add jitter if configured
        if retryConfiguration.useJitter {
            let jitter = Double.random(in: 0...0.3) * delay
            delay += jitter
        }
        
        return delay
    }
    
    /// Perform the actual extraction
    /// - Parameters:
    ///   - linkID: The UUID of the saved link
    ///   - url: The URL to extract from
    ///   - title: The title of the link (for logging)
    /// - Returns: Tuple of (recipe, downloaded images)
    /// - Throws: Any error during extraction
    private func performExtractionWithValues(linkID: UUID, url: String, title: String) async throws -> (RecipeX, [UIImage]) {
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
        
        // Extract image URLs from recipe notes (where they're stored during web extraction)
        let imageURLs = extractImageURLsFromNotes(recipe)
        
        // Download images if available
        var downloadedImages: [UIImage] = []
        if !imageURLs.isEmpty {
            currentStatus = "Downloading \(imageURLs.count) image(s)..."
            logInfo("Downloading \(imageURLs.count) images for: \(String(describing: recipe.title))", category: "batch-extraction")
            
            for (_ , imageURL) in imageURLs.enumerated() {
                // Try to download each image with basic retry
                var imageAttempt = 0
                let maxImageAttempts = 2
                
                while imageAttempt < maxImageAttempts {
                    imageAttempt += 1
                    
                    do {
                        let image = try await webImageDownloader.downloadImage(from: imageURL)
                        downloadedImages.append(image)
                        break // Success
                    } catch {
                        if imageAttempt < maxImageAttempts {
                            logWarning("Image download attempt \(imageAttempt) failed, retrying: \(error)", category: "batch-extraction")
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        } else {
                            logWarning("Failed to download image after \(imageAttempt) attempts: \(error)", category: "batch-extraction")
                            // Continue with other images - don't fail the whole extraction
                        }
                    }
                }
            }
        }
        
        return (recipe, downloadedImages)
    }
    
    /// Save a recipe with its images to the database
    private func saveRecipe(_ recipe: RecipeX, images: [UIImage], link: SavedLink) async throws {
        
        // Set reference to the original link URL
        recipe.reference = link.url
        
        // Save images directly to SwiftData using imageData
        var additionalImageFilenames: [String] = []
        var totalImageDataSize = 0
        
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                logError("Failed to convert image to JPEG data", category: "batch-extraction")
                continue
            }
            
            totalImageDataSize += imageData.count
            
            if index == 0 {
                // First image is the main image - store in imageData
                let filename = "recipe_\(recipe.id!.uuidString).jpg"
                recipe.imageName = filename
                recipe.imageData = imageData
                
                logInfo("Saved main image data (\(imageData.count / 1024)KB) to recipe", category: "batch-extraction")
                
                // Create image assignment for compatibility
                let assignment = RecipeImageAssignment(recipeID: recipe.id!, imageName: filename)
                modelContext.insert(assignment)
            } else {
                // Additional images - add to the filename list for tracking
                let filename = "recipe_\(recipe.id!.uuidString)_\(index).jpg"
                additionalImageFilenames.append(filename)
            }
        }
        
        // Set additional images data if any
        if images.count > 1 {
            var additionalImages: [[String: Data]] = []
            
            // Process additional images (skip first one as it's the main image)
            for (index, image) in images.dropFirst().enumerated() {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
                
                let filename = "recipe_\(recipe.id!.uuidString)_\(index + 1).jpg"
                additionalImages.append(["data": imageData, "name": Data(filename.utf8)])
            }
            
            // Encode and store additional images
            if !additionalImages.isEmpty {
                if let encoded = try? JSONEncoder().encode(additionalImages) {
                    recipe.additionalImagesData = encoded
                    recipe.additionalImageNames = additionalImageFilenames
                    logInfo("Saved \(additionalImages.count) additional images (\(totalImageDataSize / 1024)KB total) to recipe", category: "batch-extraction")
                }
            }
        }
        
        // Insert into SwiftData context
        modelContext.insert(recipe)
        
        // Update the link to mark it as processed
        link.extractedRecipeID = recipe.id
        
        // Save the context
        do {
            try modelContext.save()
            logInfo("Recipe saved successfully: \(String(describing: recipe.title)) with \(images.count) image(s) in SwiftData", category: "batch-extraction")
        } catch {
            logError("Failed to save recipe to database: \(error)", category: "batch-extraction")
            throw error
        }
    }
    
    /// Extract image URLs from recipe notes
    /// Image URLs are stored in notes during web extraction with the format:
    /// "Image URLs from source:\n" followed by URLs on separate lines
    private func extractImageURLsFromNotes(_ recipe: RecipeX) -> [String] {
        let notes = recipe.notes
        
        for note in notes {
            if note.text.hasPrefix("Image URLs from source:") {
                // Extract URLs from the note text
                let lines = note.text.components(separatedBy: .newlines)
                // Skip the first line which is "Image URLs from source:"
                let urls = lines.dropFirst().compactMap { line -> String? in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    // Validate it looks like a URL
                    if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                        return trimmed
                    }
                    return nil
                }
                return urls
            }
        }
        
        return []
    }
}
