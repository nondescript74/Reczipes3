//
//  CloudKitContainerValidator.swift
//  Reczipes2
//
//  Validates CloudKit container configuration
//

import Foundation
import CloudKit

/// Validates CloudKit container configuration and accessibility
actor CloudKitContainerValidator {
    
    /// Comprehensive validation of a specific CloudKit container
    static func validateContainer(identifier: String) async -> ValidationResult {
        var result = ValidationResult(containerIdentifier: identifier)
        
        // 1. Check if we can create a container reference
        let container = CKContainer(identifier: identifier)
        result.canCreateReference = true
        
        // 2. Check account status
        do {
            let status = try await container.accountStatus()
            result.accountStatus = status
            result.isAccountAvailable = (status == .available)
            
            switch status {
            case .available:
                result.accountStatusMessage = "✅ iCloud account available"
            case .noAccount:
                result.accountStatusMessage = "❌ Not signed into iCloud"
            case .restricted:
                result.accountStatusMessage = "🚫 iCloud access restricted"
            case .couldNotDetermine:
                result.accountStatusMessage = "❓ Could not determine account status"
            case .temporarilyUnavailable:
                result.accountStatusMessage = "⏳ Temporarily unavailable"
            @unknown default:
                result.accountStatusMessage = "❓ Unknown status"
            }
        } catch {
            result.accountStatusError = error.localizedDescription
            result.accountStatusMessage = "❌ Error checking account: \(error.localizedDescription)"
        }
        
        // 3. Try to access the container's database
        do {
            _ = container.privateCloudDatabase
            result.canAccessPrivateDatabase = true
            
            // Try to get user record ID (proves we can communicate with CloudKit)
            let userRecordID = try await container.userRecordID()
            result.userRecordID = userRecordID.recordName
            result.canFetchUserRecord = true
            result.containerAccessMessage = "✅ Container accessible"
        } catch {
            result.containerAccessError = error.localizedDescription
            result.containerAccessMessage = "❌ Cannot access container: \(error.localizedDescription)"
            
            // Parse specific errors
            let nsError = error as NSError
            if nsError.domain == CKErrorDomain {
                switch CKError.Code(rawValue: nsError.code) {
                case .notAuthenticated:
                    result.containerAccessMessage = "❌ Not authenticated to iCloud"
                case .networkUnavailable, .networkFailure:
                    result.containerAccessMessage = "❌ Network issue - check connection"
                case .serviceUnavailable:
                    result.containerAccessMessage = "❌ CloudKit service unavailable"
                case .badContainer:
                    result.containerAccessMessage = "❌ Container identifier is invalid or doesn't exist"
                case .permissionFailure:
                    result.containerAccessMessage = "❌ Permission denied - check entitlements"
                default:
                    break
                }
            }
        }
        
        // 4. Check bundle entitlements
        result.bundleID = Bundle.main.bundleIdentifier ?? "Unknown"
        result.entitlementsCheck = checkEntitlements(for: identifier)
        
        return result
    }
    
    /// Check if entitlements include the container
    private static func checkEntitlements(for containerID: String) -> EntitlementsCheck {
        var check = EntitlementsCheck()
        
        // Check for iCloud services entitlement
        if let services = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.icloud-services") as? [String] {
            check.hasICloudServices = true
            check.iCloudServices = services
            check.hasCloudKit = services.contains("CloudKit")
        }
        
        // Check for container identifiers entitlement
        if let containers = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.icloud-container-identifiers") as? [String] {
            check.hasContainerIdentifiers = true
            check.containerIdentifiers = containers
            check.containsTargetContainer = containers.contains(containerID)
        }
        
        // Check for ubiquity container identifiers (for iCloud Drive)
        if let ubiquityContainers = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.ubiquity-container-identifiers") as? [String] {
            check.ubiquityContainers = ubiquityContainers
        }
        
        return check
    }
    
    /// Print detailed validation report
    @MainActor static func printValidationReport(_ result: ValidationResult) {
        print("\n" + String(repeating: "=", count: 70))
        print("☁️  CLOUDKIT CONTAINER VALIDATION REPORT")
        print(String(repeating: "=", count: 70))
        
        print("\n📦 CONTAINER INFORMATION:")
        print("   Container ID: \(result.containerIdentifier)")
        print("   Bundle ID: \(result.bundleID)")
        print("   Can Create Reference: \(result.canCreateReference ? "✅" : "❌")")
        
        print("\n👤 ICLOUD ACCOUNT:")
        print("   \(result.accountStatusMessage)")
        if let error = result.accountStatusError {
            print("   Error: \(error)")
        }
        
        print("\n🗄️  CONTAINER ACCESS:")
        print("   \(result.containerAccessMessage)")
        if result.canAccessPrivateDatabase {
            print("   Private Database: ✅ Accessible")
        }
        if let userID = result.userRecordID {
            print("   User Record ID: \(userID)")
        }
        if let error = result.containerAccessError {
            print("   Error: \(error)")
        }
        
        print("\n🔐 ENTITLEMENTS CHECK:")
        let entitlements = result.entitlementsCheck
        print("   iCloud Services: \(entitlements.hasICloudServices ? "✅" : "❌")")
        if entitlements.hasICloudServices {
            print("      Services: \(entitlements.iCloudServices.joined(separator: ", "))")
        }
        print("   CloudKit Enabled: \(entitlements.hasCloudKit ? "✅" : "❌")")
        print("   Container Identifiers: \(entitlements.hasContainerIdentifiers ? "✅" : "❌")")
        if entitlements.hasContainerIdentifiers {
            print("      Containers:")
            for container in entitlements.containerIdentifiers {
                let marker = container == result.containerIdentifier ? "  ➜" : "   "
                print("\(marker) \(container)")
            }
        }
        print("   Target Container Listed: \(entitlements.containsTargetContainer ? "✅" : "❌")")
        
        print("\n🔍 DIAGNOSIS:")
        let diagnosis = result.diagnose()
        print("   \(diagnosis.emoji) \(diagnosis.summary)")
        
        if !diagnosis.issues.isEmpty {
            print("\n⚠️  ISSUES FOUND:")
            for (index, issue) in diagnosis.issues.enumerated() {
                print("   \(index + 1). \(issue)")
            }
        }
        
        if !diagnosis.recommendations.isEmpty {
            print("\n💡 RECOMMENDATIONS:")
            for (index, recommendation) in diagnosis.recommendations.enumerated() {
                print("   \(index + 1). \(recommendation)")
            }
        }
        
        print("\n" + String(repeating: "=", count: 70) + "\n")
    }
}

// MARK: - Supporting Types

struct ValidationResult {
    let containerIdentifier: String
    var bundleID: String = "Unknown"
    
    // Container reference
    var canCreateReference: Bool = false
    
    // Account status
    var accountStatus: CKAccountStatus?
    var isAccountAvailable: Bool = false
    var accountStatusMessage: String = ""
    var accountStatusError: String?
    
    // Container access
    var canAccessPrivateDatabase: Bool = false
    var canFetchUserRecord: Bool = false
    var userRecordID: String?
    var containerAccessMessage: String = ""
    var containerAccessError: String?
    
    // Entitlements
    var entitlementsCheck: EntitlementsCheck = EntitlementsCheck()
    
    func diagnose() -> Diagnosis {
        var issues: [String] = []
        var recommendations: [String] = []
        
        // Check account
        if !isAccountAvailable {
            issues.append("iCloud account not available")
            recommendations.append("Sign into iCloud in Settings app")
        }
        
        // Check entitlements
        if !entitlementsCheck.hasCloudKit {
            issues.append("CloudKit not enabled in entitlements")
            recommendations.append("Add iCloud capability with CloudKit in Xcode")
        }
        
        if !entitlementsCheck.containsTargetContainer {
            issues.append("Container '\(containerIdentifier)' not listed in entitlements")
            recommendations.append("Add '\(containerIdentifier)' to iCloud container identifiers in entitlements")
        }
        
        // Check container access
        if !canAccessPrivateDatabase {
            issues.append("Cannot access container's private database")
            if let error = containerAccessError {
                if error.contains("bad container") || error.contains("badContainer") {
                    recommendations.append("Container may not exist in Apple Developer Portal - create it or use existing container")
                } else if error.contains("permission") {
                    recommendations.append("Check that app is properly signed and entitlements are correct")
                } else {
                    recommendations.append("Check error: \(error)")
                }
            }
        }
        
        // Generate summary
        let emoji: String
        let summary: String
        
        if issues.isEmpty {
            emoji = "✅"
            summary = "All checks passed - CloudKit should work!"
        } else if issues.count == 1 {
            emoji = "⚠️"
            summary = "1 issue found: \(issues[0])"
        } else {
            emoji = "❌"
            summary = "\(issues.count) issues found"
        }
        
        return Diagnosis(emoji: emoji, summary: summary, issues: issues, recommendations: recommendations)
    }
}

struct EntitlementsCheck {
    var hasICloudServices: Bool = false
    var iCloudServices: [String] = []
    var hasCloudKit: Bool = false
    var hasContainerIdentifiers: Bool = false
    var containerIdentifiers: [String] = []
    var containsTargetContainer: Bool = false
    var ubiquityContainers: [String] = []
}

struct Diagnosis {
    let emoji: String
    let summary: String
    let issues: [String]
    let recommendations: [String]
}
