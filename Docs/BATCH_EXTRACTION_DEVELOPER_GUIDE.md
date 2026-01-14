# Batch Extraction Developer Guide

## Quick Start

### Adding Batch Extraction to Your View

```swift
import SwiftUI
import SwiftData

struct MyExtractView: View {
    @State private var showBatchExtraction = false
    @Environment(\.modelContext) private var modelContext
    private let apiKey: String
    
    var body: some View {
        Button("Batch Extract") {
            showBatchExtraction = true
        }
        .sheet(isPresented: $showBatchExtraction) {
            BatchRecipeExtractorView(
                apiKey: apiKey,
                modelContext: modelContext
            )
        }
    }
}
```

## Customization Examples

### 1. Adjusting Extraction Speed

Modify `BatchRecipeExtractorViewModel.swift`:

```swift
// Faster extraction (3 seconds between recipes)
private let extractionInterval: TimeInterval = 3.0

// Slower extraction (10 seconds between recipes)
private let extractionInterval: TimeInterval = 10.0

// No delay (not recommended - may hit rate limits)
private let extractionInterval: TimeInterval = 0.0
```

### 2. Changing Batch Size Limit

```swift
// Increase limit to 100 recipes
private let maxBatchSize: Int = 100

// Unlimited batch size (not recommended)
private let maxBatchSize: Int = Int.max

// Small batches (20 recipes)
private let maxBatchSize: Int = 20
```

### 3. Custom Retry Configuration

```swift
// More aggressive retry
private let retryConfiguration = ExtractionRetryManager.RetryConfiguration(
    maxAttempts: 5,        // Try 5 times
    initialDelay: 1.0,     // Start with 1 second
    maxDelay: 60.0,        // Max 1 minute wait
    backoffMultiplier: 3.0, // Triple delay each time
    useJitter: true        // Randomize slightly
)

// Conservative retry (fewer attempts)
private let retryConfiguration = ExtractionRetryManager.RetryConfiguration(
    maxAttempts: 2,
    initialDelay: 5.0,
    maxDelay: 15.0,
    backoffMultiplier: 2.0,
    useJitter: false
)
```

### 4. Filtering Links to Process

```swift
// Only extract links from specific domain
func startBatchExtraction(links: [SavedLink]) {
    let filteredLinks = links.filter { link in
        !link.isProcessed && link.url.contains("example.com")
    }
    // ... process filteredLinks
}

// Only extract recently added links
func startBatchExtraction(links: [SavedLink]) {
    let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
    let recentLinks = links.filter { link in
        !link.isProcessed && link.dateAdded >= oneWeekAgo
    }
    // ... process recentLinks
}

// Sort by priority (if you add priority field)
func startBatchExtraction(links: [SavedLink]) {
    let sortedLinks = links
        .filter { !$0.isProcessed }
        .sorted { $0.priority > $1.priority }
    // ... process sortedLinks
}
```

### 5. Custom Progress Callbacks

Add a completion handler:

```swift
class BatchRecipeExtractorViewModel: ObservableObject {
    var onRecipeExtracted: ((RecipeModel) -> Void)?
    var onBatchComplete: ((Int, Int) -> Void)? // success, failure
    
    private func extractSingleLink(_ link: SavedLink) async {
        // ... extraction logic
        
        if let recipe = extractedRecipe {
            onRecipeExtracted?(recipe)
        }
    }
    
    private func extractLinks(_ links: [SavedLink]) async {
        // ... batch processing
        
        onBatchComplete?(successCount, failureCount)
    }
}
```

Usage:
```swift
viewModel.onRecipeExtracted = { recipe in
    print("Extracted: \(recipe.title)")
    // Send notification, update analytics, etc.
}

viewModel.onBatchComplete = { success, failure in
    print("Batch complete: \(success) succeeded, \(failure) failed")
    // Show custom alert, log to analytics, etc.
}
```

### 6. Custom UI Themes

Modify `BatchRecipeExtractorView.swift`:

```swift
// Custom color scheme
private let themeColor: Color = .orange // Change from purple
private let successColor: Color = .mint
private let errorColor: Color = .pink

// Apply in UI:
.background(themeColor.opacity(0.1))
.tint(themeColor)
```

### 7. Image Download Configuration

Modify image retry settings:

```swift
// More retries for images
let image = try await retryManager.withRetry(
    operationID: imageOperationID,
    configuration: .init(
        maxAttempts: 5,      // Try 5 times instead of 2
        initialDelay: 0.5,
        maxDelay: 10.0,
        backoffMultiplier: 2.0,
        useJitter: true
    )
) {
    try await self.webImageDownloader.downloadImage(from: imageURL)
}
```

Skip images on failure instead of continuing:

```swift
do {
    let image = try await retryManager.withRetry(/*...*/) {
        try await self.webImageDownloader.downloadImage(from: imageURL)
    }
    downloadedImages.append(image)
} catch {
    // Option 1: Continue with other images (current behavior)
    logWarning("Failed to download image: \(error)")
    
    // Option 2: Fail entire extraction
    throw error
    
    // Option 3: Use placeholder image
    if let placeholder = UIImage(systemName: "photo") {
        downloadedImages.append(placeholder)
    }
}
```

## Advanced Customization

### 1. Parallel Processing

Process multiple recipes at once (requires careful rate limiting):

```swift
private func extractLinks(_ links: [SavedLink]) async {
    await withTaskGroup(of: Void.self) { group in
        for link in links.prefix(3) { // Process 3 at a time
            group.addTask {
                await self.extractSingleLink(link)
            }
        }
        
        // Wait for batch to complete before starting next batch
        await group.waitForAll()
    }
}
```

### 2. Priority Queue

Implement priority-based extraction:

```swift
struct PriorityLink: Comparable {
    let link: SavedLink
    let priority: Int
    
    static func < (lhs: PriorityLink, rhs: PriorityLink) -> Bool {
        lhs.priority < rhs.priority
    }
}

private func extractLinks(_ links: [SavedLink]) async {
    var queue = links.map { PriorityLink(link: $0, priority: calculatePriority($0)) }
        .sorted(by: >)
    
    for priorityLink in queue {
        await extractSingleLink(priorityLink.link)
    }
}

private func calculatePriority(_ link: SavedLink) -> Int {
    var priority = 0
    
    // Newer links get higher priority
    let daysSinceAdded = -link.dateAdded.timeIntervalSinceNow / (24 * 60 * 60)
    priority += Int(100 - daysSinceAdded)
    
    // Specific domains get priority
    if link.url.contains("allrecipes.com") {
        priority += 50
    }
    
    return priority
}
```

### 3. Persistence Across App Launches

Save batch state:

```swift
struct BatchExtractionState: Codable {
    let linksToProcess: [UUID]
    let currentIndex: Int
    let startTime: Date
}

func saveState() {
    let state = BatchExtractionState(
        linksToProcess: linksToProcess.map { $0.id },
        currentIndex: currentIndex,
        startTime: startTime ?? Date()
    )
    
    if let encoded = try? JSONEncoder().encode(state) {
        UserDefaults.standard.set(encoded, forKey: "batchExtractionState")
    }
}

func restoreState() -> BatchExtractionState? {
    guard let data = UserDefaults.standard.data(forKey: "batchExtractionState"),
          let state = try? JSONDecoder().decode(BatchExtractionState.self, from: data) else {
        return nil
    }
    return state
}
```

### 4. Analytics Integration

Track extraction metrics:

```swift
private func extractSingleLink(_ link: SavedLink) async {
    let startTime = Date()
    
    do {
        // ... extraction
        
        let duration = Date().timeIntervalSince(startTime)
        Analytics.logEvent("recipe_extracted", parameters: [
            "duration": duration,
            "domain": extractDomain(from: link.url),
            "success": true
        ])
    } catch {
        Analytics.logEvent("extraction_failed", parameters: [
            "error": error.localizedDescription,
            "domain": extractDomain(from: link.url)
        ])
    }
}
```

### 5. Notifications

Send local notifications:

```swift
import UserNotifications

func sendCompletionNotification() async {
    let content = UNMutableNotificationContent()
    content.title = "Batch Extraction Complete"
    content.body = "Extracted \(successCount) recipes successfully"
    content.sound = .default
    
    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil // Immediate
    )
    
    try? await UNUserNotificationCenter.current().add(request)
}
```

### 6. Export Error Log

```swift
func exportErrorLog() -> String {
    var csv = "Link,Error,Timestamp\n"
    
    for error in errorLog {
        csv += "\"\(error.link)\",\"\(error.error)\",\"\(formatDate(error.timestamp))\"\n"
    }
    
    return csv
}

// Save to file
func saveErrorLog() {
    let csv = exportErrorLog()
    let filename = "extraction_errors_\(Date().ISO8601Format()).csv"
    
    if let data = csv.data(using: .utf8) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        // Share via share sheet
    }
}
```

### 7. Smart Scheduling

Schedule batch extraction for off-peak hours:

```swift
import BackgroundTasks

func scheduleBatchExtraction() {
    let request = BGProcessingTaskRequest(identifier: "com.yourapp.batchextract")
    request.requiresNetworkConnectivity = true
    request.requiresExternalPower = false
    request.earliestBeginDate = Calendar.current.date(bySettingHour: 2, minute: 0, second: 0, of: Date())
    
    try? BGTaskScheduler.shared.submit(request)
}

func handleBackgroundTask(task: BGProcessingTask) {
    task.expirationHandler = {
        // Save state and cancel
        self.stop()
    }
    
    Task {
        await startBatchExtraction(links: fetchUnprocessedLinks())
        task.setTaskCompleted(success: true)
    }
}
```

## Testing

### Unit Test Example

```swift
import Testing
@testable import Reczipes2

@Suite("Batch Extraction Tests")
struct BatchExtractionTests {
    
    @Test("Batch processes all links")
    func testBatchProcessing() async throws {
        let viewModel = BatchRecipeExtractorViewModel(
            apiKey: "test-key",
            modelContext: mockContext
        )
        
        let links = [
            SavedLink(url: "https://example.com/1", title: "Recipe 1"),
            SavedLink(url: "https://example.com/2", title: "Recipe 2")
        ]
        
        viewModel.startBatchExtraction(links: links)
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
        
        #expect(viewModel.totalToExtract == 2)
        #expect(viewModel.currentProgress == 2)
    }
    
    @Test("Pause and resume works")
    func testPauseResume() async throws {
        let viewModel = BatchRecipeExtractorViewModel(
            apiKey: "test-key",
            modelContext: mockContext
        )
        
        viewModel.startBatchExtraction(links: testLinks)
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        viewModel.pause()
        #expect(viewModel.isPaused == true)
        
        let progressBeforePause = viewModel.currentProgress
        
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Progress shouldn't change while paused
        #expect(viewModel.currentProgress == progressBeforePause)
        
        viewModel.resume()
        #expect(viewModel.isPaused == false)
    }
}
```

### UI Test Example

```swift
import XCTest

class BatchExtractionUITests: XCTestCase {
    func testBatchExtractionFlow() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Extract tab
        app.tabBars.buttons["Extract"].tap()
        
        // Tap Batch Extract
        app.buttons["Batch Extract"].tap()
        
        // Verify batch view appeared
        XCTAssertTrue(app.staticTexts["Batch Extraction"].exists)
        
        // Start extraction
        app.buttons["Start Batch Extraction"].tap()
        
        // Wait for progress
        let progressExists = app.progressIndicators.firstMatch.waitForExistence(timeout: 2)
        XCTAssertTrue(progressExists)
        
        // Pause
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].exists)
        
        // Resume
        app.buttons["Resume"].tap()
        XCTAssertTrue(app.buttons["Pause"].exists)
        
        // Stop
        app.buttons["Stop"].tap()
        
        // Verify stopped
        XCTAssertTrue(app.buttons["Start Batch Extraction"].exists)
    }
}
```

## Best Practices

1. **Rate Limiting**: Always maintain delay between extractions
2. **Error Handling**: Don't fail entire batch on single error
3. **User Feedback**: Show clear progress and status
4. **Cancellation**: Respect user's stop/pause requests
5. **Memory**: Don't hold all recipes in memory, save immediately
6. **Network**: Handle offline gracefully
7. **Testing**: Test with various batch sizes and error conditions
8. **Logging**: Use structured logging for debugging
9. **Accessibility**: Ensure all states are accessible
10. **Performance**: Monitor extraction times and optimize

## Common Pitfalls

### 1. Blocking the Main Thread
```swift
// ❌ Bad
func extractRecipe() {
    let recipe = extractRecipeSync() // Blocks UI
    self.currentRecipe = recipe
}

// ✅ Good
func extractRecipe() async {
    let recipe = await extractRecipeAsync()
    await MainActor.run {
        self.currentRecipe = recipe
    }
}
```

### 2. Memory Leaks with Closures
```swift
// ❌ Bad
extractionTask = Task {
    self.processLinks() // Strong reference to self
}

// ✅ Good
extractionTask = Task { [weak self] in
    await self?.processLinks()
}
```

### 3. Not Handling Cancellation
```swift
// ❌ Bad
for link in links {
    await extract(link)
}

// ✅ Good
for link in links {
    guard !Task.isCancelled else { break }
    await extract(link)
}
```

### 4. Forgetting to Save State
```swift
// ❌ Bad
link.isProcessed = true
// Forgot to save context!

// ✅ Good
link.isProcessed = true
try modelContext.save()
```

## Resources

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Background Tasks Framework](https://developer.apple.com/documentation/backgroundtasks)
- [User Notifications](https://developer.apple.com/documentation/usernotifications)

## Support

For issues or questions:
1. Check the error log in batch view
2. Review console logs for detailed errors
3. Test with a small batch first
4. Verify API key and network connection
5. Check SwiftData container status
