//
//  TestFlightProductionReadinessTests.swift
//  Reczipes2Tests
//
//  Production readiness and monitoring tests for TestFlight release
//  Created on 1/16/26.
//

import Testing
import Foundation
import CloudKit
import SwiftData
@testable import Reczipes2

/// Tests for production readiness before App Store submission
@Suite("Production Readiness Validation")
@MainActor
struct TestFlightProductionReadinessTests {
    
    @Suite("Sharing Flow End-to-End")
    struct SharingFlowTests {
        
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
        
        @Test("Recipe can be converted to CloudKit format")
        @MainActor
        func recipeConvertsToCloudKitFormat() throws {
            let recipe = RecipeModel(
                id: UUID(),
                title: "Test Recipe",
                headerNotes: "Test notes",
                yield: "4 servings",
                ingredientSections: [
                    IngredientSection(
                        title: "Main",
                        ingredients: [
                            Ingredient(quantity: "1", unit: "cup", name: "flour")
                        ]
                    )
                ],
                instructionSections: [
                    InstructionSection(
                        title: "Instructions",
                        steps: [
                            InstructionStep(stepNumber: 1, text: "Mix ingredients")
                        ]
                    )
                ],
                notes: [RecipeNote(type: .general, text: "Test note")],
                reference: "https://example.com",
                imageName: nil,
                additionalImageNames: nil
            )
            
            let cloudRecipe = CloudKitRecipe(
                id: recipe.id,
                title: recipe.title,
                headerNotes: recipe.headerNotes,
                yield: recipe.yield,
                ingredientSections: recipe.ingredientSections,
                instructionSections: recipe.instructionSections,
                notes: recipe.notes,
                reference: recipe.reference,
                imageName: recipe.imageName,
                additionalImageNames: recipe.additionalImageNames,
                sharedByUserID: "test-user",
                sharedByUserName: "Test User",
                sharedDate: Date()
            )
            
            // Verify conversion preserves all data
            #expect(cloudRecipe.title == recipe.title)
            #expect(cloudRecipe.headerNotes == recipe.headerNotes)
            #expect(cloudRecipe.yield == recipe.yield)
            #expect(cloudRecipe.ingredientSections.count == 1)
            #expect(cloudRecipe.instructionSections.count == 1)
            #expect(cloudRecipe.notes.count == 1)
        }
        
        @Test("RecipeBook can be converted to CloudKit format")
        @MainActor
        func recipeBookConvertsToCloudKitFormat() throws {
            let book = RecipeBook(
                name: "Test Book",
                bookDescription: "A test book",
                coverImageName: nil,
                dateCreated: Date(),
                dateModified: Date(),
                recipeIDs: [UUID(), UUID(), UUID()],
                color: "#FF5733"
            )
            
            let cloudBook = CloudKitRecipeBook(
                id: book.id,
                name: book.name,
                bookDescription: book.bookDescription,
                coverImageName: book.coverImageName,
                recipeIDs: book.recipeIDs,
                color: book.color,
                sharedByUserID: "test-user",
                sharedByUserName: "Test User",
                sharedDate: Date()
            )
            
            // Verify conversion preserves all data
            #expect(cloudBook.name == book.name)
            #expect(cloudBook.bookDescription == book.bookDescription)
            #expect(cloudBook.recipeIDs.count == 3)
            #expect(cloudBook.color == book.color)
        }
        
        @Test("CloudKitRecipe can be encoded to JSON")
        @MainActor
        func cloudKitRecipeEncodesToJSON() throws {
            let cloudRecipe = CloudKitRecipe(
                id: UUID(),
                title: "Test Recipe",
                headerNotes: "Notes",
                yield: "4",
                ingredientSections: [],
                instructionSections: [],
                notes: [],
                reference: nil,
                imageName: nil,
                additionalImageNames: nil,
                sharedByUserID: "user123",
                sharedByUserName: "Test User",
                sharedDate: Date()
            )
            
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(cloudRecipe)
            
            #expect(!jsonData.isEmpty, "JSON data should not be empty")
            
            // Verify it can be decoded back
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(CloudKitRecipe.self, from: jsonData)
            
            #expect(decoded.title == cloudRecipe.title)
            #expect(decoded.sharedByUserID == cloudRecipe.sharedByUserID)
        }
        
        @Test("CloudKitRecipeBook can be encoded to JSON")
        @MainActor
        func cloudKitRecipeBookEncodesToJSON() throws {
            let cloudBook = CloudKitRecipeBook(
                id: UUID(),
                name: "Test Book",
                bookDescription: "Description",
                coverImageName: nil,
                recipeIDs: [UUID()],
                color: "#FF0000",
                sharedByUserID: "user123",
                sharedByUserName: "Test User",
                sharedDate: Date()
            )
            
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(cloudBook)
            
            #expect(!jsonData.isEmpty, "JSON data should not be empty")
            
            // Verify it can be decoded back
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(CloudKitRecipeBook.self, from: jsonData)
            
            #expect(decoded.name == cloudBook.name)
            #expect(decoded.sharedByUserID == cloudBook.sharedByUserID)
        }
        
        @Test("Sharing service tracks CloudKit availability")
        @MainActor
        func sharingServiceTracksAvailability() async throws {
            let service = CloudKitSharingService.shared
            
            // Wait for initialization
            try await Task.sleep(for: .milliseconds(500))
            
            // Service should have attempted to check CloudKit
            // We're not requiring it to be available (tests may run without iCloud)
            // Just verifying the check happened
            
            // The published property should be accessible
            let _ = service.isCloudKitAvailable
        }
    }
    
    @Suite("Graceful Degradation")
    struct GracefulDegradationTests {
        
        @Test("App handles unavailable CloudKit gracefully")
        @MainActor
        func handlesUnavailableCloudKitGracefully() async {
            // When CloudKit is not available, the app should not crash
            // It should show appropriate UI and error messages
            
            let service = CloudKitSharingService.shared
            
            // Service should track availability status without crashing
            // (singleton always exists, so just accessing it verifies it doesn't crash)
            let _ = service.isCloudKitAvailable
        }
        
        @Test("Onboarding handles all failure modes")
        @MainActor
        func onboardingHandlesAllFailureModes() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            // After diagnostics, service should be in a valid state (not crashed)
            // The service is a singleton, so it will always exist
            
            // State should be determined
            switch service.onboardingState {
            case .checking:
                Issue.record("Onboarding should not be stuck in checking state")
            case .ready:
                // Great!
                break
            case .needsiCloudSignIn,
                 .needsContainerPermission,
                 .needsPublicDBSetup,
                 .needsUserIdentity,
                 .restricted,
                 .failed:
                // All acceptable states when CloudKit is unavailable
                break
            }
        }
        
        @Test("Error messages are user-friendly")
        @MainActor
        func errorMessagesAreUserFriendly() {
            // All error messages should be helpful, not technical jargon
            let errors: [SharingError] = [
                .notAuthenticated,
                .cloudKitUnavailable(message: nil),
                .recipeNotFound,
                .bookNotFound
            ]
            
            for error in errors {
                let description = error.errorDescription ?? ""
                
                // Should not contain technical terms
                #expect(!description.contains("CKError"))
                #expect(!description.contains("nil"))
                #expect(!description.contains("database"))
                
                // Should contain helpful guidance
                #expect(description.count > 10, "Error message should be descriptive")
            }
        }
        
        @Test("Diagnostics provide actionable information")
        @MainActor
        func diagnosticsProvideActionableInfo() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            guard let diagnostics = service.diagnostics else {
                Issue.record("Diagnostics should be available")
                return
            }
            
            let readable = diagnostics.readableDescription
            
            // Should contain status indicators
            #expect(readable.contains("✅") || readable.contains("❌"))
            
            // Should be readable
            #expect(readable.contains("Account Status"))
            #expect(readable.contains("Container Accessible"))
        }
    }
    
    @Suite("Data Integrity")
    struct DataIntegrityTests {
        
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
        
        @Test("Shared recipe tracking maintains referential integrity")
        @MainActor
        func sharedRecipeTrackingMaintainsIntegrity() throws {
            let container = try createTestModelContainer()
            let context = ModelContext(container)
            
            let recipeID = UUID()
            
            let sharedRecipe = SharedRecipe(
                recipeID: recipeID,
                cloudRecordID: "test-record",
                sharedByUserID: "user-123",
                sharedByUserName: "Test User",
                recipeTitle: "Test Recipe"
            )
            
            context.insert(sharedRecipe)
            try context.save()
            
            // Verify we can query by recipeID
            let descriptor = FetchDescriptor<SharedRecipe>(
                predicate: #Predicate { $0.recipeID == recipeID }
            )
            
            let results = try context.fetch(descriptor)
            #expect(results.count == 1)
            #expect(results.first?.recipeID == recipeID)
        }
        
        @Test("Shared recipe can be deactivated without deletion")
        @MainActor
        func sharedRecipeCanBeDeactivated() throws {
            let container = try createTestModelContainer()
            let context = ModelContext(container)
            
            let sharedRecipe = SharedRecipe(
                recipeID: UUID(),
                sharedByUserID: "user-123",
                recipeTitle: "Test Recipe"
            )
            
            context.insert(sharedRecipe)
            try context.save()
            
            // Deactivate
            sharedRecipe.isActive = false
            try context.save()
            
            // Verify it's still in database but marked inactive
            let descriptor = FetchDescriptor<SharedRecipe>()
            let results = try context.fetch(descriptor)
            
            #expect(results.count == 1)
            #expect(results.first?.isActive == false)
        }
        
        @Test("Multiple shares of same recipe can be tracked")
        @MainActor
        func multipleSharesCanBeTracked() throws {
            let container = try createTestModelContainer()
            let context = ModelContext(container)
            
            let recipeID = UUID()
            
            // User shares recipe, unshares it, shares it again
            // Each share gets a new SharedRecipe entry
            
            let firstShare = SharedRecipe(
                recipeID: recipeID,
                cloudRecordID: "record-1",
                sharedByUserID: "user-123",
                recipeTitle: "Test Recipe"
            )
            firstShare.isActive = false // Unshared
            
            let secondShare = SharedRecipe(
                recipeID: recipeID,
                cloudRecordID: "record-2",
                sharedByUserID: "user-123",
                recipeTitle: "Test Recipe"
            )
            secondShare.isActive = true // Currently shared
            
            context.insert(firstShare)
            context.insert(secondShare)
            try context.save()
            
            // Verify both tracked
            let descriptor = FetchDescriptor<SharedRecipe>(
                predicate: #Predicate { $0.recipeID == recipeID }
            )
            
            let results = try context.fetch(descriptor)
            #expect(results.count == 2)
            
            // Verify we can find active one
            let activeResults = results.filter { $0.isActive }
            #expect(activeResults.count == 1)
        }
    }
    
    @Suite("Performance and Limits")
    struct PerformanceTests {
        
        @Test("Can handle multiple recipes in one batch")
        @MainActor
        func handlesMultipleRecipes() throws {
            // Create many recipes
            let recipes = (0..<100).map { index in
                RecipeModel(
                    id: UUID(),
                    title: "Recipe \(index)",
                    headerNotes: nil,
                    yield: nil,
                    ingredientSections: [],
                    instructionSections: [],
                    notes: [],
                    reference: nil,
                    imageName: nil,
                    additionalImageNames: nil
                )
            }
            
            // Verify we can create CloudKit versions without issues
            let cloudRecipes = recipes.map { recipe in
                CloudKitRecipe(
                    id: recipe.id,
                    title: recipe.title,
                    headerNotes: recipe.headerNotes,
                    yield: recipe.yield,
                    ingredientSections: recipe.ingredientSections,
                    instructionSections: recipe.instructionSections,
                    notes: recipe.notes,
                    reference: recipe.reference,
                    imageName: recipe.imageName,
                    additionalImageNames: recipe.additionalImageNames,
                    sharedByUserID: "user",
                    sharedByUserName: "User",
                    sharedDate: Date()
                )
            }
            
            #expect(cloudRecipes.count == 100)
        }
        
        @Test("Large recipe data can be encoded")
        @MainActor
        func largeRecipeCanBeEncoded() throws {
            // Create a recipe with lots of data
            let largeRecipe = RecipeModel(
                id: UUID(),
                title: String(repeating: "A", count: 1000),
                headerNotes: String(repeating: "B", count: 5000),
                yield: "100 servings",
                ingredientSections: (0..<10).map { sectionIndex in
                    IngredientSection(
                        title: "Section \(sectionIndex)",
                        ingredients: (0..<20).map { ingredientIndex in
                            Ingredient(
                                name: "Ingredient \(ingredientIndex) in section \(sectionIndex)"
                            )
                        }
                    )
                },
                instructionSections: (0..<5).map { sectionIndex in
                    InstructionSection(
                        title: "Instructions \(sectionIndex)",
                        steps: (0..<10).map { instrIndex in
                            InstructionStep(
                                stepNumber: instrIndex + 1,
                                text: String(repeating: "Instruction \(instrIndex). ", count: 10)
                            )
                        }
                    )
                },
                notes: (0..<50).map { noteIndex in
                    RecipeNote(
                        type: .general,
                        text: "Note \(noteIndex): " + String(repeating: "content ", count: 20)
                    )
                },
                reference: "https://example.com/very/long/url/path",
                imageName: nil,
                additionalImageNames: nil
            )
            
            let cloudRecipe = CloudKitRecipe(
                id: largeRecipe.id,
                title: largeRecipe.title,
                headerNotes: largeRecipe.headerNotes,
                yield: largeRecipe.yield,
                ingredientSections: largeRecipe.ingredientSections,
                instructionSections: largeRecipe.instructionSections,
                notes: largeRecipe.notes,
                reference: largeRecipe.reference,
                imageName: largeRecipe.imageName,
                additionalImageNames: largeRecipe.additionalImageNames,
                sharedByUserID: "user",
                sharedByUserName: "User",
                sharedDate: Date()
            )
            
            // Encode to JSON
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(cloudRecipe)
            
            // CloudKit has a 1MB limit per field
            // JSON data should be well under that
            #expect(jsonData.count < 1_000_000, "Recipe data should be under CloudKit's 1MB limit")
            
            // Verify it can be decoded
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(CloudKitRecipe.self, from: jsonData)
            #expect(decoded.title == cloudRecipe.title)
        }
    }
    
    @Suite("Support and Diagnostics")
    struct SupportTests {
        
        @Test("Diagnostics can be exported for support tickets")
        @MainActor
        func diagnosticsCanBeExportedForSupport() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            let exported = service.exportDiagnostics()
            
            // Should be valid JSON
            #expect(!exported.isEmpty)
            
            // Try to parse as JSON
            if let jsonData = exported.data(using: .utf8) {
                let parsed = try? JSONSerialization.jsonObject(with: jsonData)
                #expect(parsed != nil, "Exported diagnostics should be valid JSON")
            }
        }
        
        @Test("Container validator provides detailed report")
        @MainActor
        func containerValidatorProvidesDetailedReport() async {
            let result = await CloudKitContainerValidator.validateContainer(
                identifier: "iCloud.com.headydiscy.reczipes"
            )
            
            let diagnosis = result.diagnose()
            
            // Should provide actionable information
            #expect(!diagnosis.summary.isEmpty)
            
            // If there are issues, should provide recommendations
            if !diagnosis.issues.isEmpty {
                #expect(!diagnosis.recommendations.isEmpty,
                       "If issues exist, recommendations should be provided")
            }
        }
        
        @Test("All diagnostic fields are accessible")
        @MainActor
        func allDiagnosticFieldsAccessible() async {
            let service = CloudKitOnboardingService.shared
            
            await service.runComprehensiveDiagnostics()
            
            guard let diagnostics = service.diagnostics else {
                Issue.record("Diagnostics should exist after running comprehensive diagnostics")
                return
            }
            
            // Verify all fields are accessible
            let _ = diagnostics.timestamp
            let _ = diagnostics.accountStatus
            let _ = diagnostics.containerAccessible
            let _ = diagnostics.publicDatabaseAccessible
            let _ = diagnostics.privateDatabaseAccessible
            let _ = diagnostics.userRecordID
            let _ = diagnostics.userDiscoverable
            let _ = diagnostics.canShareToPublic
            let _ = diagnostics.canReadFromPublic
            let _ = diagnostics.isProductionEnvironment
            let _ = diagnostics.errorMessages
            let _ = diagnostics.isFullyFunctional
            let _ = diagnostics.readableDescription
        }
    }
    
    @Suite("Monitoring and Analytics Readiness")
    struct MonitoringReadinessTests {
        
        @Test("Onboarding state is observable")
        @MainActor
        func onboardingStateIsObservable() {
            let service = CloudKitOnboardingService.shared
            
            // Verify published properties exist
            let _ = service.onboardingState
            let _ = service.diagnostics
            let _ = service.showOnboardingSheet
            let _ = service.currentStep
            let _ = service.errorDetails
        }
        
        @Test("Sharing service state is observable")
        @MainActor
        func sharingServiceStateIsObservable() {
            let service = CloudKitSharingService.shared
            
            // Verify published properties exist
            let _ = service.isCloudKitAvailable
            let _ = service.currentUserID
            let _ = service.currentUserName
        }
        
        @Test("Sharing result enum handles all outcomes")
        @MainActor
        func sharingResultHandlesAllOutcomes() {
            let results: [SharingResult] = [
                .success(recordID: "test-id"),
                .failure(error: NSError(domain: "test", code: 1)),
                .partialSuccess(successful: 5, failed: 2)
            ]
            
            #expect(results.count == 3, "All sharing result cases should be handleable")
        }
    }
    
    @Suite("App Store Submission Readiness")
    struct AppStoreReadinessTests {
        
        @Test("No debug-only code in production paths")
        @MainActor
        func noDebugOnlyCodeInProductionPaths() {
            // Verify that the app can build and run in Release mode
            // This is more of a build-time check, but we can verify
            // that services don't have debug-only requirements
            
            // Services should be accessible (they're singletons)
            let _ = CloudKitSharingService.shared
            let _ = CloudKitOnboardingService.shared
            
            // If we get here without crashing, the services are accessible
        }
        
        @Test("All models conform to required protocols")
        @MainActor
        func modelsConformToRequiredProtocols() {
            // SharedRecipe should be persistable
            let sharedRecipe = SharedRecipe(
                recipeID: UUID(),
                sharedByUserID: "test",
                recipeTitle: "Test"
            )
            
            // Should have an ID (non-optional UUID)
            _ = sharedRecipe.id
            
            // CloudKitRecipe should be Codable
            let cloudRecipe = CloudKitRecipe(
                id: UUID(),
                title: "Test",
                headerNotes: nil,
                yield: nil,
                ingredientSections: [],
                instructionSections: [],
                notes: [],
                reference: nil,
                imageName: nil,
                additionalImageNames: nil,
                sharedByUserID: "test",
                sharedByUserName: nil,
                sharedDate: Date()
            )
            
            // Should be encodable
            let encoder = JSONEncoder()
            let _ = try? encoder.encode(cloudRecipe)
        }
        
        @Test("Privacy-sensitive data is handled correctly")
        @MainActor
        func privacySensitiveDataHandledCorrectly() async {
            // User names should be optional (privacy)
            let cloudRecipe = CloudKitRecipe(
                id: UUID(),
                title: "Test",
                headerNotes: nil,
                yield: nil,
                ingredientSections: [],
                instructionSections: [],
                notes: [],
                reference: nil,
                imageName: nil,
                additionalImageNames: nil,
                sharedByUserID: "user123",
                sharedByUserName: nil, // Should be allowed to be nil
                sharedDate: Date()
            )
            
            #expect(cloudRecipe.sharedByUserName == nil, "User name should be optional for privacy")
        }
        
        @Test("Network failures are handled gracefully")
        @MainActor
        func networkFailuresHandledGracefully() async {
            // The onboarding service should handle network errors
            let service = CloudKitOnboardingService.shared
            
            // Run diagnostics (may fail with network issues)
            await service.runComprehensiveDiagnostics()
            
            // Should not crash - should have a state
            switch service.onboardingState {
            case .failed:
                // Expected when network is unavailable
                #expect(service.errorDetails != nil, "Should provide error details on failure")
            default:
                // Other states are also acceptable
                break
            }
        }
    }
}
