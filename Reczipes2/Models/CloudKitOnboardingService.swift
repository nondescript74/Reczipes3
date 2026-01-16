//
//  CloudKitOnboardingService.swift
//  Reczipes2
//
//  Created to handle CloudKit provisioning and community sharing onboarding
//

import Foundation
import CloudKit
import SwiftUI
import Combine

/// Comprehensive CloudKit onboarding and diagnostic service
/// Detects and resolves CloudKit permission issues for community sharing
@MainActor
class CloudKitOnboardingService: ObservableObject {
    static let shared = CloudKitOnboardingService()
    
    // MARK: - Published State
    
    @Published var onboardingState: OnboardingState = .checking
    @Published var diagnostics: CloudKitDiagnostics?
    @Published var showOnboardingSheet = false
    @Published var currentStep: OnboardingStep?
    @Published var errorDetails: String?
    
    // MARK: - CloudKit References
    
    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    
    // MARK: - Onboarding States
    
    enum OnboardingState: Equatable {
        case checking
        case ready                      // All systems go
        case needsiCloudSignIn          // Not signed into iCloud
        case needsContainerPermission   // Container exists but no access
        case needsPublicDBSetup         // Public database not initialized
        case needsUserIdentity          // User record not created
        case restricted                 // CloudKit restricted (parental controls, etc.)
        case failed(Error)              // Something went wrong
        
        nonisolated static func == (lhs: OnboardingState, rhs: OnboardingState) -> Bool {
            switch (lhs, rhs) {
            case (.checking, .checking),
                 (.ready, .ready),
                 (.needsiCloudSignIn, .needsiCloudSignIn),
                 (.needsContainerPermission, .needsContainerPermission),
                 (.needsPublicDBSetup, .needsPublicDBSetup),
                 (.needsUserIdentity, .needsUserIdentity),
                 (.restricted, .restricted):
                return true
            case (.failed(let lhsError), .failed(let rhsError)):
                // Compare errors by their localized description since Error isn't Equatable
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }
    
    enum OnboardingStep {
        case checkingAccount
        case requestingPermissions
        case initializingPublicDB
        case creatingUserIdentity
        case verifyingAccess
        case complete
    }
    
    // MARK: - Diagnostics
    
    struct CloudKitDiagnostics: Codable, Sendable {
        var timestamp: Date
        var accountStatus: String
        var containerAccessible: Bool
        var publicDatabaseAccessible: Bool
        var privateDatabaseAccessible: Bool
        var userRecordID: String?
        var userDiscoverable: Bool
        var canShareToPublic: Bool
        var canReadFromPublic: Bool
        var isProductionEnvironment: Bool
        var errorMessages: [String]
        
        var isFullyFunctional: Bool {
            accountStatus == "available" &&
            containerAccessible &&
            publicDatabaseAccessible &&
            canShareToPublic &&
            canReadFromPublic
        }
        
        var readableDescription: String {
            var lines: [String] = []
            lines.append("📊 CloudKit Diagnostics")
            lines.append("━━━━━━━━━━━━━━━━━━━━")
            lines.append("🕐 Timestamp: \(timestamp.formatted())")
            lines.append("")
            lines.append("Account Status: \(accountStatus)")
            lines.append("Container Accessible: \(containerAccessible ? "✅" : "❌")")
            lines.append("Public DB Accessible: \(publicDatabaseAccessible ? "✅" : "❌")")
            lines.append("Private DB Accessible: \(privateDatabaseAccessible ? "✅" : "❌")")
            lines.append("User Record ID: \(userRecordID ?? "None")")
            lines.append("User Discoverable: \(userDiscoverable ? "✅" : "❌")")
            lines.append("Can Share Publicly: \(canShareToPublic ? "✅" : "❌")")
            lines.append("Can Read Public Content: \(canReadFromPublic ? "✅" : "❌")")
            lines.append("Environment: \(isProductionEnvironment ? "Production" : "Development")")
            
            if !errorMessages.isEmpty {
                lines.append("")
                lines.append("⚠️ Issues Detected:")
                for error in errorMessages {
                    lines.append("  • \(error)")
                }
            }
            
            lines.append("")
            lines.append("Overall Status: \(isFullyFunctional ? "✅ Ready" : "❌ Issues Found")")
            
            return lines.joined(separator: "\n")
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.headydiscy.reczipes")
        self.publicDatabase = container.publicCloudDatabase
        self.privateDatabase = container.privateCloudDatabase
        
        // Start automatic diagnostics
        Task {
            await runComprehensiveDiagnostics()
        }
    }
    
    // MARK: - Main Onboarding Flow
    
    /// Run comprehensive diagnostics and determine onboarding state
    func runComprehensiveDiagnostics() async {
        logInfo("🔍 Starting CloudKit comprehensive diagnostics...", category: "onboarding")
        
        onboardingState = .checking
        currentStep = .checkingAccount
        
        var errors: [String] = []
        var accountStatusString = "unknown"
        var containerAccessible = false
        var publicDBAccessible = false
        var privateDBAccessible = false
        var userRecordID: String?
        var userDiscoverable = false
        var canShareToPublic = false
        var canReadFromPublic = false
        
        // Step 1: Check iCloud account status
        do {
            let status = try await container.accountStatus()
            accountStatusString = status.description
            
            logInfo("   Account Status: \(accountStatusString)", category: "onboarding")
            
            switch status {
            case .available:
                // Continue to next checks
                break
                
            case .noAccount:
                onboardingState = .needsiCloudSignIn
                errors.append("No iCloud account signed in")
                logWarning("   ❌ No iCloud account", category: "onboarding")
                
            case .restricted:
                onboardingState = .restricted
                errors.append("CloudKit is restricted (check Screen Time/Parental Controls)")
                logWarning("   ❌ CloudKit restricted", category: "onboarding")
                
            case .couldNotDetermine, .temporarilyUnavailable:
                errors.append("CloudKit status could not be determined")
                onboardingState = .failed(CloudKitError.statusUnknown)
                logWarning("   ❌ Status unknown", category: "onboarding")
                
            @unknown default:
                errors.append("Unknown CloudKit status")
                onboardingState = .failed(CloudKitError.statusUnknown)
            }
            
            // Early exit if not available
            guard status == .available else {
                createDiagnostics(
                    accountStatus: accountStatusString,
                    containerAccessible: false,
                    publicDBAccessible: false,
                    privateDBAccessible: false,
                    userRecordID: nil,
                    userDiscoverable: false,
                    canShareToPublic: false,
                    canReadFromPublic: false,
                    errors: errors
                )
                return
            }
            
        } catch {
            errors.append("Failed to check account status: \(error.localizedDescription)")
            onboardingState = .failed(error)
            logError("   ❌ Account check failed: \(error)", category: "onboarding")
            createDiagnostics(
                accountStatus: "error",
                containerAccessible: false,
                publicDBAccessible: false,
                privateDBAccessible: false,
                userRecordID: nil,
                userDiscoverable: false,
                canShareToPublic: false,
                canReadFromPublic: false,
                errors: errors
            )
            return
        }
        
        // Step 2: Check container accessibility
        currentStep = .requestingPermissions
        
        do {
            // Try to fetch user record ID (this validates container access)
            let recordID = try await container.userRecordID()
            userRecordID = recordID.recordName
            containerAccessible = true
            logInfo("   ✅ Container accessible, User ID: \(recordID.recordName)", category: "onboarding")
        } catch {
            errors.append("Cannot access CloudKit container: \(error.localizedDescription)")
            containerAccessible = false
            logError("   ❌ Container inaccessible: \(error)", category: "onboarding")
        }
        
        // Step 3: Check public database access (read)
        currentStep = .initializingPublicDB
        
        canReadFromPublic = await testPublicDatabaseRead()
        if canReadFromPublic {
            publicDBAccessible = true
            logInfo("   ✅ Public database readable", category: "onboarding")
        } else {
            errors.append("Cannot read from public database")
            logWarning("   ⚠️ Public database not readable", category: "onboarding")
        }
        
        // Step 4: Check public database access (write)
        canShareToPublic = await testPublicDatabaseWrite()
        if canShareToPublic {
            logInfo("   ✅ Public database writable", category: "onboarding")
        } else {
            errors.append("Cannot write to public database")
            logWarning("   ⚠️ Public database not writable", category: "onboarding")
        }
        
        // Step 5: Check private database access
        privateDBAccessible = await testPrivateDatabaseAccess()
        if privateDBAccessible {
            logInfo("   ✅ Private database accessible", category: "onboarding")
        } else {
            errors.append("Private database not accessible")
            logWarning("   ⚠️ Private database inaccessible", category: "onboarding")
        }
        
        // Step 6: Check user identity (discoverability is automatic in iOS 17+)
        currentStep = .creatingUserIdentity
        
        // Note: As of iOS 17, user discoverability is handled automatically by CloudKit
        // when sharing. No explicit permission request is needed.
        // We'll mark as discoverable if we have a valid user record ID
        userDiscoverable = (userRecordID != nil)
        
        if userDiscoverable {
            logInfo("   ✅ User identity established", category: "onboarding")
        } else {
            logWarning("   ⚠️ User identity not available", category: "onboarding")
        }
        
        // Step 7: Determine final state
        currentStep = .verifyingAccess
        
        createDiagnostics(
            accountStatus: accountStatusString,
            containerAccessible: containerAccessible,
            publicDBAccessible: publicDBAccessible,
            privateDBAccessible: privateDBAccessible,
            userRecordID: userRecordID,
            userDiscoverable: userDiscoverable,
            canShareToPublic: canShareToPublic,
            canReadFromPublic: canReadFromPublic,
            errors: errors
        )
        
        // Determine state
        if containerAccessible && publicDBAccessible && canShareToPublic && canReadFromPublic {
            onboardingState = .ready
            currentStep = .complete
            logInfo("✅ CloudKit fully functional for community sharing!", category: "onboarding")
            logInfo("Onboarding completed: ready", category: "analytics")
        } else if !containerAccessible {
            onboardingState = .needsContainerPermission
            logWarning("⚠️ Container permission needed", category: "onboarding")
            logInfo("Onboarding completed: needsContainerPermission", category: "analytics")
        } else if !publicDBAccessible {
            onboardingState = .needsPublicDBSetup
            logWarning("⚠️ Public database setup needed", category: "onboarding")
            logInfo("Onboarding completed: needsPublicDBSetup", category: "analytics")
        } else if userRecordID == nil {
            onboardingState = .needsUserIdentity
            logWarning("⚠️ User identity creation needed", category: "onboarding")
            logInfo("Onboarding completed: needsUserIdentity", category: "analytics")
        } else {
            onboardingState = .failed(CloudKitError.unknownIssue)
            errorDetails = errors.joined(separator: "\n")
            logError("❌ CloudKit issues detected: \(errors.joined(separator: ", "))", category: "onboarding")
            logInfo("Onboarding completed: failed", category: "analytics")
        }
    }
    
    // MARK: - Database Testing
    
    private func testPublicDatabaseRead() async -> Bool {
        do {
            // Try a simple query
            let query = CKQuery(recordType: "SharedRecipe", predicate: NSPredicate(value: true))
            _ = try await publicDatabase.records(matching: query, desiredKeys: nil, resultsLimit: 1)
            return true
        } catch let error as CKError {
            // Some errors are expected if no data exists yet
            switch error.code {
            case .unknownItem, .invalidArguments:
                // These actually indicate we CAN access the database, just no data
                return true
            default:
                logError("Public DB read test failed: \(error)", category: "onboarding")
                return false
            }
        } catch {
            logError("Public DB read test failed: \(error)", category: "onboarding")
            return false
        }
    }
    
    private func testPublicDatabaseWrite() async -> Bool {
        do {
            // Create a test record
            let testRecord = CKRecord(recordType: "OnboardingTest")
            testRecord["testField"] = "onboarding_\(UUID().uuidString)" as CKRecordValue
            testRecord["timestamp"] = Date() as CKRecordValue
            
            // Try to save it
            let savedRecord = try await publicDatabase.save(testRecord)
            
            // Clean up - delete the test record
            _ = try? await publicDatabase.deleteRecord(withID: savedRecord.recordID)
            
            return true
        } catch {
            logError("Public DB write test failed: \(error)", category: "onboarding")
            return false
        }
    }
    
    private func testPrivateDatabaseAccess() async -> Bool {
        do {
            // Try a simple query
            let query = CKQuery(recordType: "Recipe", predicate: NSPredicate(value: true))
            _ = try await privateDatabase.records(matching: query, desiredKeys: nil, resultsLimit: 1)
            return true
        } catch let error as CKError {
            // Some errors are expected
            switch error.code {
            case .unknownItem, .invalidArguments:
                return true
            default:
                return false
            }
        } catch {
            return false
        }
    }
    
    // MARK: - Repair Functions
    
    /// Attempt to repair CloudKit access by forcing re-initialization
    func attemptRepair() async {
        logInfo("🔧 Attempting CloudKit repair...", category: "onboarding")
        
        currentStep = .requestingPermissions
        
        // Force request container permissions
        do {
            _ = try await container.userRecordID()
            logInfo("   ✅ Container permission refreshed", category: "onboarding")
        } catch {
            logError("   ❌ Container permission refresh failed: \(error)", category: "onboarding")
        }
        
        // Note: User discoverability is handled automatically in iOS 17+
        // No need to explicitly request permission anymore
        logInfo("   ℹ️ User discoverability is automatic in iOS 17+", category: "onboarding")
        
        // Re-run diagnostics
        await runComprehensiveDiagnostics()
    }
    
    /// Initialize public database schema (create indexes, etc.)
    func initializePublicDatabaseSchema() async {
        logInfo("🗄️ Initializing public database schema...", category: "onboarding")
        
        // Create a dummy record of each type to ensure schema exists
        let recordTypes = [
            "SharedRecipe",
            "SharedRecipeBook"
        ]
        
        for recordType in recordTypes {
            do {
                let dummyRecord = CKRecord(recordType: recordType)
                dummyRecord["initialized"] = true as CKRecordValue
                dummyRecord["timestamp"] = Date() as CKRecordValue
                
                let saved = try await publicDatabase.save(dummyRecord)
                _ = try? await publicDatabase.deleteRecord(withID: saved.recordID)
                
                logInfo("   ✅ Schema initialized for \(recordType)", category: "onboarding")
            } catch {
                logError("   ❌ Failed to initialize \(recordType): \(error)", category: "onboarding")
            }
        }
        
        // Re-run diagnostics
        await runComprehensiveDiagnostics()
    }
    
    // MARK: - Helper Functions
    
    private func createDiagnostics(
        accountStatus: String,
        containerAccessible: Bool,
        publicDBAccessible: Bool,
        privateDBAccessible: Bool,
        userRecordID: String?,
        userDiscoverable: Bool,
        canShareToPublic: Bool,
        canReadFromPublic: Bool,
        errors: [String]
    ) {
        // Detect environment
        #if DEBUG
        let isProduction = false
        #else
        let isProduction = true
        #endif
        
        diagnostics = CloudKitDiagnostics(
            timestamp: Date(),
            accountStatus: accountStatus,
            containerAccessible: containerAccessible,
            publicDatabaseAccessible: publicDBAccessible,
            privateDatabaseAccessible: privateDBAccessible,
            userRecordID: userRecordID,
            userDiscoverable: userDiscoverable,
            canShareToPublic: canShareToPublic,
            canReadFromPublic: canReadFromPublic,
            isProductionEnvironment: isProduction,
            errorMessages: errors
        )
    }
    
    /// Export diagnostics as JSON string for support tickets
    func exportDiagnostics() -> String {
        guard let diagnostics = diagnostics else {
            return "No diagnostics available"
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        guard let jsonData = try? encoder.encode(diagnostics),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "Failed to encode diagnostics"
        }
        
        return jsonString
    }
}

// MARK: - Extensions

extension CKAccountStatus {
    var description: String {
        switch self {
        case .available: return "available"
        case .noAccount: return "noAccount"
        case .restricted: return "restricted"
        case .couldNotDetermine: return "couldNotDetermine"
        case .temporarilyUnavailable: return "temporarilyUnavailable"
        @unknown default: return "unknown"
        }
    }
}

// MARK: - Errors

enum CloudKitError: LocalizedError {
    case statusUnknown
    case containerInaccessible
    case publicDatabaseUnavailable
    case unknownIssue
    
    var errorDescription: String? {
        switch self {
        case .statusUnknown:
            return "Could not determine CloudKit status"
        case .containerInaccessible:
            return "CloudKit container is not accessible"
        case .publicDatabaseUnavailable:
            return "Public database is not available"
        case .unknownIssue:
            return "An unknown CloudKit issue occurred"
        }
    }
}
