//
//  ExtractionRetryTests.swift
//  Reczipes2Tests
//
//  Tests for retry logic in recipe extraction
//

import Testing
import Foundation
@testable import Reczipes2

/// Thread-safe counter for testing retry attempts
actor AttemptCounter {
    private(set) var count: Int = 0
    private(set) var timestamps: [Date] = []
    
    func increment() {
        count += 1
        timestamps.append(Date())
    }
    
    func reset() {
        count = 0
        timestamps = []
    }
}

@Suite("Extraction Retry Manager Tests")
struct ExtractionRetryTests {
    
    // MARK: - Successful Operation
    
    @Test("Successful operation on first attempt")
    func successfulFirstAttempt() async throws {
        let retryManager = ExtractionRetryManager()
        let counter = AttemptCounter()
        
        let result = try await retryManager.withRetry(
            operationID: "test-success",
            configuration: ExtractionRetryManager.RetryConfiguration.default
        ) {
            await counter.increment()
            return "Success!"
        }
        
        #expect(result == "Success!")
        let countAfterSuccess = await counter.count
        #expect(countAfterSuccess == 1)
    }
    
    // MARK: - Transient Failures
    
    @Test("Retry on transient network error")
    func retryOnNetworkError() async throws {
        let retryManager = ExtractionRetryManager()
        let counter = AttemptCounter()
        
        let result = try await retryManager.withRetry(
            operationID: "test-network-retry",
            configuration: ExtractionRetryManager.RetryConfiguration.default
        ) {
            await counter.increment()
            let currentCount = await counter.count
            if currentCount < 3 {
                // Fail first 2 attempts with network error
                throw URLError(.networkConnectionLost)
            }
            return "Success after retry!"
        }
        
        #expect(result == "Success after retry!")
        let countAfterRetry = await counter.count
        #expect(countAfterRetry == 3)
    }
    
    @Test("Retry on timeout error")
    func retryOnTimeout() async throws {
        let retryManager = ExtractionRetryManager()
        let counter = AttemptCounter()
        
        let result = try await retryManager.withRetry(
            operationID: "test-timeout-retry",
            configuration: ExtractionRetryManager.RetryConfiguration.default
        ) {
            await counter.increment()
            let currentCount = await counter.count
            if currentCount == 1 {
                throw URLError(.timedOut)
            }
            return "Success after timeout!"
        }
        
        #expect(result == "Success after timeout!")
        let countAfterTimeout = await counter.count
        #expect(countAfterTimeout == 2)
    }
    
    @Test("Retry on server error (500)")
    func retryOnServerError() async throws {
        let retryManager = ExtractionRetryManager()
        let counter = AttemptCounter()
        
        let result = try await retryManager.withRetry(
            operationID: "test-server-error",
            configuration: ExtractionRetryManager.RetryConfiguration.default
        ) {
            await counter.increment()
            let currentCount = await counter.count
            if currentCount == 1 {
                throw WebExtractionError.httpError(statusCode: 500)
            }
            return "Success after server error!"
        }
        
        #expect(result == "Success after server error!")
        let countAfterServerError = await counter.count
        #expect(countAfterServerError == 2)
    }
    
    // MARK: - Terminal Failures
    
    @Test("No retry on 404 error")
    func noRetryOn404() async throws {
        let retryManager = ExtractionRetryManager()
        let counter = AttemptCounter()
        
        do {
            _ = try await retryManager.withRetry(
                operationID: "test-404-terminal",
                configuration: ExtractionRetryManager.RetryConfiguration.default
            ) {
                await counter.increment()
                throw WebExtractionError.httpError(statusCode: 404)
            }
            
            #expect(Bool(false), "Should have thrown error")
        } catch {
            // Expected to fail
            let finalCount = await counter.count
            #expect(finalCount == 1, "Should not retry on 404")
        }
    }
    
    @Test("No retry on invalid URL")
    func noRetryOnInvalidURL() async throws {
        let retryManager = ExtractionRetryManager()
        let counter = AttemptCounter()
        
        do {
            _ = try await retryManager.withRetry(
                operationID: "test-invalid-url",
                configuration: ExtractionRetryManager.RetryConfiguration.default
            ) {
                await counter.increment()
                throw WebExtractionError.invalidURL
            }
            
            #expect(Bool(false), "Should have thrown error")
        } catch {
            // Expected to fail
            let finalCount = await counter.count
            #expect(finalCount == 1, "Should not retry on invalid URL")
        }
    }
    
    @Test("No retry on ATS error")
    func noRetryOnATS() async throws {
        let retryManager = ExtractionRetryManager()
        let counter = AttemptCounter()
        
        do {
            _ = try await retryManager.withRetry(
                operationID: "test-ats",
                configuration: ExtractionRetryManager.RetryConfiguration.default
            ) {
                await counter.increment()
                throw URLError(.appTransportSecurityRequiresSecureConnection)
            }
            
            #expect(Bool(false), "Should have thrown error")
        } catch {
            // Expected to fail
            let finalCount = await counter.count
            #expect(finalCount == 1, "Should not retry on ATS error")
        }
    }
    
    // MARK: - Rate Limiting
    
    @Test("Extended delay on rate limit (429)")
    func extendedDelayOnRateLimit() async throws {
        let retryManager = ExtractionRetryManager()
        let counter = AttemptCounter()
        let startTime = Date()
        
        let result = try await retryManager.withRetry(
            operationID: "test-rate-limit",
            configuration: ExtractionRetryManager.RetryConfiguration(
                maxAttempts: 2,
                initialDelay: 1.0,
                maxDelay: 15.0,
                backoffMultiplier: 2.0,
                useJitter: false
            )
        ) {
            await counter.increment()
            let currentCount = await counter.count
            if currentCount == 1 {
                throw WebExtractionError.httpError(statusCode: 429)
            }
            return "Success after rate limit!"
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        #expect(result == "Success after rate limit!")
        let countAfterRateLimit = await counter.count
        #expect(countAfterRateLimit == 2)
        // Should have waited ~10 seconds (rate limit delay)
        #expect(elapsed >= 9.0, "Should have delayed for rate limit")
    }
    
    // MARK: - Exponential Backoff
    
    @Test("Exponential backoff increases delay")
    func exponentialBackoff() async throws {
        let retryManager = ExtractionRetryManager()
        let counter = AttemptCounter()
        
        do {
            _ = try await retryManager.withRetry(
                operationID: "test-backoff",
                configuration: ExtractionRetryManager.RetryConfiguration(
                    maxAttempts: 3,
                    initialDelay: 1.0,
                    maxDelay: 10.0,
                    backoffMultiplier: 2.0,
                    useJitter: false
                )
            ) {
                await counter.increment()
                throw URLError(.networkConnectionLost)
            }
        } catch {
            // Expected to fail after all retries
        }
        
        let finalCount = await counter.count
        #expect(finalCount == 3)
        
        // Check delays between attempts
        let attemptTimes = await counter.timestamps
        if attemptTimes.count >= 2 {
            let delay1 = attemptTimes[1].timeIntervalSince(attemptTimes[0])
            #expect(delay1 >= 0.9 && delay1 <= 1.2, "First retry should wait ~1s")
        }
        
        if attemptTimes.count >= 3 {
            let delay2 = attemptTimes[2].timeIntervalSince(attemptTimes[1])
            #expect(delay2 >= 1.9 && delay2 <= 2.2, "Second retry should wait ~2s (exponential)")
        }
    }
    
    // MARK: - Max Attempts
    
    @Test("Respects max attempts limit")
    func respectsMaxAttempts() async throws {
        let retryManager = ExtractionRetryManager()
        let counter = AttemptCounter()
        
        do {
            _ = try await retryManager.withRetry(
                operationID: "test-max-attempts",
                configuration: ExtractionRetryManager.RetryConfiguration(
                    maxAttempts: 5,
                    initialDelay: 0.1,
                    maxDelay: 1.0,
                    backoffMultiplier: 2.0,
                    useJitter: false
                )
            ) {
                await counter.increment()
                throw URLError(.networkConnectionLost)
            }
        } catch {
            // Expected to fail
        }
        
        let finalCount = await counter.count
        #expect(finalCount == 5, "Should have attempted exactly 5 times")
    }
    
    // MARK: - Statistics
    
    @Test("Tracks retry statistics")
    func tracksStatistics() async throws {
        let retryManager = ExtractionRetryManager()
        let operationID = "test-stats"
        
        do {
            _ = try await retryManager.withRetry(
                operationID: operationID,
                configuration: ExtractionRetryManager.RetryConfiguration(
                    maxAttempts: 3,
                    initialDelay: 0.1,
                    maxDelay: 1.0,
                    backoffMultiplier: 2.0,
                    useJitter: false
                )
            ) {
                throw URLError(.networkConnectionLost)
            }
        } catch {
            // Expected to fail
        }
        
        let stats = await retryManager.getRetryStats(operationID: operationID)
        let totalAttempts = await stats.totalAttempts
        let lastAttempt = await stats.lastAttempt
        let historyCount = await stats.attemptHistory.count
        
        #expect(totalAttempts == 3)
        #expect(lastAttempt != nil)
        #expect(historyCount == 3)
    }
    
    // MARK: - Error Type Classification
    
    @Test("Classifies different error types correctly")
    func classifiesErrorTypes() async throws {
        let retryManager = ExtractionRetryManager()
        
        // Network errors should retry
        let counter1 = AttemptCounter()
        do {
            _ = try await retryManager.withRetry(
                operationID: "classify-1",
                configuration: ExtractionRetryManager.RetryConfiguration(maxAttempts: 2, initialDelay: 0.1, maxDelay: 1.0, backoffMultiplier: 2.0, useJitter: false)
            ) {
                await counter1.increment()
                throw URLError(.cannotFindHost)
            }
        } catch {}
        let count1 = await counter1.count
        #expect(count1 == 2, "Network errors should retry")
        
        // Server errors (5xx) should retry
        let counter2 = AttemptCounter()
        do {
            _ = try await retryManager.withRetry(
                operationID: "classify-2",
                configuration: ExtractionRetryManager.RetryConfiguration(maxAttempts: 2, initialDelay: 0.1, maxDelay: 1.0, backoffMultiplier: 2.0, useJitter: false)
            ) {
                await counter2.increment()
                throw WebExtractionError.httpError(statusCode: 500)
            }
        } catch {}
        let count2 = await counter2.count
        #expect(count2 == 2, "Server errors should retry")
        
        // 403 should not retry
        let counter3 = AttemptCounter()
        do {
            _ = try await retryManager.withRetry(
                operationID: "classify-3",
                configuration: ExtractionRetryManager.RetryConfiguration(maxAttempts: 3, initialDelay: 0.1, maxDelay: 1.0, backoffMultiplier: 2.0, useJitter: false)
            ) {
                await counter3.increment()
                throw WebExtractionError.httpError(statusCode: 403)
            }
        } catch {}
        let count3 = await counter3.count
        #expect(count3 == 1, "403 errors should not retry")
    }
}
