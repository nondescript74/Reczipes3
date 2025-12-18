//
//  AllergenProfile.swift
//  Reczipes2
//
//  Created on 12/17/25.
//

import Foundation
import SwiftData

// MARK: - Allergen & Sensitivity Types

enum FoodAllergen: String, Codable, CaseIterable, Identifiable {
    case milk = "Milk"
    case eggs = "Eggs"
    case peanuts = "Peanuts"
    case treeNuts = "Tree Nuts"
    case wheat = "Wheat"
    case soy = "Soy"
    case fish = "Fish"
    case shellfish = "Shellfish"
    case sesame = "Sesame"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .milk: return "🥛"
        case .eggs: return "🥚"
        case .peanuts: return "🥜"
        case .treeNuts: return "🌰"
        case .wheat: return "🌾"
        case .soy: return "🫘"
        case .fish: return "🐟"
        case .shellfish: return "🦐"
        case .sesame: return "🫘"
        }
    }
    
    var category: String { "Big 9 Allergens" }
    
    // Common ingredient names that contain this allergen
    var ingredientKeywords: [String] {
        switch self {
        case .milk:
            return ["milk", "cream", "butter", "cheese", "yogurt", "whey", "casein", "lactose", "ghee", "buttermilk", "sour cream", "ice cream", "half-and-half", "evaporated milk", "condensed milk", "dairy"]
        case .eggs:
            return ["egg", "eggs", "mayonnaise", "meringue", "albumin", "lysozyme", "ovalbumin"]
        case .peanuts:
            return ["peanut", "peanuts", "peanut butter", "groundnut", "goober"]
        case .treeNuts:
            return ["almond", "almonds", "cashew", "cashews", "walnut", "walnuts", "pecan", "pecans", "pistachio", "pistachios", "hazelnut", "hazelnuts", "macadamia", "pine nut", "pine nuts", "brazil nut"]
        case .wheat:
            return ["wheat", "flour", "bread", "pasta", "bulgur", "couscous", "farina", "semolina", "spelt", "kamut", "durum"]
        case .soy:
            return ["soy", "soya", "tofu", "edamame", "miso", "tempeh", "soy sauce", "tamari", "lecithin"]
        case .fish:
            return ["fish", "salmon", "tuna", "cod", "halibut", "bass", "trout", "anchovy", "anchovies", "sardine", "sardines", "worcestershire"]
        case .shellfish:
            return ["shrimp", "crab", "lobster", "crayfish", "prawn", "prawns", "clam", "clams", "oyster", "oysters", "mussel", "mussels", "scallop", "scallops"]
        case .sesame:
            return ["sesame", "tahini", "sesame oil", "sesame seed"]
        }
    }
}

enum FoodIntolerance: String, Codable, CaseIterable, Identifiable {
    case gluten = "Gluten"
    case lactose = "Lactose"
    case caffeine = "Caffeine"
    case histamine = "Histamine"
    case salicylates = "Salicylates"
    case sulfites = "Sulfites"
    case fodmap = "FODMAPs"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .gluten: return "🌾"
        case .lactose: return "🥛"
        case .caffeine: return "☕️"
        case .histamine: return "🍷"
        case .salicylates: return "🫐"
        case .sulfites: return "🍇"
        case .fodmap: return "🧅"
        }
    }
    
    var category: String { "Intolerances" }
    
    var ingredientKeywords: [String] {
        switch self {
        case .gluten:
            return ["wheat", "barley", "rye", "flour", "bread", "pasta", "couscous", "bulgur", "semolina", "spelt", "farina", "kamut", "triticale", "malt", "brewer's yeast"]
        case .lactose:
            return ["milk", "cream", "lactose", "dairy", "buttermilk", "ice cream", "yogurt", "kefir", "sour cream", "evaporated milk", "condensed milk"]
        case .caffeine:
            return ["coffee", "tea", "espresso", "chocolate", "cocoa", "cola", "energy drink", "green tea", "black tea", "matcha", "yerba mate"]
        case .histamine:
            return ["wine", "beer", "champagne", "vinegar", "sauerkraut", "kimchi", "aged cheese", "parmesan", "salami", "pepperoni", "sausage", "smoked", "fermented", "yeast extract", "soy sauce", "miso", "tempeh", "spinach", "eggplant", "tomato", "avocado", "banana"]
        case .salicylates:
            return ["almond", "apple", "apricot", "berry", "berries", "cherry", "cucumber", "grape", "grapes", "orange", "peach", "plum", "raisin", "raisins", "strawberry", "strawberries", "raspberry", "raspberries", "blueberry", "blueberries", "blackberry", "blackberries", "tomato", "pepper", "peppers", "zucchini", "radish", "chicory", "endive"]
        case .sulfites:
            return ["wine", "dried fruit", "molasses", "vinegar", "pickled", "grape", "grapes", "lemon juice", "lime juice", "shrimp", "lobster", "scallop", "scallops", "wine vinegar"]
        case .fodmap:
            // Comprehensive FODMAP keywords based on Monash University research
            // Organized by FODMAP categories: Oligosaccharides, Disaccharides, Monosaccharides, Polyols
            return [
                // OLIGOSACCHARIDES (Fructans & GOS)
                // Fructans - High
                "wheat", "rye", "barley", "onion", "onions", "garlic", "shallot", "shallots", "leek", "leeks",
                "spring onion", "scallion", "scallions", "green onion",
                "artichoke", "asparagus", "beetroot", "beet", "brussels sprout", "brussels sprouts",
                "cabbage", "savoy cabbage", "fennel", "okra",
                "rambutan", "watermelon", "white peach", "nectarine", "persimmon", "tamarillo",
                "pistachio", "pistachios", "cashew", "cashews",
                "chickpea", "chickpeas", "garbanzo", "garbanzos",
                // GOS - High
                "bean", "beans", "kidney bean", "black bean", "pinto bean", "navy bean",
                "lentil", "lentils", "split pea", "split peas",
                "soy bean", "soybeans", "edamame", "soy milk",
                "almond", "almonds",
                
                // DISACCHARIDES (Lactose)
                "milk", "cow's milk", "goat's milk", "sheep's milk",
                "cream", "heavy cream", "whipping cream", "sour cream", "crème fraîche",
                "ice cream", "gelato",
                "yogurt", "yoghurt", "kefir",
                "buttermilk", "evaporated milk", "condensed milk", "sweetened condensed milk",
                "custard", "pudding",
                "cottage cheese", "ricotta", "cream cheese",
                "soft cheese", "fresh cheese",
                // Note: Hard cheeses and butter are usually low FODMAP
                
                // MONOSACCHARIDES (Excess Fructose)
                "honey", "agave", "agave nectar", "agave syrup",
                "high fructose corn syrup", "corn syrup", "hfcs",
                "apple", "apples", "pear", "pears", "mango", "mangoes",
                "watermelon", "cherry", "cherries", "fig", "figs",
                "guava", "longan", "lychee", "papaya", "persimmon",
                "sugar snap pea", "snow pea",
                "asparagus",
                "fruit juice concentrate", "apple juice", "pear juice", "mango juice",
                
                // POLYOLS (Sugar Alcohols)
                "sorbitol", "mannitol", "xylitol", "maltitol", "isomalt", "erythritol",
                "sugar-free", "sugarfree", "diet", "no sugar added",
                "apple", "apples", "apricot", "apricots", "avocado", "avocados",
                "blackberry", "blackberries", "cherry", "cherries",
                "lychee", "longan", "nectarine", "nectarines", "peach", "peaches", "pear", "pears",
                "plum", "plums", "prune", "prunes", "watermelon",
                "cauliflower", "mushroom", "mushrooms", "snow pea", "snow peas",
                "sweet corn", "baby corn",
                "chewing gum", "gum", "breath mint", "mints",
                
                // VEGETABLES - Additional High FODMAP
                "artichoke", "artichoke hearts",
                "baked beans", "refried beans",
                "celery", "chicory", "endive",
                "peas", "green peas", "split peas",
                "sugar snap peas",
                "sun-dried tomato", "sun dried tomato",
                
                // FRUITS - Additional High FODMAP
                "boysenberry", "boysenberries",
                "cranberry", "dried cranberries",
                "date", "dates",
                "dried fruit", "dried apricot", "raisin", "raisins",
                "grapefruit",
                "tamarind", "tamarindo",
                
                // GRAINS & CEREALS - High FODMAP
                "wheat flour", "all-purpose flour", "plain flour", "whole wheat", "wholemeal",
                "bread", "white bread", "wheat bread", "sourdough", "rye bread",
                "pasta", "spaghetti", "noodles", "wheat noodles", "egg noodles",
                "couscous", "bulgur", "farro", "freekeh",
                "bran", "wheat bran", "oat bran",
                "muesli", "granola",
                "rye crackers", "wheat crackers",
                
                // LEGUMES - High FODMAP
                "black-eyed pea", "black eyed pea",
                "broad bean", "fava bean", "lima bean",
                "baked bean", "baked beans",
                "hummus", "houmous",
                "falafel",
                
                // NUTS - High FODMAP
                "cashew butter", "pistachio", "pistachios",
                
                // SWEETENERS - High FODMAP
                "fructose", "fruit sugar",
                "honey", "honeycomb",
                "golden syrup", "molasses", "treacle",
                "inulin", "fos", "fructooligosaccharides",
                
                // CONDIMENTS & SAUCES - High FODMAP
                "garlic powder", "garlic salt", "garlic paste", "garlic oil" /* if has solids */,
                "onion powder", "onion salt", "onion flakes",
                "bbq sauce", "barbecue sauce", "ketchup" /* some brands */,
                "relish", "pickle relish", "chutney",
                "stock", "bouillon", "broth" /* if contains onion/garlic */,
                
                // BEVERAGES - High FODMAP
                "apple juice", "pear juice", "mango juice",
                "coconut water", "coconut milk" /* full fat */,
                "soy milk", "soya milk",
                "chai tea", "chamomile tea", "fennel tea", "oolong tea",
                "rum", "port", "dessert wine",
                
                // DAIRY ALTERNATIVES - High FODMAP
                "soy yogurt", "soy milk", "soya milk",
                "cashew milk", "oat milk" /* some brands */,
                
                // PROCESSED FOODS - Often High FODMAP
                "teriyaki", "hoisin", "plum sauce",
                "gravy" /* if contains wheat/onion */,
                "marinade" /* check ingredients */,
                "instant noodles", "ramen" /* wheat-based */
            ]
        }
    }
}

// MARK: - Severity Levels

enum SensitivitySeverity: String, Codable, CaseIterable, Identifiable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .mild: return "⚠️"
        case .moderate: return "⚠️⚠️"
        case .severe: return "🚫"
        }
    }
    
    var scoreMultiplier: Double {
        switch self {
        case .mild: return 1.0
        case .moderate: return 2.0
        case .severe: return 5.0
        }
    }
    
    var color: String {
        switch self {
        case .mild: return "yellow"
        case .moderate: return "orange"
        case .severe: return "red"
        }
    }
}

// MARK: - User Sensitivity Entry

struct UserSensitivity: Codable, Identifiable, Hashable {
    let id: UUID
    let allergen: FoodAllergen?
    let intolerance: FoodIntolerance?
    let severity: SensitivitySeverity
    let notes: String?
    
    init(id: UUID = UUID(),
         allergen: FoodAllergen? = nil,
         intolerance: FoodIntolerance? = nil,
         severity: SensitivitySeverity,
         notes: String? = nil) {
        self.id = id
        self.allergen = allergen
        self.intolerance = intolerance
        self.severity = severity
        self.notes = notes
    }
    
    var name: String {
        allergen?.rawValue ?? intolerance?.rawValue ?? "Unknown"
    }
    
    var icon: String {
        allergen?.icon ?? intolerance?.icon ?? "❓"
    }
    
    var category: String {
        allergen?.category ?? intolerance?.category ?? "Other"
    }
    
    var keywords: [String] {
        allergen?.ingredientKeywords ?? intolerance?.ingredientKeywords ?? []
    }
}

// MARK: - User Profile (SwiftData Model)

@Model
final class UserAllergenProfile {
    var id: UUID
    var name: String
    var isActive: Bool
    var sensitivitiesData: Data?
    var dateCreated: Date
    var dateModified: Date
    
    init(id: UUID = UUID(),
         name: String,
         isActive: Bool = false,
         sensitivitiesData: Data? = nil,
         dateCreated: Date = Date(),
         dateModified: Date = Date()) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.sensitivitiesData = sensitivitiesData
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
    
    // Computed property to get sensitivities
    var sensitivities: [UserSensitivity] {
        get {
            guard let data = sensitivitiesData else { return [] }
            return (try? JSONDecoder().decode([UserSensitivity].self, from: data)) ?? []
        }
        set {
            sensitivitiesData = try? JSONEncoder().encode(newValue)
            dateModified = Date()
        }
    }
    
    // Add a sensitivity
    func addSensitivity(_ sensitivity: UserSensitivity) {
        var current = sensitivities
        current.append(sensitivity)
        sensitivities = current
    }
    
    // Remove a sensitivity
    func removeSensitivity(id: UUID) {
        var current = sensitivities
        current.removeAll { $0.id == id }
        sensitivities = current
    }
    
    // Update a sensitivity
    func updateSensitivity(_ sensitivity: UserSensitivity) {
        var current = sensitivities
        if let index = current.firstIndex(where: { $0.id == sensitivity.id }) {
            current[index] = sensitivity
            sensitivities = current
        }
    }
}

// MARK: - Recipe Allergen Score

struct RecipeAllergenScore: Identifiable {
    let id = UUID()
    let recipeID: UUID
    let score: Double // 0 = safe, higher = more problematic
    let detectedAllergens: [DetectedAllergen]
    let isSafe: Bool // true if score is 0
    let severityLevel: SensitivitySeverity?
    
    var summary: String {
        if isSafe {
            return "No detected allergens"
        }
        let count = detectedAllergens.count
        return "\(count) allergen\(count == 1 ? "" : "s") detected"
    }
    
    var scoreLabel: String {
        if isSafe { return "Safe" }
        if score < 5 { return "Low Risk" }
        if score < 10 { return "Medium Risk" }
        return "High Risk"
    }
}

struct DetectedAllergen: Identifiable {
    let id = UUID()
    let sensitivity: UserSensitivity
    let matchedIngredients: [String] // Ingredient names that matched
    let matchedKeywords: [String] // Keywords that caused the match
}
