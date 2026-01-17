//
//  TaskTrackingViewModifier.swift
//  Reczipes2
//
//  Created for tracking long-running task progress
//

import SwiftUI
import Combine

/// View modifier that tracks task progress and saves it to AppStateManager
struct TaskTrackingModifier: ViewModifier {
    let taskType: TaskState.TaskType
    let recipeId: UUID?
    let progress: Double
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isActive) { _, active in
                if active {
                    // Task started - register it with AppStateManager
                    AppStateManager.shared.startTask(
                        type: taskType,
                        recipeId: recipeId
                    )
                } else {
                    // Task completed - clear it from AppStateManager
                    AppStateManager.shared.completeTask()
                }
            }
            .onChange(of: progress) { _, newProgress in
                if isActive {
                    AppStateManager.shared.updateTaskProgress(newProgress)
                }
            }
    }
}

extension View {
    /// Tracks a long-running task with AppStateManager
    /// - Parameters:
    ///   - taskType: The type of task (extraction or diabetic analysis)
    ///   - recipeId: Optional recipe ID if the task is associated with a recipe
    ///   - progress: Current progress (0.0 to 1.0)
    ///   - isActive: Whether the task is currently running
    func trackTask(
        type taskType: TaskState.TaskType,
        recipeId: UUID? = nil,
        progress: Double,
        isActive: Bool
    ) -> some View {
        modifier(TaskTrackingModifier(
            taskType: taskType,
            recipeId: recipeId,
            progress: progress,
            isActive: isActive
        ))
    }
}

// MARK: - Example Integration for RecipeExtractorView

/*
 
 To integrate task tracking in your RecipeExtractorView or DiabeticAnalysisView,
 add the .trackTask modifier to your view:
 
 Example 1: Recipe Extraction
 ```swift
 struct RecipeExtractorView: View {
     @State private var isExtracting = false
     @State private var extractionProgress: Double = 0.0
     
     var body: some View {
         VStack {
             // Your extraction UI here
             
             if isExtracting {
                 ProgressView(value: extractionProgress)
             }
         }
         .trackTask(
             type: .extraction,
             progress: extractionProgress,
             isActive: isExtracting
         )
     }
     
     func startExtraction() {
         isExtracting = true
         
         Task {
             // Simulate extraction progress
             for i in 0...100 {
                 extractionProgress = Double(i) / 100.0
                 try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
             }
             
             isExtracting = false
         }
     }
 }
 ```
 
 Example 2: Diabetic Analysis
 ```swift
 struct RecipeDetailView: View {
     let recipe: RecipeModel
     @State private var isAnalyzing = false
     @State private var analysisProgress: Double = 0.0
     
     var body: some View {
         VStack {
             // Recipe details
             
             Button("Analyze for Diabetic Info") {
                 startAnalysis()
             }
             
             if isAnalyzing {
                 ProgressView(value: analysisProgress)
                     .progressViewStyle(.linear)
             }
         }
         .trackTask(
             type: .diabeticAnalysis,
             recipeId: recipe.id,
             progress: analysisProgress,
             isActive: isAnalyzing
         )
     }
     
     func startAnalysis() {
         isAnalyzing = true
         analysisProgress = 0.0
         
         Task {
             // Perform analysis with progress updates
             analysisProgress = 0.2 // Preparing request
             
             // ... call DiabeticAnalysisService ...
             
             analysisProgress = 1.0
             isAnalyzing = false
         }
     }
 }
 ```
 
 Example 3: Restore extraction on app return
 ```swift
 struct RecipeExtractorView: View {
     @EnvironmentObject private var appState: AppStateManager
     @State private var isExtracting = false
     @State private var extractionProgress: Double = 0.0
     
     var body: some View {
         VStack {
             // UI
         }
         .onAppear {
             checkForPendingExtraction()
         }
         .trackTask(
             type: .extraction,
             progress: extractionProgress,
             isActive: isExtracting
         )
     }
     
     func checkForPendingExtraction() {
         // Check if there was an extraction in progress
         if let task = appState.activeTask,
            task.taskType == .extraction {
             
             // Show UI to resume or cancel
             showResumeAlert()
         }
     }
     
     func resumeExtraction() {
         // Resume from saved progress
         if let task = appState.activeTask {
             extractionProgress = task.progress
             isExtracting = true
             
             // Continue extraction from where it left off
         }
     }
 }
 ```
 
 */
