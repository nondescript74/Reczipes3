//
//  UserContentBackupView.swift
//  Reczipes2
//
//  Created by Xcode Assistant on 01/09/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Comprehensive backup and restore view for all user content (recipes and recipe books)
struct UserContentBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var recipes: [Recipe]
    @Query private var recipeBooks: [RecipeBook]
    
    @State private var selectedTab: ContentType = .recipes
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var showShareSheet = false
    @State private var exportedURL: URL?
    @State private var errorMessage: String?
    @State private var importResult: String?
    @State private var exportResult: String?
    @State private var showImportPicker = false
    @State private var selectedImportMode: ImportOverwriteMode = .keepBoth
    @State private var availableRecipeBackups: [BackupFileInfo] = []
    @State private var availableBookBackups: [URL] = []
    @State private var selectedBackup: BackupFileInfo?
    
    enum ContentType {
        case recipes
        case books
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Content Type", selection: $selectedTab) {
                    Text("Recipes (\(recipes.count))").tag(ContentType.recipes)
                    Text("Books (\(recipeBooks.count))").tag(ContentType.books)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                Group {
                    switch selectedTab {
                    case .recipes:
                        recipeBackupView
                    case .books:
                        booksBackupView
                    }
                }
            }
            .navigationTitle("User Content Import/Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAvailableBackups()
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: selectedTab == .recipes ? [.reczipesBackup] : [UTType(filenameExtension: "recipebook") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    if selectedTab == .recipes {
                        await handleRecipeImport(result: result)
                    } else {
                        await handleBookImport(result: result)
                    }
                }
            }
            .alert("Export Successful", isPresented: $showExportSuccess) {
                Button("Share") {
                    showShareSheet = true
                }
                Button("Done", role: .cancel) { }
            } message: {
                Text(exportSuccessMessage)
            }
            .alert("Import Successful", isPresented: $showImportSuccess) {
                Button("OK") { }
            } message: {
                if let result = importResult {
                    Text(result)
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
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    BackupShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    // MARK: - Recipe Backup View
    
    private var recipeBackupView: some View {
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
                Text("Creates a backup file (.reczipes) containing all \(recipes.count) recipes with their images.")
            }
            
            // Import Section
            Section {
                Picker("Import Mode", selection: $selectedImportMode) {
                    Text("Keep Both").tag(ImportOverwriteMode.keepBoth)
                    Text("Skip Existing").tag(ImportOverwriteMode.skip)
                    Text("Overwrite").tag(ImportOverwriteMode.overwrite)
                }
                .pickerStyle(.menu)
                
                // Show available backups
                if !availableRecipeBackups.isEmpty {
                    ForEach(availableRecipeBackups) { backup in
                        Button {
                            selectedBackup = backup
                            Task {
                                await importFromRecipeBackup(backup)
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
                        Text("No backups found")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Import from other location
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
                importModeFooter
            }
        }
    }
    
    // MARK: - Books Backup View
    
    private var booksBackupView: some View {
        List {
            // Current Status
            Section("Current Library") {
                HStack {
                    Image(systemName: "books.vertical.fill")
                        .foregroundColor(.blue)
                    Text("Total Books")
                    Spacer()
                    Text("\(recipeBooks.count)")
                        .bold()
                }
                
                if recipeBooks.count > 0 {
                    HStack {
                        Image(systemName: "book.pages.fill")
                            .foregroundColor(.orange)
                        Text("Total Recipes in Books")
                        Spacer()
                        Text("\(totalRecipesInBooks)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Export All Section
            if !recipeBooks.isEmpty {
                Section {
                    Button {
                        Task {
                            await exportAllBooks()
                        }
                    } label: {
                        if isExporting {
                            HStack {
                                ProgressView()
                                Text("Exporting All Books...")
                            }
                        } else {
                            Label("Export All Books", systemImage: "square.and.arrow.up.on.square")
                        }
                    }
                    .disabled(isExporting || isImporting)
                } header: {
                    Text("Export All Books")
                } footer: {
                    Text("Creates a complete backup of all \(recipeBooks.count) recipe books with their recipes and images.")
                }
            }
            
            // Export Individual Section
            Section {
                if recipeBooks.isEmpty {
                    Text("No recipe books to export")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(recipeBooks) { book in
                        Button {
                            Task {
                                await exportBook(book)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(book.recipeCount) recipes")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if isExporting {
                                    ProgressView()
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .disabled(isExporting || isImporting)
                    }
                }
            } header: {
                Text("Export Individual Books")
            } footer: {
                Text("Export a single book as a .recipebook file to share with others or backup separately.")
            }
            
            // Import Section
            Section {
                Button {
                    showImportPicker = true
                } label: {
                    Label("Import Recipe Book", systemImage: "square.and.arrow.down")
                }
                .disabled(isExporting || isImporting)
                
                if isImporting {
                    HStack {
                        ProgressView()
                        Text("Importing book...")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Import")
            } footer: {
                Text("Import a .recipebook file shared from another device. The book and all its recipes will be added to your library.")
            }
            
            // Info Section
            Section("About Recipe Books") {
                InfoRow(
                    icon: "book.pages",
                    title: "Complete Collections",
                    description: "Each book contains its recipes and all associated images"
                )
                
                InfoRow(
                    icon: "square.and.arrow.up.on.square",
                    title: "Easy Sharing",
                    description: "Share entire recipe collections with friends and family"
                )
                
                InfoRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Smart Import",
                    description: "Books are merged intelligently to avoid duplicates"
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var importModeFooter: some View {
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
    
    private struct InfoRow: View {
        let icon: String
        let title: String
        let description: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var recipesWithImages: Int {
        recipes.filter { $0.imageName != nil || !(($0.additionalImageNames ?? []).isEmpty) }.count
    }
    
    private var totalRecipesInBooks: Int {
        recipeBooks.reduce(0) { $0 + $1.recipeCount }
    }
    
    private var exportSuccessMessage: String {
        // Use the export-specific result if available
        if let result = exportResult {
            return result
        }
        
        // Fall back to default messages
        switch selectedTab {
        case .recipes:
            return "Backup created with \(recipes.count) recipes. Share it to save somewhere safe."
        case .books:
            return "Recipe book exported successfully. You can now share it with others."
        }
    }
    
    // MARK: - Actions
    
    private func loadAvailableBackups() {
        // Load recipe backups
        do {
            availableRecipeBackups = try RecipeBackupManager.shared.listAvailableBackups()
        } catch {
            logError("Failed to load available backups: \(error)", category: "backup")
            availableRecipeBackups = []
        }
        
        // Load book backups (from Reczipes2 folder)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let reczipesDirectory = documentsDirectory.appendingPathComponent("Reczipes2", isDirectory: true)
        
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: reczipesDirectory,
            includingPropertiesForKeys: nil
        ) {
            availableBookBackups = contents.filter { $0.pathExtension == "recipebook" }
        }
    }
    
    // MARK: - Recipe Export/Import
    
    private func exportRecipes() async {
        isExporting = true
        errorMessage = nil
        exportResult = nil
        
        do {
            let url = try await RecipeBackupManager.shared.createBackup(from: recipes)
            
            await MainActor.run {
                exportedURL = url
                exportResult = "Backup created with \(recipes.count) recipes. Share it to save somewhere safe."
                showExportSuccess = true
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
    
    private func importFromRecipeBackup(_ backup: BackupFileInfo) async {
        isImporting = true
        errorMessage = nil
        
        do {
            let result = try await RecipeBackupManager.shared.importBackup(
                from: backup.url,
                into: modelContext,
                existingRecipes: recipes,
                overwriteMode: selectedImportMode
            )
            
            importResult = "\(result.summary)\n\nTotal: \(result.totalRecipes) recipes"
            showImportSuccess = true
            
            loadAvailableBackups()
            
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
        
        isImporting = false
    }
    
    private func handleRecipeImport(result: Result<[URL], Error>) async {
        isImporting = true
        errorMessage = nil
        
        do {
            let urls = try result.get()
            guard let url = urls.first else {
                errorMessage = "No file selected"
                isImporting = false
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access file"
                isImporting = false
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            let importResult = try await RecipeBackupManager.shared.importBackup(
                from: url,
                into: modelContext,
                existingRecipes: recipes,
                overwriteMode: selectedImportMode
            )
            
            self.importResult = "\(importResult.summary)\n\nTotal: \(importResult.totalRecipes) recipes"
            showImportSuccess = true
            
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
        
        isImporting = false
    }
    
    // MARK: - Book Export/Import
    
    private func exportAllBooks() async {
        isExporting = true
        errorMessage = nil
        exportResult = nil
        
        do {
            // Create a temporary directory to hold all exported books
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("AllBooksExport_\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            defer {
                try? FileManager.default.removeItem(at: tempDir)
            }
            
            // Export each book
            var exportedCount = 0
            for book in recipeBooks {
                let bookRecipeModels = book.recipeIDs.compactMap { recipeID -> RecipeModel? in
                    guard let recipe = recipes.first(where: { $0.id == recipeID }),
                          let recipeModel = recipe.toRecipeModel() else {
                        return nil
                    }
                    return recipeModel
                }
                
                let bookURL = try await RecipeBookExportService.exportBook(
                    book,
                    recipes: bookRecipeModels,
                    includeImages: true
                )
                
                // Move to temp directory with a clean name
                let fileName = sanitizeFileName(book.name)
                let destURL = tempDir.appendingPathComponent("\(fileName).recipebook")
                try? FileManager.default.moveItem(at: bookURL, to: destURL)
                
                exportedCount += 1
            }
            
            // Create a ZIP of all books
            let outputFileName = "AllRecipeBooks_\(Date().ISO8601Format()).zip"
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(outputFileName)
            
            // Use FileManager's native zipping
            let coordinator = NSFileCoordinator()
            var coordinatorError: NSError?
            var copyError: NSError?
            
            coordinator.coordinate(readingItemAt: tempDir, options: [.forUploading], error: &coordinatorError) { zipURL in
                do {
                    if FileManager.default.fileExists(atPath: outputURL.path) {
                        try FileManager.default.removeItem(at: outputURL)
                    }
                    try FileManager.default.copyItem(at: zipURL, to: outputURL)
                } catch {
                    copyError = error as NSError
                }
            }
            
            // Check for errors from either the coordinator or the copy operation
            if let error = coordinatorError ?? copyError {
                throw error
            }
            
            await MainActor.run {
                exportedURL = outputURL
                exportResult = "Successfully exported \(exportedCount) recipe books"
                showExportSuccess = true
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Export all books failed: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isExporting = false
        }
    }
    
    private func exportBook(_ book: RecipeBook) async {
        isExporting = true
        errorMessage = nil
        exportResult = nil
        
        do {
            // Get recipes in this book
            let bookRecipeModels = book.recipeIDs.compactMap { recipeID -> RecipeModel? in
                guard let recipe = recipes.first(where: { $0.id == recipeID }),
                      let recipeModel = recipe.toRecipeModel() else {
                    return nil
                }
                return recipeModel
            }
            
            let url = try await RecipeBookExportService.exportBook(
                book,
                recipes: bookRecipeModels,
                includeImages: true
            )
            
            await MainActor.run {
                exportedURL = url
                exportResult = "Recipe book '\(book.name)' exported successfully with \(book.recipeCount) recipes."
                showExportSuccess = true
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
    
    private func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    private func handleBookImport(result: Result<[URL], Error>) async {
        isImporting = true
        errorMessage = nil
        
        do {
            let urls = try result.get()
            guard let url = urls.first else {
                errorMessage = "No file selected"
                isImporting = false
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access file"
                isImporting = false
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            let importResult = try await RecipeBookImportService.shared.importBook(
                from: url,
                modelContext: modelContext,
                importMode: .keepBoth
            )
            
            self.importResult = "Successfully imported '\(importResult.book.name)' with \(importResult.book.recipeCount) recipes."
            showImportSuccess = true
            
            loadAvailableBackups()
            
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
        
        isImporting = false
    }
}

#Preview {
    NavigationView {
        UserContentBackupView()
            .modelContainer(for: [Recipe.self, RecipeBook.self], inMemory: true)
    }
}
