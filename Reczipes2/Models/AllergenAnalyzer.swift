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
    func analyzeRecipe(_ recipe: RecipeX, profile: UserAllergenProfile) -> RecipeAllergenScore {
        let detectedAllergens = detectAllergens(in: recipe, sensitivities: profile.sensitivities)
        let score = calculateScore(from: detectedAllergens)
        let maxSeverity = detectedAllergens.map { $0.sensitivity.severity }.max(by: { $0.scoreMultiplier < $1.scoreMultiplier })
        
        return RecipeAllergenScore(
            recipeID: recipe.safeID,
            score: score,
            detectedAllergens: detectedAllergens,
            isSafe: detectedAllergens.isEmpty,
            severityLevel: maxSeverity
        )
    }
    
    /// Analyze multiple recipes and return scores
    func analyzeRecipes(_ recipes: [RecipeX], profile: UserAllergenProfile) -> [UUID: RecipeAllergenScore] {
        var scores: [UUID: RecipeAllergenScore] = [:]
        for recipe in recipes {
            scores[recipe.safeID] = analyzeRecipe(recipe, profile: profile)
        }
        return scores
    }
    
    // MARK: - Detection Logic
    
    /// Detect allergens in a recipe based on user sensitivities
    private func detectAllergens(in recipe: RecipeX, sensitivities: [UserSensitivity]) -> [DetectedAllergen] {
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
    private func extractIngredientNames(from recipe: RecipeX) -> [String] {
        var names: [String] = []
        
        // Decode ingredient sections from JSON data
        guard let sectionsData = recipe.ingredientSectionsData,
              let sections = try? JSONDecoder().decode([IngredientSection].self, from: sectionsData) else {
            return []
        }
        
        for section in sections {
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
    
    /// Find ingredients that match sensitivity keywords using intelligent word-boundary matching
    private func findMatchingIngredients(ingredientNames: [String], keywords: [String]) -> [String] {
        var matched: [String] = []
        
        for ingredientName in ingredientNames {
            let lowercasedName = ingredientName.lowercased()
            
            for keyword in keywords {
                let lowercasedKeyword = keyword.lowercased()
                
                // Use intelligent matching that considers word boundaries and context
                if intelligentMatch(ingredient: lowercasedName, keyword: lowercasedKeyword) {
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
    
    /// Intelligent matching that considers word boundaries and common false positives
    private func intelligentMatch(ingredient: String, keyword: String) -> Bool {
        // First check for exact match
        if ingredient == keyword {
            return true
        }
        
        // Check if keyword is a complete word within the ingredient
        // This prevents "cream" from matching "cream of tartar" or "creamer"
        let wordPattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
        
        if let regex = try? NSRegularExpression(pattern: wordPattern, options: .caseInsensitive) {
            let range = NSRange(ingredient.startIndex..., in: ingredient)
            if regex.firstMatch(in: ingredient, range: range) != nil {
                // Found a word boundary match, but check for known exceptions
                if isKnownException(ingredient: ingredient, keyword: keyword) {
                    return false
                }
                return true
            }
        }
        
        // For multi-word keywords (e.g., "soy sauce"), check if all words are present
        let keywordWords = keyword.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if keywordWords.count > 1 {
            // All words must be present for multi-word match
            let allWordsPresent = keywordWords.allSatisfy { word in
                ingredient.range(of: "\\b\(NSRegularExpression.escapedPattern(for: word))\\b",
                                options: [.regularExpression, .caseInsensitive]) != nil
            }
            
            if allWordsPresent && !isKnownException(ingredient: ingredient, keyword: keyword) {
                return true
            }
        }
        
        return false
    }
    
    /// Check for known exceptions where ingredients shouldn't match despite containing the keyword
    private func isKnownException(ingredient: String, keyword: String) -> Bool {
        // Dictionary of exceptions: [keyword: [ingredients that shouldn't match]]
        let exceptions: [String: [String]] = [
            // Dairy exceptions
            "cream": [
                "cream of tartar", "cream of wheat", "tartar", "creamer", "creamery",
                "non-dairy", "dairy-free", "sour cream substitute", "cream substitute",
                "ice cream substitute", "whipped topping", "cool whip", "coconut cream",
                "cashew cream", "oat cream", "creamed corn"
            ],
            "milk": [
                "coconut milk", "almond milk", "oat milk", "soy milk", "rice milk",
                "milkweed", "plant-based milk", "non-dairy", "cashew milk", "hemp milk",
                "macadamia milk", "flax milk", "pea milk", "quinoa milk", "hazelnut milk",
                "tiger nut milk", "milk substitute", "milk thistle", "milkshake mix"
            ],
            "butter": [
                "peanut butter", "almond butter", "sunflower butter", "cocoa butter",
                "shea butter", "cashew butter", "tahini butter", "nut butter", "sunbutter",
                "apple butter", "pumpkin butter", "cookie butter", "speculoos", "butternut",
                "buttercup", "buttercream frosting", "vegan butter", "margarine",
                "earth balance", "ghee substitute", "nut-free butter", "seed butter"
            ],
            "cheese": [
                "vegan cheese", "cashew cheese", "nutritional yeast", "dairy-free",
                "plant-based cheese", "nut cheese", "tofu cheese", "cheesecloth",
                "cheese substitute", "non-dairy cheese", "almond cheese"
            ],
            "yogurt": [
                "coconut yogurt", "almond yogurt", "soy yogurt", "cashew yogurt",
                "oat yogurt", "non-dairy yogurt", "plant-based yogurt"
            ],
            "dairy": [
                "non-dairy", "dairy-free", "plant-based", "vegan alternative"
            ],
            
            // Egg exceptions
            "egg": [
                "eggplant", "nutmeg", "egg substitute", "flax egg", "chia egg",
                "egg replacer", "aquafaba", "egg-free", "vegan egg", "just egg",
                "ener-g", "egg white substitute", "meringue powder"
            ],
            
            // Nut exceptions
            "nut": [
                "coconut", "butternut", "donut", "doughnut", "chestnut water",
                "nutmeg", "nut-free", "hazelnut coffee", "nutritional yeast",
                "nutrient", "minute rice", "coconut aminos"
            ],
            "peanut": [
                "peanut-free", "nut-free", "peanut substitute", "sun butter",
                "sunflower seed butter", "pea protein"
            ],
            "almond": [
                "almond-free", "nut-free", "almond extract substitute"
            ],
            "walnut": [
                "nut-free", "walnut substitute"
            ],
            "cashew": [
                "nut-free", "cashew substitute", "sunflower seed alternative"
            ],
            
            // Wheat/Gluten exceptions
            "wheat": [
                "buckwheat", "wheatgrass", "wheat-free", "gluten-free",
                "wheat substitute", "wheat alternative"
            ],
            "flour": [
                "buckwheat", "almond flour", "coconut flour", "rice flour",
                "chickpea flour", "tapioca flour", "cassava flour", "cauliflower",
                "oat flour", "potato flour", "cornflour", "corn flour", "sorghum flour",
                "teff flour", "millet flour", "amaranth flour", "quinoa flour",
                "arrowroot flour", "tiger nut flour", "gluten-free flour",
                "all-purpose gluten-free", "1-to-1 flour", "sunflower seed flour"
            ],
            "gluten": [
                "gluten-free", "glutinous rice", "gluten substitute", "xanthan gum"
            ],
            "bread": [
                "gluten-free bread", "breadfruit", "bread substitute", "lettuce wrap",
                "corn tortilla", "rice paper", "cloud bread", "ezekiel bread"
            ],
            
            // Soy exceptions
            "soy": [
                "soy-free", "non-soy", "soy substitute", "coconut aminos",
                "liquid aminos alternative"
            ],
            "soy sauce": [
                "soy-free sauce", "non-soy sauce", "coconut aminos", "tamari alternative",
                "liquid aminos substitute", "worcestershire substitute"
            ],
            "tofu": [
                "tofu substitute", "chickpea tofu", "burmese tofu", "soy-free"
            ],
            "edamame": [
                "soy-free", "edamame substitute"
            ],
            
            // Seafood exceptions
            "fish": [
                "shellfish", "starfish", "fish sauce substitute", "vegan fish sauce",
                "seaweed", "dulse", "fish-free", "fishwort", "fish pepper"
            ],
            "fish sauce": [
                "fish sauce substitute", "vegan fish sauce", "soy sauce alternative",
                "coconut aminos", "seaweed broth"
            ],
            "shrimp": [
                "shrimp substitute", "hearts of palm", "lion's mane mushroom",
                "shrimp-free"
            ],
            "crab": [
                "imitation crab", "hearts of palm", "jackfruit", "crab substitute",
                "crabapple", "crab-free"
            ],
            "shellfish": [
                "shellfish-free", "shellfish substitute"
            ],
            "oyster": [
                "oyster sauce substitute", "mushroom sauce", "oyster-free",
                "oyster mushroom", "king oyster mushroom"
            ],
            
            // Meat exceptions
            "meat": [
                "meatless", "plant-based meat", "impossible meat", "beyond meat",
                "meat substitute", "meat alternative", "vegan meat", "sweetmeat",
                "mincemeat", "nut meat", "coconut meat"
            ],
            "beef": [
                "beef substitute", "impossible beef", "beyond beef", "jackfruit",
                "mushroom", "lentil", "beefy seasoning"
            ],
            "chicken": [
                "chicken substitute", "chicken-style seasoning", "jackfruit",
                "seitan", "tofu", "chickpea", "chick pea"
            ],
            "pork": [
                "pork substitute", "mushroom bacon", "coconut bacon", "tempeh bacon"
            ],
            "bacon": [
                "tempeh bacon", "coconut bacon", "mushroom bacon", "eggplant bacon",
                "carrot bacon", "rice paper bacon", "bacon bits substitute"
            ],
            "ham": [
                "vegan ham", "ham substitute", "hamantaschen", "hampton"
            ],
            "gelatin": [
                "agar agar", "carrageenan", "pectin", "gelatin substitute",
                "vegan gelatin", "vegetarian gelatin", "kosher gelatin"
            ],
            
            // Chocolate/Cocoa exceptions
            "chocolate": [
                "white chocolate", "carob", "chocolate substitute", "cacao nibs alternative"
            ],
            "cocoa": [
                "carob powder", "cocoa substitute", "coconut"
            ],
            
            // Corn exceptions
            "corn": [
                "cornflower", "popcorn kernel", "baby corn", "corn-free",
                "unicorn", "acorn", "cornish", "corner", "corny"
            ],
            "cornstarch": [
                "arrowroot", "tapioca starch", "potato starch", "cornstarch substitute"
            ],
            
            // Sugar exceptions
            "sugar": [
                "sugar-free", "date sugar", "coconut sugar", "monk fruit",
                "stevia", "erythritol", "xylitol", "sugar substitute",
                "sugar alternative", "sugarsnap pea", "blood sugar"
            ],
            "honey": [
                "maple syrup", "agave", "date syrup", "honey substitute",
                "vegan honey", "bee-free honey", "honeydew", "honeycomb cereal"
            ],
            
            // Oil exceptions
            "oil": [
                "oil-free", "oil substitute", "applesauce", "aquafaba",
                "foil", "soil", "boil", "toil", "embroil"
            ],
            
            // Onion/Garlic exceptions (FODMAP-related)
            "onion": [
                "onion powder substitute", "asafoetida", "green onion tops only",
                "scallion greens", "chives", "onion-infused oil", "onion-free"
            ],
            "garlic": [
                "garlic-infused oil", "asafoetida", "garlic scape", "garlic powder substitute",
                "garlic-free", "garlic greens"
            ],
            
            // Legume exceptions
            "bean": [
                "green bean", "coffee bean", "vanilla bean", "cocoa bean",
                "bean sprout", "jelly bean", "beanstalk"
            ],
            "pea": [
                "chickpea", "pea protein", "peach", "pear", "pearl", "peanut",
                "appearance", "speak", "repeat"
            ],
            "lentil": [
                "lentil-free", "lentil substitute"
            ],
            
            // Nightshade exceptions
            "tomato": [
                "tomato-free", "tomato substitute", "beet", "carrot sauce"
            ],
            "pepper": [
                "peppermint", "peppercorn", "black pepper", "white pepper",
                "pink peppercorn", "szechuan pepper", "pepper substitute"
            ],
            "potato": [
                "sweet potato", "potato-free", "cauliflower substitute",
                "potato starch"
            ],
            
            // Seed exceptions
            "seed": [
                "seeded", "seedless", "flaxseed meal", "chia seed substitute",
                "sesame-free", "seed-free", "linseed"
            ],
            "sesame": [
                "sesame-free", "tahini-free", "sesame substitute", "sunflower seed butter"
            ],
            
            // Yeast exceptions
            "yeast": [
                "yeast-free", "nutritional yeast", "baking powder", "baking soda"
            ],
            
            // Vinegar exceptions
            "vinegar": [
                "vinegar-free", "lemon juice", "citric acid", "vinegar substitute"
            ],
            
            // Spice exceptions
            "cinnamon": [
                "cinnamon substitute", "cassia", "cinnamon-free"
            ],
            "ginger": [
                "ginger substitute", "gingerbread", "ginger ale", "gingerly"
            ],
            
            // Alcohol exceptions
            "wine": [
                "wine vinegar", "grape juice", "wine substitute", "alcohol-free wine",
                "swine", "twine", "entwine"
            ],
            "beer": [
                "root beer", "ginger beer", "non-alcoholic beer", "beer substitute"
            ],
            "rum": [
                "rum extract", "rum flavoring", "alcohol-free", "bread crumb",
                "crumb", "drum", "forum", "spectrum"
            ],
            
            // Caffeine exceptions
            "coffee": [
                "coffee substitute", "chicory coffee", "dandelion coffee",
                "coffee-free", "decaf", "toffee"
            ],
            "tea": [
                "herbal tea", "rooibos", "caffeine-free tea", "team", "steak",
                "steam", "teach", "tear", "tease"
            ],
            
            // Histamine/FODMAP-related
            "fermented": [
                "non-fermented", "fresh alternative", "fermented-free"
            ],
            "aged": [
                "fresh alternative", "young cheese", "un-aged", "teenage"
            ],
            
            // Additive exceptions
            "msg": [
                "msg-free", "no msg", "nutritional yeast", "mushroom powder"
            ],
            "preservative": [
                "preservative-free", "no preservatives", "natural"
            ],
            
            // Cooking method exceptions (for recipe context)
            "fried": [
                "air-fried", "baked", "dried", "fried alternative"
            ],
            "deep fried": [
                "air-fried", "oven-baked", "pan-fried with less oil"
            ]
        ]
        
        guard let exceptionList = exceptions[keyword] else {
            // If no specific exception list, still check for general negation patterns
            return checkForNegationPatterns(ingredient: ingredient, keyword: keyword)
        }
        
        // Check if ingredient matches any exception pattern
        for exception in exceptionList {
            if ingredient.contains(exception) {
                return true
            }
        }
        
        // Additional check: if ingredient explicitly says it's free of the allergen
        return checkForNegationPatterns(ingredient: ingredient, keyword: keyword)
    }
    
    /// Check if an ingredient has negation patterns indicating it's free of the allergen
    private func checkForNegationPatterns(ingredient: String, keyword: String) -> Bool {
        // For multi-word keywords (e.g., "soy sauce"), check if the first word has a negation
        let keywordWords = keyword.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let firstWord = keywordWords.first ?? keyword
        
        // Common negation patterns
        let freePatterns = [
            "\(firstWord)-free",
            "non-\(firstWord)",
            "free of \(firstWord)",
            "without \(firstWord)",
            "no \(firstWord)"
        ]
        
        for pattern in freePatterns {
            if ingredient.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    /// Find which keywords caused the matches (using intelligent matching, not simple contains)
    private func findMatchedKeywords(matchedIngredients: [String], keywords: [String]) -> [String] {
        var matchedKeywords: Set<String> = []
        
        for ingredient in matchedIngredients {
            let lowercasedIngredient = ingredient.lowercased()
            for keyword in keywords {
                let lowercasedKeyword = keyword.lowercased()
                
                // Use the same intelligent matching logic to find which keywords actually matched
                if intelligentMatch(ingredient: lowercasedIngredient, keyword: lowercasedKeyword) {
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
    func filterSafeRecipes(_ recipes: [RecipeX], profile: UserAllergenProfile) -> [RecipeX] {
        recipes.filter { recipe in
            let score = analyzeRecipe(recipe, profile: profile)
            return score.isSafe
        }
    }
    
    /// Sort recipes by safety score (safest first)
    func sortRecipesBySafety(_ recipes: [RecipeX], profile: UserAllergenProfile) -> [RecipeX] {
        let scores = analyzeRecipes(recipes, profile: profile)
        return recipes.sorted { recipe1, recipe2 in
            let score1 = scores[recipe1.safeID]?.score ?? Double.infinity
            let score2 = scores[recipe2.safeID]?.score ?? Double.infinity
            return score1 < score2
        }
    }
    
    // MARK: - Claude API Enhancement
    
    /// Generate a prompt for Claude to analyze ingredients more deeply
    func generateClaudeAnalysisPrompt(recipe: RecipeX, profile: UserAllergenProfile) -> String {
        let sensitivityList = profile.sensitivities.map { "\($0.name) (\($0.severity.rawValue))" }.joined(separator: ", ")
        
        // Build comprehensive ingredient list with full context
        var ingredientList: [String] = []
        
        // Decode ingredient sections from JSON data
        if let sectionsData = recipe.ingredientSectionsData,
           let sections = try? JSONDecoder().decode([IngredientSection].self, from: sectionsData) {
            for section in sections {
                for ingredient in section.ingredients {
                    var fullIngredient = ""
                    if let qty = ingredient.quantity { fullIngredient += qty + " " }
                    if let unit = ingredient.unit { fullIngredient += unit + " " }
                    fullIngredient += ingredient.name
                    if let prep = ingredient.preparation { fullIngredient += ", " + prep }
                    ingredientList.append(fullIngredient.trimmingCharacters(in: .whitespaces))
                }
            }
        }
        
        let ingredients = ingredientList.joined(separator: "\n- ")
        
        // Check if FODMAP sensitivity is included
        let hasFODMAPSensitivity = profile.sensitivities.contains { sensitivity in
            sensitivity.intolerance == .fodmap
        }
        
        var prompt = """
        Analyze the following recipe ingredients for potential allergens and sensitivities.
        
        User's sensitivities: \(sensitivityList)
        
        Recipe: \(recipe.safeTitle)
        
        Ingredients (with full context):
        - \(ingredients)
        
        **CRITICAL ANALYSIS INSTRUCTIONS:**
        
        You MUST consider the COMPLETE ingredient phrase, not just individual words. This is essential for accurate allergen detection.
        
        Common mistakes to AVOID:
        - "cream of tartar" is NOT dairy cream (it's potassium bitartrate, completely dairy-free)
        - "coconut milk" is NOT dairy milk (it's plant-based and dairy-free)
        - "almond milk", "oat milk", "soy milk" are NOT dairy (they're dairy alternatives)
        - "peanut butter" is NOT dairy butter (contains peanuts but NO dairy)
        - "almond butter", "cashew butter" are NOT dairy (they're nut butters)
        - "cocoa butter" is NOT dairy butter (it's from cacao beans)
        - "butternut squash" has NO relation to dairy butter
        - "eggplant" does NOT contain eggs
        - "buckwheat" does NOT contain wheat (it's gluten-free)
        - "nutmeg" is NOT a nut (it's a spice, safe for nut allergies)
        
        Analysis requirements:
        1. **Context-Aware Matching**: Always consider the complete ingredient phrase
        2. **Hidden Allergens**: Identify ingredients where allergens may be truly present (e.g., "whey" contains dairy, "worcestershire sauce" often contains fish)
        3. **Qualifiers Matter**: Pay attention to "vegan", "dairy-free", "lactose-free", "gluten-free" modifiers
        4. **Cross-Contamination**: Note if an ingredient may have been processed in facilities with allergens
        5. **Severity Assessment**: Rate the actual risk, not just presence of a word
        6. **Substitutions**: Provide practical alternatives that maintain recipe integrity
        7. **Overall Safety Score**: 0-10 scale (0=completely safe, 10=extremely dangerous for this user)
        
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
            - Context matters: "cream" in "cream of tartar" is NOT a FODMAP issue
            
            Include FODMAP analysis in your response with specific alternatives from Monash University data.
            """
        }
        
        prompt += """
        
        
        Format your response as JSON:
        {
            "detectedAllergens": [
                {
                    "name": "allergen name",
                    "foundIn": ["complete ingredient phrase", "another ingredient"],
                    "severity": "mild|moderate|severe",
                    "hidden": true/false,
                    "substitutions": ["alternative1", "alternative2"],
                    "confidenceScore": 0.0-1.0,
                    "reasoning": "Brief explanation of why this is a match"
                }
            ],
            "falsePositivesAvoided": [
                {
                    "ingredient": "complete phrase",
                    "whyNotAnAllergen": "explanation"
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
                        "ingredient": "complete ingredient phrase",
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
        
        Remember:
        - Always analyze the COMPLETE ingredient phrase
        - Consider context and modifiers
        - Only flag true allergen matches, not word similarities
        - Reference Monash University FODMAP data for FODMAP sensitivities
        - Consider cross-contamination risks
        - Be specific about portion sizes for FODMAP foods when relevant
        - Include confidence scores to help users understand certainty
        """
        
        return prompt
    }
}
