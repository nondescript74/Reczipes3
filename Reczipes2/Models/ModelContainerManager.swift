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
        // IMPORTANT: Start with local-only container to avoid blocking initialization
        // We'll check CloudKit asynchronously and upgrade if available
        print("🚀 ModelContainerManager initializing...")
        print("   Starting with local-only container, will check CloudKit availability async")
        
        let (container, cloudKitEnabled) = Self.createModelContainer(forceCloudKit: false)
        self.container = container
        self.isCloudKitEnabled = cloudKitEnabled
        
        // Monitor CloudKit account changes
        setupAccountMonitoring()
        
        // Check CloudKit status after initialization and upgrade if available
        Task {
            await checkAndUpgradeToCloudKitIfAvailable()
        }
    }
    
    deinit {
        if let observer = accountStatusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Container Creation
    
    private static func createModelContainer(forceCloudKit: Bool? = nil) -> (ModelContainer, Bool) {
        // Log schema version information
        print("🚀 STARTING MODEL CONTAINER INITIALIZATION")
        print("   Schema Version: \(SchemaVersionManager.versionString(SchemaVersionManager.currentVersion))")
        SchemaVersionManager.logSchemaInfo()
        
        // Use the forced CloudKit setting
        let shouldUseCloudKit = forceCloudKit ?? false
        
        if shouldUseCloudKit {
            print("📦 Creating container with CloudKit enabled")
            // Try CloudKit configuration
            if let container = tryCreateCloudKitContainer() {
                return (container, true)
            }
            print("⚠️ CloudKit container creation failed, falling back to local-only")
        } else {
            print("📦 Creating local-only container (CloudKit will be checked asynchronously)")
        }
        
        // Fall back to local-only configuration
        return (createLocalContainer(), false)
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
        // CRITICAL: Use the same database file as CloudKit config to preserve data!
        let cloudKitURL = URL.applicationSupportDirectory.appending(path: "CloudKitModel.sqlite")
        let localConfiguration = ModelConfiguration(
            url: cloudKitURL  // Use same database file, CloudKit disabled by not specifying cloudKitDatabase
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
            print("   Using existing database: CloudKitModel.sqlite")
            print("   Your data is preserved even though CloudKit is disabled")
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
    
    private func checkAndUpgradeToCloudKitIfAvailable() async {
        // Wait a moment for app to fully launch
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Check if CloudKit is available
        let cloudKitAvailable = await checkCurrentCloudKitStatus()
        
        print("🔍 Post-initialization CloudKit check:")
        print("   CloudKit available: \(cloudKitAvailable)")
        
        // If CloudKit is available, upgrade the container
        if cloudKitAvailable {
            print("✅ CloudKit is available - upgrading container to enable sync...")
            await recreateContainer(withCloudKitEnabled: true)
        } else {
            print("ℹ️ CloudKit not available - continuing with local-only storage")
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
                await recreateContainer(withCloudKitEnabled: nowAvailable)
            } else {
                print("✓ CloudKit status unchanged, no container recreation needed")
            }
        }
    }
    
    private func checkCurrentCloudKitStatus() async -> Bool {
        do {
            let status = try await CKContainer.default().accountStatus()
            let isAvailable = (status == .available)
            print("   Current CloudKit status: \(status.rawValue) (\(isAvailable ? "available" : "not available"))")
            return isAvailable
        } catch {
            print("❌ Error checking CloudKit status: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Container Recreation
    
    func recreateContainer(withCloudKitEnabled cloudKitEnabled: Bool? = nil) async {
        guard !isRecreating else {
            print("⚠️ Container recreation already in progress, skipping...")
            return
        }
        
        isRecreating = true
        defer { isRecreating = false }
        
        print("🔄 Recreating ModelContainer...")
        if let enabled = cloudKitEnabled {
            print("   Target CloudKit state: \(enabled ? "enabled" : "disabled")")
        }
        
        // Determine appropriate wait time based on current container state
        let wasCloudKitEnabled = isCloudKitEnabled
        let waitTime: UInt64 = wasCloudKitEnabled ? 5_000_000_000 : 1_000_000_000 // 5s if CloudKit was on, 1s if local
        
        print("   Waiting for previous container to tear down...")
        print("   (Wait time: \(waitTime / 1_000_000_000) seconds - \(wasCloudKitEnabled ? "CloudKit cleanup needed" : "local-only, minimal wait"))")
        
        // Store reference to old container
        let oldContainer = container
        
        // Give the old container time to tear down properly
        try? await Task.sleep(nanoseconds: waitTime)
        
        // Keep reference to ensure it stays alive until now
        _ = oldContainer.schema
        
        print("   Creating new container...")
        
        // Create new container with known CloudKit state if provided
        let (newContainer, actualCloudKitEnabled) = Self.createModelContainer(forceCloudKit: cloudKitEnabled)
        
        // Replace the old container
        container = newContainer
        isCloudKitEnabled = actualCloudKitEnabled
        
        print("✅ ModelContainer recreated successfully")
        print("   CloudKit enabled: \(actualCloudKitEnabled)")
        
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
