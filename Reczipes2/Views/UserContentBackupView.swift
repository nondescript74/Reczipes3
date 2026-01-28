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
    
    // Legacy models (for migration period)
    @Query private var recipes: [Recipe]
    @Query private var recipeBooks: [RecipeBook]
    
    // New unified models (CloudKit-compatible)
    @Query private var recipesX: [RecipeX]
    @Query private var books: [Book]
    
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
    
    // Model type selection for recipes
    @State private var selectedExportModelType: RecipeModelType = .all
    @State private var selectedImportModelType: RecipeModelType = .all
    
    // Model type selection for books
    @State private var selectedBookExportModelType: BookModelType = .all
    
    enum ContentType {
        case recipes
        case books
    }
    
    enum RecipeModelType: String, CaseIterable {
        case all = "All Recipes"
        case legacyOnly = "Legacy Only"
        case newOnly = "RecipeX Only"
        
        var description: String {
            switch self {
            case .all:
                return "Export both legacy and RecipeX models"
            case .legacyOnly:
                return "Export only legacy Recipe models"
            case .newOnly:
                return "Export only RecipeX models"
            }
        }
    }
    
    enum BookModelType: String, CaseIterable {
        case all = "All Books"
        case legacyOnly = "Legacy Only"
        case newOnly = "Book Only"
        
        var description: String {
            switch self {
            case .all:
                return "Export both legacy RecipeBooks and new Books"
            case .legacyOnly:
                return "Export only legacy RecipeBook models"
            case .newOnly:
                return "Export only new Book models"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Content Type", selection: $selectedTab) {
                    Text("Recipes (\(totalRecipeCount))").tag(ContentType.recipes)
                    Text("Books (\(totalBookCount))").tag(ContentType.books)
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
                allowedContentTypes: selectedTab == .recipes 
                    ? [.reczipesBackup] 
                    : [.recipeBook, .bookBackup, .zip],
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
                    Text("\(totalRecipeCount)")
                        .bold()
                }
                
                // Show breakdown of model types
                if recipes.count > 0 || recipesX.count > 0 {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.secondary)
                        Text("Legacy Recipes")
                        Spacer()
                        Text("\(recipes.count)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    
                    HStack {
                        Image(systemName: "doc.badge.gearshape")
                            .foregroundColor(.secondary)
                        Text("RecipeX (New Model)")
                        Spacer()
                        Text("\(recipesX.count)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
                
                if totalRecipeCount > 0 {
                    HStack {
                        Image(systemName: "photo.fill")
                            .foregroundColor(.orange)
                        Text("With Images")
                        Spacer()
                        Text("\(totalRecipesWithImages)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Export Section
            Section {
                // Model Type Picker (only show if both types exist)
                if recipes.count > 0 && recipesX.count > 0 {
                    Picker("Export Type", selection: $selectedExportModelType) {
                        ForEach(RecipeModelType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Show description
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(selectedExportModelType.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if recipesX.count > 0 {
                    // Only RecipeX available
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Only RecipeX models available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if recipes.count > 0 {
                    // Only legacy available
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Only legacy Recipe models available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
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
                        Label("Export Recipes", systemImage: "square.and.arrow.up")
                    }
                }
                .disabled(totalRecipeCount == 0 || isExporting || isImporting || !canExportWithSelectedType)
            } header: {
                Text("Export")
            } footer: {
                exportFooterText
            }
            
            // Import Section
            Section {
                Picker("Import Mode", selection: $selectedImportMode) {
                    Text("Keep Both").tag(ImportOverwriteMode.keepBoth)
                    Text("Skip Existing").tag(ImportOverwriteMode.skip)
                    Text("Overwrite").tag(ImportOverwriteMode.overwrite)
                }
                .pickerStyle(.menu)
                
                // Model Type Picker for import (only show if both types exist)
                if recipes.count > 0 || recipesX.count > 0 {
                    Picker("Import As", selection: $selectedImportModelType) {
                        ForEach(RecipeModelType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Show description
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(importModelTypeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
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
                    Text("\(totalBookCount)")
                        .bold()
                }
                
                // Show breakdown of model types
                if recipeBooks.count > 0 || books.count > 0 {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.secondary)
                        Text("Legacy Recipe Books")
                        Spacer()
                        Text("\(recipeBooks.count)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    
                    HStack {
                        Image(systemName: "doc.badge.gearshape")
                            .foregroundColor(.secondary)
                        Text("Books (New Model)")
                        Spacer()
                        Text("\(books.count)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
                
                if totalBookCount > 0 {
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
            if totalBookCount > 0 {
                Section {
                    // Model Type Picker (only show if both types exist)
                    if recipeBooks.count > 0 && books.count > 0 {
                        Picker("Export Type", selection: $selectedBookExportModelType) {
                            ForEach(BookModelType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        // Show description
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(selectedBookExportModelType.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if books.count > 0 {
                        // Only new Book available
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Only new Book models available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if recipeBooks.count > 0 {
                        // Only legacy available
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Only legacy RecipeBook models available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
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
                    .disabled(isExporting || isImporting || !canExportBooksWithSelectedType)
                } header: {
                    Text("Export All Books")
                } footer: {
                    bookExportFooterText
                }
            }
            
            // Export Individual Section
            Section {
                if totalBookCount == 0 {
                    Text("No recipe books to export")
                        .foregroundColor(.secondary)
                } else {
                    // Legacy RecipeBooks
                    if recipeBooks.count > 0 {
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
    
    /// Total recipe count (legacy + new models)
    private var totalRecipeCount: Int {
        recipes.count + recipesX.count
    }
    
    /// Total book count (legacy + new models)
    private var totalBookCount: Int {
        recipeBooks.count + books.count
    }
    
    /// Recipes with images (legacy model)
    private var recipesWithImages: Int {
        recipes.filter { $0.imageName != nil || !(($0.additionalImageNames ?? []).isEmpty) }.count
    }
    
    /// RecipesX with images (new model)
    private var recipesXWithImages: Int {
        recipesX.filter { $0.imageData != nil || $0.additionalImagesData != nil }.count
    }
    
    /// Combined recipes with images count
    private var totalRecipesWithImages: Int {
        recipesWithImages + recipesXWithImages
    }
    
    /// Total recipes in all books (legacy + new)
    private var totalRecipesInBooks: Int {
        let legacyCount = recipeBooks.reduce(0) { $0 + $1.recipeCount }
        let newCount = books.reduce(into: 0) { accumulator, book in
            accumulator += (book.recipeIDs?.count ?? 0)
        }
        return legacyCount + newCount
    }
    
    private var exportSuccessMessage: String {
        // Use the export-specific result if available
        if let result = exportResult {
            return result
        }
        
        // Fall back to default messages
        switch selectedTab {
        case .recipes:
            return "Backup created with \(totalRecipeCount) recipes. Share it to save somewhere safe."
        case .books:
            return "Recipe book exported successfully. You can now share it with others."
        }
    }
    
    /// Check if export is possible with selected model type
    private var canExportWithSelectedType: Bool {
        switch selectedExportModelType {
        case .all:
            return totalRecipeCount > 0
        case .legacyOnly:
            return recipes.count > 0
        case .newOnly:
            return recipesX.count > 0
        }
    }
    
    /// Export footer text based on selected model type
    private var exportFooterText: Text {
        switch selectedExportModelType {
        case .all:
            if recipes.count > 0 && recipesX.count > 0 {
                return Text("Creates a backup file containing all \(totalRecipeCount) recipes (\(recipes.count) legacy + \(recipesX.count) RecipeX) with their images.")
            } else if recipesX.count > 0 {
                return Text("Creates a backup file containing all \(recipesX.count) RecipeX recipes with their images.")
            } else {
                return Text("Creates a backup file containing all \(recipes.count) recipes with their images.")
            }
        case .legacyOnly:
            return Text("Creates a backup file containing \(recipes.count) legacy Recipe models with their images.")
        case .newOnly:
            return Text("Creates a backup file containing \(recipesX.count) RecipeX models with their images and CloudKit data.")
        }
    }
    
    /// Import model type description
    private var importModelTypeDescription: String {
        switch selectedImportModelType {
        case .all:
            return "Import recipes in their original format"
        case .legacyOnly:
            return "Import all recipes as legacy Recipe models"
        case .newOnly:
            return "Import all recipes as RecipeX models"
        }
    }
    
    /// Check if book export is possible with selected model type
    private var canExportBooksWithSelectedType: Bool {
        switch selectedBookExportModelType {
        case .all:
            return totalBookCount > 0
        case .legacyOnly:
            return recipeBooks.count > 0
        case .newOnly:
            return books.count > 0
        }
    }
    
    /// Book export footer text based on selected model type
    private var bookExportFooterText: Text {
        switch selectedBookExportModelType {
        case .all:
            if recipeBooks.count > 0 && books.count > 0 {
                return Text("Creates a backup of all \(totalBookCount) books (\(recipeBooks.count) legacy RecipeBooks + \(books.count) new Books).")
            } else if books.count > 0 {
                return Text("Creates a backup of all \(books.count) books with CloudKit sync data.")
            } else {
                return Text("Creates a complete backup of all \(recipeBooks.count) recipe books with their recipes and images.")
            }
        case .legacyOnly:
            return Text("Creates a backup of \(recipeBooks.count) legacy RecipeBook models with their recipes and images.")
        case .newOnly:
            return Text("Creates a backup of \(books.count) new Book models with CloudKit sync data.")
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
            let url: URL
            
            // Determine which recipes to export based on selected type
            switch selectedExportModelType {
            case .all:
                // Export both types using hybrid backup
                if recipes.count > 0 && recipesX.count > 0 {
                    url = try await RecipeBackupManager.shared.createHybridBackup(recipes: recipes, recipesX: recipesX)
                    exportResult = "Hybrid backup created with \(recipes.count) legacy recipes and \(recipesX.count) RecipeX recipes"
                } else if recipesX.count > 0 {
                    // RecipeX only
                    url = try await RecipeBackupManager.shared.createBackupX(from: recipesX)
                    exportResult = "Backup created with \(recipesX.count) RecipeX recipes"
                } else {
                    // Legacy Recipe only
                    url = try await RecipeBackupManager.shared.createBackup(from: recipes)
                    exportResult = "Backup created with \(recipes.count) recipes"
                }
                
            case .legacyOnly:
                // Export only legacy recipes
                guard recipes.count > 0 else {
                    throw RecipeBackupError.noRecipesToBackup
                }
                url = try await RecipeBackupManager.shared.createBackup(from: recipes)
                exportResult = "Backup created with \(recipes.count) legacy recipes"
                
            case .newOnly:
                // Export only RecipeX recipes
                guard recipesX.count > 0 else {
                    throw RecipeBackupError.noRecipesToBackup
                }
                url = try await RecipeBackupManager.shared.createBackupX(from: recipesX)
                exportResult = "Backup created with \(recipesX.count) RecipeX recipes with CloudKit sync data"
            }
            
            await MainActor.run {
                exportedURL = url
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
            // Import based on selected model type
            switch selectedImportModelType {
            case .all, .legacyOnly:
                // Import as legacy Recipe models
                let result = try await RecipeBackupManager.shared.importBackup(
                    from: backup.url,
                    into: modelContext,
                    existingRecipes: recipes,
                    overwriteMode: selectedImportMode
                )
                
                let modelNote = selectedImportModelType == .all 
                    ? "Imported in original format"
                    : "Imported as legacy Recipe models"
                
                importResult = "\(result.summary)\n\nTotal: \(result.totalRecipes) recipes\n\(modelNote)"
                
            case .newOnly:
                // Import as RecipeX models (with CloudKit sync)
                let result = try await RecipeBackupManager.shared.importBackupX(
                    from: backup.url,
                    into: modelContext,
                    existingRecipes: recipesX,
                    overwriteMode: selectedImportMode
                )
                
                importResult = "\(result.summary)\n\nTotal: \(result.totalRecipes) recipes\nImported as RecipeX models with CloudKit sync enabled"
            }
            
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
            
            // Import based on selected model type
            switch selectedImportModelType {
            case .all, .legacyOnly:
                // Import as legacy Recipe models
                let importResult = try await RecipeBackupManager.shared.importBackup(
                    from: url,
                    into: modelContext,
                    existingRecipes: recipes,
                    overwriteMode: selectedImportMode
                )
                
                let modelNote = selectedImportModelType == .all 
                    ? "Imported in original format"
                    : "Imported as legacy Recipe models"
                
                self.importResult = "\(importResult.summary)\n\nTotal: \(importResult.totalRecipes) recipes\n\(modelNote)"
                
            case .newOnly:
                // Import as RecipeX models (with CloudKit sync)
                let importResult = try await RecipeBackupManager.shared.importBackupX(
                    from: url,
                    into: modelContext,
                    existingRecipes: recipesX,
                    overwriteMode: selectedImportMode
                )
                
                self.importResult = "\(importResult.summary)\n\nTotal: \(importResult.totalRecipes) recipes\nImported as RecipeX models with CloudKit sync enabled"
            }
            
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
            let url: URL
            var resultMessage: String
            
            // Determine which books to export based on selected type
            switch selectedBookExportModelType {
            case .all:
                // Export both legacy RecipeBooks and new Books
                if recipeBooks.count > 0 && books.count > 0 {
                    // Create hybrid export with both types
                    url = try await exportHybridBooks()
                    resultMessage = "Successfully exported \(recipeBooks.count) legacy RecipeBooks and \(books.count) new Books"
                } else if books.count > 0 {
                    // Only new Books
                    url = try await BookBackupManager.shared.createBackup(from: books)
                    resultMessage = "Successfully exported \(books.count) new Books"
                } else if recipeBooks.count > 0 {
                    // Only legacy RecipeBooks
                    url = try await exportLegacyBooks(recipeBooks)
                    resultMessage = "Successfully exported \(recipeBooks.count) legacy RecipeBooks"
                } else {
                    throw RecipeBackupError.noRecipesToBackup
                }
                
            case .legacyOnly:
                guard recipeBooks.count > 0 else {
                    throw RecipeBackupError.noRecipesToBackup
                }
                url = try await exportLegacyBooks(recipeBooks)
                resultMessage = "Successfully exported \(recipeBooks.count) legacy RecipeBooks"
                
            case .newOnly:
                guard books.count > 0 else {
                    throw RecipeBackupError.noRecipesToBackup
                }
                url = try await BookBackupManager.shared.createBackup(from: books)
                resultMessage = "Successfully exported \(books.count) new Books with CloudKit sync data"
            }
            
            await MainActor.run {
                exportedURL = url
                exportResult = resultMessage
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
    
    /// Export legacy RecipeBook models (existing implementation)
    private func exportLegacyBooks(_ booksToExport: [RecipeBook]) async throws -> URL {
        // Create a temporary directory to hold all exported books
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AllBooksExport_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Export each book
        for book in booksToExport {
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
        
        return outputURL
    }
    
    /// Export hybrid package containing both legacy RecipeBooks and new Books
    private func exportHybridBooks() async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HybridBooksExport_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Export legacy RecipeBooks
        if recipeBooks.count > 0 {
            let legacyDir = tempDir.appendingPathComponent("LegacyRecipeBooks")
            try FileManager.default.createDirectory(at: legacyDir, withIntermediateDirectories: true)
            
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
                
                let fileName = sanitizeFileName(book.name)
                let destURL = legacyDir.appendingPathComponent("\(fileName).recipebook")
                try? FileManager.default.moveItem(at: bookURL, to: destURL)
            }
        }
        
        // Export new Books
        if books.count > 0 {
            let booksURL = try await BookBackupManager.shared.createBackup(from: books)
            let destURL = tempDir.appendingPathComponent("Books.bookbackup")
            try FileManager.default.copyItem(at: booksURL, to: destURL)
        }
        
        // Create ZIP of everything
        let outputFileName = "AllBooks_Hybrid_\(Date().ISO8601Format()).zip"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(outputFileName)
        
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
        
        if let error = coordinatorError ?? copyError {
            throw error
        }
        
        return outputURL
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
            
            // Check file extension to determine type
            let fileExtension = url.pathExtension.lowercased()
            
            if fileExtension == "bookbackup" {
                // New Book model import
                let importResult = try await BookBackupManager.shared.importBackup(
                    from: url,
                    into: modelContext,
                    existingBooks: books,
                    overwriteMode: selectedImportMode
                )
                
                self.importResult = "Successfully imported \(importResult.totalBooks) books.\n\(importResult.summary)"
                
            } else if fileExtension == "recipebook" {
                // Legacy RecipeBook import (single book)
                let importResult = try await RecipeBookImportService.shared.importBook(
                    from: url,
                    modelContext: modelContext,
                    importMode: .keepBoth
                )
                
                self.importResult = "Successfully imported '\(importResult.book.name)' with \(importResult.book.recipeCount) recipes."
                
            } else if fileExtension == "zip" {
                // Could be multiple legacy books or hybrid export
                try await handleZipBookImport(from: url)
                
            } else {
                errorMessage = "Unsupported file type: .\(fileExtension). Expected .bookbackup, .recipebook, or .zip"
                isImporting = false
                return
            }
            
            showImportSuccess = true
            loadAvailableBackups()
            
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
        
        isImporting = false
    }
    
    /// Handles importing from ZIP files (legacy RecipeBooks or hybrid exports)
    private func handleZipBookImport(from url: URL) async throws {
        // Create temp extraction directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BookZipImport_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Extract ZIP
        try RecipeBookExportService.extractZipArchive(from: url, to: tempDir)
        
        // Check what's in the ZIP
        let contents = try FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        )
        
        var legacyBooksImported = 0
        var newBooksImported = 0
        
        // Look for .bookbackup file (new Book models)
        if let bookbackupFile = contents.first(where: { $0.pathExtension == "bookbackup" }) {
            let importResult = try await BookBackupManager.shared.importBackup(
                from: bookbackupFile,
                into: modelContext,
                existingBooks: books,
                overwriteMode: selectedImportMode
            )
            newBooksImported = importResult.totalBooks
        }
        
        // Look for .recipebook files or LegacyRecipeBooks directory
        let legacyBooksDir = tempDir.appendingPathComponent("LegacyRecipeBooks")
        let searchDirs = [tempDir, legacyBooksDir]
        
        for searchDir in searchDirs {
            guard FileManager.default.fileExists(atPath: searchDir.path) else { continue }
            
            let files = try FileManager.default.contentsOfDirectory(
                at: searchDir,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: []
            )
            
            let recipeBookFiles = files.filter { $0.pathExtension == "recipebook" }
            
            for recipeBookFile in recipeBookFiles {
                do {
                    _ = try await RecipeBookImportService.shared.importBook(
                        from: recipeBookFile,
                        modelContext: modelContext,
                        importMode: .keepBoth
                    )
                    legacyBooksImported += 1
                } catch {
                    logError("Failed to import legacy book \(recipeBookFile.lastPathComponent): \(error)", category: "backup")
                }
            }
        }
        
        // Build result message
        var resultParts: [String] = []
        if newBooksImported > 0 {
            resultParts.append("\(newBooksImported) new Books")
        }
        if legacyBooksImported > 0 {
            resultParts.append("\(legacyBooksImported) legacy RecipeBooks")
        }
        
        if resultParts.isEmpty {
            throw RecipeBackupError.invalidBackupFile
        }
        
        importResult = "Successfully imported: \(resultParts.joined(separator: ", "))"
    }
}

#Preview {
    NavigationView {
        UserContentBackupView()
            .modelContainer(for: [Recipe.self, RecipeX.self, RecipeBook.self, Book.self], inMemory: true)
    }
}
// MARK: - UTType Extensions

extension UTType {
    static var bookBackup: UTType {
        UTType(exportedAs: "com.reczipes.bookbackup")
    }
}

