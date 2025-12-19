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
        isLoading = true
        errorMessage = nil
        extractedRecipe = nil
        selectedImage = nil // Clear image when extracting from URL
        processedImage = nil
        
        do {
            // Fetch web content
            let htmlContent = try await webExtractor.fetchWebContent(from: url)
            
            // Extract image URLs BEFORE cleaning (to preserve all HTML)
            let imageURLs = webExtractor.extractImageURLs(from: htmlContent)
            print("🖼️ Found \(imageURLs.count) image URL(s) in webpage")
            
            // Clean the HTML
            let cleanedContent = webExtractor.cleanHTML(htmlContent)
            
            // Limit content size to avoid token limits (approximately 100k characters)
            let contentToSend: String
            if cleanedContent.count > 100_000 {
                print("⚠️ Content too large, truncating to 100k characters")
                contentToSend = String(cleanedContent.prefix(100_000))
            } else {
                contentToSend = cleanedContent
            }
            
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
            
            self.extractedRecipe = recipe
        } catch let error as WebExtractionError {
            self.errorMessage = error.errorDescription
        } catch let error as ClaudeAPIError {
            self.errorMessage = error.errorDescription
        } catch {
            self.errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Extract recipe from the selected image
    func extractRecipe(from image: UIImage) async {
        isLoading = true
        errorMessage = nil
        selectedImage = image
        
        // Generate processed preview if preprocessing is enabled
        if usePreprocessing {
            if let processedData = imagePreprocessor.preprocessForOCR(image),
               let processedUIImage = UIImage(data: processedData) {
                processedImage = processedUIImage
            }
        } else {
            processedImage = nil
        }
        
        do {
            guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                throw ClaudeAPIError.invalidResponse
            }
            
            let recipe = try await apiClient.extractRecipe(
                from: imageData,
                usePreprocessing: usePreprocessing
            )
            
            self.extractedRecipe = recipe
        } catch let error as ClaudeAPIError {
            self.errorMessage = error.errorDescription
        } catch {
            self.errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        
        isLoading = false
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
