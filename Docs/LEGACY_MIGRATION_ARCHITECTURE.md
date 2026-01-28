# Legacy Migration Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Reczipes2 App                           │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                   User Interface Layer                    │ │
│  │                                                           │ │
│  │  ┌─────────────────┐      ┌─────────────────────────┐   │ │
│  │  │ ContentView     │      │ MigrationBadgeView      │   │ │
│  │  │                 │      │                         │   │ │
│  │  │ • Recipes Tab   │      │ • Shows count          │   │ │
│  │  │ • More Menu     │◄─────┤ • Opens migration UI   │   │ │
│  │  │ • Migration Item│      │ • Auto-detects need    │   │ │
│  │  └────────┬────────┘      └─────────────────────────┘   │ │
│  │           │                                              │ │
│  │           │ Shows Sheet                                  │ │
│  │           ▼                                              │ │
│  │  ┌─────────────────────────────────────────────────┐    │ │
│  │  │     LegacyMigrationView                        │    │ │
│  │  │                                                 │    │ │
│  │  │  • Display stats                               │    │ │
│  │  │  • Start migration button                      │    │ │
│  │  │  • Show progress                               │    │ │
│  │  │  • Display results                             │    │ │
│  │  │  • Delete legacy data button                   │    │ │
│  │  └────────────────┬────────────────────────────────┘    │ │
│  └─────────────────────┼─────────────────────────────────────┘ │
│                        │                                       │
│  ┌─────────────────────┼─────────────────────────────────────┐ │
│  │                     ▼     Migration Logic Layer         │ │
│  │  ┌────────────────────────────────────────────────┐     │ │
│  │  │  LegacyToNewMigrationManager                   │     │ │
│  │  │                                                 │     │ │
│  │  │  Core Methods:                                 │     │ │
│  │  │  • needsMigration() → Bool                    │     │ │
│  │  │  • getMigrationStats() → MigrationStats       │     │ │
│  │  │  • performMigration() → MigrationResult       │     │ │
│  │  │  • migrateRecipes() → (count, skipped)        │     │ │
│  │  │  • migrateBooks() → (count, skipped)          │     │ │
│  │  │  • validateMigration() → Validation           │     │ │
│  │  │                                                 │     │ │
│  │  │  State Tracking:                               │     │ │
│  │  │  • UserDefaults for completion status         │     │ │
│  │  │  • Migration date tracking                    │     │ │
│  │  │  • Version tracking                           │     │ │
│  │  └────────────────────────────────────────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                        │                                       │
│  ┌─────────────────────┼─────────────────────────────────────┐ │
│  │                     ▼          Data Layer                │ │
│  │                                                           │ │
│  │  ┌──────────────┐           ┌──────────────┐            │ │
│  │  │ Legacy Models│           │  New Models  │            │ │
│  │  │              │           │              │            │ │
│  │  │ • Recipe     │──Copy────►│ • RecipeX    │            │ │
│  │  │   - Local    │           │   - CloudKit │            │ │
│  │  │   - Files    │           │   - SwiftData│            │ │
│  │  │              │           │   - Auto-sync│            │ │
│  │  │ • RecipeBook │──Copy────►│ • Book       │            │ │
│  │  │   - Local    │           │   - CloudKit │            │ │
│  │  │   - Manual   │           │   - SwiftData│            │ │
│  │  │              │           │   - Auto-sync│            │ │
│  │  └──────────────┘           └──────┬───────┘            │ │
│  │                                     │                    │ │
│  │                                     ▼                    │ │
│  │                          ┌──────────────────┐            │ │
│  │                          │   SwiftData      │            │ │
│  │                          │   ModelContext   │            │ │
│  │                          └────────┬─────────┘            │ │
│  └─────────────────────────────────┼─────────────────────┘ │
│                                     │                        │
│  ┌─────────────────────────────────┼─────────────────────┐ │
│  │                                  ▼  Sync Layer         │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │    RecipeXCloudKitSyncService                    │  │ │
│  │  │                                                   │  │ │
│  │  │  • Monitors needsCloudSync flag                 │  │ │
│  │  │  • Uploads to CloudKit Public Database          │  │ │
│  │  │  • Updates sync timestamps                      │  │ │
│  │  │  • Handles sync errors                          │  │ │
│  │  └──────────────────────┬───────────────────────────┘  │ │
│  └─────────────────────────┼───────────────────────────┘ │
│                            │                              │
└────────────────────────────┼──────────────────────────────┘
                             │
                             ▼
                ┌────────────────────────┐
                │   iCloud / CloudKit    │
                │                        │
                │ • Public Database      │
                │ • Private Database     │
                │ • Cross-device sync    │
                └────────────────────────┘
```

## Data Flow

### Migration Process

```
┌──────────┐
│  User    │
│ Launches │
│   App    │
└────┬─────┘
     │
     ▼
┌────────────────────────┐
│ App Startup            │
│ (Reczipes2App.swift)   │
└────┬───────────────────┘
     │
     ├─► checkLegacyMigration()
     │
     ▼
┌─────────────────────────────┐
│ LegacyToNewMigrationManager │
│ .needsMigration()           │
└────┬────────────────────────┘
     │
     ├──[Has Legacy?]──No──► Continue normally
     │
     ├──Yes──► Show badge
     │
     ▼
┌──────────────────┐
│ User Taps Badge  │
└────┬─────────────┘
     │
     ▼
┌──────────────────────┐
│ LegacyMigrationView  │
│ • Display stats      │
│ • Show actions       │
└────┬─────────────────┘
     │
     ├──[User Taps Start]
     │
     ▼
┌────────────────────────────────────────────────┐
│ performMigration()                             │
│                                                │
│  Step 1: Migrate Recipes                      │
│  ┌───────────────────────────────────────┐    │
│  │ For each Recipe:                      │    │
│  │  • Check if RecipeX exists (by ID)   │    │
│  │  • Skip if exists (duplicate)        │    │
│  │  • Create new RecipeX                │    │
│  │  • Copy all data                     │    │
│  │  • Set needsCloudSync = true         │    │
│  │  • Set owner metadata                │    │
│  │  • Insert into context               │    │
│  └───────────────────────────────────────┘    │
│                                                │
│  Step 2: Migrate Books                        │
│  ┌───────────────────────────────────────┐    │
│  │ For each RecipeBook:                  │    │
│  │  • Check if Book exists (by ID)      │    │
│  │  • Skip if exists (duplicate)        │    │
│  │  • Create new Book                   │    │
│  │  • Copy all data & recipe IDs        │    │
│  │  • Set needsCloudSync = true         │    │
│  │  • Set owner metadata                │    │
│  │  • Insert into context               │    │
│  └───────────────────────────────────────┘    │
│                                                │
│  Step 3: Validate                             │
│  ┌───────────────────────────────────────┐    │
│  │ • Check all recipes migrated          │    │
│  │ • Check all books migrated            │    │
│  │ • Verify no duplicate IDs             │    │
│  │ • Check data integrity                │    │
│  └───────────────────────────────────────┘    │
│                                                │
│  Step 4: Save                                 │
│  ┌───────────────────────────────────────┐    │
│  │ modelContext.save()                   │    │
│  └───────────────────────────────────────┘    │
│                                                │
│  Step 5: Mark Complete                        │
│  ┌───────────────────────────────────────┐    │
│  │ UserDefaults:                         │    │
│  │  • migrationCompleted = true          │    │
│  │  • migrationDate = Date()             │    │
│  │  • migrationVersion = 1               │    │
│  └───────────────────────────────────────┘    │
└────────────────────────────────────────────────┘
     │
     ▼
┌──────────────────────┐
│ Display Results      │
│ • Success count      │
│ • Skipped count      │
│ • Errors (if any)    │
│ • Validation results │
└──────────────────────┘
```

### CloudKit Sync After Migration

```
┌──────────────┐
│ Migration    │
│ Complete     │
└──────┬───────┘
       │
       ▼
┌────────────────────────────┐
│ RecipeX/Book marked:       │
│ • needsCloudSync = true    │
│ • ownerUserID set          │
│ • ownerDisplayName set     │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────────┐
│ RecipeXCloudKitSyncService     │
│ (background task)              │
│                                │
│ • Monitors needsCloudSync flag │
│ • Fetches pending items        │
└──────┬─────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│ Upload to CloudKit              │
│                                 │
│ • Create CKRecord               │
│ • Set fields                    │
│ • Upload to Public Database     │
└──────┬──────────────────────────┘
       │
       ├──[Success]──► Update:
       │               • cloudRecordID
       │               • lastSyncedToCloud
       │               • needsCloudSync = false
       │
       ├──[Error]──► Increment:
       │             • syncRetryCount
       │             • lastSyncError
       │             • Keep needsCloudSync = true
       │
       ▼
┌─────────────────────────┐
│ iCloud Propagation      │
│                         │
│ • Sync to other devices │
│ • Available in community│
│ • Cross-device conflict │
│   resolution            │
└─────────────────────────┘
```

## Component Interaction Diagram

```
┌──────────────────┐
│  ContentView     │
│                  │
│  • Recipe list   │
│  • Toolbar       │
└────────┬─────────┘
         │
         │ Shows
         ▼
    ┌─────────────────────┐
    │ MigrationBadgeView  │
    │                     │
    │ • Checks need       │
    │ • Shows count       │
    │ • Opens sheet       │
    └────────┬────────────┘
             │
             │ Presents
             ▼
        ┌────────────────────────┐
        │ LegacyMigrationView    │
        │                        │
        │ • Stats display        │
        │ • Action buttons       │
        │ • Result display       │
        └────────┬───────────────┘
                 │
                 │ Uses
                 ▼
     ┌─────────────────────────────────┐
     │ LegacyToNewMigrationManager     │
     │                                 │
     │ • Migration logic               │
     │ • Validation                    │
     │ • State tracking                │
     └──────────┬──────────────────────┘
                │
                │ Accesses
                ▼
    ┌──────────────────────┐
    │   ModelContext       │
    │                      │
    │ • Fetch legacy       │
    │ • Insert new         │
    │ • Save changes       │
    └──────┬───────────────┘
           │
           ├─► Recipe → RecipeX
           ├─► RecipeBook → Book
           │
           ▼
    ┌──────────────────────┐
    │   SwiftData Store    │
    │                      │
    │ • Persist models     │
    │ • Sync to iCloud     │
    └──────────────────────┘
```

## Class Relationships

```
┌──────────────────────────────────┐
│  LegacyToNewMigrationManager     │
├──────────────────────────────────┤
│ - modelContext: ModelContext     │
│ - logger: Logger                 │
├──────────────────────────────────┤
│ + needsMigration() → Bool        │
│ + getMigrationStats() → Stats   │
│ + performMigration() → Result   │
│ + migrateRecipe() → RecipeX      │
│ + migrateBook() → Book           │
│ + resetMigrationStatus()         │
└──────────┬───────────────────────┘
           │ Uses
           ▼
    ┌─────────────────┐
    │  ModelContext   │
    ├─────────────────┤
    │ + fetch()       │
    │ + insert()      │
    │ + delete()      │
    │ + save()        │
    └─────────────────┘
           │
           ├─► Manages
           ▼
    ┌──────────────────────┐
    │ Legacy Models:       │
    │ • Recipe             │
    │ • RecipeBook         │
    │ • SharedRecipe       │
    │ • SharedRecipeBook   │
    └──────────────────────┘
           │
           ├─► Creates
           ▼
    ┌──────────────────────┐
    │ New Models:          │
    │ • RecipeX            │
    │ • Book               │
    └──────────────────────┘
```

## State Machine

```
[App Launch] ──► [Check Migration Status]
                        │
                        ├──[Not Completed]──► [Check for Legacy Data]
                        │                            │
                        │                            ├──[Has Legacy]──► [Show Badge]
                        │                            │                         │
                        │                            ├──[No Legacy]──► [Hide Badge]
                        │                            │
                        ├──[Completed]──► [Hide Badge]
                        │
                        ▼
                [User Interaction]
                        │
                        ├──[Taps Badge]──► [Show Migration UI]
                        │                         │
                        │                         ├──[Taps Start]──► [Run Migration]
                        │                         │                         │
                        │                         │                         ├──[Success]──► [Show Results]
                        │                         │                         │                     │
                        │                         │                         ├──[Error]──► [Show Error]
                        │                         │                         │
                        │                         ├──[Taps Delete]──► [Confirm]──► [Delete Legacy]
                        │                         │
                        │                         ├──[Taps Refresh]──► [Update Stats]
                        │
                        ▼
                [Migration Complete]
                        │
                        ├──► [Mark as Completed]
                        ├──► [Trigger CloudKit Sync]
                        ├──► [Update UI]
                        │
                        ▼
                [Normal Operation]
```

## File Organization

```
Reczipes2/
├── Models/
│   ├── Legacy/
│   │   ├── Recipe.swift
│   │   └── RecipeBook.swift
│   └── New/
│       ├── RecipeX.swift
│       └── Book.swift
│
├── Services/
│   └── Migration/
│       └── LegacyToNewMigrationManager.swift
│
├── Views/
│   ├── ContentView.swift
│   ├── Migration/
│   │   ├── LegacyMigrationView.swift
│   │   └── MigrationBadgeView.swift
│
├── Documentation/
│   ├── LEGACY_MIGRATION_GUIDE.md
│   ├── LEGACY_MIGRATION_SUMMARY.md
│   ├── LEGACY_MIGRATION_QUICK_REF.md
│   └── LEGACY_MIGRATION_ARCHITECTURE.md
│
└── App/
    └── Reczipes2App.swift
```

## Security & Privacy

```
┌────────────────────────────────────┐
│  Data Protection During Migration │
├────────────────────────────────────┤
│                                    │
│  1. Transaction Safety             │
│     • All changes in one save      │
│     • Rollback on error            │
│     • No partial data corruption   │
│                                    │
│  2. Data Integrity                 │
│     • ID preservation              │
│     • Reference preservation       │
│     • Validation before commit     │
│                                    │
│  3. Privacy                        │
│     • Owner attribution (user ID)  │
│     • No data leak to other users  │
│     • Secure CloudKit transmission │
│                                    │
│  4. Safety                         │
│     • Non-destructive by default   │
│     • Confirmation for deletion    │
│     • Logging for audit trail      │
│                                    │
└────────────────────────────────────┘
```

---

This architecture ensures:
- ✅ Safe, non-destructive migration
- ✅ Data integrity and preservation
- ✅ Seamless CloudKit integration
- ✅ User-friendly interface
- ✅ Comprehensive error handling
- ✅ Privacy and security
