//
//  ReadOnlyRecipeBookDetailView.swift
//  Reczipes2
//
//  Created on 1/25/26.
//

import SwiftUI
import SwiftData
import CloudKit

/// Wrapper struct to make recipe + preview combination identifiable for sheet presentation
struct RecipeWithPreview: Identifiable {
    let id = UUID()
    let recipe: CloudKitRecipe
    let preview: CloudKitRecipePreview
}

/// Read-only view for displaying shared recipe books
/// Shows book contents with CloudKitRecipePreviews without edit functionality
struct ReadOnlyRecipeBookDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var recipePreviews: [CloudKitRecipePreview]
    
    let book: RecipeBook
    let sharedEntry: SharedRecipeBook
    
    @State private var currentPage = 0
    @State private var selectedRecipe: RecipeWithPreview?
    
    private var isPad: Bool {
        horizontalSizeClass == .regular
    }
    
    // Get recipe previews for this book
    private var bookRecipePreviews: [CloudKitRecipePreview] {
        recipePreviews.filter { $0.bookID == book.id }
    }
    
    private var bookColor: Color {
        if let colorHex = book.color {
            return Color(hex: colorHex) ?? .blue
        }
        return .blue
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if bookRecipePreviews.isEmpty {
                    emptyBookView
                } else {
                    recipePageView
                }
            }
            .navigationTitle(book.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Shared by \(sharedEntry.sharedByUserName ?? "Someone")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(item: $selectedRecipe) { item in
                NavigationStack {
                    ReadOnlyRecipeDetailView(recipe: item.recipe, preview: item.preview)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    selectedRecipe = nil
                                }
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Empty Book View
    
    private var emptyBookView: some View {
        ContentUnavailableView {
            Label("Empty Book", systemImage: "book.closed")
        } description: {
            Text("This shared book doesn't have any recipes yet")
        } actions: {
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(bookColor)
        }
    }
    
    // MARK: - Recipe Page View
    
    private var recipePageView: some View {
        VStack(spacing: 0) {
            // Shared book banner
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(.blue)
                Text("Shared by \(sharedEntry.sharedByUserName ?? "Someone")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(sharedEntry.sharedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.blue.opacity(0.1))
            
            // Page indicator
            HStack {
                Text("Recipe \(currentPage + 1) of \(bookRecipePreviews.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Quick navigation
                if bookRecipePreviews.count > 1 {
                    Button {
                        withAnimation {
                            currentPage = max(0, currentPage - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                    }
                    .disabled(currentPage == 0)
                    
                    Button {
                        withAnimation {
                            currentPage = min(bookRecipePreviews.count - 1, currentPage + 1)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .disabled(currentPage == bookRecipePreviews.count - 1)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Page turning view
            TabView(selection: $currentPage) {
                ForEach(Array(bookRecipePreviews.enumerated()), id: \.element.id) { index, preview in
                    RecipePreviewPageView(
                        preview: preview,
                        pageNumber: index + 1,
                        bookColor: bookColor,
                        onTap: {
                            // Fetch full recipe from CloudKit and show detail view
                            Task {
                                await loadAndShowRecipe(preview)
                            }
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
    }
    
    // MARK: - Helpers
    
    private func loadAndShowRecipe(_ preview: CloudKitRecipePreview) async {
        // Load full recipe from CloudKit using the stored cloudRecordID
        guard let cloudRecordID = preview.cloudRecordID else {
            logError("Preview missing cloudRecordID, cannot fetch full recipe", category: "sharing")
            return
        }
        
        do {
            let fullRecipe = try await fetchFullRecipeFromCloudKit(recordID: cloudRecordID)
            
            await MainActor.run {
                selectedRecipe = RecipeWithPreview(recipe: fullRecipe, preview: preview)
            }
        } catch {
            logError("Failed to load full recipe: \(error)", category: "sharing")
        }
    }
    
    /// Fetch full recipe from CloudKit using record ID
    private func fetchFullRecipeFromCloudKit(recordID: String) async throws -> CloudKitRecipe {
        let publicDatabase = CloudKitSharingService.shared.publicDatabase
        let ckRecordID = CKRecord.ID(recordName: recordID)
        
        let record = try await publicDatabase.record(for: ckRecordID)
        
        // Decode recipe data from the CloudKit record
        guard let recipeData = record["recipeData"] as? String,
              let jsonData = recipeData.data(using: .utf8) else {
            throw SharingError.invalidData
        }
        
        let decoder = JSONDecoder()
        let cloudRecipe = try decoder.decode(CloudKitRecipe.self, from: jsonData)
        
        return cloudRecipe
    }
}

// MARK: - Recipe Preview Page View

struct RecipePreviewPageView: View {
    let preview: CloudKitRecipePreview
    let pageNumber: Int
    let bookColor: Color
    let onTap: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Recipe image
                    if let imageData = preview.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: 300)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(bookColor.opacity(0.3))
                            .frame(height: 300)
                            .overlay {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 48))
                                        .foregroundStyle(bookColor)
                                    Text("No Image")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Page number decoration
                        HStack {
                            Rectangle()
                                .fill(bookColor)
                                .frame(width: 4, height: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Page \(pageNumber)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(preview.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                        }
                        
                        // View Full Recipe button
                        Button {
                            onTap()
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text("View Full Recipe")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(bookColor.opacity(0.1))
                            .foregroundStyle(bookColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.bottom, 8)
                        
                        // Header notes (preview only)
                        if let headerNotes = preview.headerNotes, !headerNotes.isEmpty {
                            Text(headerNotes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Yield
                        if let recipeYield = preview.recipeYield, !recipeYield.isEmpty {
                            HStack {
                                Image(systemName: "person.2")
                                    .foregroundStyle(bookColor)
                                Text(recipeYield)
                                    .font(.subheadline)
                            }
                        }
                        
                        Divider()
                        
                        // Shared info
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Shared by \(preview.sharedByUserName ?? "Unknown")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Spacer(minLength: 40)
                        
                        // Tap to view more hint
                        VStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Tap 'View Full Recipe' to see ingredients and instructions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RecipeBook.self, Recipe.self, SharedRecipeBook.self, CloudKitRecipePreview.self, configurations: config)
    
    // Create a sample shared book
    let book = RecipeBook(
        name: "Italian Classics",
        bookDescription: "Traditional Italian recipes",
        color: "FF6B6B"
    )
    
    let sharedEntry = SharedRecipeBook(
        bookID: book.id,
        sharedByUserID: "user123",
        sharedByUserName: "Maria Rossi"
    )
    
    container.mainContext.insert(book)
    container.mainContext.insert(sharedEntry)
    
    // Add some preview recipes
    let preview1 = CloudKitRecipePreview(
        id: UUID(),
        title: "Pasta Carbonara",
        headerNotes: "Classic Roman pasta dish",
        imageName: nil,
        imageData: nil,
        sharedByUserID: "user123",
        sharedByUserName: "Maria Rossi",
        recipeYield: "4 servings",
        bookID: book.id,
        cloudRecordID: nil
    )
    
    container.mainContext.insert(preview1)
    
    return ReadOnlyRecipeBookDetailView(book: book, sharedEntry: sharedEntry)
        .modelContainer(container)
}
