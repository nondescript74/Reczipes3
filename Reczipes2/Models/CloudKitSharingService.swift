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

/// Service for sharing recipes and recipe books via CloudKit Public Database
@MainActor
class CloudKitSharingService: ObservableObject {
    static let shared = CloudKitSharingService()
    
    private let container: CKContainer
    private let publicDatabase: CKDatabase
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
            // For privacy reasons, we'll use a user-configured display name instead
            // You can retrieve this from UserDefaults or your app's settings
            currentUserName = UserDefaults.standard.string(forKey: "userDisplayName")
            
            logInfo("User ID: \(currentUserID ?? "unknown"), Name: \(currentUserName ?? "not set")", category: "sharing")
        } catch {
            logError("Failed to fetch user identity: \(error)", category: "sharing")
        }
    }
    
    
    // MARK: - Share Recipe
    
    func shareRecipe(_ recipe: RecipeModel, modelContext: ModelContext) async throws -> String {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        guard let userID = currentUserID else {
            throw SharingError.notAuthenticated
        }
        
        // Check if this recipe is already shared and active
        let recipeIDToFind = recipe.id
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
                logInfo("Recipe '\(recipe.title)' is already shared (verified in CloudKit)", category: "sharing")
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
               cloudRecipe.id == recipe.id {
                // Found duplicate - delete it
                _ = try? await publicDatabase.deleteRecord(withID: record.recordID)
                logInfo("Deleted duplicate CloudKit record for recipe '\(recipe.title)'", category: "sharing")
            }
        }
        
        // Create CloudKit record
        let record = CKRecord(recordType: CloudKitRecordType.sharedRecipe)
        
        // Convert recipe to CloudKit-friendly format
        let cloudRecipe = CloudKitRecipe(
            id: recipe.id,
            title: recipe.title,
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
        record["title"] = recipe.title as CKRecordValue
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
            recipeID: recipe.id,
            cloudRecordID: savedRecord.recordID.recordName,
            sharedByUserID: userID,
            sharedByUserName: currentUserName,
            recipeTitle: recipe.title,
            recipeImageName: recipe.imageName
        )
        
        modelContext.insert(sharedRecipe)
        try modelContext.save()
        
        logInfo("Shared recipe: \(recipe.title)", category: "sharing")
        logInfo("Community share successful", category: "analytics")
        
        return savedRecord.recordID.recordName
    }
    
    // MARK: - Share Recipe Book
    
    func shareRecipeBook(_ book: RecipeBook, modelContext: ModelContext) async throws -> String {
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
            logInfo("Recipe book '\(book.name)' is already shared", category: "sharing")
            return existingShared.cloudRecordID ?? "Already shared"
        }
        
        // Create CloudKit record
        let record = CKRecord(recordType: CloudKitRecordType.sharedRecipeBook)
        
        // Convert book to CloudKit-friendly format
        let cloudBook = CloudKitRecipeBook(
            id: book.id,
            name: book.name,
            bookDescription: book.bookDescription,
            coverImageName: book.coverImageName,
            recipeIDs: book.recipeIDs,
            color: book.color,
            sharedByUserID: userID,
            sharedByUserName: currentUserName,
            sharedDate: Date()
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(cloudBook)
        
        record["bookData"] = String(data: jsonData, encoding: .utf8)
        record["name"] = book.name as CKRecordValue
        record["sharedBy"] = userID as CKRecordValue
        record["sharedByName"] = (currentUserName ?? "Anonymous") as CKRecordValue
        record["sharedDate"] = Date() as CKRecordValue
        
        // Upload cover image if exists
        if let coverImage = book.coverImageName {
            try await uploadImage(named: coverImage, to: record, fieldName: "coverImage")
        }
        
        // Save to public database
        let savedRecord = try await publicDatabase.save(record)
        
        // Track locally
        let sharedBook = SharedRecipeBook(
            bookID: book.id,
            cloudRecordID: savedRecord.recordID.recordName,
            sharedByUserID: userID,
            sharedByUserName: currentUserName,
            bookName: book.name,
            bookDescription: book.bookDescription,
            coverImageName: book.coverImageName
        )
        
        modelContext.insert(sharedBook)
        try modelContext.save()
        
        logInfo("Shared recipe book: \(book.name)", category: "sharing")
        logInfo("Community share successful", category: "analytics")
        
        return savedRecord.recordID.recordName
    }
    
    // MARK: - Share Multiple Items
    
    func shareMultipleRecipes(_ recipes: [RecipeModel], modelContext: ModelContext) async -> SharingResult {
        var successful = 0
        var failed = 0
        
        for recipe in recipes {
            do {
                _ = try await shareRecipe(recipe, modelContext: modelContext)
                successful += 1
            } catch {
                logError("Failed to share recipe '\(recipe.title)': \(error)", category: "sharing")
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
    
    func shareMultipleBooks(_ books: [RecipeBook], modelContext: ModelContext) async -> SharingResult {
        var successful = 0
        var failed = 0
        
        for book in books {
            do {
                _ = try await shareRecipeBook(book, modelContext: modelContext)
                successful += 1
            } catch {
                logError("Failed to share book '\(book.name)': \(error)", category: "sharing")
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
    
    func fetchSharedRecipes(limit: Int = 400) async throws -> [CloudKitRecipe] {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        logInfo("Starting fetchSharedRecipes with limit: \(limit)", category: "sharing")
        
        let query = CKQuery(recordType: CloudKitRecordType.sharedRecipe, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "sharedDate", ascending: false)]
        
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
        
        logInfo("✅ Fetched \(allRecipes.count) shared recipes total (using cursor pagination)", category: "sharing")
        return allRecipes
    }
    
    func fetchSharedRecipeBooks(limit: Int = 400) async throws -> [CloudKitRecipeBook] {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        let query = CKQuery(recordType: CloudKitRecordType.sharedRecipeBook, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "sharedDate", ascending: false)]
        
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
        
        let recordID = CKRecord.ID(recordName: cloudRecordID)
        try await publicDatabase.deleteRecord(withID: recordID)
        
        // Remove from local tracking
        let recordIDToFind = cloudRecordID
        let descriptor = FetchDescriptor<SharedRecipeBook>(
            predicate: #Predicate<SharedRecipeBook> { sharedBook in
                sharedBook.cloudRecordID == recordIDToFind
            }
        )
        
        if let sharedBook = try modelContext.fetch(descriptor).first {
            modelContext.delete(sharedBook)
            try modelContext.save()
        }
        
        logInfo("Unshared recipe book with ID: \(cloudRecordID)", category: "sharing")
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
    
    /// Diagnostic function to check CloudKit public database status
    func diagnoseSharedRecipes() async {
        logInfo("🔍 DIAGNOSTIC: Starting shared recipes check...", category: "sharing")
        
        do {
            let recipes = try await fetchSharedRecipes()
            logInfo("🔍 DIAGNOSTIC: Successfully fetched \(recipes.count) recipes from CloudKit", category: "sharing")
            
            // Group by sharer
            let groupedByUser = Dictionary(grouping: recipes) { $0.sharedByUserID }
            for (userID, userRecipes) in groupedByUser {
                let userName = userRecipes.first?.sharedByUserName ?? "Unknown"
                logInfo("🔍 DIAGNOSTIC: User '\(userName)' (\(userID)) shared \(userRecipes.count) recipes", category: "sharing")
            }
            
            // Detect duplicates by recipe ID
            let groupedByRecipeID = Dictionary(grouping: recipes) { $0.id }
            let duplicates = groupedByRecipeID.filter { $0.value.count > 1 }
            if !duplicates.isEmpty {
                logWarning("🔍 DIAGNOSTIC: Found \(duplicates.count) duplicate recipe IDs in CloudKit!", category: "sharing")
                for (recipeID, dupes) in duplicates.prefix(5) {
                    logWarning("  Recipe ID \(recipeID) has \(dupes.count) copies", category: "sharing")
                }
            }
            
            // Show first few recipe titles
            logInfo("🔍 DIAGNOSTIC: First 5 recipe titles:", category: "sharing")
            for (index, recipe) in recipes.prefix(5).enumerated() {
                logInfo("  \(index + 1). \(recipe.title) by \(recipe.sharedByUserName ?? "Unknown")", category: "sharing")
            }
            
        } catch {
            logError("🔍 DIAGNOSTIC: Failed to fetch recipes: \(error)", category: "sharing")
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
        let allLocalRecipes = try modelContext.fetch(FetchDescriptor<Recipe>())
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
    private func fetchAllCloudKitRecords(type: String) async throws -> [CKRecord] {
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "sharedDate", ascending: false)]
        
        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor? = nil
        
        repeat {
            let results: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)
            
            if let cursor = cursor {
                results = try await publicDatabase.records(continuingMatchFrom: cursor, desiredKeys: nil, resultsLimit: 100)
            } else {
                results = try await publicDatabase.records(matching: query, desiredKeys: nil, resultsLimit: 100)
            }
            
            for (_, result) in results.matchResults {
                if case .success(let record) = result {
                    allRecords.append(record)
                }
            }
            
            cursor = results.queryCursor
        } while cursor != nil
        
        return allRecords
    }
    
    /// Import a shared recipe into the user's local collection
    func importSharedRecipe(_ cloudRecipe: CloudKitRecipe, modelContext: ModelContext) async throws {
        // Convert CloudKitRecipe to local RecipeModel
        let recipeModel = RecipeModel(
            id: UUID(), // Generate new ID (don't conflict with original)
            title: "\(cloudRecipe.title) (from \(cloudRecipe.sharedByUserName ?? "community"))",
            headerNotes: cloudRecipe.headerNotes,
            yield: cloudRecipe.yield,
            ingredientSections: cloudRecipe.ingredientSections,
            instructionSections: cloudRecipe.instructionSections,
            notes: cloudRecipe.notes,
            reference: cloudRecipe.reference,
            imageName: cloudRecipe.imageName,
            additionalImageNames: cloudRecipe.additionalImageNames
        )
        
        let recipe = Recipe(from: recipeModel)
 
            modelContext.insert(recipe)
            try modelContext.save()
            logInfo("Imported shared recipe: \(cloudRecipe.title)", category: "sharing")
        
        logInfo("Imported shared recipe: \(cloudRecipe.title)", category: "sharing")
    }
}
