//
//  SharingPreferences.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 1/20/26.
//


import Foundation
import SwiftData
import CloudKit
import SwiftUI


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