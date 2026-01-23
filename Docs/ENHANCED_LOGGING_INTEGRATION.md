# Enhanced Logging Integration Checklist

## Quick Start Guide

Follow these steps to integrate the enhanced database recovery logging into your app.

## ✅ Step 1: Add DatabaseRecoveryLogger Calls

### In `ModelContainerManager.tryCreateCloudKitContainer()`

Find the error handling block and enhance it:

```swift
} catch let error as NSError {
    logError("❌ CloudKit ModelContainer creation failed: \(error.localizedDescription)", category: "storage")
    
    // ✨ NEW: Analyze error chain
    let analysis = DatabaseRecoveryLogger.analyzeError(error)
    analysis.logAnalysis()
    
    if analysis.isSchemaIssue {
        // ✨ NEW: Begin tracking recovery
        DatabaseRecoveryLogger.shared.beginRecoveryAttempt()
        
        // ✨ NEW: Capture database size before deletion
        let databaseSizeMB = DatabaseRecoveryLogger.getDatabaseSize(at: cloudKitURL)
        
        logWarning("⚠️ Database incompatible with current schema (unknown model version)", category: "storage")
        // ... existing deletion code ...
        
        var filesDeleted: [String] = []
        
        // Track which files were deleted
        for filePath in filesToDelete {
            if fileManager.fileExists(atPath: filePath) {
                do {
                    try fileManager.removeItem(atPath: filePath)
                    filesDeleted.append(filePath.split(separator: "/").last.map(String.init) ?? filePath)
                    logInfo("   ✅ Deleted: \(filesDeleted.last!)", category: "storage")
                } catch {
                    logError("   ❌ Failed to delete \(filePath): \(error)", category: "storage")
                }
            }
        }
        
        if filesDeleted.count > 0 {
            // Try creating container again
            do {
                let container = try ModelContainer(...)
                
                // ✨ NEW: Log successful recovery
                DatabaseRecoveryLogger.shared.logRecoverySuccess(
                    error: error,
                    filesDeleted: filesDeleted,
                    cloudKitEnabled: true,
                    databaseSizeMB: databaseSizeMB
                )
                
                return container
            } catch let recreationError {
                // ✨ NEW: Log failed recovery
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
    
    return nil
}
```

### In `ModelContainerManager.createLocalContainer()`

Apply the same enhancements:

```swift
} catch let error as NSError {
    logError("❌ Local ModelContainer creation failed: \(error.localizedDescription)", category: "storage")
    
    // ✨ NEW: Add same error analysis and recovery tracking as above
    let analysis = DatabaseRecoveryLogger.analyzeError(error)
    analysis.logAnalysis()
    
    // ... rest of recovery code with logging ...
}
```

## ✅ Step 2: Add Diagnostics View to Settings

### In your SettingsView or Debug menu:

```swift
Section("Diagnostics") {
    NavigationLink {
        DatabaseDiagnosticsView()
    } label: {
        Label("Database Diagnostics", systemImage: "stethoscope")
    }
    
    Button {
        Task {
            await ModelContainerManager.shared.logDiagnosticInfo()
            DatabaseRecoveryLogger.shared.logRecoveryStatistics()
        }
    } label: {
        Label("Export Diagnostic Logs", systemImage: "doc.text")
    }
}
```

### For Debug Builds Only:

```swift
#if DEBUG
Section("Debug Tools") {
    NavigationLink {
        DatabaseDiagnosticsView()
    } label: {
        Label("Database Diagnostics", systemImage: "stethoscope")
    }
}
#endif
```

## ✅ Step 3: Add Statistics Logging on App Launch

### In your AppDelegate or main App struct:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // ✨ NEW: Log recovery statistics on startup (for monitoring)
    Task { @MainActor in
        // Give container time to initialize
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let stats = DatabaseRecoveryLogger.shared.getRecoveryStatistics()
        if stats.totalAttempts > 0 {
            DatabaseRecoveryLogger.shared.logRecoveryStatistics()
            
            // Alert if recent failures
            if stats.hasRecentFailures {
                logWarning("⚠️ Recent database recovery failures detected", category: "storage")
            }
        }
    }
    
    return true
}
```

### Or in SwiftUI App:

```swift
@main
struct Reczipes2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Wait for container initialization
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    
                    let stats = DatabaseRecoveryLogger.shared.getRecoveryStatistics()
                    if stats.totalAttempts > 0 {
                        DatabaseRecoveryLogger.shared.logRecoveryStatistics()
                    }
                }
        }
    }
}
```

## ✅ Step 4: Test the Integration

### Test 1: Verify Logging Works

1. Add a debug button that simulates recovery:

```swift
Button("Test Recovery Logging") {
    DatabaseRecoveryLogger.shared.beginRecoveryAttempt()
    
    let testError = NSError(
        domain: "NSCocoaErrorDomain",
        code: 134504,
        userInfo: [NSLocalizedDescriptionKey: "Test error"]
    )
    
    DatabaseRecoveryLogger.shared.logRecoverySuccess(
        error: testError,
        filesDeleted: ["test1.sqlite", "test2.shm"],
        cloudKitEnabled: true,
        databaseSizeMB: 10.5
    )
}
```

2. Check the logs for success message
3. Open Database Diagnostics view
4. Verify statistics appear

### Test 2: Verify Error Analysis

1. Trigger a real schema mismatch (or simulate with test data)
2. Check logs for error analysis output
3. Verify it identifies schema issues correctly

### Test 3: Verify User Diagnostics

1. Open Database Diagnostics view
2. Verify all sections populate correctly
3. Run health check
4. Export diagnostics
5. Clear history and verify it clears

## ✅ Step 5: Monitor in Production

### Add Analytics (Optional)

```swift
// In DatabaseRecoveryLogger.logRecoverySuccess()
// After logging success, optionally report to analytics

#if !DEBUG
// Your analytics service
Analytics.track("database_recovery_success", properties: [
    "duration": attempt.recoveryDurationSeconds,
    "files_deleted": attempt.filesDeleted.count,
    "cloudkit_enabled": attempt.cloudKitEnabled
])
#endif
```

### Add Crash Reporting Context

```swift
// In your crash reporting service initialization
let stats = DatabaseRecoveryLogger.shared.getRecoveryStatistics()
Crashlytics.setCustomValue(stats.totalAttempts, forKey: "db_recovery_attempts")
Crashlytics.setCustomValue(stats.successRate, forKey: "db_recovery_success_rate")
Crashlytics.setCustomValue(stats.hasRecentFailures, forKey: "db_has_recent_failures")
```

## ✅ Step 6: Document for Support Team

### Share with Support:

1. **Access Logs**: Show them how to find diagnostic logs
2. **Diagnostics View**: Explain the UI and what stats mean
3. **Common Issues**: Reference the troubleshooting guide
4. **Escalation Criteria**: When to escalate (e.g., multiple failures)

### Create Support Script:

```
User reports app crashes on launch:

1. Ask user to open Settings > Database Diagnostics
2. Check "Recovery History" section
3. If "Failed" count > 0:
   - Check "Last Attempt" details
   - Note error code and duration
4. If "Recent Recovery Failures" warning appears:
   - Advise: Settings > iCloud > verify signed in
   - If persists: Reinstall app (data in iCloud)
5. Have user tap "Export Diagnostic Logs"
6. Request they email logs to support
```

## Common Issues During Integration

### Issue: Compiler errors on DatabaseRecoveryLogger

**Solution:** Ensure `DatabaseRecoveryLogger.swift` is added to your target.

### Issue: Statistics always show 0 attempts

**Solution:** Make sure you're calling `beginRecoveryAttempt()` before the recovery code runs.

### Issue: Diagnostics view crashes

**Solution:** Check that `ModelContainerManager.shared` is accessible on MainActor.

### Issue: Logs not appearing

**Solution:** Verify DiagnosticLogger is initialized before database recovery runs.

## Verification Checklist

- [ ] Added DatabaseRecoveryLogger.swift to project
- [ ] Added DatabaseDiagnosticsView.swift to project
- [ ] Integrated logging in tryCreateCloudKitContainer()
- [ ] Integrated logging in createLocalContainer()
- [ ] Added diagnostics view to settings/debug menu
- [ ] Added statistics logging on app launch
- [ ] Tested with simulated recovery
- [ ] Verified logs appear correctly
- [ ] Verified diagnostics view populates
- [ ] Tested clear history functionality
- [ ] Documented for support team
- [ ] (Optional) Added analytics integration
- [ ] (Optional) Added crash reporting context

## Success Criteria

✅ When recovery occurs, you should see:
- Detailed error analysis in logs
- Recovery attempt tracked with all metadata
- User-facing diagnostic event created
- Statistics updated in diagnostics view
- Success/failure logged with duration

✅ In Database Diagnostics view, you should see:
- Current container status
- CloudKit sync status
- Recovery statistics (if any attempts)
- Last attempt details
- Health check functionality works

✅ In diagnostic logs, you should see:
- "Starting database recovery attempt #N"
- "ERROR ANALYSIS" block
- "RECOVERY SUCCESS" or "RECOVERY FAILED"
- "RECOVERY STATISTICS" on app launch (if applicable)

## Next Steps

After integration is complete:

1. Monitor recovery success rates in production
2. Adjust thresholds for warnings if needed
3. Gather user feedback on diagnostics UI
4. Consider adding telemetry for aggregate stats
5. Review logs periodically for patterns

## Support

For questions or issues with integration:
- Review: `DATABASE_RECOVERY_TROUBLESHOOTING.md`
- Check: `CRASH_FIX_UNKNOWN_MODEL_VERSION.md`
- See examples in: `DatabaseRecoveryLogger.swift` comments
