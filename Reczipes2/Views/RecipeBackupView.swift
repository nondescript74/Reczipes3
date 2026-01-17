//
//  RecipeBackupView.swift
//  Reczipes2
//
//  Complete backup and restore UI for all recipes
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct RecipeBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var recipes: [Recipe]
    
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showImportPicker = false
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var showShareSheet = false
    @State private var exportedURL: URL?
    @State private var errorMessage: String?
    @State private var importResult: RecipeImportResult?
    @State private var selectedImportMode: ImportOverwriteMode = .keepBoth
    @State private var availableBackups: [BackupFileInfo] = []
    @State private var selectedBackup: BackupFileInfo?
    
    var body: some View {
        List {
            // Current Status
            Section("Current Database") {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(.blue)
                    Text("Total Recipes")
                    Spacer()
                    Text("\(recipes.count)")
                        .bold()
                }
                
                if recipes.count > 0 {
                    HStack {
                        Image(systemName: "photo.fill")
                            .foregroundColor(.orange)
                        Text("With Images")
                        Spacer()
                        Text("\(recipesWithImages)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Export Section
            Section {
                Button {
                    Task {
                        await exportRecipes()
                    }
                } label: {
                    if isExporting {
                        HStack {
                            ProgressView()
                            Text("Exporting...")
                        }
                    } else {
                        Label("Export All Recipes", systemImage: "square.and.arrow.up")
                    }
                }
                .disabled(recipes.isEmpty || isExporting || isImporting)
            } header: {
                Text("Export")
            } footer: {
                Text("Creates a backup file (.reczipes) containing all \(recipes.count) recipes with their images. You can import this file later to restore your recipes.")
            }
            
            // Import Section
            Section {
                Picker("Import Mode", selection: $selectedImportMode) {
                    Text("Keep Both").tag(ImportOverwriteMode.keepBoth)
                    Text("Skip Existing").tag(ImportOverwriteMode.skip)
                    Text("Overwrite").tag(ImportOverwriteMode.overwrite)
                }
                .pickerStyle(.menu)
                
                // Show available backups from Reczipes2 folder
                if !availableBackups.isEmpty {
                    ForEach(availableBackups) { backup in
                        Button {
                            selectedBackup = backup
                            Task {
                                await importFromBackup(backup)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(backup.displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        Text(backup.modificationDate, style: .date)
                                        Text("•")
                                        Text(backup.fileSizeFormatted)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if isImporting && selectedBackup?.id == backup.id {
                                    ProgressView()
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .disabled(isImporting || isExporting)
                    }
                } else {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundColor(.secondary)
                        Text("No backups found in Reczipes2 folder")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Option to import from other location
                Button {
                    showImportPicker = true
                } label: {
                    Label("Import from Other Location", systemImage: "folder")
                }
                .disabled(isExporting || isImporting)
            } header: {
                HStack {
                    Text("Import")
                    Spacer()
                    Button {
                        loadAvailableBackups()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import recipes from a backup file (.reczipes).")
                    
                    Text("Import Modes:")
                        .font(.caption)
                        .bold()
                    
                    Text("• Keep Both: Imports all recipes, even duplicates")
                        .font(.caption)
                    Text("• Skip Existing: Only imports new recipes")
                        .font(.caption)
                    Text("• Overwrite: Replaces existing recipes with imported ones")
                        .font(.caption)
                }
            }
            
            // Tips Section
            Section("Tips") {
                tipRow(icon: "exclamationmark.triangle", text: "Always backup before reinstalling the app")
                tipRow(icon: "icloud.and.arrow.up", text: "Store backups in iCloud Drive or Files for safety")
                tipRow(icon: "arrow.triangle.2.circlepath", text: "Use 'Keep Both' mode to avoid losing any recipes")
            }
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAvailableBackups()
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.reczipesBackup],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await handleImport(result: result)
            }
        }
        .sheet(isPresented: $showExportSuccess) {
            if let url = exportedURL {
                BackupShareSheet(activityItems: [url])
            }
        }
        .alert("Export Successful", isPresented: $showExportSuccess) {
            Button("Share") {
                // Sheet will show automatically
            }
            Button("Done", role: .cancel) { }
        } message: {
            Text("Backup created with \(recipes.count) recipes. Share it to save somewhere safe.")
        }
        .alert("Import Successful", isPresented: $showImportSuccess) {
            Button("OK") { }
        } message: {
            if let result = importResult {
                Text("\(result.summary)\n\nTotal: \(result.totalRecipes) recipes")
            }
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
    
    // MARK: - Helpers
    
    private var recipesWithImages: Int {
        recipes.filter { $0.imageName != nil || !(($0.additionalImageNames ?? []).isEmpty) }.count
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
    
    // MARK: - Export
    
    private func exportRecipes() async {
        isExporting = true
        errorMessage = nil
        
        do {
            let url = try await RecipeBackupManager.shared.createBackup(from: recipes)
            
            await MainActor.run {
                exportedURL = url
                // Show share sheet directly instead of alert
                showShareSheet = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Export failed: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isExporting = false
        }
    }
    
    // MARK: - Import
    
    private func loadAvailableBackups() {
        do {
            availableBackups = try RecipeBackupManager.shared.listAvailableBackups()
        } catch {
            logError("Failed to load available backups: \(error)", category: "backup")
            availableBackups = []
        }
    }
    
    private func importFromBackup(_ backup: BackupFileInfo) async {
        isImporting = true
        errorMessage = nil
        
        do {
            let result = try await RecipeBackupManager.shared.importBackup(
                from: backup.url,
                into: modelContext,
                existingRecipes: recipes,
                overwriteMode: selectedImportMode
            )
            
            importResult = result
            showImportSuccess = true
            
            // Refresh the backup list
            loadAvailableBackups()
            
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
        
        isImporting = false
    }
    
    private func handleImport(result: Result<[URL], Error>) async {
        isImporting = true
        errorMessage = nil
        
        do {
            let urls = try result.get()
            guard let url = urls.first else {
                errorMessage = "No file selected"
                isImporting = false
                return
            }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access file"
                isImporting = false
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            let result = try await RecipeBackupManager.shared.importBackup(
                from: url,
                into: modelContext,
                existingRecipes: recipes,
                overwriteMode: selectedImportMode
            )
            
            importResult = result
            showImportSuccess = true
            
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
        
        isImporting = false
    }
}

// MARK: - Custom UTType for .reczipes files

extension UTType {
    static var reczipesBackup: UTType {
        UTType(exportedAs: "com.reczipes.backup")
    }
}

// MARK: - Backup-specific Share Sheet (to avoid conflicts)

struct BackupShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    NavigationView {
        RecipeBackupView()
            .modelContainer(for: Recipe.self)
    }
}
