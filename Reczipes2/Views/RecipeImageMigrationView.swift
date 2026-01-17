//
//  RecipeImageMigrationView.swift
//  Reczipes2
//
//  View for migrating recipe images to SwiftData
//

import SwiftUI
import SwiftData

struct RecipeImageMigrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var recipes: [Recipe]
    
    @State private var isMigrating = false
    @State private var isRestoring = false
    @State private var migrationComplete = false
    @State private var restorationComplete = false
    @State private var errorMessage: String?
    @State private var migratedCount = 0
    @State private var needsRestoration = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "photo.stack")
                        .foregroundColor(.blue)
                    Text("Total Recipes")
                    Spacer()
                    Text("\(recipes.count)")
                        .bold()
                }
                
                HStack {
                    Image(systemName: "photo.fill")
                        .foregroundColor(.orange)
                    Text("With Images")
                    Spacer()
                    Text("\(recipesWithImages)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundColor(.green)
                    Text("Migrated to SwiftData")
                    Spacer()
                    Text("\(recipesWithImageDataCount)")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Current Status")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What does this do?")
                        .font(.headline)
                    
                    Text("Stores your recipe images directly in SwiftData so they sync via CloudKit. This means your images will survive app deletion and reinstallation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    Task {
                        await migrateImages()
                    }
                } label: {
                    if isMigrating {
                        HStack {
                            ProgressView()
                            Text("Migrating...")
                        }
                    } else {
                        Label("Migrate Images to SwiftData", systemImage: "arrow.up.circle")
                    }
                }
                .disabled(isMigrating || isRestoring || recipes.isEmpty)
                
                if migrationComplete {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Migration complete! \(migratedCount) recipes migrated.")
                            .font(.caption)
                    }
                }
            } header: {
                Text("Migrate Images")
            } footer: {
                Text("Run this once to store all recipe images in SwiftData. This will allow CloudKit to sync your images across devices.")
                    .font(.caption)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When to use this?")
                        .font(.headline)
                    
                    Text("After reinstalling the app, run this to restore image files from SwiftData back to your device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if needsRestoration {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Some recipes are missing image files")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Button {
                    Task {
                        await restoreImages()
                    }
                } label: {
                    if isRestoring {
                        HStack {
                            ProgressView()
                            Text("Restoring...")
                        }
                    } else {
                        Label("Restore Images from SwiftData", systemImage: "arrow.down.circle")
                    }
                }
                .disabled(isMigrating || isRestoring)
                
                if restorationComplete {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Restoration complete!")
                            .font(.caption)
                    }
                }
            } header: {
                Text("Restore Images")
            } footer: {
                Text("This recreates image files from SwiftData when they're missing (e.g., after app reinstall).")
                    .font(.caption)
            }
            
            Section("Important Notes") {
                tipRow(icon: "exclamationmark.triangle", text: "Run migration before deleting the app")
                tipRow(icon: "icloud", text: "Requires CloudKit to be enabled")
                tipRow(icon: "externaldrive", text: "Image data uses external storage for efficiency")
                tipRow(icon: "arrow.triangle.2.circlepath", text: "Safe to run multiple times - already migrated items are skipped")
            }
        }
        .navigationTitle("Image Migration")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            checkIfRestorationNeeded()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var recipesWithImages: Int {
        recipes.filter { !$0.allImageNames.isEmpty }.count
    }
    
    private var recipesWithImageDataCount: Int {
        recipes.filter { $0.imageData != nil || $0.additionalImagesData != nil }.count
    }
    
    // MARK: - Actions
    
    private func migrateImages() async {
        isMigrating = true
        migrationComplete = false
        migratedCount = 0
        errorMessage = nil
        
        do {
            try await RecipeImageMigrationService.migrateAllRecipeImages(modelContext: modelContext)
            
            // Count how many were actually migrated
            await MainActor.run {
                migratedCount = recipesWithImageDataCount
                migrationComplete = true
            }
            
            logInfo("Successfully migrated images for \(migratedCount) recipes", category: "image-migration")
        } catch {
            await MainActor.run {
                errorMessage = "Migration failed: \(error.localizedDescription)"
            }
            logError("Image migration failed: \(error)", category: "image-migration")
        }
        
        await MainActor.run {
            isMigrating = false
        }
    }
    
    private func restoreImages() async {
        isRestoring = true
        restorationComplete = false
        errorMessage = nil
        
        do {
            try await RecipeImageMigrationService.restoreAllRecipeImages(modelContext: modelContext)
            
            await MainActor.run {
                restorationComplete = true
                needsRestoration = false
            }
            
            logInfo("Successfully restored images from SwiftData", category: "image-migration")
        } catch {
            await MainActor.run {
                errorMessage = "Restoration failed: \(error.localizedDescription)"
            }
            logError("Image restoration failed: \(error)", category: "image-migration")
        }
        
        await MainActor.run {
            isRestoring = false
        }
    }
    
    private func checkIfRestorationNeeded() {
        needsRestoration = RecipeImageMigrationService.needsImageRestoration(modelContext: modelContext)
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        RecipeImageMigrationView()
            .modelContainer(for: Recipe.self, inMemory: true)
    }
}
