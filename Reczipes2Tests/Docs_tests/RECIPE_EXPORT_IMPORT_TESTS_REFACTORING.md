# Recipe Export/Import Tests Refactoring

## Summary

The large `RecipeExportImportTests.swift` file (2,864 lines) has been split into 5 focused test files for better organization and maintainability.

## New Test File Structure

### 1. **RecipeExportImportBasicTests.swift** (Basic Operations)
- **Purpose**: Basic smoke tests, test data factories, and simple encoding/decoding
- **Tests Include**:
  - Smoke tests (basic assertions)
  - Test data factory methods (createCompleteRecipeModel, createMinimalRecipeModel)
  - RecipeModel complete encoding/decoding
  - Recipe to RecipeModel conversion
  - Component tests (Ingredient, RecipeNote)
  - Backward compatibility tests

### 2. **RecipeExportImportBackupTests.swift** (Backup Creation)
- **Purpose**: Tests for backup creation, file naming, and directory management
- **Tests Include**:
  - Backup directory path validation
  - Backup directory creation
  - Backup file naming conventions
  - Backup file listing (listAvailableBackups)
  - Backup creation with single/multiple recipes
  - Backup file validation (JSON structure)
  - BackupFileInfo display name formatting

### 3. **RecipeExportImportRestoreTests.swift** (Import & Restore)
- **Purpose**: Tests for backup import, overwrite modes, and restore workflows
- **Tests Include**:
  - Import from Reczipes2 folder
  - Import modes (keepBoth, skip, overwrite)
  - Import failure scenarios (non-existent files, corrupted files, empty files)
  - Backup persistence across app sessions
  - Multiple sequential backups

### 4. **RecipeExportImportIntegrationTests.swift** (End-to-End)
- **Purpose**: Full cycle integration tests and complex scenarios
- **Tests Include**:
  - Full export/import cycle data preservation
  - Complete backup and restore workflow
  - Backup/restore with complex relationships
  - Export package encoding with all fields
  - ExportableRecipeBook initialization
  - Image manifest ID uniqueness
  - Image type categorization

### 5. **RecipeExportImportEdgeCaseTests.swift** (Edge Cases & Errors)
- **Purpose**: Error handling, corrupted files, special characters, and large data
- **Tests Include**:
  - Special characters in text fields
  - Very long text fields
  - Invalid JSON handling
  - Missing required fields
  - Corrupted recipe data
  - Malformed dates
  - Error message validation
  - Data integrity checks
  - Recipe ID consistency
  - Image manifest reference validity
  - Round-trip encoding preservation
  - Large data sets (50 recipes)
  - File name sanitization
  - Version compatibility
  - Export date preservation

## Benefits of This Organization

1. **Easier Navigation**: Tests are grouped by logical functionality
2. **Faster Test Execution**: Can run specific test suites independently
3. **Better Maintenance**: Smaller files are easier to understand and modify
4. **Clearer Purpose**: Each file has a specific focus area
5. **Follows Best Practices**: Matches the structure used for diabetic cache tests

## Test Count Distribution

- **RecipeExportImportBasicTests**: ~12 tests (encoding/decoding fundamentals)
- **RecipeExportImportBackupTests**: ~13 tests (backup creation and management)
- **RecipeExportImportRestoreTests**: ~9 tests (import and restore operations)
- **RecipeExportImportIntegrationTests**: ~7 tests (full workflows)
- **RecipeExportImportEdgeCaseTests**: ~25+ tests (edge cases and error handling)

**Total**: ~66 tests (same as original, just reorganized)

## Next Steps

You can now:
1. Delete or archive the original `RecipeExportImportTests.swift` file
2. Run the new test suites independently or together
3. Add new tests to the appropriate focused file

## Example: Running Specific Test Suites

```swift
// Run all export/import tests
xcodebuild test -scheme Reczipes2Tests

// Run just backup creation tests
xcodebuild test -scheme Reczipes2Tests -only-testing:RecipeExportImportBackupTests

// Run just edge case tests
xcodebuild test -scheme Reczipes2Tests -only-testing:RecipeExportImportEdgeCaseTests
```

## File Locations

All new test files are located in the test directory alongside:
- `DiabeticCacheTests.swift`
- `DiabeticCacheStorageTests.swift`
- `DiabeticCacheIntegrationTests.swift`
- `DiabeticCacheEdgeCaseTests.swift`
