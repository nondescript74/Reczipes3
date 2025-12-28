# Schema Migration Visual Guide

## 📊 Migration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Reczipes2App.swift                       │
│                                                             │
│  ┌───────────────────────────────────────────────────┐    │
│  │        ModelContainer Initialization              │    │
│  │                                                   │    │
│  │  1. Log schema version info                      │    │
│  │  2. Try CloudKit with migration plan             │    │
│  │  3. Fallback to local with migration plan        │    │
│  │  4. Last resort: no migration                    │    │
│  └───────────────────────────────────────────────────┘    │
│                          │                                  │
│                          ▼                                  │
│  ┌───────────────────────────────────────────────────┐    │
│  │      Uses: Reczipes2MigrationPlan                │    │
│  └───────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                           │
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  SchemaMigration.swift                      │
│                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │  SchemaV1    │   │  SchemaV2    │   │  SchemaV3    │  │
│  │  (1.0.0)     │   │  (2.0.0)     │   │  (3.0.0)     │  │
│  │              │   │              │   │   Future     │  │
│  │  Original    │   │  + Diabetes  │   │              │  │
│  └──────────────┘   └──────────────┘   └──────────────┘  │
│         │                   │                              │
│         │                   │                              │
│         └───────┬───────────┘                              │
│                 │                                          │
│                 ▼                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │       Reczipes2MigrationPlan                      │   │
│  │                                                   │   │
│  │  schemas: [V1, V2, V3...]                        │   │
│  │  stages:  [V1→V2, V2→V3...]                      │   │
│  └───────────────────────────────────────────────────┘   │
│                         │                                  │
│                         ▼                                  │
│  ┌───────────────────────────────────────────────────┐   │
│  │       Migration Stages                            │   │
│  │                                                   │   │
│  │  migrateV1toV2:                                   │   │
│  │    willMigrate: Log and prepare                   │   │
│  │    didMigrate:  Set defaults & validate           │   │
│  └───────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              UserAllergenProfile.swift                      │
│                                                             │
│  ┌───────────────────────────────────────────────────┐    │
│  │  @Model final class UserAllergenProfile           │    │
│  │                                                   │    │
│  │  - id: UUID                                       │    │
│  │  - name: String                                   │    │
│  │  - isActive: Bool                                 │    │
│  │  - sensitivitiesData: Data?                       │    │
│  │  - diabetesStatusRaw: String    ← Added in V2    │    │
│  │  - dateCreated: Date                              │    │
│  │  - dateModified: Date                             │    │
│  └───────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Migration Flow Timeline

```
App Launch (User with V1 data)
│
├─ App detects new version
│  └─ Schema V2.0.0 > stored V1.0.0
│
├─ Migration starts automatically
│  ┌────────────────────────────────────┐
│  │ willMigrate (Pre-migration)        │
│  │ • Log migration start              │
│  │ • Count existing profiles          │
│  │ • Prepare for changes              │
│  └────────────────────────────────────┘
│
├─ SwiftData performs automatic migration
│  ┌────────────────────────────────────┐
│  │ Automatic Schema Updates           │
│  │ • Add diabetesStatusRaw property   │
│  │ • Preserve all existing data       │
│  │ • Update schema metadata           │
│  └────────────────────────────────────┘
│
├─ Custom migration logic
│  ┌────────────────────────────────────┐
│  │ didMigrate (Post-migration)        │
│  │ • Fetch all profiles               │
│  │ • Set default diabetes = "None"    │
│  │ • Validate migration               │
│  │ • Save context                     │
│  │ • Log success                      │
│  └────────────────────────────────────┘
│
└─ App continues normally
   └─ User sees all their data + new features
```

## 📈 Data Flow During Migration

```
BEFORE MIGRATION (V1)
┌─────────────────────────────┐
│  UserAllergenProfile        │
├─────────────────────────────┤
│  id: abc-123                │
│  name: "John's Profile"     │
│  isActive: true             │
│  sensitivitiesData: [🥜🥛]  │
│  dateCreated: 2024-01-01    │
│  dateModified: 2024-06-15   │
└─────────────────────────────┘

         │
         │ MIGRATION
         ▼

AFTER MIGRATION (V2)
┌─────────────────────────────┐
│  UserAllergenProfile        │
├─────────────────────────────┤
│  id: abc-123                │ ← Preserved
│  name: "John's Profile"     │ ← Preserved
│  isActive: true             │ ← Preserved
│  sensitivitiesData: [🥜🥛]  │ ← Preserved
│  diabetesStatusRaw: "None"  │ ← NEW (default)
│  dateCreated: 2024-01-01    │ ← Preserved
│  dateModified: 2024-06-15   │ ← Preserved
└─────────────────────────────┘
```

## 🎯 Version Evolution Path

```
┌──────────────┐
│  Version 1.0 │
│  Original    │
│              │
│  Properties: │
│  • id        │
│  • name      │
│  • isActive  │
│  • sensData  │
│  • created   │
│  • modified  │
└──────────────┘
      │
      │ Migration V1→V2
      │ + diabetesStatusRaw
      ▼
┌──────────────┐
│  Version 2.0 │
│  Current     │
│              │
│  Properties: │
│  • id        │
│  • name      │
│  • isActive  │
│  • sensData  │
│  • diabetes  │ ← NEW
│  • created   │
│  • modified  │
└──────────────┘
      │
      │ Migration V2→V3 (Future)
      │ + yourNewProperty
      ▼
┌──────────────┐
│  Version 3.0 │
│  Future      │
│              │
│  Properties: │
│  • (all V2)  │
│  • newProp   │ ← Future feature
└──────────────┘
```

## 🏗️ Component Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                     App Architecture                        │
│                                                             │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────┐   │
│  │   App.swift  │────▶│  Migration   │────▶│  Model   │   │
│  │              │     │    Plan      │     │  V2.0.0  │   │
│  └──────────────┘     └──────────────┘     └──────────┘   │
│         │                     │                    │        │
│         │                     │                    │        │
│         ▼                     ▼                    ▼        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           ModelContainer (SwiftData)                 │  │
│  │                                                      │  │
│  │  • Manages persistence                              │  │
│  │  • Handles CloudKit sync                            │  │
│  │  • Executes migrations                              │  │
│  │  • Validates schema                                 │  │
│  └──────────────────────────────────────────────────────┘  │
│         │                                                   │
│         ▼                                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              SQLite Database                         │  │
│  │              (With schema V2.0.0)                    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🔍 Decision Tree

```
                   App Launches
                        │
                        ▼
              ┌─────────────────┐
              │ Check DB schema │
              └─────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
        ▼                               ▼
┌───────────────┐             ┌─────────────────┐
│ Fresh Install │             │ Existing Data   │
│ (No DB)       │             │                 │
└───────────────┘             └─────────────────┘
        │                               │
        ▼                               ▼
┌───────────────┐             ┌─────────────────┐
│ Create V2     │             │ Compare Versions│
│ Schema        │             │                 │
│               │             └─────────────────┘
│ No migration  │                       │
│ needed        │       ┌───────────────┴───────────────┐
└───────────────┘       │                               │
        │               ▼                               ▼
        │      ┌─────────────────┐           ┌─────────────────┐
        │      │ Same Version    │           │ Old Version     │
        │      │ (V2 = V2)       │           │ (V1 < V2)       │
        │      └─────────────────┘           └─────────────────┘
        │               │                               │
        │               ▼                               ▼
        │      ┌─────────────────┐           ┌─────────────────┐
        │      │ No migration    │           │ Run Migration   │
        │      │ needed          │           │ V1 → V2         │
        │      └─────────────────┘           └─────────────────┘
        │               │                               │
        │               │                               │
        └───────────────┴───────────────────────────────┘
                        │
                        ▼
                ┌───────────────┐
                │ App Ready     │
                │ with V2 data  │
                └───────────────┘
```

## 📱 User Experience Flow

```
USER'S PERSPECTIVE

Before Update (V1)
┌──────────────────────────────┐
│  Allergen Profiles           │
├──────────────────────────────┤
│                              │
│  👤 John's Profile      ✓    │
│     3 sensitivities          │
│     🥜 🥛 🍞                 │
│                              │
│  👤 Sarah's Profile          │
│     1 sensitivity            │
│     🦐                       │
│                              │
└──────────────────────────────┘

         ↓ User Updates App

During Update (Invisible to User)
┌──────────────────────────────┐
│  🔄 Migration happening...   │
│                              │
│  (Automatic, in background)  │
│  • Preserving data           │
│  • Adding diabetes field     │
│  • Setting defaults          │
└──────────────────────────────┘

         ↓

After Update (V2)
┌──────────────────────────────┐
│  Allergen Profiles           │
├──────────────────────────────┤
│                              │
│  👤 John's Profile      ✓    │
│     3 sensitivities          │ ← Still there!
│     🥜 🥛 🍞                 │ ← Preserved!
│     Diabetes: None           │ ← NEW feature!
│                              │
│  👤 Sarah's Profile          │
│     1 sensitivity            │ ← Still there!
│     🦐                       │ ← Preserved!
│     Diabetes: None           │ ← NEW feature!
│                              │
└──────────────────────────────┘

Result: ✅ All data preserved
        ✅ New features available
        ✅ No reinstall needed
```

## 🎓 Key Concepts

### 1. VersionedSchema
```
Purpose: Define what the database looks like at each version
Think of it as: A snapshot of your data structure at a point in time
```

### 2. SchemaMigrationPlan
```
Purpose: Tell SwiftData how to move from version to version
Think of it as: A roadmap for upgrading your database
```

### 3. MigrationStage
```
Purpose: The actual work to upgrade from one version to another
Think of it as: The construction crew that renovates your database
```

### 4. willMigrate vs didMigrate
```
willMigrate:  Before changes (prepare, log, validate)
didMigrate:   After changes (set defaults, validate, cleanup)
```

## 🚨 What NOT To Do

```
❌ WRONG: Delete the property
@Model class Profile {
    // var diabetesStatusRaw: String  // ❌ Removed!
}

✅ RIGHT: Keep it, add new version if needed
@Model class Profile {
    var diabetesStatusRaw: String  // ✅ Keep it!
    // Add new properties in next version
}

❌ WRONG: Change type without migration
var diabetesStatusRaw: Int  // ❌ Changed from String!

✅ RIGHT: Add new property, deprecate old
var diabetesStatusRaw: String  // ✅ Keep old
var diabetesStatusNew: Int     // ✅ Add new in V3
// Migrate data in migration stage

❌ WRONG: No default value in migration
// Just adding property without migration logic

✅ RIGHT: Set default in migration
didMigrate: { context in
    for profile in profiles {
        profile.diabetesStatusRaw = "None"  // ✅ Default!
    }
}
```

---

**Visual Guide Version**: 1.0  
**Schema Version**: 2.0.0  
**Last Updated**: December 28, 2025
