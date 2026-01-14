//
//  ModelContainerManager.swift
//  Reczipes2
//
//  Created to handle dynamic ModelContainer creation and iCloud state changes
//

import Foundation
import SwiftUI
import SwiftData
import CloudKit
import Combine

/// Manages ModelContainer lifecycle and handles iCloud account changes
@MainActor
class ModelContainerManager: ObservableObject {
    static let shared = ModelContainerManager()
    
    @Published private(set) var container: ModelContainer
    @Published private(set) var isCloudKitEnabled: Bool = false
    @Published private(set) var isRecreating: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private nonisolated(unsafe) var accountStatusObserver: NSObjectProtocol?
    
    private init() {
        // Create initial container
        self.container = Self.createModelContainer()
        
        // Monitor CloudKit account changes
        setupAccountMonitoring()
    }
    
    deinit {
        if let observer = accountStatusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Container Creation
    
    private static func createModelContainer() -> ModelContainer {
        // Log schema version information
        print("🚀 STARTING MODEL CONTAINER INITIALIZATION")
        print("   Schema Version: \(SchemaVersionManager.versionString(SchemaVersionManager.currentVersion))")
        SchemaVersionManager.logSchemaInfo()
        
        // Check CloudKit availability synchronously
        let shouldUseCloudKit = checkCloudKitAvailability()
        
        if shouldUseCloudKit {
            // Try CloudKit configuration
            if let container = tryCreateCloudKitContainer() {
                return container
            }
            print("⚠️ CloudKit container creation failed, falling back to local-only")
        } else {
            print("ℹ️ CloudKit not available, using local-only storage")
        }
        
        // Fall back to local-only configuration
        return createLocalContainer()
    }
    
    private static func checkCloudKitAvailability() -> Bool {
        // Use a semaphore to make async check synchronous
        let semaphore = DispatchSemaphore(value: 0)
        var isAvailable = false
        
        Task {
            do {
                let status = try await CKContainer.default().accountStatus()
                isAvailable = (status == .available)
                print("   CloudKit account status: \(status)")
            } catch {
                print("   CloudKit check error: \(error.localizedDescription)")
                isAvailable = false
            }
            semaphore.signal()
        }
        
        // Wait with timeout
        _ = semaphore.wait(timeout: .now() + 2.0)
        return isAvailable
    }
    
    private static func tryCreateCloudKitContainer() -> ModelContainer? {
        let cloudKitURL = URL.applicationSupportDirectory.appending(path: "CloudKitModel.sqlite")
        let cloudKitConfiguration = ModelConfiguration(
            url: cloudKitURL,
            cloudKitDatabase: .private("iCloud.com.headydiscy.reczipes")
        )
        
        print("📦 Attempting to create ModelContainer with CloudKit...")
        do {
            let container = try ModelContainer(
                for: Recipe.self,
                RecipeImageAssignment.self,
                UserAllergenProfile.self,
                CachedDiabeticAnalysis.self,
                SavedLink.self,
                RecipeBook.self,
                CookingSession.self,
                migrationPlan: Reczipes2MigrationPlan.self,
                configurations: cloudKitConfiguration
            )
            print("✅ ModelContainer created successfully with CloudKit sync enabled")
            print("   Container: iCloud.com.headydiscy.reczipes")
            print("   Database: CloudKitModel.sqlite")
            return container
        } catch {
            print("❌ CloudKit ModelContainer creation failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    private static func createLocalContainer() -> ModelContainer {
        let localConfiguration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        
        do {
            let container = try ModelContainer(
                for: Recipe.self,
                RecipeImageAssignment.self,
                UserAllergenProfile.self,
                CachedDiabeticAnalysis.self,
                SavedLink.self,
                RecipeBook.self,
                CookingSession.self,
                migrationPlan: Reczipes2MigrationPlan.self,
                configurations: localConfiguration
            )
            print("✅ ModelContainer created successfully (local-only, no CloudKit sync)")
            return container
        } catch {
            print("❌ All ModelContainer initialization attempts failed")
            print("   Final error: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Account Monitoring
    
    private func setupAccountMonitoring() {
        // Listen for CKAccountChanged notifications
        accountStatusObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAccountChange()
            }
        }
    }
    
    private func handleAccountChange() {
        print("🔄 CloudKit account changed - checking if container recreation is needed...")
        
        Task {
            // Check new account status
            let wasCloudKitEnabled = isCloudKitEnabled
            let nowAvailable = await checkCurrentCloudKitStatus()
            
            // Only recreate if status actually changed
            if wasCloudKitEnabled != nowAvailable {
                print("⚠️ CloudKit availability changed: \(wasCloudKitEnabled) → \(nowAvailable)")
                print("   Recreating ModelContainer to match new iCloud state...")
                await recreateContainer()
            } else {
                print("✓ CloudKit status unchanged, no container recreation needed")
            }
        }
    }
    
    private func checkCurrentCloudKitStatus() async -> Bool {
        do {
            let status = try await CKContainer.default().accountStatus()
            isCloudKitEnabled = (status == .available)
            return isCloudKitEnabled
        } catch {
            print("❌ Error checking CloudKit status: \(error.localizedDescription)")
            isCloudKitEnabled = false
            return false
        }
    }
    
    // MARK: - Container Recreation
    
    func recreateContainer() async {
        guard !isRecreating else {
            print("⚠️ Container recreation already in progress, skipping...")
            return
        }
        
        isRecreating = true
        defer { isRecreating = false }
        
        print("🔄 Recreating ModelContainer...")
        
        // Give the system a moment to settle after account change
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Create new container
        let newContainer = Self.createModelContainer()
        
        // Replace the old container
        container = newContainer
        
        print("✅ ModelContainer recreated successfully")
        
        // Post notification so views can refresh if needed
        NotificationCenter.default.post(name: .modelContainerRecreated, object: nil)
    }
    
    /// Manually trigger container recreation (for testing or troubleshooting)
    func manuallyRecreateContainer() async {
        print("🔧 Manually recreating ModelContainer...")
        await recreateContainer()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let modelContainerRecreated = Notification.Name("modelContainerRecreated")
}
