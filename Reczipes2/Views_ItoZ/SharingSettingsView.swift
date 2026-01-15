//
//  SharingSettingsView.swift
//  Reczipes2
//
//  Created on 1/15/26.
//

import SwiftUI
import SwiftData

struct SharingSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var sharingService = CloudKitSharingService.shared
    
    @Query private var sharingPreferences: [SharingPreferences]
    @Query private var sharedRecipes: [SharedRecipe]
    @Query private var sharedBooks: [SharedRecipeBook]
    @Query private var allRecipes: [Recipe]
    @Query private var allBooks: [RecipeBook]
    
    @State private var showingRecipeSelector = false
    @State private var showingBookSelector = false
    @State private var isSharing = false
    @State private var sharingStatus = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var preferences: SharingPreferences {
        if let existing = sharingPreferences.first {
            return existing
        } else {
            let newPrefs = SharingPreferences()
            modelContext.insert(newPrefs)
            return newPrefs
        }
    }
    
    var body: some View {
        List {
            // CloudKit Status
            cloudKitStatusSection
            
            // Sharing Preferences
            sharingPreferencesSection
            
            // My Shared Content
            mySharedContentSection
            
            // Quick Actions
            quickActionsSection
            
            // Community Content
            communitySection
        }
        .navigationTitle("Sharing & Community")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingRecipeSelector) {
            RecipeSelectorView(
                selectedRecipes: [],
                onShare: { recipes in
                    Task {
                        await shareRecipes(recipes)
                    }
                }
            )
        }
        .sheet(isPresented: $showingBookSelector) {
            BookSelectorView(
                selectedBooks: [],
                onShare: { books in
                    Task {
                        await shareBooks(books)
                    }
                }
            )
        }
        .alert("Sharing Status", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .task {
            await sharingService.checkCloudKitAvailability()
        }
    }
    
    // MARK: - Sections
    
    private var cloudKitStatusSection: some View {
        Section("CloudKit Status") {
            HStack {
                Image(systemName: sharingService.isCloudKitAvailable ? "icloud.fill" : "icloud.slash.fill")
                    .foregroundStyle(sharingService.isCloudKitAvailable ? .green : .red)
                
                VStack(alignment: .leading) {
                    Text(sharingService.isCloudKitAvailable ? "Ready to Share" : "Not Available")
                        .font(.headline)
                    
                    if let userName = sharingService.currentUserName {
                        Text("Signed in as \(userName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if !sharingService.isCloudKitAvailable {
                        Text("Sign in to iCloud to enable sharing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var sharingPreferencesSection: some View {
        Section {
            Toggle("Share All Recipes", isOn: Binding(
                get: { preferences.shareAllRecipes },
                set: { newValue in
                    preferences.shareAllRecipes = newValue
                    preferences.dateModified = Date()
                    try? modelContext.save()
                    
                    if newValue {
                        Task {
                            await shareAllRecipes()
                        }
                    }
                }
            ))
            .disabled(!sharingService.isCloudKitAvailable)
            
            Toggle("Share All Recipe Books", isOn: Binding(
                get: { preferences.shareAllBooks },
                set: { newValue in
                    preferences.shareAllBooks = newValue
                    preferences.dateModified = Date()
                    try? modelContext.save()
                    
                    if newValue {
                        Task {
                            await shareAllBooks()
                        }
                    }
                }
            ))
            .disabled(!sharingService.isCloudKitAvailable)
            
            Toggle("Show My Name", isOn: Binding(
                get: { preferences.allowOthersToSeeMyName },
                set: { newValue in
                    preferences.allowOthersToSeeMyName = newValue
                    preferences.dateModified = Date()
                    try? modelContext.save()
                }
            ))
            .disabled(!sharingService.isCloudKitAvailable)
            
        } header: {
            Text("Sharing Preferences")
        } footer: {
            Text("When 'Share All' is enabled, new recipes/books will automatically be shared with the community.")
        }
    }
    
    private var mySharedContentSection: some View {
        Section("My Shared Content") {
            HStack {
                Label("\(sharedRecipes.filter { $0.isActive }.count) Recipes", systemImage: "book.fill")
                Spacer()
                Text("Shared")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("\(sharedBooks.filter { $0.isActive }.count) Recipe Books", systemImage: "books.vertical.fill")
                Spacer()
                Text("Shared")
                    .foregroundStyle(.secondary)
            }
            
            NavigationLink("Manage Shared Content") {
                ManageSharedContentView()
            }
        }
    }
    
    private var quickActionsSection: some View {
        Section("Quick Actions") {
            Button {
                showingRecipeSelector = true
            } label: {
                Label("Share Specific Recipes", systemImage: "square.and.arrow.up")
            }
            .disabled(!sharingService.isCloudKitAvailable)
            
            Button {
                showingBookSelector = true
            } label: {
                Label("Share Specific Books", systemImage: "square.and.arrow.up.on.square")
            }
            .disabled(!sharingService.isCloudKitAvailable)
        }
    }
    
    private var communitySection: some View {
        Section("Community") {
            NavigationLink {
                SharedRecipesBrowserView()
            } label: {
                Label("Browse Shared Recipes", systemImage: "person.3.fill")
            }
            .disabled(!sharingService.isCloudKitAvailable)
            
            NavigationLink {
                SharedBooksBrowserView()
            } label: {
                Label("Browse Shared Recipe Books", systemImage: "books.vertical.circle.fill")
            }
            .disabled(!sharingService.isCloudKitAvailable)
        }
    }
    
    // MARK: - Actions
    
    private func shareAllRecipes() async {
        guard !allRecipes.isEmpty else { return }
        
        isSharing = true
        sharingStatus = "Sharing all recipes..."
        // Convert SwiftData Recipe to RecipeModel
        let recipeModels = allRecipes.compactMap { $0.toRecipeModel() }
        let result = await sharingService.shareMultipleRecipes(recipeModels, modelContext: modelContext)
        isSharing = false
        
        switch result {
        case .success(let message):
            alertMessage = message
            showingAlert = true
        case .partialSuccess(let successful, let failed):
            alertMessage = "Shared \(successful) recipes. \(failed) failed."
            showingAlert = true
        case .failure(let error):
            alertMessage = "Failed to share recipes: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func shareAllBooks() async {
        guard !allBooks.isEmpty else { return }
        
        isSharing = true
        sharingStatus = "Sharing all books..."
        
        let result = await sharingService.shareMultipleBooks(allBooks, modelContext: modelContext)
        
        isSharing = false
        
        switch result {
        case .success(let message):
            alertMessage = message
            showingAlert = true
        case .partialSuccess(let successful, let failed):
            alertMessage = "Shared \(successful) books. \(failed) failed."
            showingAlert = true
        case .failure(let error):
            alertMessage = "Failed to share books: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func shareRecipes(_ recipes: [Recipe]) async {
        // Convert and share selected recipes
        isSharing = true
        let recipeModels = recipes.compactMap { $0.toRecipeModel() }
        let result = await sharingService.shareMultipleRecipes(recipeModels, modelContext: modelContext)
        isSharing = false
        
        switch result {
        case .success(let message):
            alertMessage = message
            showingAlert = true
        case .partialSuccess(let successful, let failed):
            alertMessage = "Shared \(successful) recipes. \(failed) failed."
            showingAlert = true
        case .failure(let error):
            alertMessage = "Failed to share recipes: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func shareBooks(_ books: [RecipeBook]) async {
        isSharing = true
        let result = await sharingService.shareMultipleBooks(books, modelContext: modelContext)
        isSharing = false
        
        switch result {
        case .success(let message):
            alertMessage = message
            showingAlert = true
        case .partialSuccess(let successful, let failed):
            alertMessage = "Shared \(successful) books. \(failed) failed."
            showingAlert = true
        case .failure(let error):
            alertMessage = "Failed to share books: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Recipe Selector

struct RecipeSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allRecipes: [Recipe]
    
    @State var selectedRecipes: [Recipe]
    let onShare: ([Recipe]) -> Void
    
    var body: some View {
        NavigationView {
            #if os(macOS)
            macOSList
            #else
            iOSList
            #endif
        }
    }
    
    // macOS version with native selection
    #if os(macOS)
    private var macOSList: some View {
        List(allRecipes, selection: $selectedRecipes) { recipe in
            recipeRow(recipe)
        }
        .navigationTitle("Select Recipes")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Share") {
                    onShare(selectedRecipes)
                    dismiss()
                }
                .disabled(selectedRecipes.isEmpty)
            }
        }
    }
    #endif
    
    // iOS version with manual selection
    private var iOSList: some View {
        List(allRecipes) { recipe in
            Button {
                toggleSelection(for: recipe)
            } label: {
                recipeRow(recipe)
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Select Recipes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Share") {
                    onShare(selectedRecipes)
                    dismiss()
                }
                .disabled(selectedRecipes.isEmpty)
            }
        }
    }
    
    @ViewBuilder
    private func recipeRow(_ recipe: Recipe) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(recipe.title)
                    .font(.headline)
                
                if let description = recipe.headerNotes {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if selectedRecipes.contains(where: { $0.id == recipe.id }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private func toggleSelection(for recipe: Recipe) {
        if let index = selectedRecipes.firstIndex(where: { $0.id == recipe.id }) {
            selectedRecipes.remove(at: index)
        } else {
            selectedRecipes.append(recipe)
        }
    }
}

// MARK: - Book Selector

struct BookSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allBooks: [RecipeBook]
    
    @State var selectedBooks: [RecipeBook]
    let onShare: ([RecipeBook]) -> Void
    
    var body: some View {
        NavigationView {
            #if os(macOS)
            macOSList
            #else
            iOSList
            #endif
        }
    }
    
    // macOS version with native selection
    #if os(macOS)
    private var macOSList: some View {
        List(allBooks, selection: $selectedBooks) { book in
            bookRow(book)
        }
        .navigationTitle("Select Books")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Share") {
                    onShare(selectedBooks)
                    dismiss()
                }
                .disabled(selectedBooks.isEmpty)
            }
        }
    }
    #endif
    
    // iOS version with manual selection
    private var iOSList: some View {
        List(allBooks) { book in
            Button {
                toggleSelection(for: book)
            } label: {
                bookRow(book)
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Select Books")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Share") {
                    onShare(selectedBooks)
                    dismiss()
                }
                .disabled(selectedBooks.isEmpty)
            }
        }
    }
    
    @ViewBuilder
    private func bookRow(_ book: RecipeBook) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(book.name)
                    .font(.headline)
                
                if let description = book.bookDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if selectedBooks.contains(where: { $0.id == book.id }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private func toggleSelection(for book: RecipeBook) {
        if let index = selectedBooks.firstIndex(where: { $0.id == book.id }) {
            selectedBooks.remove(at: index)
        } else {
            selectedBooks.append(book)
        }
    }
}

// MARK: - Placeholder Views

struct ManageSharedContentView: View {
    var body: some View {
        Text("Manage your shared content here")
            .navigationTitle("My Shared Content")
    }
}

//struct SharedRecipesBrowserView: View {
//    var body: some View {
//        Text("Browse community recipes here")
//            .navigationTitle("Community Recipes")
//    }
//}

struct SharedBooksBrowserView: View {
    var body: some View {
        Text("Browse community recipe books here")
            .navigationTitle("Community Books")
    }
}

#Preview {
    NavigationStack {
        SharingSettingsView()
            .modelContainer(for: [SharingPreferences.self, SharedRecipe.self, SharedRecipeBook.self])
    }
}
