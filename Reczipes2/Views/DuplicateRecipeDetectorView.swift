//
//  DuplicateRecipeDetectorView.swift
//  Reczipes2
//
//  Tool for finding and cleaning up duplicate recipes
//  Created by Zahirudeen Premji on 1/19/26.
//

import SwiftUI
import SwiftData

struct DuplicateRecipeDetectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.title) private var allRecipes: [Recipe]
    @StateObject private var monitor = CloudKitDuplicateMonitor.shared
    
    @State private var duplicateGroups: [String: [Recipe]] = [:]
    @State private var isAnalyzing = false
    @State private var showingConfirmation = false
    @State private var selectedGroup: String?
    @State private var selectedRecipe: Recipe?
    
    var body: some View {
        List {
            // Summary Section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Recipes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(allRecipes.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Duplicate Groups")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(duplicateGroups.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(duplicateGroups.isEmpty ? .green : .red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Extra Copies")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(totalDuplicateCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(totalDuplicateCount == 0 ? .green : .orange)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Statistics")
            }
            
            // Actions Section
            Section {
                Button {
                    findDuplicates()
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Scan for Duplicates")
                        if isAnalyzing {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                }
                .disabled(isAnalyzing)
                
                if !duplicateGroups.isEmpty {
                    Button {
                        showingConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Duplicates")
                            Text("(\(totalDuplicateCount))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.red)
                }
            } header: {
                Text("Actions")
            } footer: {
                if !duplicateGroups.isEmpty {
                    Text("This will keep the oldest copy of each recipe and delete the rest.")
                        .font(.caption)
                }
            }
            
            // Duplicate Groups
            if !duplicateGroups.isEmpty {
                Section {
                    ForEach(Array(duplicateGroups.keys.sorted()), id: \.self) { fingerprint in
                        if let recipes = duplicateGroups[fingerprint], recipes.count > 1 {
                            DisclosureGroup {
                                ForEach(recipes.sorted(by: { r1, r2 in
                                    r1.dateAdded < r2.dateAdded
                                })) { recipe in
                                    recipeRow(recipe, isCanonical: recipe == recipes.first)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recipes.first?.title ?? "Unknown")
                                            .font(.headline)
                                        Text("\(recipes.count) copies found")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Duplicate Groups (\(duplicateGroups.count))")
                }
            } else if isAnalyzing {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Analyzing recipes...")
                        Spacer()
                    }
                    .padding()
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "No Duplicates Found",
                        systemImage: "checkmark.circle.fill",
                        description: Text("Tap 'Scan for Duplicates' to check for duplicate recipes")
                    )
                }
            }
        }
        .navigationTitle("Duplicate Detector")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete All Duplicates?",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete \(totalDuplicateCount) Duplicates", role: .destructive) {
                Task {
                    await deleteAllDuplicates()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete \(totalDuplicateCount) duplicate recipes, keeping only the oldest copy of each. This action cannot be undone.")
        }
        .onAppear {
            // Configure monitor with context
            monitor.configure(with: modelContext)
            // Auto-scan on appear
            findDuplicates()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowDuplicateDetector"))) { _ in
            // Triggered by duplicate detection alert
            findDuplicates()
        }
    }
    
    // MARK: - Row Views
    
    @ViewBuilder
    private func recipeRow(_ recipe: Recipe, isCanonical: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if isCanonical {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("KEEP")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "trash.circle.fill")
                            .foregroundStyle(.red)
                        Text("DELETE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                    }
                }
                
                Text("ID: \(recipe.id.uuidString.prefix(8))...")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                Label {
                    Text(recipe.dateAdded, style: .date)
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if !isCanonical {
                Button {
                    selectedRecipe = recipe
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
        .alert("Delete This Recipe?", isPresented: .init(
            get: { selectedRecipe == recipe },
            set: { if !$0 { selectedRecipe = nil } }
        )) {
            Button("Delete", role: .destructive) {
                deleteRecipe(recipe)
            }
            Button("Cancel", role: .cancel) {
                selectedRecipe = nil
            }
        } message: {
            Text("This will permanently delete this copy of '\(recipe.title)'")
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalDuplicateCount: Int {
        duplicateGroups.reduce(0) { total, group in
            total + (group.value.count - 1) // Count extras (keep 1 per group)
        }
    }
    
    // MARK: - Actions
    
    private func findDuplicates() {
        isAnalyzing = true
        
        Task {
            // Small delay for UI responsiveness
            try? await Task.sleep(for: .milliseconds(100))
            
            // Group recipes by content fingerprint
            var groups: [String: [Recipe]] = [:]
            for recipe in allRecipes {
                let fingerprint = recipe.contentFingerprint
                groups[fingerprint, default: []].append(recipe)
            }
            
            // Keep only groups with duplicates
            let duplicates = groups.filter { $0.value.count > 1 }
            
            await MainActor.run {
                duplicateGroups = duplicates
                isAnalyzing = false
                
                print("📊 Duplicate scan complete:")
                print("   Total recipes: \(allRecipes.count)")
                print("   Duplicate groups: \(duplicates.count)")
                print("   Extra copies: \(totalDuplicateCount)")
            }
        }
    }
    
    private func deleteRecipe(_ recipe: Recipe) {
        modelContext.delete(recipe)
        
        do {
            try modelContext.save()
            print("✅ Deleted recipe: \(recipe.title) (ID: \(recipe.id))")
            
            // Refresh analysis
            findDuplicates()
        } catch {
            print("❌ Failed to delete recipe: \(error)")
        }
    }
    
    private func deleteAllDuplicates() async {
        print("🧹 Starting bulk duplicate deletion...")
        
        var deletedCount = 0
        
        for (_, recipes) in duplicateGroups where recipes.count > 1 {
            // Sort by creation date, keep oldest
            let sorted = recipes.sorted { recipe1, recipe2 in
                recipe1.dateAdded < recipe2.dateAdded
            }
            
            let canonical = sorted.first!
            let duplicates = sorted.dropFirst()
            
            print("   Keeping: \(canonical.title) (ID: \(canonical.id))")
            for duplicate in duplicates {
                print("   🗑️ Deleting: \(duplicate.id)")
                modelContext.delete(duplicate)
                deletedCount += 1
            }
        }
        
        if deletedCount > 0 {
            do {
                try modelContext.save()
                print("✅ Successfully deleted \(deletedCount) duplicate recipes")
                
                await MainActor.run {
                    // Clear the duplicates
                    duplicateGroups.removeAll()
                    
                    // Update monitor
                    monitor.duplicatesDetected = 0
                }
            } catch {
                print("❌ Failed to save after deletion: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DuplicateRecipeDetectorView()
            .modelContainer(for: Recipe.self, inMemory: true)
    }
}
