//
//  UserAllergenProfile.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/18/25.
//  Schema Version: 2.0.0 - Added diabetes status support
//

import Foundation
import SwiftData

// MARK: - Diabetes Status

enum DiabetesStatus: String, Codable, CaseIterable {
    case none = "None"
    case prediabetic = "Prediabetic"
    case diabetic = "Diabetic"
    
    var icon: String {
        switch self {
        case .none: return ""
        case .prediabetic: return "⚠️"
        case .diabetic: return "🩸"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "No diabetes concerns"
        case .prediabetic: return "Monitor blood sugar levels"
        case .diabetic: return "Requires blood sugar management"
        }
    }
}

// MARK: - User Profile (SwiftData Model)
// Schema Version: 2.0.0

@Model
final class UserAllergenProfile {
    var id: UUID = UUID()
    var name: String = ""
    var isActive: Bool = false
    var sensitivitiesData: Data?
    
    // Added in Schema V2.0.0
    // Default value ensures automatic migration works without deleting the app
    var diabetesStatusRaw: String = DiabetesStatus.none.rawValue
    
    var dateCreated: Date = Date()
    var dateModified: Date = Date()
    
    init(id: UUID = UUID(),
         name: String,
         isActive: Bool = false,
         sensitivitiesData: Data? = nil,
         diabetesStatus: DiabetesStatus = .none,
         dateCreated: Date = Date(),
         dateModified: Date = Date()) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.sensitivitiesData = sensitivitiesData
        self.diabetesStatusRaw = diabetesStatus.rawValue
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
    
    // Computed property for diabetes status
    var diabetesStatus: DiabetesStatus {
        get {
            DiabetesStatus(rawValue: diabetesStatusRaw) ?? .none
        }
        set {
            diabetesStatusRaw = newValue.rawValue
            dateModified = Date()
        }
    }
    
    // Convenience property to check if diabetes filtering is needed
    var hasDiabetesConcern: Bool {
        diabetesStatus != .none
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
