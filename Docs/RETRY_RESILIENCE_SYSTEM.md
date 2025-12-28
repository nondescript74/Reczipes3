# Recipe Extraction Retry & Resilience System

## Overview

The recipe extraction system now includes comprehensive retry logic to handle transient failures during batch extraction. This makes the system resilient to network issues, temporary server errors, and data extraction failures.

## Architecture

### Core Components

1. **ExtractionRetryManager** (`ExtractionRetryManager.swift`)
   - Actor-based retry manager with exponential backoff
   - Intelligent error classification
   - Configurable retry behavior
   - Operation tracking and statistics

2. **Integration Points**
   - `BatchRecipeExtractorViewModel`: Batch extraction with retry
   - `WebRecipeExtractor`: Web content fetching with retry
   - `ClaudeAPIClient`: API calls with retry
   - `WebImageDownloader`: Image downloads with retry

## Error Classification

The system automatically classifies errors into three categories:

### 1. Retryable Errors (Automatic Retry)
These errors are considered transient and will be automatically retried:

- **Network connectivity issues**
  - `notConnectedToInternet`
  - `networkConnectionLost`
  - `cannotConnectToHost`
  - `cannotFindHost`
  - `dnsLookupFailed`

- **Timeout errors**
  - `timedOut`

- **Server errors (5xx)**
  - HTTP 500 (Internal Server Error)
  - HTTP 502 (Bad Gateway)
  - HTTP 503 (Service Unavailable)
  - HTTP 504 (Gateway Timeout)

- **Data decoding errors**
  - `decodingError` (transient corruption)

- **Transient API errors**
  - HTTP 401 (Unauthorized) - could be temporary auth issue
  - HTTP 408 (Request Timeout)

### 2. Retryable with Extended Delay
These errors require waiting before retry:

- **Rate limiting**
  - HTTP 429 (Too Many Requests)
  - Waits 10 seconds before retry

### 3. Terminal Errors (No Retry)
These errors are permanent and will not be retried:

- **Invalid URLs**
  - Malformed URLs
  - Unsupported protocols

- **Authentication/Authorization failures**
  - HTTP 403 (Forbidden) - access denied

- **Resource not found**
  - HTTP 404 (Not Found)

- **Certificate/Security issues**
  - Certificate validation failures
  - App Transport Security violations

- **Content issues**
  - No recipe found in content
  - Invalid JSON structure

## Retry Configuration

### Default Configuration
```swift
RetryConfiguration(
    maxAttempts: 3,           // Try up to 3 times
    initialDelay: 2.0,        // Wait 2 seconds before first retry
    maxDelay: 30.0,           // Maximum delay of 30 seconds
    backoffMultiplier: 2.0,   // Double delay each time
    useJitter: true           // Add randomness to avoid thundering herd
)
```

### Exponential Backoff Schedule
With default configuration:
- Attempt 1: Immediate
- Attempt 2: After 2 seconds
- Attempt 3: After 4 seconds (2 × 2)
- Attempt 4: After 8 seconds (2 × 4)

With jitter enabled, actual delays vary by ±30% to prevent synchronized retries across multiple operations.

### Alternative Configurations

**Aggressive** (for time-sensitive operations):
```swift
RetryConfiguration.aggressive
// maxAttempts: 5
// initialDelay: 1.0
// maxDelay: 60.0
// backoffMultiplier: 2.5
```

**Conservative** (for rate-limited APIs):
```swift
RetryConfiguration.conservative
// maxAttempts: 2
// initialDelay: 5.0
// maxDelay: 15.0
// backoffMultiplier: 2.0
```

## Usage Examples

### Basic Retry Wrapper
```swift
let retryManager = ExtractionRetryManager()

let result = try await retryManager.withRetry(
    operationID: "fetch-recipe",
    configuration: .default
) {
    // Your operation here
    try await fetchRecipe(from: url)
}
```

### Custom Configuration
```swift
let result = try await retryManager.withRetry(
    operationID: "download-image",
    configuration: .init(
        maxAttempts: 2,
        initialDelay: 1.0,
        maxDelay: 5.0,
        backoffMultiplier: 2.0,
        useJitter: true
    )
) {
    try await downloadImage(from: imageURL)
}
```

### Getting Retry Statistics
```swift
let stats = await retryManager.getRetryStats(operationID: "fetch-recipe")
print("Total attempts: \(stats.totalAttempts)")
print("Last attempt: \(stats.lastAttempt)")
print("Average time between attempts: \(stats.averageTimeBetweenAttempts)")
```

## Batch Extraction Behavior

When running batch extraction, each recipe extraction is wrapped in retry logic:

1. **Individual recipe extraction** gets 3 retry attempts
2. **Image downloads** get 2 retry attempts per image
3. Failed recipes are marked with error details
4. Success/failure counts are updated in real-time
5. Retry statistics are logged for debugging

### Example Log Output
```
🔄 Starting operation with retry: extract-abc123
🔄 Attempt 1/3 for: extract-abc123
⚠️ Attempt 1 failed for extract-abc123: Network connection lost
ℹ️ Retrying after 2.0s delay...
🔄 Attempt 2/3 for: extract-abc123
✓ Operation succeeded on attempt 2: extract-abc123
```

## Error Messages for Users

The system provides clear error messages based on the type of failure:

### Network Errors
- "Network error. Please check your internet connection."
- Automatically retried up to 3 times

### HTTP Errors
- **404**: "Page not found. Please check the URL." (Not retried)
- **403**: "Access denied. The website may be blocking automated access." (Not retried)
- **429**: "Too many requests. Waiting before retry..." (Retried with 10s delay)
- **500-599**: "Server error. The website may be temporarily unavailable." (Retried)

### Data Errors
- "The data couldn't be read because it is missing." (Retried once)
- "No recipe could be found on this webpage." (Not retried)

### Security Errors
- "App Transport Security policy requires the use of a secure connection." (Not retried)

## Testing

Comprehensive test coverage in `ExtractionRetryTests.swift`:

- ✅ Successful operations
- ✅ Transient network failures
- ✅ Timeout handling
- ✅ Server error retry
- ✅ Terminal error handling (no retry)
- ✅ Rate limiting with extended delay
- ✅ Exponential backoff behavior
- ✅ Max attempts enforcement
- ✅ Statistics tracking
- ✅ Error type classification

Run tests with:
```bash
swift test --filter ExtractionRetryTests
```

## Monitoring & Debugging

### Enable Detailed Logging
The system uses the existing logging infrastructure:

```swift
// Retry-specific logs use category: "retry"
logInfo("Starting operation with retry: \(operationID)", category: "retry")
logDebug("Attempt \(attempt)/\(maxAttempts)", category: "retry")
logWarning("Retryable error detected: \(error)", category: "retry")
logError("Terminal error - not retrying: \(error)", category: "retry")
```

### Check Retry History
```swift
let stats = await retryManager.getRetryStats(operationID: operationID)
print("Operation attempted \(stats.totalAttempts) times")
if let lastAttempt = stats.lastAttempt {
    print("Last attempt: \(lastAttempt)")
}
```

## Performance Considerations

### Trade-offs

**Benefits:**
- Higher success rate for transient failures
- Better user experience (fewer manual retries)
- Automatic handling of rate limits
- Graceful degradation under poor network conditions

**Costs:**
- Increased latency on failures (due to delays)
- Potential for longer batch extraction times
- Additional memory for retry state tracking

### Optimization Tips

1. **Adjust retry configuration** based on:
   - Network quality (reduce retries on stable connections)
   - API rate limits (increase delays for rate-limited services)
   - User patience (shorter timeouts for interactive operations)

2. **Monitor retry rates**:
   - High retry rates may indicate infrastructure issues
   - Pattern of failures can guide configuration tuning

3. **Use appropriate timeouts**:
   - Set reasonable `URLRequest.timeoutInterval`
   - Balance between giving operations time vs. failing fast

## Future Enhancements

Potential improvements:

1. **Adaptive retry logic**
   - Learn from historical success/failure patterns
   - Adjust retry behavior based on error types

2. **Circuit breaker pattern**
   - Stop retrying if many operations fail
   - Prevent cascading failures

3. **User control**
   - Settings UI for retry configuration
   - Enable/disable retry per operation type

4. **Enhanced monitoring**
   - Dashboard for retry statistics
   - Alerts for high failure rates

5. **Intelligent backoff**
   - Use server-provided Retry-After headers
   - Detect connection quality and adjust delays

## Related Files

- `ExtractionRetryManager.swift` - Core retry logic
- `BatchRecipeExtractorViewModel.swift` - Batch extraction with retry
- `WebRecipeExtractor.swift` - Web fetching with retry
- `ClaudeAPIClient.swift` - API calls with retry
- `ExtractionRetryTests.swift` - Test coverage

## Support

For issues or questions about the retry system:
1. Check logs for detailed error classification
2. Review retry statistics for operation patterns
3. Adjust configuration based on error types
4. File issues with complete logs and error context
