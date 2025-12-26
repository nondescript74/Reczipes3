//
//  SavedLink.swift
//  Reczipes2
//
//  Created for importing saved recipe links
//

import Foundation
import SwiftData

@Model
final class SavedLink {
    var id: UUID
    var title: String
    var url: String
    var dateAdded: Date
    var isProcessed: Bool // Whether the recipe has been extracted from this link
    var extractedRecipeID: UUID? // ID of the recipe extracted from this link
    var processingError: String? // Error message if extraction failed
    
    init(id: UUID = UUID(),
         title: String,
         url: String,
         dateAdded: Date = Date(),
         isProcessed: Bool = false,
         extractedRecipeID: UUID? = nil,
         processingError: String? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.dateAdded = dateAdded
        self.isProcessed = isProcessed
        self.extractedRecipeID = extractedRecipeID
        self.processingError = processingError
    }
}

// MARK: - Decodable for JSON Import

extension SavedLink {
    /// Convenience initializer from JSON structure
    convenience init(from jsonLink: JSONLink) {
        self.init(
            title: jsonLink.title,
            url: jsonLink.url,
            dateAdded: Date(),
            isProcessed: false
        )
    }
}

// MARK: - JSON Structure

struct JSONLink: Codable {
    let title: String
    let url: String
}
