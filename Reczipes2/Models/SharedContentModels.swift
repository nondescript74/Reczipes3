//
//  SharedContentModels.swift
//  Reczipes2
//
//  Created on 1/15/26.
//

import Foundation
import SwiftData
import CloudKit
import SwiftUI

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
struct CloudKitRecipe: Codable, Identifiable {
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
struct CloudKitRecipeBook: Codable, Identifiable {
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

enum SharingError: LocalizedError, Equatable {
    case notAuthenticated
    case cloudKitUnavailable(message: String? = nil)
    case recipeNotFound
    case bookNotFound
    case uploadFailed(Error)
    case downloadFailed(Error)
    case invalidData
    case imageUploadFailed(Error)
    
    static func == (lhs: SharingError, rhs: SharingError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthenticated, .notAuthenticated),
             (.recipeNotFound, .recipeNotFound),
             (.bookNotFound, .bookNotFound),
             (.invalidData, .invalidData):
            return true
        case (.cloudKitUnavailable(let lhsMsg), .cloudKitUnavailable(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
    
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

// MARK: - CloudKit Manager Data Structures

/// Status of a recipe in CloudKit
struct CloudKitRecipeStatus: Identifiable {
    let id = UUID()
    let recipe: CloudKitRecipe
    let cloudRecordID: String
    let sharedDate: Date
    let localTrackingRecord: SharedRecipe?
    
    var isTracked: Bool {
        localTrackingRecord != nil
    }
    
    var isOrphaned: Bool {
        !isTracked
    }
    
    var statusIcon: String {
        isTracked ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }
    
    var statusColor: Color {
        isTracked ? .green : .orange
    }
    
    var statusDescription: String {
        isTracked ? "Tracked" : "Orphaned (not tracked locally)"
    }
}

/// Data for CloudKit Recipe Manager View
struct CloudKitRecipeManagerData {
    let recipes: [CloudKitRecipeStatus]
    
    var trackedRecipes: [CloudKitRecipeStatus] {
        recipes.filter { $0.isTracked }
    }
    
    var orphanedRecipes: [CloudKitRecipeStatus] {
        recipes.filter { $0.isOrphaned }
    }
    
    var trackedCount: Int {
        trackedRecipes.count
    }
    
    var orphanedCount: Int {
        orphanedRecipes.count
    }
    
    var totalCount: Int {
        recipes.count
    }
}

/// Status of a recipe book in CloudKit
struct CloudKitRecipeBookStatus: Identifiable {
    let id = UUID()
    let book: CloudKitRecipeBook
    let cloudRecordID: String
    let sharedDate: Date
    let localTrackingRecord: SharedRecipeBook?
    
    var isTracked: Bool {
        localTrackingRecord != nil
    }
    
    var isOrphaned: Bool {
        !isTracked
    }
    
    var statusIcon: String {
        isTracked ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }
    
    var statusColor: Color {
        isTracked ? .green : .orange
    }
    
    var statusDescription: String {
        isTracked ? "Tracked" : "Orphaned (not tracked locally)"
    }
}

/// Data for CloudKit Recipe Book Manager View
struct CloudKitRecipeBookManagerData {
    let books: [CloudKitRecipeBookStatus]
    
    var trackedBooks: [CloudKitRecipeBookStatus] {
        books.filter { $0.isTracked }
    }
    
    var orphanedBooks: [CloudKitRecipeBookStatus] {
        books.filter { $0.isOrphaned }
    }
    
    var trackedCount: Int {
        trackedBooks.count
    }
    
    var orphanedCount: Int {
        orphanedBooks.count
    }
    
    var totalCount: Int {
        books.count
    }
}

