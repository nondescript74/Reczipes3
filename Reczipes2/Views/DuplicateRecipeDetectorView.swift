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
    @Query(sort: \RecipeX.title) private var allRecipes: [RecipeX]
    @Query private var recipeXEntities: [RecipeX]
    @StateObject private var monitor = CloudKitDuplicateMonitor.shared
    
    @State private var duplicateGroups: [String: [RecipeX]] = [:]
    @State private var isAnalyzing = false
    @State private var showingConfirmation = false
    @State private var selectedGroup: String?
    @State private var selectedRecipe: RecipeX?
    
    var body: some View {
        List {
            statisticsSection
            actionsSection
            duplicateGroupsSection
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
    
    // MARK: - Section Views
    
    private var statisticsSection: some View {
        Section {
            HStack {
                statisticView(title: "Total Recipes", value: "\(allRecipes.count)", color: nil)
                Spacer()
                statisticView(title: "Duplicate Groups", value: "\(duplicateGroups.count)", color: duplicateGroups.isEmpty ? .green : .red)
                Spacer()
                statisticView(title: "Extra Copies", value: "\(totalDuplicateCount)", color: totalDuplicateCount == 0 ? .green : .orange)
            }
            .padding(.vertical, 8)
        } header: {
            Text("Statistics")
        }
    }
    
    private func statisticView(title: String, value: String, color: Color?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color ?? Color.primary)
        }
    }
    
    private var actionsSection: some View {
        Section {
            scanButton
            if !duplicateGroups.isEmpty {
                deleteAllButton
            }
        } header: {
            Text("Actions")
        } footer: {
            if !duplicateGroups.isEmpty {
                Text("This will keep the oldest copy of each recipe and delete the rest.")
                    .font(.caption)
            }
        }
    }
    
    private var scanButton: some View {
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
    }
    
    private var deleteAllButton: some View {
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
    
    @ViewBuilder
    private var duplicateGroupsSection: some View {
        if !duplicateGroups.isEmpty {
            Section {
                ForEach(Array(duplicateGroups.keys.sorted()), id: \.self) { fingerprint in
                    if let recipes = duplicateGroups[fingerprint], recipes.count > 1 {
                        duplicateGroupRow(recipes: recipes)
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
    
    private func duplicateGroupRow(recipes: [RecipeX]) -> some View {
        DisclosureGroup {
            ForEach(recipes.sorted(by: { r1, r2 in
                (r1.dateAdded ?? Date.distantPast) < (r2.dateAdded ?? Date.distantPast)
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
    
    // MARK: - Row Views
    
    @ViewBuilder
    private func recipeRow(_ recipe: RecipeX, isCanonical: Bool) -> some View {
        let recipeIDPreview: String = {
            if let id = recipe.id {
                return String(id.uuidString.prefix(8))
            } else {
                return "unknown"
            }
        }()
        
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
                
                Text("ID: \(recipeIDPreview)...")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                Label {
                    Text(recipe.dateAdded ?? Date(), style: .date)
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
            Text("This will permanently delete this copy of '\(recipe.title ?? "Unknown Recipe")'")
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
            var groups: [String: [RecipeX]] = [:]
            for recipe in allRecipes {
                let fingerprint = recipe.contentFingerprint ?? recipe.id?.uuidString ?? UUID().uuidString
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
    
    private func deleteRecipe(_ recipe: RecipeX) {
        modelContext.delete(recipe)
        
        do {
            try modelContext.save()
            print("✅ Deleted recipe: \(String(describing: recipe.title)) (ID: \(String(describing: recipe.id)))")
            
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
                let dateA = Date()
                return (recipe1.dateAdded ?? dateA) < (recipe2.dateAdded ?? dateA)
            }
            
            let canonical = sorted.first!
            let duplicates = sorted.dropFirst()
            
            print("   Keeping: \(String(describing: canonical.title)) (ID: \(String(describing: canonical.id)))")
            for duplicate in duplicates {
                print("   🗑️ Deleting: \(String(describing: duplicate.title)) (ID: \(String(describing: duplicate.id)))")
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
            .modelContainer(for: RecipeX.self, inMemory: true)
    }
}
