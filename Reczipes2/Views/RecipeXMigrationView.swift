//
//  RecipeXMigrationView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 1/26/26.
//
//  UI for migrating recipes to RecipeX and monitoring CloudKit sync

import SwiftUI
import SwiftData

struct RecipeXMigrationView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncService = RecipeXCloudKitSyncService.shared
    
    @State private var migrationManager: RecipeXMigrationManager?
    @State private var isMigrating = false
    @State private var migrationProgress: (current: Int, total: Int, status: String) = (0, 0, "")
    @State private var migrationResult: RecipeXMigrationManager.MigrationResult?
    @State private var showingResult = false
    @State private var showingDeleteConfirmation = false
    
    @State private var recipeCount = 0
    @State private var recipeXCount = 0
    @State private var needsMigration = false
    
    var body: some View {
        List {
            // Migration Status Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    migrationStatusView
                    
                    if needsMigration {
                        migrationActionView
                    } else {
                        Text("All recipes have been migrated to the new format.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            } header: {
                Label("Recipe Migration", systemImage: "arrow.triangle.2.circlepath")
            } footer: {
                Text("RecipeX is the new unified recipe format with automatic iCloud sharing. Your recipes will be accessible to everyone.")
            }
            
            // CloudKit Sync Section
            Section {
                syncStatusView
                
                if syncService.pendingCount > 0 {
                    HStack {
                        Text("Pending Recipes")
                        Spacer()
                        Text("\(syncService.pendingCount)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let lastSync = syncService.lastSyncDate {
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text(lastSync, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let error = syncService.lastError {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Error")
                            .font(.caption)
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button(action: {
                    Task {
                        await syncService.syncNow()
                    }
                }) {
                    Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(syncService.isSyncing)
                
            } header: {
                Label("iCloud Sync", systemImage: "icloud.fill")
            } footer: {
                Text("Recipes are automatically synced to iCloud every minute. You can also trigger a manual sync.")
            }
            
            // Advanced Section
            if !needsMigration {
                Section {
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Delete Old Recipes", systemImage: "trash")
                    }
                    .disabled(needsMigration)
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("⚠️ Only delete old Recipe objects after verifying all data is in RecipeX and synced to iCloud.")
                }
            }
        }
        .navigationTitle("Recipe Migration")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            setupMigrationManager()
            loadStats()
        }
        .sheet(isPresented: $showingResult) {
            if let result = migrationResult {
                MigrationResultView(result: result)
            }
        }
        .alert("Delete Old Recipes?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteOldRecipes()
                }
            }
        } message: {
            Text("This will permanently delete all old Recipe objects. Make sure your RecipeX data is synced to iCloud first!")
        }
        .overlay {
            if isMigrating {
                migrationProgressOverlay
            }
        }
    }
    
    // MARK: - Subviews
    
    private var migrationStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Old Format")
                Spacer()
                Text("\(recipeCount) recipes")
                    .foregroundStyle(recipeCount > 0 ? .orange : .secondary)
            }
            
            HStack {
                Text("New Format (RecipeX)")
                Spacer()
                Text("\(recipeXCount) recipes")
                    .foregroundStyle(recipeXCount > 0 ? .green : .secondary)
            }
        }
        .font(.subheadline)
    }
    
    private var migrationActionView: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await startMigration()
                }
            }) {
                Label("Migrate to RecipeX", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isMigrating)
            
            Text("This will convert \(recipeCount) recipe(s) to the new format and enable iCloud sharing.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var syncStatusView: some View {
        HStack {
            Text("Status")
            Spacer()
            if syncService.isSyncing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Syncing...")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Active")
                    .foregroundStyle(.green)
            }
        }
    }
    
    private var migrationProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: Double(migrationProgress.current), total: Double(migrationProgress.total))
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                
                Text("\(migrationProgress.current) / \(migrationProgress.total)")
                    .font(.headline)
                
                Text(migrationProgress.status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(30)
            .background(.regularMaterial)
            .cornerRadius(20)
        }
    }
    
    // MARK: - Actions
    
    private func setupMigrationManager() {
        migrationManager = RecipeXMigrationManager(
            modelContext: modelContext,
            getCurrentUserID: {
                // Get CloudKit user ID from sharing service
                return CloudKitSharingService.shared.currentUserID
            },
            getCurrentUserDisplayName: {
                // Get user's display name from sharing service
                return CloudKitSharingService.shared.currentUserName
            }
        )
    }
    
    private func loadStats() {
        // Count Recipe objects
        let recipeDescriptor = FetchDescriptor<Recipe>()
        recipeCount = (try? modelContext.fetchCount(recipeDescriptor)) ?? 0
        
        // Count RecipeX objects
        let recipeXDescriptor = FetchDescriptor<RecipeX>()
        recipeXCount = (try? modelContext.fetchCount(recipeXDescriptor)) ?? 0
        
        // Check if migration is needed
        needsMigration = migrationManager?.needsMigration() ?? false
    }
    
    private func startMigration() async {
        guard let manager = migrationManager else { return }
        
        isMigrating = true
        
        let result = await manager.migrateWithProgress { current, total, status in
            migrationProgress = (current, total, status)
        }
        
        isMigrating = false
        migrationResult = result
        showingResult = true
        
        // Reload stats
        loadStats()
        
        // Start CloudKit sync service if not already running
        syncService.startAutomaticSync(modelContext: modelContext)
    }
    
    private func deleteOldRecipes() async {
        guard let manager = migrationManager else { return }
        
        do {
            let deletedCount = try await manager.deleteOldRecipes()
            logInfo("Deleted \(deletedCount) old Recipe objects", category: "migration")
            loadStats()
        } catch {
            logError("Failed to delete old recipes: \(error)", category: "migration")
        }
    }
}

// MARK: - Migration Result View

struct MigrationResultView: View {
    let result: RecipeXMigrationManager.MigrationResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    resultRow(icon: "checkmark.circle.fill", color: .green, label: "Migrated", count: result.migratedCount)
                    resultRow(icon: "forward.circle.fill", color: .orange, label: "Skipped", count: result.skippedCount)
                    resultRow(icon: "xmark.circle.fill", color: .red, label: "Errors", count: result.errorCount)
                } header: {
                    Text("Migration Summary")
                }
                
                if !result.errors.isEmpty {
                    Section {
                        ForEach(result.errors, id: \.recipeTitle) { error in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(error.recipeTitle)
                                    .font(.subheadline)
                                Text(error.error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Errors")
                    }
                }
            }
            .navigationTitle("Migration Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func resultRow(icon: String, color: Color, label: String, count: Int) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        RecipeXMigrationView()
    }
}
