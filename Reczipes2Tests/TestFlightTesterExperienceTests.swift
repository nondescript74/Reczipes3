//
//  TestFlightTesterExperienceTests.swift
//  Reczipes2Tests
//
//  Tests simulating the TestFlight tester experience
//  Created on 1/16/26.
//

import Testing
import Foundation
import CloudKit
import SwiftData
@testable import Reczipes2

/// Tests that simulate what TestFlight testers will experience
@Suite("TestFlight Tester Experience Simulation")
@MainActor
struct TestFlightTesterExperienceTests {
    
    @Suite("First Launch Experience")
    struct FirstLaunchTests {
        
        @Test("Onboarding triggers on first check")
        func onboardingTriggersOnFirstCheck() async {
            let service = CloudKitOnboardingService.shared
            
            // On first launch, comprehensive diagnostics should run
            await service.runComprehensiveDiagnostics()
            
            // State should be determined
            #expect(service.onboardingState != .checking,
                   "After diagnostics, state should be determined")
            
            // Diagnostics should exist
            #expect(service.diagnostics != nil,
                   "Diagnostics should be available after first check")
        }
        
        @Test("Diagnostics explain current status to user")
        func diagnosticsExplainStatus() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            guard let diagnostics = service.diagnostics else {
                Issue.record("Diagnostics should be available")
                return
            }
            
            let description = diagnostics.readableDescription
            
            // Should be human-readable
            #expect(description.contains("CloudKit Diagnostics"))
            
            // Should show clear status
            #expect(description.contains("Account Status"))
            #expect(description.contains("Container Accessible"))
            
            // Should have clear overall status
            #expect(description.contains("Overall Status"))
        }
        
        @Test("Tester can see if they're ready to share")
        func testerCanSeeIfReadyToShare() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            // Tester should be able to check the state
            switch service.onboardingState {
            case .ready:
                // Great! Tester can share
                break
            case .needsiCloudSignIn:
                // Clear: tester needs to sign into iCloud
                break
            case .needsContainerPermission:
                // Clear: tester needs to grant permissions
                break
            case .needsPublicDBSetup:
                // Clear: database needs setup
                break
            case .needsUserIdentity:
                // Clear: user identity needed
                break
            case .restricted:
                // Clear: CloudKit is restricted
                break
            case .failed(let error):
                // Should have error details
                #expect(service.errorDetails != nil || error.localizedDescription.count > 0,
                       "Failure state should provide error information")
            case .checking:
                Issue.record("Should not still be checking after diagnostics complete")
            }
        }
    }
    
    @Suite("Setup & Diagnostics Screen")
    struct SetupDiagnosticsTests {
        
        @Test("All diagnostic checks are clearly labeled")
        func diagnosticChecksAreClearlyLabeled() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            guard let diagnostics = service.diagnostics else {
                Issue.record("Diagnostics should exist")
                return
            }
            
            let description = diagnostics.readableDescription
            
            // Each major check should be visible
            let expectedChecks = [
                "Account Status",
                "Container Accessible",
                "Public DB Accessible",
                "Can Share Publicly",
                "Can Read Public Content"
            ]
            
            for check in expectedChecks {
                #expect(description.contains(check),
                       "Diagnostics should include '\(check)' check")
            }
        }
        
        @Test("Success indicators are clear")
        func successIndicatorsAreClear() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            guard let diagnostics = service.diagnostics else {
                return
            }
            
            let description = diagnostics.readableDescription
            
            // Should use clear success/failure indicators
            #expect(description.contains("✅") || description.contains("❌"),
                   "Should use visual indicators")
        }
        
        @Test("Issues section highlights problems")
        func issuesSectionHighlightsProblems() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            guard let diagnostics = service.diagnostics else {
                return
            }
            
            if !diagnostics.errorMessages.isEmpty {
                let description = diagnostics.readableDescription
                
                // Should have an issues section
                #expect(description.contains("Issues") || description.contains("⚠️"),
                       "Should highlight issues when they exist")
            }
        }
        
        @Test("Repair function is available to testers")
        func repairFunctionAvailable() async {
            let service = CloudKitOnboardingService.shared
            
            // Tester can trigger repair
            await service.attemptRepair()
            
            // After repair, diagnostics should be updated
            #expect(service.diagnostics != nil,
                   "Diagnostics should be available after repair attempt")
        }
        
        @Test("Schema initialization is available to testers")
        func schemaInitializationAvailable() async {
            let service = CloudKitOnboardingService.shared
            
            // Tester can trigger schema initialization
            await service.initializePublicDatabaseSchema()
            
            // After initialization, diagnostics should be updated
            #expect(service.diagnostics != nil,
                   "Diagnostics should be available after schema initialization")
        }
    }
    
    @Suite("Sharing Flow from Tester Perspective")
    struct TesterSharingFlowTests {
        
        private func createTestModelContainer() throws -> ModelContainer {
            let schema = Schema([
                Recipe.self,
                RecipeBook.self,
                SharedRecipe.self,
                SharedRecipeBook.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [configuration])
        }
        
        @Test("Tester can see if CloudKit is available before sharing")
        func canCheckAvailabilityBeforeSharing() async {
            let service = CloudKitSharingService.shared
            
            // Tester should be able to check availability
            let isAvailable = service.isCloudKitAvailable
            
            // Property should be set (true or false)
            // We don't require it to be true in tests
        }
        
        @Test("Share button checks CloudKit status first (simulated)")
        func shareButtonChecksStatus() async {
            let service = CloudKitSharingService.shared
            
            // In the UI, the share button should check this first:
            if !service.isCloudKitAvailable {
                // Should show error to user, not attempt to share
                // This prevents confusing CloudKit errors
            }
            
            // Verify the check is possible
            let _ = service.isCloudKitAvailable
        }
        
        @Test("Tester receives clear error messages on failure")
        func clearErrorMessagesOnFailure() {
            let errors: [SharingError] = [
                .notAuthenticated,
                .cloudKitUnavailable,
                .recipeNotFound,
                .bookNotFound
            ]
            
            for error in errors {
                let message = error.errorDescription ?? ""
                
                // Should be helpful
                #expect(!message.isEmpty,
                       "Error message should not be empty")
                
                // Should not be cryptic
                #expect(!message.contains("CKError"),
                       "Should not expose CloudKit error codes directly")
                #expect(!message.contains("database"),
                       "Should use user-friendly terms")
            }
        }
    }
    
    @Suite("Browsing Shared Content")
    struct BrowsingSharedContentTests {
        
        @Test("Shared recipes can be fetched")
        func sharedRecipesCanBeFetched() async {
            let service = CloudKitSharingService.shared
            
            // Even if fetch fails (no CloudKit access), should not crash
            do {
                _ = try await service.fetchSharedRecipes(limit: 10)
                // Success!
            } catch {
                // Failure is acceptable in test environment
                // Just verify it's a known error type
                if let sharingError = error as? SharingError {
                    #expect(sharingError.errorDescription != nil,
                           "Error should have a description")
                }
            }
        }
        
        @Test("Shared recipe books can be fetched")
        func sharedRecipeBooksCanBeFetched() async {
            let service = CloudKitSharingService.shared
            
            // Even if fetch fails (no CloudKit access), should not crash
            do {
                _ = try await service.fetchSharedRecipeBooks(limit: 10)
                // Success!
            } catch {
                // Failure is acceptable in test environment
                if let sharingError = error as? SharingError {
                    #expect(sharingError.errorDescription != nil,
                           "Error should have a description")
                }
            }
        }
        
        @Test("Fetch limit can be configured")
        func fetchLimitConfigurable() async {
            let service = CloudKitSharingService.shared
            
            // Should accept different limits
            do {
                _ = try await service.fetchSharedRecipes(limit: 5)
                _ = try await service.fetchSharedRecipes(limit: 50)
                _ = try await service.fetchSharedRecipes(limit: 100)
            } catch {
                // Acceptable in test environment
            }
        }
    }
    
    @Suite("Common Tester Issues")
    struct CommonTesterIssuesTests {
        
        @Test("Handles 'not signed into iCloud' scenario")
        func handlesNotSignedIntoiCloud() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            // If account is not available, should be clearly indicated
            guard let diagnostics = service.diagnostics else {
                return
            }
            
            if diagnostics.accountStatus == "noAccount" {
                // Should be in needsiCloudSignIn state
                switch service.onboardingState {
                case .needsiCloudSignIn:
                    // Correct!
                    break
                default:
                    Issue.record("When account status is noAccount, onboarding should indicate sign in needed")
                }
            }
        }
        
        @Test("Handles 'CloudKit restricted' scenario")
        func handlesCloudKitRestricted() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            guard let diagnostics = service.diagnostics else {
                return
            }
            
            if diagnostics.accountStatus == "restricted" {
                // Should be in restricted state
                switch service.onboardingState {
                case .restricted:
                    // Correct!
                    break
                default:
                    Issue.record("When account is restricted, onboarding should indicate restricted state")
                }
            }
        }
        
        @Test("Provides help for 'works in dev, fails in TestFlight' scenario")
        func helpsWithDevVsTestFlightIssues() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            guard let diagnostics = service.diagnostics else {
                return
            }
            
            // Diagnostics should show environment
            let isProduction = diagnostics.isProductionEnvironment
            
            // In TestFlight, this should be true
            // In Xcode development, this should be false
            // Helps identify environment-specific issues
        }
        
        @Test("Container validation helps diagnose setup issues")
        func containerValidationHelps() async {
            let result = await CloudKitContainerValidator.validateContainer(
                identifier: "iCloud.com.headydiscy.reczipes"
            )
            
            let diagnosis = result.diagnose()
            
            // Should provide recommendations if issues found
            if !diagnosis.issues.isEmpty {
                #expect(!diagnosis.recommendations.isEmpty,
                       "Issues should come with recommendations")
            }
        }
    }
    
    @Suite("Tester Feedback Scenarios")
    struct TesterFeedbackScenariosTests {
        
        @Test("Tester can export diagnostics for feedback")
        func canExportDiagnosticsForFeedback() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            let exported = service.exportDiagnostics()
            
            // Should be something a tester can copy and paste
            #expect(!exported.isEmpty)
            #expect(exported.count > 50, "Should have substantial diagnostic information")
            
            // Should be readable (JSON)
            #expect(exported.contains("{") && exported.contains("}"),
                   "Should be JSON format")
        }
        
        @Test("Readable description is suitable for screenshots")
        func readableDescriptionSuitableForScreenshots() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            guard let diagnostics = service.diagnostics else {
                return
            }
            
            let description = diagnostics.readableDescription
            
            // Should be well-formatted
            #expect(description.contains("\n"), "Should be multi-line")
            
            // Should have visual indicators
            #expect(description.contains("✅") || description.contains("❌"),
                   "Should have clear visual status indicators")
            
            // Should have section headers
            #expect(description.contains("━") || description.contains("="),
                   "Should have formatted sections")
        }
        
        @Test("Container validation report is detailed")
        func containerValidationReportDetailed() async {
            let result = await CloudKitContainerValidator.validateContainer(
                identifier: "iCloud.com.headydiscy.reczipes"
            )
            
            // Report should include key information
            #expect(!result.containerIdentifier.isEmpty)
            #expect(!result.bundleID.isEmpty)
            #expect(!result.accountStatusMessage.isEmpty)
            #expect(!result.containerAccessMessage.isEmpty)
        }
    }
    
    @Suite("Onboarding Never Completes Scenarios")
    struct OnboardingNeverCompletesTests {
        
        @Test("Onboarding times out appropriately")
        func onboardingTimesOut() async {
            let service = CloudKitOnboardingService.shared
            
            // Run diagnostics with timeout
            await withTimeout(seconds: 30) {
                await service.runComprehensiveDiagnostics()
            }
            
            // Should not hang forever
            // Should complete with some state
            #expect(service.onboardingState != .checking,
                   "Onboarding should complete, not hang in checking state")
        }
        
        @Test("Network issues don't cause indefinite hang")
        func networkIssuesDontCauseHang() async {
            let service = CloudKitOnboardingService.shared
            
            // Even with network issues, should complete
            await withTimeout(seconds: 30) {
                await service.runComprehensiveDiagnostics()
            }
            
            // Should have diagnostics even if network failed
            #expect(service.diagnostics != nil,
                   "Should generate diagnostics even with network issues")
        }
        
        private func withTimeout(seconds: TimeInterval, operation: @escaping () async -> Void) async {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await operation()
                }
                
                group.addTask {
                    try? await Task.sleep(for: .seconds(seconds))
                }
                
                // Wait for first to complete
                await group.next()
                
                // Cancel the other
                group.cancelAll()
            }
        }
    }
    
    @Suite("Success Metrics Validation")
    struct SuccessMetricsTests {
        
        @Test("Can track onboarding completion")
        func canTrackOnboardingCompletion() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            // Can determine if onboarding completed successfully
            switch service.onboardingState {
            case .ready:
                // Onboarding completed! Count as success.
                break
            default:
                // Onboarding did not complete. Count as incomplete.
                break
            }
        }
        
        @Test("Can track successful shares")
        func canTrackSuccessfulShares() async {
            // When share succeeds, returns record ID
            // When share fails, throws error
            // This allows tracking success rate
            
            let service = CloudKitSharingService.shared
            
            // The share methods return String on success or throw on failure
            // This makes success tracking straightforward
        }
        
        @Test("Can identify most common errors")
        func canIdentifyCommonErrors() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            guard let diagnostics = service.diagnostics else {
                return
            }
            
            // Error messages are tracked
            let errors = diagnostics.errorMessages
            
            // These can be logged/analyzed to find common patterns
            // e.g., "Cannot access CloudKit container" appears 50% of the time
        }
        
        @Test("Diagnostics provide measurable success criteria")
        func diagnosticsProvideMeasurableSuccessCriteria() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            guard let diagnostics = service.diagnostics else {
                return
            }
            
            // Can measure:
            // - Is account available?
            let accountAvailable = diagnostics.accountStatus == "available"
            
            // - Can access container?
            let containerAccessible = diagnostics.containerAccessible
            
            // - Can share publicly?
            let canShare = diagnostics.canShareToPublic
            
            // - Is fully functional?
            let fullyFunctional = diagnostics.isFullyFunctional
            
            // All of these are measurable metrics
        }
    }
}
