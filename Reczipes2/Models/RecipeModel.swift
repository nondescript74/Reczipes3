//
//  RecipeModel.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import Foundation

struct RecipeModel: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let headerNotes: String?
    let yield: String?
    let ingredientSections: [IngredientSection]
    let instructionSections: [InstructionSection]
    let notes: [RecipeNote]
    let reference: String?
    
    init(id: UUID = UUID(),
         title: String,
         headerNotes: String? = nil,
         yield: String? = nil,
         ingredientSections: [IngredientSection],
         instructionSections: [InstructionSection],
         notes: [RecipeNote] = [],
         reference: String? = nil) {
        self.id = id
        self.title = title
        self.headerNotes = headerNotes
        self.yield = yield
        self.ingredientSections = ingredientSections
        self.instructionSections = instructionSections
        self.notes = notes
        self.reference = reference
    }
}

struct IngredientSection: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String?
    let ingredients: [Ingredient]
    let transitionNote: String?
    
    init(id: UUID = UUID(),
         title: String? = nil,
         ingredients: [Ingredient],
         transitionNote: String? = nil) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.transitionNote = transitionNote
    }
}

struct Ingredient: Codable, Identifiable, Hashable {
    let id: UUID
    let quantity: String
    let unit: String
    let name: String
    let preparation: String?
    let metricQuantity: String?
    let metricUnit: String?
    
    init(id: UUID = UUID(),
         quantity: String,
         unit: String,
         name: String,
         preparation: String? = nil,
         metricQuantity: String? = nil,
         metricUnit: String? = nil) {
        self.id = id
        self.quantity = quantity
        self.unit = unit
        self.name = name
        self.preparation = preparation
        self.metricQuantity = metricQuantity
        self.metricUnit = metricUnit
    }
}

struct InstructionSection: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String?
    let steps: [InstructionStep]
    
    init(id: UUID = UUID(),
         title: String? = nil,
         steps: [InstructionStep]) {
        self.id = id
        self.title = title
        self.steps = steps
    }
}

struct InstructionStep: Codable, Identifiable, Hashable {
    let id: UUID
    let stepNumber: Int?
    let text: String
    
    init(id: UUID = UUID(),
         stepNumber: Int? = nil,
         text: String) {
        self.id = id
        self.stepNumber = stepNumber
        self.text = text
    }
}

struct RecipeNote: Codable, Identifiable, Hashable {
    let id: UUID
    let type: NoteType
    let text: String
    
    init(id: UUID = UUID(),
         type: NoteType,
         text: String) {
        self.id = id
        self.type = type
        self.text = text
    }
    
    enum NoteType: String, Codable {
        case tip
        case substitution
        case warning
        case timing
        case general
    }
}
