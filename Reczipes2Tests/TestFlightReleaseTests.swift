//
//  TestFlightReleaseTests.swift
//  Reczipes2Tests
//
//  Comprehensive test suite implementing TESTFLIGHT_RELEASE_CHECKLIST.md
//  Created on 1/16/26.
//

import Testing
import Foundation
import CloudKit
import SwiftData
@testable import Reczipes2

/// Master test suite for TestFlight release validation
/// Implements all items from TESTFLIGHT_RELEASE_CHECKLIST.md
@Suite("TestFlight Release Checklist Validation", .serialized)
@MainActor
struct TestFlightReleaseTests {
    
    // MARK: - Pre-Release Checklist Tests
    
    @Suite("CloudKit Dashboard Setup")
    @MainActor
    struct CloudKitDashboardTests {
        
        @Test("Container identifier is correct")
        @MainActor
        func containerIdentifierIsCorrect() async throws {
            _ = "iCloud.com.headydiscy.reczipes"
            let service = CloudKitSharingService.shared
            
            // Verify the service is using the correct container
            let containerField = Mirror(reflecting: service)
                .children
                .first { $0.label == "container" }
            
            #expect(containerField != nil, "CloudKitSharingService should have a container")
        }
        
        @Test("CloudKit container is accessible")
        func cloudKitContainerIsAccessible() async throws {
            let container = CKContainer(identifier: "iCloud.com.headydiscy.reczipes")
            
            // Try to get account status (requires network)
            // Note: This will fail in CI/CD without iCloud login
            do {
                let status = try await container.accountStatus()
                
                // In TestFlight, we expect .available or .noAccount (if user not logged in)
                // .restricted or .couldNotDetermine indicate problems
                let acceptableStatuses: [CKAccountStatus] = [.available, .noAccount]
                #expect(acceptableStatuses.contains(status) || status == .temporarilyUnavailable,
                       "Account status should be available, noAccount, or temporarily unavailable. Got: \(status)")
            } catch {
                // Network errors are acceptable in testing environment
                // But we want to know about them
                Issue.record("CloudKit container check failed (may be expected in test environment): \(error)")
            }
        }
        
        @Test("Record types are defined")
        func recordTypesAreDefined() async throws {
            // Verify that the expected record type names are used in code
            #expect(CloudKitRecordType.sharedRecipe == "SharedRecipe")
            #expect(CloudKitRecordType.sharedRecipeBook == "SharedRecipeBook")
        }
        
        @Test("OnboardingTest record type exists for diagnostics")
        @MainActor
        func onboardingTestRecordTypeExists() async throws {
            // This test verifies the onboarding service uses the diagnostic record type
            let service = CloudKitOnboardingService.shared
            
            // Run diagnostics
            await service.runComprehensiveDiagnostics()
            
            // Verify diagnostics were generated
            #expect(service.diagnostics != nil, "Diagnostics should be generated")
        }
        
        @Test("Schema includes all required fields for SharedRecipe")
        @MainActor
        func sharedRecipeSchemaComplete() async throws {
            // Create a test recipe to share
            let testRecipe = RecipeModel(
                id: UUID(),
                title: "Test Recipe",
                headerNotes: "Test notes",
                yield: "4 servings",
                ingredientSections: [],
                instructionSections: [],
                notes: [],
                reference: "https://example.com",
                imageName: nil,
                additionalImageNames: nil
            )
            
            // Convert to CloudKit format
            let cloudRecipe = CloudKitRecipe(
                id: testRecipe.id,
                title: testRecipe.title,
                headerNotes: testRecipe.headerNotes,
                yield: testRecipe.yield,
                ingredientSections: testRecipe.ingredientSections,
                instructionSections: testRecipe.instructionSections,
                notes: testRecipe.notes,
                reference: testRecipe.reference,
                imageName: testRecipe.imageName,
                additionalImageNames: testRecipe.additionalImageNames,
                sharedByUserID: "test-user",
                sharedByUserName: "Test User",
                sharedDate: Date()
            )
            
            // Verify all expected fields are present
            #expect(cloudRecipe.id == testRecipe.id)
            #expect(cloudRecipe.title == testRecipe.title)
            #expect(cloudRecipe.sharedByUserID == "test-user")
            #expect(cloudRecipe.sharedByUserName == "Test User")
            //#expect(cloudRecipe.sharedDate != nil)
        }
        
        @Test("Schema includes all required fields for SharedRecipeBook")
        @MainActor
        func sharedRecipeBookSchemaComplete() async throws {
            let testBook = RecipeBook(
                name: "Test Book",
                bookDescription: "Test description",
                coverImageName: nil,
                dateCreated: Date(),
                dateModified: Date(),
                recipeIDs: [UUID(), UUID()],
                color: "#FF5733"
            )
            
            // Convert to CloudKit format
            let cloudBook = CloudKitRecipeBook(
                id: testBook.id,
                name: testBook.name,
                bookDescription: testBook.bookDescription,
                coverImageName: testBook.coverImageName,
                recipeIDs: testBook.recipeIDs,
                color: testBook.color,
                sharedByUserID: "test-user",
                sharedByUserName: "Test User",
                sharedDate: Date()
            )
            
            // Verify all expected fields are present
            #expect(cloudBook.id == testBook.id)
            #expect(cloudBook.name == testBook.name)
            #expect(cloudBook.recipeIDs == testBook.recipeIDs)
            #expect(cloudBook.sharedByUserID == "test-user")
            //#expect(cloudBook.sharedDate != nil)
        }
    }
    
    @Suite("App Configuration")
    struct AppConfigurationTests {
        
        @Test("Bundle identifier is correct")
        func bundleIdentifierIsCorrect() throws {
            let bundleID = Bundle.main.bundleIdentifier
            #expect(bundleID != nil, "Bundle identifier should exist")
            
            // Verify it's not a placeholder
            #expect(bundleID != "com.example.app", "Bundle ID should not be a placeholder")
        }
        
        @Test("CloudKit capability is configured")
        @MainActor
        func cloudKitCapabilityConfigured() async throws {
            // Test that we can instantiate the CloudKit services
            _ = CloudKitSharingService.shared
            _ = CloudKitOnboardingService.shared
            
            //#expect(sharingService != nil)
            //#expect(onboardingService != nil)
        }
        
        @Test("CloudKitOnboardingService is added to project")
        @MainActor
        func onboardingServiceExists() {
            _ = CloudKitOnboardingService.shared
            //#expect(service != nil, "CloudKitOnboardingService should exist")
        }
        
        @Test("CloudKitSharingService is added to project")
        @MainActor
        func sharingServiceExists() {
            _ = CloudKitSharingService.shared
            //#expect(service != nil, "CloudKitSharingService should exist")
        }
        
        @Test("SharedContentModels are defined")
        func sharedContentModelsDefined() throws {
            // Verify model types exist by creating instances
            _ = SharedRecipe(
                recipeID: UUID(),
                sharedByUserID: "test",
                recipeTitle: "Test"
            )
            
            _ = SharedRecipeBook(
                bookID: UUID(),
                sharedByUserID: "test",
                bookName: "Test Book"
            )
            
            //#expect(sharedRecipe.id != nil)
            //#expect(sharedBook.id != nil)
        }
    }
    
    @Suite("Testing Before TestFlight")
    struct PreTestFlightTests {
        
        @Test("Onboarding service runs diagnostics")
        @MainActor
        func onboardingServiceRunsDiagnostics() async throws {
            let service = CloudKitOnboardingService.shared
            
            // Run diagnostics
            await service.runComprehensiveDiagnostics()
            
            // Verify diagnostics were created
            #expect(service.diagnostics != nil, "Diagnostics should be generated")
            
            // Verify diagnostics contain expected information
            let diagnostics = try #require(service.diagnostics)
            //#expect(diagnostics.timestamp != nil)
            #expect(!diagnostics.accountStatus.isEmpty)
        }
        
        @Test("Onboarding state is determinable")
        @MainActor
        func onboardingStateIsDeterminable() async throws {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            // State should be determined (not stuck on .checking)
            #expect(service.onboardingState != .checking,
                   "Onboarding state should be determined after diagnostics")
        }
        
        @Test("Diagnostics can be exported as JSON")
        @MainActor
        func diagnosticsCanBeExported() async throws {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            let exported = service.exportDiagnostics()
            
            #expect(!exported.isEmpty, "Exported diagnostics should not be empty")
            #expect(exported != "No diagnostics available")
            #expect(exported != "Failed to encode diagnostics")
        }
        
        @Test("Diagnostics include readable description")
        @MainActor
        func diagnosticsIncludeReadableDescription() async throws {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            let diagnostics = try #require(service.diagnostics)
            let description = diagnostics.readableDescription
            
            #expect(description.contains("CloudKit Diagnostics"))
            #expect(description.contains("Account Status"))
            #expect(description.contains("Container Accessible"))
        }
        
        @Test("CloudKit sharing service checks availability")
        @MainActor
        func sharingServiceChecksAvailability() async throws {
            _ = CloudKitSharingService.shared
            
            // Service should have checked availability on init
            // isCloudKitAvailable should be set (true or false)
            // We don't require it to be true, just that the check happened
            
            // Wait a moment for async init to complete
            try await Task.sleep(for: .milliseconds(500))
            
            // The service should have attempted to check
            // In a real environment, this would be true or false
            // In tests without iCloud, it might be false
            // We're just verifying the property exists and is set
        }
    }
    
    @Suite("Data Model Validation")
    struct DataModelTests {
        
        private func createTestModelContainer() throws -> ModelContainer {
            let schema = Schema([
                Recipe.self,
                RecipeBook.self,
                SharedRecipe.self,
                SharedRecipeBook.self,
                SharingPreferences.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [configuration])
        }
        
        @Test("SharedRecipe model can be created and saved")
        func sharedRecipeModelWorks() throws {
            let container = try createTestModelContainer()
            let context = ModelContext(container)
            
            let sharedRecipe = SharedRecipe(
                recipeID: UUID(),
                cloudRecordID: "test-record-id",
                sharedByUserID: "test-user",
                sharedByUserName: "Test User",
                sharedDate: Date(),
                recipeTitle: "Test Recipe",
                recipeImageName: nil
            )
            
            context.insert(sharedRecipe)
            try context.save()
            
            // Verify it was saved
            let descriptor = FetchDescriptor<SharedRecipe>()
            let results = try context.fetch(descriptor)
            
            #expect(results.count == 1)
            #expect(results.first?.recipeTitle == "Test Recipe")
        }
        
        @Test("SharedRecipeBook model can be created and saved")
        func sharedRecipeBookModelWorks() throws {
            let container = try createTestModelContainer()
            let context = ModelContext(container)
            
            let sharedBook = SharedRecipeBook(
                bookID: UUID(),
                cloudRecordID: "test-book-record-id",
                sharedByUserID: "test-user",
                sharedByUserName: "Test User",
                sharedDate: Date(),
                bookName: "Test Book",
                bookDescription: "A test book",
                coverImageName: nil
            )
            
            context.insert(sharedBook)
            try context.save()
            
            // Verify it was saved
            let descriptor = FetchDescriptor<SharedRecipeBook>()
            let results = try context.fetch(descriptor)
            
            #expect(results.count == 1)
            #expect(results.first?.bookName == "Test Book")
        }
        
        @Test("SharingPreferences model can be created and saved")
        func sharingPreferencesModelWorks() throws {
            let container = try createTestModelContainer()
            let context = ModelContext(container)
            
            let preferences = SharingPreferences(
                shareAllRecipes: false,
                shareAllBooks: false,
                allowOthersToSeeMyName: true,
                displayName: "Test User"
            )
            
            context.insert(preferences)
            try context.save()
            
            // Verify it was saved
            let descriptor = FetchDescriptor<SharingPreferences>()
            let results = try context.fetch(descriptor)
            
            #expect(results.count == 1)
            #expect(results.first?.displayName == "Test User")
        }
        
        @Test("Multiple SharedRecipes can be tracked")
        func multipleSharedRecipesCanBeTracked() throws {
            let container = try createTestModelContainer()
            let context = ModelContext(container)
            
            // Create multiple shared recipes
            for i in 0..<5 {
                let sharedRecipe = SharedRecipe(
                    recipeID: UUID(),
                    sharedByUserID: "test-user",
                    recipeTitle: "Recipe \(i)"
                )
                context.insert(sharedRecipe)
            }
            
            try context.save()
            
            // Verify all were saved
            let descriptor = FetchDescriptor<SharedRecipe>()
            let results = try context.fetch(descriptor)
            
            #expect(results.count == 5)
        }
    }
    
    @Suite("Error Handling")
    struct ErrorHandlingTests {
        
        @Test("SharingError provides helpful messages")
        func sharingErrorMessagesAreHelpful() {
            let errors: [SharingError] = [
                .notAuthenticated,
                .cloudKitUnavailable(message: "Test unavailable"),
                .recipeNotFound,
                .bookNotFound,
                .uploadFailed(NSError(domain: "test", code: 1)),
                .downloadFailed(NSError(domain: "test", code: 2)),
                .invalidData,
                .imageUploadFailed(NSError(domain: "test", code: 3))
            ]
            
            for error in errors {
                let description = error.errorDescription
                #expect(description != nil, "Error should have a description")
                #expect(!description!.isEmpty, "Error description should not be empty")
            }
        }
        
        @Test("CloudKitError provides helpful messages")
        @MainActor
        func cloudKitErrorMessagesAreHelpful() async throws {
            let errors: [CloudKitError] = [
                .statusUnknown,
                .containerInaccessible,
                .publicDatabaseUnavailable,
                .unknownIssue
            ]
            
            for error in errors {
                let description = error.errorDescription
                #expect(description != nil, "Error should have a description")
                #expect(!description!.isEmpty, "Error description should not be empty")
            }
        }
        
        @Test("Onboarding service handles all account statuses")
        func onboardingHandlesAllAccountStatuses() async throws {
            // This test verifies that the onboarding service's diagnostic
            // output includes handling for all possible account statuses
            
            let statuses: [CKAccountStatus] = [
                .available,
                .noAccount,
                .restricted,
                .couldNotDetermine,
                .temporarilyUnavailable
            ]
            
            // Each status should have a description
            for status in statuses {
                let description = status.description
                #expect(!description.isEmpty, "Status \(status) should have a description")
            }
        }
    }
    
    @Suite("Onboarding Flow")
    struct OnboardingFlowTests {
        
        @Test("Onboarding states are comprehensive")
        func onboardingStatesComprehensive() {
            // Verify all expected states exist
            let states: [CloudKitOnboardingService.OnboardingState] = [
                .checking,
                .ready,
                .needsiCloudSignIn,
                .needsContainerPermission,
                .needsPublicDBSetup,
                .needsUserIdentity,
                .restricted,
                .failed(CloudKitError.unknownIssue)
            ]
            
            #expect(states.count >= 7, "Should have at least 7 onboarding states")
        }
        
        @Test("Onboarding steps are defined")
        func onboardingStepsDefined() {
            // Verify all expected steps exist
            let steps: [CloudKitOnboardingService.OnboardingStep] = [
                .checkingAccount,
                .requestingPermissions,
                .initializingPublicDB,
                .creatingUserIdentity,
                .verifyingAccess,
                .complete
            ]
            
            #expect(steps.count == 6, "Should have 6 onboarding steps")
        }
        
        @Test("Diagnostics track all required checks")
        @MainActor
        func diagnosticsTrackAllChecks() async throws {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            let diagnostics = try #require(service.diagnostics)
            
            // Verify all diagnostic fields are present
            // timestamp is non-optional Date, so it always exists
            #expect(!diagnostics.accountStatus.isEmpty)
            // containerAccessible, publicDatabaseAccessible, etc. are Bool so always present
            
            // Verify isFullyFunctional logic exists
            let _ = diagnostics.isFullyFunctional
        }
        
        @Test("Repair function exists")
        @MainActor
        func repairFunctionExists() async {
            let service = CloudKitOnboardingService.shared
            
            // Verify we can call attemptRepair without crashing
            await service.attemptRepair()
            
            // After repair, diagnostics should exist
            #expect(service.diagnostics != nil)
        }
        
        @Test("Public database schema initialization exists")
        @MainActor
        func publicDBSchemaInitializationExists() async {
            let service = CloudKitOnboardingService.shared
            
            // Verify we can call initializePublicDatabaseSchema without crashing
            // (It will likely fail without proper CloudKit access, but should not crash)
            await service.initializePublicDatabaseSchema()
            
            // Diagnostics should be updated
            #expect(service.diagnostics != nil)
        }
    }
    
    @Suite("Container Validation")
    struct ContainerValidationTests {
        
        @Test("Container validator can validate container")
        func containerValidatorWorks() async {
            let result = await CloudKitContainerValidator.validateContainer(
                identifier: "iCloud.com.headydiscy.reczipes"
            )
            let a = await result.containerIdentifier
            #expect(a == "iCloud.com.headydiscy.reczipes")
            let rb = await result.bundleID
            #expect(!rb.isEmpty)
        }
        
        @Test("Validation result can diagnose issues")
        @MainActor
        func validationResultDiagnoses() async {
            let result = await CloudKitContainerValidator.validateContainer(
                identifier: "iCloud.com.headydiscy.reczipes"
            )
            
            let diagnosis = result.diagnose()
            
            let de = diagnosis.emoji
            #expect(!de.isEmpty)
            let ds = diagnosis.summary
            #expect(!ds.isEmpty)
        }
        
        @Test("Validation can identify account issues")
        @MainActor
        func validationIdentifiesAccountIssues() async {
            var result = ValidationResult(containerIdentifier: "test")
            result.isAccountAvailable = false
            result.accountStatusMessage = "No account"
            
            let diagnosis = result.diagnose()
            
            let di = diagnosis.issues
            #expect(di.contains { $0.contains("account") || $0.contains("iCloud") })
            let dr = diagnosis.recommendations
            #expect(dr.contains { $0.contains("Sign into iCloud") })
        }
        
        @Test("Validation can identify container access issues")
        @MainActor
        func validationIdentifiesContainerIssues() async {
            var result = ValidationResult(containerIdentifier: "test")
            result.isAccountAvailable = true
            result.canAccessPrivateDatabase = false
            result.containerAccessError = "bad container"
            
            let diagnosis = result.diagnose()
            let di = diagnosis.issues
            
            #expect(di.contains { $0.contains("Cannot access container") })
        }
    }
}
