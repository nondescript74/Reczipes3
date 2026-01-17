//
//  ContentFilterMode.swift
//  Reczipes2
//
//  Created on 1/17/26.
//

import Foundation

/// Enum representing the three content filter modes for recipes and books
enum ContentFilterMode: String, CaseIterable, Identifiable {
    case mine = "Mine"
    case shared = "Shared"
    case all = "All"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .mine:
            return "person.fill"
        case .shared:
            return "person.2.fill"
        case .all:
            return "person.3.fill"
        }
    }
    
    var description: String {
        switch self {
        case .mine:
            return "My Content"
        case .shared:
            return "Shared by Others"
        case .all:
            return "All Content"
        }
    }
}
