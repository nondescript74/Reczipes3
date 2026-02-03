//
//  RecipeBookUTType.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 1/22/26.
//

import UniformTypeIdentifiers

extension UTType {
    /// Custom UTType for recipe book export files
    static let recipeBook = UTType(exportedAs: "com.headydiscy.reczipes.recipebook",
                                       conformingTo: .data)
}

/// Package manifest for exported recipe books
struct RecipeBookPackageType {
    static let fileExtension = "recipebook"
    static let mimeType = "application/x-recipebook"
    
    /// User-friendly description of the file type
    static let typeDescription = "Recipe Book Package"
    
    /// Icon representation (SF Symbol)
    static let iconName = "books.vertical.fill"
}
