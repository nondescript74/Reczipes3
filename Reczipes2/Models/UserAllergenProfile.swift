//
//  UserAllergenProfile.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/18/25.
//

import Foundation
import SwiftData

// MARK: - User Profile (SwiftData Model)

@Model
final class UserAllergenProfile {
    var id: UUID
    var name: String
    var isActive: Bool
    var sensitivitiesData: Data?
    var dateCreated: Date
    var dateModified: Date
    
    init(id: UUID = UUID(),
         name: String,
         isActive: Bool = false,
         sensitivitiesData: Data? = nil,
         dateCreated: Date = Date(),
         dateModified: Date = Date()) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.sensitivitiesData = sensitivitiesData
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
    
    // Computed property to get sensitivities
    var sensitivities: [UserSensitivity] {
        get {
            guard let data = sensitivitiesData else { return [] }
            return (try? JSONDecoder().decode([UserSensitivity].self, from: data)) ?? []
        }
        set {
            sensitivitiesData = try? JSONEncoder().encode(newValue)
            dateModified = Date()
        }
    }
    
    // Add a sensitivity
    func addSensitivity(_ sensitivity: UserSensitivity) {
        var current = sensitivities
        current.append(sensitivity)
        sensitivities = current
    }
    
    // Remove a sensitivity
    func removeSensitivity(id: UUID) {
        var current = sensitivities
        current.removeAll { $0.id == id }
        sensitivities = current
    }
    
    // Update a sensitivity
    func updateSensitivity(_ sensitivity: UserSensitivity) {
        var current = sensitivities
        if let index = current.firstIndex(where: { $0.id == sensitivity.id }) {
            current[index] = sensitivity
            sensitivities = current
        }
    }
}
