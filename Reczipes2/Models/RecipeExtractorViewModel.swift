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
    @Published var extractedRecipe: RecipeModel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var usePreprocessing = true
    @Published var recipeURL: String = ""
    
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
    
    private func saveRecipeDirectly(_ recipeModel: RecipeModel, modelContext: ModelContext) {
        let recipe = Recipe(from: recipeModel)
        
        // Generate and store image hash
        if let image = selectedImage,
           let hash = imageHashService.generateHash(for: image) {
            recipe.imageHash = hash
        }
        
        recipe.extractionSource = "camera" // or "photos" or "files"
        
        // ... rest of save logic ...
        
        modelContext.insert(recipe)
        try? modelContext.save()
    }
    
    func handleKeepBoth(modelContext: ModelContext) {
        guard let recipe = extractedRecipe else { return }
        
        // Create a new RecipeModel with modified title
        let modifiedRecipe = RecipeModel(
            id: recipe.id,
            title: "\(recipe.title) (2)",
            headerNotes: recipe.headerNotes,
            yield: recipe.yield,
            ingredientSections: recipe.ingredientSections,
            instructionSections: recipe.instructionSections,
            notes: recipe.notes,
            reference: recipe.reference,
            imageName: recipe.imageName,
            additionalImageNames: recipe.additionalImageNames,
            imageURLs: recipe.imageURLs
        )
        
        saveRecipeDirectly(modifiedRecipe, modelContext: modelContext)
    }
    
    func handleReplaceOriginal(modelContext: ModelContext) {
        guard let newRecipe = extractedRecipe,
              let match = duplicateMatch else { return }
        
        let existingRecipe = match.existingRecipe
        let encoder = JSONEncoder()
        
        // Update existing recipe with new data
        existingRecipe.title = newRecipe.title
        existingRecipe.headerNotes = newRecipe.headerNotes
        existingRecipe.recipeYield = newRecipe.yield
        existingRecipe.reference = newRecipe.reference
        
        // Encode and update ingredient sections
        if let ingredientsData = try? encoder.encode(newRecipe.ingredientSections) {
            existingRecipe.ingredientSectionsData = ingredientsData
        }
        
        // Encode and update instruction sections
        if let instructionsData = try? encoder.encode(newRecipe.instructionSections) {
            existingRecipe.instructionSectionsData = instructionsData
        }
        
        // Encode and update notes
        if let notesData = try? encoder.encode(newRecipe.notes) {
            existingRecipe.notesData = notesData
        }
        
        // Update version tracking
        existingRecipe.lastModified = Date()
        existingRecipe.version = (existingRecipe.version ?? 1) + 1
        existingRecipe.ingredientsHash = Recipe.calculateIngredientsHash(from: existingRecipe.ingredientSectionsData)
        
        try? modelContext.save()
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
            var recipe = try await apiClient.extractRecipe(from: contentToSend)
            
            // Add the source URL to the reference field
            if recipe.reference == nil || recipe.reference?.isEmpty == true {
                recipe = RecipeModel(
                    id: recipe.id,
                    title: recipe.title,
                    headerNotes: recipe.headerNotes,
                    yield: recipe.yield,
                    ingredientSections: recipe.ingredientSections,
                    instructionSections: recipe.instructionSections,
                    notes: recipe.notes,
                    reference: url,
                    imageName: recipe.imageName,
                    imageURLs: imageURLs.isEmpty ? nil : imageURLs
                )
            } else {
                // Just add image URLs to existing recipe
                recipe = RecipeModel(
                    id: recipe.id,
                    title: recipe.title,
                    headerNotes: recipe.headerNotes,
                    yield: recipe.yield,
                    ingredientSections: recipe.ingredientSections,
                    instructionSections: recipe.instructionSections,
                    notes: recipe.notes,
                    reference: recipe.reference,
                    imageName: recipe.imageName,
                    imageURLs: imageURLs.isEmpty ? nil : imageURLs
                )
            }
            
            await MainActor.run {
                self.extractedRecipe = recipe
                logInfo("URL extraction successful: \(recipe.title)", category: "extraction")
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
            // Reduce image size to 500KB max before sending to Claude
            logInfo("Reducing image size before sending to Claude...", category: "extraction")
            guard let imageData = imagePreprocessor.reduceImageSize(image, maxSizeBytes: 500_000) else {
                throw ClaudeAPIError.invalidResponse
            }
            logInfo("Image size after reduction: \(imageData.count) bytes", category: "extraction")
            
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
    }
    
    /// Toggle preprocessing and re-extract if image is available
    func togglePreprocessing() async {
        usePreprocessing.toggle()
        
        if let image = selectedImage {
            await extractRecipe(from: image)
        }
    }
}
