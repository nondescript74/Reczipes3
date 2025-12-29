//
//  RecipeImageAssignment.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import Foundation
import SwiftData

@Model
final class RecipeImageAssignment {
    var recipeID: UUID = UUID()
    var imageName: String = ""
    
    init(recipeID: UUID, imageName: String) {
        self.recipeID = recipeID
        self.imageName = imageName
    }
}
