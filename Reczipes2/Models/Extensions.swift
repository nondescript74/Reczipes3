//
//  Extensions.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import Foundation

// MARK: - Recipe Collection
extension RecipeModel {
    /// All available recipes from the Extensions file.
    /// NOTE: Use RecipeCollection.shared.allRecipes instead for stable UUIDs!
    
    /// Returns a copy of this recipe with the specified image name
    func withImageName(_ imageName: String?) -> RecipeModel {
        RecipeModel(
            id: self.id,
            title: self.title,
            headerNotes: self.headerNotes,
            yield: self.yield,
            ingredientSections: self.ingredientSections,
            instructionSections: self.instructionSections,
            notes: self.notes,
            reference: self.reference,
            imageName: imageName
        )
    }
}

//// MARK: - Recipe Extensions
//
//extension RecipeModel {
//    
//    // MARK: - Ambli ni Chutney
//    static var ambli_ni_chutney: RecipeModel {
//        RecipeModel(
//            title: "Ambli ni Chutney",
//            headerNotes: "Tamarind Sauce",
//            yield: "Makes 4 cups (1 L)",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "½", unit: "lb.", name: "tamarind", metricQuantity: "250", metricUnit: "g"),
//                        Ingredient(quantity: "3", unit: "cups", name: "water", metricQuantity: "750", metricUnit: "mL"),
//                        Ingredient(quantity: "½", unit: "cup", name: "sugar or", metricQuantity: "125", metricUnit: "mL"),
//                        Ingredient(quantity: "½", unit: "lb.", name: "chopped pitted dates", metricQuantity: "250", metricUnit: "g"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "salt", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "cumin powder", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "chilli powder", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "tbsp.", name: "vinegar", metricQuantity: "15", metricUnit: "mL")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(stepNumber: 1, text: "Cover tamarind with water and soak overnight."),
//                        InstructionStep(stepNumber: 2, text: "Remove seeds, blend and strain into a saucepan."),
//                        InstructionStep(stepNumber: 3, text: "Add salt, cumin and sugar or dates and boil for 10 minutes."),
//                        InstructionStep(stepNumber: 4, text: "Add chilli powder and vinegar."),
//                        InstructionStep(stepNumber: 5, text: "Cool and store the sauce in plastic containers."),
//                        InstructionStep(stepNumber: 6, text: "Use freezer for long-term storage, and refrigeration for up to 60 days.")
//                    ]
//                )
//            ],
//            reference: "See photograph, page 80."
//        )
//    }
//    
//    
//    // MARK: - Cucumber Raita
//    static var cucumber_raita: RecipeModel {
//        RecipeModel(
//            title: "Cucumber Raita",
//            yield: "Makes 2 cups (500 mL)",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "1", unit: "cup", name: "plain yogurt", metricQuantity: "250", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "cup", name: "cucumber, chopped or grated", metricQuantity: "250", metricUnit: "mL"),
//                        Ingredient(quantity: "", unit: "", name: "salt to taste"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "freshly ground black pepper", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "½-1", unit: "", name: "hot pepper, chopped, or to taste"),
//                        Ingredient(quantity: "1", unit: "tbsp.", name: "chopped coriander leaves", metricQuantity: "15", metricUnit: "mL")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(text: "Combine all ingredients and stir thoroughly. Garnish with coriander leaves."),
//                        InstructionStep(text: "Serve as a sauce with chapati or with entrées. Can also be served as vegetable dip.")
//                    ]
//                ),
//                InstructionSection(
//                    title: "Variation",
//                    steps: [
//                        InstructionStep(text: "Finely chopped mixed vegetables like cucumber, cauliflower, celery, broccoli, tomatoes, carrots, onion and radish can be added.")
//                    ]
//                )
//            ]
//        )
//    }
//    
//    // MARK: - Dhokra Chutney
//    static var dhokra_chutney: RecipeModel {
//        RecipeModel(
//            title: "Dhokra Chutney",
//            headerNotes: "Savoury Cake Chutney",
//            yield: "Makes ½ cup (125 mL)",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "1", unit: "tsp.", name: "chilli powder", metricQuantity: "5", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "tsp.", name: "paprika powder", metricQuantity: "5", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "garlic powder", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "citric acid", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "salt", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "tbsp.", name: "tomato paste", metricQuantity: "15", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "cumin powder", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "dried parsley", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "1½", unit: "tbsp.", name: "sunflower or corn oil", metricQuantity: "20", metricUnit: "mL")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(text: "Combine all the ingredients and mix thoroughly.")
//                    ]
//                )
//            ]
//        )
//    }
//    
//    
//    // MARK: - Eggplant Raita
//    static var eggplant_raita: RecipeModel {
//        RecipeModel(
//            title: "Eggplant Raita",
//            yield: "Makes 3½ cups (875 mL)",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "1", unit: "", name: "large eggplant"),
//                        Ingredient(quantity: "", unit: "", name: "oil"),
//                        Ingredient(quantity: "2", unit: "tbsp.", name: "chopped green onion", metricQuantity: "30", metricUnit: "mL"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "crushed hot pepper", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "cumin powder", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "tbsp.", name: "fresh, grated tomato", metricQuantity: "15", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "salt, or to taste", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "2", unit: "cups", name: "plain yogurt", metricQuantity: "500", metricUnit: "mL")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(stepNumber: 1, text: "Brush oil on an eggplant and bake at 350 F (180 C) for 45-50 minutes."),
//                        InstructionStep(stepNumber: 2, text: "When tender run under cold water. Peel and mash with a fork, removing seeds if any."),
//                        InstructionStep(stepNumber: 3, text: "Combine with onion, hot pepper, cumin powder, tomato, salt and yogurt and mix well."),
//                        InstructionStep(stepNumber: 4, text: "Serve with any curry dish or with chapati (page 40) as an appetizer.")
//                    ]
//                ),
//                InstructionSection(
//                    title: "Variation",
//                    steps: [
//                        InstructionStep(text: "Eggplant Bhadthu: omit yogurt and tomatoes and add ¼ tsp. (1 mL) crushed garlic and 1 tbsp. (15 mL) oil. Serve with chapati (page 40) and plain yogurt or Lasan-na-Ladu (page 42).")
//                    ]
//                )
//            ]
//        )
//    }
//    
//    // MARK: - Garam Masala
//    static var garam_masala: RecipeModel {
//        RecipeModel(
//            title: "Garam Masala",
//            yield: "Makes ¾ cup (175 mL)",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "2", unit: "oz.", name: "cinnamon sticks", metricQuantity: "55", metricUnit: "g"),
//                        Ingredient(quantity: "2", unit: "tbsp.", name: "green cardamoms", metricQuantity: "30", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "tbsp.", name: "black peppercorns", metricQuantity: "15", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "tbsp.", name: "cloves", metricQuantity: "15", metricUnit: "mL")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(stepNumber: 1, text: "Break cinnamon sticks into small pieces."),
//                        InstructionStep(stepNumber: 2, text: "Roast all ingredients in preheated oven at 150 F (70 C) for 10 minutes."),
//                        InstructionStep(stepNumber: 3, text: "Blend in a coffee grinder."),
//                        InstructionStep(stepNumber: 4, text: "Best fresh but can also be stored in airtight container.")
//                    ]
//                )
//            ]
//        )
//    }
//    
//    // MARK: - Ghee
//    static var ghee: RecipeModel {
//        RecipeModel(
//            title: "Ghee",
//            headerNotes: "Clarified Butter",
//            yield: "Makes 6 cups (1½ L)",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "3", unit: "lbs.", name: "butter", metricQuantity: "1.5", metricUnit: "kg"),
//                        Ingredient(quantity: "6", unit: "tbsp.", name: "corn or sunflower oil", metricQuantity: "90", metricUnit: "mL")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(text: "Put butter and oil in large microwave bowl with lid. Microwave at high for 30 minutes, covered, and let cool."),
//                        InstructionStep(text: "When cold, pour into container, discarding the salt sediments. Store covered, preferably in the refrigerator."),
//                        InstructionStep(text: "A 500-volt microwave is used; therefore adjust cooking time according to the voltage of your microwave oven."),
//                        InstructionStep(text: "Can be made on the stove on medium heat. Cook until salt sediment is just turning gold because it will become darker after it is off the stove.")
//                    ]
//                )
//            ]
//        )
//    }
//    
//    
//    // MARK: - Homemade Yogurt
//    static var homemade_yogurt: RecipeModel {
//        RecipeModel(
//            title: "Homemade Yogurt",
//            yield: "Serves 4 to 5",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "4", unit: "cups", name: "milk", metricQuantity: "1", metricUnit: "L"),
//                        Ingredient(quantity: "1", unit: "cup", name: "commercial buttermilk (Lucerne recommended)", metricQuantity: "250", metricUnit: "mL")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(stepNumber: 1, text: "Bring milk to boiling point and then let cool until slightly warm to the touch."),
//                        InstructionStep(stepNumber: 2, text: "Add buttermilk and stir well."),
//                        InstructionStep(stepNumber: 3, text: "Pour into a bowl and cover."),
//                        InstructionStep(stepNumber: 4, text: "Leave in a warm place overnight to set."),
//                        InstructionStep(stepNumber: 5, text: "Refrigerate before serving."),
//                        InstructionStep(stepNumber: 6, text: "This yogurt can then be used instead of buttermilk to make more yogurt."),
//                        InstructionStep(stepNumber: 7, text: "After using mixture a few times, switch to buttermilk for new starter.")
//                    ]
//                )
//            ]
//        )
//    }
//    
//    // MARK: - Kachumber
//    static var kachumber: RecipeModel {
//        RecipeModel(
//            title: "Kachumber",
//            yield: "Makes 1½ cups (375 mL)",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "1", unit: "", name: "carrot"),
//                        Ingredient(quantity: "1", unit: "", name: "onion"),
//                        Ingredient(quantity: "1", unit: "", name: "tomato"),
//                        Ingredient(quantity: "1½", unit: "tsp.", name: "chopped coriander leaves", metricQuantity: "7", metricUnit: "mL"),
//                        Ingredient(quantity: "", unit: "", name: "salt to taste"),
//                        Ingredient(quantity: "", unit: "", name: "chilli powder to taste or chopped hot peppers"),
//                        Ingredient(quantity: "1", unit: "tbsp.", name: "vinegar", metricQuantity: "15", metricUnit: "mL")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(text: "Cut carrot, onion and tomato into quarters and slice thinly."),
//                        InstructionStep(text: "Add chopped coriander and the rest of the ingredients and mix well.")
//                    ]
//                )
//            ]
//        )
//    }
//    
//    // MARK: - Kadho
//    static var kadho: RecipeModel {
//        RecipeModel(
//            title: "Kadho",
//            headerNotes: "Saffron Milk - This is a traditional wedding drink. It is also an excellent cold remedy, with or without nuts.",
//            yield: "Serves 6 to 7",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "4", unit: "cups", name: "milk", metricQuantity: "1", metricUnit: "L"),
//                        Ingredient(quantity: "13½", unit: "oz.", name: "can evaporated milk", metricQuantity: "385", metricUnit: "mL"),
//                        Ingredient(quantity: "⅔", unit: "cup", name: "condensed milk", metricQuantity: "150", metricUnit: "mL"),
//                        Ingredient(quantity: "6-8", unit: "", name: "strands saffron"),
//                        Ingredient(quantity: "¼", unit: "cup", name: "chopped almonds", metricQuantity: "50", metricUnit: "mL"),
//                        Ingredient(quantity: "2", unit: "tbsp.", name: "chopped pistachios", metricQuantity: "30", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "ground cardamom", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "⅛", unit: "tsp.", name: "ground nutmeg", metricQuantity: "0.5", metricUnit: "mL")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(text: "Bring regular milk to a boil, stirring continuously. Stir in other milks and rest of the ingredients. Continue cooking on medium heat, stirring continuously for 4 to 5 minutes and serve hot.")
//                    ]
//                )
//            ],
//            reference: "See photograph, page 16."
//        )
//    }
//    
//    // MARK: - Lassi
//    static var lassi: RecipeModel {
//        RecipeModel(
//            title: "Lassi",
//            headerNotes: "Yogurt Sherbet - Very refreshing and cooling.",
//            yield: "Serves 1 to 2",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "¾", unit: "cup", name: "plain yogurt", metricQuantity: "175", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "cup", name: "water", metricQuantity: "250", metricUnit: "mL"),
//                        Ingredient(quantity: "⅛", unit: "tsp.", name: "salt", metricQuantity: "0.5", metricUnit: "mL"),
//                        Ingredient(quantity: "⅛", unit: "tsp.", name: "ground black pepper", metricQuantity: "0.5", metricUnit: "mL"),
//                        Ingredient(quantity: "⅛", unit: "tsp.", name: "cumin powder", metricQuantity: "0.5", metricUnit: "mL"),
//                        Ingredient(quantity: "", unit: "", name: "ice cubes")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(text: "Combine all ingredients in the blender and blend until smooth. Serve. Sugar can be added instead of salt and pepper, if preferred.")
//                    ]
//                )
//            ],
//            reference: "See photograph, page 48."
//        )
//    }
//
//    
//    // MARK: - Sherbet
//    static var sherbet: RecipeModel {
//        RecipeModel(
//            title: "Sherbet",
//            headerNotes: "Milk Shake - A traditional wedding drink.",
//            yield: "Serves 8 to 10",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "4", unit: "cups", name: "homogenized milk", metricQuantity: "1", metricUnit: "L"),
//                        Ingredient(quantity: "13½", unit: "oz.", name: "can evaporated milk", metricQuantity: "385", metricUnit: "mL"),
//                        Ingredient(quantity: "⅔", unit: "cup", name: "condensed milk", metricQuantity: "150", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "cup", name: "strawberry ice cream", metricQuantity: "250", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "cup", name: "chopped almonds", metricQuantity: "50", metricUnit: "mL"),
//                        Ingredient(quantity: "2", unit: "tbsp.", name: "chopped unsalted pistachios", metricQuantity: "30", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "tsp.", name: "vanilla essence", metricQuantity: "5", metricUnit: "mL"),
//                        Ingredient(quantity: "4-6", unit: "", name: "drops rose essence"),
//                        Ingredient(quantity: "", unit: "", name: "pink food colour (for pale pink colour)"),
//                        Ingredient(quantity: "", unit: "", name: "ice")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(text: "Stir all ingredients together and serve cold.")
//                    ]
//                )
//            ],
//            reference: "See photograph, page 7."
//        )
//    }
//    
//    // MARK: - Vegetable Soup
//    static var vegetable_soup: RecipeModel {
//        RecipeModel(
//            title: "Vegetable Soup",
//            yield: "Serves 4 to 5",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "¼", unit: "cup", name: "masoor (lentils)", metricQuantity: "50", metricUnit: "mL"),
//                        Ingredient(quantity: "1½", unit: "cups", name: "mixed vegetables (peas, celery, onion, beans, carrots, cauliflower, cabbage, potatoes)", metricQuantity: "375", metricUnit: "mL"),
//                        Ingredient(quantity: "3", unit: "cups", name: "water", metricQuantity: "750", metricUnit: "mL"),
//                        Ingredient(quantity: "", unit: "", name: "salt, pepper"),
//                        Ingredient(quantity: "1", unit: "tbsp.", name: "rolled oats", metricQuantity: "15", metricUnit: "mL")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(text: "Soak masoor (lentils) overnight, in water to cover. Wash and drain before adding to the soup."),
//                        InstructionStep(text: "Put all ingredients in a saucepan. Bring to a boil. Lower heat and cook until vegetables are tender and broth is reduced to your desired consistency.")
//                    ]
//                )
//            ]
//        )
//    }
//    
//    // MARK: - Vegetable Sambhar
//    static var vegetable_sambhar: RecipeModel {
//        RecipeModel(
//            title: "Vegetable Sambhar",
//            headerNotes: "Cold Marinated Vegetables",
//            yield: "Makes 4 cups (1 L)",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "½", unit: "cup", name: "oil", metricQuantity: "125", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "tsp.", name: "mustard seeds", metricQuantity: "5", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "cumin seeds", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "10-12", unit: "", name: "curry leaves* (Lindho)"),
//                        Ingredient(quantity: "10-12", unit: "", name: "hot peppers, halved"),
//                        Ingredient(quantity: "1", unit: "", name: "medium cabbage, shredded"),
//                        Ingredient(quantity: "3", unit: "", name: "large carrots, cut into strips"),
//                        Ingredient(quantity: "1", unit: "", name: "small raw mango, cut into pieces"),
//                        Ingredient(quantity: "1", unit: "tsp.", name: "cumin powder", metricQuantity: "5", metricUnit: "mL"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "crushed garlic", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "turmeric powder", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "1½", unit: "tsp.", name: "salt", metricQuantity: "7", metricUnit: "mL"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "chilli powder", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "2", unit: "tbsp.", name: "lemon juice, or to taste", metricQuantity: "30", metricUnit: "mL"),
//                        Ingredient(quantity: "2", unit: "tbsp.", name: "sugar", metricQuantity: "30", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "tbsp.", name: "Tamarind Chutney (see page 17)", metricQuantity: "15", metricUnit: "mL")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(stepNumber: 1, text: "Heat oil, add mustard seeds, cumin seeds, curry leaves and hot peppers."),
//                        InstructionStep(stepNumber: 2, text: "Add cabbage, carrots and mango and cook on low heat until cabbage is transparent."),
//                        InstructionStep(stepNumber: 3, text: "Add cumin powder, garlic, turmeric, salt and chilli powder and continue to cook until carrots are tender."),
//                        InstructionStep(stepNumber: 4, text: "Add lemon juice, sugar, Tamarind Chutney and continue cooking until all the liquid is absorbed."),
//                        InstructionStep(stepNumber: 5, text: "Serve with any curry dish.")
//                    ]
//                ),
//                InstructionSection(
//                    title: "Variation",
//                    steps: [
//                        InstructionStep(text: "1 tbsp. (15 mL) gram flour can be added and sautéed for ½ minute just before adding cabbage."),
//                        InstructionStep(text: "Bell peppers can be used instead of hot peppers or combine bell peppers and hot peppers to reduce the hot taste.")
//                    ]
//                )
//            ],
//            notes: [
//                RecipeNote(type: .general, text: "*Curry leaves are like bay leaves but much smaller.")
//            ]
//        )
//    }
//    
//    // MARK: - Chicken Soup
//    static var chicken_soup: RecipeModel {
//        RecipeModel(
//            title: "Chicken Soup",
//            headerNotes: "Grandma's remedy for the common cold.",
//            yield: "Serves 6 to 8",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "2", unit: "lbs.", name: "chicken, skinned, cut, wash, OR back and neck bones", metricQuantity: "1", metricUnit: "kg"),
//                        Ingredient(quantity: "7½", unit: "cups", name: "water", metricQuantity: "2", metricUnit: "L"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "whole black peppercorns", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "6", unit: "", name: "small cinnamon sticks"),
//                        Ingredient(quantity: "5", unit: "", name: "cloves"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "crushed ginger", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "crushed garlic", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "turmeric", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "salt", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "ground black pepper", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "", name: "small onion, finely chopped")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(stepNumber: 1, text: "Put all ingredients in a saucepan and bring to boil. Reduce heat to medium and let boil uncovered for 1½ hours."),
//                        InstructionStep(stepNumber: 2, text: "Remove chicken from the soup, bone, and set meat aside."),
//                        InstructionStep(stepNumber: 3, text: "Drain stock and place in the refrigerator for 2-3 hours or until the fat has set on the top."),
//                        InstructionStep(stepNumber: 4, text: "Discard the fat, return boned chicken to the stock and boil for a few minutes. Serve.")
//                    ]
//                )
//            ]
//        )
//    }
//    
//    // MARK: - Moong Bean Soup
//    static var moong_bean_soup: RecipeModel {
//        RecipeModel(
//            title: "Moong Bean Soup",
//            headerNotes: "Very nutritious and slimming.",
//            yield: "Serves 6 to 8",
//            ingredientSections: [
//                IngredientSection(
//                    ingredients: [
//                        Ingredient(quantity: "1", unit: "cup", name: "moong beans", metricQuantity: "250", metricUnit: "mL"),
//                        Ingredient(quantity: "3", unit: "cups", name: "water", metricQuantity: "750", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "", name: "small onion, blended"),
//                        Ingredient(quantity: "1", unit: "", name: "small tomato, blended"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "crushed garlic (optional)", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "½", unit: "tsp.", name: "salt", metricQuantity: "2", metricUnit: "mL"),
//                        Ingredient(quantity: "¼", unit: "tsp.", name: "ground black pepper", metricQuantity: "1", metricUnit: "mL"),
//                        Ingredient(quantity: "1", unit: "", name: "stalk celery, finely chopped"),
//                        Ingredient(quantity: "½", unit: "", name: "bell pepper, finely chopped")
//                    ]
//                )
//            ],
//            instructionSections: [
//                InstructionSection(
//                    steps: [
//                        InstructionStep(stepNumber: 1, text: "Soak moong overnight in water to cover."),
//                        InstructionStep(stepNumber: 2, text: "In a saucepan place drained moong, 3 cups (750 mL) water and remaining ingredients. Bring to boil. Lower heat and simmer for about 1½ hours."),
//                        InstructionStep(stepNumber: 3, text: "Serve hot.")
//                    ]
//                )
//            ]
//        )
//    }
//}
