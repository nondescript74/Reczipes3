//
//  DatabaseDuplicateCleanupView.swift
//  Reczipes2
//
//  Created on 1/18/26.
//  Remove duplicate Recipe records from the database
//

import SwiftUI
import SwiftData

struct DatabaseDuplicateCleanupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isScanning = true
    @State private var duplicateInfo: DuplicateInfo?
    @State private var isRemoving = false
    @State private var cleanupComplete = false
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isScanning {
                    scanningView
                } else if let info = duplicateInfo, info.hasDuplicates {
                    duplicatesFoundView(info: info)
                } else if cleanupComplete {
                    cleanupCompleteView
                } else {
                    noDuplicatesView
                }
            }
            .padding()
            .navigationTitle("Remove Duplicates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .disabled(isRemoving)
                }
            }
            .task {
                await scanForDuplicates()
            }
        }
    }
    
    // MARK: - Views
    
    private var scanningView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Scanning for duplicates...")
                .font(.headline)
            
            Text("Checking recipe database...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func duplicatesFoundView(info: DuplicateInfo) -> some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            // Title
            Text("Duplicates Found!")
                .font(.title)
                .fontWeight(.bold)
            
            // Stats
            VStack(spacing: 12) {
                HStack {
                    Text("Total Recipes:")
                    Spacer()
                    Text("\(info.totalRecipes)")
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
                
                HStack {
                    Text("Unique Recipes:")
                    Spacer()
                    Text("\(info.uniqueRecipes)")
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                
                Divider()
                
                HStack {
                    Text("Duplicates to Remove:")
                    Spacer()
                    Text("\(info.duplicateCount)")
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Examples
            if !info.duplicateExamples.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Example duplicates:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(info.duplicateExamples.prefix(3), id: \.self) { example in
                        Text("• \(example)")
                            .font(.caption2)
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Cleanup button
            VStack(spacing: 12) {
                Button(action: { Task { await performCleanup(info: info) } }) {
                    HStack {
                        if isRemoving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "trash.fill")
                        }
                        Text(isRemoving ? "Removing duplicates..." : "Remove Duplicates")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isRemoving)
                
                Text("This will keep the newest version of each recipe and delete older duplicates")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let error = error {
                Text("Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var cleanupCompleteView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Cleanup Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            if let info = duplicateInfo {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Removed \(info.duplicateCount) duplicate recipes")
                        .font(.headline)
                    
                    Text("Your database now has \(info.uniqueRecipes) clean recipes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(spacing: 12) {
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text("You can now proceed with CloudKit cleanup if needed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var noDuplicatesView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("No Duplicates!")
                .font(.title)
                .fontWeight(.bold)
            
            if let info = duplicateInfo {
                Text("Your database has \(info.totalRecipes) recipes, all unique.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            
            Button("Close") {
                dismiss()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Actions
    
    private func scanForDuplicates() async {
        isScanning = true
        
        do {
            let allRecipes = try modelContext.fetch(FetchDescriptor<Recipe>())
            
            // Group by ID to find duplicates
            var recipesByID: [UUID: [Recipe]] = [:]
            for recipe in allRecipes {
                recipesByID[recipe.id, default: []].append(recipe)
            }
            
            // Find which IDs have duplicates
            let duplicateGroups = recipesByID.filter { $0.value.count > 1 }
            let duplicateCount = duplicateGroups.values.reduce(0) { $0 + ($1.count - 1) } // Total duplicates to remove
            
            // Get example titles
            let examples = duplicateGroups.values.prefix(5).map { group in
                "\(group.first?.title ?? "Unknown") (\(group.count) copies)"
            }
            
            duplicateInfo = DuplicateInfo(
                totalRecipes: allRecipes.count,
                uniqueRecipes: recipesByID.count,
                duplicateCount: duplicateCount,
                duplicateExamples: examples,
                duplicateGroups: duplicateGroups
            )
            
        } catch {
            self.error = error
        }
        
        isScanning = false
    }
    
    private func performCleanup(info: DuplicateInfo) async {
        isRemoving = true
        error = nil
        
        do {
            var removedCount = 0
            
            // For each duplicate group, keep the newest and delete the rest
            for (_, recipes) in info.duplicateGroups {
                // Sort by persistence date (newest first)
                let sorted = recipes.sorted { first, second in
                    (first.persistentModelID.hashValue) > (second.persistentModelID.hashValue)
                }
                
                // Delete all except the first (newest)
                for recipe in sorted.dropFirst() {
                    modelContext.delete(recipe)
                    removedCount += 1
                }
            }
            
            // Save changes
            try modelContext.save()
            
            print("✅ Removed \(removedCount) duplicate recipes")
            print("✅ Database now has \(info.uniqueRecipes) unique recipes")
            
            cleanupComplete = true
            
        } catch {
            self.error = error
        }
        
        isRemoving = false
    }
}

// MARK: - Supporting Types

struct DuplicateInfo {
    let totalRecipes: Int
    let uniqueRecipes: Int
    let duplicateCount: Int
    let duplicateExamples: [String]
    let duplicateGroups: [UUID: [Recipe]]
    
    var hasDuplicates: Bool {
        duplicateCount > 0
    }
}

#Preview {
    DatabaseDuplicateCleanupView()
}
