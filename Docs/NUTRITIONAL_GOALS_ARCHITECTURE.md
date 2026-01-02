# Nutritional Goals System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERFACE                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐   ┌──────────────────┐                  │
│  │ AllergenProfile  │   │  RecipeDetail    │                  │
│  │      View        │   │      View        │                  │
│  │                  │   │                  │                  │
│  │  ┌────────────┐  │   │  ┌────────────┐  │                  │
│  │  │ Set Goals  │  │   │  │  Show      │  │                  │
│  │  │   Button   │  │   │  │ Analysis   │  │                  │
│  │  └────────────┘  │   │  └────────────┘  │                  │
│  └──────────────────┘   └──────────────────┘                  │
│           │                       │                            │
│           ▼                       ▼                            │
│  ┌──────────────────┐   ┌──────────────────┐                  │
│  │ Nutritional      │   │   Recipe         │                  │
│  │  Goals View      │   │ Nutritional      │                  │
│  │                  │   │   Section        │                  │
│  │  - Preset picker │   │                  │                  │
│  │  - Nutrient form │   │  - Score display │                  │
│  │  - Validation    │   │  - Percentages   │                  │
│  └──────────────────┘   │  - Alerts        │                  │
│                         └──────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DATA LAYER                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         UserAllergenProfile (SwiftData Model)            │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │ • id: UUID                                          │ │  │
│  │  │ • name: String                                      │ │  │
│  │  │ • isActive: Bool                                    │ │  │
│  │  │ • sensitivitiesData: Data?                         │ │  │
│  │  │ • diabetesStatusRaw: String                        │ │  │
│  │  │ • nutritionalGoalsData: Data?  ◄── NEW (V3.0.0)   │ │  │
│  │  │ • dateCreated: Date                                │ │  │
│  │  │ • dateModified: Date                               │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  │                                                            │  │
│  │  Computed Properties:                                      │  │
│  │  • nutritionalGoals: NutritionalGoals? ◄── Decode Data   │  │
│  │  • hasNutritionalGoals: Bool                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              │ stores                           │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         NutritionalGoals (Struct - Codable)              │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │ Core Macronutrients:                                │ │  │
│  │  │  • dailyCalories: Double?                          │ │  │
│  │  │  • dailyProtein: Double?                           │ │  │
│  │  │  • dailyCarbohydrates: Double?                     │ │  │
│  │  │  • dailyTotalFat: Double?                          │ │  │
│  │  │                                                      │ │  │
│  │  │ Heart Health:                                       │ │  │
│  │  │  • dailySaturatedFat: Double?                      │ │  │
│  │  │  • dailyTransFat: Double?                          │ │  │
│  │  │  • dailySodium: Double?                            │ │  │
│  │  │  • dailyCholesterol: Double?                       │ │  │
│  │  │                                                      │ │  │
│  │  │ Blood Sugar:                                        │ │  │
│  │  │  • dailySugar: Double?                             │ │  │
│  │  │  • dailyAddedSugar: Double?                        │ │  │
│  │  │  • dailyFiber: Double?                             │ │  │
│  │  │                                                      │ │  │
│  │  │ Minerals:                                           │ │  │
│  │  │  • dailyPotassium: Double?                         │ │  │
│  │  │  • dailyCalcium: Double?                           │ │  │
│  │  │                                                      │ │  │
│  │  │ Meta:                                               │ │  │
│  │  │  • goalType: GoalType (enum)                       │ │  │
│  │  │  • dateSet: Date                                   │ │  │
│  │  │  • dateModified: Date                              │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  │                                                            │  │
│  │  Preset Templates:                                         │  │
│  │  • .weightLoss (1,500 cal)                                │  │
│  │  • .diabetesManagement (1,800 cal)                        │  │
│  │  • .heartHealth (2,000 cal, DASH)                         │  │
│  │  • .generalHealth (2,000 cal)                             │  │
│  │  • .athleticPerformance (2,800 cal)                       │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ANALYSIS ENGINE                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         NutritionalAnalyzer (Singleton Class)            │  │
│  │                                                            │  │
│  │  Input:                                                    │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │ • RecipeModel                                        │  │  │
│  │  │ • NutritionalGoals                                   │  │  │
│  │  │ • Servings (optional)                                │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                        │                                   │  │
│  │                        ▼                                   │  │
│  │  Processing Steps:                                         │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │ 1. Extract ingredients from recipe                   │  │  │
│  │  │ 2. Parse explicit nutrition (if in notes)            │  │  │
│  │  │ 3. Estimate nutrition from keywords                  │  │  │
│  │  │ 4. Calculate % of daily goals                        │  │  │
│  │  │ 5. Generate alerts for high-risk nutrients           │  │  │
│  │  │ 6. Add positive alerts (high fiber, etc.)            │  │  │
│  │  │ 7. Calculate compatibility score (0-100)             │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                        │                                   │  │
│  │                        ▼                                   │  │
│  │  Output:                                                   │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │ NutritionalScore                                     │  │  │
│  │  │  • nutrition: RecipeNutrition                       │  │  │
│  │  │  • dailyPercentages: [String: Double]               │  │  │
│  │  │  • alerts: [NutritionAlert]                         │  │  │
│  │  │  • compatibilityScore: Double (0-100)               │  │  │
│  │  │  • servings: Int                                    │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                                                            │  │
│  │  Helper Methods:                                           │  │
│  │  • filterCompatibleRecipes()                              │  │
│  │  • sortRecipesByCompatibility()                           │  │
│  │  • analyzeRecipes() - batch analysis                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DISPLAY COMPONENTS                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐   ┌──────────────────┐                  │
│  │ Nutritional      │   │ Nutritional      │                  │
│  │   Badge          │   │   Badge          │                  │
│  │   (Compact)      │   │  (Expanded)      │                  │
│  │                  │   │                  │                  │
│  │  ┌────────────┐  │   │  ┌────────────┐  │                  │
│  │  │ 85% [✓]    │  │   │  │ Score: 85% │  │                  │
│  │  └────────────┘  │   │  │            │  │                  │
│  │                  │   │  │ Percentages│  │                  │
│  │  For recipe list │   │  │ • Sodium   │  │                  │
│  │                  │   │  │ • Fat      │  │                  │
│  └──────────────────┘   │  │            │  │                  │
│                         │  │ Alerts     │  │                  │
│                         │  │ ⚠️ High Na │  │                  │
│                         │  │ ✅ Hi Fiber│  │                  │
│                         │  └────────────┘  │                  │
│                         │                  │                  │
│                         │  For detail view │                  │
│                         └──────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Setting Goals Flow

```
User Action                 Data Layer                CloudKit
    │                           │                         │
    │ 1. Select preset          │                         │
    ├──────────────────────────►│                         │
    │                           │                         │
    │ 2. Modify values          │                         │
    ├──────────────────────────►│                         │
    │                           │                         │
    │ 3. Press Save             │                         │
    ├──────────────────────────►│                         │
    │                           │ 4. Encode to Data       │
    │                           ├────────────┐            │
    │                           │◄───────────┘            │
    │                           │ 5. Save to SwiftData    │
    │                           ├────────────┐            │
    │                           │◄───────────┘            │
    │                           │ 6. Trigger sync         │
    │                           ├────────────────────────►│
    │                           │                         │ 7. Upload
    │                           │                         ├──────►
    │◄──────────────────────────┤                         │
    │ 8. Dismiss                │                         │
```

### Recipe Analysis Flow

```
View Request               Analyzer                  Profile
    │                         │                          │
    │ 1. Analyze recipe       │                          │
    ├────────────────────────►│                          │
    │                         │ 2. Get goals             │
    │                         ├─────────────────────────►│
    │                         │◄─────────────────────────┤
    │                         │ 3. Goals returned        │
    │                         │                          │
    │                         │ 4. Extract ingredients   │
    │                         ├─────────┐                │
    │                         │◄────────┘                │
    │                         │                          │
    │                         │ 5. Parse nutrition       │
    │                         ├─────────┐                │
    │                         │◄────────┘                │
    │                         │                          │
    │                         │ 6. Calculate percentages │
    │                         ├─────────┐                │
    │                         │◄────────┘                │
    │                         │                          │
    │                         │ 7. Generate alerts       │
    │                         ├─────────┐                │
    │                         │◄────────┘                │
    │                         │                          │
    │                         │ 8. Calculate score       │
    │                         ├─────────┐                │
    │                         │◄────────┘                │
    │                         │                          │
    │◄────────────────────────┤                          │
    │ 9. Return score         │                          │
    │                         │                          │
    ▼                         │                          │
Display results              │                          │
```

### Filtering Flow

```
ContentView              Filter Engine            Analyzer
    │                         │                       │
    │ 1. User changes filter  │                       │
    ├────────────────────────►│                       │
    │                         │                       │
    │                         │ 2. Check mode         │
    │                         ├──────┐                │
    │                         │◄─────┘                │
    │                         │                       │
    │                         │ 3. Analyze all recipes│
    │                         ├──────────────────────►│
    │                         │                       │
    │                         │                       │ 4. Process
    │                         │                       │    batch
    │                         │                       ├─────►
    │                         │◄──────────────────────┤
    │                         │ 5. Scores returned    │
    │                         │                       │
    │                         │ 6. Sort by score      │
    │                         ├──────┐                │
    │                         │◄─────┘                │
    │                         │                       │
    │◄────────────────────────┤                       │
    │ 7. Update UI            │                       │
    │                         │                       │
    ▼                         │                       │
Show filtered list           │                       │
```

## Component Dependencies

```
┌───────────────────────────────────────────────────────┐
│                   SwiftUI Views                       │
│  • NutritionalGoalsView                              │
│  • NutritionalBadge                                  │
│  • RecipeNutritionalSection                          │
└────────────────┬──────────────────────────────────────┘
                 │ uses
                 ▼
┌───────────────────────────────────────────────────────┐
│                   Data Models                         │
│  • NutritionalGoals (struct)                         │
│  • UserAllergenProfile (SwiftData)                   │
└────────────────┬──────────────────────────────────────┘
                 │ consumed by
                 ▼
┌───────────────────────────────────────────────────────┐
│                  Analysis Engine                      │
│  • NutritionalAnalyzer                               │
│  • RecipeNutrition (struct)                          │
│  • NutritionalScore (struct)                         │
│  • NutritionAlert (struct)                           │
└────────────────┬──────────────────────────────────────┘
                 │ produces
                 ▼
┌───────────────────────────────────────────────────────┐
│                   Display Models                      │
│  • Scores, alerts, percentages                       │
│  • Color-coded results                               │
└───────────────────────────────────────────────────────┘
```

## Medical Guidelines Source Map

```
                        Medical Sources
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│     AHA      │     │     ADA      │     │     CDC      │
│              │     │              │     │              │
│ • Sodium     │     │ • Carbs      │     │ • General    │
│ • Sat Fat    │     │ • Fiber      │     │   limits     │
│ • Trans Fat  │     │ • Sugar      │     │ • Population │
│ • Sugar      │     │ • Diabetes   │     │   guidelines │
│ • Potassium  │     │   guidelines │     │              │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       └────────────────────┼────────────────────┘
                            │
                            ▼
                ┌────────────────────────┐
                │  NutritionalGoals      │
                │      Presets           │
                │                        │
                │ • Weight Loss          │
                │ • Diabetes Mgmt        │
                │ • Heart Health         │
                │ • General Health       │
                │ • Athletic Perf        │
                └────────────────────────┘
```

## File Structure

```
Reczipes2/
├── Models/
│   ├── UserAllergenProfile.swift         (Updated - V3.0.0)
│   ├── NutritionalGoals.swift            (New)
│   └── RecipeModel.swift                 (Existing)
│
├── Analyzers/
│   ├── AllergenAnalyzer.swift            (Existing)
│   ├── DiabetesAnalyzer.swift            (Existing)
│   └── NutritionalAnalyzer.swift         (New)
│
├── Views/
│   ├── ContentView.swift                 (Existing - needs updates)
│   ├── AllergenProfileView.swift         (Existing - needs updates)
│   ├── RecipeDetailView.swift            (Existing - needs updates)
│   ├── NutritionalGoalsView.swift        (New)
│   ├── NutritionalBadge.swift            (New)
│   └── RecipeNutritionalSection.swift    (New)
│
├── Documentation/
│   ├── NUTRITIONAL_GOALS_SUMMARY.md      (New)
│   ├── NUTRITIONAL_GOALS_GUIDE.md        (New)
│   ├── MEDICAL_GUIDELINES_REFERENCE.md   (New)
│   └── NUTRITIONAL_GOALS_CHECKLIST.md    (New)
│
└── VersionHistory.swift                  (Updated)
```

## State Management

```
                     App State
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Profile    │  │   Recipes    │  │   Filters    │
│    State     │  │    State     │  │    State     │
│              │  │              │  │              │
│ • Active     │  │ • All        │  │ • Mode       │
│   profile    │  │   recipes    │  │ • Show safe  │
│ • Goals set? │  │ • Selected   │  │ • Cached     │
│              │  │   recipe     │  │   scores     │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │
                         ▼
                   UI Updates
```

## Performance Considerations

```
┌─────────────────────────────────────────────────────┐
│              Performance Strategy                   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. Caching Layer                                  │
│     • Cache analyzed scores                        │
│     • Invalidate on recipe/goals change            │
│     • Store in @State for quick access             │
│                                                     │
│  2. Background Processing                          │
│     • Use Task.detached for analysis               │
│     • Process in batches                           │
│     • Show loading indicator                       │
│                                                     │
│  3. Lazy Loading                                   │
│     • Analyze on-demand for detail view            │
│     • Batch analyze for list filtering             │
│     • Skip if no goals set                         │
│                                                     │
│  4. Data Optimization                              │
│     • Store as compressed Data                     │
│     • Only decode when needed                      │
│     • Use computed properties                      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Error Handling

```
┌─────────────────────────────────────────────────────┐
│               Error Scenarios                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. No Goals Set                                   │
│     → Show prompt to set goals                     │
│     → Provide quick setup button                   │
│                                                     │
│  2. Incomplete Nutrition Data                      │
│     → Show "estimated" disclaimer                  │
│     → Offer to add manual data                     │
│                                                     │
│  3. Analysis Failure                               │
│     → Log error                                    │
│     → Show user-friendly message                   │
│     → Allow retry                                  │
│                                                     │
│  4. CloudKit Sync Issues                           │
│     → Handle gracefully                            │
│     → Show sync status                             │
│     → Retry automatically                          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

This architecture provides:
- ✅ Clear separation of concerns
- ✅ Testable components
- ✅ Scalable design
- ✅ Performance optimized
- ✅ User-friendly error handling
- ✅ Medical guideline compliance
