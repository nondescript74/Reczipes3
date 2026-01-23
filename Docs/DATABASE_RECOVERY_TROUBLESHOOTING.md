# Database Recovery & Troubleshooting Guide

## Overview

This guide covers the enhanced logging and diagnostic systems for database recovery in Reczipes. These tools help diagnose, track, and resolve database issues automatically while providing transparency to users and developers.

## New Components

### 1. DatabaseRecoveryLogger

A comprehensive logging system that tracks all database recovery attempts.

**Location:** `DatabaseRecoveryLogger.swift`

**Key Features:**
- Tracks every recovery attempt with detailed metrics
- Records success/failure rates
- Measures recovery duration
- Logs file deletions and database sizes
- Persists recovery history (last 50 attempts)
- Provides statistical analysis

**Usage Example:**
```swift
// Start tracking a recovery attempt
DatabaseRecoveryLogger.shared.beginRecoveryAttempt()

// Log successful recovery
DatabaseRecoveryLogger.shared.logRecoverySuccess(
    error: originalError,
    filesDeleted: ["CloudKitModel.sqlite", "CloudKitModel.sqlite-shm", "CloudKitModel.sqlite-wal"],
    cloudKitEnabled: true,
    databaseSizeMB: 22.4
)

// Log failed recovery
DatabaseRecoveryLogger.shared.logRecoveryFailure(
    error: originalError,
    filesDeleted: filesDeleted,
    cloudKitEnabled: true,
    secondaryError: recreationError
)

// Get statistics
let stats = DatabaseRecoveryLogger.shared.getRecoveryStatistics()
print("Success rate: \(stats.successRate * 100)%")
```

### 2. DatabaseDiagnosticsView

A user-facing SwiftUI view for database diagnostics.

**Location:** `DatabaseDiagnosticsView.swift`

**Features:**
- Current container status
- CloudKit sync status
- Schema version information
- Recovery history with statistics
- Manual health check trigger
- Full diagnostics export
- Recovery history clearing

**Access:**
Add to your settings or debug menu:
```swift
NavigationLink("Database Diagnostics") {
    DatabaseDiagnosticsView()
}
```

### 3. Enhanced Error Analysis

**Location:** `DatabaseRecoveryLogger.swift` (extension)

**Features:**
- Recursive error chain analysis
- Identifies schema issues automatically
- Detects SwiftData wrapper errors
- Provides suggested resolutions

**Usage:**
```swift
let analysis = DatabaseRecoveryLogger.analyzeError(error as NSError)
analysis.logAnalysis()

if analysis.isSchemaIssue {
    // Handle schema migration error
}
```

## Integration with ModelContainerManager

### Current Flow

1. **Container Creation Fails**
   ```
   tryCreateCloudKitContainer() → catches NSError
   ```

2. **Error Detection**
   ```swift
   // Old way (still works)
   let isUnknownModelVersion = (error.domain == "NSCocoaErrorDomain" && error.code == 134504)
   
   // Enhanced way (recommended)
   let analysis = DatabaseRecoveryLogger.analyzeError(error as NSError)
   if analysis.isSchemaIssue {
       // Begin recovery
   }
   ```

3. **Recovery Process**
   ```swift
   DatabaseRecoveryLogger.shared.beginRecoveryAttempt()
   
   // Delete database files
   // Attempt recreation
   
   if success {
       DatabaseRecoveryLogger.shared.logRecoverySuccess(...)
   } else {
       DatabaseRecoveryLogger.shared.logRecoveryFailure(...)
   }
   ```

### Recommended Integration

Add to `ModelContainerManager.tryCreateCloudKitContainer()`:

```swift
} catch let error as NSError {
    // Analyze the error
    let analysis = DatabaseRecoveryLogger.analyzeError(error)
    analysis.logAnalysis()
    
    if analysis.isSchemaIssue {
        // Begin tracking recovery
        DatabaseRecoveryLogger.shared.beginRecoveryAttempt()
        
        // Get database size before deletion
        let sizeMB = DatabaseRecoveryLogger.getDatabaseSize(at: cloudKitURL)
        
        // Delete files...
        let filesDeleted = ["CloudKitModel.sqlite", "..."]
        
        // Try recreation
        do {
            let container = try ModelContainer(...)
            
            // Log success
            DatabaseRecoveryLogger.shared.logRecoverySuccess(
                error: error,
                filesDeleted: filesDeleted,
                cloudKitEnabled: true,
                databaseSizeMB: sizeMB
            )
            
            return container
        } catch let recreationError {
            // Log failure
            DatabaseRecoveryLogger.shared.logRecoveryFailure(
                error: error,
                filesDeleted: filesDeleted,
                cloudKitEnabled: true,
                secondaryError: recreationError
            )
            
            return nil
        }
    }
}
```

## Log Analysis

### Successful Recovery Log Pattern

```
📊 Starting database recovery attempt #1
🔍 ERROR ANALYSIS:
   Error chain depth: 2
   [0] SwiftData.SwiftDataError (1): ...
   [1] NSCocoaErrorDomain (134504): Cannot use staged migration...
   Schema issue: YES ⚠️
   SwiftData wrapper: YES
   Suggested resolution: Delete and recreate database
   
⚠️ Database incompatible with current schema (unknown model version)
   Attempting to delete incompatible database and start fresh...
   ✅ Deleted: CloudKitModel.sqlite
   ✅ Deleted: CloudKitModel.sqlite-shm
   ✅ Deleted: CloudKitModel.sqlite-wal
   Deleted 3 database file(s), attempting to recreate...
   
✅ ModelContainer recreated successfully after database cleanup

✅ RECOVERY SUCCESS
   Duration: 0.45s
   Files deleted: 3
   CloudKit: enabled
   Database size: 22.4 MB
```

### Failed Recovery Log Pattern

```
📊 Starting database recovery attempt #2
🔍 ERROR ANALYSIS:
   Error chain depth: 2
   Schema issue: YES ⚠️
   
⚠️ Database incompatible with current schema
   Attempting to delete incompatible database and start fresh...
   ✅ Deleted: CloudKitModel.sqlite
   ✅ Deleted: CloudKitModel.sqlite-shm
   ✅ Deleted: CloudKitModel.sqlite-wal
   
❌ Failed to recreate container after cleanup: [error details]

❌ RECOVERY FAILED
   Duration: 0.62s
   Files deleted: 3
   Secondary error: [error details]
   
[Critical diagnostic logged with user actions]
```

## Statistics Dashboard

### Recovery Statistics Structure

```swift
struct RecoveryStatistics {
    let totalAttempts: Int          // Total recovery attempts
    let successfulAttempts: Int     // Successful recoveries
    let failedAttempts: Int         // Failed recoveries
    let averageDurationSeconds: Double  // Average recovery time
    let lastAttempt: RecoveryAttempt?  // Most recent attempt
    
    var successRate: Double         // Computed success rate (0.0-1.0)
    var hasRecentFailures: Bool     // True if failed within last hour
}
```

### Interpreting Statistics

**Healthy App:**
```
Total attempts: 1-2
Success rate: 100%
Recent failures: No
```

**Concerning Pattern:**
```
Total attempts: 5+
Success rate: < 80%
Recent failures: Yes
```

**Action Required:**
```
Total attempts: 10+
Success rate: < 50%
Recent failures: Yes (multiple within hours)
→ Suggest reinstall or contact support
```

## User-Facing Diagnostics

### Diagnostic Events Created

1. **Database Schema Mismatch** (Warning)
   - Shown when recovery begins
   - Explains what's happening
   - Reassures user about data safety

2. **Database Recovered** (Info)
   - Shown after successful recovery
   - Provides recovery duration
   - Suggests verifying data

3. **Database Recovery Failed** (Critical)
   - Shown after failed recovery
   - Provides multiple action options
   - Includes support contact option

### User Actions Available

1. **Wait for Recovery** - Recovery is automatic
2. **Wait for Sync** - CloudKit sync in progress
3. **Verify Your Data** - Check recipes loaded correctly
4. **Restart App** - Close and reopen
5. **Check iCloud Settings** - Navigate to Settings
6. **Reinstall App** - Delete and reinstall
7. **Contact Support** - Get help with diagnostics

## Testing & Debugging

### Simulate Schema Mismatch

To test recovery:

1. Install an older version of the app
2. Create some data
3. Update to current version with schema changes
4. App should auto-recover on launch

### Check Recovery History

```swift
let stats = DatabaseRecoveryLogger.shared.getRecoveryStatistics()
print("Attempts: \(stats.totalAttempts)")
print("Success: \(stats.successfulAttempts)")
print("Failed: \(stats.failedAttempts)")
```

### Access Diagnostics View

Add temporary button to settings:
```swift
#if DEBUG
Button("Database Diagnostics") {
    showDatabaseDiagnostics = true
}
.sheet(isPresented: $showDatabaseDiagnostics) {
    DatabaseDiagnosticsView()
}
#endif
```

### Export Diagnostic Logs

```swift
// Trigger full diagnostic export
Task {
    await ModelContainerManager.shared.logDiagnosticInfo()
    DatabaseRecoveryLogger.shared.logRecoveryStatistics()
}

// Logs available at:
// Documents/reczipes_diagnostics.log
```

## Performance Considerations

### Storage Overhead

- Recovery history: ~1-2 KB per attempt
- Maximum 50 attempts stored
- Total storage: < 100 KB
- Automatically pruned on save

### Performance Impact

- Logging: < 1ms per operation
- Statistics calculation: < 5ms
- History persistence: < 10ms
- No impact on normal operations

## Privacy & Data Retention

### What's Stored

- Timestamp of recovery attempts
- Error codes and domains
- File names deleted
- Success/failure status
- Recovery duration
- Database size

### What's NOT Stored

- ❌ Recipe content
- ❌ User personal data
- ❌ iCloud account information
- ❌ Sensitive credentials

### Data Retention

- Last 50 recovery attempts only
- Older attempts automatically pruned
- User can manually clear history
- History cleared on app deletion

## Troubleshooting Common Issues

### Issue: Multiple Failed Recoveries

**Symptoms:**
- App crashes repeatedly on launch
- Recovery statistics show multiple failures
- Database keeps getting corrupted

**Diagnosis:**
```swift
let stats = DatabaseRecoveryLogger.shared.getRecoveryStatistics()
if stats.failedAttempts > 3 && stats.hasRecentFailures {
    // Serious issue - needs manual intervention
}
```

**Resolution:**
1. Check available storage space
2. Verify iCloud sync status
3. Try airplane mode + launch
4. Reinstall app (last resort)

### Issue: Slow Recovery

**Symptoms:**
- Recovery takes > 5 seconds
- App feels sluggish after recovery

**Diagnosis:**
```swift
let stats = DatabaseRecoveryLogger.shared.getRecoveryStatistics()
if stats.averageDurationSeconds > 5.0 {
    // Slow recovery - large database or storage issues
}
```

**Resolution:**
1. Check database size in diagnostics
2. Consider data cleanup/archiving
3. Check device storage performance

### Issue: Frequent Recoveries

**Symptoms:**
- Recovery happens on most app launches
- User didn't update app recently

**Diagnosis:**
- Multiple recovery attempts within hours/days
- No app updates between attempts

**Root Causes:**
1. Corrupted CloudKit sync
2. File system issues
3. Schema version tracking broken

**Resolution:**
1. Disable CloudKit temporarily
2. Let container stabilize locally
3. Re-enable CloudKit sync
4. Monitor for repeat occurrences

## Future Enhancements

### Potential Additions

1. **Remote Diagnostics**
   - Optional anonymous telemetry
   - Recovery success rate tracking
   - Common error pattern identification

2. **Predictive Recovery**
   - Detect imminent database issues
   - Proactive backup before migration
   - Pre-emptive recovery suggestions

3. **Enhanced UI**
   - Real-time recovery progress
   - Animated status indicators
   - Recovery history timeline

4. **Smart Recovery**
   - ML-based error classification
   - Adaptive recovery strategies
   - Historical pattern analysis

## Support Resources

### For Users

- **Database Diagnostics View** - Check container health and recovery history
- **Diagnostic Logs** - Found in app Documents folder
- **Support Email** - Include diagnostic logs when contacting support

### For Developers

- **Log Categories** - All logs use `category: "storage"`
- **Diagnostic Events** - Available in `DiagnosticManager.shared`
- **Recovery Statistics** - Programmatic access via `DatabaseRecoveryLogger.shared`

## Summary

The enhanced database recovery system provides:

✅ **Automatic recovery** from schema mismatches
✅ **Comprehensive logging** of all recovery attempts
✅ **Statistical analysis** for pattern detection
✅ **User-facing diagnostics** for transparency
✅ **Error analysis** for better troubleshooting
✅ **Recovery history** for debugging

This system significantly improves the app's resilience and makes database issues much easier to diagnose and resolve.
