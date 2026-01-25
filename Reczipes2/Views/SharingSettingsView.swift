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
    @State private var showingOnboarding = false
    @State private var currentSharingError: SharingError?
    
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
            cloudKitRecipeManagementSection
            
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
        .onAppear {
            // Initialize CloudKitSharingService with current preferences
            sharingService.updateUserDisplayName(from: preferences)
        }
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
        .alert("Sharing Failed", isPresented: Binding(
            get: { currentSharingError != nil },
            set: { if !$0 { currentSharingError = nil } }
        )) {
            if let error = currentSharingError, error.canOpenOnboarding {
                Button("Open Setup & Diagnostics") {
                    showingOnboarding = true
                    currentSharingError = nil
                }
            }
            Button("OK", role: .cancel) {
                currentSharingError = nil
            }
        } message: {
            if let error = currentSharingError {
                Text(error.localizedDescription)
            }
        }
        .sheet(isPresented: $showingOnboarding) {
            CloudKitOnboardingView()
        }
        .task {
            await sharingService.checkCloudKitAvailability()
        }
    }
    
    // MARK: - Sections
    
    private var cloudKitStatusSection: some View {
        Section {
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
        } header: {
            Text("CloudKit Status")
        }
    }
    
    private var cloudKitRecipeManagementSection: some View {
        Section {
            NavigationLink {
                CloudKitRecipeManagerView()
            } label: {
                Label("Manage CloudKit Recipes", systemImage: "cloud")
            }
            
            NavigationLink {
                CloudKitRecipeBookManagerView()
            } label: {
                Label("Manage CloudKit Recipe Books", systemImage: "books.vertical")
            }
        } header: {
            Text("CloudKit Management")
        } footer: {
            Text("View and manage all your content stored in CloudKit, including orphaned items that aren't tracked locally.")
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
                    } else {
                        Task {
                            await unshareAllRecipes()
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
                    } else {
                        Task {
                            await unshareAllBooks()
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
                    
                    // Update CloudKitSharingService with new preference
                    sharingService.updateUserDisplayName(from: preferences)
                }
            ))
            .disabled(!sharingService.isCloudKitAvailable)
            
            if preferences.allowOthersToSeeMyName {
                TextField("Display Name", text: Binding(
                    get: { preferences.displayName ?? "" },
                    set: { newValue in
                        preferences.displayName = newValue.isEmpty ? nil : newValue
                        preferences.dateModified = Date()
                        try? modelContext.save()
                        
                        // Update CloudKitSharingService with new name
                        sharingService.updateUserDisplayName(from: preferences)
                    }
                ))
                .textContentType(.name)
                .autocorrectionDisabled()
                .disabled(!sharingService.isCloudKitAvailable)
                
                Text("This name will be shown when you share recipes and books with the community")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
        } header: {
            Text("Sharing Preferences")
        } footer: {
            Text("When 'Share All' is enabled, new recipes/books will automatically be shared with the community.")
        }
    }
    
    private var mySharedContentSection: some View {
        Section {
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
        } header: {
            Text("My Shared Content")
        }
    }
    
    private var quickActionsSection: some View {
        Section {
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
            
            // Diagnostic & Cleanup Tools - Recipes
            Button {
                Task {
                    await cleanupGhostRecipes()
                }
            } label: {
                Label("Clean Up Ghost Recipes", systemImage: "sparkles")
            }
            .disabled(!sharingService.isCloudKitAvailable)
            
            Button {
                Task {
                    await syncLocalTracking()
                }
            } label: {
                Label("Sync Recipe Sharing Status", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(!sharingService.isCloudKitAvailable)
            
            Button {
                Task {
                    await repairRecipeCloudKitIDs()
                }
            } label: {
                Label("Repair Recipe CloudKit IDs", systemImage: "wrench.and.screwdriver")
            }
            .disabled(!sharingService.isCloudKitAvailable)
            
            // Diagnostic & Cleanup Tools - Recipe Books
            Button {
                Task {
                    await cleanupGhostRecipeBooks()
                }
            } label: {
                Label("Clean Up Ghost Recipe Books", systemImage: "sparkles.rectangle.stack")
            }
            .disabled(!sharingService.isCloudKitAvailable)
            
            Button {
                Task {
                    await syncLocalRecipeBookTracking()
                }
            } label: {
                Label("Sync Recipe Book Sharing Status", systemImage: "arrow.triangle.2.circlepath.circle")
            }
            .disabled(!sharingService.isCloudKitAvailable)
            
            Button {
                Task {
                    await repairRecipeBookCloudKitIDs()
                }
            } label: {
                Label("Repair Recipe Book CloudKit IDs", systemImage: "wrench.and.screwdriver.fill")
            }
            .disabled(!sharingService.isCloudKitAvailable)
            
            // Community Sync
            Button {
                Task {
                    await syncCommunityBooks()
                }
            } label: {
                Label("Sync Community Books", systemImage: "books.vertical.circle")
            }
            .disabled(!sharingService.isCloudKitAvailable)
            
            // Diagnostics
            Button {
                Task {
                    await diagnoseSharedBooks()
                }
            } label: {
                Label("Diagnose Shared Books", systemImage: "stethoscope")
            }
            .disabled(!sharingService.isCloudKitAvailable)
            
            Button {
                Task {
                    await syncCommunityRecipes()
                }
            } label: {
                Label("Sync Community Recipes", systemImage: "book.circle")
            }
            .disabled(!sharingService.isCloudKitAvailable)
        } header: {
            Text("Quick Actions")
        } footer: {
            Text("Use 'Clean Up Ghost' buttons if you see content in Browse view that you've already unshared. Use 'Sync Status' buttons to fix tracking mismatches. Use 'Repair CloudKit IDs' if you see '⚠️ No CloudKit ID' warnings. Use 'Sync Community' to refresh shared content for viewing.")
        }
    }
    
    private var communitySection: some View {
        Section {
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
        } header: {
            Text("Community")
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
            if let sharingError = error as? SharingError {
                currentSharingError = sharingError
            } else {
                alertMessage = "Failed to share recipes: \(error.localizedDescription)"
                showingAlert = true
            }
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
            if let sharingError = error as? SharingError {
                currentSharingError = sharingError
            } else {
                alertMessage = "Failed to share books: \(error.localizedDescription)"
                showingAlert = true
            }
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
            if let sharingError = error as? SharingError {
                currentSharingError = sharingError
            } else {
                alertMessage = "Failed to share recipes: \(error.localizedDescription)"
                showingAlert = true
            }
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
            if let sharingError = error as? SharingError {
                currentSharingError = sharingError
            } else {
                alertMessage = "Failed to share books: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func unshareAllRecipes() async {
        isSharing = true
        sharingStatus = "Unsharing all recipes..."
        
        // Get all shared recipes (both active and inactive to ensure cleanup)
        let allSharedRecipes = sharedRecipes
        
        var successful = 0
        var failed = 0
        
        for sharedRecipe in allSharedRecipes {
            // If already inactive, skip it
            if !sharedRecipe.isActive {
                continue
            }
            
            guard let cloudRecordID = sharedRecipe.cloudRecordID else {
                // Mark as inactive if no cloud record ID (shouldn't happen, but handle gracefully)
                sharedRecipe.isActive = false
                successful += 1
                logError("Recipe '\(sharedRecipe.recipeTitle)' had no cloudRecordID, marked as inactive", category: "sharing")
                continue
            }
            
            do {
                try await sharingService.unshareRecipe(cloudRecordID: cloudRecordID, modelContext: modelContext)
                successful += 1
            } catch {
                logError("Failed to unshare recipe '\(sharedRecipe.recipeTitle)': \(error)", category: "sharing")
                failed += 1
            }
        }
        
        // Save changes to SwiftData
        try? modelContext.save()
        
        isSharing = false
        
        if allSharedRecipes.isEmpty {
            alertMessage = "No recipes to unshare"
        } else if failed == 0 {
            alertMessage = "Successfully unshared all \(successful) recipes"
        } else {
            alertMessage = "Unshared \(successful) of \(allSharedRecipes.count) recipes. \(failed) failed."
        }
        showingAlert = true
    }
    
    private func unshareAllBooks() async {
        isSharing = true
        sharingStatus = "Unsharing all books..."
        
        // Get all shared books (both active and inactive to ensure cleanup)
        let allSharedBooks = sharedBooks
        
        var successful = 0
        var failed = 0
        
        for sharedBook in allSharedBooks {
            // If already inactive, skip it
            if !sharedBook.isActive {
                continue
            }
            
            guard let cloudRecordID = sharedBook.cloudRecordID else {
                // Mark as inactive if no cloud record ID (shouldn't happen, but handle gracefully)
                sharedBook.isActive = false
                successful += 1
                logError("Book '\(sharedBook.bookName)' had no cloudRecordID, marked as inactive", category: "sharing")
                continue
            }
            
            do {
                try await sharingService.unshareRecipeBook(cloudRecordID: cloudRecordID, modelContext: modelContext)
                successful += 1
            } catch {
                logError("Failed to unshare book '\(sharedBook.bookName)': \(error)", category: "sharing")
                failed += 1
            }
        }
        
        // Save changes to SwiftData
        try? modelContext.save()
        
        isSharing = false
        
        if allSharedBooks.isEmpty {
            alertMessage = "No books to unshare"
        } else if failed == 0 {
            alertMessage = "Successfully unshared all \(successful) books"
        } else {
            alertMessage = "Unshared \(successful) of \(allSharedBooks.count) books. \(failed) failed."
        }
        showingAlert = true
    }
    
    // MARK: - Cleanup & Sync Actions
    
    private func cleanupGhostRecipes() async {
        isSharing = true
        sharingStatus = "Cleaning up ghost recipes..."
        
        do {
            try await sharingService.cleanupGhostRecipes(modelContext: modelContext)
            alertMessage = "✅ Ghost recipe cleanup complete! Check Console logs for details."
            showingAlert = true
        } catch {
            alertMessage = "Failed to clean up ghost recipes: \(error.localizedDescription)"
            showingAlert = true
        }
        
        isSharing = false
    }
    
    private func syncLocalTracking() async {
        isSharing = true
        sharingStatus = "Syncing recipe sharing status..."
        
        do {
            try await sharingService.syncLocalTrackingWithCloudKit(modelContext: modelContext)
            alertMessage = "✅ Recipe sharing status synced! Check Console logs for details."
            showingAlert = true
        } catch {
            alertMessage = "Failed to sync recipes: \(error.localizedDescription)"
            showingAlert = true
        }
        
        isSharing = false
    }
    
    private func repairRecipeCloudKitIDs() async {
        isSharing = true
        sharingStatus = "Repairing recipe CloudKit IDs..."
        
        do {
            try await sharingService.repairMissingRecipeCloudKitIDs(modelContext: modelContext)
            alertMessage = "✅ Recipe CloudKit IDs repaired! Check Console logs for details."
            showingAlert = true
        } catch {
            alertMessage = "Failed to repair recipe IDs: \(error.localizedDescription)"
            showingAlert = true
        }
        
        isSharing = false
    }
    
    // MARK: - Recipe Book Cleanup & Sync Actions
    
    private func cleanupGhostRecipeBooks() async {
        isSharing = true
        sharingStatus = "Cleaning up ghost recipe books..."
        
        do {
            try await sharingService.cleanupGhostRecipeBooks(modelContext: modelContext)
            alertMessage = "✅ Ghost recipe book cleanup complete! Check Console logs for details."
            showingAlert = true
        } catch {
            alertMessage = "Failed to clean up ghost recipe books: \(error.localizedDescription)"
            showingAlert = true
        }
        
        isSharing = false
    }
    
    private func syncLocalRecipeBookTracking() async {
        isSharing = true
        sharingStatus = "Syncing recipe book sharing status..."
        
        do {
            try await sharingService.syncLocalRecipeBookTrackingWithCloudKit(modelContext: modelContext)
            alertMessage = "✅ Recipe book sharing status synced! Check Console logs for details."
            showingAlert = true
        } catch {
            alertMessage = "Failed to sync recipe books: \(error.localizedDescription)"
            showingAlert = true
        }
        
        isSharing = false
    }
    
    private func repairRecipeBookCloudKitIDs() async {
        isSharing = true
        sharingStatus = "Repairing recipe book CloudKit IDs..."
        
        do {
            try await sharingService.repairMissingRecipeBookCloudKitIDs(modelContext: modelContext)
            alertMessage = "✅ Recipe book CloudKit IDs repaired! Check Console logs for details."
            showingAlert = true
        } catch {
            alertMessage = "Failed to repair recipe book IDs: \(error.localizedDescription)"
            showingAlert = true
        }
        
        isSharing = false
    }
    
    // MARK: - Community Sync Actions
    
    private func syncCommunityBooks() async {
        isSharing = true
        sharingStatus = "Syncing community books..."
        
        do {
            try await sharingService.syncCommunityBooksToLocal(modelContext: modelContext)
            alertMessage = "✅ Community books synced! Shared books should now appear in the Books view."
            showingAlert = true
        } catch {
            alertMessage = "Failed to sync community books: \(error.localizedDescription)"
            showingAlert = true
        }
        
        isSharing = false
    }
    
    private func syncCommunityRecipes() async {
        isSharing = true
        sharingStatus = "Syncing community recipes..."
        
        do {
            try await sharingService.syncCommunityRecipesForViewing(modelContext: modelContext, limit: 100)
            alertMessage = "✅ Community recipes synced! Shared recipes are now available for viewing and cooking."
            showingAlert = true
        } catch {
            alertMessage = "Failed to sync community recipes: \(error.localizedDescription)"
            showingAlert = true
        }
        
        isSharing = false
    }
    
    // MARK: - Diagnostic Actions
    
    private func diagnoseSharedBooks() async {
        isSharing = true
        sharingStatus = "Running diagnostics..."
        
        await sharingService.diagnoseSharedRecipeBooks(modelContext: modelContext)
        
        alertMessage = "✅ Diagnostic complete! Check the Xcode console for detailed results."
        showingAlert = true
        
        isSharing = false
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

// MARK: - Manage Shared Content View

struct ManageSharedContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var sharingService = CloudKitSharingService.shared
    
    @Query(filter: #Predicate<SharedRecipe> { $0.isActive == true })
    private var activeSharedRecipes: [SharedRecipe]
    
    @Query(filter: #Predicate<SharedRecipeBook> { $0.isActive == true })
    private var activeSharedBooks: [SharedRecipeBook]
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var itemToUnshare: (id: String, type: UnshareType)?
    
    enum UnshareType {
        case recipe
        case book
    }
    
    var body: some View {
        Group {
            if activeSharedRecipes.isEmpty && activeSharedBooks.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "tray.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No Shared Content")
                        .font(.headline)
                    
                    Text("You haven't shared any recipes or books yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    NavigationLink("Share Content") {
                        SharingSettingsView()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if !activeSharedRecipes.isEmpty {
                        Section {
                            ForEach(activeSharedRecipes) { sharedRecipe in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(sharedRecipe.recipeTitle)
                                            .font(.headline)
                                        
                                        Text("Shared \(sharedRecipe.sharedDate, style: .date)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        if sharedRecipe.cloudRecordID == nil {
                                            Text("⚠️ No CloudKit ID")
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if let cloudRecordID = sharedRecipe.cloudRecordID {
                                        Button(role: .destructive) {
                                            logInfo("🗑️ User tapped unshare for recipe: \(sharedRecipe.recipeTitle)", category: "sharing")
                                            itemToUnshare = (cloudRecordID, .recipe)
                                        } label: {
                                            Label("Unshare", systemImage: "xmark.circle.fill")
                                                .labelStyle(.iconOnly)
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        // Recipe has no CloudKit ID - show error
                                        Button {
                                            alertMessage = "Cannot unshare '\(sharedRecipe.recipeTitle)': No CloudKit record ID found. Try running 'Sync Recipe Sharing Status' first."
                                            showingAlert = true
                                        } label: {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(.orange)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if let cloudRecordID = sharedRecipe.cloudRecordID {
                                        Button(role: .destructive) {
                                            logInfo("🗑️ User swiped to unshare recipe: \(sharedRecipe.recipeTitle)", category: "sharing")
                                            itemToUnshare = (cloudRecordID, .recipe)
                                        } label: {
                                            Label("Unshare", systemImage: "xmark.circle")
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text("Shared Recipes")
                        } footer: {
                            Text("Tap the ✕ button or swipe to stop sharing a recipe.")
                        }
                    }
                    
                    if !activeSharedBooks.isEmpty {
                        Section {
                            ForEach(activeSharedBooks) { sharedBook in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(sharedBook.bookName)
                                            .font(.headline)
                                        
                                        if let description = sharedBook.bookDescription {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Text("Shared \(sharedBook.sharedDate, style: .date)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        if sharedBook.cloudRecordID == nil {
                                            Text("⚠️ No CloudKit ID")
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if let cloudRecordID = sharedBook.cloudRecordID {
                                        Button(role: .destructive) {
                                            logInfo("🗑️ User tapped unshare for book: \(sharedBook.bookName)", category: "sharing")
                                            itemToUnshare = (cloudRecordID, .book)
                                        } label: {
                                            Label("Unshare", systemImage: "xmark.circle.fill")
                                                .labelStyle(.iconOnly)
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        // Book has no CloudKit ID - show error
                                        Button {
                                            alertMessage = "Cannot unshare '\(sharedBook.bookName)': No CloudKit record ID found. Try running 'Sync Recipe Book Sharing Status' first."
                                            showingAlert = true
                                        } label: {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(.orange)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if let cloudRecordID = sharedBook.cloudRecordID {
                                        Button(role: .destructive) {
                                            logInfo("🗑️ User swiped to unshare book: \(sharedBook.bookName)", category: "sharing")
                                            itemToUnshare = (cloudRecordID, .book)
                                        } label: {
                                            Label("Unshare", systemImage: "xmark.circle")
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text("Shared Recipe Books")
                        } footer: {
                            Text("Tap the ✕ button or swipe to stop sharing a recipe book.")
                        }
                    }
                }
            }
        }
        .navigationTitle("My Shared Content")
        .alert("Unshare Content", isPresented: Binding(
            get: { itemToUnshare != nil },
            set: { if !$0 { itemToUnshare = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                logInfo("🚫 User cancelled unshare", category: "sharing")
                itemToUnshare = nil
            }
            Button("Unshare", role: .destructive) {
                if let item = itemToUnshare {
                    logInfo("✅ User confirmed unshare for \(item.type)", category: "sharing")
                    Task {
                        await unshareItem(cloudRecordID: item.id, type: item.type)
                    }
                } else {
                    logError("❌ itemToUnshare was nil in alert confirmation", category: "sharing")
                }
            }
        } message: {
            if let item = itemToUnshare {
                Text("This will remove this \(item.type == .recipe ? "recipe" : "recipe book") from the community. You can share it again later.")
            } else {
                Text("This will remove the item from the community.")
            }
        }
        .alert("Status", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func unshareItem(cloudRecordID: String, type: UnshareType) async {
        logInfo("🔄 Starting unshare process for \(type): \(cloudRecordID)", category: "sharing")
        
        do {
            switch type {
            case .recipe:
                logInfo("🍽️ Calling unshareRecipe...", category: "sharing")
                try await sharingService.unshareRecipe(cloudRecordID: cloudRecordID, modelContext: modelContext)
                alertMessage = "Recipe unshared successfully"
                logInfo("✅ Recipe unshared successfully", category: "sharing")
            case .book:
                logInfo("📚 Calling unshareRecipeBook...", category: "sharing")
                try await sharingService.unshareRecipeBook(cloudRecordID: cloudRecordID, modelContext: modelContext)
                alertMessage = "Recipe book unshared successfully"
                logInfo("✅ Recipe book unshared successfully", category: "sharing")
            }
            itemToUnshare = nil
            showingAlert = true
        } catch {
            logError("❌ Failed to unshare \(type): \(error)", category: "sharing")
            alertMessage = "Failed to unshare: \(error.localizedDescription)"
            itemToUnshare = nil
            showingAlert = true
        }
    }
}

// MARK: - Shared Books Browser

struct SharedBooksBrowserView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var sharingService = CloudKitSharingService.shared
    
    @State private var sharedBooks: [CloudKitRecipeBook] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var errorMessage: String?
    @State private var showingBookDetail: CloudKitRecipeBook?
    
    var filteredBooks: [CloudKitRecipeBook] {
        if searchText.isEmpty {
            return sharedBooks
        }
        return sharedBooks.filter { book in
            book.name.localizedCaseInsensitiveContains(searchText) ||
            (book.sharedByUserName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (book.bookDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        Group {
            if isLoading && sharedBooks.isEmpty {
                ProgressView("Loading community recipe books...")
            } else if sharedBooks.isEmpty {
                ContentUnavailableView(
                    "No Community Recipe Books",
                    systemImage: "books.vertical.fill",
                    description: Text("No recipe books have been shared by the community yet. Be the first to share!")
                )
            } else {
                List(filteredBooks) { book in
                    SharedBookRow(book: book) {
                        showingBookDetail = book
                    }
                }
                .searchable(text: $searchText, prompt: "Search books or authors")
            }
        }
        .navigationTitle("Browse Community Books")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isLoading {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProgressView()
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await loadBooks() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await loadBooks()
        }
        .refreshable {
            await loadBooks()
        }
        .sheet(item: $showingBookDetail) { book in
            SharedBookDetailView(book: book)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func loadBooks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let books = try await sharingService.fetchSharedRecipeBooks(excludeCurrentUser: true)
            await MainActor.run {
                sharedBooks = books
                logInfo("📚 Loaded \(books.count) shared books from CloudKit", category: "sharing")
            }
            
            // Automatically sync to local SwiftData so books appear in RecipeBooksView
            do {
                try await sharingService.syncCommunityBooksToLocal(modelContext: modelContext)
                logInfo("📚 Synced community books to local SwiftData", category: "sharing")
            } catch {
                logError("Failed to sync community books to local: \(error)", category: "sharing")
                // Don't show error to user - the browse view still works
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load recipe books: \(error.localizedDescription)"
                logError("Failed to load shared books: \(error)", category: "sharing")
            }
        }
        
        isLoading = false
    }
}

struct SharedBookRow: View {
    let book: CloudKitRecipeBook
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let userName = book.sharedByUserName {
                            Label(userName, systemImage: "person.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 12) {
                            Label("\(book.recipeIDs.count) recipes", systemImage: "book.fill")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            
                            Text("Shared \(book.sharedDate, style: .date)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                if let description = book.bookDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct SharedBookDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let book: CloudKitRecipeBook
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let description = book.bookDescription {
                        Text(description)
                            .font(.body)
                    }
                    
                    if let userName = book.sharedByUserName {
                        LabeledContent("Shared by") {
                            Text(userName)
                        }
                    }
                    
                    LabeledContent("Shared on") {
                        Text(book.sharedDate, style: .date)
                    }
                    
                    LabeledContent("Recipes") {
                        Text("\(book.recipeIDs.count)")
                    }
                } header: {
                    Text("Book Information")
                }
                
                Section {
                    Text("Recipe IDs:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(book.recipeIDs, id: \.self) { recipeID in
                        Text(recipeID.uuidString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Recipes in This Book (\(book.recipeIDs.count))")
                } footer: {
                    Text("To view these recipes, you'll need to import them individually from Browse Community Recipes.")
                }
            }
            .navigationTitle(book.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SharingSettingsView()
            .modelContainer(for: [SharingPreferences.self, SharedRecipe.self, SharedRecipeBook.self])
    }
}
