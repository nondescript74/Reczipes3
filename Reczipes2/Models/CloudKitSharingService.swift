//
//  CloudKitSharingService.swift
//  Reczipes2
//
//  Created on 1/15/26.
//

import Foundation
import CloudKit
import SwiftData
import UIKit
import Combine
import SwiftUI

/// Service for sharing recipes and recipe books via CloudKit Public Database
@MainActor
class CloudKitSharingService: ObservableObject {
    static let shared = CloudKitSharingService()
    
    let container: CKContainer
    let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    
    @Published var isCloudKitAvailable = false
    @Published var currentUserID: String?
    @Published var currentUserName: String?
    
    private init() {
        // Use the same container as your app
        self.container = CKContainer(identifier: "iCloud.com.headydiscy.reczipes")
        self.publicDatabase = container.publicCloudDatabase
        self.privateDatabase = container.privateCloudDatabase
        
        Task {
            await checkCloudKitAvailability()
        }
    }
    
    // MARK: - CloudKit Availability
    
    func checkCloudKitAvailability() async {
        do {
            let status = try await container.accountStatus()
            
            switch status {
            case .available:
                isCloudKitAvailable = true
                await fetchUserIdentity()
                logInfo("CloudKit available for sharing", category: "sharing")
                
            case .noAccount:
                isCloudKitAvailable = false
                logWarning("No iCloud account - sharing disabled", category: "sharing")
                
            case .restricted:
                isCloudKitAvailable = false
                logWarning("CloudKit restricted - sharing disabled", category: "sharing")
                
            case .couldNotDetermine:
                isCloudKitAvailable = false
                logWarning("CloudKit status unknown - sharing disabled", category: "sharing")
                
            case .temporarilyUnavailable:
                isCloudKitAvailable = false
                logWarning("CloudKit temporarily unavailable", category: "sharing")
                
            @unknown default:
                isCloudKitAvailable = false
            }
        } catch {
            isCloudKitAvailable = false
            logError("Failed to check CloudKit status: \(error)", category: "sharing")
        }
    }
    
    private func fetchUserIdentity() async {
        do {
            let userRecordID = try await container.userRecordID()
            currentUserID = userRecordID.recordName
            
            // Note: userIdentity(forUserRecordID:) was deprecated in iOS 17.0
            // For privacy reasons, we'll use a user-configured display name from SharingPreferences
            // Fall back to UserDefaults for backwards compatibility
            await fetchUserDisplayName()
            
            logInfo("User ID: \(currentUserID ?? "unknown"), Name: \(currentUserName ?? "not set")", category: "sharing")
        } catch {
            logError("Failed to fetch user identity: \(error)", category: "sharing")
        }
    }
    
    /// Fetch user's display name from SharingPreferences
    private func fetchUserDisplayName() async {
        // This needs to be called from a context where we have access to ModelContext
        // For now, read from UserDefaults as fallback
        currentUserName = UserDefaults.standard.string(forKey: "userDisplayName")
    }
    
    /// Update the current user's display name (call this when SharingPreferences change)
    func updateUserDisplayName(from preferences: SharingPreferences) {
        if preferences.allowOthersToSeeMyName, let displayName = preferences.displayName, !displayName.isEmpty {
            currentUserName = displayName
            // Also save to UserDefaults for persistence
            UserDefaults.standard.set(displayName, forKey: "userDisplayName")
        } else {
            currentUserName = nil
            UserDefaults.standard.removeObject(forKey: "userDisplayName")
        }
        logInfo("Updated user display name: \(currentUserName ?? "not set")", category: "sharing")
    }
    
    
    /// Fetch all recipes owned by current user with tracking status
    func fetchMyCloudKitRecipesWithStatus(modelContext: ModelContext) async throws -> CloudKitRecipeManagerData {
        guard let currentUserID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        logInfo("📋 Fetching all CloudKit recipes for current user...", category: "sharing")
        
        // 1. Fetch all local tracking records first
        let allTracking = try modelContext.fetch(FetchDescriptor<SharedRecipe>())
        logInfo("📋 Found \(allTracking.count) local tracking records", category: "sharing")
        
        // 2. Fetch CloudKit records with record IDs
        let allCloudKitRecords = try await fetchAllCloudKitRecords(type: CloudKitRecordType.sharedRecipe)
        let myCloudKitRecords = allCloudKitRecords.filter { record in
            guard let sharedBy = record["sharedBy"] as? String else { return false }
            return sharedBy == currentUserID
        }
        
        logInfo("📋 Found \(myCloudKitRecords.count) of my recipes in CloudKit", category: "sharing")
        
        // 3. Build lookup for tracking by both recipeID and cloudRecordID
        var trackingByRecipeID: [UUID: SharedRecipe] = [:]
        var trackingByCloudRecordID: [String: SharedRecipe] = [:]
        var orphanedTrackingRecords: [SharedRecipe] = []
        
        for tracking in allTracking {
            if let recipeID = tracking.recipeID {
                trackingByRecipeID[recipeID] = tracking
            }
            if let cloudRecordID = tracking.cloudRecordID {
                trackingByCloudRecordID[cloudRecordID] = tracking
            }
        }
        
        // 4. Build status objects from CloudKit records
        var statuses: [CloudKitRecipeStatus] = []
        var foundCloudRecordIDs = Set<String>()
        
        for record in myCloudKitRecords {
            guard let recipeData = record["recipeData"] as? String,
                  let jsonData = recipeData.data(using: .utf8),
                  let cloudRecipe = try? JSONDecoder().decode(CloudKitRecipe.self, from: jsonData),
                  let sharedDate = record["sharedDate"] as? Date else {
                logWarning("📋 Skipping invalid CloudKit record: \(record.recordID.recordName)", category: "sharing")
                continue
            }
            
            let cloudRecordID = record.recordID.recordName
            foundCloudRecordIDs.insert(cloudRecordID)
            
            // Check for tracking by both recipe ID and cloud record ID
            let trackingRecord = trackingByRecipeID[cloudRecipe.id] ?? trackingByCloudRecordID[cloudRecordID]
            
            let status = CloudKitRecipeStatus(
                recipe: cloudRecipe,
                cloudRecordID: cloudRecordID,
                sharedDate: sharedDate,
                localTrackingRecord: trackingRecord
            )
            
            statuses.append(status)
        }
        
        // 5. Clean up orphaned tracking records (tracking records that point to deleted CloudKit records)
        for tracking in allTracking {
            if let cloudRecordID = tracking.cloudRecordID,
               !foundCloudRecordIDs.contains(cloudRecordID),
               tracking.sharedByUserID == currentUserID {
                logWarning("📋 Found orphaned tracking record for '\(tracking.recipeTitle)' - CloudKit record was deleted", category: "sharing")
                orphanedTrackingRecords.append(tracking)
            }
        }
        
        // Clean up orphaned tracking records
        if !orphanedTrackingRecords.isEmpty {
            logInfo("📋 Cleaning up \(orphanedTrackingRecords.count) orphaned tracking records...", category: "sharing")
            for tracking in orphanedTrackingRecords {
                modelContext.delete(tracking)
            }
            try? modelContext.save()
        }
        
        // 6. Sort: tracked first, then by date
        statuses.sort { (lhs: CloudKitRecipeStatus, rhs: CloudKitRecipeStatus) in
            if lhs.isTracked != rhs.isTracked {
                return lhs.isTracked // Tracked first
            }
            return lhs.sharedDate > rhs.sharedDate // Newest first
        }
        
        logInfo("📋 Status: \(statuses.filter { $0.isTracked }.count) tracked, \(statuses.filter { $0.isOrphaned }.count) orphaned", category: "sharing")
        logInfo("📋 Cleaned up \(orphanedTrackingRecords.count) stale tracking records", category: "sharing")
        
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
        let recipeIDToFind = recipe.id
        let existing = try modelContext.fetch(
            FetchDescriptor<SharedRecipe>(
                predicate: #Predicate<SharedRecipe> { $0.recipeID == recipeIDToFind }
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
                cloudRecordID: cloudRecordID,
                sharedByUserID: recipe.sharedByUserID,
                sharedByUserName: recipe.sharedByUserName,
                sharedDate: Date(),
                recipeTitle: recipe.title,
                recipeImageName: recipe.imageName
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
    
    // MARK: - CloudKit Recipe Book Manager
    
    /// Fetch all recipe books owned by current user with tracking status
    func fetchMyCloudKitRecipeBooksWithStatus(modelContext: ModelContext) async throws -> CloudKitRecipeBookManagerData {
        guard let currentUserID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        logInfo("📚 Fetching all CloudKit recipe books for current user...", category: "sharing")
        
        // 1. Fetch all recipe book records from CloudKit
        let allRecords = try await fetchAllCloudKitRecords(type: CloudKitRecordType.sharedRecipeBook)
        logInfo("📚 Found \(allRecords.count) total recipe book records in CloudKit", category: "sharing")
        
        // 2. Filter to only current user's books
        let myCloudKitRecords = allRecords.filter { record in
            guard let sharedBy = record["sharedBy"] as? String else { return false }
            return sharedBy == currentUserID
        }
        logInfo("📚 Found \(myCloudKitRecords.count) recipe books belonging to current user", category: "sharing")
        
        // 3. Fetch all local tracking records
        let allTrackingDescriptor = FetchDescriptor<SharedRecipeBook>()
        let allTracking = (try? modelContext.fetch(allTrackingDescriptor)) ?? []
        logInfo("📚 Found \(allTracking.count) local SharedRecipeBook tracking records", category: "sharing")
        
        // Build lookup dictionaries
        var trackingByBookID: [UUID: SharedRecipeBook] = [:]
        var trackingByCloudRecordID: [String: SharedRecipeBook] = [:]
        
        for tracking in allTracking {
            if let bookID = tracking.bookID {
                trackingByBookID[bookID] = tracking
            }
            if let cloudRecordID = tracking.cloudRecordID {
                trackingByCloudRecordID[cloudRecordID] = tracking
            }
        }
        
        // 4. Build status objects from CloudKit records
        var statuses: [CloudKitRecipeBookStatus] = []
        var foundCloudRecordIDs = Set<String>()
        
        for record in myCloudKitRecords {
            guard let bookData = record["bookData"] as? String,
                  let jsonData = bookData.data(using: .utf8),
                  let cloudBook = try? JSONDecoder().decode(CloudKitRecipeBook.self, from: jsonData),
                  let sharedDate = record["sharedDate"] as? Date else {
                logWarning("📚 Skipping invalid CloudKit record: \(record.recordID.recordName)", category: "sharing")
                continue
            }
            
            let cloudRecordID = record.recordID.recordName
            foundCloudRecordIDs.insert(cloudRecordID)
            
            // Check if we have a tracking record for this CloudKit record
            let trackingRecord = trackingByCloudRecordID[cloudRecordID] ?? trackingByBookID[cloudBook.id]
            
            let status = CloudKitRecipeBookStatus(
                book: cloudBook,
                cloudRecordID: cloudRecordID,
                sharedDate: sharedDate,
                localTrackingRecord: trackingRecord
            )
            
            statuses.append(status)
        }
        
        logInfo("📚 Built \(statuses.count) status objects", category: "sharing")
        logInfo("📚 Tracked: \(statuses.filter { $0.isTracked }.count), Orphaned: \(statuses.filter { $0.isOrphaned }.count)", category: "sharing")
        
        return CloudKitRecipeBookManagerData(books: statuses)
    }
    
    /// Delete a recipe book from CloudKit
    func deleteRecipeBookFromCloudKit(cloudRecordID: String) async throws {
        let recordID = CKRecord.ID(recordName: cloudRecordID)
        
        do {
            _ = try await publicDatabase.deleteRecord(withID: recordID)
            logInfo("🗑️ Deleted recipe book from CloudKit: \(cloudRecordID)", category: "sharing")
        } catch {
            logError("❌ Failed to delete recipe book from CloudKit: \(error)", category: "sharing")
            throw SharingError.uploadFailed(error)
        }
    }
    
    /// Re-track an orphaned recipe book
    func reTrackRecipeBook(book: CloudKitRecipeBook, cloudRecordID: String, modelContext: ModelContext) throws {
        logInfo("🔄 Re-tracking recipe book: \(book.name)", category: "sharing")
        
        // Check if tracking already exists
        let cloudRecordIDToFind = cloudRecordID
        let existingDescriptor = FetchDescriptor<SharedRecipeBook>(
            predicate: #Predicate<SharedRecipeBook> { sharedBook in
                sharedBook.cloudRecordID == cloudRecordIDToFind
            }
        )
        
        if let existing = try? modelContext.fetch(existingDescriptor).first {
            // Reactivate existing tracking
            existing.isActive = true
            logInfo("✅ Reactivated existing tracking record", category: "sharing")
        } else {
            // Create new tracking record
            let tracking = SharedRecipeBook(
                bookID: book.id,
                cloudRecordID: cloudRecordID,
                sharedByUserID: book.sharedByUserID,
                sharedByUserName: book.sharedByUserName,
                sharedDate: book.sharedDate,
                bookName: book.name,
                bookDescription: book.bookDescription,
                coverImageName: book.coverImageName
            )
            modelContext.insert(tracking)
            logInfo("✅ Created new tracking record", category: "sharing")
        }
        
        try modelContext.save()
    }
    
    /// Delete all orphaned recipe books from CloudKit
    func deleteAllOrphanedRecipeBooks(orphanedStatuses: [CloudKitRecipeBookStatus]) async throws {
        logInfo("🗑️ Deleting \(orphanedStatuses.count) orphaned recipe books from CloudKit...", category: "sharing")
        
        var successCount = 0
        var failCount = 0
        
        for status in orphanedStatuses {
            do {
                try await deleteRecipeBookFromCloudKit(cloudRecordID: status.cloudRecordID)
                successCount += 1
            } catch {
                logError("❌ Failed to delete '\(status.book.name)': \(error)", category: "sharing")
                failCount += 1
            }
        }
        
        logInfo("✅ Deleted \(successCount) orphaned recipe books, \(failCount) failures", category: "sharing")
    }
    
    // MARK: - Share Recipe
    
    func shareRecipe(_ recipe: RecipeX, modelContext: ModelContext) async throws -> String {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        guard let userID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        // Check if this recipe is already shared and active
        let recipeIDToFind = recipe.safeID
        let existingDescriptor = FetchDescriptor<SharedRecipe>(
            predicate: #Predicate<SharedRecipe> { sharedRecipe in
                sharedRecipe.recipeID == recipeIDToFind && sharedRecipe.isActive == true
            }
        )
        
        if let existingShared = try? modelContext.fetch(existingDescriptor).first,
           let cloudRecordID = existingShared.cloudRecordID {
            // Verify it still exists in CloudKit
            do {
                let recordID = CKRecord.ID(recordName: cloudRecordID)
                _ = try await publicDatabase.record(for: recordID)
                logInfo("Recipe '\(recipe.safeTitle)' is already shared (verified in CloudKit)", category: "sharing")
                return cloudRecordID
            } catch {
                // Record doesn't exist in CloudKit anymore - clean up and reshare
                logWarning("CloudKit record missing for tracked share - will reshare", category: "sharing")
                modelContext.delete(existingShared)
                try? modelContext.save()
            }
        }
        
        // Check for duplicates in CloudKit by recipe ID (safety check)
        let query = CKQuery(
            recordType: CloudKitRecordType.sharedRecipe,
            predicate: NSPredicate(format: "sharedBy == %@", userID)
        )
        let existingRecords = try await publicDatabase.records(matching: query, desiredKeys: ["recipeData"], resultsLimit: 400)
        
        // Delete any existing records for this recipe ID
        for (_, result) in existingRecords.matchResults {
            if case .success(let record) = result,
               let recipeData = record["recipeData"] as? String,
               let jsonData = recipeData.data(using: .utf8),
               let cloudRecipe = try? JSONDecoder().decode(CloudKitRecipe.self, from: jsonData),
               cloudRecipe.id == recipe.safeID {
                // Found duplicate - delete it
                _ = try? await publicDatabase.deleteRecord(withID: record.recordID)
                logInfo("Deleted duplicate CloudKit record for recipe '\(recipe.safeTitle)'", category: "sharing")
            }
        }
        
        // Create CloudKit record
        let record = CKRecord(recordType: CloudKitRecordType.sharedRecipe)
        
        // Convert recipe to CloudKit-friendly format
        let cloudRecipe = CloudKitRecipe(
            id: recipe.safeID,
            title: recipe.safeTitle,
            headerNotes: recipe.headerNotes,
            yield: recipe.yield,
            ingredientSections: recipe.ingredientSections,
            instructionSections: recipe.instructionSections,
            notes: recipe.notes,
            reference: recipe.reference,
            imageName: recipe.imageName,
            additionalImageNames: recipe.additionalImageNames,
            sharedByUserID: userID,
            sharedByUserName: currentUserName,
            sharedDate: Date()
        )
        
        // Encode to JSON and store in CloudKit
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(cloudRecipe)
        
        record["recipeData"] = String(data: jsonData, encoding: .utf8)
        record["title"] = recipe.safeTitle as CKRecordValue
        record["sharedBy"] = userID as CKRecordValue
        record["sharedByName"] = (currentUserName ?? "Anonymous") as CKRecordValue
        record["sharedDate"] = Date() as CKRecordValue
        
        // Upload images if they exist
        if let imageName = recipe.imageName {
            try await uploadImage(named: imageName, to: record, fieldName: "mainImage")
        }
        
        // Save to public database
        let savedRecord = try await publicDatabase.save(record)
        
        // Track locally
        let sharedRecipe = SharedRecipe(
            recipeID: recipe.safeID,
            cloudRecordID: savedRecord.recordID.recordName,
            sharedByUserID: userID,
            sharedByUserName: currentUserName,
            recipeTitle: recipe.safeTitle,
            recipeImageName: recipe.imageName
        )
        
        modelContext.insert(sharedRecipe)
        try modelContext.save()
        
        logInfo("Shared recipe: \(recipe.safeTitle)", category: "sharing")
        logInfo("Community share successful", category: "analytics")
        
        return savedRecord.recordID.recordName
    }
    
    // MARK: - Share Recipe Book
    
    func shareRecipeBook(_ book: Book, modelContext: ModelContext) async throws -> String {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        guard let userID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        // Check if this book is already shared and active
        let bookIDToFind = book.id
        let existingDescriptor = FetchDescriptor<SharedRecipeBook>(
            predicate: #Predicate<SharedRecipeBook> { sharedBook in
                sharedBook.bookID == bookIDToFind && sharedBook.isActive == true
            }
        )
        
        if let existingShared = try? modelContext.fetch(existingDescriptor).first {
            logInfo("Book '\(String(describing: book.name))' is already shared", category: "sharing")
            return existingShared.cloudRecordID ?? "Already shared"
        }
        
        logInfo("📚 Sharing recipe book '\(String(describing: book.name))' with \(book.recipeIDs?.count ?? 0) recipes...", category: "sharing")
        
        // Fetch recipe previews for all recipes in the book
        var recipePreviews: [RecipePreviewData] = []
        var recipeCloudRecordIDs: [UUID: String] = [:]
        
        // Safely unwrap recipeIDs before iterating
        guard let recipeIDs = book.recipeIDs else {
            throw SharingError.invalidData
        }
        
        for recipeID in recipeIDs {
            // Find the recipe in local SwiftData (using RecipeX)
            let recipeDescriptor = FetchDescriptor<RecipeX>(
                predicate: #Predicate<RecipeX> { $0.id == recipeID }
            )
            
            guard let recipes = try? modelContext.fetch(recipeDescriptor),
                  let recipe = recipes.first else {
                logWarning("Recipe \(recipeID) not found locally, skipping preview", category: "sharing")
                continue
            }
            
            // Check if this recipe is already shared (to get its CloudKit record ID)
            let sharedRecipeDescriptor = FetchDescriptor<SharedRecipe>(
                predicate: #Predicate<SharedRecipe> { $0.recipeID == recipeID && $0.isActive == true }
            )
            var cloudRecordID = (try? modelContext.fetch(sharedRecipeDescriptor).first)?.cloudRecordID
            
            // If recipe is not shared yet, share it now so we have a cloudRecordID
            if cloudRecordID == nil {
                logInfo("  📤 Recipe '\(recipe.safeTitle)' not yet shared, sharing now...", category: "sharing")
                do {
                    cloudRecordID = try await shareRecipe(recipe, modelContext: modelContext)
                    logInfo("  ✅ Shared recipe '\(recipe.safeTitle)' with CloudKit ID: \(cloudRecordID ?? "unknown")", category: "sharing")
                } catch {
                    logError("  ❌ Failed to share recipe '\(recipe.safeTitle)': \(error)", category: "sharing")
                    // Continue anyway - preview will be created without cloudRecordID (read-only)
                }
            }
            
            // Create thumbnail (small, base64-encoded)
            var thumbnailBase64: String?
            if let imageName = recipe.imageName {
                if let thumbnailData = createThumbnail(for: imageName, maxSize: 200) {
                    thumbnailBase64 = thumbnailData.base64EncodedString()
                }
            }
            
            // Create preview data with embedded thumbnail
            let preview = RecipePreviewData(
                id: recipe.safeID,
                title: recipe.safeTitle,
                headerNotes: recipe.headerNotes,
                imageName: recipe.imageName,
                recipeYield: recipe.recipeYield,
                cloudRecordID: cloudRecordID,
                thumbnailBase64: thumbnailBase64
            )
            
            recipePreviews.append(preview)
            
            if let cloudRecordID = cloudRecordID {
                recipeCloudRecordIDs[recipe.safeID] = cloudRecordID
            }
            
            logInfo("  ✅ Added preview for '\(recipe.safeTitle)'\(thumbnailBase64 != nil ? " (with thumbnail)" : "")", category: "sharing")
        }
        
        logInfo("📚 Created \(recipePreviews.count) recipe previews", category: "sharing")
        
        // Create CloudKit record
        let record = CKRecord(recordType: CloudKitRecordType.sharedRecipeBook)
        
        // Convert book to CloudKit-friendly format with previews
        let cloudBook = CloudKitRecipeBook(
            id: book.id!,
            name: book.name!,
            bookDescription: book.bookDescription,
            coverImageName: book.coverImageName,
            recipeIDs: book.recipeIDs!,
            color: book.color,
            sharedByUserID: userID,
            sharedByUserName: currentUserName,
            sharedDate: Date()
        )
        
        // Encode book data to JSON
        let encoder = JSONEncoder()
        let bookJsonData = try encoder.encode(cloudBook)
        
        record["bookData"] = String(data: bookJsonData, encoding: .utf8)
        record["name"] = book.name! as any CKRecordValue as CKRecordValue
        record["sharedBy"] = userID as CKRecordValue
        record["sharedByName"] = (currentUserName ?? "Anonymous") as CKRecordValue
        record["sharedDate"] = Date() as CKRecordValue
        
        // NEW: Store recipe previews with embedded thumbnails
        let previewsJsonData = try encoder.encode(recipePreviews)
        record["recipePreviews"] = String(data: previewsJsonData, encoding: .utf8)
        
        logInfo("📚 Uploading cover image...", category: "sharing")
        
        // Upload cover image if exists
        if let coverImageName = book.coverImageName {
            do {
                try await uploadImage(named: coverImageName, to: record, fieldName: "coverImage")
                logInfo("  ✅ Uploaded cover image: \(coverImageName)", category: "sharing")
            } catch {
                logWarning("  ⚠️ Failed to upload cover image: \(error)", category: "sharing")
            }
        } else if let coverImageData = book.coverImageData {
            // Handle inline cover image data
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_cover_\(String(describing: book.id)).jpg")
            try? coverImageData.write(to: tempURL)
            let asset = CKAsset(fileURL: tempURL)
            record["coverImage"] = asset
            logInfo("  ✅ Uploaded cover image from data", category: "sharing")
        }
        
        // Save to public database
        logInfo("📚 Saving to CloudKit Public Database...", category: "sharing")
        let savedRecord = try await publicDatabase.save(record)
        
        // Track locally
        let sharedBook = SharedRecipeBook(
            bookID: book.id!,
            cloudRecordID: savedRecord.recordID.recordName,
            sharedByUserID: userID,
            sharedByUserName: currentUserName,
            bookName: book.name!,
            bookDescription: book.bookDescription,
            coverImageName: book.coverImageName
        )
        
        modelContext.insert(sharedBook)
        try modelContext.save()
        
        logInfo("✅ Shared recipe book: \(String(describing: book.name)) with \(recipePreviews.count) recipe previews", category: "sharing")
        logInfo("Community share successful", category: "analytics")
        
        return savedRecord.recordID.recordName
    }
    
    // MARK: - Share Multiple Items
    
    func shareMultipleRecipes(_ recipes: [RecipeX], modelContext: ModelContext) async -> SharingResult {
        var successful = 0
        var failed = 0
        
        for recipe in recipes {
            do {
                _ = try await shareRecipe(recipe, modelContext: modelContext)
                successful += 1
            } catch {
                logError("Failed to share recipe '\(recipe.safeTitle)': \(error)", category: "sharing")
                logError("Community share failed: \(error)", category: "analytics")
                failed += 1
            }
        }
        
        if failed == 0 {
            return .success(recordID: "\(successful) recipes shared")
        } else {
            return .partialSuccess(successful: successful, failed: failed)
        }
    }
    
    func shareMultipleBooks(_ books: [Book], modelContext: ModelContext) async -> SharingResult {
        var successful = 0
        var failed = 0
        
        for book in books {
            do {
                _ = try await shareRecipeBook(book, modelContext: modelContext)
                successful += 1
            } catch {
                logError("Failed to share book '\(String(describing: book.name))': \(error)", category: "sharing")
                logError("Community share failed: \(error)", category: "analytics")
                failed += 1
            }
        }
        
        if failed == 0 {
            return .success(recordID: "\(successful) books shared")
        } else {
            return .partialSuccess(successful: successful, failed: failed)
        }
    }
    
    // MARK: - Fetch Shared Content
    
    /// Force refresh shared content by clearing any local cache
    func clearSharedContentCache(modelContext: ModelContext) throws {
        // This doesn't delete the actual shared recipes in CloudKit,
        // just the local tracking records that might be stale
        let sharedRecipesDescriptor = FetchDescriptor<SharedRecipe>()
        let sharedBooksDescriptor = FetchDescriptor<SharedRecipeBook>()
        
        let recipes = try modelContext.fetch(sharedRecipesDescriptor)
        let books = try modelContext.fetch(sharedBooksDescriptor)
        
        logInfo("Clearing \(recipes.count) cached shared recipes and \(books.count) cached books", category: "sharing")
        
        // Note: Only delete tracking records for recipes shared by OTHERS
        // Keep our own shared recipe tracking
        for recipe in recipes where recipe.sharedByUserID != currentUserID {
            modelContext.delete(recipe)
        }
        
        for book in books where book.sharedByUserID != currentUserID {
            modelContext.delete(book)
        }
        
        try modelContext.save()
        logInfo("Shared content cache cleared - next fetch will be fresh from CloudKit", category: "sharing")
    }
    
    
    func fetchSharedRecipes(limit: Int = 400, excludeCurrentUser: Bool = true) async throws -> [CloudKitRecipe] {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        logInfo("Starting fetchSharedRecipes with limit: \(limit), excludeCurrentUser: \(excludeCurrentUser)", category: "sharing")
        
        // Build predicate: exclude current user's recipes if requested
        let predicate: NSPredicate
        if excludeCurrentUser, let currentUserID = currentUserID {
            predicate = NSPredicate(format: "sharedBy != %@", currentUserID)
            logInfo("Filtering out recipes from current user: \(currentUserID)", category: "sharing")
        } else {
            predicate = NSPredicate(value: true)
        }
        
        let query = CKQuery(recordType: CloudKitRecordType.sharedRecipe, predicate: predicate)
        // Note: Don't use sortDescriptors - fields must be marked queryable in CloudKit schema
        // We'll sort results in memory after fetching
        
        var allRecipes: [CloudKitRecipe] = []
        var cursor: CKQueryOperation.Cursor? = nil
        let batchSize = 100 // CloudKit recommended batch size
        var batchNumber = 1
        
        repeat {
            logInfo("Fetching batch #\(batchNumber) from CloudKit...", category: "sharing")
            let results: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)
            
            if let cursor = cursor {
                // Continue fetching with cursor
                results = try await publicDatabase.records(continuingMatchFrom: cursor, desiredKeys: nil, resultsLimit: batchSize)
            } else {
                // Initial fetch
                results = try await publicDatabase.records(matching: query, desiredKeys: nil, resultsLimit: batchSize)
            }
            
            // Process batch
            var successCount = 0
            var failureCount = 0
            for (_, result) in results.matchResults {
                switch result {
                case .success(let record):
                    if let recipeData = record["recipeData"] as? String,
                       let jsonData = recipeData.data(using: .utf8) {
                        let decoder = JSONDecoder()
                        if let recipe = try? decoder.decode(CloudKitRecipe.self, from: jsonData) {
                            allRecipes.append(recipe)
                            successCount += 1
                        } else {
                            logWarning("Failed to decode recipe data from record: \(record.recordID.recordName)", category: "sharing")
                            failureCount += 1
                        }
                    } else {
                        logWarning("Record missing recipeData field: \(record.recordID.recordName)", category: "sharing")
                        failureCount += 1
                    }
                case .failure(let error):
                    logError("Failed to fetch shared recipe: \(error)", category: "sharing")
                    failureCount += 1
                }
            }
            logInfo("Batch decoded: \(successCount) success, \(failureCount) failures", category: "sharing")
            
            // Update cursor for next iteration
            cursor = results.queryCursor
            
            logInfo("Batch #\(batchNumber) complete: \(allRecipes.count) total recipes so far, cursor: \(cursor != nil ? "has more" : "end")", category: "sharing")
            batchNumber += 1
            
            // Stop if we've reached the limit or no more results
            if allRecipes.count >= limit || cursor == nil {
                break
            }
            
        } while cursor != nil
        
        // Sort in memory by sharedDate (most recent first)
        allRecipes.sort { recipe1, recipe2 in
            recipe1.sharedDate > recipe2.sharedDate
        }
        
        logInfo("✅ Fetched \(allRecipes.count) shared recipes total (using cursor pagination)", category: "sharing")
        return allRecipes
    }
    
    func fetchSharedRecipeBooks(limit: Int = 400, excludeCurrentUser: Bool = true) async throws -> [CloudKitRecipeBook] {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        // Build predicate: exclude current user's books if requested
        let predicate: NSPredicate
        if excludeCurrentUser, let currentUserID = currentUserID {
            predicate = NSPredicate(format: "sharedBy != %@", currentUserID)
            logInfo("Filtering out recipe books from current user: \(currentUserID)", category: "sharing")
        } else {
            predicate = NSPredicate(value: true)
        }
        
        let query = CKQuery(recordType: CloudKitRecordType.sharedRecipeBook, predicate: predicate)
        // Note: Don't use sortDescriptors - fields must be marked queryable in CloudKit schema
        // We'll sort results in memory after fetching
        
        var allBooks: [CloudKitRecipeBook] = []
        var cursor: CKQueryOperation.Cursor? = nil
        let batchSize = 100 // CloudKit recommended batch size
        
        repeat {
            let results: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)
            
            if let cursor = cursor {
                // Continue fetching with cursor
                results = try await publicDatabase.records(continuingMatchFrom: cursor, desiredKeys: nil, resultsLimit: batchSize)
            } else {
                // Initial fetch
                results = try await publicDatabase.records(matching: query, desiredKeys: nil, resultsLimit: batchSize)
            }
            
            // Process batch
            for (_, result) in results.matchResults {
                switch result {
                case .success(let record):
                    if let bookData = record["bookData"] as? String,
                       let jsonData = bookData.data(using: .utf8) {
                        let decoder = JSONDecoder()
                        if let book = try? decoder.decode(CloudKitRecipeBook.self, from: jsonData) {
                            allBooks.append(book)
                        }
                    }
                case .failure(let error):
                    logError("Failed to fetch shared book: \(error)", category: "sharing")
                }
            }
            
            // Update cursor for next iteration
            cursor = results.queryCursor
            
            // Stop if we've reached the limit or no more results
            if allBooks.count >= limit || cursor == nil {
                break
            }
            
        } while cursor != nil
        
        // Sort in memory by sharedDate (most recent first)
        allBooks.sort { book1, book2 in
            book1.sharedDate > book2.sharedDate
        }
        
        logInfo("Fetched \(allBooks.count) shared recipe books (using cursor pagination)", category: "sharing")
        return allBooks
    }
    
    // MARK: - Unshare Content
    
    func unshareRecipe(cloudRecordID: String, modelContext: ModelContext) async throws {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        let recordID = CKRecord.ID(recordName: cloudRecordID)
        try await publicDatabase.deleteRecord(withID: recordID)
        
        // Remove from local tracking
        let recordIDToFind = cloudRecordID
        let descriptor = FetchDescriptor<SharedRecipe>(
            predicate: #Predicate<SharedRecipe> { sharedRecipe in
                sharedRecipe.cloudRecordID == recordIDToFind
            }
        )
        
        if let sharedRecipe = try modelContext.fetch(descriptor).first {
            modelContext.delete(sharedRecipe)
            try modelContext.save()
        }
        
        logInfo("Unshared recipe with ID: \(cloudRecordID)", category: "sharing")
    }
    
    func unshareRecipeBook(cloudRecordID: String, modelContext: ModelContext) async throws {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        logInfo("📚 Unsharing book: \(cloudRecordID)", category: "sharing")
        
        // Find the SharedRecipeBook entry to get the bookID before deletion
        let recordIDToFind = cloudRecordID
        let sharedBookDescriptor = FetchDescriptor<SharedRecipeBook>(
            predicate: #Predicate<SharedRecipeBook> { sharedBook in
                sharedBook.cloudRecordID == recordIDToFind
            }
        )
        
        let sharedBook = try modelContext.fetch(sharedBookDescriptor).first
        let bookID = sharedBook?.bookID
        
        // Delete from CloudKit first
        let recordID = CKRecord.ID(recordName: cloudRecordID)
        try await publicDatabase.deleteRecord(withID: recordID)
        logInfo("📚 Deleted CloudKit record: \(cloudRecordID)", category: "sharing")
        
        // Remove from local tracking
        if let sharedBook = sharedBook {
            modelContext.delete(sharedBook)
            logInfo("📚 Deleted SharedRecipeBook tracking entry", category: "sharing")
        }
        
        // IMPORTANT: Also delete the local RecipeBook if this was the user's own shared book
        // (Don't delete it if it's someone else's shared book - that should only be cleaned by sync)
        if let bookID = bookID,
           let currentUserID = currentUserID,
           sharedBook?.sharedByUserID == currentUserID {
            let bookDescriptor = FetchDescriptor<Book>(
                predicate: #Predicate<Book> { book in
                    book.id == bookID
                }
            )
            
            if (try modelContext.fetch(bookDescriptor).first) != nil {
                logInfo("📚 Also deleting local RecipeBook (user's own shared book)", category: "sharing")
                // Note: We're NOT deleting the book here because the user may still want to keep it locally
                // Only mark the sharing as inactive
            }
        }
        
        try modelContext.save()
        logInfo("✅ Successfully unshared recipe book: \(cloudRecordID)", category: "sharing")
    }
    
    // MARK: - Image Handling
    
    private func uploadImage(named imageName: String, to record: CKRecord, fieldName: String) async throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageURL = documentsPath.appendingPathComponent(imageName)
        
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            logWarning("Image file not found: \(imageName)", category: "sharing")
            return
        }
        
        let asset = CKAsset(fileURL: imageURL)
        record[fieldName] = asset
    }
    
    func downloadImage(from record: CKRecord, fieldName: String) async throws -> UIImage? {
        guard let asset = record[fieldName] as? CKAsset,
              let fileURL = asset.fileURL else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    // MARK: - Import Shared Content
    
    /// Diagnostic function to check CloudKit public database status and detect sync issues
    func diagnoseSharedRecipes() async {
        logInfo("🔍 DIAGNOSTIC: Starting shared recipes check...", category: "sharing")
        
        guard let currentUserID = currentUserID else {
            logError("🔍 DIAGNOSTIC: Cannot run - no current user ID", category: "sharing")
            return
        }
        
        do {
            // Fetch ALL recipes (including current user's) for diagnostic purposes
            let recipes = try await fetchSharedRecipes(excludeCurrentUser: false)
            logInfo("🔍 DIAGNOSTIC: Successfully fetched \(recipes.count) total recipes from CloudKit", category: "sharing")
            
            // Separate current user's recipes vs others
            let myRecipes = recipes.filter { $0.sharedByUserID == currentUserID }
            let othersRecipes = recipes.filter { $0.sharedByUserID != currentUserID }
            
            logInfo("🔍 DIAGNOSTIC: Found \(myRecipes.count) recipes from current user", category: "sharing")
            logInfo("🔍 DIAGNOSTIC: Found \(othersRecipes.count) recipes from other users", category: "sharing")
            
            // Group by sharer
            let groupedByUser = Dictionary(grouping: recipes) { $0.sharedByUserID }
            logInfo("🔍 DIAGNOSTIC: Total unique sharers: \(groupedByUser.count)", category: "sharing")
            for (userID, userRecipes) in groupedByUser.prefix(5) {
                let userName = userRecipes.first?.sharedByUserName ?? "Unknown"
                logInfo("🔍   User '\(userName)' (\(userID)): \(userRecipes.count) recipes", category: "sharing")
            }
            
            // Detect duplicates by recipe ID
            let groupedByRecipeID = Dictionary(grouping: recipes) { $0.id }
            let duplicates = groupedByRecipeID.filter { $0.value.count > 1 }
            if !duplicates.isEmpty {
                logWarning("🔍 DIAGNOSTIC: Found \(duplicates.count) duplicate recipe IDs in CloudKit!", category: "sharing")
                for (recipeID, dupes) in duplicates.prefix(5) {
                    logWarning("🔍   Recipe ID \(recipeID) has \(dupes.count) copies", category: "sharing")
                }
            } else {
                logInfo("🔍 DIAGNOSTIC: No duplicates found ✅", category: "sharing")
            }
            
            // Check for orphaned CloudKit records (recipes in CloudKit but not in local tracking)
            logInfo("🔍 DIAGNOSTIC: Checking for orphaned CloudKit records...", category: "sharing")
            logInfo("🔍   My CloudKit recipes: \(myRecipes.count)", category: "sharing")
            
        } catch {
            logError("🔍 DIAGNOSTIC: Failed to fetch recipes: \(error)", category: "sharing")
        }
    }
    
    /// Sync local SharedRecipe tracking with CloudKit truth
    /// This finds recipes in CloudKit that should be tracked locally but aren't
    func syncLocalTrackingWithCloudKit(modelContext: ModelContext) async throws {
        guard let currentUserID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        logInfo("🔄 SYNC: Starting local tracking sync...", category: "sharing")
        
        // Fetch ALL recipes from CloudKit (including current user's)
        let allCloudKitRecipes = try await fetchSharedRecipes(excludeCurrentUser: false)
        let myCloudKitRecipes = allCloudKitRecipes.filter { $0.sharedByUserID == currentUserID }
        
        logInfo("🔄 SYNC: Found \(myCloudKitRecipes.count) of my recipes in CloudKit", category: "sharing")
        
        // Fetch all local SharedRecipe tracking records
        let localTracking = try modelContext.fetch(FetchDescriptor<SharedRecipe>())
        let localRecipeIDs = Set(localTracking.compactMap { $0.recipeID })
        
        logInfo("🔄 SYNC: Found \(localTracking.count) local tracking records", category: "sharing")
        
        // Find CloudKit recipes that aren't tracked locally
        var missingLocalTracking: [CloudKitRecipe] = []
        
        for cloudRecipe in myCloudKitRecipes {
            if !localRecipeIDs.contains(cloudRecipe.id) {
                missingLocalTracking.append(cloudRecipe)
                logWarning("🔄 SYNC: Recipe '\(cloudRecipe.title)' (ID: \(cloudRecipe.id)) is in CloudKit but not tracked locally", category: "sharing")
            }
        }
        
        // Find local tracking records that don't exist in CloudKit
        let cloudKitRecipeIDs = Set(myCloudKitRecipes.map { $0.id })
        var orphanedLocalRecords: [SharedRecipe] = []
        
        for localRecord in localTracking where localRecord.isActive {
            if let recipeID = localRecord.recipeID,
               !cloudKitRecipeIDs.contains(recipeID) {
                orphanedLocalRecords.append(localRecord)
                logWarning("🔄 SYNC: Local tracking for '\(localRecord.recipeTitle)' (ID: \(recipeID)) has no CloudKit record", category: "sharing")
            }
        }
        
        logInfo("🔄 SYNC: Found \(missingLocalTracking.count) CloudKit recipes not tracked locally", category: "sharing")
        logInfo("🔄 SYNC: Found \(orphanedLocalRecords.count) orphaned local tracking records", category: "sharing")
        
        // Option 1: Clean up orphaned local records (recipes that were unshared but local tracking wasn't cleaned)
        if !orphanedLocalRecords.isEmpty {
            logInfo("🔄 SYNC: Cleaning up \(orphanedLocalRecords.count) orphaned local tracking records...", category: "sharing")
            for record in orphanedLocalRecords {
                record.isActive = false
                logInfo("🔄   Marked '\(record.recipeTitle)' as inactive", category: "sharing")
            }
        }
        
        // Option 2: Re-create missing local tracking records
        // Note: This is optional - you may want to just delete the orphaned CloudKit records instead
        if !missingLocalTracking.isEmpty {
            logWarning("🔄 SYNC: Found \(missingLocalTracking.count) recipes in CloudKit without local tracking", category: "sharing")
            logWarning("🔄   This suggests previous unshare operations failed to delete from CloudKit", category: "sharing")
            logWarning("🔄   Recommendation: Run cleanupGhostRecipes() to remove these from CloudKit", category: "sharing")
        }
        
        try modelContext.save()
        
        logInfo("✅ SYNC COMPLETE: Local tracking is now synced with CloudKit", category: "sharing")
        logInfo("   - Deactivated \(orphanedLocalRecords.count) stale local records", category: "sharing")
        logInfo("   - Found \(missingLocalTracking.count) ghost recipes in CloudKit (need cleanup)", category: "sharing")
    }
    
    /// Repair missing CloudKit record IDs for shared recipes
    /// This fixes recipes that were shared but don't have cloudRecordID stored
    func repairMissingRecipeCloudKitIDs(modelContext: ModelContext) async throws {
        guard let currentUserID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        logInfo("🔧 REPAIR: Starting repair of missing recipe CloudKit IDs...", category: "sharing")
        
        // Find all active shared recipes without cloudRecordID
        let allSharedRecipes = try modelContext.fetch(FetchDescriptor<SharedRecipe>())
        let recipesNeedingRepair = allSharedRecipes.filter { $0.cloudRecordID == nil && $0.isActive }
        
        if recipesNeedingRepair.isEmpty {
            logInfo("✅ REPAIR: No recipes need repair - all have CloudKit IDs", category: "sharing")
            return
        }
        
        logInfo("🔧 REPAIR: Found \(recipesNeedingRepair.count) recipes missing CloudKit IDs", category: "sharing")
        
        // Fetch all CloudKit records for current user's recipes
        let allCloudKitRecords = try await fetchAllCloudKitRecords(type: CloudKitRecordType.sharedRecipe)
        let myRecords = allCloudKitRecords.filter { record in
            guard let sharedBy = record["sharedBy"] as? String else { return false }
            return sharedBy == currentUserID
        }
        
        logInfo("🔧 REPAIR: Found \(myRecords.count) CloudKit records belonging to current user", category: "sharing")
        
        // Build mapping from recipeID to cloudRecordID
        var recipeIDToRecordID: [UUID: String] = [:]
        for record in myRecords {
            guard let recipeData = record["recipeData"] as? String,
                  let jsonData = recipeData.data(using: .utf8),
                  let cloudRecipe = try? JSONDecoder().decode(CloudKitRecipe.self, from: jsonData) else {
                continue
            }
            
            recipeIDToRecordID[cloudRecipe.id] = record.recordID.recordName
        }
        
        // Repair each recipe
        var repairedCount = 0
        for sharedRecipe in recipesNeedingRepair {
            guard let recipeID = sharedRecipe.recipeID,
                  let cloudRecordID = recipeIDToRecordID[recipeID] else {
                logWarning("🔧 REPAIR: Could not find CloudKit record for recipe '\(sharedRecipe.recipeTitle)'", category: "sharing")
                continue
            }
            
            sharedRecipe.cloudRecordID = cloudRecordID
            repairedCount += 1
            logInfo("🔧 REPAIR: Fixed '\(sharedRecipe.recipeTitle)' - added CloudKit ID: \(cloudRecordID)", category: "sharing")
        }
        
        try modelContext.save()
        
        logInfo("✅ REPAIR COMPLETE: Fixed \(repairedCount) of \(recipesNeedingRepair.count) recipes", category: "sharing")
    }
    
    /// Remove "ghost recipes" - recipes in CloudKit that users think they've unshared
    /// These are recipes where the CloudKit record exists but there's no active local tracking
    /// Returns: (ghostsFound: Int, deleted: Int, failed: Int)
    func cleanupGhostRecipes(modelContext: ModelContext) async throws -> (ghostsFound: Int, deleted: Int, failed: Int) {
        guard let currentUserID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        logInfo("👻 GHOST CLEANUP: Starting ghost recipe detection...", category: "sharing")
        
        // Fetch ALL my recipes from CloudKit
        let allCloudKitRecipes = try await fetchSharedRecipes(excludeCurrentUser: false)
        let myCloudKitRecipes = allCloudKitRecipes.filter { $0.sharedByUserID == currentUserID }
        
        logInfo("👻 Found \(myCloudKitRecipes.count) of my recipes in CloudKit", category: "sharing")
        
        // Fetch all ACTIVE local SharedRecipe tracking records
        let activeTracking = try modelContext.fetch(
            FetchDescriptor<SharedRecipe>(
                predicate: #Predicate<SharedRecipe> { $0.isActive == true }
            )
        )
        let activeRecipeIDs = Set(activeTracking.compactMap { $0.recipeID })
        
        logInfo("👻 Found \(activeTracking.count) active local tracking records", category: "sharing")
        
        // Find CloudKit recipes that aren't actively tracked (these are ghosts!)
        var ghostRecipes: [(recipe: CloudKitRecipe, cloudRecordID: String)] = []
        
        // We need to fetch the actual CloudKit records to get their record IDs for deletion
        let allCloudKitRecords = try await fetchAllCloudKitRecords(type: CloudKitRecordType.sharedRecipe)
        
        for record in allCloudKitRecords {
            guard let sharedBy = record["sharedBy"] as? String,
                  sharedBy == currentUserID,
                  let recipeData = record["recipeData"] as? String,
                  let jsonData = recipeData.data(using: .utf8),
                  let cloudRecipe = try? JSONDecoder().decode(CloudKitRecipe.self, from: jsonData) else {
                continue
            }
            
            // If this recipe isn't actively tracked locally, it's a ghost
            if !activeRecipeIDs.contains(cloudRecipe.id) {
                ghostRecipes.append((cloudRecipe, record.recordID.recordName))
                logWarning("👻 Found ghost recipe: '\(cloudRecipe.title)' (ID: \(cloudRecipe.id))", category: "sharing")
            }
        }
        
        logInfo("👻 Found \(ghostRecipes.count) ghost recipes", category: "sharing")
        
        if ghostRecipes.isEmpty {
            logInfo("✅ No ghost recipes found - everything is in sync!", category: "sharing")
            return (ghostsFound: 0, deleted: 0, failed: 0)
        }
        
        // Delete ghost recipes from CloudKit
        logInfo("👻 Deleting \(ghostRecipes.count) ghost recipes from CloudKit...", category: "sharing")
        var successCount = 0
        var failCount = 0
        
        for (recipe, cloudRecordID) in ghostRecipes {
            do {
                let recordID = CKRecord.ID(recordName: cloudRecordID)
                try await publicDatabase.deleteRecord(withID: recordID)
                logInfo("👻   Deleted '\(recipe.title)'", category: "sharing")
                successCount += 1
            } catch {
                logError("👻   Failed to delete '\(recipe.title)': \(error)", category: "sharing")
                failCount += 1
            }
        }
        
        logInfo("✅ GHOST CLEANUP COMPLETE: Deleted \(successCount) ghost recipes, \(failCount) failures", category: "sharing")
        
        return (ghostsFound: ghostRecipes.count, deleted: successCount, failed: failCount)
    }
    
    // MARK: - Ghost/Orphaned Recipe Books Cleanup
    
    /// Diagnostic result for recipe book analysis
    struct BookDiagnosticResult {
        let cloudKitBooks: Int
        let myCloudKitBooks: Int
        let othersCloudKitBooks: Int
        let localBooks: Int
        let activeTracking: Int
        let inactiveTracking: Int
        let myTracking: Int
        let othersTracking: Int
        let duplicateBookIDs: Int
        let orphanedBooks: Int
    }
    
    /// Diagnostic function to analyze recipe book sharing state
    /// Returns structured diagnostic data for display to user
    func diagnoseSharedRecipeBooks(modelContext: ModelContext) async -> BookDiagnosticResult? {
        guard let currentUserID = currentUserID else {
            logError("🔍 DIAGNOSTIC: No user ID available", category: "sharing")
            return nil
        }
        
        logInfo("🔍 DIAGNOSTIC: Starting Recipe Books Analysis", category: "sharing")
        
        var cloudKitBooks = 0
        var myCloudKitBooks = 0
        var othersCloudKitBooks = 0
        var duplicateBookIDs = 0
        
        // PART 1: Check CloudKit Public Database
        do {
            let books = try await fetchSharedRecipeBooks(excludeCurrentUser: false)
            cloudKitBooks = books.count
            myCloudKitBooks = books.filter { $0.sharedByUserID == currentUserID }.count
            othersCloudKitBooks = books.filter { $0.sharedByUserID != currentUserID }.count
            
            // Detect duplicates
            let groupedByBookID = Dictionary(grouping: books) { $0.id }
            duplicateBookIDs = groupedByBookID.filter { $0.value.count > 1 }.count
            
            logInfo("🔍 CloudKit: \(cloudKitBooks) total (\(myCloudKitBooks) mine, \(othersCloudKitBooks) others)", category: "sharing")
        } catch {
            logError("🔍 ❌ Failed to fetch from CloudKit: \(error)", category: "sharing")
        }
        
        var localBooks = 0
        var totalTracking = 0
        var activeCount = 0
        var myTracking = 0
        var othersTracking = 0
        var orphanedBooks = 0
        
        // PART 2: Check Local SwiftData
        do {
            let allLocalBooks = try modelContext.fetch(FetchDescriptor<Book>())
            localBooks = allLocalBooks.count
            
            let allTracking = try modelContext.fetch(FetchDescriptor<SharedRecipeBook>())
            totalTracking = allTracking.count
            
            let activeTracking = allTracking.filter { $0.isActive }
            activeCount = activeTracking.count
            
            myTracking = activeTracking.filter { $0.sharedByUserID == currentUserID }.count
            othersTracking = activeTracking.filter { $0.sharedByUserID != currentUserID }.count
            
            // Check for orphaned books
            let trackedBookIDs = Set(activeTracking.compactMap { $0.bookID })
            orphanedBooks = allLocalBooks.filter { !trackedBookIDs.contains($0.id!) }.count
            
            logInfo("🔍 Local: \(localBooks) books, \(activeCount) active tracking, \(orphanedBooks) orphaned", category: "sharing")
        } catch {
            logError("🔍 ❌ Failed to fetch from local: \(error)", category: "sharing")
        }
        
        return BookDiagnosticResult(
            cloudKitBooks: cloudKitBooks,
            myCloudKitBooks: myCloudKitBooks,
            othersCloudKitBooks: othersCloudKitBooks,
            localBooks: localBooks,
            activeTracking: activeCount,
            inactiveTracking: totalTracking - activeCount,
            myTracking: myTracking,
            othersTracking: othersTracking,
            duplicateBookIDs: duplicateBookIDs,
            orphanedBooks: orphanedBooks
        )
    }
    
    /// Sync local SharedRecipeBook tracking with CloudKit truth
    /// This finds recipe books in CloudKit that should be tracked locally but aren't
    func syncLocalRecipeBookTrackingWithCloudKit(modelContext: ModelContext) async throws {
        guard let currentUserID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        logInfo("🔄 SYNC: Starting local recipe book tracking sync...", category: "sharing")
        
        // Fetch ALL recipe books from CloudKit (including current user's)
        let allCloudKitBooks = try await fetchSharedRecipeBooks(excludeCurrentUser: false)
        let myCloudKitBooks = allCloudKitBooks.filter { $0.sharedByUserID == currentUserID }
        
        logInfo("🔄 SYNC: Found \(myCloudKitBooks.count) of my recipe books in CloudKit", category: "sharing")
        
        // Fetch all local SharedRecipeBook tracking records
        let localTracking = try modelContext.fetch(FetchDescriptor<SharedRecipeBook>())
        let localBookIDs = Set(localTracking.compactMap { $0.bookID })
        
        logInfo("🔄 SYNC: Found \(localTracking.count) local tracking records", category: "sharing")
        
        // Find CloudKit recipe books that aren't tracked locally
        var missingLocalTracking: [CloudKitRecipeBook] = []
        
        for cloudBook in myCloudKitBooks {
            if !localBookIDs.contains(cloudBook.id) {
                missingLocalTracking.append(cloudBook)
                logWarning("🔄 SYNC: Recipe book '\(cloudBook.name)' (ID: \(cloudBook.id)) is in CloudKit but not tracked locally", category: "sharing")
            }
        }
        
        // Find local tracking records that don't exist in CloudKit
        let cloudKitBookIDs = Set(myCloudKitBooks.map { $0.id })
        var orphanedLocalRecords: [SharedRecipeBook] = []
        
        for localRecord in localTracking where localRecord.isActive {
            if let bookID = localRecord.bookID,
               !cloudKitBookIDs.contains(bookID) {
                orphanedLocalRecords.append(localRecord)
                logWarning("🔄 SYNC: Local tracking for '\(localRecord.bookName)' (ID: \(bookID)) has no CloudKit record", category: "sharing")
            }
        }
        
        logInfo("🔄 SYNC: Found \(missingLocalTracking.count) CloudKit recipe books not tracked locally", category: "sharing")
        logInfo("🔄 SYNC: Found \(orphanedLocalRecords.count) orphaned local tracking records", category: "sharing")
        
        // Clean up orphaned local records (books that were unshared but local tracking wasn't cleaned)
        if !orphanedLocalRecords.isEmpty {
            logInfo("🔄 SYNC: Cleaning up \(orphanedLocalRecords.count) orphaned local tracking records...", category: "sharing")
            for record in orphanedLocalRecords {
                record.isActive = false
                logInfo("🔄   Marked '\(record.bookName)' as inactive", category: "sharing")
            }
        }
        
        // Warn about missing local tracking
        if !missingLocalTracking.isEmpty {
            logWarning("🔄 SYNC: Found \(missingLocalTracking.count) recipe books in CloudKit without local tracking", category: "sharing")
            logWarning("🔄   This suggests previous unshare operations failed to delete from CloudKit", category: "sharing")
            logWarning("🔄   Recommendation: Run cleanupGhostRecipeBooks() to remove these from CloudKit", category: "sharing")
        }
        
        try modelContext.save()
        
        logInfo("✅ SYNC COMPLETE: Local recipe book tracking is now synced with CloudKit", category: "sharing")
        logInfo("   - Deactivated \(orphanedLocalRecords.count) stale local records", category: "sharing")
        logInfo("   - Found \(missingLocalTracking.count) ghost recipe books in CloudKit (need cleanup)", category: "sharing")
    }
    
    /// Repair missing CloudKit record IDs for shared recipe books
    /// This fixes books that were shared but don't have cloudRecordID stored
    func repairMissingRecipeBookCloudKitIDs(modelContext: ModelContext) async throws {
        guard let currentUserID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        logInfo("🔧 REPAIR: Starting repair of missing recipe book CloudKit IDs...", category: "sharing")
        
        // Find all active shared books without cloudRecordID
        let allSharedBooks = try modelContext.fetch(FetchDescriptor<SharedRecipeBook>())
        let booksNeedingRepair = allSharedBooks.filter { $0.cloudRecordID == nil && $0.isActive }
        
        if booksNeedingRepair.isEmpty {
            logInfo("✅ REPAIR: No recipe books need repair - all have CloudKit IDs", category: "sharing")
            return
        }
        
        logInfo("🔧 REPAIR: Found \(booksNeedingRepair.count) books missing CloudKit IDs", category: "sharing")
        
        // Fetch all CloudKit records for current user's books
        let allCloudKitRecords = try await fetchAllCloudKitRecords(type: CloudKitRecordType.sharedRecipeBook)
        let myRecords = allCloudKitRecords.filter { record in
            guard let sharedBy = record["sharedBy"] as? String else { return false }
            return sharedBy == currentUserID
        }
        
        logInfo("🔧 REPAIR: Found \(myRecords.count) CloudKit records belonging to current user", category: "sharing")
        
        // Build mapping from bookID to cloudRecordID
        var bookIDToRecordID: [UUID: String] = [:]
        for record in myRecords {
            guard let bookData = record["bookData"] as? String,
                  let jsonData = bookData.data(using: .utf8),
                  let cloudBook = try? JSONDecoder().decode(CloudKitRecipeBook.self, from: jsonData) else {
                continue
            }
            
            bookIDToRecordID[cloudBook.id] = record.recordID.recordName
        }
        
        // Repair each book
        var repairedCount = 0
        for sharedBook in booksNeedingRepair {
            guard let bookID = sharedBook.bookID,
                  let cloudRecordID = bookIDToRecordID[bookID] else {
                logWarning("🔧 REPAIR: Could not find CloudKit record for book '\(sharedBook.bookName)'", category: "sharing")
                continue
            }
            
            sharedBook.cloudRecordID = cloudRecordID
            repairedCount += 1
            logInfo("🔧 REPAIR: Fixed '\(sharedBook.bookName)' - added CloudKit ID: \(cloudRecordID)", category: "sharing")
        }
        
        try modelContext.save()
        
        logInfo("✅ REPAIR COMPLETE: Fixed \(repairedCount) of \(booksNeedingRepair.count) books", category: "sharing")
    }
    
    /// Remove "ghost recipe books" - books in CloudKit that users think they've unshared
    /// These are books where the CloudKit record exists but there's no active local tracking
    /// Returns: (ghostsFound: Int, deleted: Int, failed: Int)
    func cleanupGhostRecipeBooks(modelContext: ModelContext) async throws -> (ghostsFound: Int, deleted: Int, failed: Int) {
        guard let currentUserID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        logInfo("👻 GHOST CLEANUP: Starting ghost recipe book detection...", category: "sharing")
        
        // Fetch ALL my recipe books from CloudKit
        let allCloudKitBooks = try await fetchSharedRecipeBooks(excludeCurrentUser: false)
        let myCloudKitBooks = allCloudKitBooks.filter { $0.sharedByUserID == currentUserID }
        
        logInfo("👻 Found \(myCloudKitBooks.count) of my recipe books in CloudKit", category: "sharing")
        
        // Fetch all ACTIVE local SharedRecipeBook tracking records
        let activeTracking = try modelContext.fetch(
            FetchDescriptor<SharedRecipeBook>(
                predicate: #Predicate<SharedRecipeBook> { $0.isActive == true }
            )
        )
        let activeBookIDs = Set(activeTracking.compactMap { $0.bookID })
        
        logInfo("👻 Found \(activeTracking.count) active local tracking records", category: "sharing")
        
        // Find CloudKit recipe books that aren't actively tracked (these are ghosts!)
        var ghostBooks: [(book: CloudKitRecipeBook, cloudRecordID: String)] = []
        
        // We need to fetch the actual CloudKit records to get their record IDs for deletion
        let allCloudKitRecords = try await fetchAllCloudKitRecords(type: CloudKitRecordType.sharedRecipeBook)
        
        for record in allCloudKitRecords {
            guard let sharedBy = record["sharedBy"] as? String,
                  sharedBy == currentUserID,
                  let bookData = record["bookData"] as? String,
                  let jsonData = bookData.data(using: .utf8),
                  let cloudBook = try? JSONDecoder().decode(CloudKitRecipeBook.self, from: jsonData) else {
                continue
            }
            
            // If this book isn't actively tracked locally, it's a ghost
            if !activeBookIDs.contains(cloudBook.id) {
                ghostBooks.append((cloudBook, record.recordID.recordName))
                logWarning("👻 Found ghost recipe book: '\(cloudBook.name)' (ID: \(cloudBook.id))", category: "sharing")
            }
        }
        
        logInfo("👻 Found \(ghostBooks.count) ghost recipe books", category: "sharing")
        
        if ghostBooks.isEmpty {
            logInfo("✅ No ghost recipe books found - everything is in sync!", category: "sharing")
            return (ghostsFound: 0, deleted: 0, failed: 0)
        }
        
        // Delete ghost recipe books from CloudKit
        logInfo("👻 Deleting \(ghostBooks.count) ghost recipe books from CloudKit...", category: "sharing")
        var successCount = 0
        var failCount = 0
        
        for (book, cloudRecordID) in ghostBooks {
            do {
                let recordID = CKRecord.ID(recordName: cloudRecordID)
                try await publicDatabase.deleteRecord(withID: recordID)
                logInfo("👻   Deleted '\(book.name)'", category: "sharing")
                successCount += 1
            } catch {
                logError("👻   Failed to delete '\(book.name)': \(error)", category: "sharing")
                failCount += 1
            }
        }
        
        logInfo("✅ GHOST CLEANUP COMPLETE: Deleted \(successCount) ghost recipe books, \(failCount) failures", category: "sharing")
        
        return (ghostsFound: ghostBooks.count, deleted: successCount, failed: failCount)
    }
    
    // MARK: - Community Recipes Sync (Temporary Cache)
    
    /// Sync community recipes for viewing (not permanent import)
    /// Creates temporary cache for viewing, cooking, etc. with automatic cleanup
    /// Uses pagination to fetch all available recipes efficiently
    func syncCommunityRecipesForViewing(modelContext: ModelContext, limit: Int = Int.max) async throws {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        let isFetchingAll = limit == Int.max
        logInfo("📖 SYNC: Syncing community recipes for viewing\(isFetchingAll ? " (ALL recipes)" : " (limit: \(limit))")...", category: "sharing")
        
        // Fetch shared recipes from CloudKit with pagination
        // The fetchSharedRecipes method automatically handles pagination in batches of 100
        let cloudRecipes = try await fetchSharedRecipes(limit: limit, excludeCurrentUser: true)
        let recipesToCache = isFetchingAll ? cloudRecipes : Array(cloudRecipes.prefix(limit))
        
        logInfo("📖 SYNC: Found \(cloudRecipes.count) community recipes, caching \(recipesToCache.count)", category: "sharing")
        
        // Fetch existing cached recipes
        let existingCached = try modelContext.fetch(FetchDescriptor<CachedSharedRecipe>())
        var existingByID = [UUID: CachedSharedRecipe]()
        for cached in existingCached {
            existingByID[cached.id] = cached
        }
        
        // Track which recipes are still in CloudKit
        var currentCloudRecipeIDs = Set<UUID>()
        
        var addedCount = 0
        var updatedCount = 0
        
        // Process each CloudKit recipe
        for cloudRecipe in recipesToCache {
            currentCloudRecipeIDs.insert(cloudRecipe.id)
            
            if let existingCached = existingByID[cloudRecipe.id] {
                // Update existing cache
                existingCached.title = cloudRecipe.title
                existingCached.headerNotes = cloudRecipe.headerNotes
                existingCached.yield = cloudRecipe.yield
                existingCached.ingredientSections = cloudRecipe.ingredientSections
                existingCached.instructionSections = cloudRecipe.instructionSections
                existingCached.notes = cloudRecipe.notes
                existingCached.reference = cloudRecipe.reference
                existingCached.imageName = cloudRecipe.imageName
                existingCached.additionalImageNames = cloudRecipe.additionalImageNames
                existingCached.sharedByUserName = cloudRecipe.sharedByUserName
                existingCached.cachedDate = Date()
                updatedCount += 1
                logInfo("📖   Updated cached recipe: '\(cloudRecipe.title)'", category: "sharing")
            } else {
                // Create new cached recipe
                let newCached = CachedSharedRecipe(from: cloudRecipe)
                modelContext.insert(newCached)
                addedCount += 1
                logInfo("📖   Cached new recipe: '\(cloudRecipe.title)' by \(cloudRecipe.sharedByUserName ?? "Unknown")", category: "sharing")
            }
        }
        
        // Clean up cached recipes that are no longer available or old
        var removedCount = 0
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        for cached in existingCached {
            let shouldRemove = !currentCloudRecipeIDs.contains(cached.id) || cached.lastAccessedDate < thirtyDaysAgo
            
            if shouldRemove {
                modelContext.delete(cached)
                removedCount += 1
                logInfo("📖   Removed cached recipe: '\(cached.title)'", category: "sharing")
            }
        }
        
        try modelContext.save()
        
        logInfo("✅ SYNC COMPLETE: Community recipes cached for viewing", category: "sharing")
        logInfo("   - Added: \(addedCount) recipes", category: "sharing")
        logInfo("   - Updated: \(updatedCount) recipes", category: "sharing")
        logInfo("   - Removed: \(removedCount) recipes", category: "sharing")
    }
    
    /// Update last accessed date for a cached recipe (prevents auto-cleanup)
    func markCachedRecipeAsAccessed(_ recipeID: UUID, modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<CachedSharedRecipe>(
            predicate: #Predicate<CachedSharedRecipe> { $0.id == recipeID }
        )
        
        if let cached = try modelContext.fetch(descriptor).first {
            cached.lastAccessedDate = Date()
            try modelContext.save()
            logInfo("📖 Marked cached recipe as accessed: '\(cached.title)'", category: "sharing")
        }
    }
    
    /// Convert a cached recipe to permanent import
    func importCachedRecipe(_ cachedRecipe: CachedSharedRecipe, modelContext: ModelContext) throws {
        // Create RecipeX directly from cached data
        let encoder = JSONEncoder()
        
        let recipe = RecipeX(
            id: UUID(), // New ID - independent copy
            title: cachedRecipe.title,
            headerNotes: cachedRecipe.headerNotes,
            recipeYield: cachedRecipe.yield,
            reference: cachedRecipe.reference,
            ingredientSectionsData: try? encoder.encode(cachedRecipe.ingredientSections),
            instructionSectionsData: try? encoder.encode(cachedRecipe.instructionSections),
            notesData: try? encoder.encode(cachedRecipe.notes),
            imageName: cachedRecipe.imageName,
            additionalImageNames: cachedRecipe.additionalImageNames
        )
        
        modelContext.insert(recipe)
        try modelContext.save()
        
        logInfo("Imported cached recipe to permanent collection: \(cachedRecipe.title)", category: "sharing")
    }
    
    /// Clean up old cached recipes (not accessed in 30 days)
    func cleanupOldCachedRecipes(modelContext: ModelContext) throws {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<CachedSharedRecipe>(
            predicate: #Predicate<CachedSharedRecipe> { recipe in
                recipe.lastAccessedDate < thirtyDaysAgo
            }
        )
        
        let oldRecipes = try modelContext.fetch(descriptor)
        
        for recipe in oldRecipes {
            modelContext.delete(recipe)
        }
        
        try modelContext.save()
        
        logInfo("🧹 Cleaned up \(oldRecipes.count) old cached recipes", category: "sharing")
    }
    
    // MARK: - Community Books Sync
    
    /// Sync community recipe books from CloudKit to local SwiftData
    /// This allows shared books to appear in the Books view's "Shared" tab
    /// Phase 4: Enhanced with recipe previews and thumbnail downloads
    func syncCommunityBooksToLocal(modelContext: ModelContext) async throws {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        logInfo("📚 SYNC: Starting enhanced community books sync to local SwiftData...", category: "sharing")
        
        // Step 1: Fetch all CloudKit records (including assets)
        logInfo("📚 Step 1: Fetching CloudKit records with assets...", category: "sharing")
        let allCloudKitRecords = try await fetchAllCloudKitRecords(type: CloudKitRecordType.sharedRecipeBook)
        
        // Filter to exclude current user's books
        let communityRecords = allCloudKitRecords.filter { record in
            guard let sharedBy = record["sharedBy"] as? String else { return false }
            return sharedBy != currentUserID
        }
        
        logInfo("📚 Found \(communityRecords.count) community book records in CloudKit", category: "sharing")
        
        // Fetch all existing SharedRecipeBook records that are shared by others
        let existingSharedBooks = try modelContext.fetch(
            FetchDescriptor<SharedRecipeBook>(
                predicate: #Predicate<SharedRecipeBook> { book in
                    book.sharedByUserID != nil && book.isActive == true
                }
            )
        )
        
        // Fetch all existing RecipeBook records
        let allRecipeBooks = try modelContext.fetch(FetchDescriptor<Book>())
        
        // Fetch all existing CloudKitRecipePreview records
        let allPreviews = try modelContext.fetch(FetchDescriptor<CloudKitRecipePreview>())
        
        // Create dictionaries for quick lookup
        var existingSharedBooksByID = [UUID: SharedRecipeBook]()
        var existingRecipeBooksByID = [UUID: Book]()
        var existingPreviewsByBookID = [UUID: [CloudKitRecipePreview]]()
        
        for book in existingSharedBooks {
            if let bookID = book.bookID {
                existingSharedBooksByID[bookID] = book
            }
        }
        
        for book in allRecipeBooks {
            existingRecipeBooksByID[book.id!] = book
        }
        
        for preview in allPreviews {
            if let bookID = preview.bookID {
                existingPreviewsByBookID[bookID, default: []].append(preview)
            }
        }
        
        logInfo("📚 SYNC: Found \(existingSharedBooks.count) existing community book tracking records", category: "sharing")
        logInfo("📚 SYNC: Found \(allRecipeBooks.count) total RecipeBook entries", category: "sharing")
        logInfo("📚 SYNC: Found \(allPreviews.count) existing recipe previews", category: "sharing")
        
        // Track which CloudKit books we've seen (to identify books to remove)
        var cloudKitBookIDs = Set<UUID>()
        
        var addedCount = 0
        var updatedCount = 0
        var previewsCreated = 0
        var thumbnailsDownloaded = 0
        
        // Step 2-6: Process each CloudKit book record
        for record in communityRecords {
            // Parse book data
            guard let bookData = record["bookData"] as? String,
                  let jsonData = bookData.data(using: .utf8),
                  let cloudBook = try? JSONDecoder().decode(CloudKitRecipeBook.self, from: jsonData) else {
                logWarning("📚 Skipping invalid book record: \(record.recordID.recordName)", category: "sharing")
                continue
            }
            
            cloudKitBookIDs.insert(cloudBook.id)
            let cloudRecordID = record.recordID.recordName
            
            logInfo("📚 Processing book: '\(cloudBook.name)' (\(cloudBook.recipeIDs.count) recipes)", category: "sharing")
            
            // Step 2: Download cover image
            if let coverImageAsset = record["coverImage"] as? CKAsset,
               let coverImageURL = coverImageAsset.fileURL,
               let coverImageData = try? Data(contentsOf: coverImageURL) {
                // Save cover image to local storage
                let coverImageName = "shared_cover_\(cloudBook.id).jpg"
                try? saveImageToDocuments(data: coverImageData, filename: coverImageName)
                logInfo("📚   ✅ Downloaded cover image: \(coverImageName)", category: "sharing")
            }
            
            // Step 3: Parse recipe previews JSON
            var recipePreviews: [RecipePreviewData] = []
            if let previewsJSON = record["recipePreviews"] as? String,
               let previewsData = previewsJSON.data(using: .utf8),
               let previews = try? JSONDecoder().decode([RecipePreviewData].self, from: previewsData) {
                recipePreviews = previews
                logInfo("📚   ✅ Parsed \(previews.count) recipe previews", category: "sharing")
            } else {
                logWarning("📚   ⚠️ No recipe previews found in record", category: "sharing")
            }
            
            // Check if RecipeBook entity exists
            let book: Book
            if let existingRecipeBook = existingRecipeBooksByID[cloudBook.id] {
                book = existingRecipeBook
                
                // Update RecipeBook properties if needed
                var needsUpdate = false
                if book.name != cloudBook.name {
                    book.name = cloudBook.name
                    needsUpdate = true
                }
                if book.bookDescription != cloudBook.bookDescription {
                    book.bookDescription = cloudBook.bookDescription
                    needsUpdate = true
                }
                if book.color != cloudBook.color {
                    book.color = cloudBook.color
                    needsUpdate = true
                }
                
                // Ensure owner information is set for shared books
                if book.ownerUserID != cloudBook.sharedByUserID {
                    book.ownerUserID = cloudBook.sharedByUserID
                    needsUpdate = true
                }
                if book.ownerDisplayName != cloudBook.sharedByUserName {
                    book.ownerDisplayName = cloudBook.sharedByUserName
                    needsUpdate = true
                }
                
                if needsUpdate {
                    book.dateModified = Date()
                    updatedCount += 1
                    logInfo("📚   Updated RecipeBook: '\(cloudBook.name)'", category: "sharing")
                }
            } else {
                // Create new Book entity
                let coverImageName = "shared_cover_\(cloudBook.id).jpg"
                book = Book(
                    id: cloudBook.id,
                    name: cloudBook.name,
                    bookDescription: cloudBook.bookDescription,
                    coverImageName: coverImageName,
                    color: cloudBook.color, recipeIDs: cloudBook.recipeIDs, dateCreated: cloudBook.sharedDate,
                    dateModified: cloudBook.sharedDate
                )
                
                // Set owner information for shared books
                book.ownerUserID = cloudBook.sharedByUserID
                book.ownerDisplayName = cloudBook.sharedByUserName
                
                modelContext.insert(book)
                addedCount += 1
                logInfo("📚   Created RecipeBook: '\(cloudBook.name)' by \(cloudBook.sharedByUserName ?? "Unknown")", category: "sharing")
            }
            
            // Check if SharedRecipeBook tracking entry exists
            if let existingSharedBook = existingSharedBooksByID[cloudBook.id] {
                // Update existing tracking entry if needed
                var needsUpdate = false
                
                if existingSharedBook.bookName != cloudBook.name {
                    existingSharedBook.bookName = cloudBook.name
                    needsUpdate = true
                }
                
                if existingSharedBook.bookDescription != cloudBook.bookDescription {
                    existingSharedBook.bookDescription = cloudBook.bookDescription
                    needsUpdate = true
                }
                
                if existingSharedBook.sharedByUserName != cloudBook.sharedByUserName {
                    existingSharedBook.sharedByUserName = cloudBook.sharedByUserName
                    needsUpdate = true
                }
                
                if existingSharedBook.cloudRecordID != cloudRecordID {
                    existingSharedBook.cloudRecordID = cloudRecordID
                    needsUpdate = true
                }
                
                if needsUpdate {
                    logInfo("📚   Updated SharedRecipeBook tracking: '\(cloudBook.name)'", category: "sharing")
                }
            } else {
                // Create new SharedRecipeBook tracking entry
                let newSharedBook = SharedRecipeBook(
                    bookID: cloudBook.id,
                    cloudRecordID: cloudRecordID,
                    sharedByUserID: cloudBook.sharedByUserID,
                    sharedByUserName: cloudBook.sharedByUserName,
                    sharedDate: cloudBook.sharedDate,
                    bookName: cloudBook.name,
                    bookDescription: cloudBook.bookDescription,
                    coverImageName: cloudBook.coverImageName
                )
                
                modelContext.insert(newSharedBook)
                logInfo("📚   Created SharedRecipeBook tracking: '\(cloudBook.name)' by \(cloudBook.sharedByUserName ?? "Unknown")", category: "sharing")
            }
            
            // Step 4-5: Decode thumbnails from base64 and create CloudKitRecipePreview entries
            if !recipePreviews.isEmpty {
                // Delete old previews for this book
                if let oldPreviews = existingPreviewsByBookID[cloudBook.id] {
                    for oldPreview in oldPreviews {
                        modelContext.delete(oldPreview)
                    }
                }
                
                // Create new previews
                for previewData in recipePreviews {
                    // Step 4: Decode thumbnail from base64
                    var thumbnailData: Data?
                    if let base64String = previewData.thumbnailBase64,
                       let data = Data(base64Encoded: base64String) {
                        thumbnailData = data
                        thumbnailsDownloaded += 1
                        logInfo("📚     ✅ Decoded thumbnail: '\(previewData.title)'", category: "sharing")
                    } else {
                        logInfo("📚     ⚪️ No thumbnail for '\(previewData.title)'", category: "sharing")
                    }
                    
                    // Step 5: Create CloudKitRecipePreview entry
                    let preview = CloudKitRecipePreview(
                        id: previewData.id,
                        title: previewData.title,
                        headerNotes: previewData.headerNotes,
                        imageName: previewData.imageName,
                        imageData: thumbnailData,
                        sharedByUserID: cloudBook.sharedByUserID,
                        sharedByUserName: cloudBook.sharedByUserName,
                        recipeYield: previewData.recipeYield,
                        bookID: cloudBook.id,
                        cloudRecordID: previewData.cloudRecordID
                    )
                    
                    modelContext.insert(preview)
                    previewsCreated += 1
                }
                
                logInfo("📚   ✅ Created \(recipePreviews.count) recipe previews", category: "sharing")
            }
        }
        
        // Find and remove books that are no longer in CloudKit
        var removedCount = 0
        for existingSharedBook in existingSharedBooks {
            guard let bookID = existingSharedBook.bookID else { continue }
            
            // If this book is not in CloudKit anymore, mark it as inactive and delete the RecipeBook
            if !cloudKitBookIDs.contains(bookID) {
                // Only remove books shared by others, not the current user's own shared books
                if existingSharedBook.sharedByUserID != currentUserID {
                    logInfo("📚   Removing book (no longer shared): '\(existingSharedBook.bookName)'", category: "sharing")
                    
                    // Step 1: Delete associated recipe previews
                    if let previews = existingPreviewsByBookID[bookID] {
                        logInfo("📚     Deleting \(previews.count) recipe previews", category: "sharing")
                        for preview in previews {
                            modelContext.delete(preview)
                        }
                    }
                    
                    // Step 2: Delete the RecipeBook entity and its cover image
                    if let recipeBook = existingRecipeBooksByID[bookID] {
                        // Try to delete cover image file if it exists
                        if let coverImageName = recipeBook.coverImageName {
                            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            let fileURL = documentsPath.appendingPathComponent(coverImageName)
                            do {
                                try FileManager.default.removeItem(at: fileURL)
                                logInfo("📚     Deleted cover image: \(coverImageName)", category: "sharing")
                            } catch {
                                // File might not exist, which is fine
                                logDebug("📚     Cover image file not found (already deleted): \(error)", category: "sharing")
                            }
                        }
                        
                        // Note: We intentionally DO NOT delete the Recipe entities themselves
                        // because they might be used in other books or standalone.
                        // Only delete the book container.
                        logInfo("📚     Deleting RecipeBook entity", category: "sharing")
                        modelContext.delete(recipeBook)
                    } else {
                        // RecipeBook might have already been deleted, but tracking remains
                        logWarning("📚     RecipeBook entity not found (might have been already deleted)", category: "sharing")
                    }
                    
                    // Step 3: Delete the tracking entry completely (not just marking inactive)
                    // This ensures the book disappears from ALL tabs, including "All"
                    logInfo("📚     Deleting SharedRecipeBook tracking entry", category: "sharing")
                    modelContext.delete(existingSharedBook)
                    
                    removedCount += 1
                    logInfo("📚   ✅ Removed book '\(existingSharedBook.bookName)' and cleaned up associated data", category: "sharing")
                }
            }
        }
        
        // Save changes with error handling
        do {
            try modelContext.save()
            logInfo("✅ SYNC COMPLETE: Enhanced community books sync finished", category: "sharing")
        } catch {
            logError("❌ Failed to save sync changes: \(error)", category: "sharing")
            // Try to rollback to prevent partial state
            modelContext.rollback()
            throw error
        }
        
        logInfo("   - Added: \(addedCount) books", category: "sharing")
        logInfo("   - Updated: \(updatedCount) books", category: "sharing")
        logInfo("   - Removed: \(removedCount) books", category: "sharing")
        logInfo("   - Recipe previews created: \(previewsCreated)", category: "sharing")
        logInfo("   - Thumbnails decoded: \(thumbnailsDownloaded)", category: "sharing")
    }
    
    /// Helper: Save image data to Documents directory
    private func saveImageToDocuments(data: Data, filename: String) throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        try data.write(to: fileURL)
    }
    
    /// Helper: Create a small thumbnail from an image
    /// Returns JPEG data resized to maxSize (width/height), compressed to keep file size small
    private func createThumbnail(for imageName: String, maxSize: CGFloat = 200) -> Data? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageURL = documentsPath.appendingPathComponent(imageName)
        
        guard FileManager.default.fileExists(atPath: imageURL.path),
              let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        // Calculate new size maintaining aspect ratio
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Compress to JPEG with quality 0.6 (good balance of size vs quality)
        return resizedImage?.jpegData(compressionQuality: 0.6)
    }
    
    /// Remove orphaned recipes from CloudKit (recipes with invalid/missing sharedByUserID)
    func removeOrphanedRecipes() async throws {
        logInfo("🧹 ORPHAN CLEANUP: Starting orphan detection...", category: "sharing")
        
        guard currentUserID != nil else {
            throw SharingError.notAuthenticated
        }
        
        // Fetch all CloudKit records
        let allRecords = try await fetchAllCloudKitRecords(type: CloudKitRecordType.sharedRecipe)
        logInfo("🧹 Found \(allRecords.count) total records in CloudKit", category: "sharing")
        
        var orphanedRecords: [CKRecord.ID] = []
        var validUserIDs = Set<String>()
        
        // Identify orphans
        for record in allRecords {
            guard let sharedBy = record["sharedBy"] as? String,
                  !sharedBy.isEmpty else {
                // No valid sharedByUserID - this is an orphan
                orphanedRecords.append(record.recordID)
                logWarning("🧹 Found orphan (no sharedBy): \(record.recordID.recordName)", category: "sharing")
                continue
            }
            
            // Track valid user IDs
            validUserIDs.insert(sharedBy)
        }
        
        logInfo("🧹 Found \(orphanedRecords.count) orphaned records", category: "sharing")
        logInfo("🧹 Found \(validUserIDs.count) distinct valid users", category: "sharing")
        
        // Delete orphans
        if !orphanedRecords.isEmpty {
            logInfo("🧹 Deleting \(orphanedRecords.count) orphaned records...", category: "sharing")
            
            let batches = stride(from: 0, to: orphanedRecords.count, by: 100).map {
                Array(orphanedRecords[$0..<min($0 + 100, orphanedRecords.count)])
            }
            
            for (index, batch) in batches.enumerated() {
                do {
                    _ = try await publicDatabase.modifyRecords(saving: [], deleting: batch)
                    logInfo("🧹 Deleted orphan batch \(index + 1)/\(batches.count) (\(batch.count) records)", category: "sharing")
                } catch {
                    logError("🧹 Failed to delete orphan batch \(index + 1): \(error)", category: "sharing")
                }
            }
            
            logInfo("✅ Orphan cleanup complete: Removed \(orphanedRecords.count) orphans", category: "sharing")
        } else {
            logInfo("✅ No orphans found - CloudKit is clean!", category: "sharing")
        }
    }
    
    /// Clean up all stale shared content and re-sync from CloudKit
    /// WARNING: This removes ALL local sharing tracking and rebuilds from CloudKit truth
    func cleanupAndResyncSharing(modelContext: ModelContext) async throws {
        logInfo("🧹 CLEANUP: Starting comprehensive sharing cleanup...", category: "sharing")
        
        guard let currentUserID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        // Step 0: Check for duplicate local Recipe records first
        logInfo("🧹 Step 0: Checking for duplicate local Recipe records...", category: "sharing")
        let allLocalRecipes = try modelContext.fetch(FetchDescriptor<RecipeX>())
        let uniqueRecipeIDs = Set(allLocalRecipes.compactMap { $0.id })
        let duplicateCount = allLocalRecipes.count - uniqueRecipeIDs.count
        
        if duplicateCount > 0 {
            logWarning("🧹 Found \(duplicateCount) duplicate Recipe records in local database!", category: "sharing")
            logWarning("🧹 ⚠️ IMPORTANT: You have \(allLocalRecipes.count) recipes but only \(uniqueRecipeIDs.count) unique IDs", category: "sharing")
            logWarning("🧹 Please use Settings → Database Recovery to clean up local duplicates first", category: "sharing")
            throw SharingError.invalidData
        }
        
        logInfo("🧹 Local database clean: \(allLocalRecipes.count) recipes, all unique ✅", category: "sharing")
        
        // Step 1: Delete ALL local SharedRecipe tracking records
        logInfo("🧹 Step 1: Removing all local SharedRecipe tracking...", category: "sharing")
        let allSharedRecipes = try modelContext.fetch(FetchDescriptor<SharedRecipe>())
        let allSharedBooks = try modelContext.fetch(FetchDescriptor<SharedRecipeBook>())
        
        for recipe in allSharedRecipes {
            modelContext.delete(recipe)
        }
        for book in allSharedBooks {
            modelContext.delete(book)
        }
        try modelContext.save()
        logInfo("🧹 Deleted \(allSharedRecipes.count) SharedRecipe and \(allSharedBooks.count) SharedRecipeBook tracking records", category: "sharing")
        
        // Step 2: Fetch ALL records from CloudKit public database
        logInfo("🧹 Step 2: Fetching all CloudKit public database records...", category: "sharing")
        let allCloudRecipes = try await fetchAllCloudKitRecords(type: CloudKitRecordType.sharedRecipe)
        logInfo("🧹 Found \(allCloudRecipes.count) total records in CloudKit public database", category: "sharing")
        
        // Step 3: Find and delete duplicates + records not owned by current user
        logInfo("🧹 Step 3: Identifying stale and duplicate records...", category: "sharing")
        
        // Group by recipe ID to find duplicates
        var recordsToKeep: [CKRecord.ID] = []
        var recordsToDelete: [CKRecord.ID] = []
        var seenRecipeIDs: [UUID: CKRecord] = [:]
        
        for record in allCloudRecipes {
            guard let recipeData = record["recipeData"] as? String,
                  let jsonData = recipeData.data(using: .utf8),
                  let cloudRecipe = try? JSONDecoder().decode(CloudKitRecipe.self, from: jsonData) else {
                // Invalid record - delete it
                recordsToDelete.append(record.recordID)
                logWarning("🧹 Marking invalid record for deletion: \(record.recordID.recordName)", category: "sharing")
                continue
            }
            
            let sharedBy = record["sharedBy"] as? String ?? ""
            let isMyRecord = sharedBy == currentUserID
            
            // Check if we've seen this recipe ID before
            if let existingRecord = seenRecipeIDs[cloudRecipe.id] {
                // Duplicate found!
                let existingSharedBy = existingRecord["sharedBy"] as? String ?? ""
                
                if isMyRecord && existingSharedBy != currentUserID {
                    // Keep mine, delete the other
                    recordsToDelete.append(existingRecord.recordID)
                    seenRecipeIDs[cloudRecipe.id] = record
                    recordsToKeep.append(record.recordID)
                    logInfo("🧹 Duplicate: Keeping my record, deleting other for recipe \(cloudRecipe.title)", category: "sharing")
                } else if existingSharedBy == currentUserID && !isMyRecord {
                    // Keep existing (mine), delete this one
                    recordsToDelete.append(record.recordID)
                    logInfo("🧹 Duplicate: Keeping existing record, deleting duplicate for recipe \(cloudRecipe.title)", category: "sharing")
                } else {
                    // Both from same user - keep newer one
                    let existingDate = existingRecord["sharedDate"] as? Date ?? Date.distantPast
                    let currentDate = record["sharedDate"] as? Date ?? Date.distantPast
                    
                    if currentDate > existingDate {
                        recordsToDelete.append(existingRecord.recordID)
                        seenRecipeIDs[cloudRecipe.id] = record
                        recordsToKeep.append(record.recordID)
                    } else {
                        recordsToDelete.append(record.recordID)
                    }
                    logInfo("🧹 Duplicate: Keeping newer record for recipe \(cloudRecipe.title)", category: "sharing")
                }
            } else {
                // First time seeing this recipe ID
                seenRecipeIDs[cloudRecipe.id] = record
                recordsToKeep.append(record.recordID)
            }
        }
        
        // Step 4: Delete stale/duplicate records from CloudKit
        logInfo("🧹 Step 4: Deleting \(recordsToDelete.count) stale/duplicate records from CloudKit...", category: "sharing")
        
        if !recordsToDelete.isEmpty {
            // Delete in batches of 100
            let batches = stride(from: 0, to: recordsToDelete.count, by: 100).map {
                Array(recordsToDelete[$0..<min($0 + 100, recordsToDelete.count)])
            }
            
            for (index, batch) in batches.enumerated() {
                do {
                    _ = try await publicDatabase.modifyRecords(saving: [], deleting: batch)
                    logInfo("🧹 Deleted batch \(index + 1)/\(batches.count) (\(batch.count) records)", category: "sharing")
                } catch {
                    logError("🧹 Failed to delete batch \(index + 1): \(error)", category: "sharing")
                }
            }
        }
        
        // Step 5: Rebuild local tracking from clean CloudKit data
        logInfo("🧹 Step 5: Rebuilding local SharedRecipe tracking from \(seenRecipeIDs.count) clean records...", category: "sharing")
        
        for (_, record) in seenRecipeIDs {
            guard let recipeData = record["recipeData"] as? String,
                  let jsonData = recipeData.data(using: .utf8),
                  let cloudRecipe = try? JSONDecoder().decode(CloudKitRecipe.self, from: jsonData) else {
                continue
            }
            
            let sharedBy = record["sharedBy"] as? String ?? ""
            let isMyRecord = sharedBy == currentUserID
            
            if isMyRecord {
                // Track my own shared recipe
                let sharedRecipe = SharedRecipe(
                    recipeID: cloudRecipe.id,
                    cloudRecordID: record.recordID.recordName,
                    sharedByUserID: currentUserID,
                    sharedByUserName: currentUserName,
                    sharedDate: record["sharedDate"] as? Date ?? Date(),
                    recipeTitle: cloudRecipe.title,
                    recipeImageName: cloudRecipe.imageName
                )
                modelContext.insert(sharedRecipe)
            }
        }
        
        try modelContext.save()
        
        logInfo("✅ CLEANUP COMPLETE: Removed \(recordsToDelete.count) duplicates, kept \(seenRecipeIDs.count) clean records", category: "sharing")
        logInfo("✅ You should now see accurate counts: Mine=\(seenRecipeIDs.values.filter { ($0["sharedBy"] as? String) == currentUserID }.count), Shared=\(seenRecipeIDs.count)", category: "sharing")
    }
    
    /// Fetch all CloudKit records of a given type (with pagination)
    /// 
    /// ⚠️ IMPORTANT: CloudKit Schema Configuration Required
    /// If you get "Field 'recordName' is not marked queryable" errors:
    /// 1. Go to CloudKit Dashboard: https://icloud.developer.apple.com/dashboard
    /// 2. Select your container: iCloud.com.headydiscy.reczipes
    /// 3. Go to Schema → Indexes
    /// 4. For each Record Type (SharedRecipe, SharedRecipeBook):
    ///    - Add QUERYABLE index on "recordName" field
    ///    - Add SORTABLE index on "sharedDate" field  
    ///    - Deploy to Production
    private func fetchAllCloudKitRecords(type: String) async throws -> [CKRecord] {
        logInfo("📦 Fetching all '\(type)' records from CloudKit Public Database...", category: "sharing")
        
        var allRecords: [CKRecord] = []
        
        // Create the most basic query - no sort, no filters
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: type, predicate: predicate)
        
        // Fetch initial batch
        var currentCursor: CKQueryOperation.Cursor?
        let batchSize = 100
        var batchNumber = 1
        
        do {
            // Initial query
            let results = try await publicDatabase.records(matching: query, desiredKeys: nil, resultsLimit: batchSize)
            
            // Process initial batch
            for (_, result) in results.matchResults {
                switch result {
                case .success(let record):
                    allRecords.append(record)
                case .failure(let error):
                    logError("❌ Error fetching record: \(error)", category: "sharing")
                }
            }
            
            currentCursor = results.queryCursor
            logInfo("📦 Batch #\(batchNumber): Fetched \(results.matchResults.count) records, total: \(allRecords.count)", category: "sharing")
            
            // Continue with cursor if available
            while let cursor = currentCursor {
                batchNumber += 1
                
                let nextResults = try await publicDatabase.records(
                    continuingMatchFrom: cursor,
                    desiredKeys: nil,
                    resultsLimit: batchSize
                )
                
                // Process batch
                for (_, result) in nextResults.matchResults {
                    switch result {
                    case .success(let record):
                        allRecords.append(record)
                    case .failure(let error):
                        logError("❌ Error fetching record: \(error)", category: "sharing")
                    }
                }
                
                currentCursor = nextResults.queryCursor
                logInfo("📦 Batch #\(batchNumber): Fetched \(nextResults.matchResults.count) records, total: \(allRecords.count)", category: "sharing")
                
                // Safety: prevent infinite loops
                if batchNumber > 100 {
                    logWarning("📦 Reached maximum batch limit (100), stopping pagination", category: "sharing")
                    break
                }
            }
            
            // Sort in memory by date
            let sorted = allRecords.sorted { r1, r2 in
                let date1 = r1["sharedDate"] as? Date ?? .distantPast
                let date2 = r2["sharedDate"] as? Date ?? .distantPast
                return date1 > date2
            }
            
            logInfo("✅ Fetched all \(sorted.count) '\(type)' records in \(batchNumber) batches", category: "sharing")
            return sorted
            
        } catch let error as CKError {
            logError("❌ CloudKit query failed for '\(type)': \(error)", category: "sharing")
            
            // Check if it's the "recordName not queryable" error
            if error.code == .invalidArguments {
                let errorMessage = error.localizedDescription
                if errorMessage.contains("recordName") || errorMessage.contains("queryable") {
                    throw SharingError.cloudKitUnavailable(
                        message: "CloudKit schema not configured. Please add queryable indexes in CloudKit Dashboard for record type '\(type)'. See CloudKitSharingService.swift for instructions."
                    )
                }
            }
            
            throw error
        }
    }
    
    /// Import a shared recipe into the user's local collection
    func importSharedRecipe(_ cloudRecipe: CloudKitRecipe, modelContext: ModelContext) async throws {
        // Create RecipeX directly from CloudKitRecipe
        let encoder = JSONEncoder()
        
        let recipe = RecipeX(
            id: UUID(), // Generate new ID (don't conflict with original)
            title: "\(cloudRecipe.title) (from \(cloudRecipe.sharedByUserName ?? "community"))",
            headerNotes: cloudRecipe.headerNotes,
            recipeYield: cloudRecipe.yield,
            reference: cloudRecipe.reference,
            ingredientSectionsData: try? encoder.encode(cloudRecipe.ingredientSections),
            instructionSectionsData: try? encoder.encode(cloudRecipe.instructionSections),
            notesData: try? encoder.encode(cloudRecipe.notes),
            imageName: cloudRecipe.imageName,
            additionalImageNames: cloudRecipe.additionalImageNames
        )
 
        modelContext.insert(recipe)
        try modelContext.save()
        
        logInfo("Imported shared recipe: \(cloudRecipe.title)", category: "sharing")
    }
}
