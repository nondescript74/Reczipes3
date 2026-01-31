//
//  CloudKitSyncLogger.swift
//  Reczipes2
//
//  Helper for logging CloudKit sync events
//

import Foundation
import SwiftData

/// Logger specifically for CloudKit sync debugging
final class CloudKitSyncLogger: Sendable {
    static let shared = CloudKitSyncLogger()
    
    private init() {}
    
    /// Log when a recipe is created
    nonisolated func logRecipeCreated(_ recipe: RecipeX) {
        print("🔵 [CloudKit Sync] RecipeX created:")
        print("   ID: \(recipe.id!.uuidString)")
        print("   Title: \(String(describing: recipe.title))")
        print("   Date: \(String(describing: recipe.dateAdded))")
        print("   Should sync to CloudKit automatically")
    }
    
    /// Log when a recipe is updated
    nonisolated func logRecipeUpdated(_ recipe: RecipeX) {
        print("🟡 [CloudKit Sync] RecipeX updated:")
        print("   ID: \(recipe.id!.uuidString)")
        print("   Title: \(String(describing: recipe.title))")
        print("   Modified: \(recipe.lastModified ?? Date())")
        print("   Version: \(recipe.currentVersion)")
        print("   Should sync changes to CloudKit")
    }
    
    /// Log when a recipe is deleted
    nonisolated func logRecipeDeleted(id: UUID, title: String) {
        print("🔴 [CloudKit Sync] RecipeX deleted:")
        print("   ID: \(id.uuidString)")
        print("   Title: \(title)")
        print("   Should remove from CloudKit")
    }
    
    /// Log when context is saved
    nonisolated func logContextSaved(itemCount: Int) {
        print("💾 [CloudKit Sync] ModelContext saved")
        print("   Changes will be synced to CloudKit")
        print("   Affected items: ~\(itemCount)")
    }
    
    /// Log sync status check
    nonisolated func logSyncStatus(enabled: Bool, accountStatus: String) {
        print("📊 [CloudKit Sync] Status check:")
        print("   Sync enabled: \(enabled)")
        print("   Account status: \(accountStatus)")
    }
}

