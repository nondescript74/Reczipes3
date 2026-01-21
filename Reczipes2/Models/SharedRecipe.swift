//
//  SharedRecipe.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 1/20/26.
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