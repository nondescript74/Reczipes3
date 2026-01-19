//
//  RecipeDuplicateDetector.swift
//  Reczipes2
//
//  Diagnostic tool to detect and clean up duplicate recipes
//  Created for fixing CloudKit sync duplicate issues
//

import SwiftUI
import SwiftData

// MARK: - Duplicate Group Model

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let fingerprint: String
    let title: String
    let recipes: [Recipe]
    
    var duplicateCount: Int {
        recipes.count
    }
    
    /// The canonical (preferred) recipe to keep
    var canonical: Recipe {
        // Sort by creation date, keep oldest
        recipes.sorted { recipe1, recipe2 in
            let date1 = recipe1.dateCreated ?? recipe1.dateAdded
            let date2 = recipe2.dateCreated ?? recipe2.dateAdded
            return date1 < date2
        }.first!
    }
    
    /// Recipes that should be deleted (all except canonical)
    var duplicatesToDelete: [Recipe] {
        recipes.filter { $0.id != canonical.id }
    }
}

// MARK: - Duplicate Detector View

struct RecipeDuplicateDetectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.title) private var allRecipes: [Recipe]
    
    @State private var duplicateGroups: [DuplicateGroup] = []
    @State private var orphanedAssignments: [RecipeImageAssignment] = []
    @State private var isAnalyzing = false
    @State private var showingDeleteConfirmation = false
    @State private var groupToDelete: DuplicateGroup?
    
    var totalDuplicates: Int {
        duplicateGroups.reduce(0) { $0 + ($1.duplicateCount - 1) }
    }
    
    var body: some View {
        List {
            // MARK: - Analysis Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Total Recipes:")
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(allRecipes.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    if !duplicateGroups.isEmpty {
                        HStack {
                            Text("Duplicate Groups:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(duplicateGroups.count)")
                                .foregroundStyle(.orange)
                        }
                        
                        HStack {
                            Text("Extra Copies:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(totalDuplicates)")
                                .foregroundStyle(.red)
                        }
                        
                        HStack {
                            Text("After Cleanup:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(allRecipes.count - totalDuplicates)")
                                .foregroundStyle(.green)
                        }
                    }
                    
                    if !orphanedAssignments.isEmpty {
                        Divider()
                        HStack {
                            Text("Orphaned Assignments:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(orphanedAssignments.count)")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Analysis")
            }
            
            // MARK: - Actions Section
            Section {
                Button {
                    findDuplicates()
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Find Duplicates")
                    }
                }
                .disabled(isAnalyzing)
                
                if !duplicateGroups.isEmpty {
                    Button {
                        cleanupAllDuplicates()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Duplicates")
                            Spacer()
                            Text("(\(totalDuplicates) recipes)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.red)
                }
                
                if !orphanedAssignments.isEmpty {
                    Button {
                        cleanupOrphanedAssignments()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clean Up Orphaned Assignments")
                            Spacer()
                            Text("(\(orphanedAssignments.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.orange)
                }
            } header: {
                Text("Actions")
            }
            
            // MARK: - Duplicate Groups List
            if !duplicateGroups.isEmpty {
                Section {
                    ForEach(duplicateGroups) { group in
                        DuplicateGroupRow(
                            group: group,
                            onDeleteDuplicates: {
                                groupToDelete = group
                                showingDeleteConfirmation = true
                            },
                            onDeleteSingle: { recipe in
                                deleteSingleRecipe(recipe, from: group)
                            }
                        )
                    }
                } header: {
                    Text("Duplicate Groups (\(duplicateGroups.count))")
                }
            }
        }
        .navigationTitle("Duplicate Detector")
        .alert("Delete Duplicates?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                groupToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let group = groupToDelete {
                    deleteGroupDuplicates(group)
                    groupToDelete = nil
                }
            }
        } message: {
            if let group = groupToDelete {
                Text("This will delete \(group.duplicatesToDelete.count) duplicate(s) of '\(group.title)', keeping the oldest version.")
            }
        }
        .onAppear {
            // Auto-run analysis on appear
            findDuplicates()
        }
    }
    
    // MARK: - Analysis Functions
    
    private func findDuplicates() {
        isAnalyzing = true
        
        print("🔍 Starting duplicate analysis...")
        print("📊 Total recipes in database: \(allRecipes.count)")
        
        // Group recipes by content fingerprint
        var recipesByFingerprint: [String: [Recipe]] = [:]
        for recipe in allRecipes {
            let fingerprint = recipe.contentFingerprint
            recipesByFingerprint[fingerprint, default: []].append(recipe)
        }
        
        // Filter to only groups with duplicates
        let duplicateGroupsArray = recipesByFingerprint
            .filter { $0.value.count > 1 }
            .map { fingerprint, recipes in
                DuplicateGroup(
                    fingerprint: fingerprint,
                    title: recipes.first?.title ?? "Untitled",
                    recipes: recipes
                )
            }
            .sorted { $0.title < $1.title }
        
        duplicateGroups = duplicateGroupsArray
        
        print("📊 Found \(duplicateGroups.count) duplicate groups")
        print("📊 Total duplicate recipes: \(totalDuplicates)")
        
        // Also check for orphaned assignments
        findOrphanedAssignments()
        
        isAnalyzing = false
    }
    
    private func findOrphanedAssignments() {
        do {
            let assignments = try modelContext.fetch(FetchDescriptor<RecipeImageAssignment>())
            let validRecipeIDs = Set(allRecipes.map { $0.id })
            
            orphanedAssignments = assignments.filter { !validRecipeIDs.contains($0.recipeID) }
            
            if !orphanedAssignments.isEmpty {
                print("⚠️ Found \(orphanedAssignments.count) orphaned image assignments")
            }
        } catch {
            print("❌ Error fetching assignments: \(error)")
        }
    }
    
    // MARK: - Cleanup Functions
    
    private func deleteGroupDuplicates(_ group: DuplicateGroup) {
        let toDelete = group.duplicatesToDelete
        
        print("🗑️ Deleting \(toDelete.count) duplicates of '\(group.title)'")
        print("✅ Keeping canonical recipe ID: \(group.canonical.id)")
        
        for recipe in toDelete {
            print("   🗑️ Deleting duplicate ID: \(recipe.id)")
            modelContext.delete(recipe)
        }
        
        do {
            try modelContext.save()
            print("✅ Successfully deleted duplicates")
            
            // Refresh the analysis
            findDuplicates()
        } catch {
            print("❌ Failed to delete duplicates: \(error)")
        }
    }
    
    private func deleteSingleRecipe(_ recipe: Recipe, from group: DuplicateGroup) {
        // Don't allow deleting the canonical recipe
        guard recipe.id != group.canonical.id else {
            print("⚠️ Cannot delete canonical recipe")
            return
        }
        
        print("🗑️ Deleting single recipe: \(recipe.title) (ID: \(recipe.id))")
        modelContext.delete(recipe)
        
        do {
            try modelContext.save()
            print("✅ Deleted recipe")
            
            // Refresh the analysis
            findDuplicates()
        } catch {
            print("❌ Failed to delete recipe: \(error)")
        }
    }
    
    private func cleanupAllDuplicates() {
        print("🗑️ Cleaning up ALL duplicates...")
        
        var totalDeleted = 0
        for group in duplicateGroups {
            let toDelete = group.duplicatesToDelete
            totalDeleted += toDelete.count
            
            for recipe in toDelete {
                modelContext.delete(recipe)
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Successfully deleted \(totalDeleted) duplicate recipes")
            
            // Refresh the analysis
            findDuplicates()
        } catch {
            print("❌ Failed to cleanup duplicates: \(error)")
        }
    }
    
    private func cleanupOrphanedAssignments() {
        print("🗑️ Cleaning up \(orphanedAssignments.count) orphaned assignments...")
        
        for assignment in orphanedAssignments {
            modelContext.delete(assignment)
        }
        
        do {
            try modelContext.save()
            print("✅ Successfully cleaned up orphaned assignments")
            
            // Refresh the analysis
            findDuplicates()
        } catch {
            print("❌ Failed to cleanup orphaned assignments: \(error)")
        }
    }
}

// MARK: - Duplicate Group Row View

struct DuplicateGroupRow: View {
    let group: DuplicateGroup
    let onDeleteDuplicates: () -> Void
    let onDeleteSingle: (Recipe) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(group.recipes) { recipe in
                RecipeRowView(
                    recipe: recipe,
                    isCanonical: recipe.id == group.canonical.id,
                    onDelete: { onDeleteSingle(recipe) }
                )
            }
            
            Button {
                onDeleteDuplicates()
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete All Duplicates")
                    Spacer()
                    Text("Keep oldest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.red)
            .padding(.top, 8)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.title)
                        .fontWeight(.medium)
                    Text("\(group.duplicateCount) copies found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(group.duplicateCount - 1)")
                    .font(.headline)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Recipe Row View

struct RecipeRowView: View {
    let recipe: Recipe
    let isCanonical: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Image(systemName: isCanonical ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isCanonical ? .green : .secondary)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                if isCanonical {
                    Text("KEEP THIS ONE ✓")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                
                Text("ID: \(recipe.id.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let created = recipe.dateCreated {
                    Text("Created: \(created, style: .date)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text("Added: \(recipe.dateAdded, style: .date)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if !isCanonical {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecipeDuplicateDetectorView()
            .modelContainer(for: [Recipe.self, RecipeImageAssignment.self])
    }
}
