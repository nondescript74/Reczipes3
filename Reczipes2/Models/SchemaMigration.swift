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
    static nonisolated(unsafe) var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            Recipe.self,
            RecipeImageAssignment.self,
            UserAllergenProfile.self,
            CachedDiabeticAnalysis.self,
            SavedLink.self,
            RecipeBook.self,
            CookingSession.self,
        ]
    }
    
    @Model
    final class UserAllergenProfile {
        // CloudKit requires optional properties
        var id: UUID?
        var name: String?
        var isActive: Bool?
        var sensitivitiesData: Data?
        var dateCreated: Date?
        var dateModified: Date?
        
        init(id: UUID = UUID(),
             name: String = "",
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

// MARK: - Schema Version 2 (with Diabetes Status)

/// Schema V2 with diabetes status added to profiles
enum SchemaV2: VersionedSchema {
    static nonisolated(unsafe) var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            Recipe.self,
            RecipeImageAssignment.self,
            UserAllergenProfile.self,
            CachedDiabeticAnalysis.self,
            SavedLink.self,
            RecipeBook.self,
            CookingSession.self,
        ]
    }
    
    @Model
    final class UserAllergenProfile {
        // CloudKit requires optional properties
        var id: UUID?
        var name: String?
        var isActive: Bool?
        var sensitivitiesData: Data?
        var diabetesStatusRaw: String?  // NEW: Added in V2
        var dateCreated: Date?
        var dateModified: Date?
        
        init(id: UUID = UUID(),
             name: String = "",
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
        nonisolated var diabetesStatus: DiabetesStatus {
            get {
                guard let raw = diabetesStatusRaw else { return .none }
                return DiabetesStatus(rawValue: raw) ?? .none
            }
            set {
                diabetesStatusRaw = newValue.rawValue
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
                return MainActor.assumeIsolated {
                    (try? JSONDecoder().decode([UserSensitivity].self, from: data)) ?? []
                }
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

// MARK: - Schema Version 3 (with Nutritional Goals)

/// Schema V3 with nutritional goals added to profiles
enum SchemaV3: VersionedSchema {
    static nonisolated(unsafe) var versionIdentifier = Schema.Version(3, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            Recipe.self,
            RecipeImageAssignment.self,
            UserAllergenProfile.self,
            CachedDiabeticAnalysis.self,
            SavedLink.self,
            RecipeBook.self,
            CookingSession.self,
        ]
    }
    
    @Model
    final class UserAllergenProfile {
        // CloudKit doesn't support unique constraints
        // CloudKit requires properties to be optional OR have defaults - we make them optional
        var id: UUID?
        var name: String?
        var isActive: Bool?
        var sensitivitiesData: Data?
        var diabetesStatusRaw: String?
        var nutritionalGoalsData: Data?  // NEW: Added in V3
        var dateCreated: Date?
        var dateModified: Date?
        
        init(
            id: UUID = UUID(),
            name: String = "",
            isActive: Bool = false,
            sensitivitiesData: Data? = nil,
            diabetesStatus: DiabetesStatus = .none,
            nutritionalGoals: NutritionalGoals? = nil,
            dateCreated: Date = Date(),
            dateModified: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.isActive = isActive
            self.sensitivitiesData = sensitivitiesData
            self.diabetesStatusRaw = diabetesStatus.rawValue
            // Encode nutritional goals data
            self.nutritionalGoalsData = MainActor.assumeIsolated {
                if let goals = nutritionalGoals {
                    return try? JSONEncoder().encode(goals)
                } else {
                    return nil
                }
            }
            self.dateCreated = dateCreated
            self.dateModified = dateModified
        }
        
        // Computed property for diabetes status
        var diabetesStatus: DiabetesStatus {
            get {
                guard let raw = diabetesStatusRaw else { return .none }
                return DiabetesStatus(rawValue: raw) ?? .none
            }
            set {
                diabetesStatusRaw = newValue.rawValue
                dateModified = Date()
            }
        }
        
        // Computed property for nutritional goals
        var nutritionalGoals: NutritionalGoals? {
            get {
                guard let data = nutritionalGoalsData else { return nil }
                return MainActor.assumeIsolated {
                    try? JSONDecoder().decode(NutritionalGoals.self, from: data)
                }
            }
            set {
                nutritionalGoalsData = try? JSONEncoder().encode(newValue)
                dateModified = Date()
            }
        }
        
        // Convenience properties
        var hasDiabetesConcern: Bool {
            diabetesStatus != .none
        }
        
        var hasNutritionalGoals: Bool {
            nutritionalGoals != nil
        }
        
        // Sensitivities management
        var sensitivities: [UserSensitivity] {
            get {
                guard let data = sensitivitiesData else { return [] }
                return MainActor.assumeIsolated {
                    (try? JSONDecoder().decode([UserSensitivity].self, from: data)) ?? []
                }
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

// MARK: - Schema Version 4 (Current - with CloudKit Sharing)

/// Current schema with CloudKit sharing models
enum SchemaV4: VersionedSchema {
    static nonisolated(unsafe) var versionIdentifier = Schema.Version(4, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            Recipe.self,
            RecipeImageAssignment.self,
            UserAllergenProfile.self,
            CachedDiabeticAnalysis.self,
            SavedLink.self,
            RecipeBook.self,
            CookingSession.self,
            SharedRecipe.self,          // NEW: CloudKit sharing models
            SharedRecipeBook.self,      // NEW: CloudKit sharing models
            SharingPreferences.self,    // NEW: CloudKit sharing models
        ]
    }
    
    @Model
    final class UserAllergenProfile {
        // CloudKit doesn't support unique constraints
        // CloudKit requires properties to be optional OR have defaults - we make them optional
        var id: UUID?
        var name: String?
        var isActive: Bool?
        var sensitivitiesData: Data?
        var diabetesStatusRaw: String?
        var nutritionalGoalsData: Data?
        var dateCreated: Date?
        var dateModified: Date?
        
        init(
            id: UUID = UUID(),
            name: String = "",
            isActive: Bool = false,
            sensitivitiesData: Data? = nil,
            diabetesStatus: DiabetesStatus = .none,
            nutritionalGoals: NutritionalGoals? = nil,
            dateCreated: Date = Date(),
            dateModified: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.isActive = isActive
            self.sensitivitiesData = sensitivitiesData
            self.diabetesStatusRaw = diabetesStatus.rawValue
            // Encode nutritional goals data
            self.nutritionalGoalsData = MainActor.assumeIsolated {
                if let goals = nutritionalGoals {
                    return try? JSONEncoder().encode(goals)
                } else {
                    return nil
                }
            }
            self.dateCreated = dateCreated
            self.dateModified = dateModified
        }
        
        // Computed property for diabetes status
        var diabetesStatus: DiabetesStatus {
            get {
                guard let raw = diabetesStatusRaw else { return .none }
                return DiabetesStatus(rawValue: raw) ?? .none
            }
            set {
                diabetesStatusRaw = newValue.rawValue
                dateModified = Date()
            }
        }
        
        // Computed property for nutritional goals
        var nutritionalGoals: NutritionalGoals? {
            get {
                guard let data = nutritionalGoalsData else { return nil }
                return MainActor.assumeIsolated {
                    try? JSONDecoder().decode(NutritionalGoals.self, from: data)
                }
            }
            set {
                nutritionalGoalsData = try? JSONEncoder().encode(newValue)
                dateModified = Date()
            }
        }
        
        // Convenience properties
        var hasDiabetesConcern: Bool {
            diabetesStatus != .none
        }
        
        var hasNutritionalGoals: Bool {
            nutritionalGoals != nil
        }
        
        // Sensitivities management
        var sensitivities: [UserSensitivity] {
            get {
                guard let data = sensitivitiesData else { return [] }
                return MainActor.assumeIsolated {
                    (try? JSONDecoder().decode([UserSensitivity].self, from: data)) ?? []
                }
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
            SchemaV3.self,
            SchemaV4.self,
        ]
    }
    
    static var stages: [MigrationStage] {
        [
            // Migration from V1 to V2: Add diabetes status with default value
            migrateV1toV2,
            // Migration from V2 to V3: Add nutritional goals
            migrateV2toV3,
            // Migration from V3 to V4: Add CloudKit sharing models
            migrateV3toV4,
        ]
    }
    
    /// Migration from V1 to V2: Adds diabetesStatusRaw field with default "None"
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Log migration start
            print("[Migration] 🔄 Starting migration from Schema V1 to V2")
            print("[Migration]    Adding diabetes status to user profiles...")
            
            // Fetch all existing profiles
            let profiles = try context.fetch(FetchDescriptor<SchemaV1.UserAllergenProfile>())
            print("[Migration]    Found \(profiles.count) profile(s) to migrate")
        },
        didMigrate: { context in
            // After automatic migration, ensure all profiles have diabetes status set
            let profiles = try context.fetch(FetchDescriptor<SchemaV2.UserAllergenProfile>())
            
            var migratedCount = 0
            for profile in profiles {
                // Ensure diabetes status is set (should be automatic with default value)
                if profile.diabetesStatusRaw == nil || profile.diabetesStatusRaw?.isEmpty == true {
                    profile.diabetesStatusRaw = DiabetesStatus.none.rawValue
                    migratedCount += 1
                }
            }
            
            // Save changes
            try context.save()
            
            // Log completion
            print("[Migration] ✅ Migration to Schema V2 complete")
            print("[Migration]    Total profiles: \(profiles.count)")
            print("[Migration]    Profiles updated with default diabetes status: \(migratedCount)")
            print("[Migration]    All existing profiles now have diabetes status = 'None'")
        }
    )
    
    /// Migration from V2 to V3: Adds nutritionalGoalsData field (optional)
    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: { context in
            // Log migration start
            print("[Migration] 🔄 Starting migration from Schema V2 to V3")
            print("[Migration]    Adding nutritional goals support to user profiles...")
            
            // Fetch all existing profiles
            let profiles = try context.fetch(FetchDescriptor<SchemaV2.UserAllergenProfile>())
            print("[Migration]    Found \(profiles.count) profile(s) to migrate")
        },
        didMigrate: { context in
            // After automatic migration, nutritionalGoalsData will be nil by default
            let profiles = try context.fetch(FetchDescriptor<SchemaV3.UserAllergenProfile>())
            
            // No action needed - nutritionalGoalsData is optional
            // Users can set their goals through the UI
            
            // Save changes
            try context.save()
            
            // Log completion
            print("[Migration] ✅ Migration to Schema V3 complete")
            print("[Migration]    Total profiles: \(profiles.count)")
            print("[Migration]    All profiles can now set nutritional goals")
            print("[Migration]    Note: Nutritional goals are optional and can be configured by users")
        }
    )
    
    /// Migration from V3 to V4: Adds CloudKit sharing models (no data migration needed)
    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )
}

// MARK: - Schema Versioning Helper

/// Helper struct to track and manage schema versions
struct SchemaVersionManager {
    
    /// Current schema version
    static let currentVersion = SchemaV4.versionIdentifier
    
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
        // Use print for schema info to avoid concurrency issues
        print("[Schema] 📊 Schema Version Info:")
        print("[Schema]    Current Version: \(versionString(currentVersion))")
        print("[Schema]    Available Versions:")
        for schema in Reczipes2MigrationPlan.schemas {
            print("[Schema]      - \(versionString(schema.versionIdentifier)): \(schema)")
        }
        print("[Schema]    Migration Stages: \(Reczipes2MigrationPlan.stages.count)")
    }
}

// MARK: - Version History Documentation

/*
 
 ## Schema Version History
 
 ### Version 1.0.0 (Initial)
 - Original schema
 - UserAllergenProfile without diabetes status or nutritional goals
 - Basic profile with sensitivities only
 - **CloudKit Compatibility**: All properties made optional (CloudKit requirement)
 
 ### Version 2.0.0
 - Added `diabetesStatusRaw` to UserAllergenProfile
 - Default value: "None"
 - Supports: None, Prediabetic, Diabetic
 - Migration: Automatic with default value assignment
 - Backward compatible: Old profiles get "None" status
 - **CloudKit Compatibility**: All properties made optional (CloudKit requirement)
 
 ### Version 3.0.0
 - Added `nutritionalGoalsData` to UserAllergenProfile
 - Stores encoded NutritionalGoals struct as Data
 - Optional field (nil by default)
 - Supports tracking of daily nutritional targets
 - Migration: Automatic, no data transformation needed
 - **CloudKit Compatibility**: 
   - Removed @Attribute(.unique) from id field (CloudKit doesn't support unique constraints)
   - Made all properties optional (CloudKit requirement)
   - Properties initialized with default values in init()
   - Allows seamless CloudKit sync with existing data
 
 ### Version 4.0.0 (Current)
 - Added CloudKit sharing models:
   - SharedRecipe: For sharing recipes to community
   - SharedRecipeBook: For sharing recipe collections
   - SharingPreferences: User preferences for sharing features
 - Migration: Lightweight (no data transformation)
 - Existing recipes and data are preserved
 - New models start empty (users opt-in to sharing)
 
 ## Future Versions
 
 To add a new schema version:
 
 1. Create SchemaVX enum conforming to VersionedSchema
 2. Update version identifier: Schema.Version(X, 0, 0)
 3. Add any new properties or models
 4. Add migration stage to Reczipes2MigrationPlan.stages
 5. Update SchemaVersionManager.currentVersion
 6. Test migration thoroughly
 7. Update this documentation
 
 Example for V4:
 
 ```swift
 enum SchemaV4: VersionedSchema {
     static var versionIdentifier = Schema.Version(4, 0, 0)
     
     static var models: [any PersistentModel.Type] {
         [/* updated models */]
     }
     
     // Define your new model structure here
 }
 
 // Add to MigrationPlan:
 static let migrateV3toV4 = MigrationStage.custom(
     fromVersion: SchemaV3.self,
     toVersion: SchemaV4.self,
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
