//
//  BookExampleView.swift
//  Reczipes2
//
//  Created on 1/26/26.
//
//  Example view demonstrating how to use the unified Book model

import SwiftUI
import SwiftData

struct BookExampleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateModified, order: .reverse) private var books: [Book]
    
    @State private var showingCreateBook = false
    @State private var showingMigration = false
    @State private var selectedBook: Book?
    
    var body: some View {
        NavigationStack {
            List {
                // My Books Section
                Section("My Books") {
                    ForEach(ownedBooks) { book in
                        BookRow(book: book)
                            .onTapGesture {
                                selectedBook = book
                            }
                    }
                }
                
                // Imported Books Section
                Section("Imported Books") {
                    ForEach(importedBooks) { book in
                        BookRow(book: book)
                            .onTapGesture {
                                selectedBook = book
                            }
                    }
                }
                
                // Needs Sync Section
                if !needsSyncBooks.isEmpty {
                    Section("Needs Sync") {
                        ForEach(needsSyncBooks) { book in
                            BookRow(book: book)
                                .badge(book.statusIcon)
                        }
                    }
                }
            }
            .navigationTitle("Books")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateBook = true
                    } label: {
                        Label("New Book", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showingMigration = true
                    } label: {
                        Label("Migration", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingCreateBook) {
                CreateBookView()
            }
            .sheet(isPresented: $showingMigration) {
                BookMigrationView()
            }
            .sheet(item: $selectedBook) { book in
                BookDetailView_BEV(book: book)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var ownedBooks: [Book] {
        books.filter { $0.isOwnedByCurrentUser }
    }
    
    private var importedBooks: [Book] {
        books.filter { $0.isImported == true }
    }
    
    private var needsSyncBooks: [Book] {
        books.filter { $0.needsCloudSync == true }
    }
}

// MARK: - Book Row

struct BookRow: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover Image
            if let imageData = book.coverImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 80)
                    .overlay {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.secondary)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.displayName)
                    .font(.headline)
                
                if let description = book.bookDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    Label("\(book.recipeCount)", systemImage: "fork.knife")
                    
                    if book.isImported == true,
                       let ownerName = book.originalOwnerDisplayName {
                        Label(ownerName, systemImage: "person.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Status indicators
            VStack(alignment: .trailing, spacing: 4) {
                if book.isShared == true {
                    Image(systemName: "icloud.fill")
                        .foregroundStyle(.blue)
                }
                
                if book.needsCloudSync == true {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Book View

struct CreateBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor: Color = .blue
    @State private var coverImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Book Name", text: $name)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Appearance") {
                    ColorPicker("Theme Color", selection: $selectedColor)
                    
                    Button {
                        showingImagePicker = true
                    } label: {
                        if let image = coverImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("Add Cover Image", systemImage: "photo")
                        }
                    }
                }
            }
            .navigationTitle("New Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createBook()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createBook() {
        let book = Book(
            name: name,
            bookDescription: description.isEmpty ? nil : description,
            coverImageData: coverImage?.jpegData(compressionQuality: 0.8),
            color: selectedColor.toHexString(),
            needsCloudSync: true,
            isShared: true
        )
        
        modelContext.insert(book)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error creating book: \(error.localizedDescription)")
        }
    }
}

// MARK: - Book Detail View

struct BookDetailView_BEV: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddContent = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Cover Image
                    if let imageData = book.coverImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    }
                    
                    // Book Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(book.displayName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let description = book.bookDescription {
                            Text(description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Statistics
                        HStack(spacing: 20) {
                            StatItem(icon: "fork.knife", value: "\(book.recipeCount)", label: "Recipes")
                            StatItem(icon: "photo", value: "\(book.images.count)", label: "Images")
                            StatItem(icon: "list.bullet", value: "\(book.instructions.count)", label: "Guides")
                            StatItem(icon: "book.closed", value: "\(book.glossary.count)", label: "Terms")
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    
                    // Content Sections
                    if book.recipeCount > 0 {
                        RecipesSection(book: book)
                    }
                    
                    if !book.instructions.isEmpty {
                        InstructionsSection(instructions: book.instructions)
                    }
                    
                    if !book.glossary.isEmpty {
                        GlossarySection(entries: book.glossary)
                    }
                    
                    // Sharing Info
                    if book.isShared == true {
                        SharingInfoSection(book: book)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddContent = true
                        } label: {
                            Label("Add Content", systemImage: "plus")
                        }
                        
                        Button {
                            toggleSharing()
                        } label: {
                            if book.isShared == true {
                                Label("Stop Sharing", systemImage: "icloud.slash")
                            } else {
                                Label("Share to Cloud", systemImage: "icloud")
                            }
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            deleteBook()
                        } label: {
                            Label("Delete Book", systemImage: "trash")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func toggleSharing() {
        book.toggleSharing()
        try? modelContext.save()
    }
    
    private func deleteBook() {
        modelContext.delete(book)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct RecipesSection: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipes")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(book.recipePreviews) { preview in
                        RecipePreviewCard(preview: preview)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RecipePreviewCard: View {
    let preview: BookRecipePreview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let thumbnailData = preview.thumbnailData,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 100)
            }
            
            Text(preview.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            if let yield = preview.yield {
                Text(yield)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 150)
    }
}

struct InstructionsSection: View {
    let instructions: [BookInstruction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions & Guides")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ForEach(instructions) { instruction in
                VStack(alignment: .leading, spacing: 8) {
                    Text(instruction.title)
                        .font(.headline)
                    Text(instruction.content)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }
}

struct GlossarySection: View {
    let entries: [BookGlossaryEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Glossary")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.term)
                        .font(.headline)
                    Text(entry.definition)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }
}

struct SharingInfoSection: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sharing Information")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                InfoRow_SIS(label: "Status", value: book.isSynced ? "Synced to Cloud" : "Pending Sync", icon: "icloud")
                
                if let sharedDate = book.sharedDate {
                    InfoRow_SIS(label: "Shared", value: sharedDate.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                }
                
                if let ownerName = book.ownerDisplayName {
                    InfoRow_SIS(label: "Owner", value: ownerName, icon: "person.fill")
                }
                
                if let viewCount = book.viewCount, viewCount > 0 {
                    InfoRow_SIS(label: "Views", value: "\(viewCount)", icon: "eye")
                }
                
                if let downloadCount = book.downloadCount, downloadCount > 0 {
                    InfoRow_SIS(label: "Downloads", value: "\(downloadCount)", icon: "arrow.down.circle")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
}

struct InfoRow_SIS: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Book Migration View

struct BookMigrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var migrationManager: BookMigrationManager?
    @State private var stats: BookMigrationStats?
    @State private var migrationInProgress = false
    @State private var migrationResult: BookMigrationResult?
    
    var body: some View {
        NavigationStack {
            List {
                if let stats = stats {
                    Section("Migration Status") {
                        InfoRow_SIS(label: "RecipeBooks", value: "\(stats.recipeBookCount)", icon: "book")
                        InfoRow_SIS(label: "SharedRecipeBooks", value: "\(stats.sharedRecipeBookCount)", icon: "book.fill")
                        InfoRow_SIS(label: "Migrated Books", value: "\(stats.migratedBookCount)", icon: "checkmark.circle")
                        InfoRow_SIS(label: "Total Recipes", value: "\(stats.totalRecipesInBooks)", icon: "fork.knife")
                    }
                    
                    if stats.needsMigration {
                        Section {
                            Button {
                                performMigration()
                            } label: {
                                if migrationInProgress {
                                    HStack {
                                        ProgressView()
                                        Text("Migrating...")
                                    }
                                } else {
                                    Label("Start Migration", systemImage: "arrow.triangle.2.circlepath")
                                }
                            }
                            .disabled(migrationInProgress)
                        }
                    }
                    
                    if let result = migrationResult {
                        Section("Migration Result") {
                            Text(result.summary)
                                .foregroundStyle(result.isFullSuccess ? .green : .orange)
                        }
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Book Migration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadMigrationStats()
            }
        }
    }
    
    private func loadMigrationStats() {
        migrationManager = BookMigrationManager(modelContext: modelContext)
        stats = migrationManager?.getMigrationStats()
    }
    
    private func performMigration() {
        guard let manager = migrationManager else { return }
        
        migrationInProgress = true
        
        Task {
            do {
                let result = try await manager.performMigration(deleteOldRecords: true)
                await MainActor.run {
                    migrationResult = result
                    migrationInProgress = false
                    loadMigrationStats() // Refresh stats
                }
            } catch {
                await MainActor.run {
                    migrationInProgress = false
                    print("Migration failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Helpers

extension Color {
    func toHexString() -> String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension Book {
    var statusIcon: String {
        if needsCloudSync == true {
            return "arrow.triangle.2.circlepath"
        } else if isSynced {
            return "checkmark.icloud"
        } else {
            return "icloud.slash"
        }
    }
}

#Preview {
    BookExampleView()
        .modelContainer(for: [Book.self, RecipeBook.self, SharedRecipeBook.self])
}
