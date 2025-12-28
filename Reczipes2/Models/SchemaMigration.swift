//
//  SchemaMigration.swift
//  Reczipes2
//
//  SwiftData schema versioning and migration
//  Created by Zahirudeen Premji on 12/28/25.
//

import Foundation
import SwiftData

// MARK: - Schema Version 1 (Original)

/// Original schema before diabetes status was added
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            UserAllergenProfile.self,
        ]
    }
    
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
    }
}

// MARK: - Schema Version 2 (Current - with Diabetes Status)

/// Current schema with diabetes status added to profiles
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            UserAllergenProfile.self,
        ]
    }
    
    @Model
    final class UserAllergenProfile {
        var id: UUID
        var name: String
        var isActive: Bool
        var sensitivitiesData: Data?
        var diabetesStatusRaw: String  // NEW: Added in V2
        var dateCreated: Date
        var dateModified: Date
        
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
        
        // Convenience property
        var hasDiabetesConcern: Bool {
            diabetesStatus != .none
        }
        
        // Sensitivities management
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
        
        func addSensitivity(_ sensitivity: UserSensitivity) {
            var current = sensitivities
            current.append(sensitivity)
            sensitivities = current
        }
        
        func removeSensitivity(id: UUID) {
            var current = sensitivities
            current.removeAll { $0.id == id }
            sensitivities = current
        }
        
        func updateSensitivity(_ sensitivity: UserSensitivity) {
            var current = sensitivities
            if let index = current.firstIndex(where: { $0.id == sensitivity.id }) {
                current[index] = sensitivity
                sensitivities = current
            }
        }
    }
}

// MARK: - Migration Plan

enum Reczipes2MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self,
        ]
    }
    
    static var stages: [MigrationStage] {
        [
            // Migration from V1 to V2: Add diabetes status with default value
            migrateV1toV2,
        ]
    }
    
    /// Migration from V1 to V2: Adds diabetesStatusRaw field with default "None"
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Log migration start
            print("🔄 Starting migration from Schema V1 to V2")
            print("   Adding diabetes status to user profiles...")
            
            // Fetch all existing profiles
            let profiles = try context.fetch(FetchDescriptor<SchemaV1.UserAllergenProfile>())
            print("   Found \(profiles.count) profile(s) to migrate")
        },
        didMigrate: { context in
            // After automatic migration, ensure all profiles have diabetes status set
            let profiles = try context.fetch(FetchDescriptor<SchemaV2.UserAllergenProfile>())
            
            var migratedCount = 0
            for profile in profiles {
                // Ensure diabetes status is set (should be automatic with default value)
                if profile.diabetesStatusRaw.isEmpty {
                    profile.diabetesStatusRaw = DiabetesStatus.none.rawValue
                    migratedCount += 1
                }
            }
            
            // Save changes
            try context.save()
            
            print("✅ Migration to Schema V2 complete")
            print("   Total profiles: \(profiles.count)")
            print("   Profiles updated with default diabetes status: \(migratedCount)")
            print("   All existing profiles now have diabetes status = 'None'")
        }
    )
}

// MARK: - Schema Versioning Helper

/// Helper struct to track and manage schema versions
struct SchemaVersionManager {
    
    /// Current schema version
    static let currentVersion = SchemaV2.versionIdentifier
    
    /// Check if migration is needed
    static func needsMigration(currentStoredVersion: Schema.Version?) -> Bool {
        guard let stored = currentStoredVersion else {
            // No version stored = new install, no migration needed
            return false
        }
        return stored < currentVersion
    }
    
    /// Get human-readable version string
    static func versionString(_ version: Schema.Version) -> String {
        "\(version.major).\(version.minor).\(version.patch)"
    }
    
    /// Log current schema information
    static func logSchemaInfo() {
        print("📊 Schema Version Info:")
        print("   Current Version: \(versionString(currentVersion))")
        print("   Available Versions:")
        for schema in Reczipes2MigrationPlan.schemas {
            print("     - \(versionString(schema.versionIdentifier)): \(schema)")
        }
        print("   Migration Stages: \(Reczipes2MigrationPlan.stages.count)")
    }
}

// MARK: - Version History Documentation

/*
 
 ## Schema Version History
 
 ### Version 1.0.0 (Initial)
 - Original schema
 - UserAllergenProfile without diabetes status
 - All other models in initial state
 
 ### Version 2.0.0 (Current)
 - Added `diabetesStatusRaw` to UserAllergenProfile
 - Default value: "None"
 - Supports: None, Prediabetic, Diabetic
 - Migration: Automatic with default value assignment
 - Backward compatible: Old profiles get "None" status
 
 ## Future Versions
 
 To add a new schema version:
 
 1. Create SchemaVX enum conforming to VersionedSchema
 2. Update version identifier: Schema.Version(X, 0, 0)
 3. Add any new properties or models
 4. Add migration stage to Reczipes2MigrationPlan.stages
 5. Test migration thoroughly
 6. Update this documentation
 
 Example for V3:
 
 ```swift
 enum SchemaV3: VersionedSchema {
     static var versionIdentifier = Schema.Version(3, 0, 0)
     
     static var models: [any PersistentModel.Type] {
         [/* updated models */]
     }
     
     // Define your new model structure here
 }
 
 // Add to MigrationPlan:
 static let migrateV2toV3 = MigrationStage.custom(
     fromVersion: SchemaV2.self,
     toVersion: SchemaV3.self,
     willMigrate: { context in
         // Pre-migration logic
     },
     didMigrate: { context in
         // Post-migration logic
     }
 )
 ```
 
 ## Migration Best Practices
 
 1. **Always provide default values** for new properties
 2. **Never remove properties** - mark as deprecated instead
 3. **Test migrations** with real user data
 4. **Log migration progress** for debugging
 5. **Keep old schema definitions** for reference
 6. **Version bump rules**:
    - Major (X.0.0): Breaking changes
    - Minor (0.X.0): New features, backward compatible
    - Patch (0.0.X): Bug fixes only
 
 */
