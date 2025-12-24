//
//  RecipeSearchService.swift
//  Reczipes2
//
//  Created for comprehensive recipe searching
//

import Foundation

/// A service that provides comprehensive recipe search functionality
class RecipeSearchService {
    
    /// Search criteria for filtering recipes
    struct SearchCriteria {
        var searchText: String = ""
        var dishTypes: Set<DishType> = []
        var maxCookingTime: Int? = nil // in minutes
        var author: String? = nil
        
        var isEmpty: Bool {
            searchText.isEmpty && dishTypes.isEmpty && maxCookingTime == nil && author == nil
        }
    }
    
    /// Common dish types that can be detected in recipes
    enum DishType: String, CaseIterable, Identifiable {
        case soup
        case salad
        case appetizer
        case mainCourse = "main course"
        case sideDish = "side dish"
        case dessert
        case breakfast
        case beverage
        case sauce
        case bread
        case pasta
        case pizza
        case sandwich
        case casserole
        case stew
        case curry
        case stirFry = "stir-fry"
        case grill
        case bake
        case roast
        
        var id: String { rawValue }
        
        var displayName: String {
            rawValue.capitalized
        }
        
        /// Keywords that help identify this dish type
        var keywords: [String] {
            switch self {
            case .soup:
                return ["soup", "broth", "chowder", "bisque", "stew", "gazpacho"]
            case .salad:
                return ["salad", "slaw", "greens"]
            case .appetizer:
                return ["appetizer", "starter", "hors d'oeuvre", "finger food", "dip"]
            case .mainCourse:
                return ["main", "entrée", "entree", "dinner"]
            case .sideDish:
                return ["side dish", "side", "accompaniment"]
            case .dessert:
                return ["dessert", "cake", "cookie", "pie", "tart", "pudding", "ice cream", "brownie"]
            case .breakfast:
                return ["breakfast", "pancake", "waffle", "omelet", "omelette", "cereal", "muffin"]
            case .beverage:
                return ["beverage", "drink", "smoothie", "juice", "cocktail", "coffee", "tea"]
            case .sauce:
                return ["sauce", "gravy", "dressing", "marinade", "glaze"]
            case .bread:
                return ["bread", "roll", "biscuit", "scone", "baguette", "loaf"]
            case .pasta:
                return ["pasta", "spaghetti", "lasagna", "ravioli", "penne", "fettuccine", "noodle"]
            case .pizza:
                return ["pizza", "flatbread", "calzone"]
            case .sandwich:
                return ["sandwich", "burger", "wrap", "panini", "sub"]
            case .casserole:
                return ["casserole", "bake", "gratin"]
            case .stew:
                return ["stew", "ragout", "goulash"]
            case .curry:
                return ["curry", "masala", "korma", "vindaloo"]
            case .stirFry:
                return ["stir-fry", "stir fry", "wok"]
            case .grill:
                return ["grilled", "grill", "bbq", "barbecue"]
            case .bake:
                return ["baked", "baking", "oven-baked"]
            case .roast:
                return ["roast", "roasted"]
            }
        }
    }
    
    /// Search results with relevance scoring
    struct SearchResult {
        let recipe: RecipeModel
        let score: Double
        let matchedFields: [MatchField]
        
        enum MatchField: Equatable {
            case title
            case author
            case ingredient(name: String)
            case dishType(DishType)
            case cookingTime
            case headerNotes
            case instructions
        }
    }
    
    // MARK: - Search Methods
    
    /// Search recipes based on the provided criteria
    /// - Parameters:
    ///   - recipes: The recipes to search through
    ///   - criteria: The search criteria to apply
    /// - Returns: An array of search results, sorted by relevance score (highest first)
    func search(recipes: [RecipeModel], criteria: SearchCriteria) -> [SearchResult] {
        guard !criteria.isEmpty else {
            // Return all recipes with default score when no criteria
            return recipes.map { SearchResult(recipe: $0, score: 1.0, matchedFields: []) }
        }
        
        var results: [SearchResult] = []
        
        for recipe in recipes {
            var score: Double = 0
            var matchedFields: [SearchResult.MatchField] = []
            
            // Search text matching (title, ingredients, instructions, notes)
            if !criteria.searchText.isEmpty {
                let textMatches = searchText(in: recipe, searchText: criteria.searchText)
                score += textMatches.score
                matchedFields.append(contentsOf: textMatches.fields)
            }
            
            // Dish type matching
            if !criteria.dishTypes.isEmpty {
                let dishTypeMatches = matchDishTypes(in: recipe, types: criteria.dishTypes)
                if !dishTypeMatches.isEmpty {
                    score += 10.0 * Double(dishTypeMatches.count)
                    matchedFields.append(contentsOf: dishTypeMatches.map { .dishType($0) })
                }
            }
            
            // Cooking time matching
            if let maxTime = criteria.maxCookingTime {
                if let recipeTime = extractCookingTime(from: recipe), recipeTime <= maxTime {
                    score += 5.0
                    matchedFields.append(.cookingTime)
                }
            }
            
            // Author matching
            if let authorQuery = criteria.author, !authorQuery.isEmpty {
                if let reference = recipe.reference, reference.localizedCaseInsensitiveContains(authorQuery) {
                    score += 8.0
                    matchedFields.append(.author)
                }
            }
            
            // Only include recipes with matches
            if score > 0 {
                results.append(SearchResult(recipe: recipe, score: score, matchedFields: matchedFields))
            }
        }
        
        // Sort by score (highest first)
        return results.sorted { $0.score > $1.score }
    }
    
    /// Convenience method to get just the recipes without search metadata
    func searchRecipes(recipes: [RecipeModel], criteria: SearchCriteria) -> [RecipeModel] {
        search(recipes: recipes, criteria: criteria).map { $0.recipe }
    }
    
    // MARK: - Private Helper Methods
    
    private func searchText(in recipe: RecipeModel, searchText: String) -> (score: Double, fields: [SearchResult.MatchField]) {
        var score: Double = 0
        var fields: [SearchResult.MatchField] = []
        let query = searchText.lowercased()
        
        // Title matching (highest weight)
        if recipe.title.localizedCaseInsensitiveContains(query) {
            score += 10.0
            fields.append(.title)
        }
        
        // Header notes matching
        if let headerNotes = recipe.headerNotes, headerNotes.localizedCaseInsensitiveContains(query) {
            score += 6.0
            fields.append(.headerNotes)
        }
        
        // Ingredient matching
        for section in recipe.ingredientSections {
            for ingredient in section.ingredients {
                if ingredient.name.localizedCaseInsensitiveContains(query) {
                    score += 5.0
                    if !fields.contains(where: { 
                        if case .ingredient(let name) = $0, name == ingredient.name {
                            return true
                        }
                        return false
                    }) {
                        fields.append(.ingredient(name: ingredient.name))
                    }
                }
                
                // Also check preparation notes
                if let prep = ingredient.preparation, prep.localizedCaseInsensitiveContains(query) {
                    score += 2.0
                    if !fields.contains(where: { 
                        if case .ingredient(let name) = $0, name == ingredient.name {
                            return true
                        }
                        return false
                    }) {
                        fields.append(.ingredient(name: ingredient.name))
                    }
                }
            }
        }
        
        // Instruction matching
        for section in recipe.instructionSections {
            for step in section.steps {
                if step.text.localizedCaseInsensitiveContains(query) {
                    score += 3.0
                    if !fields.contains(.instructions) {
                        fields.append(.instructions)
                    }
                }
            }
        }
        
        // Reference/author matching
        if let reference = recipe.reference, reference.localizedCaseInsensitiveContains(query) {
            score += 4.0
            fields.append(.author)
        }
        
        return (score, fields)
    }
    
    private func matchDishTypes(in recipe: RecipeModel, types: Set<DishType>) -> [DishType] {
        var matches: [DishType] = []
        
        for dishType in types {
            if detectDishType(recipe, type: dishType) {
                matches.append(dishType)
            }
        }
        
        return matches
    }
    
    /// Detect if a recipe matches a specific dish type
    private func detectDishType(_ recipe: RecipeModel, type: DishType) -> Bool {
        let searchableText = [
            recipe.title,
            recipe.headerNotes ?? "",
            recipe.notes.map { $0.text }.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        
        // Check if any of the dish type's keywords appear in the recipe
        return type.keywords.contains { keyword in
            searchableText.contains(keyword.lowercased())
        }
    }
    
    /// Extract cooking time from recipe (in minutes)
    private func extractCookingTime(from recipe: RecipeModel) -> Int? {
        // Look for time mentions in header notes, instructions, and notes
        let searchableText = [
            recipe.headerNotes ?? "",
            recipe.instructionSections.flatMap { $0.steps.map { $0.text } }.joined(separator: " "),
            recipe.notes.map { $0.text }.joined(separator: " ")
        ].joined(separator: " ")
        
        return parseTimeFromText(searchableText)
    }
    
    /// Parse time mentions from text (e.g., "30 minutes", "1 hour", "2 hrs")
    private func parseTimeFromText(_ text: String) -> Int? {
        let lowercased = text.lowercased()
        var totalMinutes: Int? = nil
        
        // Patterns to match time expressions
        let patterns = [
            // "30 minutes", "30 mins", "30 min"
            (regex: #"(\d+)\s*(minute|minutes|min|mins)"#, multiplier: 1),
            // "2 hours", "2 hrs", "2 hr"
            (regex: #"(\d+)\s*(hour|hours|hr|hrs)"#, multiplier: 60),
            // "1.5 hours"
            (regex: #"(\d+\.?\d*)\s*(hour|hours|hr|hrs)"#, multiplier: 60)
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern.regex, options: .caseInsensitive) {
                let nsRange = NSRange(lowercased.startIndex..<lowercased.endIndex, in: lowercased)
                if let match = regex.firstMatch(in: lowercased, options: [], range: nsRange) {
                    if let numberRange = Range(match.range(at: 1), in: lowercased) {
                        let numberString = String(lowercased[numberRange])
                        if let number = Double(numberString) {
                            let minutes = Int(number * Double(pattern.multiplier))
                            if let existing = totalMinutes {
                                totalMinutes = min(existing, minutes)
                            } else {
                                totalMinutes = minutes
                            }
                        }
                    }
                }
            }
        }
        
        return totalMinutes
    }
    
    // MARK: - Helper Methods for UI
    
    /// Get all detected dish types for a recipe
    func detectAllDishTypes(for recipe: RecipeModel) -> [DishType] {
        DishType.allCases.filter { detectDishType(recipe, type: $0) }
    }
    
    /// Get cooking time display string for a recipe
    func getCookingTimeString(for recipe: RecipeModel) -> String? {
        guard let minutes = extractCookingTime(from: recipe) else { return nil }
        
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(remainingMinutes) min"
            }
        }
    }
}


