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
        logInfo("🚀 ModelContainerManager initializing...", category: "storage")
        logInfo("   Starting with local-only container for instant app launch", category: "storage")
        logInfo("   Will check CloudKit availability in background and upgrade if available", category: "storage")
        
        let (container, cloudKitEnabled) = Self.createModelContainer(forceCloudKit: false)
        self.container = container
        self.isCloudKitEnabled = cloudKitEnabled
        
        // Monitor CloudKit account changes
        setupAccountMonitoring()
        
        // Check CloudKit status after initialization and upgrade if available
        // This happens in the background and won't block the UI
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
        logInfo("🚀 STARTING MODEL CONTAINER INITIALIZATION", category: "storage")
        logInfo("   Schema Version: \(SchemaVersionManager.versionString(SchemaVersionManager.currentVersion))", category: "storage")
        SchemaVersionManager.logSchemaInfo()
        
        // Use the forced CloudKit setting
        let shouldUseCloudKit = forceCloudKit ?? false
        
        if shouldUseCloudKit {
            logInfo("📦 Creating container with CloudKit enabled", category: "storage")
            // Try CloudKit configuration
            if let container = tryCreateCloudKitContainer() {
                return (container, true)
            }
            logWarning("⚠️ CloudKit container creation failed, falling back to local-only", category: "storage")
        } else {
            logInfo("📦 Creating local-only container (CloudKit will be checked asynchronously)", category: "storage")
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
        
        logInfo("📦 Attempting to create ModelContainer with CloudKit...", category: "storage")
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
            logInfo("✅ ModelContainer created successfully with CloudKit sync enabled", category: "storage")
            logInfo("   Container: iCloud.com.headydiscy.reczipes", category: "storage")
            logInfo("   Database: CloudKitModel.sqlite", category: "storage")
            return container
        } catch {
            logError("❌ CloudKit ModelContainer creation failed: \(error.localizedDescription)", category: "storage")
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
            logInfo("✅ ModelContainer created successfully (local-only, no CloudKit sync)", category: "storage")
            logInfo("   Using existing database: CloudKitModel.sqlite", category: "storage")
            logInfo("   Your data is preserved even though CloudKit is disabled", category: "storage")
            return container
        } catch {
            logCritical("❌ All ModelContainer initialization attempts failed", category: "storage")
            logCritical("   Final error: \(error)", category: "storage")
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
        // Check if CloudKit is available immediately (no artificial delay)
        let cloudKitAvailable = await checkCurrentCloudKitStatus()
        
        logInfo("🔍 Post-initialization CloudKit check:", category: "storage")
        logInfo("   CloudKit available: \(cloudKitAvailable)", category: "storage")
        
        // If CloudKit is available, upgrade the container
        if cloudKitAvailable {
            logInfo("✅ CloudKit is available - upgrading container to enable sync...", category: "storage")
            await recreateContainer(withCloudKitEnabled: true)
        } else {
            logInfo("ℹ️ CloudKit not available - continuing with local-only storage", category: "storage")
        }
    }
    
    private func handleAccountChange() {
        logInfo("🔄 CloudKit account changed - checking if container recreation is needed...", category: "storage")
        
        Task {
            // Check new account status
            let wasCloudKitEnabled = isCloudKitEnabled
            let nowAvailable = await checkCurrentCloudKitStatus()
            
            // Only recreate if status actually changed
            if wasCloudKitEnabled != nowAvailable {
                logWarning("⚠️ CloudKit availability changed: \(wasCloudKitEnabled) → \(nowAvailable)", category: "storage")
                logInfo("   Recreating ModelContainer to match new iCloud state...", category: "storage")
                await recreateContainer(withCloudKitEnabled: nowAvailable)
            } else {
                logInfo("✓ CloudKit status unchanged, no container recreation needed", category: "storage")
            }
        }
    }
    
    private func checkCurrentCloudKitStatus() async -> Bool {
        do {
            let status = try await CKContainer.default().accountStatus()
            let isAvailable = (status == .available)
            logInfo("   Current CloudKit status: \(status.rawValue) (\(isAvailable ? "available" : "not available"))", category: "storage")
            return isAvailable
        } catch {
            logError("❌ Error checking CloudKit status: \(error.localizedDescription)", category: "storage")
            return false
        }
    }
    
    // MARK: - Container Recreation
    
    func recreateContainer(withCloudKitEnabled cloudKitEnabled: Bool? = nil) async {
        guard !isRecreating else {
            logWarning("⚠️ Container recreation already in progress, skipping...", category: "storage")
            return
        }
        
        isRecreating = true
        defer { isRecreating = false }
        
        logInfo("🔄 Recreating ModelContainer...", category: "storage")
        if let enabled = cloudKitEnabled {
            logInfo("   Target CloudKit state: \(enabled ? "enabled" : "disabled")", category: "storage")
        }
        
        // Determine appropriate wait time based on current container state
        let wasCloudKitEnabled = isCloudKitEnabled
        let waitTime: UInt64 = wasCloudKitEnabled ? 5_000_000_000 : 1_000_000_000 // 5s if CloudKit was on, 1s if local
        
        logInfo("   Waiting for previous container to tear down...", category: "storage")
        logInfo("   (Wait time: \(waitTime / 1_000_000_000) seconds - \(wasCloudKitEnabled ? "CloudKit cleanup needed" : "local-only, minimal wait"))", category: "storage")
        
        // Store reference to old container
        let oldContainer = container
        
        // Give the old container time to tear down properly
        try? await Task.sleep(nanoseconds: waitTime)
        
        // Keep reference to ensure it stays alive until now
        _ = oldContainer.schema
        
        logInfo("   Creating new container...", category: "storage")
        
        // Create new container with known CloudKit state if provided
        let (newContainer, actualCloudKitEnabled) = Self.createModelContainer(forceCloudKit: cloudKitEnabled)
        
        // Replace the old container
        container = newContainer
        isCloudKitEnabled = actualCloudKitEnabled
        
        logInfo("✅ ModelContainer recreated successfully", category: "storage")
        logInfo("   CloudKit enabled: \(actualCloudKitEnabled)", category: "storage")
        
        // Post notification so views can refresh if needed
        NotificationCenter.default.post(name: .modelContainerRecreated, object: nil)
    }
    
    /// Manually trigger container recreation (for testing or troubleshooting)
    func manuallyRecreateContainer() async {
        logInfo("🔧 Manually recreating ModelContainer...", category: "storage")
        await recreateContainer()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let modelContainerRecreated = Notification.Name("modelContainerRecreated")
}
