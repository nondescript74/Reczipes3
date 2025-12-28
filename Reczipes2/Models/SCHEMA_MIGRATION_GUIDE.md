# SwiftData Schema Migration Guide

## Overview

This app uses SwiftData's built-in migration system to handle schema changes without requiring users to delete and reinstall the app. The migration system automatically preserves user data when updating to new versions of the app.

## Current Schema Version: 2.0.0

### What's Included

- **Automatic Migration**: When users update the app, their data is automatically migrated to the new schema
- **Version Tracking**: Each schema version is tracked and logged
- **Data Preservation**: All existing user data is preserved during migration
- **CloudKit Compatible**: Migrations work with both local and CloudKit-synced data

## Schema Version History

### Version 1.0.0 (Initial Release)
- **UserAllergenProfile** (original schema)
  - `id: UUID`
  - `name: String`
  - `isActive: Bool`
  - `sensitivitiesData: Data?`
  - `dateCreated: Date`
  - `dateModified: Date`

### Version 2.0.0 (Current - Diabetes Support)
- **UserAllergenProfile** (updated schema)
  - `id: UUID`
  - `name: String`
  - `isActive: Bool`
  - `sensitivitiesData: Data?`
  - **NEW**: `diabetesStatusRaw: String` (default: "None")
  - `dateCreated: Date`
  - `dateModified: Date`

**Migration Behavior**:
- All existing profiles receive diabetes status = "None"
- No data loss
- Users can update diabetes status after migration

## How It Works

### For Users

When you update the app:

1. **Launch the App**: No action required
2. **Automatic Migration**: App detects schema change and migrates data automatically
3. **Data Preserved**: All your profiles, recipes, and settings remain intact
4. **New Features Available**: Diabetes status feature is now available in profile settings

### For Developers

The migration system consists of three main components:

#### 1. Schema Versions (`SchemaMigration.swift`)

```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    // Original schema definition
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    // Updated schema with new fields
}
```

#### 2. Migration Plan

```swift
enum Reczipes2MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
}
```

#### 3. Migration Stages

```swift
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self,
    willMigrate: { context in
        // Pre-migration setup
    },
    didMigrate: { context in
        // Post-migration validation and cleanup
    }
)
```

## Adding New Schema Versions

### Step 1: Create New Schema Version

```swift
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [UserAllergenProfile.self]
    }
    
    @Model
    final class UserAllergenProfile {
        // Add your new properties here
        var newProperty: String  // NEW in V3
        // ... existing properties
    }
}
```

### Step 2: Update Migration Plan

```swift
enum Reczipes2MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]  // Add V3
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]  // Add new migration
    }
}
```

### Step 3: Define Migration Logic

```swift
static let migrateV2toV3 = MigrationStage.custom(
    fromVersion: SchemaV2.self,
    toVersion: SchemaV3.self,
    willMigrate: { context in
        print("🔄 Starting migration from V2 to V3")
        let profiles = try context.fetch(FetchDescriptor<SchemaV2.UserAllergenProfile>())
        print("   Found \(profiles.count) profiles to migrate")
    },
    didMigrate: { context in
        let profiles = try context.fetch(FetchDescriptor<SchemaV3.UserAllergenProfile>())
        
        // Set default values for new property
        for profile in profiles {
            if profile.newProperty.isEmpty {
                profile.newProperty = "default value"
            }
        }
        
        try context.save()
        print("✅ Migration to V3 complete")
    }
)
```

### Step 4: Update Active Model

Update `UserAllergenProfile.swift` to match the latest schema:

```swift
@Model
final class UserAllergenProfile {
    var id: UUID
    var name: String
    var isActive: Bool
    var sensitivitiesData: Data?
    var diabetesStatusRaw: String
    var newProperty: String  // Add new property
    var dateCreated: Date
    var dateModified: Date
    
    init(/* update initializer */) {
        // Initialize new property
        self.newProperty = newProperty
    }
}
```

### Step 5: Update Version Manager

```swift
struct SchemaVersionManager {
    static let currentVersion = SchemaV3.versionIdentifier  // Update to V3
}
```

## Migration Best Practices

### ✅ DO

1. **Always provide default values** for new properties
2. **Test migrations thoroughly** with real user data
3. **Log migration progress** for debugging
4. **Keep old schema versions** in the codebase
5. **Document all changes** in version history
6. **Use semantic versioning**:
   - Major (X.0.0): Breaking changes
   - Minor (0.X.0): New features, backward compatible
   - Patch (0.0.X): Bug fixes only

### ❌ DON'T

1. **Don't remove properties** - mark as deprecated instead
2. **Don't change property types** without migration logic
3. **Don't skip version numbers** - must migrate sequentially
4. **Don't forget to test** on devices with real data
5. **Don't assume migration is instant** - can take time for large datasets

## Testing Migrations

### Test Scenarios

1. **Fresh Install**
   - Install app fresh
   - Should use latest schema (V2)
   - No migration needed

2. **Upgrade from V1**
   - Install app with V1 schema
   - Create test data
   - Update to V2
   - Verify data preserved
   - Verify new fields have defaults

3. **CloudKit Sync**
   - Test migration with CloudKit enabled
   - Verify data syncs after migration
   - Check multiple devices receive migration

### Test Checklist

- [ ] Create profiles in V1
- [ ] Add sensitivities to profiles
- [ ] Set active profile
- [ ] Upgrade to V2
- [ ] Verify all profiles still exist
- [ ] Verify all sensitivities intact
- [ ] Verify diabetes status = "None" by default
- [ ] Verify can update diabetes status
- [ ] Verify CloudKit sync works
- [ ] Check console logs for migration success

## Console Logs

During migration, you'll see logs like:

```
📊 Schema Version Info:
   Current Version: 2.0.0
   Available Versions:
     - 1.0.0: SchemaV1
     - 2.0.0: SchemaV2
   Migration Stages: 1

🔄 Starting migration from Schema V1 to V2
   Adding diabetes status to user profiles...
   Found 3 profile(s) to migrate

✅ Migration to Schema V2 complete
   Total profiles: 3
   Profiles updated with default diabetes status: 0
   All existing profiles now have diabetes status = 'None'

✅ ModelContainer created successfully with CloudKit sync enabled
   Container: iCloud.com.headydiscy.reczipes
   Schema Version: 2.0.0
   Migration support enabled - existing data will be preserved
```

## Troubleshooting

### Migration Failed

**Symptoms**: App crashes on launch, error messages about schema mismatch

**Solutions**:
1. Check console logs for specific error
2. Verify all schema versions are properly defined
3. Ensure migration stages are in correct order
4. Clean build folder (Cmd+Shift+K)
5. Delete app and reinstall (last resort)

### Data Missing After Migration

**Symptoms**: Profiles or recipes disappeared after update

**Solutions**:
1. Check migration logic in `didMigrate`
2. Verify property names match between versions
3. Check if CloudKit sync is functioning
4. Review console logs for clues

### CloudKit Sync Issues After Migration

**Symptoms**: Data not syncing after schema update

**Solutions**:
1. Check CloudKit container configuration
2. Verify iCloud account is signed in
3. Force sync by toggling iCloud in Settings
4. Check CloudKit Dashboard for sync errors

## Files Involved

- **`SchemaMigration.swift`**: Schema versions and migration plan
- **`UserAllergenProfile.swift`**: Current model definition
- **`Reczipes2App.swift`**: Model container initialization with migration
- **`SCHEMA_MIGRATION_GUIDE.md`**: This documentation

## Resources

- [Apple SwiftData Migration Documentation](https://developer.apple.com/documentation/swiftdata/migrating-your-models)
- [WWDC SwiftData Sessions](https://developer.apple.com/videos/swiftdata)
- CloudKit Setup Guide: See `CLOUDKIT_SETUP_GUIDE.md`

## Version Bump Checklist

When creating a new schema version:

- [ ] Create new `SchemaVX` enum in `SchemaMigration.swift`
- [ ] Update model definitions in schema version
- [ ] Add to `Reczipes2MigrationPlan.schemas` array
- [ ] Create new migration stage
- [ ] Add migration stage to `stages` array
- [ ] Update `SchemaVersionManager.currentVersion`
- [ ] Update active model file (`UserAllergenProfile.swift`)
- [ ] Update this documentation
- [ ] Test migration thoroughly
- [ ] Update app version number
- [ ] Add release notes about schema changes

## Support

For migration issues or questions:
1. Check console logs first
2. Review this guide
3. Check existing schema versions
4. Test with sample data before production
5. Document any new migration patterns discovered

---

**Last Updated**: December 28, 2025  
**Current Schema Version**: 2.0.0  
**Migration Status**: Active and tested
