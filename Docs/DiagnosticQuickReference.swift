//
//  DiagnosticQuickReference.swift
//  Reczipes2
//
//  Quick reference for common diagnostic patterns
//

import SwiftUI

/*
 ╔═══════════════════════════════════════════════════════════╗
 ║         DIAGNOSTIC SYSTEM - QUICK REFERENCE               ║
 ╚═══════════════════════════════════════════════════════════╝
 
 ┌─────────────────────────────────────────────────────────┐
 │ 1. BASIC SETUP                                          │
 └─────────────────────────────────────────────────────────┘
 
 In your App file:
 ```swift
 @main
 struct Reczipes2App: App {
     var body: some Scene {
         WindowGroup {
             ContentView()
                 .diagnosticsCapable()
         }
     }
 }
 ```
 
 ┌─────────────────────────────────────────────────────────┐
 │ 2. ADD A BUTTON                                         │
 └─────────────────────────────────────────────────────────┘
 
 // In toolbar
 .toolbar {
     DiagnosticButton()
 }
 
 // In menu
 Menu("More") {
     DiagnosticMenuItem()
 }
 
 // As floating button
 .diagnosticFloatingButton()
 
 ┌─────────────────────────────────────────────────────────┐
 │ 3. LOG A DIAGNOSTIC                                     │
 └─────────────────────────────────────────────────────────┘
 
 // Simple info
 logUserDiagnostic(
     .info,
     category: .general,
     title: "Recipe Saved",
     message: "Your recipe was saved successfully."
 )
 
 // Error with actions
 logUserDiagnostic(
     .error,
     category: .network,
     title: "Sync Failed",
     message: "Couldn't sync your recipes.",
     technicalDetails: error.localizedDescription,
     suggestedActions: [
         DiagnosticAction(
             title: "Check Connection",
             description: "Verify you're online",
             actionType: .checkNetworkConnection
         )
     ]
 )
 
 ┌─────────────────────────────────────────────────────────┐
 │ 4. USE PRE-BUILT EVENTS                                 │
 └─────────────────────────────────────────────────────────┘
 
 DiagnosticManager.shared.addEvent(
     .containerCreated(cloudKitEnabled: true)
 )
 
 DiagnosticManager.shared.addEvent(
     .cloudKitUnavailable(reason: "No account")
 )
 
 DiagnosticManager.shared.addEvent(
     .networkError(operation: "sync", error: errorMsg)
 )
 
 ┌─────────────────────────────────────────────────────────┐
 │ 5. SHOW DIAGNOSTICS PROGRAMMATICALLY                    │
 └─────────────────────────────────────────────────────────┘
 
 struct MyView: View {
     @Environment(\.showDiagnostics) var showDiagnostics
     
     var body: some View {
         Button("Show Diagnostics") {
             showDiagnostics()
         }
     }
 }
 
 ┌─────────────────────────────────────────────────────────┐
 │ 6. CHECK FOR ISSUES                                     │
 └─────────────────────────────────────────────────────────┘
 
 let diagnostics = DiagnosticManager.shared
 
 // Has failures?
 if !diagnostics.unresolvedFailures.isEmpty {
     // Show badge or alert
 }
 
 // Count
 let count = diagnostics.failureEvents.count
 
 // Export for support
 let report = diagnostics.exportAsText()
 
 ┌─────────────────────────────────────────────────────────┐
 │ 7. SEVERITY LEVELS                                      │
 └─────────────────────────────────────────────────────────┘
 
 .info      → 🔵 Normal operations, good news
 .warning   → 🟠 Potential issues, degraded functionality
 .error     → 🔴 Failed operations, can be retried
 .critical  → 🟣 Serious issues, user action required
 
 ┌─────────────────────────────────────────────────────────┐
 │ 8. CATEGORIES                                           │
 └─────────────────────────────────────────────────────────┘
 
 .storage    → Database, persistence
 .cloudKit   → iCloud sync
 .network    → API calls, connectivity
 .extraction → Recipe parsing
 .image      → Image handling
 .allergen   → Allergen detection
 .sharing    → Recipe sharing
 .general    → Everything else
 
 ┌─────────────────────────────────────────────────────────┐
 │ 9. ACTION TYPES                                         │
 └─────────────────────────────────────────────────────────┘
 
 .openSettings(.icloud)     → Open iCloud settings
 .openSettings(.wifi)       → Open Wi-Fi settings
 .checkCloudKitStatus       → Verify CloudKit
 .checkNetworkConnection    → Check network
 .recreateContainer         → Rebuild storage
 .retryOperation            → Try again
 .contactSupport            → Email support
 .deleteAndReinstall        → Nuclear option
 .custom("identifier")      → App-specific action
 
 ┌─────────────────────────────────────────────────────────┐
 │ 10. MIGRATION PATTERN                                   │
 └─────────────────────────────────────────────────────────┘
 
 // OLD - technical only
 logError("Container failed: \(error)", category: "storage")
 
 // NEW - user-friendly
 logUserDiagnostic(
     .error,
     category: .storage,
     title: "Storage Error",
     message: "Couldn't access your recipes.",
     technicalDetails: error.localizedDescription,
     suggestedActions: [
         DiagnosticAction(
             title: "Restart App",
             description: "Close and reopen Reczipes",
             actionType: .retryOperation
         )
     ]
 )
 
 ╔═══════════════════════════════════════════════════════════╗
 ║                    BEST PRACTICES                         ║
 ╚═══════════════════════════════════════════════════════════╝
 
 ✅ DO: Use friendly language
    "Your recipes are saved locally"
 
 ❌ DON'T: Use jargon
    "ModelContainer initialization failed with error -1"
 
 ✅ DO: Provide specific actions
    "Go to Settings > iCloud to sign in"
 
 ❌ DON'T: Be vague
    "Check your settings"
 
 ✅ DO: Include technical details
    Put error codes in technicalDetails field
 
 ❌ DON'T: Show raw errors to users
    Users don't need to see stack traces
 
 ✅ DO: Mark resolved when fixed
    diagnosticManager.markResolved(eventId: id)
 
 ❌ DON'T: Let old events pile up
    Clear resolved events periodically
 
 ╔═══════════════════════════════════════════════════════════╗
 ║                  COMMON PATTERNS                          ║
 ╚═══════════════════════════════════════════════════════════╝
 
 // Network failure
 catch {
     logUserDiagnostic(
         .error,
         category: .network,
         title: "Connection Failed",
         message: "Couldn't complete the request.",
         technicalDetails: error.localizedDescription,
         suggestedActions: [
             DiagnosticAction(
                 title: "Check Connection",
                 description: "Make sure you're online",
                 actionType: .checkNetworkConnection
             )
         ]
     )
 }
 
 // CloudKit unavailable
 if !cloudKitAvailable {
     logUserDiagnostic(
         .warning,
         category: .cloudKit,
         title: "iCloud Sync Disabled",
         message: "Sign into iCloud to sync across devices.",
         suggestedActions: [
             DiagnosticAction(
                 title: "Open iCloud Settings",
                 description: "Go to Settings to sign in",
                 actionType: .openSettings(.icloud)
             )
         ]
     )
 }
 
 // Successful operation
 logUserDiagnostic(
     .info,
     category: .extraction,
     title: "Recipe Imported",
     message: "Successfully added \(recipeName)."
 )
 
 // Critical failure
 logUserDiagnostic(
     .critical,
     category: .storage,
     title: "Data Corruption",
     message: "Couldn't recover your data. Try reinstalling.",
     technicalDetails: "Recovery failed after 3 attempts",
     suggestedActions: [
         DiagnosticAction(
             title: "Reinstall App",
             description: "Your iCloud data will restore automatically",
             actionType: .deleteAndReinstall
         ),
         DiagnosticAction(
             title: "Contact Support",
             description: "Get help from our team",
             actionType: .contactSupport
         )
     ]
 )
 
 */

// This file is documentation only - no executable code
