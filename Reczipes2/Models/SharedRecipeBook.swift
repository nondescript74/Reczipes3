//
//  SharedRecipeBook.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 1/20/26.
//


import Foundation
import SwiftData
import CloudKit
import SwiftUI

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