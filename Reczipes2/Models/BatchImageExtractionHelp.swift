//
//  BatchImageExtractionHelp.swift
//  Reczipes2
//
//  Help topic for Batch Image Extraction feature
//  Add this to ContextualHelp.swift
//

import SwiftUI

// MARK: - Batch Image Extraction Help Topic

extension AppHelp {
    
    static let batchImageExtraction = HelpTopic(
        title: "Batch Image Extraction",
        icon: "photo.stack.fill",
        description: """
        Extract multiple recipes at once from images in your Photos library. Perfect for digitizing recipe collections quickly - process up to 10 images at a time with optional cropping.
        """,
        tips: [
            "Tap 'Batch Extract Images' from the Extract tab",
            "Select multiple recipe photos from your library",
            "Toggle 'Crop each image' ON to adjust each photo individually, or OFF for fastest processing",
            "The app processes images in batches of 10 with progress updates",
            "You can pause, resume, or stop extraction at any time",
            "Each extraction takes 10-30 seconds per image",
            "All successfully extracted recipes are automatically saved",
            "Review the error log if any images fail to extract",
            "Start with 3-5 images to learn the workflow before processing larger batches"
        ],
        relatedTopics: ["Recipe Extraction", "Image Preprocessing", "Claude API", "Photos Library"]
    )
    
}

// MARK: - Integration Instructions

/*
 To add this to your app:
 
 1. Open ContextualHelp.swift
 
 2. Add after the existing help topics (around line 250-300):
 
    static let batchImageExtraction = HelpTopic(
        title: "Batch Image Extraction",
        icon: "photo.stack.fill",
        description: """
        Extract multiple recipes at once from images in your Photos library. Perfect for digitizing recipe collections quickly - process up to 10 images at a time with optional cropping.
        """,
        tips: [
            "Tap 'Batch Extract Images' from the Extract tab",
            "Select multiple recipe photos from your library",
            "Toggle 'Crop each image' ON to adjust each photo individually, or OFF for fastest processing",
            "The app processes images in batches of 10 with progress updates",
            "You can pause, resume, or stop extraction at any time",
            "Each extraction takes 10-30 seconds per image",
            "All successfully extracted recipes are automatically saved",
            "Review the error log if any images fail to extract",
            "Start with 3-5 images to learn the workflow before processing larger batches"
        ],
        relatedTopics: ["Recipe Extraction", "Image Preprocessing", "Claude API", "Photos Library"]
    )
 
 3. Add to the category in HelpCategory (likely under "Extraction" or "Images" category):
 
    .batchImageExtraction
 
 4. Update HELP_TOPICS_QUICK_REFERENCE.md to include:
 
    ### 19. Batch Image Extraction 📚
    **What:** Extract multiple recipes at once  
    **When to use:** Digitizing recipe collections, processing many photos  
    **Key tips:**
    - Process up to 10 images at a time
    - Optional cropping for each image
    - Pause/resume/stop controls
    - Start small (3-5 images) to learn
 
 5. Add help button to BatchImageExtractorView.swift toolbar:
 
    ToolbarItem(placement: .primaryAction) {
        Button {
            showingHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
        }
    }
    
    .sheet(isPresented: $showingHelp) {
        HelpDetailView(topic: .batchImageExtraction)
    }
 
 */
