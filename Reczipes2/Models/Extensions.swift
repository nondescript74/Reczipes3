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
    /// Add new recipes to this array when creating new recipe extensions.
    /// NOTE: Use RecipeCollection.shared.allRecipes instead for stable UUIDs!
    static var allRecipes: [RecipeModel] {
        [
            .limePickleExample,
            .ambliNiChutney,
            .carrotPickle,
            .corianderChutney,
            .cucumberRaita,
            .dhokraChutney,
            .driedCarrots,
            .eggplantRaita,
            .garamMasala,
            .ghee,
            .homemadeYogurt,
            .instantTomatoChutney,
            .kachumber,
            .kadho,
            .lassi,
            .lemonChutney,
            .mangoPickleInOil,
            .sherbet,
            .vegetableSoup,
            .vegetableSambhar
        ]
    }
    
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

// MARK: - Lime Pickle
extension RecipeModel {
    static var limePickleExample: RecipeModel {
        RecipeModel(
            title: "Lime Pickle",
            headerNotes: "Limes take approximately 15-30 days to soften depending on the type of limes. Choose limes with thin skins.",
            yield: "Makes 2 quarts (2 L)",
            ingredientSections: [
                IngredientSection(
                    title: "Initial Ingredients",
                    ingredients: [
                        Ingredient(quantity: "1", unit: "lb.", name: "limes", preparation: "preferably yellow and juicy", metricQuantity: "500", metricUnit: "g"),
                        Ingredient(quantity: "1", unit: "tbsp.", name: "salt", metricQuantity: "15", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tsp.", name: "turmeric powder", metricQuantity: "10", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "chilli powder", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tsp.", name: "sugar", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "¼", unit: "cup", name: "lemon juice", metricQuantity: "125", metricUnit: "mL")
                    ],
                    transitionNote: "These ingredients are to be bought and used 15 days later."
                ),
                IngredientSection(
                    title: "Additional Ingredients (15 days later)",
                    ingredients: [
                        Ingredient(quantity: "2", unit: "oz.", name: "hot peppers", metricQuantity: "50", metricUnit: "g"),
                        Ingredient(quantity: "2", unit: "oz.", name: "garmar", preparation: "if available", metricQuantity: "50", metricUnit: "g"),
                        Ingredient(quantity: "2", unit: "oz.", name: "tender guar", metricQuantity: "50", metricUnit: "g"),
                        Ingredient(quantity: "2", unit: "oz.", name: "ginger", preparation: "cut into slices", metricQuantity: "50", metricUnit: "g"),
                        Ingredient(quantity: "2", unit: "oz.", name: "fresh green peppercorn", preparation: "if available", metricQuantity: "50", metricUnit: "g"),
                        Ingredient(quantity: "1", unit: "tsp.", name: "salt", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "turmeric", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "cup", name: "lemon juice", metricQuantity: "250", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tsp.", name: "crushed mustard seed", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tsp.", name: "citric acid", metricQuantity: "5", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    title: "Part 1",
                    steps: [
                        InstructionStep(text: "Cut each lime into eighths. Mix in the salt, turmeric powder, chilli powder, and sugar, transfer to a 1-quart jar. Cover and keep in a warm place for 1 week. Add lemon juice and let rest until the skin of the lime is tender, approximately 3-4 weeks. It is important to shake the jar daily to prevent moulding.")
                    ]
                ),
                InstructionSection(
                    title: "Part 2",
                    steps: [
                        InstructionStep(text: "Slit the peppers halfway. Peel and cut the garmar lengthwise and then again into 2½″ (6 cm) pieces. Cut off the top and tail of the guar."),
                        InstructionStep(text: "Mix the above ingredients together, except for mustard seed and citric acid, let stand for ½ hour. Put the prepared vegetables into a 2-quart (2 L) jar. Place the limes on top of the vegetables. Add cooled, boiled water until the jar is ¾ full. Add mustard seeds and citric acid. Let it sit out for a day and then keep in refrigerator. This pickle keeps well.")
                    ]
                )
            ],
            notes: [
                RecipeNote(type: .substitution, text: "If all the vegetables are not available, substitute with vegetables in season. You will need ½ lb. (250 g) vegetables in total.")
            ],
            reference: "See photograph on front cover."
        )
    }
}

// MARK: - Ambli ni Chutney (Tamarind Sauce)
extension RecipeModel {
    static var ambliNiChutney: RecipeModel {
        RecipeModel(
            title: "Ambli ni Chutney",
            headerNotes: "Tamarind Sauce",
            yield: "Makes 4 cups (1 L)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "½", unit: "lb.", name: "tamarind", metricQuantity: "250", metricUnit: "g"),
                        Ingredient(quantity: "3", unit: "cups", name: "water", metricQuantity: "750", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "cup", name: "sugar or", metricQuantity: "125", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "lb.", name: "chopped pitted dates", metricQuantity: "250", metricUnit: "g"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "salt", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "cumin powder", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "chilli powder", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tbsp.", name: "vinegar", metricQuantity: "15", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Cover tamarind with water and soak overnight."),
                        InstructionStep(stepNumber: 2, text: "Remove seeds, blend and strain into a saucepan."),
                        InstructionStep(stepNumber: 3, text: "Add salt, cumin and sugar or dates and boil for 10 minutes."),
                        InstructionStep(stepNumber: 4, text: "Add chilli powder and vinegar."),
                        InstructionStep(stepNumber: 5, text: "Cool and store the sauce in plastic containers."),
                        InstructionStep(stepNumber: 6, text: "Use freezer for long-term storage, and refrigeration for up to 60 days.")
                    ]
                )
            ],
            reference: "See photograph, page 80."
        )
    }
}

// MARK: - Carrot Pickle
extension RecipeModel {
    static var carrotPickle: RecipeModel {
        RecipeModel(
            title: "Carrot Pickle",
            yield: "Makes 1 to 1½ cups (250-375 mL)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "2", unit: "", name: "medium carrots"),
                        Ingredient(quantity: "4", unit: "", name: "hot peppers"),
                        Ingredient(quantity: "½", unit: "", name: "bell pepper"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "salt", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "chilli powder, or to taste", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "", name: "", metricQuantity: "", metricUnit: ""),
                        Ingredient(quantity: "4", unit: "", name: "", metricQuantity: "", metricUnit: ""),
                        Ingredient(quantity: "½", unit: "", name: "", metricQuantity: "", metricUnit: ""),
                        Ingredient(quantity: "¼", unit: "tsp.", name: "turmeric", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tsp.", name: "slightly crushed mustard seeds", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tbsp.", name: "white vinegar", metricQuantity: "30", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Peel carrots and cut into thin strips, 2″ (5 cm) long."),
                        InstructionStep(stepNumber: 2, text: "Cut hot peppers and bell pepper into similar strips."),
                        InstructionStep(stepNumber: 3, text: "Combine all 3 and add remaining ingredients."),
                        InstructionStep(stepNumber: 4, text: "Mix well and let stand for about 1 hour."),
                        InstructionStep(stepNumber: 5, text: "Serve with any curry dish.")
                    ]
                ),
                InstructionSection(
                    title: "Variation",
                    steps: [
                        InstructionStep(text: "Substitute mustard and white vinegar with 2 tsp. (10 mL) tomato paste and 1-2 tbsp. (15-30 mL) oil, and add ¼ tsp. (1 mL) citric acid and chopped coriander leaves.")
                    ]
                )
            ],
            reference: "See photograph, page 48."
        )
    }
}

// MARK: - Coriander Chutney
extension RecipeModel {
    static var corianderChutney: RecipeModel {
        RecipeModel(
            title: "Coriander Chutney",
            yield: "Makes about ½ to ⅔ cup (125-175 mL) (depending on quantity of coriander)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "1", unit: "bunch", name: "coriander leaves*"),
                        Ingredient(quantity: "1-2", unit: "", name: "whole hot peppers"),
                        Ingredient(quantity: "1", unit: "", name: "", metricQuantity: "", metricUnit: ""),
                        Ingredient(quantity: "1-2", unit: "", name: "", metricQuantity: "", metricUnit: ""),
                        Ingredient(quantity: "2", unit: "tsp.", name: "salt, to taste lemon juice", metricQuantity: "10", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Blend all the ingredients to a smooth paste."),
                        InstructionStep(stepNumber: 2, text: "Keeps in refrigerator for a long time.")
                    ]
                ),
                InstructionSection(
                    title: "Variations",
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Add 1 small fresh tomato, adjust salt and blend."),
                        InstructionStep(stepNumber: 2, text: "Add ½ cup (125 mL) of chopped unripe mango, and blend."),
                        InstructionStep(stepNumber: 3, text: "Coconut Chutney: 1 cup (250 mL) fine unsweetened coconut, 1 tbsp. (15 mL) oil, ½ tsp. (2 mL) rai seeds, 1 cup (250 mL) water, 1 tbsp. (15 mL) lemon juice and 1 tsp. (5 mL) sugar and salt to taste. Blend."),
                        InstructionStep(stepNumber: 4, text: "Mint Chutney: Substitute ½ bunch coriander leaves with ½ bunch mint leaves.")
                    ]
                )
            ],
            notes: [
                RecipeNote(type: .general, text: "* Coriander leaves are also known as Chinese parsley or cilantro.")
            ],
            reference: "See photograph, page 16."
        )
    }
}

// MARK: - Cucumber Raita
extension RecipeModel {
    static var cucumberRaita: RecipeModel {
        RecipeModel(
            title: "Cucumber Raita",
            yield: "Makes 2 cups (500 mL)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "1", unit: "cup", name: "plain yogurt", metricQuantity: "250", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "cup", name: "cucumber, chopped or grated salt to taste", metricQuantity: "250", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "freshly ground black pepper", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "½-1", unit: "", name: "hot pepper, chopped, or to taste"),
                        Ingredient(quantity: "1", unit: "tbsp.", name: "chopped coriander leaves", metricQuantity: "15", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Combine all ingredients and stir thoroughly. Garnish with coriander leaves."),
                        InstructionStep(text: "Serve as a sauce with chapati or with entrees. Can also be served as vegetable dip.")
                    ]
                ),
                InstructionSection(
                    title: "Variation",
                    steps: [
                        InstructionStep(text: "Finely chopped mixed vegetables like cucumber, cauliflower, celery, broccoli, tomatoes, carrots, onion and radish can be added.")
                    ]
                )
            ]
        )
    }
}

// MARK: - Dhokra Chutney
extension RecipeModel {
    static var dhokraChutney: RecipeModel {
        RecipeModel(
            title: "Dhokra Chutney",
            headerNotes: "Savoury Cake Chutney",
            yield: "Makes ½ cup (125 mL)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "1", unit: "tsp.", name: "chilli powder", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tsp.", name: "paprika powder", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "garlic powder", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "citric acid", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "salt", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tbsp.", name: "tomato paste", metricQuantity: "15", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "cumin powder", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "dried parsley", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "1½", unit: "tbsp.", name: "sunflower or corn oil", metricQuantity: "20", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Combine all the ingredients and mix thoroughly.")
                    ]
                )
            ]
        )
    }
}

// MARK: - Dried Carrots
extension RecipeModel {
    static var driedCarrots: RecipeModel {
        RecipeModel(
            title: "Dried Carrots",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "2", unit: "tsp.", name: "salt", metricQuantity: "10", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "turmeric", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "1¼", unit: "lb.", name: "carrots, in 3″ x ½″ (7 x 1 cm) sticks", metricQuantity: "625", metricUnit: "g")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Rub salt and turmeric into carrot sticks and set aside for 1-2 days, unrefrigerated."),
                        InstructionStep(stepNumber: 2, text: "Completely drain off all water."),
                        InstructionStep(stepNumber: 3, text: "Dry on paper towel."),
                        InstructionStep(stepNumber: 4, text: "Put in preheated oven at 150 F (70 C) until completely dry. Alternately, this dries well out in the sun in summertime."),
                        InstructionStep(stepNumber: 5, text: "May be stored in an airtight container for a long time. Use as needed.")
                    ]
                )
            ]
        )
    }
}

// MARK: - Eggplant Raita
extension RecipeModel {
    static var eggplantRaita: RecipeModel {
        RecipeModel(
            title: "Eggplant Raita",
            yield: "Makes 3½ cups (875 mL)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "1", unit: "", name: "large eggplant oil"),
                        Ingredient(quantity: "2", unit: "tbsp.", name: "chopped green onion", metricQuantity: "30", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "crushed hot pepper", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "", name: "", metricQuantity: "", metricUnit: ""),
                        Ingredient(quantity: "½", unit: "tsp.", name: "cumin powder", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tbsp.", name: "fresh, grated tomato", metricQuantity: "15", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "salt, or to taste", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "cups", name: "plain yogurt", metricQuantity: "500", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Brush oil on an eggplant and bake at 350 F (180 C) for 45-50 minutes."),
                        InstructionStep(stepNumber: 2, text: "When softer run under cold water. Peel and mash with a fork, removing seeds if any."),
                        InstructionStep(stepNumber: 3, text: "Combine with onion, hot pepper, cumin powder, tomato, salt and yogurt and mix well."),
                        InstructionStep(stepNumber: 4, text: "Serve with any curry dish or with chapati (page 40) as an appetizer.")
                    ]
                ),
                InstructionSection(
                    title: "Variation",
                    steps: [
                        InstructionStep(text: "Eggplant Bhadthu: omit yogurt and tomatoes and add ¼ tsp. (1 mL) crushed garlic and 1 tbsp. (15 mL) oil. Serve with chapati (page 40) and plain yogurt or Lasan-na-Ladu (page 42).")
                    ]
                )
            ]
        )
    }
}

// MARK: - Garam Masala
extension RecipeModel {
    static var garamMasala: RecipeModel {
        RecipeModel(
            title: "Garam Masala",
            yield: "Makes ⅓ cup (75 mL)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "2", unit: "oz.", name: "cinnamon sticks", metricQuantity: "55", metricUnit: "g"),
                        Ingredient(quantity: "2", unit: "tbsp.", name: "green cardamoms", metricQuantity: "30", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tbsp.", name: "black peppercorns", metricQuantity: "15", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tbsp.", name: "cloves", metricQuantity: "15", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Break cinnamon sticks into small pieces."),
                        InstructionStep(stepNumber: 2, text: "Roast all ingredients in preheated oven at 150 F (70 C) for 10 minutes."),
                        InstructionStep(stepNumber: 3, text: "Blend in a coffee grinder."),
                        InstructionStep(stepNumber: 4, text: "Best fresh but can also be stored in airtight container.")
                    ]
                )
            ]
        )
    }
}

// MARK: - Ghee
extension RecipeModel {
    static var ghee: RecipeModel {
        RecipeModel(
            title: "Ghee",
            headerNotes: "Clarified Butter",
            yield: "Makes 6 cups (1½ L)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "3", unit: "lbs.", name: "butter", metricQuantity: "1.5", metricUnit: "kg"),
                        Ingredient(quantity: "6", unit: "tbsp.", name: "corn or sunflower oil", metricQuantity: "90", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Put butter and oil in large microwave bowl with lid. Microwave at high for 30 minutes, covered, and let cool."),
                        InstructionStep(text: "When cold, pour into container, discarding the salt sediments. Store covered, preferably in the refrigerator."),
                        InstructionStep(text: "A 500-volt microwave is used; therefore adjust cooking time according to the voltage of your microwave oven."),
                        InstructionStep(text: "Ghee can be made on the stove on medium heat. Cook until salt sediment is just turning gold because it will become darker after it is off the stove.")
                    ]
                )
            ]
        )
    }
}
// MARK: - Homemade Yogurt
extension RecipeModel {
    static var homemadeYogurt: RecipeModel {
        RecipeModel(
            title: "Homemade Yogurt",
            yield: "Serves 4 to 5",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "4", unit: "cups", name: "milk", metricQuantity: "1", metricUnit: "L"),
                        Ingredient(quantity: "1", unit: "cup", name: "commercial buttermilk (Lucerne recommended)", metricQuantity: "250", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Bring milk to boiling point and then let cool until slightly warm to the touch."),
                        InstructionStep(stepNumber: 2, text: "Add buttermilk and stir well."),
                        InstructionStep(stepNumber: 3, text: "Pour into a bowl and cover."),
                        InstructionStep(stepNumber: 4, text: "Leave in a warm place overnight to set."),
                        InstructionStep(stepNumber: 5, text: "Refrigerate before serving."),
                        InstructionStep(stepNumber: 6, text: "This yogurt can then be used instead of buttermilk to make more yogurt."),
                        InstructionStep(stepNumber: 7, text: "After using mixture a few times, switch to buttermilk for new starter.")
                    ]
                )
            ]
        )
    }
}

// MARK: - Instant Tomato Chutney
extension RecipeModel {
    static var instantTomatoChutney: RecipeModel {
        RecipeModel(
            title: "Instant Tomato Chutney",
            yield: "Makes ¾ cup (175 mL)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "½", unit: "cup", name: "ketchup and", metricQuantity: "125", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tbsp.", name: "water OR", metricQuantity: "30", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "", name: "medium tomato, blended"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "citric acid OR", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tbsp.", name: "lemon juice", metricQuantity: "30", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "chilli powder or to taste", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "salt", metricQuantity: "1", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Mix all ingredients into a smooth paste.")
                    ]
                )
            ],
            reference: "See photograph, page 16."
        )
    }
}

// MARK: - Kachumber
extension RecipeModel {
    static var kachumber: RecipeModel {
        RecipeModel(
            title: "Kachumber",
            yield: "Makes 1½ cups (375 mL)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "1", unit: "", name: "carrot"),
                        Ingredient(quantity: "1", unit: "", name: "onion"),
                        Ingredient(quantity: "1", unit: "", name: "tomato"),
                        Ingredient(quantity: "1½", unit: "tsp.", name: "chopped coriander leaves", metricQuantity: "7", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "", name: "salt to taste"),
                        Ingredient(quantity: "1", unit: "", name: "chilli powder to taste or chopped peppers"),
                        Ingredient(quantity: "1", unit: "tbsp.", name: "vinegar", metricQuantity: "15", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Cut carrot, onion and tomato into quarters and slice thinly."),
                        InstructionStep(text: "Add chopped coriander and the rest of the ingredients and mix well.")
                    ]
                )
            ]
        )
    }
}

// MARK: - Kadho
extension RecipeModel {
    static var kadho: RecipeModel {
        RecipeModel(
            title: "Kadho",
            headerNotes: "Saffron Milk - This is a traditional wedding drink. It is also an excellent cold remedy, with or without nuts.",
            yield: "Serves 6 to 7",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "4", unit: "cups", name: "milk", metricQuantity: "1", metricUnit: "L"),
                        Ingredient(quantity: "13½", unit: "oz.", name: "can evaporated milk", metricQuantity: "385", metricUnit: "mL"),
                        Ingredient(quantity: "⅓", unit: "cup", name: "condensed milk", metricQuantity: "150", metricUnit: "mL"),
                        Ingredient(quantity: "6-8", unit: "", name: "strands saffron"),
                        Ingredient(quantity: "⅓", unit: "cup", name: "chopped almonds", metricQuantity: "50", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tbsp.", name: "chopped pistachios", metricQuantity: "30", metricUnit: "mL"),
                        Ingredient(quantity: "¼", unit: "tsp.", name: "ground cardamom", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "ground nutmeg", metricQuantity: "0.5", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Bring regular milk to a boil, stirring continuously. Stir in other milks and rest of the ingredients. Continue cooking on medium heat, stirring continuously for 4 to 5 minutes and serve hot.")
                    ]
                )
            ],
            reference: "See photograph, page 16."
        )
    }
}

// MARK: - Lassi
extension RecipeModel {
    static var lassi: RecipeModel {
        RecipeModel(
            title: "Lassi",
            headerNotes: "Yogurt Sherbet - Very refreshing and cooling.",
            yield: "Serves 1 to 2",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "¾", unit: "cup", name: "plain yogurt", metricQuantity: "175", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "cup", name: "water", metricQuantity: "250", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "salt", metricQuantity: "0.5", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "ground black pepper", metricQuantity: "0.5", metricUnit: "mL"),
                        Ingredient(quantity: "⅛", unit: "tsp.", name: "cumin powder", metricQuantity: "0.5", metricUnit: "mL"),
                        Ingredient(quantity: "", unit: "", name: "ice cubes")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Combine all ingredients in the blender and blend until smooth. Serve. Sugar can be added instead of salt and pepper, if preferred.")
                    ]
                )
            ],
            reference: "See photograph, page 48."
        )
    }
}

// MARK: - Lemon Chutney
extension RecipeModel {
    static var lemonChutney: RecipeModel {
        RecipeModel(
            title: "Lemon Chutney",
            yield: "Makes 4 to 5 lbs. (2-2.5 kg)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "2", unit: "lbs.", name: "lemons", metricQuantity: "1", metricUnit: "kg"),
                        Ingredient(quantity: "1", unit: "tsp.", name: "turmeric", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tbsp.", name: "salt", metricQuantity: "15", metricUnit: "mL"),
                        Ingredient(quantity: "6", unit: "cups", name: "sugar", metricQuantity: "1.5", metricUnit: "L"),
                        Ingredient(quantity: "1½", unit: "tsp.", name: "chilli powder, or to taste", metricQuantity: "7", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Quarter each lemon, remove seeds and slice each quarter into thin slices, or chop in blender or food processor."),
                        InstructionStep(stepNumber: 2, text: "Sprinkle with turmeric and salt and set aside for 2-3 days."),
                        InstructionStep(stepNumber: 3, text: "Add sugar and boil mixture until syrup reaches 170 F (80 C) on a candy thermometer."),
                        InstructionStep(stepNumber: 4, text: "Add chilli powder and remove from heat."),
                        InstructionStep(stepNumber: 5, text: "Let cool and fill sterile glass jars.")
                    ]
                )
            ]
        )
    }
}

// MARK: - Mango Pickle in Oil
extension RecipeModel {
    static var mangoPickleInOil: RecipeModel {
        RecipeModel(
            title: "Mango Pickle in Oil",
            yield: "Makes 3 quarts (3 L)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "2", unit: "lbs.", name: "small, firm raw mangoes", metricQuantity: "1", metricUnit: "kg"),
                        Ingredient(quantity: "½", unit: "lb.", name: "hot peppers, halved", metricQuantity: "250", metricUnit: "g"),
                        Ingredient(quantity: "2½", unit: "tsp.", name: "turmeric powder", metricQuantity: "12", metricUnit: "mL"),
                        Ingredient(quantity: "8", unit: "tsp.", name: "salt", metricQuantity: "40", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "", name: "recipe Dried Carrots (page 15)"),
                        Ingredient(quantity: "½", unit: "cup", name: "vinegar", metricQuantity: "125", metricUnit: "mL"),
                        Ingredient(quantity: "4", unit: "cups", name: "oil", metricQuantity: "1", metricUnit: "L"),
                        Ingredient(quantity: "2", unit: "tbsp.", name: "coarsely ground coriander", metricQuantity: "30", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tbsp.", name: "coarsely ground fenugreek", metricQuantity: "30", metricUnit: "mL"),
                        Ingredient(quantity: "6", unit: "tbsp.", name: "coarsely ground mustard seeds", metricQuantity: "90", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tsp.", name: "salt", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tsp.", name: "chilli powder", metricQuantity: "10", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tsp.", name: "paprika powder", metricQuantity: "10", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tsp.", name: "black peppercorns", metricQuantity: "10", metricUnit: "mL"),
                        Ingredient(quantity: "5", unit: "", name: "cloves garlic, chopped OR"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "garlic powder", metricQuantity: "2", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Cut mangoes into pieces and discard seed."),
                        InstructionStep(stepNumber: 2, text: "Marinate mangoes and hot peppers in salt and turmeric for 2 days."),
                        InstructionStep(stepNumber: 3, text: "Soak carrot in vinegar."),
                        InstructionStep(stepNumber: 4, text: "Heat oil to 350°F (180°C) and set aside."),
                        InstructionStep(stepNumber: 5, text: "Mix rest of the dry ingredients and the garlic and add ½ cup (125 mL) hot oil and set aside."),
                        InstructionStep(stepNumber: 6, text: "Drain the mangoes and place on paper towel to drain more thoroughly."),
                        InstructionStep(stepNumber: 7, text: "Drain carrots on paper towel as well."),
                        InstructionStep(stepNumber: 8, text: "When all the water is absorbed from mangoes and carrots, rub in dry ingredient mixture and mix thoroughly."),
                        InstructionStep(stepNumber: 9, text: "Set aside for 2 days, turning occasionally."),
                        InstructionStep(stepNumber: 10, text: "Fill sterile glass jars and top with oil."),
                        InstructionStep(stepNumber: 11, text: "This pickle will keep for months unrefrigerated or will keep longer in refrigerator.")
                    ]
                )
            ],
            notes: [
                RecipeNote(type: .general, text: "Coarsely ground coriander, fenugreek and mustard are always used ready-made but can be purchased from an Indian grocery store.")
            ]
        )
    }
}

// MARK: - Sherbet
extension RecipeModel {
    static var sherbet: RecipeModel {
        RecipeModel(
            title: "Sherbet",
            headerNotes: "Milk Shake - A traditional wedding drink.",
            yield: "Serves 8 to 10",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "4", unit: "cups", name: "homogenized milk", metricQuantity: "1", metricUnit: "L"),
                        Ingredient(quantity: "13½", unit: "oz.", name: "can evaporated milk", metricQuantity: "385", metricUnit: "mL"),
                        Ingredient(quantity: "⅓", unit: "cup", name: "condensed milk", metricQuantity: "150", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "cup", name: "strawberry cream", metricQuantity: "250", metricUnit: "mL"),
                        Ingredient(quantity: "⅓", unit: "cup", name: "chopped almonds", metricQuantity: "50", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tbsp.", name: "chopped unsalted pistachios", metricQuantity: "30", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tsp.", name: "vanilla essence", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "4-6", unit: "", name: "drops rose essence"),
                        Ingredient(quantity: "", unit: "", name: "pink food colour (for pure pink colour)"),
                        Ingredient(quantity: "", unit: "", name: "ice")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Stir all ingredients together and serve cold.")
                    ]
                )
            ],
            reference: "See photograph, page 7."
        )
    }
}

// MARK: - Vegetable Soup
extension RecipeModel {
    static var vegetableSoup: RecipeModel {
        RecipeModel(
            title: "Vegetable Soup",
            yield: "Serves 4 to 5",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "½", unit: "cup", name: "masoor (lentils)", metricQuantity: "50", metricUnit: "mL"),
                        Ingredient(quantity: "1½", unit: "cups", name: "mixed vegetables (peas, celery, onion, beans, carrots, cauliflower, cabbage, potatoes)", metricQuantity: "375", metricUnit: "mL"),
                        Ingredient(quantity: "3", unit: "cups", name: "water", metricQuantity: "750", metricUnit: "mL"),
                        Ingredient(quantity: "", unit: "", name: "salt, pepper"),
                        Ingredient(quantity: "1", unit: "tbsp.", name: "rolled oats", metricQuantity: "15", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(text: "Soak masoor (lentils) overnight, in water to cover. Wash and drain before adding to the soup."),
                        InstructionStep(text: "Put all ingredients in a saucepan. Bring to a boil. Lower heat and cook until vegetables are tender and broth is reduced to your desired consistency.")
                    ]
                )
            ]
        )
    }
}

// MARK: - Vegetable Sambhar
extension RecipeModel {
    static var vegetableSambhar: RecipeModel {
        RecipeModel(
            title: "Vegetable Sambhar",
            headerNotes: "Cold Marinated Vegetables",
            yield: "Makes 4 cups (1 L)",
            ingredientSections: [
                IngredientSection(
                    ingredients: [
                        Ingredient(quantity: "½", unit: "cup", name: "oil", metricQuantity: "125", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tsp.", name: "mustard seeds", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "¼", unit: "tsp.", name: "cumin seeds", metricQuantity: "1", metricUnit: "mL"),
                        Ingredient(quantity: "10-12", unit: "", name: "curry leaves* (Lindho)"),
                        Ingredient(quantity: "10-12", unit: "", name: "hot peppers, halved"),
                        Ingredient(quantity: "1", unit: "", name: "medium cabbage, shredded"),
                        Ingredient(quantity: "3", unit: "", name: "large carrots, cut into strips"),
                        Ingredient(quantity: "1", unit: "", name: "small raw mango, cut into pieces"),
                        Ingredient(quantity: "1", unit: "tsp.", name: "cumin powder", metricQuantity: "5", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "crushed garlic", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "turmeric powder", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "1½", unit: "tsp.", name: "salt", metricQuantity: "7", metricUnit: "mL"),
                        Ingredient(quantity: "½", unit: "tsp.", name: "chilli powder", metricQuantity: "2", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tbsp.", name: "lemon juice, or to taste", metricQuantity: "30", metricUnit: "mL"),
                        Ingredient(quantity: "2", unit: "tbsp.", name: "sugar", metricQuantity: "30", metricUnit: "mL"),
                        Ingredient(quantity: "1", unit: "tbsp.", name: "Tamarind Chutney (see page 17)", metricQuantity: "15", metricUnit: "mL")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Heat oil, add mustard seeds, cumin seeds, curry leaves and hot peppers."),
                        InstructionStep(stepNumber: 2, text: "Add cabbage, carrots and mango and cook on low heat until cabbage is transparent."),
                        InstructionStep(stepNumber: 3, text: "Add cumin powder, garlic, turmeric, salt and chilli powder and continue to cook until carrots are tender."),
                        InstructionStep(stepNumber: 4, text: "Add lemon juice, sugar, Tamarind Chutney and continue cooking until all the liquid is absorbed."),
                        InstructionStep(stepNumber: 5, text: "Serve with any curry dish.")
                    ]
                ),
                InstructionSection(
                    title: "Variation",
                    steps: [
                        InstructionStep(text: "1 tbsp. (15 mL) gram flour can be added and sautéed for ½ minute just before adding cabbage."),
                        InstructionStep(text: "Bell peppers can be used instead of hot peppers or combine bell peppers and hot peppers to reduce the hot taste.")
                    ]
                )
            ],
            notes: [
                RecipeNote(type: .general, text: "*Curry leaves are like bay leaves but much smaller.")
            ]
        )
    }
}
