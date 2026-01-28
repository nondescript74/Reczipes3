//
//  LegacyMigrationView.swift
//  Reczipes2
//
//  Created on 1/27/26.
//
//  UI for migrating legacy Recipe and RecipeBook models to new RecipeX and Book models

import SwiftUI
import SwiftData

struct LegacyMigrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var migrationManager: LegacyToNewMigrationManager?
    @State private var stats: MigrationStats?
    @State private var isMigrating = false
    @State private var migrationResult: MigrationResult?
    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Current Status
                    if let stats = stats {
                        statsSection(stats)
                    }
                    
                    // Migration Result
                    if let result = migrationResult {
                        resultSection(result)
                    }
                    
                    // Actions
                    if !isMigrating {
                        actionsSection
                    }
                    
                    // Error Message
                    if let error = errorMessage {
                        errorSection(error)
                    }
                }
                .padding()
            }
            .navigationTitle("Legacy Migration")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadStats()
            }
            .overlay {
                if isMigrating {
                    migrationOverlay
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Migrate to New Models")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Copy your legacy recipes and books to the new unified models with automatic iCloud sync")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
    
    // MARK: - Stats Section
    
    private func statsSection(_ stats: MigrationStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Status")
                .font(.headline)
            
            // Legacy Data
            GroupBox("Legacy Models") {
                VStack(spacing: 8) {
                    HStack {
                        Label("Recipes", systemImage: "book.fill")
                        Spacer()
                        Text("\(stats.legacyRecipeCount)")
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    HStack {
                        Label("Books", systemImage: "books.vertical.fill")
                        Spacer()
                        Text("\(stats.legacyBookCount)")
                            .fontWeight(.semibold)
                    }
                }
            }
            
            // New Data
            GroupBox("New Models") {
                VStack(spacing: 8) {
                    HStack {
                        Label("RecipeX", systemImage: "sparkles")
                        Spacer()
                        Text("\(stats.migratedRecipeCount)")
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    
                    Divider()
                    
                    HStack {
                        Label("Book", systemImage: "sparkles")
                        Spacer()
                        Text("\(stats.migratedBookCount)")
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            // Progress
            if stats.totalLegacyItems > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Migration Progress")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(stats.overallProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    
                    ProgressView(value: stats.overallProgress)
                        .tint(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
    
    // MARK: - Result Section
    
    private func resultSection(_ result: MigrationResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(result.isSuccess ? .green : .orange)
                    .font(.title2)
                
                Text(result.isSuccess ? "Migration Complete!" : "Migration Completed with Issues")
                    .font(.headline)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recipes Migrated")
                        Spacer()
                        Text("\(result.recipesSuccess)")
                            .fontWeight(.semibold)
                    }
                    
                    if result.recipesSkipped > 0 {
                        HStack {
                            Text("Recipes Skipped")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(result.recipesSkipped)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Books Migrated")
                        Spacer()
                        Text("\(result.booksSuccess)")
                            .fontWeight(.semibold)
                    }
                    
                    if result.booksSkipped > 0 {
                        HStack {
                            Text("Books Skipped")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(result.booksSkipped)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            if let validation = result.validation {
                validationSection(validation)
            }
            
            if result.hasErrors {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Errors", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(result.errorSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
    
    private func validationSection(_ validation: MigrationValidation) -> some View {
        GroupBox("Validation") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(validation.isValid ? .green : .red)
                    Text(validation.summary)
                        .font(.subheadline)
                }
                
                if !validation.errors.isEmpty || !validation.warnings.isEmpty {
                    Divider()
                    
                    Text(validation.detailedSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            // Migrate Button
            Button {
                Task {
                    await performMigration()
                }
            } label: {
                Label("Start Migration", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(stats?.totalLegacyItems == 0)
            
            // Delete Legacy Data Button (only after successful migration)
            if let result = migrationResult, result.isSuccess, !result.legacyDataDeleted {
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Legacy Data", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            // Refresh Stats
            Button {
                Task {
                    await loadStats()
                }
            } label: {
                Label("Refresh Status", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .confirmationDialog(
            "Delete Legacy Data?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteLegacyData()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all legacy Recipe and RecipeBook models. Your data is safe in the new RecipeX and Book models. This action cannot be undone.")
        }
    }
    
    // MARK: - Error Section
    
    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Error", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Migration Overlay
    
    private var migrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Migrating Data...")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("Please don't close the app")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(32)
            .background(Color(.systemGray))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Actions
    
    private func loadStats() async {
        let manager = LegacyToNewMigrationManager(modelContext: modelContext)
        migrationManager = manager
        stats = await manager.getMigrationStats()
    }
    
    private func performMigration() async {
        guard let manager = migrationManager else { return }
        
        isMigrating = true
        errorMessage = nil
        
        do {
            let result = try await manager.performMigration(
                deleteLegacyData: false,
                skipCloudSync: false
            )
            
            migrationResult = result
            
            // Refresh stats
            await loadStats()
            
            logInfo("✅ Migration completed: \(result.summary)", category: "migration")
            
        } catch {
            errorMessage = error.localizedDescription
            logError("❌ Migration failed: \(error)", category: "migration")
        }
        
        isMigrating = false
    }
    
    private func deleteLegacyData() async {
        guard let manager = migrationManager else { return }
        
        isMigrating = true
        errorMessage = nil
        
        do {
            let result = try await manager.performMigration(
                deleteLegacyData: true,
                skipCloudSync: false
            )
            
            migrationResult = result
            
            // Refresh stats
            await loadStats()
            
            logInfo("✅ Legacy data deleted successfully", category: "migration")
            
        } catch {
            errorMessage = error.localizedDescription
            logError("❌ Failed to delete legacy data: \(error)", category: "migration")
        }
        
        isMigrating = false
    }
}

#Preview {
    LegacyMigrationView()
        .modelContainer(for: [Recipe.self, RecipeX.self, RecipeBook.self, Book.self], inMemory: true)
}
