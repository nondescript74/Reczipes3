# Medical Nutrition Guidelines Reference

Quick reference for the nutritional guidelines implemented in Reczipes.

## Sources

- **AHA** - American Heart Association (heart.org)
- **ADA** - American Diabetes Association (diabetes.org)
- **CDC** - Centers for Disease Control and Prevention (cdc.gov)
- **DGA** - Dietary Guidelines for Americans 2020-2025 (dietaryguidelines.gov)

## Daily Limits & Targets

### Macronutrients

| Nutrient | General Population | Weight Loss | Diabetes | Heart Health | Notes |
|----------|-------------------|-------------|----------|--------------|-------|
| **Calories** | 2,000 (baseline) | 1,500 | 1,800 | 2,000 | Varies by age, sex, activity |
| **Protein** | 46-56g (0.8g/kg) | 75g (20%) | 90g (20%) | 100g (20%) | ADA: 15-20% of calories |
| **Carbohydrates** | 275g (55%) | 169g (45%) | 180g (40%) | 250g (50%) | ADA: 45-60% for diabetes |
| **Total Fat** | 44-77g (25-35%) | 58g (35%) | 70g (35%) | 67g (30%) | Focus on unsaturated fats |

### Critical Limits (Heart Health)

| Nutrient | AHA Recommendation | CDC Recommendation | Notes |
|----------|-------------------|-------------------|-------|
| **Sodium** | Ideal: <1,500mg<br>Max: 2,300mg | <2,300mg | Lower for hypertension/diabetes |
| **Saturated Fat** | <6% of calories<br>(~13g for 2,000 cal) | <10% of calories<br>(~22g for 2,000 cal) | ADA: <7% for diabetes |
| **Trans Fat** | As low as possible | <1% of calories<br>(~2g for 2,000 cal) | AHA: Eliminate completely |
| **Cholesterol** | <300mg | <300mg | ADA: <200mg for diabetes |

### Blood Sugar Management

| Nutrient | ADA Recommendation | Notes |
|----------|-------------------|-------|
| **Carbohydrates** | 45-60g per meal (135-180g daily) | Focus on complex carbs |
| **Fiber** | 25-30g daily | Helps regulate blood sugar |
| **Sugar** | Limit added sugars | No specific limit, minimize |
| **Added Sugar** | <10% of calories | AHA: Women 25g, Men 36g |

### Beneficial Nutrients

| Nutrient | Target | Source | Benefits |
|----------|--------|--------|----------|
| **Fiber** | Women: 21-25g<br>Men: 30-38g | DGA | Digestive health, blood sugar control |
| **Potassium** | 2,600-4,700mg | AHA | Counters sodium, heart health |
| **Calcium** | 1,000-1,200mg | CDC | Bone health |

## Preset Templates

### 1. Weight Loss (1,500 cal)
**Goal**: 500 cal deficit for ~1 lb/week loss

```
Calories:       1,500 kcal
Protein:        75g (20%)
Carbohydrates:  169g (45%)
Total Fat:      58g (35%)
Saturated Fat:  10g (<7%)
Sodium:         1,500mg (AHA ideal)
Fiber:          28g
Sugar:          25g (AHA women's limit)
```

**Notes**: 
- Moderate deficit, sustainable long-term
- Higher protein preserves muscle mass
- Low sodium reduces water retention

### 2. Diabetes Management (1,800 cal)
**Goal**: Blood sugar control, stable energy

```
Calories:       1,800 kcal
Protein:        90g (20%)
Carbohydrates:  180g (40%, 60g per meal)
Total Fat:      70g (35%)
Saturated Fat:  12g (<7%)
Sodium:         1,500mg
Fiber:          30g (ADA recommendation)
Added Sugar:    18g (<10%)
Cholesterol:    200mg (ADA limit)
```

**Notes**:
- 60g carbs per meal prevents spikes
- High fiber slows glucose absorption
- Low saturated fat protects heart

### 3. Heart Health / DASH Diet (2,000 cal)
**Goal**: Reduce cardiovascular risk

```
Calories:       2,000 kcal
Protein:        100g (20%)
Carbohydrates:  250g (50%)
Total Fat:      67g (30%)
Saturated Fat:  13g (<6% AHA ideal)
Trans Fat:      0g (eliminate)
Sodium:         1,500mg (AHA ideal)
Potassium:      4,700mg (high, DASH)
Calcium:        1,200mg (DASH)
Fiber:          30g
Cholesterol:    200mg
```

**Notes**:
- Lowest sodium target
- High potassium counters sodium
- DASH diet proven to lower BP

### 4. General Health (2,000 cal)
**Goal**: Balanced nutrition, maintain health

```
Calories:       2,000 kcal
Protein:        100g (20%)
Carbohydrates:  275g (55%)
Total Fat:      56g (25%)
Saturated Fat:  22g (<10%)
Sodium:         2,300mg (CDC limit)
Fiber:          28g (14g per 1000 cal)
Sugar:          50g (<10%)
```

**Notes**:
- Standard baseline
- Follows DGA 2020-2025
- Suitable for most adults

### 5. Athletic Performance (2,800 cal)
**Goal**: Support training, recovery

```
Calories:       2,800 kcal
Protein:        140g (20%, 1.2-2.0g/kg)
Carbohydrates:  385g (55%, fuel for activity)
Total Fat:      78g (25%)
Sodium:         3,000mg (replace sweat losses)
Potassium:      4,700mg (replace losses)
Calcium:        1,200mg (bone health)
Fiber:          35g
```

**Notes**:
- Higher calories for energy needs
- More protein for muscle repair
- Higher sodium for athletes

## Risk Categories

### Sodium Levels
- **Low**: <800mg per meal (green)
- **Moderate**: 800-1,200mg per meal (yellow)
- **High**: >1,200mg per meal (red)

### Saturated Fat Levels (2,000 cal diet)
- **Low**: <7g per meal (green)
- **Moderate**: 7-11g per meal (yellow)
- **High**: >11g per meal (red)

### Sugar Levels
- **Low**: <8g per meal (green)
- **Moderate**: 8-17g per meal (yellow)
- **High**: >17g per meal (red)

### Fiber Levels
- **Low**: <3g per meal (need more)
- **Good**: 3-5g per meal (green)
- **Excellent**: >5g per meal (blue star)

## Population-Specific Guidelines

### Women
- Calories: 1,600-2,400 (based on activity)
- Protein: 46g minimum (0.8g/kg)
- Fiber: 21-25g
- Added Sugar: <25g (AHA)

### Men
- Calories: 2,000-3,000 (based on activity)
- Protein: 56g minimum (0.8g/kg)
- Fiber: 30-38g
- Added Sugar: <36g (AHA)

### Older Adults (50+)
- Calcium: Increase to 1,200mg
- Vitamin D: Increase (aids calcium absorption)
- Protein: May need 1.0-1.2g/kg (preserve muscle)
- Calories: May decrease (lower metabolism)

### Children & Adolescents
⚠️ **Not covered in this implementation**
- Consult pediatrician for guidelines
- Different needs based on growth stage

## Medical Conditions

### Hypertension (High Blood Pressure)
- Sodium: <1,500mg (AHA)
- Potassium: 4,700mg (helps lower BP)
- Follow DASH diet principles
- Reduce saturated fat

### Type 2 Diabetes
- Carbs: 45-60g per meal
- Fiber: 25-30g (slows glucose absorption)
- Saturated Fat: <7% of calories
- Cholesterol: <200mg
- Monitor glycemic index

### High Cholesterol
- Saturated Fat: Minimize
- Trans Fat: Eliminate
- Cholesterol: <200mg
- Increase soluble fiber (oats, beans)
- Add omega-3 fatty acids

### Chronic Kidney Disease
⚠️ **Requires medical supervision**
- Sodium: Restrict further
- Potassium: May need restriction
- Protein: May need reduction
- **Always consult nephrologist**

## Glycemic Index (GI) Reference

### Low GI Foods (<55) - Best for Diabetes
- Most non-starchy vegetables
- Legumes (beans, lentils)
- Whole grains (oats, barley, quinoa)
- Most fruits (berries, apples)

### Medium GI Foods (56-69) - Moderate
- Brown rice
- Whole wheat bread
- Sweet potatoes
- Bananas

### High GI Foods (>70) - Limit for Diabetes
- White bread, white rice
- Potatoes (white, mashed)
- Sugary drinks
- Candy, pastries

## Disclaimer

⚠️ **IMPORTANT MEDICAL DISCLAIMER**

These guidelines are for informational purposes only and are NOT medical advice. 

**Always consult with qualified healthcare providers:**
- Registered Dietitian (RD) for personalized nutrition
- Physician for medical conditions
- Diabetes Educator for diabetes management
- Cardiologist for heart health

**Individual needs vary based on:**
- Age, sex, body composition
- Activity level
- Medical conditions
- Medications
- Pregnancy/breastfeeding status
- Personal health goals

**This app is a tool, not a replacement for professional medical care.**

## Updates & Research

Guidelines are updated periodically by medical organizations:
- AHA updates cardiovascular guidelines every 3-5 years
- ADA updates diabetes standards annually
- DGA updated every 5 years (last: 2020-2025, next: 2025-2030)

Always check official sources for latest recommendations:
- https://www.heart.org
- https://www.diabetes.org
- https://www.cdc.gov/nutrition
- https://www.dietaryguidelines.gov

## Implementation Notes

```swift
// In your code, access these via:
let goals = NutritionalGoals.preset(for: .heartHealth)

// Daily limits:
print("Sodium limit: \(goals.dailySodium ?? 0)mg")
print("Saturated fat: \(goals.dailySaturatedFat ?? 0)g")

// Analyze recipe:
let score = NutritionalAnalyzer.shared.analyzeRecipe(recipe, goals: goals)
print("Compatibility: \(score.compatibilityScore)%")
```

---

**Last Updated**: January 2, 2026
**Based On**: AHA 2024, ADA 2024, CDC 2024, DGA 2020-2025
