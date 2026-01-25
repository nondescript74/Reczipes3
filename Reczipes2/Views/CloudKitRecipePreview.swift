//
//  CloudKitRecipePreview.swift
//  Reczipes2
//
//  Created on 1/25/26.
//

import Foundation
import SwiftData

/// Lightweight preview of a shared recipe for display in book lists
/// Contains just enough data to show in a recipe list without downloading the full recipe
@Model
final class CloudKitRecipePreview {
    // CloudKit requires: all attributes must be optional OR have default values
    var id: UUID = UUID()
    var title: String = ""
    var headerNotes: String?
    var imageName: String?
    var imageData: Data?  // Thumbnail stored locally
    var sharedByUserID: String = ""
    var sharedByUserName: String?
    var recipeYield: String?
    
    // Reference to the book this preview belongs to
    var bookID: UUID?
    
    // CloudKit record ID for fetching full recipe later
    var cloudRecordID: String?
    
    // Cache metadata
    var previewCachedDate: Date = Date()
    var lastAccessedDate: Date = Date()
    
    init(
        id: UUID,
        title: String,
        headerNotes: String? = nil,
        imageName: String? = nil,
        imageData: Data? = nil,
        sharedByUserID: String,
        sharedByUserName: String? = nil,
        recipeYield: String? = nil,
        bookID: UUID? = nil,
        cloudRecordID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.headerNotes = headerNotes
        self.imageName = imageName
        self.imageData = imageData
        self.sharedByUserID = sharedByUserID
        self.sharedByUserName = sharedByUserName
        self.recipeYield = recipeYield
        self.bookID = bookID
        self.cloudRecordID = cloudRecordID
        self.previewCachedDate = Date()
        self.lastAccessedDate = Date()
    }
    
    /// Create preview from a full CloudKitRecipe
    convenience init(from cloudRecipe: CloudKitRecipe, bookID: UUID?, cloudRecordID: String?) {
        self.init(
            id: cloudRecipe.id,
            title: cloudRecipe.title,
            headerNotes: cloudRecipe.headerNotes,
            imageName: cloudRecipe.imageName,
            sharedByUserID: cloudRecipe.sharedByUserID,
            sharedByUserName: cloudRecipe.sharedByUserName,
            recipeYield: cloudRecipe.yield,
            bookID: bookID,
            cloudRecordID: cloudRecordID
        )
    }
}

/// Extends CloudKitRecipeBook to include recipe previews
struct CloudKitRecipeBookWithPreviews: Codable, Identifiable {
    let id: UUID
    let name: String
    let bookDescription: String?
    let coverImageName: String?
    let recipeIDs: [UUID]
    let recipePreviews: [RecipePreviewData]  // NEW: Lightweight recipe data
    let color: String?
    let sharedByUserID: String
    let sharedByUserName: String?
    let sharedDate: Date
}

/// Lightweight recipe data for previews (stored in JSON)
struct RecipePreviewData: Codable, Identifiable {
    let id: UUID
    let title: String
    let headerNotes: String?
    let imageName: String?
    let recipeYield: String?
    let cloudRecordID: String?  // For fetching full recipe later
    let thumbnailBase64: String?  // Small thumbnail encoded as base64
}
