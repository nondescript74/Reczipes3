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
    
    func fetchSharedRecipes(limit: Int = 100) async throws -> [CloudKitRecipe] {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        let query = CKQuery(recordType: CloudKitRecordType.sharedRecipe, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "sharedDate", ascending: false)]
        
        let results = try await publicDatabase.records(matching: query, desiredKeys: nil, resultsLimit: limit)
        
        var recipes: [CloudKitRecipe] = []
        
        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let recipeData = record["recipeData"] as? String,
                   let jsonData = recipeData.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    if let recipe = try? decoder.decode(CloudKitRecipe.self, from: jsonData) {
                        recipes.append(recipe)
                    }
                }
            case .failure(let error):
                logError("Failed to fetch shared recipe: \(error)", category: "sharing")
            }
        }
        
        logInfo("Fetched \(recipes.count) shared recipes", category: "sharing")
        return recipes
    }
    
    func fetchSharedRecipeBooks(limit: Int = 100) async throws -> [CloudKitRecipeBook] {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        let query = CKQuery(recordType: CloudKitRecordType.sharedRecipeBook, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "sharedDate", ascending: false)]
        
        let results = try await publicDatabase.records(matching: query, desiredKeys: nil, resultsLimit: limit)
        
        var books: [CloudKitRecipeBook] = []
        
        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let bookData = record["bookData"] as? String,
                   let jsonData = bookData.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    if let book = try? decoder.decode(CloudKitRecipeBook.self, from: jsonData) {
                        books.append(book)
                    }
                }
            case .failure(let error):
                logError("Failed to fetch shared book: \(error)", category: "sharing")
            }
        }
        
        logInfo("Fetched \(books.count) shared recipe books", category: "sharing")
        return books
    }
    
    // MARK: - Unshare Content
    
    func unshareRecipe(cloudRecordID: String, modelContext: ModelContext) async throws {
        guard isCloudKitAvailable else {
            throw SharingError.cloudKitUnavailable()
        }
        
        let recordID = CKRecord.ID(recordName: cloudRecordID)
        try await publicDatabase.deleteRecord(withID: recordID)
        
        // Remove from local tracking
        let descriptor = FetchDescriptor<SharedRecipe>(
            predicate: #Predicate { $0.cloudRecordID == cloudRecordID }
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
        let descriptor = FetchDescriptor<SharedRecipeBook>(
            predicate: #Predicate { $0.cloudRecordID == cloudRecordID }
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
