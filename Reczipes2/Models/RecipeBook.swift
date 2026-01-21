//
//  RecipeBook.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import Foundation
import SwiftData
import SwiftUI


@Model
final class RecipeBook {
    var id: UUID = UUID()
    var name: String = ""
    var bookDescription: String?
    var coverImageName: String? // Legacy field for reference, prefer coverImageData
    var coverImageData: Data? // Cover image stored in SwiftData
    var dateCreated: Date = Date()
    var dateModified: Date = Date()
    var recipeIDs: [UUID] = [] // Ordered list of recipe IDs in this book
    var color: String? // Optional color theme for the book (hex string)
    
    init(id: UUID = UUID(),
         name: String,
         bookDescription: String? = nil,
         coverImageName: String? = nil,
         coverImageData: Data? = nil,
         dateCreated: Date = Date(),
         dateModified: Date = Date(),
         recipeIDs: [UUID] = [],
         color: String? = nil) {
        self.id = id
        self.name = name
        self.bookDescription = bookDescription
        self.coverImageName = coverImageName
        self.coverImageData = coverImageData
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.recipeIDs = recipeIDs
        self.color = color
    }
    
    var recipeCount: Int {
        recipeIDs.count
    }
    
    // Helper to add a recipe
    func addRecipe(_ recipeID: UUID) {
        if !recipeIDs.contains(recipeID) {
            recipeIDs.append(recipeID)
            dateModified = Date()
        }
    }
    
    // Helper to remove a recipe
    func removeRecipe(_ recipeID: UUID) {
        recipeIDs.removeAll { $0 == recipeID }
        dateModified = Date()
    }
    
    // Helper to reorder recipes
    func moveRecipe(from source: IndexSet, to destination: Int) {
        recipeIDs.move(fromOffsets: source, toOffset: destination)
        dateModified = Date()
    }
}
