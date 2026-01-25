//
//  CloudKitDuplicateMonitor.swift
//  Reczipes2
//
//  Monitor CloudKit sync events and trigger deduplication when needed
//  Created for preventing duplicate recipes during sync token expiry
//

import Foundation
import SwiftData
import Combine

@MainActor
class CloudKitDuplicateMonitor: ObservableObject {
    static let shared = CloudKitDuplicateMonitor()
    
    @Published var isSyncing = false
    @Published var lastSyncReset: Date?
    @Published var duplicatesDetected = 0
    
    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?
    
    private init() {
        setupNotifications()
    }
    
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - CloudKit Notifications
    
    private func setupNotifications() {
        // Notification when CloudKit sync will reset (token expired)
        NotificationCenter.default.publisher(for: NSNotification.Name("NSCloudKitMirroringDelegateWillResetSyncNotificationName"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleSyncWillReset(notification)
            }
            .store(in: &cancellables)
        
        // Notification when CloudKit sync did reset
        NotificationCenter.default.publisher(for: NSNotification.Name("NSCloudKitMirroringDelegateDidResetSyncNotificationName"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleSyncDidReset(notification)
            }
            .store(in: &cancellables)
        
        // Import started
        NotificationCenter.default.publisher(for: NSNotification.Name("NSCloudKitMirroringDelegateImportDidStart"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isSyncing = true
                logInfo("☁️ CloudKit import started", category: "cloudkit")
            }
            .store(in: &cancellables)
        
        // Import finished
        NotificationCenter.default.publisher(for: NSNotification.Name("NSCloudKitMirroringDelegateImportDidFinish"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleImportFinished(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleSyncWillReset(_ notification: Notification) {
        logWarning("⚠️ CloudKit sync will reset - change token expired", category: "cloudkit")
        logWarning("⚠️ This may cause duplicate recipes to be synced", category: "cloudkit")
        
        // Log the reason if available
        if let userInfo = notification.userInfo,
           let reason = userInfo["reason"] as? String {
            logWarning("⚠️ Reason: \(reason)", category: "cloudkit")
        }
        
        isSyncing = true
    }
    
    private func handleSyncDidReset(_ notification: Notification) {
        logInfo("✅ CloudKit sync reset complete", category: "cloudkit")
        lastSyncReset = Date()
        
        // Schedule duplicate detection after a delay to let sync finish
        Task {
            try? await Task.sleep(for: .seconds(5))
            await checkForDuplicates()
        }
    }
    
    private func handleImportFinished(_ notification: Notification) {
        logInfo("✅ CloudKit import finished", category: "cloudkit")
        isSyncing = false
        
        // Check if there was an error
        if let userInfo = notification.userInfo,
           let error = userInfo[NSUnderlyingErrorKey] as? Error {
            logError("❌ Import finished with error: \(error.localizedDescription)", category: "cloudkit")
        }
        
        // Run duplicate check after import
        Task {
            await checkForDuplicates()
        }
    }
    
    // MARK: - Duplicate Detection
    
    func checkForDuplicates() async {
        guard let context = modelContext else {
            logWarning("⚠️ ModelContext not configured for duplicate detection", category: "cloudkit")
            return
        }
        
        logInfo("🔍 Checking for duplicates after sync...", category: "cloudkit")
        
        do {
            let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.title)])
            let allRecipes = try context.fetch(descriptor)
            
            logInfo("📊 Total recipes: \(allRecipes.count)", category: "cloudkit")
            
            // Group by content fingerprint
            var recipesByFingerprint: [String: [Recipe]] = [:]
            for recipe in allRecipes {
                let fingerprint = recipe.contentFingerprint
                recipesByFingerprint[fingerprint, default: []].append(recipe)
            }
            
            // Count duplicates
            let duplicateGroups = recipesByFingerprint.filter { $0.value.count > 1 }
            let totalDuplicates = duplicateGroups.reduce(0) { $0 + ($1.value.count - 1) }
            
            duplicatesDetected = totalDuplicates
            
            if totalDuplicates > 0 {
                logWarning("⚠️ Found \(duplicateGroups.count) duplicate groups containing \(totalDuplicates) extra recipes", category: "cloudkit")
                logInfo("💡 Open Settings → Duplicate Detector to clean up", category: "cloudkit")
                
                // Post notification to UI
                NotificationCenter.default.post(
                    name: NSNotification.Name("RecipeDuplicatesDetected"),
                    object: nil,
                    userInfo: ["count": totalDuplicates]
                )
            } else {
                logInfo("✅ No duplicates detected", category: "cloudkit")
            }
            
        } catch {
            logError("❌ Error checking for duplicates: \(error)", category: "cloudkit")
        }
    }
    
    // MARK: - Auto Cleanup
    
    /// Automatically clean up duplicates (USE WITH CAUTION)
    /// This will delete duplicate recipes keeping only the oldest copy
    func autoCleanupDuplicates() async {
        guard let context = modelContext else {
            logWarning("⚠️ ModelContext not configured", category: "cloudkit")
            return
        }
        
        logInfo("🧹 Starting automatic duplicate cleanup...", category: "cloudkit")
        
        do {
            let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.title)])
            let allRecipes = try context.fetch(descriptor)
            
            // Group by content fingerprint
            var recipesByFingerprint: [String: [Recipe]] = [:]
            for recipe in allRecipes {
                let fingerprint = recipe.contentFingerprint
                recipesByFingerprint[fingerprint, default: []].append(recipe)
            }
            
            // Delete duplicates
            var deletedCount = 0
            for (_, recipes) in recipesByFingerprint where recipes.count > 1 {
                // Sort by creation date, keep oldest
                let sorted = recipes.sorted { recipe1, recipe2 in
                    // Use dateAdded to determine which is oldest
                    return recipe1.dateAdded < recipe2.dateAdded
                }
                
                let canonical = sorted.first!
                let duplicates = sorted.dropFirst()
                
                logInfo("   Keeping: \(canonical.title) (ID: \(canonical.id))", category: "cloudkit")
                for duplicate in duplicates {
                    logInfo("   🗑️ Deleting duplicate: \(duplicate.id)", category: "cloudkit")
                    context.delete(duplicate)
                    deletedCount += 1
                }
            }
            
            if deletedCount > 0 {
                try context.save()
                logInfo("✅ Deleted \(deletedCount) duplicate recipes", category: "cloudkit")
                duplicatesDetected = 0
            } else {
                logInfo("✅ No duplicates to delete", category: "cloudkit")
            }
            
        } catch {
            logError("❌ Error during auto cleanup: \(error)", category: "cloudkit")
        }
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

/// View modifier to show duplicate detection alert
struct DuplicateDetectionModifier: ViewModifier {
    @StateObject private var monitor = CloudKitDuplicateMonitor.shared
    @State private var showingAlert = false
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeDuplicatesDetected"))) { notification in
                if let count = notification.userInfo?["count"] as? Int, count > 0 {
                    showingAlert = true
                }
            }
            .alert("Duplicates Detected", isPresented: $showingAlert) {
                Button("View & Clean Up", role: .none) {
                    // Navigate to duplicate detector
                    NotificationCenter.default.post(name: NSNotification.Name("ShowDuplicateDetector"), object: nil)
                }
                Button("Dismiss", role: .cancel) { }
            } message: {
                Text("Found \(monitor.duplicatesDetected) duplicate recipes after CloudKit sync. Would you like to clean them up?")
            }
    }
}

extension View {
    func monitorDuplicates() -> some View {
        modifier(DuplicateDetectionModifier())
    }
}
