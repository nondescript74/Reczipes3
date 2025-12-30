//
//  RecipeExtractorViewModel.swift
//  Reczipes2
//
//  Created for Claude-powered recipe extraction
//

import SwiftUI
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
            if cleanedContent.count > 100_000 {
                logWarning("Content too large (\(cleanedContent.count) chars), truncating to 100k characters", category: "extraction")
                contentToSend = String(cleanedContent.prefix(100_000))
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
            guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                throw ClaudeAPIError.invalidResponse
            }
            
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
