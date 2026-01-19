//
//  DiagnosticIntegrationGuide.swift
//  Reczipes2
//
//  Created on 1/19/26.
//  Example integration of the new diagnostic system
//

import SwiftUI

/*
 DIAGNOSTIC SYSTEM INTEGRATION GUIDE
 ===================================
 
 This new diagnostic system provides:
 1. User-friendly diagnostic messages with actionable next steps
 2. Automatic categorization and severity levels
 3. Easy filtering (failures vs all events)
 4. Quick access from anywhere in the app
 5. Export capabilities for support
 
 HOW TO USE
 ==========
 
 1. ADD DIAGNOSTICS CAPABILITY TO YOUR ROOT VIEW
 -----------------------------------------------
 In your App file or root view:
 
 @main
 struct Reczipes2App: App {
     @StateObject private var containerManager = ModelContainerManager.shared
     
     var body: some Scene {
         WindowGroup {
             ContentView()
                 .modelContainer(containerManager.container)
                 .diagnosticsCapable()  // ← Add this
                 .shakeToShowDiagnostics()  // ← Optional: Show diagnostics on device shake
         }
     }
 }
 
 
 2. ADD DIAGNOSTIC BUTTONS TO YOUR UI
 ------------------------------------
 
 In Settings View:
 ```swift
 struct SettingsView: View {
     var body: some View {
         Form {
             Section("Developer Tools") {
                 DiagnosticMenuItem()  // ← Automatically shows badge if there are issues
             }
         }
     }
 }
 ```
 
 In Toolbar:
 ```swift
 .toolbar {
     ToolbarItem(placement: .topBarTrailing) {
         DiagnosticButton()  // ← Shows red badge if there are failures
     }
 }
 ```
 
 As Floating Button:
 ```swift
 NavigationStack {
     RecipeListView()
 }
 .diagnosticFloatingButton()  // ← Floating button in bottom-right corner
 ```
 
 
 3. LOG DIAGNOSTIC EVENTS IN YOUR CODE
 -------------------------------------
 
 Instead of just logging to console, create user-facing diagnostics:
 
 // Old way (technical logging only):
 logError("Failed to extract recipe: \(error)", category: "extraction")
 
 // New way (user-facing + technical logging):
 logUserDiagnostic(
     .error,
     category: .extraction,
     title: "Recipe Extraction Failed",
     message: "Couldn't extract recipe from this website.",
     technicalDetails: error.localizedDescription,
     suggestedActions: [
         DiagnosticAction(
             title: "Try a Different URL",
             description: "Some websites don't support recipe extraction",
             actionType: .retryOperation
         )
     ]
 )
 
 
 4. USE PRE-BUILT DIAGNOSTIC EVENTS
 ----------------------------------
 
 For common scenarios, use the built-in events:
 
 // Storage events
 DiagnosticManager.shared.addEvent(.containerCreated(cloudKitEnabled: true))
 DiagnosticManager.shared.addEvent(.containerHealthCheckFailed(error: errorMessage))
 
 // CloudKit events
 DiagnosticManager.shared.addEvent(.cloudKitAvailable())
 DiagnosticManager.shared.addEvent(.cloudKitUnavailable(reason: "No account"))
 
 // Network events
 DiagnosticManager.shared.addEvent(.networkError(operation: "recipe sync", error: errorMessage))
 
 // Extraction events
 DiagnosticManager.shared.addEvent(.extractionSuccess(source: url))
 DiagnosticManager.shared.addEvent(.extractionFailed(source: url, error: errorMessage))
 
 
 5. CREATE CUSTOM DIAGNOSTIC EVENTS
 ----------------------------------
 
 For app-specific scenarios:
 
 extension DiagnosticEvent {
     static func allergenDetected(allergen: String, inRecipe: String) -> DiagnosticEvent {
         DiagnosticEvent(
             severity: .warning,
             category: .allergen,
             title: "Allergen Detected",
             message: "Recipe '\(inRecipe)' contains \(allergen), which is in your allergen profile.",
             technicalDetails: "Allergen: \(allergen)",
             suggestedActions: [
                 DiagnosticAction(
                     title: "View Allergen Profile",
                     description: "Review or update your allergen settings",
                     actionType: .openSettings(.general)
                 )
             ]
         )
     }
 }
 
 // Usage:
 DiagnosticManager.shared.addEvent(.allergenDetected(allergen: "peanuts", inRecipe: "Thai Curry"))
 
 
 6. PROGRAMMATIC ACCESS TO DIAGNOSTICS
 -------------------------------------
 
 ```swift
 let diagnostics = DiagnosticManager.shared
 
 // Check for failures
 if !diagnostics.unresolvedFailures.isEmpty {
     // Show alert or badge
 }
 
 // Get failure count
 let count = diagnostics.unresolvedFailures.count
 
 // Filter by category
 let storageIssues = diagnostics.events(inCategory: .storage)
 
 // Export for support
 let report = diagnostics.exportAsText()
 // Send to support email or save to file
 ```
 
 
 7. SHOW DIAGNOSTICS PROGRAMMATICALLY
 ------------------------------------
 
 ```swift
 struct MyView: View {
     @Environment(\.showDiagnostics) private var showDiagnostics
     
     var body: some View {
         Button("Show Diagnostics") {
             showDiagnostics()
         }
     }
 }
 ```
 
 
 MIGRATION FROM OLD LOGGING
 ==========================
 
 Old Code:
 ```swift
 logCritical("❌ CRITICAL: Container recovery failed!", category: "storage")
 logCritical("   App may not function correctly", category: "storage")
 logCritical("   User should delete and reinstall app to resolve", category: "storage")
 ```
 
 New Code:
 ```swift
 logUserDiagnostic(
     .critical,
     category: .storage,
     title: "Storage Recovery Failed",
     message: "Automatic recovery couldn't fix the storage issue. Your data may be in iCloud.",
     technicalDetails: "All recovery attempts exhausted",
     suggestedActions: [
         DiagnosticAction(
             title: "Check iCloud Status",
             description: "Verify you're signed into iCloud and have sync enabled",
             actionType: .checkCloudKitStatus
         ),
         DiagnosticAction(
             title: "Reinstall Reczipes",
             description: "Delete the app and reinstall it. Your iCloud data will sync back automatically.",
             actionType: .deleteAndReinstall
         ),
         DiagnosticAction(
             title: "Contact Support",
             description: "If the problem persists, reach out for help",
             actionType: .contactSupport
         )
     ]
 )
 ```
 
 The old logCritical() calls still work for technical debugging,
 but now users get actionable, helpful guidance instead of
 cryptic error messages.
 
 
 BEST PRACTICES
 ==============
 
 1. Use appropriate severity levels:
    - .info: Normal operations (container created, sync started)
    - .warning: Potential issues (CloudKit unavailable, network slow)
    - .error: Failed operations that can be retried (extraction failed)
    - .critical: Serious issues requiring user action (data corruption)
 
 2. Always provide user-friendly messages:
    - ✅ "Your recipes are saved locally only"
    - ❌ "CloudKit container initialization returned nil"
 
 3. Include actionable next steps:
    - Tell users WHAT to do, not just WHAT went wrong
    - Link to specific settings when possible
    - Provide retry options
 
 4. Use technical details for debugging:
    - Store error codes, stack traces, etc. in technicalDetails
    - Users can expand to see this if needed
    - Included in export reports for support
 
 5. Mark events as resolved when fixed:
    - Helps users see progress
    - Reduces noise in the failures view
    - Can be done automatically when actions are taken
 
 */

// MARK: - Example Implementation

struct ExampleContentView: View {
    @StateObject private var diagnosticManager = DiagnosticManager.shared
    
    var body: some View {
        TabView {
            RecipeListTab()
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }
            
            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .diagnosticsCapable()
        .shakeToShowDiagnostics()
    }
}

struct RecipeListTab: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<10) { index in
                    Text("Recipe \(index)")
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Add Recipe") { }
                        Divider()
                        DiagnosticMenuItem()
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

struct SettingsTab: View {
    @Environment(\.showDiagnostics) private var showDiagnostics
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Profile") { }
                    Button("Allergens") { }
                }
                
                Section("Developer") {
                    Button {
                        showDiagnostics()
                    } label: {
                        HStack {
                            Label("Diagnostics", systemImage: "stethoscope")
                            Spacer()
                            DiagnosticBadge()
                        }
                    }
                    
                    Button("Simulate Error") {
                        simulateError()
                    }
                    
                    Button("Simulate Warning") {
                        simulateWarning()
                    }
                    
                    Button("Simulate Success") {
                        simulateSuccess()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func simulateError() {
        logUserDiagnostic(
            .error,
            category: .network,
            title: "Network Request Failed",
            message: "Couldn't connect to the recipe database.",
            technicalDetails: "URLError: -1009 (No internet connection)",
            suggestedActions: [
                DiagnosticAction(
                    title: "Check Your Connection",
                    description: "Make sure you're connected to Wi-Fi or cellular",
                    actionType: .checkNetworkConnection
                ),
                DiagnosticAction(
                    title: "Try Again",
                    description: "Retry once you're back online",
                    actionType: .retryOperation
                )
            ]
        )
    }
    
    private func simulateWarning() {
        logUserDiagnostic(
            .warning,
            category: .cloudKit,
            title: "iCloud Sync Paused",
            message: "Sync will resume when you're back online.",
            technicalDetails: "Network connectivity lost during sync operation"
        )
    }
    
    private func simulateSuccess() {
        logUserDiagnostic(
            .info,
            category: .extraction,
            title: "Recipe Imported",
            message: "Successfully imported recipe from AllRecipes.com"
        )
    }
}

// Small badge indicator for unresolved failures
struct DiagnosticBadge: View {
    @StateObject private var diagnosticManager = DiagnosticManager.shared
    
    var body: some View {
        if !diagnosticManager.unresolvedFailures.isEmpty {
            Text("\(diagnosticManager.unresolvedFailures.count)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    ExampleContentView()
        .onAppear {
            // Add some sample diagnostics
            let manager = DiagnosticManager.shared
            manager.addEvent(.containerCreated(cloudKitEnabled: true))
            manager.addEvent(.cloudKitAvailable())
            manager.addEvent(.extractionSuccess(source: "allrecipes.com"))
            manager.addEvent(.networkError(operation: "recipe sync", error: "Connection timeout"))
        }
}
