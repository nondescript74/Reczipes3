# State Preservation and Restoration Guide

## Overview

This implementation provides comprehensive state preservation and restoration for your Reczipes2 app. When users navigate away from the app and return, they will see exactly where they left off—including:

- ✅ The tab they were viewing
- ✅ The selected recipe in the recipes list
- ✅ In-progress long-running operations (extraction, diabetic analysis)
- ✅ No launch screen shown when returning from background

## Architecture

### 1. AppStateManager (`AppStateManager.swift`)

**Purpose**: Central state management using `@AppStorage` and `UserDefaults` for persistence.

**Key Features**:
- Tracks current tab selection
- Tracks selected recipe ID
- Tracks active long-running tasks with progress
- Determines whether to show launch screen (only on first launch or after 30+ days)
- Automatically saves state when app enters background

**Usage**:
```swift
// Access the shared instance
let appState = AppStateManager.shared

// Current tab is automatically persisted
appState.currentTab = .extract

// Selected recipe is automatically persisted
appState.selectedRecipeId = recipe.id

// Track long-running tasks
appState.startTask(type: .extraction)
appState.updateTaskProgress(0.5) // 50% complete
appState.completeTask()
```

### 2. TaskRestorationCoordinator (`TaskRestorationCoordinator.swift`)

**Purpose**: Handles restoration of interrupted long-running operations.

**Key Features**:
- Checks for pending tasks when app returns from background
- Shows restoration prompt if task was started within last 2 hours
- Navigates to appropriate view to continue the task
- Provides user choice to resume or cancel

**Task Types**:
- `.extraction` - Recipe extraction from image/text
- `.diabeticAnalysis` - Diabetic analysis of a recipe

### 3. TaskTrackingViewModifier (`TaskTrackingViewModifier.swift`)

**Purpose**: SwiftUI view modifier for easy task tracking integration.

**Usage**:
```swift
.trackTask(
    type: .extraction,
    recipeId: recipe.id, // optional
    progress: extractionProgress,
    isActive: isExtracting
)
```

## Implementation Details

### Launch Screen Behavior

The launch screen now only appears:
1. **On true first launch** - When the app is installed and opened for the first time
2. **After long absence** - If the app hasn't been used in 30+ days

It will **NOT** appear:
- When returning from background
- When switching apps
- When device is locked/unlocked
- After app is killed by system

This is controlled by `AppStateManager.shouldShowLaunchScreen()`.

### State Persistence Strategy

State is persisted using `UserDefaults` with the following keys:

| Key | Type | Purpose |
|-----|------|---------|
| `currentTab` | String | Active tab (recipes/extract/settings) |
| `selectedRecipeId` | String | UUID of selected recipe |
| `activeTask` | Data | JSON-encoded TaskState |
| `isFirstLaunch` | Bool | Whether this is first app launch |
| `lastActiveDate` | Date | Last time app was active |

State is automatically saved:
- When app enters background (`.background` scene phase)
- When properties change (via `didSet` observers)

### Task Restoration Flow

1. **App enters background with active task**:
   - `AppStateManager` saves task state to `UserDefaults`
   - Includes task type, recipe ID, progress, timestamp

2. **App returns to foreground**:
   - `TaskRestorationCoordinator.checkForTaskRestoration()` is called
   - If task was started within 2 hours, shows restoration prompt
   - User can choose to resume or cancel

3. **User chooses to resume**:
   - App navigates to appropriate tab
   - For extraction: navigates to Extract tab
   - For diabetic analysis: navigates to recipe detail view
   - View checks for pending task and shows appropriate UI

## Integration Guide

### For RecipeExtractorView

Add task tracking to your extraction view:

```swift
struct RecipeExtractorView: View {
    @EnvironmentObject private var appState: AppStateManager
    @State private var isExtracting = false
    @State private var extractionProgress: Double = 0.0
    @State private var currentImage: UIImage?
    
    var body: some View {
        VStack {
            // Your existing UI
            
            if isExtracting {
                ProgressView("Extracting recipe...", value: extractionProgress)
            }
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
    
    private func checkForPendingExtraction() {
        // Check if there's a pending extraction task
        if let task = appState.activeTask,
           task.taskType == .extraction {
            // Show UI indicating we can resume
            // Or automatically resume if you have the data
        }
    }
}
```

### For RecipeDetailView (Diabetic Analysis)

Add task tracking to your diabetic analysis:

```swift
struct RecipeDetailView: View {
    let recipe: RecipeModel
    @EnvironmentObject private var appState: AppStateManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var isAnalyzing = false
    @State private var analysisProgress: Double = 0.0
    @State private var diabeticInfo: DiabeticInfo?
    
    var body: some View {
        ScrollView {
            // Recipe details
            
            Section {
                if let info = diabeticInfo {
                    // Show diabetic info
                } else if isAnalyzing {
                    ProgressView("Analyzing recipe...", value: analysisProgress)
                } else {
                    Button("Analyze for Diabetic Info") {
                        Task { await analyzeDiabeticImpact() }
                    }
                }
            }
        }
        .onAppear {
            checkForPendingAnalysis()
        }
        .trackTask(
            type: .diabeticAnalysis,
            recipeId: recipe.id,
            progress: analysisProgress,
            isActive: isAnalyzing
        )
    }
    
    private func checkForPendingAnalysis() {
        // Check if this recipe has pending analysis
        if let task = appState.activeTask,
           task.taskType == .diabeticAnalysis,
           task.recipeId == recipe.id {
            // Resume analysis or show status
            Task { await resumeAnalysis() }
        }
    }
    
    private func analyzeDiabeticImpact() async {
        isAnalyzing = true
        analysisProgress = 0.0
        
        do {
            // Update progress periodically during analysis
            analysisProgress = 0.1
            
            // Get model container
            guard let container = modelContext.container else { return }
            
            analysisProgress = 0.3
            
            // Perform analysis
            let info = try await DiabeticAnalysisService.shared.analyzeDiabeticImpact(
                recipe: recipe,
                modelContainer: container
            )
            
            analysisProgress = 1.0
            diabeticInfo = info
            isAnalyzing = false
            
        } catch {
            print("Analysis failed: \(error)")
            isAnalyzing = false
        }
    }
    
    private func resumeAnalysis() async {
        // Resume from saved progress
        if let task = appState.activeTask {
            analysisProgress = task.progress
            isAnalyzing = true
            
            // Continue analysis
            await analyzeDiabeticImpact()
        }
    }
}
```

## Testing Checklist

### Basic State Preservation
- [ ] Open app, navigate to Extract tab, background app, reopen → should show Extract tab
- [ ] Select a recipe, background app, reopen → should show same recipe selected
- [ ] Open Settings tab, background app, reopen → should show Settings tab

### Launch Screen
- [ ] First app install and launch → should show launch screen
- [ ] Background and reopen → should NOT show launch screen
- [ ] Kill app and relaunch → should NOT show launch screen
- [ ] Wait 30+ days (or adjust date in settings) → should show launch screen

### Task Restoration
- [ ] Start recipe extraction, background app → should save task state
- [ ] Reopen app within 2 hours → should show restoration prompt
- [ ] Choose "Resume" → should navigate to Extract tab
- [ ] Choose "Cancel" → should clear task and stay on current view

- [ ] Start diabetic analysis on a recipe, background app → should save task state
- [ ] Reopen app within 2 hours → should show restoration prompt
- [ ] Choose "Resume" → should navigate to recipe and continue analysis
- [ ] Choose "Cancel" → should clear task

- [ ] Start task, wait 3+ hours, reopen → should NOT show restoration prompt (task expired)

### Edge Cases
- [ ] Background app with no recipe selected → reopen should work correctly
- [ ] Delete a recipe that was selected → reopen should handle gracefully
- [ ] Start multiple tasks quickly → should only track most recent

## Performance Considerations

1. **UserDefaults Usage**: Only small amounts of data are persisted (IDs, enums, small JSON)
2. **Automatic Saving**: State is saved automatically on background, no manual calls needed
3. **Task Expiration**: Old tasks (2+ hours) are automatically ignored to prevent stale restoration
4. **Cache Cleanup**: Expired tasks are cleaned up automatically

## Future Enhancements

Consider adding:
1. **Navigation Path Restoration**: For deep navigation hierarchies
2. **Form State Preservation**: Save partially filled forms
3. **Scroll Position Restoration**: Remember scroll positions in lists
4. **Multi-window Support**: For iPad multi-window scenarios
5. **iCloud Sync**: Sync state across devices

## Troubleshooting

**Launch screen still appears on background return**:
- Check that `AppStateManager` is properly initialized as `@StateObject` in app struct
- Verify `isFirstLaunch` is being set to `false` after first launch

**Selected recipe not restoring**:
- Ensure `ContentView` has `@EnvironmentObject private var appState: AppStateManager`
- Check that `MainTabView` injects the environment object: `.environmentObject(appState)`

**Task restoration not working**:
- Verify `.trackTask()` modifier is applied to your view
- Check that task type matches in both tracking and restoration
- Ensure `TaskRestorationCoordinator` is initialized in app struct

**State not persisting**:
- Check UserDefaults in debugger: `po UserDefaults.standard.dictionaryRepresentation()`
- Look for keys: `currentTab`, `selectedRecipeId`, `activeTask`
- Verify app enters `.background` scene phase (check logs)
