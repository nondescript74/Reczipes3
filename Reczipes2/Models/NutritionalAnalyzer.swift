//
//  NutritionalAnalyzer.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 1/2/26.
//  Analyzes recipes against user nutritional goals
//

import Foundation
import RegexBuilder

/// Analyzes recipes for how well they fit within user's daily nutritional goals
class NutritionalAnalyzer {
    
    static let shared = NutritionalAnalyzer()
    
    private init() {}
    
    // MARK: - Analysis Methods
    
    /// Analyze a single recipe against user's nutritional goals
    /// Returns a score indicating how well the recipe fits the goals
    func analyzeRecipe(_ recipe: RecipeX, goals: NutritionalGoals, servings: Int = 1) -> NutritionalScore {
        // Extract nutrition info from recipe
        let nutrition = extractNutrition(from: recipe, servings: servings)
        
        // Calculate per-serving values as percentage of daily goals
        var alerts: [NutritionAlert] = []
        var percentages: [String: Double] = [:]
        
        // Check calories
        if let recipeCalories = nutrition.calories, let dailyCalories = goals.dailyCalories {
            let percentage = (recipeCalories / dailyCalories) * 100
            percentages["calories"] = percentage
            
            if percentage > 50 {
                alerts.append(NutritionAlert(
                    nutrient: "Calories",
                    severity: .high,
                    message: "This recipe contains \(Int(percentage))% of your daily calorie goal (\(Int(recipeCalories)) of \(Int(dailyCalories)) kcal)",
                    recommendation: "Consider splitting into multiple meals or reducing portion size"
                ))
            } else if percentage > 33 {
                alerts.append(NutritionAlert(
                    nutrient: "Calories",
                    severity: .moderate,
                    message: "This recipe contains \(Int(percentage))% of your daily calorie goal",
                    recommendation: "This is appropriate for a main meal"
                ))
            }
        }
        
        // Check sodium (critical for heart health and diabetes)
        if let recipeSodium = nutrition.sodium, let dailySodium = goals.dailySodium {
            let percentage = (recipeSodium / dailySodium) * 100
            percentages["sodium"] = percentage
            
            if percentage > 50 {
                alerts.append(NutritionAlert(
                    nutrient: "Sodium",
                    severity: .high,
                    message: "⚠️ Very high sodium: \(Int(recipeSodium))mg (\(Int(percentage))% of daily limit)",
                    recommendation: "Reduce salt, use herbs and spices for flavor instead"
                ))
            } else if percentage > 33 {
                alerts.append(NutritionAlert(
                    nutrient: "Sodium",
                    severity: .moderate,
                    message: "Moderate sodium: \(Int(recipeSodium))mg (\(Int(percentage))% of daily limit)",
                    recommendation: "Be mindful of sodium in other meals today"
                ))
            }
        }
        
        // Check saturated fat
        if let recipeSatFat = nutrition.saturatedFat, let dailySatFat = goals.dailySaturatedFat {
            let percentage = (recipeSatFat / dailySatFat) * 100
            percentages["saturatedFat"] = percentage
            
            if percentage > 50 {
                alerts.append(NutritionAlert(
                    nutrient: "Saturated Fat",
                    severity: .high,
                    message: "⚠️ High saturated fat: \(Int(recipeSatFat))g (\(Int(percentage))% of daily limit)",
                    recommendation: "Choose lean proteins and reduce butter/cream"
                ))
            }
        }
        
        // Check sugar
        if let recipeSugar = nutrition.sugar, let dailySugar = goals.dailySugar {
            let percentage = (recipeSugar / dailySugar) * 100
            percentages["sugar"] = percentage
            
            if percentage > 50 {
                alerts.append(NutritionAlert(
                    nutrient: "Sugar",
                    severity: .high,
                    message: "⚠️ High sugar: \(Int(recipeSugar))g (\(Int(percentage))% of daily limit)",
                    recommendation: "Reduce added sugars, use natural sweeteners"
                ))
            }
        }
        
        // Check fiber (good to be high!)
        if let recipeFiber = nutrition.fiber, let dailyFiber = goals.dailyFiber {
            let percentage = (recipeFiber / dailyFiber) * 100
            percentages["fiber"] = percentage
            
            if percentage > 25 {
                alerts.append(NutritionAlert(
                    nutrient: "Fiber",
                    severity: .positive,
                    message: "✅ Excellent fiber content: \(Int(recipeFiber))g (\(Int(percentage))% of daily goal)",
                    recommendation: "Great for digestive health and blood sugar control"
                ))
            }
        }
        
        // Calculate overall compatibility score
        let compatibilityScore = calculateCompatibilityScore(percentages: percentages, alerts: alerts)
        
        return NutritionalScore(
            recipeID: recipe.safeID,
            nutrition: nutrition,
            dailyPercentages: percentages,
            alerts: alerts,
            compatibilityScore: compatibilityScore,
            servings: servings
        )
    }
    
    /// Analyze multiple recipes
    func analyzeRecipes(_ recipes: [RecipeX], goals: NutritionalGoals) -> [UUID: NutritionalScore] {
        var scores: [UUID: NutritionalScore] = [:]
        for recipe in recipes {
            scores[recipe.safeID] = analyzeRecipe(recipe, goals: goals)
        }
        return scores
    }
    
    // MARK: - Filtering & Sorting
    
    /// Filter recipes that fit well within nutritional goals
    func filterCompatibleRecipes(_ recipes: [RecipeX], goals: NutritionalGoals, minimumScore: Double = 60.0) -> [RecipeX] {
        recipes.filter { recipe in
            let score = analyzeRecipe(recipe, goals: goals)
            return score.compatibilityScore >= minimumScore
        }
    }
    
    /// Sort recipes by compatibility with nutritional goals (best fit first)
    func sortRecipesByCompatibility(_ recipes: [RecipeX], goals: NutritionalGoals) -> [RecipeX] {
        let scores = analyzeRecipes(recipes, goals: goals)
        return recipes.sorted { recipe1, recipe2 in
            let score1 = scores[recipe1.safeID]?.compatibilityScore ?? 0
            let score2 = scores[recipe2.safeID]?.compatibilityScore ?? 0
            return score1 > score2
        }
    }
    
    // MARK: - Helper Methods
    
    /// Extract nutritional information from a recipe
    /// This uses keyword matching and estimation
    /// TODO: Integrate with Claude API for more accurate extraction
    private func extractNutrition(from recipe: RecipeX, servings: Int) -> RecipeNutrition {
        // Get servings from recipe or use parameter
        let recipeServings = extractServingsCount(from: recipe) ?? servings
        
        // Try to extract explicit nutrition info from recipe notes/headers
        if let explicit = parseExplicitNutrition(from: recipe) {
            return explicit.perServing(recipeServings)
        }
        
        // Fallback: Estimate from ingredients (basic)
        return estimateNutrition(from: recipe, servings: recipeServings)
    }
    
    /// Try to parse explicit nutrition information from recipe
    private func parseExplicitNutrition(from recipe: RecipeX) -> RecipeNutrition? {
        // Decode notes from JSON data
        var notesText = ""
        if let notesData = recipe.notesData,
           let notes = try? JSONDecoder().decode([RecipeNote].self, from: notesData) {
            notesText = notes.map { $0.text }.joined(separator: " ")
        }
        
        // Look in headerNotes and notes for nutrition facts
        let searchText = [recipe.headerNotes, notesText]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        
        // Look for patterns like "Calories: 350" or "350 calories"
        var nutrition = RecipeNutrition()
        
        // Calories
        if let caloriesMatch = searchText.range(of: #"(\d+)\s*(kcal|calories|cal)"#, options: String.CompareOptions.regularExpression) {
            let match = String(searchText[caloriesMatch])
            if let value = match.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap({ Int($0) }).first {
                nutrition.calories = Double(value)
            }
        }
        
        // Sodium
        if let sodiumMatch = searchText.range(of: #"(\d+)\s*mg\s*sodium"#, options: String.CompareOptions.regularExpression) {
            let match = String(searchText[sodiumMatch])
            if let value = match.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap({ Int($0) }).first {
                nutrition.sodium = Double(value)
            }
        }
        
        // If we found at least one value, return the nutrition info
        if nutrition.calories != nil || nutrition.sodium != nil {
            return nutrition
        }
        
        return nil
    }
    
    /// Estimate nutrition from ingredients (basic keyword matching)
    private func estimateNutrition(from recipe: RecipeX, servings: Int) -> RecipeNutrition {
        var estimatedCalories = 0.0
        var estimatedSodium = 0.0
        var estimatedSugar = 0.0
        var estimatedFiber = 0.0
        var estimatedSatFat = 0.0
        
        // Extract all ingredients
        let ingredients = extractIngredients(from: recipe)
        
        for ingredient in ingredients {
            let lower = ingredient.lowercased()
            
            // High-calorie ingredients
            if lower.contains("butter") || lower.contains("oil") {
                estimatedCalories += 100
                estimatedSatFat += 5
            }
            if lower.contains("sugar") || lower.contains("honey") {
                estimatedCalories += 50
                estimatedSugar += 12
            }
            if lower.contains("cream") || lower.contains("cheese") {
                estimatedCalories += 80
                estimatedSatFat += 4
                estimatedSodium += 100
            }
            
            // Sodium sources
            if lower.contains("salt") {
                estimatedSodium += 300
            }
            if lower.contains("soy sauce") {
                estimatedSodium += 500
            }
            if lower.contains("bacon") || lower.contains("ham") {
                estimatedSodium += 400
                estimatedSatFat += 3
            }
            
            // Fiber sources
            if lower.contains("whole wheat") || lower.contains("oats") || lower.contains("beans") {
                estimatedFiber += 3
            }
            if lower.contains("vegetable") || lower.contains("broccoli") || lower.contains("spinach") {
                estimatedFiber += 2
            }
            
            // Protein sources
            if lower.contains("chicken") || lower.contains("turkey") {
                estimatedCalories += 50
            }
            if lower.contains("beef") || lower.contains("pork") {
                estimatedCalories += 70
                estimatedSatFat += 3
            }
        }
        
        // Divide by servings for per-serving values
        let servingDivisor = max(Double(servings), 1.0)
        
        return RecipeNutrition(
            calories: estimatedCalories / servingDivisor,
            protein: nil, // Not estimated yet
            carbohydrates: nil,
            totalFat: nil,
            saturatedFat: estimatedSatFat / servingDivisor,
            transFat: nil,
            sodium: estimatedSodium / servingDivisor,
            potassium: nil,
            calcium: nil,
            sugar: estimatedSugar / servingDivisor,
            addedSugar: nil,
            fiber: estimatedFiber / servingDivisor,
            cholesterol: nil,
            isEstimated: true
        )
    }
    
    /// Extract servings count from recipe yield
    private func extractServingsCount(from recipe: RecipeX) -> Int? {
        guard let yieldString = recipe.recipeYield else { return nil }
        
        let numbers = yieldString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        
        return numbers.first
    }
    
    /// Extract ingredient names from recipe
    private func extractIngredients(from recipe: RecipeX) -> [String] {
        var ingredients: [String] = []
        
        // Decode ingredient sections from JSON data
        guard let sectionsData = recipe.ingredientSectionsData,
              let sections = try? JSONDecoder().decode([IngredientSection].self, from: sectionsData) else {
            return []
        }
        
        for section in sections {
            for ingredient in section.ingredients {
                ingredients.append(ingredient.name)
            }
        }
        
        return ingredients
    }
    
    /// Calculate overall compatibility score (0-100)
    private func calculateCompatibilityScore(percentages: [String: Double], alerts: [NutritionAlert]) -> Double {
        var score = 100.0
        
        // Penalize for high alerts
        let highAlerts = alerts.filter { $0.severity == .high }
        score -= Double(highAlerts.count) * 20
        
        // Penalize for moderate alerts
        let moderateAlerts = alerts.filter { $0.severity == .moderate }
        score -= Double(moderateAlerts.count) * 10
        
        // Bonus for positive alerts (like high fiber)
        let positiveAlerts = alerts.filter { $0.severity == .positive }
        score += Double(positiveAlerts.count) * 10
        
        // Ensure score stays in 0-100 range
        return max(0, min(100, score))
    }
}

// MARK: - Nutrition Models

/// Nutritional information for a recipe (per serving)
struct RecipeNutrition: Sendable {
    var calories: Double?
    var protein: Double?
    var carbohydrates: Double?
    var totalFat: Double?
    var saturatedFat: Double?
    var transFat: Double?
    var sodium: Double?
    var potassium: Double?
    var calcium: Double?
    var sugar: Double?
    var addedSugar: Double?
    var fiber: Double?
    var cholesterol: Double?
    var isEstimated: Bool = false
    
    /// Calculate per-serving values
    func perServing(_ servings: Int) -> RecipeNutrition {
        let divisor = max(Double(servings), 1.0)
        
        return RecipeNutrition(
            calories: calories.map { $0 / divisor },
            protein: protein.map { $0 / divisor },
            carbohydrates: carbohydrates.map { $0 / divisor },
            totalFat: totalFat.map { $0 / divisor },
            saturatedFat: saturatedFat.map { $0 / divisor },
            transFat: transFat.map { $0 / divisor },
            sodium: sodium.map { $0 / divisor },
            potassium: potassium.map { $0 / divisor },
            calcium: calcium.map { $0 / divisor },
            sugar: sugar.map { $0 / divisor },
            addedSugar: addedSugar.map { $0 / divisor },
            fiber: fiber.map { $0 / divisor },
            cholesterol: cholesterol.map { $0 / divisor },
            isEstimated: isEstimated
        )
    }
}

/// Analysis result for a recipe
struct NutritionalScore: Identifiable, Sendable {
    let id = UUID()
    let recipeID: UUID
    let nutrition: RecipeNutrition
    let dailyPercentages: [String: Double] // e.g., ["calories": 33.5, "sodium": 45.0]
    let alerts: [NutritionAlert]
    let compatibilityScore: Double // 0-100, higher is better fit
    let servings: Int
    
    /// Check if recipe fits well within goals
    var isCompatible: Bool {
        compatibilityScore >= 60.0
    }
    
    /// Get severity level
    var overallSeverity: AlertSeverity {
        if alerts.contains(where: { $0.severity == .high }) {
            return .high
        } else if alerts.contains(where: { $0.severity == .moderate }) {
            return .moderate
        } else if alerts.contains(where: { $0.severity == .positive }) {
            return .positive
        }
        return .low
    }
}

/// Alert for a specific nutrient
struct NutritionAlert: Identifiable, Sendable {
    let id = UUID()
    let nutrient: String
    let severity: AlertSeverity
    let message: String
    let recommendation: String?
}

/// Severity levels for nutrition alerts
enum AlertSeverity: String, Sendable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case positive = "Positive" // Good things like high fiber
    
    var icon: String {
        switch self {
        case .low: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .positive: return "star.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "yellow"
        case .high: return "red"
        case .positive: return "blue"
        }
    }
}

// MARK: - Future Enhancements

/*
 TODO: Enhanced Nutrition Extraction
 ===================================
 
 1. CLAUDE API INTEGRATION
    - Send recipe to Claude with prompt: "Extract nutrition facts per serving"
    - Parse structured nutrition data from response
    - Much more accurate than keyword matching
 
 2. NUTRITION DATABASE
    - Integrate USDA FoodData Central API
    - Match ingredients to database entries
    - Calculate totals from individual ingredients
 
 3. USER INPUT
    - Allow users to manually enter nutrition facts
    - Save to recipe for future reference
    - Display "verified" badge
 
 4. RECIPE SCALING
    - Adjust nutrition values when servings change
    - Show nutrition for different portion sizes
 
 5. MEAL PLANNING
    - Track daily totals across multiple recipes
    - Show remaining daily allowances
    - Suggest recipes to meet goals
 
 6. BARCODE SCANNING
    - Scan packaged ingredients
    - Auto-populate nutrition from product database
 */
