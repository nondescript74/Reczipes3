# CloudKit Recipe Manager - Implementation Guide

## Purpose

Provide users with **full visibility and control** over all their recipes stored in CloudKit, addressing the ghost/orphaned recipe problem by giving users a UI to:

1. **See** all recipes they own in CloudKit
2. **Identify** orphaned recipes (not tracked locally)
3. **Delete** individual recipes or bulk delete orphans
4. **Restore** tracking for recipes they want to keep
5. **Verify** sync status across devices

---

## User Interface Design

### Location
**Settings → Sharing & Community → "Manage CloudKit Recipes"**

### Layout

```
┌────────────────────────────────────────┐
│ My CloudKit Recipes                    │
├────────────────────────────────────────┤
│ 📊 Status                               │
│ ✅ 8 tracked recipes                    │
│ ⚠️ 3 orphaned recipes                   │
│ 📦 11 total in CloudKit                 │
├────────────────────────────────────────┤
│ Search recipes...                  🔍  │
├────────────────────────────────────────┤
│ ━━━ Tracked Recipes ━━━                │
│ ✅ Chocolate Cake              [Delete] │
│    Shared: Jan 15, 2026                │
│    Status: Active & Tracked            │
│                                        │
│ ✅ Pasta Carbonara             [Delete] │
│    Shared: Jan 14, 2026                │
│    Status: Active & Tracked            │
│                                        │
│ ━━━ Orphaned Recipes ⚠️ ━━━             │
│ ⚠️ Apple Pie                   [Delete] │
│    Shared: Dec 20, 2025                │
│    Status: Orphaned (no tracking)      │
│    [Re-Track This Recipe]              │
│                                        │
│ ⚠️ Banana Bread                [Delete] │
│    Shared: Dec 18, 2025                │
│    Status: Orphaned (no tracking)      │
│    [Re-Track This Recipe]              │
│                                        │
├────────────────────────────────────────┤
│ [Refresh from CloudKit]                │
│ [Delete All Orphaned (3)]              │
│ [Export Diagnostic Report]             │
└────────────────────────────────────────┘
```

---

## Implementation

### 1. Data Model

```swift
// CloudKitSharingService.swift

struct CloudKitRecipeStatus: Identifiable {
    let id: UUID
    let recipe: CloudKitRecipe
    let cloudRecordID: String
    let isTrackedLocally: Bool
    let sharedDate: Date
    let localTrackingRecord: SharedRecipe?
    
    var isOrphaned: Bool {
        !isTrackedLocally
    }
    
    var statusDescription: String {
        if isTrackedLocally {
            return "Active & Tracked"
        } else {
            return "Orphaned (no tracking)"
        }
    }
    
    var statusIcon: String {
        isTrackedLocally ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }
    
    var statusColor: Color {
        isTrackedLocally ? .green : .orange
    }
}

struct CloudKitRecipeManagerData {
    let recipes: [CloudKitRecipeStatus]
    
    var trackedCount: Int {
        recipes.filter { $0.isTrackedLocally }.count
    }
    
    var orphanedCount: Int {
        recipes.filter { $0.isOrphaned }.count
    }
    
    var totalCount: Int {
        recipes.count
    }
    
    var trackedRecipes: [CloudKitRecipeStatus] {
        recipes.filter { $0.isTrackedLocally }
    }
    
    var orphanedRecipes: [CloudKitRecipeStatus] {
        recipes.filter { $0.isOrphaned }
    }
}
```

### 2. Service Methods

```swift
// Add to CloudKitSharingService.swift

/// Fetch all recipes owned by current user with tracking status
func fetchMyCloudKitRecipesWithStatus(modelContext: ModelContext) async throws -> CloudKitRecipeManagerData {
    guard let currentUserID = currentUserID else {
        throw SharingError.notAuthenticated
    }
    
    logInfo("📋 Fetching all CloudKit recipes for current user...", category: "sharing")
    
    // 1. Fetch ALL recipes from CloudKit (including current user's)
    let allCloudKitRecipes = try await fetchSharedRecipes(excludeCurrentUser: false)
    let myRecipes = allCloudKitRecipes.filter { $0.sharedByUserID == currentUserID }
    
    logInfo("📋 Found \(myRecipes.count) recipes in CloudKit", category: "sharing")
    
    // 2. Fetch all local tracking records
    let allTracking = try modelContext.fetch(FetchDescriptor<SharedRecipe>())
    let trackingByRecipeID = Dictionary(uniqueKeysWithValues: allTracking.map { ($0.recipeID, $0) })
    
    logInfo("📋 Found \(allTracking.count) local tracking records", category: "sharing")
    
    // 3. Fetch CloudKit records with record IDs
    let allCloudKitRecords = try await fetchAllCloudKitRecords(type: CloudKitRecordType.sharedRecipe)
    let myCloudKitRecords = allCloudKitRecords.filter { record in
        guard let sharedBy = record["sharedBy"] as? String else { return false }
        return sharedBy == currentUserID
    }
    
    // 4. Build status objects
    var statuses: [CloudKitRecipeStatus] = []
    
    for record in myCloudKitRecords {
        guard let recipeData = record["recipeData"] as? String,
              let jsonData = recipeData.data(using: .utf8),
              let cloudRecipe = try? JSONDecoder().decode(CloudKitRecipe.self, from: jsonData),
              let sharedDate = record["sharedDate"] as? Date else {
            continue
        }
        
        let isTracked = trackingByRecipeID[cloudRecipe.id] != nil
        let trackingRecord = trackingByRecipeID[cloudRecipe.id]
        
        let status = CloudKitRecipeStatus(
            id: UUID(),
            recipe: cloudRecipe,
            cloudRecordID: record.recordID.recordName,
            isTrackedLocally: isTracked,
            sharedDate: sharedDate,
            localTrackingRecord: trackingRecord
        )
        
        statuses.append(status)
    }
    
    // Sort: tracked first, then by date
    statuses.sort { lhs, rhs in
        if lhs.isTrackedLocally != rhs.isTrackedLocally {
            return lhs.isTrackedLocally // Tracked first
        }
        return lhs.sharedDate > rhs.sharedDate // Newest first
    }
    
    logInfo("📋 Status: \(statuses.filter { $0.isTrackedLocally }.count) tracked, \(statuses.filter { $0.isOrphaned }.count) orphaned", category: "sharing")
    
    return CloudKitRecipeManagerData(recipes: statuses)
}

/// Delete a single recipe from CloudKit by record ID
func deleteRecipeFromCloudKit(cloudRecordID: String) async throws {
    logInfo("🗑️ Deleting recipe from CloudKit: \(cloudRecordID)", category: "sharing")
    
    let recordID = CKRecord.ID(recordName: cloudRecordID)
    try await publicDatabase.deleteRecord(withID: recordID)
    
    logInfo("✅ Recipe deleted from CloudKit", category: "sharing")
}

/// Re-track an orphaned recipe (restore local tracking)
func reTrackRecipe(recipe: CloudKitRecipe, cloudRecordID: String, modelContext: ModelContext) throws {
    logInfo("🔄 Re-tracking orphaned recipe: \(recipe.title)", category: "sharing")
    
    // Check if tracking already exists
    let existing = try modelContext.fetch(
        FetchDescriptor<SharedRecipe>(
            predicate: #Predicate<SharedRecipe> { $0.recipeID == recipe.id }
        )
    )
    
    if let existingRecord = existing.first {
        // Reactivate existing record
        existingRecord.isActive = true
        logInfo("✅ Reactivated existing tracking record", category: "sharing")
    } else {
        // Create new tracking record
        let tracking = SharedRecipe(
            recipeID: recipe.id,
            recipeTitle: recipe.title,
            cloudRecordID: cloudRecordID,
            sharedByUserID: recipe.sharedByUserID,
            sharedByUserName: recipe.sharedByUserName,
            sharedDate: Date()
        )
        modelContext.insert(tracking)
        logInfo("✅ Created new tracking record", category: "sharing")
    }
    
    try modelContext.save()
}

/// Delete all orphaned recipes from CloudKit
func deleteAllOrphanedRecipes(orphanedStatuses: [CloudKitRecipeStatus]) async throws {
    logInfo("🗑️ Deleting \(orphanedStatuses.count) orphaned recipes from CloudKit...", category: "sharing")
    
    var successCount = 0
    var failCount = 0
    
    for status in orphanedStatuses {
        do {
            try await deleteRecipeFromCloudKit(cloudRecordID: status.cloudRecordID)
            successCount += 1
        } catch {
            logError("❌ Failed to delete '\(status.recipe.title)': \(error)", category: "sharing")
            failCount += 1
        }
    }
    
    logInfo("✅ Deleted \(successCount) orphaned recipes, \(failCount) failures", category: "sharing")
}
```

### 3. SwiftUI View

```swift
// CloudKitRecipeManagerView.swift

import SwiftUI
import SwiftData

struct CloudKitRecipeManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var sharingService = CloudKitSharingService.shared
    
    @State private var managerData: CloudKitRecipeManagerData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var showingDeleteAllConfirmation = false
    
    var filteredRecipes: [CloudKitRecipeStatus] {
        guard let data = managerData else { return [] }
        if searchText.isEmpty {
            return data.recipes
        }
        return data.recipes.filter { $0.recipe.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            // Status Section
            Section("Status") {
                if let data = managerData {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(data.trackedCount) tracked recipes")
                    }
                    
                    if data.orphanedCount > 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(data.orphanedCount) orphaned recipes")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(.blue)
                        Text("\(data.totalCount) total in CloudKit")
                    }
                }
            }
            
            // Tracked Recipes
            if let data = managerData, !data.trackedRecipes.isEmpty {
                Section {
                    ForEach(data.trackedRecipes.filter { recipe in
                        searchText.isEmpty || recipe.recipe.title.localizedCaseInsensitiveContains(searchText)
                    }) { status in
                        RecipeStatusRow(
                            status: status,
                            onDelete: { deleteRecipe(status) },
                            onReTrack: nil
                        )
                    }
                } header: {
                    Label("Tracked Recipes", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            // Orphaned Recipes
            if let data = managerData, !data.orphanedRecipes.isEmpty {
                Section {
                    ForEach(data.orphanedRecipes.filter { recipe in
                        searchText.isEmpty || recipe.recipe.title.localizedCaseInsensitiveContains(searchText)
                    }) { status in
                        RecipeStatusRow(
                            status: status,
                            onDelete: { deleteRecipe(status) },
                            onReTrack: { reTrackRecipe(status) }
                        )
                    }
                } header: {
                    Label("Orphaned Recipes", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                } footer: {
                    Text("These recipes exist in CloudKit but aren't tracked locally. They may be from a previous device or installation.")
                }
            }
            
            // Actions
            Section {
                Button("Refresh from CloudKit") {
                    Task { await loadRecipes() }
                }
                .disabled(isLoading)
                
                if let data = managerData, data.orphanedCount > 0 {
                    Button(role: .destructive) {
                        showingDeleteAllConfirmation = true
                    } label: {
                        Label("Delete All Orphaned (\(data.orphanedCount))", systemImage: "trash")
                    }
                    .disabled(isLoading)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search recipes")
        .navigationTitle("My CloudKit Recipes")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isLoading {
                ProgressView("Loading...")
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .alert("Delete All Orphaned Recipes?", isPresented: $showingDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await deleteAllOrphaned() }
            }
        } message: {
            if let data = managerData {
                Text("This will permanently delete \(data.orphanedCount) orphaned recipes from CloudKit. This cannot be undone.")
            }
        }
        .task {
            await loadRecipes()
        }
    }
    
    // MARK: - Actions
    
    private func loadRecipes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await sharingService.fetchMyCloudKitRecipesWithStatus(modelContext: modelContext)
            await MainActor.run {
                managerData = data
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load recipes: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    private func deleteRecipe(_ status: CloudKitRecipeStatus) {
        Task {
            isLoading = true
            
            do {
                try await sharingService.deleteRecipeFromCloudKit(cloudRecordID: status.cloudRecordID)
                
                // If there's a tracking record, mark it inactive
                if let tracking = status.localTrackingRecord {
                    tracking.isActive = false
                    try modelContext.save()
                }
                
                await loadRecipes()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete recipe: \(error.localizedDescription)"
                }
            }
            
            isLoading = false
        }
    }
    
    private func reTrackRecipe(_ status: CloudKitRecipeStatus) {
        Task {
            isLoading = true
            
            do {
                try sharingService.reTrackRecipe(
                    recipe: status.recipe,
                    cloudRecordID: status.cloudRecordID,
                    modelContext: modelContext
                )
                await loadRecipes()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to re-track recipe: \(error.localizedDescription)"
                }
            }
            
            isLoading = false
        }
    }
    
    private func deleteAllOrphaned() async {
        guard let data = managerData else { return }
        
        isLoading = true
        
        do {
            try await sharingService.deleteAllOrphanedRecipes(orphanedStatuses: data.orphanedRecipes)
            await loadRecipes()
        } catch {
            await MainActor.run {
                errorMessage = "Failed to delete orphaned recipes: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views

struct RecipeStatusRow: View {
    let status: CloudKitRecipeStatus
    let onDelete: () -> Void
    let onReTrack: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: status.statusIcon)
                    .foregroundColor(status.statusColor)
                
                Text(status.recipe.title)
                    .font(.headline)
                
                Spacer()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Text("Delete")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            Text("Shared: \(status.sharedDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Status:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(status.statusDescription)
                    .font(.caption)
                    .foregroundColor(status.statusColor)
            }
            
            if let onReTrack = onReTrack {
                Button {
                    onReTrack()
                } label: {
                    Label("Re-Track This Recipe", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        CloudKitRecipeManagerView()
    }
}
```

### 4. Add to Settings

```swift
// In SharingSettingsView.swift

Section {
    NavigationLink {
        CloudKitRecipeManagerView()
    } label: {
        Label("Manage CloudKit Recipes", systemImage: "cloud")
    }
} header: {
    Text("CloudKit Management")
} footer: {
    Text("View and manage all your recipes stored in CloudKit, including orphaned recipes that aren't tracked locally.")
}
```

---

## Benefits

✅ **Full Visibility** - Users can see every recipe they own in CloudKit  
✅ **Problem Detection** - Clearly shows orphaned vs tracked recipes  
✅ **Selective Control** - Delete individual recipes or bulk delete orphans  
✅ **Recovery Option** - Re-track orphaned recipes if desired  
✅ **Safety** - Preview before deletion, no blind cleanup  
✅ **Device Switching** - Identify and restore tracking on new devices  
✅ **Transparency** - Users understand what's happening with their data  

---

## Testing Checklist

- [ ] View loads correctly on empty CloudKit
- [ ] View shows tracked recipes correctly
- [ ] View identifies orphaned recipes correctly
- [ ] Individual delete works for tracked recipes
- [ ] Individual delete works for orphaned recipes
- [ ] Re-track restores tracking correctly
- [ ] Re-track reactivates inactive records
- [ ] Delete all orphaned shows correct count
- [ ] Delete all orphaned confirmation works
- [ ] Search filters recipes correctly
- [ ] Refresh updates data correctly
- [ ] Error handling works for network failures
- [ ] Loading states display correctly

---

## Migration Path

1. **Phase 1:** Add the view and service methods
2. **Phase 2:** Add navigation link in Settings
3. **Phase 3:** Add educational messaging about orphaned recipes
4. **Phase 4:** Deprecate blind "Clean Up Ghost Recipes" button
5. **Phase 5:** Implement CloudKit-backed tracking for future-proofing

---

## Future Enhancements

- **Export diagnostic report** - Share logs with developer for debugging
- **Batch operations** - Select multiple recipes to delete
- **Recipe preview** - View recipe details before deleting
- **Sync history** - Show when recipes were shared/unshared
- **Cross-reference with local recipes** - Show if recipe still exists locally
- **Auto-cleanup suggestion** - Notify users of orphaned recipes on app launch
