//
//  BackgroundProcessingManager.swift
//  Reczipes2
//
//  Created for true background processing support
//

import Foundation
import BackgroundTasks
import UIKit
import SwiftData
import Combine

/// Manager for handling background processing tasks when app is backgrounded
@MainActor
class BackgroundProcessingManager: ObservableObject {
    static let shared = BackgroundProcessingManager()
    
    // Background task identifier - must match Info.plist
    private let backgroundTaskIdentifier = "com.yourapp.reczipes.backgroundExtraction"
    
    // Processing state
    @Published var isBackgroundTaskActive = false
    @Published var backgroundProgress: Double = 0.0
    
    // Background task reference
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // Queue for pending extractions
    private var pendingExtractions: [(imageData: Data, index: Int)] = []
    private var apiKey: String?
    private var modelContext: ModelContext?
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Register background task handler - call from AppDelegate
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleBackgroundProcessing(task: task as! BGProcessingTask)
            }
        }
        
        logInfo("Background task handler registered: \(backgroundTaskIdentifier)", category: "background")
    }
    
    /// Configure with API key and model context
    func configure(apiKey: String, modelContext: ModelContext) {
        self.apiKey = apiKey
        self.modelContext = modelContext
        logInfo("BackgroundProcessingManager configured", category: "background")
    }
    
    // MARK: - Background Task Scheduling
    
    /// Schedule a background processing task
    func scheduleBackgroundExtraction() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false // Allow on battery
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1) // Start ASAP
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logInfo("Background extraction task scheduled", category: "background")
        } catch {
            logError("Failed to schedule background task: \(error)", category: "background")
        }
    }
    
    /// Cancel any scheduled background tasks
    func cancelBackgroundTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
        logInfo("Background tasks cancelled", category: "background")
    }
    
    // MARK: - Foreground Background Task (for immediate backgrounding)
    
    /// Start a foreground background task that continues when app is backgrounded
    func beginBackgroundTask(name: String = "Recipe Extraction") {
        endBackgroundTask() // End any existing task
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: name) {
            // Task expiration handler
            logWarning("Background task expired, cleaning up", category: "background")
            self.endBackgroundTask()
        }
        
        if backgroundTask != .invalid {
            isBackgroundTaskActive = true
            logInfo("Background task started: \(name)", category: "background")
        } else {
            logError("Failed to start background task", category: "background")
        }
    }
    
    /// End the foreground background task
    func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
        isBackgroundTaskActive = false
        logInfo("Background task ended", category: "background")
    }
    
    // MARK: - Background Processing Handler
    
    /// Handle background processing task
    private func handleBackgroundProcessing(task: BGProcessingTask) async {
        logInfo("Background processing task started", category: "background")
        
        // Track if task was expired
        var taskExpired = false
        
        // Set expiration handler
        task.expirationHandler = {
            logWarning("Background processing task expired", category: "background")
            taskExpired = true
        }
        
        // Process pending extractions
        guard !pendingExtractions.isEmpty,
              let apiKey = apiKey,
              let modelContext = modelContext else {
            logWarning("No pending extractions or missing configuration", category: "background")
            task.setTaskCompleted(success: true)
            return
        }
        
        logInfo("Processing \(pendingExtractions.count) pending extractions in background", category: "background")
        
        let apiClient = ClaudeAPIClient(apiKey: apiKey)
        var successCount = 0
        var failureCount = 0
        
        for (imageData, index) in pendingExtractions {
            // Check if task has expired
            guard !taskExpired else {
                logInfo("Background task expired, stopping", category: "background")
                break
            }
            
            do {
                logInfo("Extracting recipe from image \(index + 1)", category: "background")
                
                let recipe = try await apiClient.extractRecipe(
                    from: imageData,
                    usePreprocessing: true
                )
                
                // Save recipe
                await saveRecipe(recipe, withImageData: imageData, modelContext: modelContext)
                
                successCount += 1
                backgroundProgress = Double(successCount + failureCount) / Double(pendingExtractions.count)
                
                logInfo("Successfully extracted recipe in background: \(String(describing: recipe.title))", category: "background")
                
            } catch {
                logError("Failed to extract recipe in background: \(error)", category: "background")
                failureCount += 1
                backgroundProgress = Double(successCount + failureCount) / Double(pendingExtractions.count)
            }
        }
        
        // Clear queue
        pendingExtractions.removeAll()
        backgroundProgress = 0.0
        
        logInfo("Background processing complete: \(successCount) success, \(failureCount) failures", category: "background")
        
        // Mark task as completed
        task.setTaskCompleted(success: successCount > 0)
        
        // Schedule notification if needed
        await scheduleCompletionNotification(successCount: successCount, failureCount: failureCount)
    }
    
    // MARK: - Queue Management
    
    /// Add images to the pending extraction queue
    func queueExtractions(images: [(data: Data, index: Int)]) {
        let converted = images.map { (imageData: $0.data, index: $0.index) }
        pendingExtractions.append(contentsOf: converted)
        logInfo("Added \(images.count) images to extraction queue. Total: \(pendingExtractions.count)", category: "background")
    }
    
    /// Clear the extraction queue
    func clearQueue() {
        pendingExtractions.removeAll()
        backgroundProgress = 0.0
        logInfo("Extraction queue cleared", category: "background")
    }
    
    /// Get the number of pending extractions
    var pendingCount: Int {
        pendingExtractions.count
    }
    
    // MARK: - Helper Methods
    
    private func saveRecipe(_ recipe: RecipeX, withImageData imageData: Data, modelContext: ModelContext) async {
        
        // Convert Data back to UIImage for saving
        if let image = UIImage(data: imageData) {
            recipe.setImage(image, isMainImage: true)
        }
        
        modelContext.insert(recipe)
        
        if let imageName = recipe.imageName {
            let assignment = RecipeImageAssignment(recipeID: recipe.id!, imageName: imageName)
            modelContext.insert(assignment)
        }
        
        do {
            try modelContext.save()
            logInfo("Recipe saved in background", category: "background")
        } catch {
            logError("Failed to save recipe in background: \(error)", category: "background")
        }
    }
    
    private func scheduleCompletionNotification(successCount: Int, failureCount: Int) async {
        guard successCount > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Recipe Extraction Complete"
        content.body = "Extracted \(successCount) recipes successfully"
        if failureCount > 0 {
            content.body += " (\(failureCount) failed)"
        }
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "recipe-extraction-complete",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            logInfo("Completion notification scheduled", category: "background")
        } catch {
            logError("Failed to schedule notification: \(error)", category: "background")
        }
    }
}

// MARK: - App Lifecycle Integration

extension BackgroundProcessingManager {
    
    /// Call this when app enters background during extraction
    func handleAppDidEnterBackground() {
        guard !pendingExtractions.isEmpty else {
            logInfo("App entering background with no pending extractions", category: "background")
            return
        }
        
        logInfo("App entering background with \(pendingExtractions.count) pending extractions", category: "background")
        
        // Start a background task to give us more time
        beginBackgroundTask(name: "Recipe Extraction Continuation")
        
        // Also schedule a background processing task for later
        scheduleBackgroundExtraction()
    }
    
    /// Call this when app enters foreground
    func handleAppWillEnterForeground() {
        logInfo("App entering foreground", category: "background")
        
        // Cancel any scheduled background tasks since we're back in foreground
        if pendingExtractions.isEmpty {
            cancelBackgroundTasks()
        } else {
            logInfo("Still have \(pendingExtractions.count) pending extractions, keeping background task active", category: "background")
        }
        
        // End any active background tasks since we're in foreground now
        if backgroundTask != .invalid {
            logInfo("Ending foreground background task since app is active again", category: "background")
            endBackgroundTask()
        }
    }
    
    /// Call this when app is about to terminate
    func handleAppWillTerminate() {
        logInfo("App terminating with \(pendingExtractions.count) pending extractions", category: "background")
        
        // Schedule background task to finish later
        if !pendingExtractions.isEmpty {
            scheduleBackgroundExtraction()
        }
        
        // Clean up any active background tasks
        endBackgroundTask()
    }
}
