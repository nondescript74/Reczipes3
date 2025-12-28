//
//  RecipeFilterMode.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import Foundation

/// Defines the four filtering modes for recipes
enum RecipeFilterMode: String, CaseIterable, Identifiable {
    case none = "None"
    case allergenFODMAP = "Allergen + FODMAP"
    case diabetes = "Diabetes"
    case all = "Allergen + FODMAP + Diabetes"
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .none:
            return "line.3.horizontal.decrease.circle"
        case .allergenFODMAP:
            return "exclamationmark.triangle.fill"
        case .diabetes:
            return "heart.text.square.fill"
        case .all:
            return "shield.lefthalf.filled"
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "Show all recipes without filtering"
        case .allergenFODMAP:
            return "Filter based on allergens and FODMAP sensitivities"
        case .diabetes:
            return "Filter for diabetes-friendly recipes (low sugar, complex carbs)"
        case .all:
            return "Apply all filters: allergens, FODMAP, and diabetes"
        }
    }
    
    /// Whether this mode includes allergen/FODMAP filtering
    var includesAllergenFilter: Bool {
        switch self {
        case .none, .diabetes:
            return false
        case .allergenFODMAP, .all:
            return true
        }
    }
    
    /// Whether this mode includes diabetes filtering
    var includesDiabetesFilter: Bool {
        switch self {
        case .none, .allergenFODMAP:
            return false
        case .diabetes, .all:
            return true
        }
    }
}
