//
//  RecipeBookExportModel.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import Foundation

/// Represents a complete recipe book package for export/import
struct RecipeBookExportPackage: Codable {
    var version: String = "2.0"
    let exportDate: Date
    let book: ExportableRecipeBook
    let recipes: [RecipeModel]
    let imageManifest: [ImageManifestEntry]
    
    init(exportDate: Date = Date(),
         book: ExportableRecipeBook,
         recipes: [RecipeModel],
         imageManifest: [ImageManifestEntry] = []) {
        self.exportDate = exportDate
        self.book = book
        self.recipes = recipes
        self.imageManifest = imageManifest
    }
}

/// Exportable version of RecipeBook (without SwiftData decorators)
struct ExportableRecipeBook: Codable {
    let id: UUID
    let name: String
    let bookDescription: String?
    let coverImageName: String?
    let dateCreated: Date
    let dateModified: Date
    let recipeIDs: [UUID]
    let color: String?
    
    init(from book: RecipeBook) {
        self.id = book.id
        self.name = book.name
        self.bookDescription = book.bookDescription
        self.coverImageName = book.coverImageName
        self.dateCreated = book.dateCreated
        self.dateModified = book.dateModified
        self.recipeIDs = book.recipeIDs
        self.color = book.color
    }
    
    init(id: UUID,
         name: String,
         bookDescription: String?,
         coverImageName: String?,
         dateCreated: Date,
         dateModified: Date,
         recipeIDs: [UUID],
         color: String?) {
        self.id = id
        self.name = name
        self.bookDescription = bookDescription
        self.coverImageName = coverImageName
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.recipeIDs = recipeIDs
        self.color = color
    }
}

/// Tracks images included in the export
struct ImageManifestEntry: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let type: ImageType
    let associatedID: UUID // Either book ID or recipe ID
    
    enum ImageType: String, Codable {
        case bookCover
        case recipePrimary
        case recipeAdditional
    }
    
    init(id: UUID = UUID(),
         fileName: String,
         type: ImageType,
         associatedID: UUID) {
        self.id = id
        self.fileName = fileName
        self.type = type
        self.associatedID = associatedID
    }
}
