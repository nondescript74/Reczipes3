//
//  AllergenAnalyzer.swift
//  Reczipes2
//
//  Created on 12/17/25.
//

import Foundation

/// Analyzes recipes for allergens and calculates risk scores based on user profiles
class AllergenAnalyzer {
    
    static let shared = AllergenAnalyzer()
    
    private init() {}
    
    // MARK: - Main Analysis Methods
    
    /// Analyze a recipe against a user's allergen profile
    func analyzeRecipe(_ recipe: RecipeModel, profile: UserAllergenProfile) -> RecipeAllergenScore {
        let detectedAllergens = detectAllergens(in: recipe, sensitivities: profile.sensitivities)
        let score = calculateScore(from: detectedAllergens)
        let maxSeverity = detectedAllergens.map { $0.sensitivity.severity }.max(by: { $0.scoreMultiplier < $1.scoreMultiplier })
        
        return RecipeAllergenScore(
            recipeID: recipe.id,
            score: score,
            detectedAllergens: detectedAllergens,
            isSafe: detectedAllergens.isEmpty,
            severityLevel: maxSeverity
        )
    }
    
    /// Analyze multiple recipes and return scores
    func analyzeRecipes(_ recipes: [RecipeModel], profile: UserAllergenProfile) -> [UUID: RecipeAllergenScore] {
        var scores: [UUID: RecipeAllergenScore] = [:]
        for recipe in recipes {
            scores[recipe.id] = analyzeRecipe(recipe, profile: profile)
        }
        return scores
    }
    
    // MARK: - Detection Logic
    
    /// Detect allergens in a recipe based on user sensitivities
    private func detectAllergens(in recipe: RecipeModel, sensitivities: [UserSensitivity]) -> [DetectedAllergen] {
        var detected: [DetectedAllergen] = []
        
        // Extract all ingredient names from the recipe
        let ingredientNames = extractIngredientNames(from: recipe)
        
        // Check each sensitivity
        for sensitivity in sensitivities {
            let matchedIngredients = findMatchingIngredients(
                ingredientNames: ingredientNames,
                keywords: sensitivity.keywords
            )
            
            if !matchedIngredients.isEmpty {
                let matchedKeywords = findMatchedKeywords(
                    matchedIngredients: matchedIngredients,
                    keywords: sensitivity.keywords
                )
                
                detected.append(DetectedAllergen(
                    sensitivity: sensitivity,
                    matchedIngredients: matchedIngredients,
                    matchedKeywords: matchedKeywords
                ))
            }
        }
        
        return detected
    }
    
    /// Extract all ingredient names from a recipe (includes name and preparation)
    private func extractIngredientNames(from recipe: RecipeModel) -> [String] {
        var names: [String] = []
        
        for section in recipe.ingredientSections {
            for ingredient in section.ingredients {
                // Add the main ingredient name
                names.append(ingredient.name)
                
                // Add preparation if it exists (e.g., "chopped", "melted butter")
                if let prep = ingredient.preparation {
                    names.append(prep)
                }
                
                // Add unit if it might contain info (e.g., "can tomato sauce")
                if let unit = ingredient.unit {
                    names.append(unit)
                }
            }
        }
        
        return names
    }
    
    /// Find ingredients that match sensitivity keywords
    private func findMatchingIngredients(ingredientNames: [String], keywords: [String]) -> [String] {
        var matched: [String] = []
        
        for ingredientName in ingredientNames {
            let lowercasedName = ingredientName.lowercased()
            
            for keyword in keywords {
                let lowercasedKeyword = keyword.lowercased()
                
                // Check if the ingredient contains the keyword
                if lowercasedName.contains(lowercasedKeyword) {
                    // Avoid duplicates
                    if !matched.contains(ingredientName) {
                        matched.append(ingredientName)
                    }
                    break // Found a match, no need to check other keywords for this ingredient
                }
            }
        }
        
        return matched
    }
    
    /// Find which keywords caused the matches
    private func findMatchedKeywords(matchedIngredients: [String], keywords: [String]) -> [String] {
        var matchedKeywords: Set<String> = []
        
        for ingredient in matchedIngredients {
            let lowercasedIngredient = ingredient.lowercased()
            for keyword in keywords {
                if lowercasedIngredient.contains(keyword.lowercased()) {
                    matchedKeywords.insert(keyword)
                }
            }
        }
        
        return Array(matchedKeywords).sorted()
    }
    
    // MARK: - Score Calculation
    
    /// Calculate overall risk score based on detected allergens
    private func calculateScore(from detectedAllergens: [DetectedAllergen]) -> Double {
        var totalScore: Double = 0
        
        for detected in detectedAllergens {
            // Base score: 1 point per matched ingredient
            let baseScore = Double(detected.matchedIngredients.count)
            
            // Apply severity multiplier
            let severityMultiplier = detected.sensitivity.severity.scoreMultiplier
            
            totalScore += baseScore * severityMultiplier
        }
        
        return totalScore
    }
    
    // MARK: - Filtering & Sorting
    
    /// Filter recipes to only show safe ones
    func filterSafeRecipes(_ recipes: [RecipeModel], profile: UserAllergenProfile) -> [RecipeModel] {
        recipes.filter { recipe in
            let score = analyzeRecipe(recipe, profile: profile)
            return score.isSafe
        }
    }
    
    /// Sort recipes by safety score (safest first)
    func sortRecipesBySafety(_ recipes: [RecipeModel], profile: UserAllergenProfile) -> [RecipeModel] {
        let scores = analyzeRecipes(recipes, profile: profile)
        return recipes.sorted { recipe1, recipe2 in
            let score1 = scores[recipe1.id]?.score ?? Double.infinity
            let score2 = scores[recipe2.id]?.score ?? Double.infinity
            return score1 < score2
        }
    }
    
    // MARK: - Claude API Enhancement
    
    /// Generate a prompt for Claude to analyze ingredients more deeply
    func generateClaudeAnalysisPrompt(recipe: RecipeModel, profile: UserAllergenProfile) -> String {
        let sensitivityList = profile.sensitivities.map { "\($0.name) (\($0.severity.rawValue))" }.joined(separator: ", ")
        let ingredients = recipe.ingredientSections.flatMap { $0.ingredients }.map { $0.name }.joined(separator: ", ")
        
        // Check if FODMAP sensitivity is included
        let hasFODMAPSensitivity = profile.sensitivities.contains { sensitivity in
            sensitivity.intolerance == .fodmap
        }
        
        var prompt = """
        Analyze the following recipe ingredients for potential allergens and sensitivities.
        
        User's sensitivities: \(sensitivityList)
        
        Recipe: \(recipe.title)
        Ingredients: \(ingredients)
        
        Please:
        1. Identify any ingredients that contain or may contain the user's allergens/sensitivities
        2. Note any hidden allergens (e.g., whey in processed foods, gluten in soy sauce)
        3. Assess the severity risk for each detected allergen
        4. Suggest substitutions where possible
        5. Rate the overall recipe safety from 0-10 (0=safe, 10=extremely risky)
        """
        
        // Add FODMAP-specific analysis if needed
        if hasFODMAPSensitivity {
            prompt += """
            
            
            **IMPORTANT: FODMAP Analysis Required**
            
            Since the user has FODMAP sensitivity, perform a comprehensive FODMAP analysis based on Monash University research:
            
            Check for the four FODMAP categories:
            1. **Oligosaccharides** (Fructans & GOS): wheat, rye, barley, onions, garlic, beans, lentils, chickpeas, cashews, pistachios
            2. **Disaccharides** (Lactose): milk, cream, yogurt, soft cheeses, ice cream
            3. **Monosaccharides** (Excess Fructose): honey, agave, apples, pears, mangoes, high-fructose corn syrup
            4. **Polyols** (Sugar Alcohols): sorbitol, mannitol, xylitol, apples, pears, stone fruits, mushrooms, cauliflower
            
            Important FODMAP considerations:
            - Green onion/scallion tops are LOW FODMAP (white parts are HIGH)
            - Garlic-infused oil is LOW FODMAP if garlic solids are removed
            - Hard cheeses (cheddar, parmesan) are LOW FODMAP
            - Lactose-free dairy is LOW FODMAP
            - Some foods are low FODMAP in small portions but high in large portions
            
            Include FODMAP analysis in your response with specific alternatives from Monash University data.
            """
        }
        
        prompt += """
        
        
        Format your response as JSON:
        {
            "detectedAllergens": [
                {
                    "name": "allergen name",
                    "foundIn": ["ingredient1", "ingredient2"],
                    "severity": "mild|moderate|severe",
                    "hidden": true/false,
                    "substitutions": ["alternative1", "alternative2"]
                }
            ],
            "overallSafetyScore": 0-10,
            "recommendation": "safe|caution|avoid",
            "notes": "Additional helpful information"
        """
        
        if hasFODMAPSensitivity {
            prompt += """
            ,
            "fodmapAnalysis": {
                "overallLevel": "low|moderate|high",
                "categoryBreakdown": {
                    "oligosaccharides": {"level": "low|moderate|high", "ingredients": []},
                    "disaccharides": {"level": "low|moderate|high", "ingredients": []},
                    "monosaccharides": {"level": "low|moderate|high", "ingredients": []},
                    "polyols": {"level": "low|moderate|high", "ingredients": []}
                },
                "detectedFODMAPs": [
                    {
                        "ingredient": "name",
                        "categories": ["oligosaccharides"],
                        "portionMatters": true/false,
                        "lowFODMAPAlternative": "suggestion"
                    }
                ],
                "modificationTips": ["tip1", "tip2"],
                "monashGuidance": "Additional notes from Monash University FODMAP research"
            }
            """
        }
        
        prompt += """
        
        }
        
        Always reference the most current Monash University FODMAP data when analyzing FODMAP sensitivities.
        Consider cross-contamination and hidden sources of allergens.
        Be specific about portion sizes for FODMAP foods when relevant.
        """
        
        return prompt
    }
}
