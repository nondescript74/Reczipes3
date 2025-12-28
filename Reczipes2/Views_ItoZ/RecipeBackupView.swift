//
//  RecipeBackupView.swift
//  Reczipes2
//
//  Created by Xcode Assistant on 12/20/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

struct RecipeBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.dateAdded, order: .reverse) private var savedRecipes: [Recipe]
    
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingImportPicker = false
    @State private var showingShareSheet = false
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var backupURL: URL?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Export Recipes", systemImage: "square.and.arrow.up")
                            .font(.headline)
                        
                        Text("Create a backup file containing all your recipes with their images. You can share this file and import it later or on another device.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if savedRecipes.isEmpty {
                            Text("No recipes to export")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        } else {
                            Text("\(savedRecipes.count) recipe(s) ready to export")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Button {
                        Task {
                            await exportRecipes()
                        }
                    } label: {
                        HStack {
                            Text("Export All Recipes")
                            Spacer()
                            if isExporting {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.up.doc")
                            }
                        }
                    }
                    .disabled(savedRecipes.isEmpty || isExporting)
                } header: {
                    Text("Backup")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Import Recipes", systemImage: "square.and.arrow.down")
                            .font(.headline)
                        
                        Text("Import recipes from a backup file (.reczipes). You can choose how to handle recipes that already exist in your collection.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    Button {
                        showingImportPicker = true
                    } label: {
                        HStack {
                            Text("Import Recipes")
                            Spacer()
                            if isImporting {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.down.doc")
                            }
                        }
                    }
                    .disabled(isImporting)
                } header: {
                    Text("Restore")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("Backup files are self-contained")
                                .font(.subheadline)
                        }
                        
                        Text("Each backup file includes all recipe data, notes, and associated images. Files can be shared via email, AirDrop, or cloud storage.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 32)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .foregroundStyle(.green)
                            Text("Compatible across devices")
                                .font(.subheadline)
                        }
                        
                        Text("Backup files work on iPhone, iPad, and Mac. Use them to sync recipes across your devices or share with friends.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 32)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About Backups")
                }
            }
            .navigationTitle("Backup & Restore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloudKitSyncBadge()
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [UTType(filenameExtension: "reczipes") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    await handleImport(result)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = backupURL {
                    #if os(iOS)
                    ShareSheet(activityItems: [url])
                    #else
                    // macOS: Use NSSharingService or save panel
                    EmptyView()
                    #endif
                }
            }
            .alert("Export Successful", isPresented: $showingSuccess) {
                Button("OK") {
                    successMessage = ""
                }
            } message: {
                Text(successMessage)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    errorMessage = ""
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Export
    
    private func exportRecipes() async {
        isExporting = true
        defer { isExporting = false }
        
        do {
            let url = try await RecipeBackupManager.shared.createBackup(from: savedRecipes)
            backupURL = url
            successMessage = "Backup created successfully with \(savedRecipes.count) recipe(s)"
            
            #if os(iOS)
            showingShareSheet = true
            #else
            // macOS: Show save panel
            await showMacOSSavePanel(url: url)
            #endif
            
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    #if os(macOS)
    @MainActor
    private func showMacOSSavePanel(url: URL) async {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = url.lastPathComponent
        savePanel.allowedContentTypes = [UTType(filenameExtension: "reczipes") ?? .data]
        savePanel.canCreateDirectories = true
        
        let response = savePanel.runModal()
        if response == .OK, let destinationURL = savePanel.url {
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: url, to: destinationURL)
            } catch {
                errorMessage = "Failed to save file: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    #endif
    
    // MARK: - Import
    
    private func handleImport(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Check for duplicate recipes
            await checkForDuplicatesAndImport(url)
            
        case .failure(let error):
            errorMessage = "Failed to open file: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func checkForDuplicatesAndImport(_ url: URL) async {
        isImporting = true
        defer { isImporting = false }
        
        // First, peek at the backup to check for duplicates
        guard let package = try? decodeBackupPackage(from: url) else {
            errorMessage = "Invalid backup file format"
            showingError = true
            return
        }
        
        let duplicateIDs = package.recipes.filter { backup in
            savedRecipes.contains { $0.id == backup.recipe.id }
        }
        
        if duplicateIDs.isEmpty {
            // No duplicates, import directly
            await performImport(url, mode: .skip)
        } else {
            // Show conflict resolution dialog
            await showConflictResolution(url, duplicateCount: duplicateIDs.count)
        }
    }
    
    private func decodeBackupPackage(from url: URL) throws -> RecipeBackupPackage? {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(RecipeBackupPackage.self, from: data)
    }
    
    @MainActor
    private func showConflictResolution(_ url: URL, duplicateCount: Int) async {
        #if os(iOS)
        // Show alert with options
        let alert = UIAlertController(
            title: "Duplicate Recipes Found",
            message: "\(duplicateCount) recipe(s) already exist in your collection. How would you like to proceed?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Skip Existing", style: .default) { _ in
            Task {
                await self.performImport(url, mode: .skip)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Overwrite Existing", style: .destructive) { _ in
            Task {
                await self.performImport(url, mode: .overwrite)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Keep Both", style: .default) { _ in
            Task {
                await self.performImport(url, mode: .keepBoth)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present the alert
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = scene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
        #else
        // macOS: Show SwiftUI dialog
        let alert = NSAlert()
        alert.messageText = "Duplicate Recipes Found"
        alert.informativeText = "\(duplicateCount) recipe(s) already exist in your collection. How would you like to proceed?"
        alert.addButton(withTitle: "Skip Existing")
        alert.addButton(withTitle: "Overwrite Existing")
        alert.addButton(withTitle: "Keep Both")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            await performImport(url, mode: .skip)
        case .alertSecondButtonReturn:
            await performImport(url, mode: .overwrite)
        case .alertThirdButtonReturn:
            await performImport(url, mode: .keepBoth)
        default:
            break
        }
        #endif
    }
    
    private func performImport(_ url: URL, mode: ImportOverwriteMode) async {
        do {
            let result = try await RecipeBackupManager.shared.importBackup(
                from: url,
                into: modelContext,
                existingRecipes: savedRecipes,
                overwriteMode: mode
            )
            
            successMessage = "Import complete: \(result.summary)"
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Share Sheet (iOS)

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    RecipeBackupView()
        .modelContainer(for: [Recipe.self], inMemory: true)
}
