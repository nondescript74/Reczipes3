# Migration Quick Reference Card

## 🎯 What You Have Now

✅ **Automatic schema migration** - no more "delete and reinstall"  
✅ **Version 2.0.0** - includes diabetes status support  
✅ **Data preservation** - all user profiles and data safe  
✅ **CloudKit compatible** - works with iCloud sync  
✅ **Production ready** - tested and documented  

## 🔍 Check Migration Status

### In Console (when app launches)

```
✅ ModelContainer created successfully with CloudKit sync enabled
   Schema Version: 2.0.0
   Migration support enabled - existing data will be preserved
```

### If Migration Runs

```
🔄 Starting migration from Schema V1 to V2
   Found X profile(s) to migrate
✅ Migration to Schema V2 complete
   All existing profiles now have diabetes status = 'None'
```

## 📁 Key Files

| File | Purpose |
|------|---------|
| `SchemaMigration.swift` | Schema versions & migration logic |
| `UserAllergenProfile.swift` | Current model (V2.0.0) |
| `Reczipes2App.swift` | Migration setup & initialization |
| `SCHEMA_MIGRATION_GUIDE.md` | Complete developer guide |
| `MIGRATION_IMPLEMENTATION_SUMMARY.md` | This implementation overview |

## 🚀 Adding Future Schema (V3)

```swift
// 1. Add to SchemaMigration.swift
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    @Model final class UserAllergenProfile {
        // Add new properties here
    }
}

// 2. Update migration plan
static var schemas = [SchemaV1.self, SchemaV2.self, SchemaV3.self]
static var stages = [migrateV1toV2, migrateV2toV3]

// 3. Create migration
static let migrateV2toV3 = MigrationStage.custom(...)

// 4. Update version
static let currentVersion = SchemaV3.versionIdentifier
```

## 🧪 Testing Migration

```bash
# 1. Install current version
# 2. Create test data (profiles, sensitivities)
# 3. Update to new version
# 4. Verify in console:
```

Look for:
- ✅ Migration started message
- ✅ Profile count matches
- ✅ Migration complete message
- ✅ No errors in console
- ✅ All data still visible in app

## ⚠️ Important Notes

1. **Never remove `diabetesStatusRaw` property** - mark deprecated instead
2. **Always provide default values** in migration logic
3. **Test before release** with real user data
4. **Check CloudKit sync** after migration
5. **Monitor console logs** during first launch after update

## 🐛 Troubleshooting

### App crashes after update
```
1. Check console logs for specific error
2. Verify schema definitions match
3. Clean build folder (Cmd+Shift+K)
4. Rebuild and test
```

### Data missing
```
1. Check migration didMigrate block
2. Verify property names match
3. Check CloudKit sync status
```

### Migration not running
```
1. Verify ModelContainer uses Reczipes2MigrationPlan
2. Check schema version numbers
3. Ensure schemas array includes all versions
```

## 📞 Support Resources

- Full guide: `SCHEMA_MIGRATION_GUIDE.md`
- Implementation: `MIGRATION_IMPLEMENTATION_SUMMARY.md`
- Code: `SchemaMigration.swift`
- Model: `UserAllergenProfile.swift`

## ✅ Checklist for Release

Before shipping update with schema changes:

- [ ] Schema version bumped
- [ ] Migration stage created
- [ ] Migration tested with sample data
- [ ] Console logs verified
- [ ] CloudKit sync tested
- [ ] Multiple profiles tested
- [ ] Active profile preserved
- [ ] New fields have defaults
- [ ] Documentation updated
- [ ] Release notes mention update preserves data

## 🎉 Success Criteria

Migration is successful when:

✅ App launches without crashes  
✅ All existing profiles visible  
✅ All sensitivities intact  
✅ New diabetes field available  
✅ CloudKit sync working  
✅ Console shows migration success  
✅ Users don't need to recreate data  

---

**Current Version**: 2.0.0  
**Migration Status**: ✅ Active  
**Last Updated**: December 28, 2025
