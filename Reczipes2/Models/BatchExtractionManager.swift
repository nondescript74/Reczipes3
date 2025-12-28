//
//  BatchExtractionManager.swift
//  Reczipes2
//
//  Created for background batch recipe extraction
//

import SwiftUI
import SwiftData
import Combine

/// Detailed extraction step for better progress tracking
enum ExtractionStep: String {
    case fetching = "Fetching recipe page..."
    case analyzing = "Analyzing with Claude AI..."
    case downloadingImages = "Downloading images..."
    case savingRecipe = "Saving recipe..."
    case waiting = "Waiting before next extraction..."
    case complete = "Complete"
    case failed = "Failed"
}

/// Detailed status for current extraction
struct ExtractionStatus {
    let currentIndex: Int
    let totalCount: Int
    let currentLink: SavedLink?
    let currentRecipe: RecipeModel?
    let currentStep: ExtractionStep
    let stepProgress: Double // 0.0 to 1.0 for current step
    let imagesDownloaded: Int
    let totalImages: Int
    let timeElapsed: TimeInterval
    let estimatedTimeRemaining: TimeInterval?
}

/// Singleton manager for background batch extraction
@MainActor
class BatchExtractionManager: ObservableObject {
    static let shared = BatchExtractionManager()
    
    // MARK: - Published Properties
    
    @Published var isExtracting = false
    @Published var isPaused = false
    @Published var currentStatus: ExtractionStatus?
    @Published var totalProcessed: Int = 0
    @Published var successCount: Int = 0
    @Published var failureCount: Int = 0
    @Published var errorLog: [(link: String, error: String, timestamp: Date)] = []
    @Published var currentRecipe: RecipeModel?
    @Published var recentlyExtracted: [RecipeModel] = [] // Last 5 extracted recipes
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    private var apiKey: String?
    private let extractionInterval: TimeInterval = 5.0
    private let maxBatchSize: Int = 50
    private var extractionTask: Task<Void, Never>?
    private var startTime: Date?
    private var averageExtractionTime: TimeInterval = 30.0 // Initial estimate
    private var extractionTimes: [TimeInterval] = []
    
    private let webImageDownloader = WebImageDownloader()
    
    // MARK: - Initialization
    
    private init() {
        logInfo("BatchExtractionManager initialized", category: "batch-extraction")
    }
    
    // MARK: - Configuration
    
    func configure(apiKey: String, modelContext: ModelContext) {
        self.apiKey = apiKey
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Start batch extraction in the background
    func startBatchExtraction(links: [SavedLink]) {
        guard !isExtracting else {
            logWarning("Extraction already in progress", category: "batch-extraction")
            return
        }
        
        guard let apiKey = apiKey, let modelContext = modelContext else {
            logError("BatchExtractionManager not configured", category: "batch-extraction")
            return
        }
        
        let unprocessedLinks = links.filter { !$0.isProcessed }
        guard !unprocessedLinks.isEmpty else {
            logInfo("No unprocessed links to extract", category: "batch-extraction")
            return
        }
        
        // Limit to maxBatchSize recipes
        let linksToProcess = Array(unprocessedLinks.prefix(maxBatchSize))
        
        isExtracting = true
        isPaused = false
        totalProcessed = 0
        successCount = 0
        failureCount = 0
        errorLog = []
        recentlyExtracted = []
        startTime = Date()
        
        logInfo("Starting batch extraction of \(linksToProcess.count) links", category: "batch-extraction")
        
        // Start extraction task that runs independently
        extractionTask = Task.detached(priority: .userInitiated) { [weak self] in
            await self?.performBatchExtraction(links: linksToProcess, apiKey: apiKey, modelContext: modelContext)
        }
    }
    
    /// Pause the batch extraction
    func pause() {
        isPaused = true
        logInfo("Batch extraction paused", category: "batch-extraction")
    }
    
    /// Resume the batch extraction
    func resume() {
        isPaused = false
        logInfo("Batch extraction resumed", category: "batch-extraction")
    }
    
    /// Stop the batch extraction
    func stop() {
        extractionTask?.cancel()
        extractionTask = nil
        
        Task { @MainActor in
            self.isExtracting = false
            self.isPaused = false
            self.currentStatus = nil
            logInfo("Batch extraction stopped", category: "batch-extraction")
        }
    }
    
    /// Reset all state
    func reset() {
        totalProcessed = 0
        successCount = 0
        failureCount = 0
        errorLog = []
        currentStatus = nil
        currentRecipe = nil
        recentlyExtracted = []
        startTime = nil
    }
    
    // MARK: - Background Extraction
    
    private func performBatchExtraction(links: [SavedLink], apiKey: String, modelContext: ModelContext) async {
        for (index, link) in links.enumerated() {
            // Check if task was cancelled
            guard !Task.isCancelled else {
                await MainActor.run {
                    self.isExtracting = false
                }
                logInfo("Batch extraction cancelled", category: "batch-extraction")
                break
            }
            
            // Wait while paused
            while await isPausedCheck() && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            guard !Task.isCancelled else { break }
            
            let extractionStart = Date()
            
            // Update status
            await updateStatus(
                currentIndex: index + 1,
                totalCount: links.count,
                currentLink: link,
                step: .fetching,
                stepProgress: 0.0
            )
            
            // Extract the recipe
            await extractSingleLink(link, index: index + 1, total: links.count, modelContext: modelContext, apiKey: apiKey)
            
            // Record extraction time
            let extractionTime = Date().timeIntervalSince(extractionStart)
            await recordExtractionTime(extractionTime)
            
            // Wait for the interval before next extraction (except for last one)
            if index < links.count - 1 && !Task.isCancelled {
                await performWait(remaining: links.count - index - 1)
            }
        }
        
        // Extraction complete
        if !Task.isCancelled {
            await MainActor.run {
                self.isExtracting = false
                logInfo("Batch extraction complete: \(self.successCount) succeeded, \(self.failureCount) failed", category: "batch-extraction")
            }
        }
    }
    
    private func extractSingleLink(_ link: SavedLink, index: Int, total: Int, modelContext: ModelContext, apiKey: String) async {
        do {
            // Step 1: Fetch and analyze
            await updateStatus(
                currentIndex: index,
                totalCount: total,
                currentLink: link,
                step: .analyzing,
                stepProgress: 0.1
            )
            
            let extractor = RecipeExtractorViewModel(apiKey: apiKey)
            await extractor.extractRecipe(from: link.url)
            
            // Check for errors
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
            
            await updateStatus(
                currentIndex: index,
                totalCount: total,
                currentLink: link,
                step: .analyzing,
                stepProgress: 0.5
            )
            
            // Store current recipe
            await MainActor.run {
                self.currentRecipe = recipe
            }
            
            // Step 2: Download images
            var downloadedImages: [UIImage] = []
            if let imageURLs = recipe.imageURLs, !imageURLs.isEmpty {
                await updateStatus(
                    currentIndex: index,
                    totalCount: total,
                    currentLink: link,
                    step: .downloadingImages,
                    stepProgress: 0.0,
                    imagesDownloaded: 0,
                    totalImages: imageURLs.count
                )
                
                for (imgIndex, imageURL) in imageURLs.enumerated() {
                    do {
                        let image = try await webImageDownloader.downloadImage(from: imageURL)
                        downloadedImages.append(image)
                        
                        await updateStatus(
                            currentIndex: index,
                            totalCount: total,
                            currentLink: link,
                            step: .downloadingImages,
                            stepProgress: Double(imgIndex + 1) / Double(imageURLs.count),
                            imagesDownloaded: imgIndex + 1,
                            totalImages: imageURLs.count
                        )
                    } catch {
                        logWarning("Failed to download image \(imgIndex + 1): \(error)", category: "batch-extraction")
                    }
                }
            }
            
            // Step 3: Save recipe
            await updateStatus(
                currentIndex: index,
                totalCount: total,
                currentLink: link,
                step: .savingRecipe,
                stepProgress: 0.8
            )
            
            try await saveRecipe(recipe, images: downloadedImages, link: link, modelContext: modelContext)
            
            // Mark as success
            await MainActor.run {
                self.successCount += 1
                self.totalProcessed += 1
                
                // Add to recently extracted (keep last 5)
                self.recentlyExtracted.insert(recipe, at: 0)
                if self.recentlyExtracted.count > 5 {
                    self.recentlyExtracted = Array(self.recentlyExtracted.prefix(5))
                }
            }
            
            link.isProcessed = true
            link.processingError = nil
            
            logInfo("Successfully extracted: \(recipe.title)", category: "batch-extraction")
            
        } catch {
            // Mark as failure
            await MainActor.run {
                self.failureCount += 1
                self.totalProcessed += 1
                self.errorLog.append((link: link.title, error: error.localizedDescription, timestamp: Date()))
            }
            
            link.isProcessed = true
            link.processingError = error.localizedDescription
            
            logError("Failed to extract \(link.title): \(error)", category: "batch-extraction")
        }
        
        // Save link status
        do {
            try modelContext.save()
        } catch {
            logError("Failed to save link status: \(error)", category: "batch-extraction")
        }
    }
    
    private func saveRecipe(_ recipeModel: RecipeModel, images: [UIImage], link: SavedLink, modelContext: ModelContext) async throws {
        // Convert RecipeModel to SwiftData Recipe
        let recipe = Recipe(from: recipeModel)
        recipe.reference = link.url
        
        // Save images
        var additionalImageFilenames: [String] = []
        for (index, image) in images.enumerated() {
            let filename: String
            if index == 0 {
                filename = "recipe_\(recipe.id.uuidString).jpg"
                recipe.imageName = filename
                saveImageToDisk(image, filename: filename)
                
                let assignment = RecipeImageAssignment(recipeID: recipe.id, imageName: filename)
                modelContext.insert(assignment)
            } else {
                filename = "recipe_\(recipe.id.uuidString)_\(index).jpg"
                saveImageToDisk(image, filename: filename)
                additionalImageFilenames.append(filename)
            }
        }
        
        if !additionalImageFilenames.isEmpty {
            recipe.additionalImageNames = additionalImageFilenames
        }
        
        modelContext.insert(recipe)
        link.extractedRecipeID = recipe.id
        
        try modelContext.save()
        logInfo("Recipe saved: \(recipe.title)", category: "batch-extraction")
    }
    
    private func saveImageToDisk(_ image: UIImage, filename: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            logError("Failed to convert image to JPEG data", category: "batch-extraction")
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
        } catch {
            logError("Failed to save image \(filename): \(error)", category: "batch-extraction")
        }
    }
    
    // MARK: - Status Updates
    
    private func updateStatus(
        currentIndex: Int,
        totalCount: Int,
        currentLink: SavedLink?,
        step: ExtractionStep,
        stepProgress: Double,
        imagesDownloaded: Int = 0,
        totalImages: Int = 0
    ) async {
        let timeElapsed = startTime.map { Date().timeIntervalSince($0) } ?? 0
        let estimatedRemaining = calculateEstimatedTimeRemaining(
            currentIndex: currentIndex,
            totalCount: totalCount,
            timeElapsed: timeElapsed
        )
        
        await MainActor.run {
            self.currentStatus = ExtractionStatus(
                currentIndex: currentIndex,
                totalCount: totalCount,
                currentLink: currentLink,
                currentRecipe: self.currentRecipe,
                currentStep: step,
                stepProgress: stepProgress,
                imagesDownloaded: imagesDownloaded,
                totalImages: totalImages,
                timeElapsed: timeElapsed,
                estimatedTimeRemaining: estimatedRemaining
            )
        }
    }
    
    private func calculateEstimatedTimeRemaining(currentIndex: Int, totalCount: Int, timeElapsed: TimeInterval) -> TimeInterval? {
        guard currentIndex > 0 else { return nil }
        
        let averageTimePerRecipe = timeElapsed / Double(currentIndex)
        let remaining = totalCount - currentIndex
        return averageTimePerRecipe * Double(remaining)
    }
    
    private func recordExtractionTime(_ time: TimeInterval) async {
        await MainActor.run {
            self.extractionTimes.append(time)
            
            // Keep only last 10 times for rolling average
            if self.extractionTimes.count > 10 {
                self.extractionTimes.removeFirst()
            }
            
            // Calculate average
            self.averageExtractionTime = self.extractionTimes.reduce(0, +) / Double(self.extractionTimes.count)
        }
    }
    
    private func performWait(remaining: Int) async {
        guard !Task.isCancelled else { return }
        
        let intervalSteps = Int(extractionInterval * 2) // Check every 0.5 seconds
        for _ in 0..<intervalSteps {
            guard !Task.isCancelled else { break }
            
            while await isPausedCheck() && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            
            guard !Task.isCancelled else { break }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
    
    private func isPausedCheck() async -> Bool {
        await MainActor.run {
            return self.isPaused
        }
    }
}
