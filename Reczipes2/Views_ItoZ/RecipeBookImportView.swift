//
//  RecipeBookImportView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct RecipeBookImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var isImporting = false
    @State private var showingFilePicker = false
    @State private var importError: Error?
    @State private var showingError = false
    @State private var importedBook: RecipeBook?
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "book.closed.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                
                // Title and description
                VStack(spacing: 8) {
                    Text("Import Recipe Book")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Import a recipe book from a .recipebook file shared from another device")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Import button
                Button {
                    showingFilePicker = true
                } label: {
                    Label("Choose File", systemImage: "folder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .disabled(isImporting)
                
                // Info section
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(
                        icon: "book.pages",
                        title: "Complete Books",
                        description: "Import entire recipe collections with all recipes"
                    )
                    
                    InfoRow(
                        icon: "photo.on.rectangle",
                        title: "Images Included",
                        description: "All recipe photos and book covers are preserved"
                    )
                    
                    InfoRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Automatic Updates",
                        description: "Existing recipes are updated, new ones are added"
                    )
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType(filenameExtension: "recipebook") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import Failed", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                if let error = importError {
                    Text(error.localizedDescription)
                }
            }
            .alert("Import Successful", isPresented: $showingSuccess) {
                Button("View Book") {
                    dismiss()
                    // You might want to pass a callback to navigate to the book
                }
                Button("Done") {
                    dismiss()
                }
            } message: {
                if let book = importedBook {
                    Text("Successfully imported \"\(book.name)\" with \(book.recipeCount) recipes")
                }
            }
            .overlay {
                if isImporting {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Importing Recipe Book...")
                                .font(.headline)
                            Text("This may take a moment...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(32)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }
    
    // MARK: - Import Handler
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                await importBook(from: url)
            }
            
        case .failure(let error):
            importError = error
            showingError = true
            logError("File picker error: \(error)", category: "book-import")
        }
    }
    
    private func importBook(from url: URL) async {
        isImporting = true
        importError = nil
        
        do {
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                throw ImportError.accessDenied
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Copy to temporary location
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)
            
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            
            try FileManager.default.copyItem(at: url, to: tempURL)
            
            // Import the book
            let book = try await RecipeBookExportService.importBook(
                from: tempURL,
                modelContext: modelContext,
                replaceExisting: false
            )
            
            await MainActor.run {
                importedBook = book
                isImporting = false
                showingSuccess = true
            }
            
            logInfo("Successfully imported book: \(book.name)", category: "book-import")
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            await MainActor.run {
                importError = error
                isImporting = false
                showingError = true
            }
            logError("Import failed: \(error)", category: "book-import")
        }
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
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

// MARK: - Import Error

enum ImportError: LocalizedError {
    case accessDenied
    case invalidFormat
    case missingData
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Unable to access the selected file"
        case .invalidFormat:
            return "The selected file is not a valid recipe book"
        case .missingData:
            return "The recipe book file is missing required data"
        }
    }
}

#Preview {
    RecipeBookImportView()
        .modelContainer(for: RecipeBook.self, inMemory: true)
}
