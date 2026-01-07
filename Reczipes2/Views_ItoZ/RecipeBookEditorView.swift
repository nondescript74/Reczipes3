//
//  RecipeBookEditorView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct RecipeBookEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var savedRecipes: [Recipe]
    
    let book: RecipeBook?
    
    @State private var name: String
    @State private var bookDescription: String
    @State private var selectedColor: Color
    @State private var coverImageName: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessingImage = false
    @State private var showingRecipeManager = false
    
    private let availableColors: [Color] = [
        .blue, .purple, .pink, .red, .orange,
        .yellow, .green, .teal, .indigo, .brown
    ]
    
    // Get recipes currently in the book (for editing existing book)
    private var bookRecipes: [Recipe] {
        guard let book = book else { return [] }
        return book.recipeIDs.compactMap { recipeID in
            savedRecipes.first { $0.id == recipeID }
        }
    }
    
    init(book: RecipeBook? = nil) {
        self.book = book
        _name = State(initialValue: book?.name ?? "")
        _bookDescription = State(initialValue: book?.bookDescription ?? "")
        _coverImageName = State(initialValue: book?.coverImageName)
        
        if let colorHex = book?.color, let color = Color(hex: colorHex) {
            _selectedColor = State(initialValue: color)
        } else {
            _selectedColor = State(initialValue: .blue)
        }
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Book Details") {
                    TextField("Book Name", text: $name)
                    
                    TextField("Description (Optional)", text: $bookDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Cover Image") {
                    if let coverImageName = coverImageName {
                        HStack {
                            RecipeImageView(
                                imageName: coverImageName,
                                size: CGSize(width: 120, height: 160),
                                cornerRadius: 8
                            )
                            
                            Spacer()
                            
                            Button("Remove", role: .destructive) {
                                removeCoverImage()
                            }
                        }
                    }
                    
                    let hasCoverImage = coverImageName != nil
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(hasCoverImage ? "Change Cover Image" : "Add Cover Image",
                              systemImage: "photo")
                    }
                    .disabled(isProcessingImage)
                    
                    if isProcessingImage {
                        HStack {
                            ProgressView()
                            Text("Processing image...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Color Theme") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if colorMatches(color, selectedColor) {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 3)
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
                
                // Recipes section (only for existing books)
                if book != nil {
                    Section {
                        Button {
                            showingRecipeManager = true
                        } label: {
                            HStack {
                                Label("Manage Recipes", systemImage: "book.pages")
                                Spacer()
                                Text("\(bookRecipes.count)")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } header: {
                        Text("Recipes")
                    } footer: {
                        Text("Add or remove recipes from this book")
                    }
                }
            }
            .navigationTitle(book == nil ? "New Book" : "Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(book == nil ? "Create" : "Save") {
                        saveBook()
                    }
                    .disabled(!isValid)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await loadImage(from: newItem)
                }
            }
            .sheet(isPresented: $showingRecipeManager) {
                if let book = book {
                    RecipeBookRecipeManagerView(book: book)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func colorMatches(_ color1: Color, _ color2: Color) -> Bool {
        // Simple comparison using hex strings
        return color1.toHex() == color2.toHex()
    }
    
    private func loadImage(from photoItem: PhotosPickerItem?) async {
        guard let photoItem = photoItem else { return }
        
        isProcessingImage = true
        defer { isProcessingImage = false }
        
        do {
            guard let data = try await photoItem.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                logError("Failed to load image data", category: "book")
                return
            }
            
            // Save the image
            let imageName = "book_cover_\(UUID().uuidString).jpg"
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(imageName)
            
            // Compress and save
            if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                try jpegData.write(to: fileURL)
                
                // Remove old image if exists
                if let oldImageName = coverImageName {
                    let oldFileURL = documentsPath.appendingPathComponent(oldImageName)
                    try? FileManager.default.removeItem(at: oldFileURL)
                }
                
                await MainActor.run {
                    coverImageName = imageName
                }
                
                logInfo("Saved book cover image: \(imageName)", category: "book")
            }
        } catch {
            logError("Error loading image: \(error)", category: "book")
        }
    }
    
    private func removeCoverImage() {
        if let imageName = coverImageName {
            // Delete the file
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(imageName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        coverImageName = nil
    }
    
    private func saveBook() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = bookDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let colorHex = selectedColor.toHex()
        
        if let book = book {
            // Update existing book
            book.name = trimmedName
            book.bookDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
            book.coverImageName = coverImageName
            book.color = colorHex
            book.dateModified = Date()
            
            logInfo("Updated book: \(book.name)", category: "book")
        } else {
            // Create new book
            let newBook = RecipeBook(
                name: trimmedName,
                bookDescription: trimmedDescription.isEmpty ? nil : trimmedDescription,
                coverImageName: coverImageName,
                color: colorHex
            )
            modelContext.insert(newBook)
            
            logInfo("Created new book: \(newBook.name)", category: "book")
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            logError("Failed to save book: \(error)", category: "book")
        }
    }
}

#Preview {
    RecipeBookEditorView()
        .modelContainer(for: RecipeBook.self, inMemory: true)
}
