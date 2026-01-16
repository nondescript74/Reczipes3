//
//  SharedContentModels.swift
//  Reczipes2
//
//  Created on 1/15/26.
//

import Foundation
import SwiftData
import CloudKit

// MARK: - Shared Content Tracking

/// Tracks which recipes a user has shared to the public CloudKit database
@Model
final class SharedRecipe {
    var id: UUID = UUID()
    var recipeID: UUID? // ID of the local recipe (optional for CloudKit)
    var cloudRecordID: String? // CloudKit record ID in public database
    var sharedByUserID: String? // User who shared it (CKRecord.ID) (optional for CloudKit)
    var sharedByUserName: String? // Display name of user who shared
    var sharedDate: Date = Date()
    var isActive: Bool = true // User can deactivate sharing
    
    // Cached recipe data (for quick display without fetching from public DB)
    var recipeTitle: String = ""
    var recipeImageName: String?
    
    init(recipeID: UUID,
         cloudRecordID: String? = nil,
         sharedByUserID: String,
         sharedByUserName: String? = nil,
         sharedDate: Date = Date(),
         recipeTitle: String = "",
         recipeImageName: String? = nil) {
        self.recipeID = recipeID
        self.cloudRecordID = cloudRecordID
        self.sharedByUserID = sharedByUserID
        self.sharedByUserName = sharedByUserName
        self.sharedDate = sharedDate
        self.recipeTitle = recipeTitle
        self.recipeImageName = recipeImageName
    }
}

/// Tracks which recipe books a user has shared
@Model
final class SharedRecipeBook {
    var id: UUID = UUID()
    var bookID: UUID? // ID of the local book (optional for CloudKit)
    var cloudRecordID: String? // CloudKit record ID in public database
    var sharedByUserID: String? // User who shared it (optional for CloudKit)
    var sharedByUserName: String?
    var sharedDate: Date = Date()
    var isActive: Bool = true
    
    // Cached book data
    var bookName: String = ""
    var bookDescription: String?
    var coverImageName: String?
    
    init(bookID: UUID,
         cloudRecordID: String? = nil,
         sharedByUserID: String,
         sharedByUserName: String? = nil,
         sharedDate: Date = Date(),
         bookName: String = "",
         bookDescription: String? = nil,
         coverImageName: String? = nil) {
        self.bookID = bookID
        self.cloudRecordID = cloudRecordID
        self.sharedByUserID = sharedByUserID
        self.sharedByUserName = sharedByUserName
        self.sharedDate = sharedDate
        self.bookName = bookName
        self.bookDescription = bookDescription
        self.coverImageName = coverImageName
    }
}

// MARK: - Sharing Preferences

/// User's sharing preferences
@Model
final class SharingPreferences {
    var id: UUID = UUID()
    var shareAllRecipes: Bool = false
    var shareAllBooks: Bool = false
    var allowOthersToSeeMyName: Bool = true
    var displayName: String?
    var dateModified: Date = Date()
    
    init(shareAllRecipes: Bool = false,
         shareAllBooks: Bool = false,
         allowOthersToSeeMyName: Bool = true,
         displayName: String? = nil) {
        self.shareAllRecipes = shareAllRecipes
        self.shareAllBooks = shareAllBooks
        self.allowOthersToSeeMyName = allowOthersToSeeMyName
        self.displayName = displayName
    }
}

// MARK: - CloudKit Record Type Names

enum CloudKitRecordType {
    static let sharedRecipe = "SharedRecipe"
    static let sharedRecipeBook = "SharedRecipeBook"
    static let sharedImage = "SharedImage"
}

// MARK: - Codable Representations for CloudKit

/// CloudKit-friendly representation of a recipe for sharing
struct CloudKitRecipe: Codable {
    let id: UUID
    let title: String
    let headerNotes: String?
    let yield: String?
    let ingredientSections: [IngredientSection]
    let instructionSections: [InstructionSection]
    let notes: [RecipeNote]
    let reference: String?
    let imageName: String?
    let additionalImageNames: [String]?
    
    // Sharing metadata
    let sharedByUserID: String
    let sharedByUserName: String?
    let sharedDate: Date
}

/// CloudKit-friendly representation of a recipe book for sharing
struct CloudKitRecipeBook: Codable {
    let id: UUID
    let name: String
    let bookDescription: String?
    let coverImageName: String?
    let recipeIDs: [UUID]
    let color: String?
    
    // Sharing metadata
    let sharedByUserID: String
    let sharedByUserName: String?
    let sharedDate: Date
}

// MARK: - Sharing Result

enum SharingResult {
    case success(recordID: String)
    case failure(error: Error)
    case partialSuccess(successful: Int, failed: Int)
}

// MARK: - Sharing Error

enum SharingError: LocalizedError {
    case notAuthenticated
    case cloudKitUnavailable(message: String? = nil)
    case recipeNotFound
    case bookNotFound
    case uploadFailed(Error)
    case downloadFailed(Error)
    case invalidData
    case imageUploadFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to iCloud to share content."
        case .cloudKitUnavailable(let message):
            return message ?? "CloudKit is not available. Check your iCloud settings."
        case .recipeNotFound:
            return "The recipe you're trying to share was not found."
        case .bookNotFound:
            return "The recipe book you're trying to share was not found."
        case .uploadFailed(let error):
            return "Failed to upload: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Failed to download: \(error.localizedDescription)"
        case .invalidData:
            return "The shared content contains invalid data."
        case .imageUploadFailed(let error):
            return "Failed to upload image: \(error.localizedDescription)"
        }
    }
    
    var canOpenOnboarding: Bool {
        switch self {
        case .cloudKitUnavailable, .notAuthenticated:
            return true
        default:
            return false
        }
    }
}
