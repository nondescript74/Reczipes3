//
//  RecipeExtractorViewModel.swift
//  Reczipes2
//
//  Created for Claude-powered recipe extraction
//

import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif
import Combine

@MainActor
class RecipeExtractorViewModel: ObservableObject {
    @Published var extractedRecipe: RecipeX?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var usePreprocessing = true
    @Published var recipeURL: String = ""
    @Published var extractedImageURLs: [String] = [] // Image URLs from web extraction
    
    private let apiClient: ClaudeAPIClient
    private let imagePreprocessor = ImagePreprocessor()
    private let webExtractor = WebRecipeExtractor()
    
    @Published var showingDuplicateResolution = false
    @Published var duplicateMatch: DuplicateMatch?
    
    private var duplicateDetectionService: DuplicateDetectionService?
    private let imageHashService = ImageHashService()
    
    func saveRecipe(modelContext: ModelContext) {
        guard let recipe = extractedRecipe else { return }
        
        // Check for duplicates
        Task {
            let service = DuplicateDetectionService(modelContext: modelContext)
            let duplicates = await service.findSimilarByContent(recipe, threshold: 0.8)
            
            if let firstMatch = duplicates.first {
                // Show duplicate resolution
                duplicateMatch = firstMatch
                showingDuplicateResolution = true
            } else {
                // No duplicates, save normally
                saveRecipeDirectly(recipe, modelContext: modelContext)
            }
        }
    }
    
    private func saveRecipeDirectly(_ recipe: RecipeX, modelContext: ModelContext) {
         
        // Set extraction source
        recipe.extractionSource = "camera" // or "photos" or "files"
        
        // Generate and store image hash
        if let image = selectedImage,
           let hash = imageHashService.generateHash(for: image) {
            recipe.imageHash = hash
            
            // Also save the image data directly in RecipeX
            recipe.setImage(image, isMainImage: true)
        }
        
        // Initialize CloudKit sync properties
        recipe.needsCloudSync = true
        recipe.syncRetryCount = 0
        recipe.lastSyncError = nil
        recipe.cloudRecordID = nil
        recipe.lastSyncedToCloud = nil
        
        // Set timestamps
        let now = Date()
        recipe.dateAdded = now
        recipe.dateCreated = now
        recipe.lastModified = now
        
        // Set initial version
        recipe.version = 1
        
        // Set device identifier for attribution
        recipe.lastModifiedDeviceID = UIDevice.current.identifierForVendor?.uuidString
        
        // Calculate content fingerprint for duplicate detection
        recipe.updateContentFingerprint()
        
        modelContext.insert(recipe)
        
        do {
            try modelContext.save()
            logInfo("Recipe saved successfully: \(recipe.safeTitle) (RecipeX with CloudKit sync)", category: "extraction")
        } catch {
            logError("Failed to save recipe: \(error)", category: "extraction")
            errorMessage = "Failed to save recipe: \(error.localizedDescription)"
        }
    }
    
    
    func handleReplaceOriginal(modelContext: ModelContext) {
        guard let newRecipe = extractedRecipe,
              let match = duplicateMatch else { return }
        
        let existingRecipe = match.existingRecipe
        let encoder = JSONEncoder()
        
        // Update existing RecipeX with new data
        existingRecipe.title = newRecipe.title
        existingRecipe.headerNotes = newRecipe.headerNotes
        existingRecipe.recipeYield = newRecipe.yield
        existingRecipe.reference = newRecipe.reference
        
        // Encode and update ingredient sections
        if let ingredientsData = try? encoder.encode(newRecipe.ingredientSections) {
            existingRecipe.updateIngredients(ingredientsData)
        }
        
        // Encode and update instruction sections
        if let instructionsData = try? encoder.encode(newRecipe.instructionSections) {
            existingRecipe.updateInstructions(instructionsData)
        }
        
        // Encode and update notes
        if let notesData = try? encoder.encode(newRecipe.notes) {
            existingRecipe.notesData = notesData
        }
        
        // Update the image if available
        if let image = selectedImage {
            existingRecipe.setImage(image, isMainImage: true)
        }
        
        // Mark as modified (this updates version, timestamp, and triggers CloudKit sync)
        existingRecipe.markAsModified()
        
        // Update content fingerprint
        existingRecipe.updateContentFingerprint()
        
        do {
            try modelContext.save()
            logInfo("Recipe replaced successfully: \(existingRecipe.safeTitle)", category: "extraction")
        } catch {
            logError("Failed to replace recipe: \(error)", category: "extraction")
            errorMessage = "Failed to replace recipe: \(error.localizedDescription)"
        }
    }
    
    func handleKeepOriginal() {
        // Just dismiss, don't save
        extractedRecipe = nil
    }
    
    init(apiKey: String) {
        self.apiClient = ClaudeAPIClient(apiKey: apiKey)
    }
    
    /// Extract recipe from a web URL
    func extractRecipe(from url: String) async {
        // Explicitly set loading state on main actor
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            extractedRecipe = nil
            selectedImage = nil // Clear image when extracting from URL
            processedImage = nil
            extractedImageURLs = [] // Clear previous image URLs
        }
        
        logInfo("Starting URL extraction from: \(url)", category: "extraction")
        
        do {
            // Fetch web content
            let htmlContent = try await webExtractor.fetchWebContent(from: url)
            
            // Extract image URLs BEFORE cleaning (to preserve all HTML)
            let imageURLs = webExtractor.extractImageURLs(from: htmlContent)
            logInfo("Found \(imageURLs.count) image URL(s) in webpage", category: "extraction")
            
            // Clean the HTML
            let cleanedContent = webExtractor.cleanHTML(htmlContent)
            
            // Limit content size to avoid token limits (approximately 100k characters)
            let contentToSend: String
            if cleanedContent.count > 50_000 {
                logWarning("Content too large (\(cleanedContent.count) chars), truncating to 50k characters", category: "extraction")
                contentToSend = String(cleanedContent.prefix(50_000))
            } else {
                contentToSend = cleanedContent
            }
            
            logInfo("Calling Claude API for URL extraction...", category: "extraction")
            
            // Extract recipe using Claude
            let recipe = try await apiClient.extractRecipe(from: contentToSend)
            
            // Add the source URL to the reference field if not already present
            if recipe.reference == nil || recipe.reference?.isEmpty == true {
                recipe.reference = url
            }
            
            // Store image URLs in recipe notes (or you can add a separate property if needed)
            if !imageURLs.isEmpty {
                let imageURLNote = "Image URLs from source:\n" + imageURLs.joined(separator: "\n")
                var notes = recipe.notes // Get current notes (computed property)
                notes.append(RecipeNote(type: .general, text: imageURLNote))
                
                // Encode and store back in notesData
                if let encodedNotes = try? JSONEncoder().encode(notes) {
                    recipe.notesData = encodedNotes
                }
            }
            
            await MainActor.run {
                self.extractedRecipe = recipe
                self.extractedImageURLs = imageURLs // Store image URLs separately for view access
                logInfo("URL extraction successful: \(String(describing: recipe.title))", category: "extraction")
            }
        } catch let error as WebExtractionError {
            await MainActor.run {
                self.errorMessage = error.errorDescription
                logError("Web extraction error: \(error.errorDescription ?? "unknown")", category: "extraction")
            }
        } catch let error as ClaudeAPIError {
            await MainActor.run {
                self.errorMessage = error.errorDescription
                logError("Claude API error during URL extraction: \(error.errorDescription ?? "unknown")", category: "extraction")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Unexpected error: \(error.localizedDescription)"
                logError("Unexpected error during URL extraction: \(error.localizedDescription)", category: "extraction")
            }
        }
        
        await MainActor.run {
            isLoading = false
            logInfo("URL extraction complete, isLoading set to false", category: "extraction")
        }
    }
    
    /// Extract recipe from the selected image
    func extractRecipe(from image: UIImage) async {
        // Explicitly set loading state on main actor
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            extractedRecipe = nil // Clear any previous recipe
            selectedImage = image
        }
        
        logInfo("Starting image extraction, isLoading set to true", category: "extraction")
        
        // Generate processed preview if preprocessing is enabled
        if usePreprocessing {
            if let processedData = imagePreprocessor.preprocessForOCR(image),
               let processedUIImage = UIImage(data: processedData) {
                await MainActor.run {
                    processedImage = processedUIImage
                }
            }
        } else {
            await MainActor.run {
                processedImage = nil
            }
        }
        
        do {
            // Reduce image size to 10-20KB max before sending to Claude
            // Since we're only extracting text, we don't need high resolution
            logInfo("Reducing image size before sending to Claude...", category: "extraction")
            guard let imageData = imagePreprocessor.reduceImageSize(image, maxSizeBytes: 20_000) else {
                throw ClaudeAPIError.invalidResponse
            }
            logInfo("Image size after reduction: \(imageData.count) bytes (~\(imageData.count / 1024)KB)", category: "extraction")
            
            logInfo("Calling Claude API for image extraction...", category: "extraction")
            let recipe = try await apiClient.extractRecipe(
                from: imageData,
                usePreprocessing: usePreprocessing
            )
            
            await MainActor.run {
                self.extractedRecipe = recipe
                logInfo("Recipe extraction successful", category: "extraction")
            }
        } catch let error as ClaudeAPIError {
            await MainActor.run {
                self.errorMessage = error.errorDescription
                logError("Claude API error during extraction: \(error.errorDescription ?? "unknown")", category: "extraction")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Unexpected error: \(error.localizedDescription)"
                logError("Unexpected error during extraction: \(error.localizedDescription)", category: "extraction")
            }
        }
        
        await MainActor.run {
            isLoading = false
            logInfo("Image extraction complete, isLoading set to false", category: "extraction")
        }
    }
    
    /// Clear all current data
    func reset() {
        extractedRecipe = nil
        selectedImage = nil
        processedImage = nil
        errorMessage = nil
        isLoading = false
        recipeURL = ""
        extractedImageURLs = []
    }
    
    /// Toggle preprocessing and re-extract if image is available
    func togglePreprocessing() async {
        usePreprocessing.toggle()
        
        if let image = selectedImage {
            await extractRecipe(from: image)
        }
    }
}
