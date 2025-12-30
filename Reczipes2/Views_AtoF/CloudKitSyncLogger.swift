//
//  CloudKitSyncLogger.swift
//  Reczipes2
//
//  Helper for logging CloudKit sync events
//

import Foundation
import SwiftData

/// Logger specifically for CloudKit sync debugging
class CloudKitSyncLogger {
    static let shared = CloudKitSyncLogger()
    
    private init() {}
    
    /// Log when a recipe is created
    func logRecipeCreated(_ recipe: Recipe) {
        print("🔵 [CloudKit Sync] Recipe created:")
        print("   ID: \(recipe.id.uuidString)")
        print("   Title: \(recipe.title)")
        print("   Date: \(recipe.dateAdded)")
        print("   Should sync to CloudKit automatically")
    }
    
    /// Log when a recipe is updated
    func logRecipeUpdated(_ recipe: Recipe) {
        print("🟡 [CloudKit Sync] Recipe updated:")
        print("   ID: \(recipe.id.uuidString)")
        print("   Title: \(recipe.title)")
        print("   Modified: \(recipe.lastModified ?? Date())")
        print("   Version: \(recipe.currentVersion)")
        print("   Should sync changes to CloudKit")
    }
    
    /// Log when a recipe is deleted
    func logRecipeDeleted(id: UUID, title: String) {
        print("🔴 [CloudKit Sync] Recipe deleted:")
        print("   ID: \(id.uuidString)")
        print("   Title: \(title)")
        print("   Should remove from CloudKit")
    }
    
    /// Log when context is saved
    func logContextSaved(itemCount: Int) {
        print("💾 [CloudKit Sync] ModelContext saved")
        print("   Changes will be synced to CloudKit")
        print("   Affected items: ~\(itemCount)")
    }
    
    /// Log sync status check
    func logSyncStatus(enabled: Bool, accountStatus: String) {
        print("📊 [CloudKit Sync] Status check:")
        print("   Sync enabled: \(enabled)")
        print("   Account status: \(accountStatus)")
    }
}

// MARK: - Extension to make logging easier

extension Recipe {
    /// Log this recipe's creation
    func logCreation() {
        CloudKitSyncLogger.shared.logRecipeCreated(self)
    }
    
    /// Log this recipe's update
    func logUpdate() {
        CloudKitSyncLogger.shared.logRecipeUpdated(self)
    }
}
