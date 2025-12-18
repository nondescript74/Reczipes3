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
    
    private let apiClient: ClaudeAPIClient
    private let imagePreprocessor = ImagePreprocessor()
    
    init(apiKey: String) {
        self.apiClient = ClaudeAPIClient(apiKey: apiKey)
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
    }
    
    /// Toggle preprocessing and re-extract if image is available
    func togglePreprocessing() async {
        usePreprocessing.toggle()
        
        if let image = selectedImage {
            await extractRecipe(from: image)
        }
    }
}
