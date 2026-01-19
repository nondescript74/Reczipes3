//
//  OrphanedDataCleanupUtility.swift
//  Reczipes2
//
//  Utility for cleaning up orphaned data (image assignments, etc.)
//  Created by Zahirudeen Premji on 1/19/26.
//

import Foundation
import SwiftData

@MainActor
struct OrphanedDataCleanupUtility {
    
    /// Clean up orphaned RecipeImageAssignments (assignments without matching recipes)
    static func cleanupOrphanedImageAssignments(context: ModelContext) async throws {
        print("🧹 Cleaning up orphaned image assignments...")
        
        // Fetch all recipes and assignments
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let assignmentDescriptor = FetchDescriptor<RecipeImageAssignment>()
        
        let recipes = try context.fetch(recipeDescriptor)
        let assignments = try context.fetch(assignmentDescriptor)
        
        print("📊 Found \(recipes.count) recipes and \(assignments.count) image assignments")
        
        // Build set of valid recipe IDs
        let validRecipeIDs = Set(recipes.map { $0.id })
        
        // Find orphaned assignments
        let orphanedAssignments = assignments.filter { assignment in
            !validRecipeIDs.contains(assignment.recipeID)
        }
        
        if orphanedAssignments.isEmpty {
            print("✅ No orphaned image assignments found")
            return
        }
        
        print("⚠️ Found \(orphanedAssignments.count) orphaned image assignments")
        
        // Delete orphaned assignments
        for assignment in orphanedAssignments {
            print("   🗑️ Deleting orphaned assignment: recipeID=\(assignment.recipeID), imageName=\(assignment.imageName)")
            context.delete(assignment)
        }
        
        // Save changes
        try context.save()
        print("✅ Cleaned up \(orphanedAssignments.count) orphaned image assignments")
    }
    
    /// Find recipes without any image assignments (potential issues)
    static func findRecipesWithoutImageAssignments(context: ModelContext) async throws -> [Recipe] {
        print("🔍 Finding recipes without image assignments...")
        
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let assignmentDescriptor = FetchDescriptor<RecipeImageAssignment>()
        
        let recipes = try context.fetch(recipeDescriptor)
        let assignments = try context.fetch(assignmentDescriptor)
        
        // Build set of recipe IDs that have assignments
        let recipeIDsWithAssignments = Set(assignments.map { $0.recipeID })
        
        // Find recipes without assignments
        let recipesWithoutAssignments = recipes.filter { recipe in
            !recipeIDsWithAssignments.contains(recipe.id)
        }
        
        print("📊 Found \(recipesWithoutAssignments.count) recipes without image assignments")
        
        return recipesWithoutAssignments
    }
    
    /// Comprehensive cleanup report
    static func generateCleanupReport(context: ModelContext) async throws -> CleanupReport {
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let assignmentDescriptor = FetchDescriptor<RecipeImageAssignment>()
        
        let recipes = try context.fetch(recipeDescriptor)
        let assignments = try context.fetch(assignmentDescriptor)
        
        let validRecipeIDs = Set(recipes.map { $0.id })
        let orphanedAssignments = assignments.filter { !validRecipeIDs.contains($0.recipeID) }
        
        let recipeIDsWithAssignments = Set(assignments.map { $0.recipeID })
        let recipesWithoutAssignments = recipes.filter { !recipeIDsWithAssignments.contains($0.id) }
        
        // Find duplicates by content fingerprint
        var recipesByFingerprint: [String: [Recipe]] = [:]
        for recipe in recipes {
            let fingerprint = recipe.contentFingerprint
            recipesByFingerprint[fingerprint, default: []].append(recipe)
        }
        let duplicateGroups = recipesByFingerprint.filter { $0.value.count > 1 }
        let totalDuplicates = duplicateGroups.reduce(0) { $0 + ($1.value.count - 1) }
        
        return CleanupReport(
            totalRecipes: recipes.count,
            totalImageAssignments: assignments.count,
            orphanedAssignments: orphanedAssignments.count,
            recipesWithoutAssignments: recipesWithoutAssignments.count,
            duplicateGroups: duplicateGroups.count,
            totalDuplicateRecipes: totalDuplicates
        )
    }
    
    /// Execute full cleanup (USE WITH CAUTION)
    static func executeFullCleanup(context: ModelContext) async throws -> CleanupResult {
        print("🧹 Starting full cleanup...")
        
        var result = CleanupResult()
        
        // 1. Clean up orphaned image assignments
        let assignmentDescriptor = FetchDescriptor<RecipeImageAssignment>()
        let assignments = try context.fetch(assignmentDescriptor)
        
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let recipes = try context.fetch(recipeDescriptor)
        
        let validRecipeIDs = Set(recipes.map { $0.id })
        let orphanedAssignments = assignments.filter { !validRecipeIDs.contains($0.recipeID) }
        
        for assignment in orphanedAssignments {
            context.delete(assignment)
            result.assignmentsDeleted += 1
        }
        
        // 2. Clean up duplicate recipes
        var recipesByFingerprint: [String: [Recipe]] = [:]
        for recipe in recipes {
            let fingerprint = recipe.contentFingerprint
            recipesByFingerprint[fingerprint, default: []].append(recipe)
        }
        
        for (_, duplicates) in recipesByFingerprint where duplicates.count > 1 {
            // Sort by creation date, keep oldest
            let sorted = duplicates.sorted { r1, r2 in
                (r1.dateCreated ?? r1.dateAdded) < (r2.dateCreated ?? r2.dateAdded)
            }
            
            // Delete all but the first (oldest)
            for duplicate in sorted.dropFirst() {
                context.delete(duplicate)
                result.recipesDeleted += 1
            }
        }
        
        // Save all changes
        try context.save()
        
        print("✅ Cleanup complete: \(result.recipesDeleted) recipes, \(result.assignmentsDeleted) assignments deleted")
        
        return result
    }
}

// MARK: - Supporting Types

struct CleanupReport: Codable {
    let totalRecipes: Int
    let totalImageAssignments: Int
    let orphanedAssignments: Int
    let recipesWithoutAssignments: Int
    let duplicateGroups: Int
    let totalDuplicateRecipes: Int
    
    var hasIssues: Bool {
        orphanedAssignments > 0 || totalDuplicateRecipes > 0
    }
    
    var summary: String {
        """
        📊 Cleanup Report
        ─────────────────────────────
        Total Recipes: \(totalRecipes)
        Total Image Assignments: \(totalImageAssignments)
        
        Issues Found:
        • Orphaned Assignments: \(orphanedAssignments)
        • Recipes Without Assignments: \(recipesWithoutAssignments)
        • Duplicate Groups: \(duplicateGroups)
        • Total Duplicate Recipes: \(totalDuplicateRecipes)
        
        Status: \(hasIssues ? "⚠️ Issues Found" : "✅ All Clean")
        """
    }
}

struct CleanupResult: Codable {
    var recipesDeleted: Int = 0
    var assignmentsDeleted: Int = 0
    
    var summary: String {
        """
        🧹 Cleanup Results
        ─────────────────────────────
        Recipes Deleted: \(recipesDeleted)
        Assignments Deleted: \(assignmentsDeleted)
        """
    }
}
