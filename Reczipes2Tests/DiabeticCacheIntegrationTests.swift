//
//  DiabeticCacheIntegrationTests.swift
//  Reczipes2Tests
//
//  Integration tests for diabetic analysis with AI service mocking
//  Created on 1/3/26.
//

import Testing
import Foundation
import OSLog
import SwiftUI
@testable import Reczipes2

@Suite("Diabetic Analysis Integration Tests")
struct DiabeticCacheIntegrationTests {
    
    private let logger = Logger(subsystem: "com.reczipes.tests", category: "integration")
    
    // MARK: - Mock AI Service
    
    /// Mock service that simulates AI analysis responses
    actor MockDiabeticAnalysisService {
        private var callCount = 0
        private var shouldFail = false
        private var responseDelay: TimeInterval = 0.1
        
        func setFailureMode(_ shouldFail: Bool) {
            self.shouldFail = shouldFail
        }
        
        func setResponseDelay(_ delay: TimeInterval) {
            self.responseDelay = delay
        }
        
        func getCallCount() -> Int {
            return callCount
        }
        
        func resetCallCount() {
            callCount = 0
        }
        
        /// Simulates analyzing a recipe using its ID
        func analyzeDiabeticInfo(recipeId: UUID, recipeTitle: String) async throws -> DiabeticInfo {
            callCount += 1
            
            // Simulate network delay
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
            
            if shouldFail {
                throw AnalysisError.serviceUnavailable
            }
            
            // Generate mock analysis based on recipe ID
            return await createMockAnalysis(recipeId: recipeId)
        }
        
        @MainActor
        private func createMockAnalysis(recipeId: UUID) -> DiabeticInfo {
            DiabeticInfo(
                id: UUID(),
                recipeId: recipeId,
                lastUpdated: Date(),
                estimatedGlycemicLoad: GlycemicLoad(value: 15.5, explanation: "Moderate glycemic load"),
                glycemicImpactFactors: [
                    GlycemicFactor(
                        ingredient: "flour",
                        glycemicIndex: 70,
                        impact: .high,
                        explanation: "White flour has a high glycemic index"
                    )
                ],
                carbCount: CarbInfo(totalCarbs: 45, netCarbs: 40, fiber: 5),
                fiberContent: FiberInfo(total: 5, soluble: 2, insoluble: 3),
                sugarBreakdown: SugarBreakdown(total: 8, added: 5, natural: 3),
                diabeticGuidance: [
                    GuidanceItem(
                        title: "Moderate Portion",
                        summary: "This recipe contains moderate carbs",
                        detailedExplanation: "Consider portion control with this recipe",
                        icon: "fork.knife",
                        color: .orange
                    )
                ],
                portionRecommendations: PortionGuidance(
                    recommendedServing: "1/4 recipe",
                    servingSize: "125g",
                    explanation: "Keep portions small to manage blood sugar"
                ),
                substitutionSuggestions: [
                    IngredientSubstitution(
                        originalIngredient: "white flour",
                        substitute: "almond flour",
                        reason: "Lower glycemic index",
                        nutritionalImprovement: "Reduces carbs by 30%"
                    )
                ],
                sources: [
                    VerifiedSource(
                        title: "ADA Nutritional Guidelines",
                        organization: "American Diabetes Association",
                        credibilityScore: .high
                    )
                ],
                consensusLevel: .strongConsensus
            )
        }
        
        enum AnalysisError: Error {
            case serviceUnavailable
            case invalidResponse
        }
    }
    
    // MARK: - Cache Manager Helper
    
    /// Helper class to manage cache operations
    class CacheManager {
        private var cache: [UUID: CachedDiabeticAnalysis] = [:]
        
        func getCachedAnalysis(for recipe: Recipe) -> CachedDiabeticAnalysis? {
            return cache[recipe.id]
        }
        
        func setCachedAnalysis(_ cached: CachedDiabeticAnalysis, for recipe: Recipe) {
            cache[recipe.id] = cached
        }
        
        func clearCache() {
            cache.removeAll()
        }
        
        func cacheCount() -> Int {
            return cache.count
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("First analysis creates cache entry")
    func firstAnalysisCreatesCache() async throws {
        logger.info("🧪 Testing first analysis creates cache")
        
        let service = MockDiabeticAnalysisService()
        let cacheManager = CacheManager()
        
        // Create recipe
        let recipe = createTestRecipe(title: "Test Recipe 1")
        logger.info("📝 Created recipe: \(recipe.title)")
        
        // Verify no cache exists
        #expect(cacheManager.getCachedAnalysis(for: recipe) == nil, "Should have no cache initially")
        
        // Perform analysis (pass IDs, not the Recipe object)
        logger.info("🔄 Performing analysis...")
        let analysis = try await service.analyzeDiabeticInfo(recipeId: recipe.id, recipeTitle: recipe.title)
        logger.info("✅ Analysis completed")
        
        // Create cache entry
        let cached = try await CachedDiabeticAnalysis.create(from: analysis, recipe: recipe)
        cacheManager.setCachedAnalysis(cached, for: recipe)
        logger.info("💾 Cache entry created")
        
        // Verify cache was created
        let retrievedCache = cacheManager.getCachedAnalysis(for: recipe)
        #expect(retrievedCache != nil, "Cache should be created")
        #expect(retrievedCache?.recipeId == recipe.id, "Cache should match recipe ID")
        #expect(await service.getCallCount() == 1, "Service should be called once")
        
        logger.info("✅ Test passed: Cache created successfully")
    }
    
    @Test("Cached analysis is reused when valid")
    func cachedAnalysisReused() async throws {
        logger.info("🧪 Testing cache reuse")
        
        let service = MockDiabeticAnalysisService()
        let cacheManager = CacheManager()
        
        let recipe = createTestRecipe(title: "Test Recipe 2")
        
        // First analysis (pass IDs, not Recipe object)
        logger.info("🔄 First analysis...")
        let analysis1 = try await service.analyzeDiabeticInfo(recipeId: recipe.id, recipeTitle: recipe.title)
        let cached = try await CachedDiabeticAnalysis.create(from: analysis1, recipe: recipe)
        cacheManager.setCachedAnalysis(cached, for: recipe)
        logger.info("💾 First analysis cached")
        
        // Check if cache is valid
        if let existingCache = cacheManager.getCachedAnalysis(for: recipe),
           existingCache.isValid(for: recipe) {
            logger.info("✅ Cache is valid, skipping second analysis")
            
            // Verify service was only called once
            let callCount = await service.getCallCount()
            #expect(callCount == 1, "Service should only be called once when cache is valid")
        } else {
            Issue.record("Cache should be valid but was not")
        }
        
        logger.info("✅ Test passed: Cache was reused")
    }
    
    @Test("Cache invalidation triggers new analysis")
    func cacheInvalidationTriggersAnalysis() async throws {
        logger.info("🧪 Testing cache invalidation")
        
        let service = MockDiabeticAnalysisService()
        let cacheManager = CacheManager()
        
        let recipe = createTestRecipe(title: "Test Recipe 3")
        
        // First analysis (pass IDs, not Recipe object)
        logger.info("🔄 First analysis...")
        let analysis1 = try await service.analyzeDiabeticInfo(recipeId: recipe.id, recipeTitle: recipe.title)
        let cached = try await CachedDiabeticAnalysis.create(from: analysis1, recipe: recipe)
        cacheManager.setCachedAnalysis(cached, for: recipe)
        let initialCallCount = await service.getCallCount()
        logger.info("💾 First analysis cached, call count: \(initialCallCount)")
        
        // Modify recipe ingredients
        logger.info("🔧 Modifying recipe ingredients...")
        let newIngredients = await [
            IngredientSection(ingredients: [
                Ingredient(quantity: "3", unit: "cups", name: "sugar") // Changed!
            ])
        ]
        let newData = try JSONEncoder().encode(newIngredients)
        recipe.updateIngredients(newData)
        logger.info("✅ Recipe modified, version: \(recipe.currentVersion)")
        
        // Check if cache is still valid (it should not be)
        if let existingCache = cacheManager.getCachedAnalysis(for: recipe) {
            let isValid = existingCache.isValid(for: recipe)
            logger.info("🔍 Cache valid: \(isValid)")
            #expect(!isValid, "Cache should be invalid after ingredient change")
            
            if !isValid {
                // Perform new analysis (pass IDs, not Recipe object)
                logger.info("🔄 Cache invalid, performing new analysis...")
                let analysis2 = try await service.analyzeDiabeticInfo(recipeId: recipe.id, recipeTitle: recipe.title)
                let newCached = try await CachedDiabeticAnalysis.create(from: analysis2, recipe: recipe)
                cacheManager.setCachedAnalysis(newCached, for: recipe)
                logger.info("💾 New analysis cached")
            }
        }
        
        let finalCallCount = await service.getCallCount()
        logger.info("📊 Final call count: \(finalCallCount)")
        #expect(finalCallCount == 2, "Service should be called twice after invalidation")
        
        logger.info("✅ Test passed: Cache invalidation triggered new analysis")
    }
    
    @Test("Multiple recipes have independent caches")
    func independentCaches() async throws {
        logger.info("🧪 Testing independent caches")
        
        let service = MockDiabeticAnalysisService()
        let cacheManager = CacheManager()
        
        // Create multiple recipes
        let recipe1 = createTestRecipe(title: "Recipe 1")
        let recipe2 = createTestRecipe(title: "Recipe 2")
        let recipe3 = createTestRecipe(title: "Recipe 3")
        
        logger.info("📝 Created 3 recipes")
        
        // Analyze all recipes (pass IDs, not Recipe objects)
        logger.info("🔄 Analyzing all recipes...")
        for recipe in [recipe1, recipe2, recipe3] {
            let analysis = try await service.analyzeDiabeticInfo(recipeId: recipe.id, recipeTitle: recipe.title)
            let cached = try await CachedDiabeticAnalysis.create(from: analysis, recipe: recipe)
            cacheManager.setCachedAnalysis(cached, for: recipe)
        }
        
        logger.info("💾 All recipes analyzed and cached")
        
        // Verify each has independent cache
        #expect(cacheManager.cacheCount() == 3, "Should have 3 cache entries")
        #expect(cacheManager.getCachedAnalysis(for: recipe1)?.recipeId == recipe1.id)
        #expect(cacheManager.getCachedAnalysis(for: recipe2)?.recipeId == recipe2.id)
        #expect(cacheManager.getCachedAnalysis(for: recipe3)?.recipeId == recipe3.id)
        
        // Modify one recipe
        logger.info("🔧 Modifying recipe 2...")
        let newIngredients = await [
            IngredientSection(ingredients: [
                Ingredient(quantity: "5", unit: "cups", name: "modified ingredient")
            ])
        ]
        let newData = try JSONEncoder().encode(newIngredients)
        recipe2.updateIngredients(newData)
        
        // Verify only recipe 2's cache is invalid
        let cache1 = cacheManager.getCachedAnalysis(for: recipe1)
        let cache2 = cacheManager.getCachedAnalysis(for: recipe2)
        let cache3 = cacheManager.getCachedAnalysis(for: recipe3)
        
        #expect(cache1?.isValid(for: recipe1) == true, "Recipe 1 cache should still be valid")
        #expect(cache2?.isValid(for: recipe2) == false, "Recipe 2 cache should be invalid")
        #expect(cache3?.isValid(for: recipe3) == true, "Recipe 3 cache should still be valid")
        
        logger.info("✅ Test passed: Caches are independent")
    }
    
    @Test("Analysis failure handling")
    func analysisFailureHandling() async throws {
        logger.info("🧪 Testing analysis failure handling")
        
        let service = MockDiabeticAnalysisService()
        await service.setFailureMode(true)
        
        let recipe = createTestRecipe(title: "Test Recipe Failure")
        
        logger.info("🔄 Attempting analysis with failure mode enabled...")
        
        do {
            _ = try await service.analyzeDiabeticInfo(recipeId: recipe.id, recipeTitle: recipe.title)
            Issue.record("Analysis should have failed but succeeded")
        } catch {
            logger.info("✅ Analysis failed as expected: \(error)")
            #expect(error is MockDiabeticAnalysisService.AnalysisError)
        }
        
        logger.info("✅ Test passed: Failure handled correctly")
    }
    
    @Test("Concurrent analysis requests")
    func concurrentAnalysisRequests() async throws {
        logger.info("🧪 Testing concurrent analysis requests")
        
        let service = MockDiabeticAnalysisService()
        await service.setResponseDelay(0.5) // Longer delay to test concurrency
        
        let recipes = (1...5).map { createTestRecipe(title: "Recipe \($0)") }
        
        logger.info("📝 Created 5 recipes for concurrent analysis")
        
        // Create a sendable representation of recipe data
        struct RecipeData: Sendable {
            let id: UUID
            let title: String
        }
        
        let recipeDataList = recipes.map { RecipeData(id: $0.id, title: $0.title) }
        
        // Analyze all concurrently using the sendable data
        logger.info("🔄 Starting concurrent analyses...")
        let startTime = Date()
        
        try await withThrowingTaskGroup(of: (UUID, DiabeticInfo).self) { group in
            for recipeData in recipeDataList {
                group.addTask {
                    let analysis = try await service.analyzeDiabeticInfo(recipeId: recipeData.id, recipeTitle: recipeData.title)
                    return (recipeData.id, analysis)
                }
            }
            
            var results: [(UUID, DiabeticInfo)] = []
            for try await result in group {
                results.append(result)
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("✅ All analyses completed in \(String(format: "%.2f", duration)) seconds")
            
            // Verify all completed
            #expect(results.count == 5, "All 5 analyses should complete")
            
            // Should take around 0.5 seconds (concurrent) not 2.5 seconds (sequential)
            #expect(duration < 1.5, "Concurrent execution should be faster than sequential")
        }
        
        let finalCallCount = await service.getCallCount()
        #expect(finalCallCount == 5, "Service should be called 5 times")
        
        logger.info("✅ Test passed: Concurrent requests handled correctly")
    }
    
    // MARK: - Helper Methods
    
    private func createTestRecipe(title: String) -> Recipe {
        let ingredients = [
            IngredientSection(ingredients: [
                Ingredient(quantity: "2", unit: "cups", name: "flour"),
                Ingredient(quantity: "1", unit: "cup", name: "sugar")
            ])
        ]
        
        let instructions = [
            InstructionSection(steps: [
                InstructionStep(text: "Mix ingredients")
            ])
        ]
        
        let recipeModel = RecipeModel(
            title: title,
            ingredientSections: ingredients,
            instructionSections: instructions
        )
        
        return Recipe(from: recipeModel)
    }
}
