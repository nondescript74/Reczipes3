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
class BackgroundProcessingManager: ObservableObject {
    static let shared = BackgroundProcessingManager()
    
    // Background task identifier - must match Info.plist
    private let backgroundTaskIdentifier = "com.yourapp.reczipes.backgroundExtraction"
    
    // Processing state (main actor isolated for UI updates)
    @MainActor @Published var isBackgroundTaskActive = false
    @MainActor @Published var backgroundProgress: Double = 0.0
    
    // Background task reference (accessed from multiple threads)
    private let backgroundTaskLock = NSLock()
    private var _backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTask: UIBackgroundTaskIdentifier {
        get {
            backgroundTaskLock.lock()
            defer { backgroundTaskLock.unlock() }
            return _backgroundTask
        }
        set {
            backgroundTaskLock.lock()
            defer { backgroundTaskLock.unlock() }
            _backgroundTask = newValue
        }
    }
    
    // Queue for pending extractions (thread-safe via actor)
    private let extractionQueue = ExtractionQueue()
    private var apiKey: String?
    private var modelContext: ModelContext?
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Register background task handler - call from AppDelegate
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self = self else { return }
            
            // Cast to BGProcessingTask
            guard let processingTask = task as? BGProcessingTask else {
                logError("Task is not a BGProcessingTask", category: "background")
                task.setTaskCompleted(success: false)
                return
            }
            
            // Handle the task directly without Task.detached to avoid sendability issues
            // The handler already runs on a background queue
            Task { [weak self] in
                guard let self = self else {
                    processingTask.setTaskCompleted(success: false)
                    return
                }
                
                await self.handleBackgroundProcessing(
                    task: processingTask,
                    apiKey: self.apiKey,
                    modelContext: self.modelContext,
                    extractionQueue: self.extractionQueue
                )
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
        
        let newTask = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            // Task expiration handler
            logWarning("Background task expired, cleaning up", category: "background")
            self?.endBackgroundTask()
        }
        
        backgroundTask = newTask
        
        if newTask != .invalid {
            Task { @MainActor in
                self.isBackgroundTaskActive = true
            }
            logInfo("Background task started: \(name)", category: "background")
        } else {
            logError("Failed to start background task", category: "background")
        }
    }
    
    /// End the foreground background task
    func endBackgroundTask() {
        let taskToEnd = backgroundTask
        guard taskToEnd != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(taskToEnd)
        backgroundTask = .invalid
        
        Task { @MainActor in
            self.isBackgroundTaskActive = false
        }
        logInfo("Background task ended", category: "background")
    }
    
    // MARK: - Background Processing Handler
    
    /// Handle background processing task (runs on background queue)
    private func handleBackgroundProcessing(
        task: BGProcessingTask,
        apiKey: String?,
        modelContext: ModelContext?,
        extractionQueue: ExtractionQueue
    ) async {
        logInfo("Background processing task started", category: "background")
        
        // Track if task was expired
        var taskExpired = false
        
        // Set expiration handler
        task.expirationHandler = {
            logWarning("Background processing task expired", category: "background")
            taskExpired = true
        }
        
        // Get pending extractions safely
        let extractionsToProcess = await extractionQueue.getAll()
        
        // Process pending extractions
        guard !extractionsToProcess.isEmpty,
              let apiKey = apiKey,
              let modelContext = modelContext else {
            logWarning("No pending extractions or missing configuration", category: "background")
            task.setTaskCompleted(success: true)
            return
        }
        
        logInfo("Processing \(extractionsToProcess.count) pending extractions in background", category: "background")
        
        let apiClient = ClaudeAPIClient(apiKey: apiKey)
        var successCount = 0
        var failureCount = 0
        
        for (imageData, index) in extractionsToProcess {
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
                
                // Save recipe on background thread
                await saveRecipe(recipe, withImageData: imageData, modelContext: modelContext)
                
                successCount += 1
                let progress = Double(successCount + failureCount) / Double(extractionsToProcess.count)
                
                // Update UI on main actor
                await MainActor.run {
                    self.backgroundProgress = progress
                }
                
                logInfo("Successfully extracted recipe in background: \(String(describing: recipe.title))", category: "background")
                
            } catch {
                logError("Failed to extract recipe in background: \(error)", category: "background")
                failureCount += 1
                let progress = Double(successCount + failureCount) / Double(extractionsToProcess.count)
                
                // Update UI on main actor
                await MainActor.run {
                    self.backgroundProgress = progress
                }
            }
        }
        
        // Clear queue safely
        await extractionQueue.clear()
        
        // Reset progress on main actor
        await MainActor.run {
            self.backgroundProgress = 0.0
        }
        
        logInfo("Background processing complete: \(successCount) success, \(failureCount) failures", category: "background")
        
        // Mark task as completed
        task.setTaskCompleted(success: successCount > 0)
        
        // Schedule notification if needed
        await scheduleCompletionNotification(successCount: successCount, failureCount: failureCount)
    }
    
    // MARK: - Queue Management
    
    /// Add images to the pending extraction queue
    func queueExtractions(images: [(data: Data, index: Int)]) {
        Task {
            let converted = images.map { (imageData: $0.data, index: $0.index) }
            await extractionQueue.append(contentsOf: converted)
            let count = await extractionQueue.count
            logInfo("Added \(images.count) images to extraction queue. Total: \(count)", category: "background")
        }
    }
    
    /// Clear the extraction queue
    func clearQueue() {
        Task {
            await extractionQueue.clear()
            
            await MainActor.run {
                self.backgroundProgress = 0.0
            }
            logInfo("Extraction queue cleared", category: "background")
        }
    }
    
    /// Get the number of pending extractions
    var pendingCount: Int {
        get async {
            await extractionQueue.count
        }
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
    /// Note: This must complete quickly to avoid crashes. Heavy work is deferred.
    func handleAppDidEnterBackground() {
        // Use detached task to avoid inheriting actor context that might cause issues
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let count = await self.extractionQueue.count
            guard count > 0 else {
                await MainActor.run {
                    logInfo("App entering background with no pending extractions", category: "background")
                }
                return
            }
            
            await MainActor.run {
                logInfo("App entering background with \(count) pending extractions", category: "background")
                
                // Start a background task to give us more time
                self.beginBackgroundTask(name: "Recipe Extraction Continuation")
                
                // Also schedule a background processing task for later
                self.scheduleBackgroundExtraction()
            }
        }
    }
    
    /// Call this when app enters foreground
    func handleAppWillEnterForeground() {
        logInfo("App entering foreground", category: "background")
        
        // End any active background tasks immediately
        // This is safe and should be done synchronously
        if backgroundTask != .invalid {
            logInfo("Ending foreground background task since app is active again", category: "background")
            endBackgroundTask()
        }
        
        // Check queue status asynchronously
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let count = await self.extractionQueue.count
            
            await MainActor.run {
                // Cancel any scheduled background tasks since we're back in foreground
                if count == 0 {
                    self.cancelBackgroundTasks()
                } else {
                    logInfo("Still have \(count) pending extractions, keeping background task active", category: "background")
                }
            }
        }
    }
    
    /// Call this when app is about to terminate
    func handleAppWillTerminate() {
        Task {
            let count = await extractionQueue.count
            logInfo("App terminating with \(count) pending extractions", category: "background")
            
            // Schedule background task to finish later
            if count > 0 {
                scheduleBackgroundExtraction()
            }
        }
        
        // Clean up any active background tasks
        endBackgroundTask()
    }
}
// MARK: - Extraction Queue Actor

/// Thread-safe actor for managing the extraction queue
private actor ExtractionQueue {
    private var items: [(imageData: Data, index: Int)] = []
    
    func append(contentsOf newItems: [(imageData: Data, index: Int)]) {
        items.append(contentsOf: newItems)
    }
    
    func getAll() -> [(imageData: Data, index: Int)] {
        return items
    }
    
    func clear() {
        items.removeAll()
    }
    
    var count: Int {
        items.count
    }
}

