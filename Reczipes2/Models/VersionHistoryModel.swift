//
//  VersionHistoryModel.swift
//  Reczipes2
//
//  Created on 02/01/26.
//

import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
final class VersionHistoryRecord {
    // CloudKit requires: no unique constraints, and all attributes must have a default value
    var id: UUID = UUID()
    
    // CloudKit requires: all properties must be optional OR have default values
    var version: String = ""
    var buildNumber: String = ""
    var releaseDate: Date = Date()
    var changesJSON: String = "[]" // Store changes as JSON string
    var versionString: String = "" // Computed property stored for querying
    
    init(version: String, buildNumber: String, releaseDate: Date, changes: [String]) {
        self.id = UUID()
        self.version = version
        self.buildNumber = buildNumber
        self.releaseDate = releaseDate
        self.versionString = "\(version) (\(buildNumber))"
        
        // Encode changes as JSON
        if let jsonData = try? JSONEncoder().encode(changes),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            self.changesJSON = jsonString
        } else {
            self.changesJSON = "[]"
        }
    }
    
    // Decode changes from JSON
    var changes: [String] {
        guard let jsonData = changesJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: jsonData) else {
            return []
        }
        return decoded
    }
    
    // Convert to the original struct for compatibility
    @MainActor func toVersionHistoryEntry() -> VersionHistoryEntry {
        VersionHistoryEntry(
            version: version,
            buildNumber: buildNumber,
            releaseDate: releaseDate,
            changes: changes
        )
    }
}

// MARK: - Original Struct (for compatibility)

struct VersionHistoryEntry: Codable, Identifiable {
    let id: UUID
    let version: String
    let buildNumber: String
    let releaseDate: Date
    let changes: [String]
    
    init(version: String, buildNumber: String, releaseDate: Date = Date(), changes: [String]) {
        self.id = UUID()
        self.version = version
        self.buildNumber = buildNumber
        self.releaseDate = releaseDate
        self.changes = changes
    }
    
    var versionString: String {
        "\(version) (\(buildNumber))"
    }
}
