# Diabetic-Friendly Analysis - User Guide

## What Is Diabetic-Friendly Analysis?

The diabetic-friendly analysis feature provides informational guidance to help you make informed decisions about recipes and blood sugar management. This feature uses artificial intelligence to analyze recipe ingredients and provide:

- **Glycemic Load Estimates** - How the recipe might impact blood sugar
- **Carbohydrate Breakdown** - Total carbs, net carbs, fiber, and sugar content
- **Practical Guidance** - Tips for preparing recipes in blood-sugar-friendly ways
- **Ingredient Substitutions** - Lower glycemic index alternatives
- **Medical Sources** - Citations from ADA, Mayo Clinic, CDC, and NIH

---

## ⚠️ Important: This Is Not Medical Advice

**Please Read Carefully:**

This feature provides **informational content only** and is **not medical, dietary, or nutritional advice.**

✋ **You should:**
- Consult your healthcare provider before making dietary changes
- Verify all nutritional information independently
- Monitor your blood glucose as directed by your medical team
- Work with a registered dietitian for personalized meal planning
- Understand that individual responses to foods vary significantly

🚫 **This feature does NOT:**
- Replace blood glucose monitoring
- Substitute for medical advice from your healthcare team
- Guarantee accuracy of glycemic load or carbohydrate calculations
- Account for your specific medications, health conditions, or metabolism
- Provide insulin dosing or medication adjustment guidance

---

## How to Use This Feature

### Step 1: Enable the Feature

1. Open **Settings** (gear icon)
2. Go to **Dietary Preferences** → **Diabetic-Friendly Analysis**
3. Toggle **"Enable Diabetic-Friendly Analysis"** to ON
4. Read the information and disclaimer
5. Customize display options if desired

### Step 2: Analyze a Recipe

1. Open any saved recipe
2. Scroll to the **"Diabetic-Friendly Analysis"** section
3. Tap **"Analyze for Diabetic-Friendly Info"**
4. Wait 10-15 seconds for the analysis
5. Review the results

### Step 3: Understand the Results

The analysis provides several sections:

#### 📊 Glycemic Impact Card
- **Glycemic Load Number**: Estimated impact (Low: ≤10, Medium: 11-20, High: >20)
- **Color Bar**: Visual indicator (green, yellow, or red)
- **Explanation**: How the calculation was performed

#### 🍞 Carbohydrate Breakdown
- **Total Carbs**: All carbohydrates in the recipe
- **Net Carbs**: Total carbs minus fiber
- **Fiber**: Dietary fiber content
- **Sugars**: Natural and added sugars

#### 💡 Guidance Cards
- **Expandable Tips**: Tap to see full details
- **Practical Advice**: Meal timing, portion control, pairing strategies
- **Icon Indicators**: Quick identification of guidance type

#### 🔄 Substitution Suggestions
- **Original Ingredient**: What the recipe calls for
- **Healthier Alternative**: Lower glycemic option
- **Why It's Better**: Explanation of the benefit

#### 📚 Source Verification
- **Consensus Badge**: Agreement level between sources
  - ✓ **Verified**: Strong consensus (3+ sources)
  - ⓘ **Moderate**: Moderate consensus (2 sources)
  - ⚠️ **Limited**: Limited evidence (1 source or conflicts)
  - ⚠️ **Review**: Needs review (outdated or no sources)
- **Last Updated**: When the analysis was performed
- **Tap to View Sources**: See full citations with URLs

---

## Understanding Glycemic Load

### What Is Glycemic Load?

Glycemic Load (GL) is an estimate of how much a food might raise blood sugar levels. It's calculated using:

```
GL = (Glycemic Index × Net Carbs per Serving) / 100
```

### Interpreting the Numbers

| Glycemic Load | Classification | What It Means |
|---------------|----------------|---------------|
| ≤ 10 | Low | Minimal blood sugar impact |
| 11-20 | Medium | Moderate blood sugar impact |
| > 20 | High | Significant blood sugar impact |

### Important Limitations

⚠️ **Glycemic load is an estimate, not a guarantee:**

- Individual responses vary based on:
  - Overall health and diabetes type
  - Current medications
  - Activity level
  - What else you eat with the meal
  - Portion sizes
  - How the food is prepared
  - Time of day

- Actual impact can only be measured with blood glucose monitoring

---

## Display Options

Customize how the analysis appears:

### Show Glycemic Load Indicators
When enabled, shows the glycemic impact prominently with color-coded bars.

**Use this if:** You want quick visual feedback about blood sugar impact.

### Highlight High GI Ingredients
When enabled, ingredients with glycemic index > 70 are marked.

**Use this if:** You want to identify high-impact ingredients quickly.

### Auto-Expand Guidance
When enabled, all guidance cards open by default.

**Use this if:** You prefer seeing all details without tapping.

---

## Data and Privacy

### What Data Is Sent to Analyze Recipes?

When you request analysis:
- Recipe ingredients (names, quantities)
- Recipe instructions
- Recipe title and serving size

This data is sent to Claude AI (by Anthropic) for analysis.

### What Is NOT Sent or Stored?

✅ **Protected:**
- Your diabetic status (we never ask)
- Your blood glucose readings
- Your medications or health conditions
- Which recipes you analyze
- Your analysis history

### How Long Are Results Cached?

- **30 days** - Results are saved locally on your device
- **Why?** Improves speed and reduces API costs
- **Last Updated** - Date shown at bottom of every analysis
- **Manual Refresh** - Force new analysis if needed (future feature)

### Is Anything Shared?

**No.** All analysis results are:
- ✅ Stored locally on your device only
- ✅ Never synced to the cloud
- ✅ Never shared with third parties
- ✅ Completely private to you

---

## Source Quality and Verification

### Which Sources Are Used?

The analysis prioritizes these reputable medical sources:

**High Priority:**
- American Diabetes Association (ADA)
- Mayo Clinic
- Centers for Disease Control and Prevention (CDC)
- National Institutes of Health (NIH)
- Peer-reviewed medical journals

**Source Requirements:**
- Published between 2023-2025 (current guidelines)
- From recognized medical institutions
- Peer-reviewed or professionally edited

**NOT Used:**
- Blogs or personal websites
- Forums or social media
- Commercial diet sites
- Non-medical sources

### How to Verify Sources

1. Tap the **source footer** at the bottom of the analysis
2. View the **Sources Detail Sheet**
3. See the **organization name** and **publish date**
4. Tap any **URL** to visit the source directly
5. Read the original content for yourself

### What If Sources Conflict?

When medical sources disagree:
- The analysis notes the conflict with neutral language
- Example: "Some sources suggest... while others recommend..."
- The **Consensus Badge** shows "Limited Evidence" or "Moderate"
- You see both perspectives to make your own informed decision

---

## Tips for Best Results

### ✅ Do:
- Use this feature as **one tool** among many
- **Verify** calculations with your healthcare team
- **Monitor** your actual blood glucose response
- **Compare** with other reputable sources
- **Adapt** recipes to your specific needs
- **Consider** portion sizes carefully

### ❌ Don't:
- Replace medical advice with this feature
- Skip blood glucose monitoring
- Adjust medications based on this information
- Assume estimates match your individual response
- Ignore guidance from your healthcare team

---

## Troubleshooting

### Analysis Takes Too Long
**Normal:** 10-15 seconds  
**Timeout:** Up to 2 minutes

**If it fails:**
- Check your internet connection
- Verify your API key is configured (Settings → API Key)
- Try again later (service may be temporarily busy)

### "API Key Not Configured"
1. Go to Settings → Recipe Extraction
2. Tap "Manage API Key"
3. Enter your Claude API key
4. Get a key at: https://console.anthropic.com

### "Failed to Analyze Recipe"
**Common reasons:**
- No internet connection
- Recipe data incomplete
- API service temporarily unavailable
- API credit balance low

**Solutions:**
- Check internet connection
- Verify recipe has ingredients and instructions
- Try again in a few minutes
- Check Claude API dashboard for credit balance

### Results Seem Inaccurate
**Remember:**
- AI can make mistakes
- Estimates are not measurements
- Individual responses vary
- Sources may disagree

**What to do:**
- Tap source footer to verify citations
- Check original medical source URLs
- Consult your healthcare provider
- Monitor your actual blood glucose

---

## Cost and Performance

### How Much Does Analysis Cost?

Each analysis costs approximately **$0.03-0.05** in Claude API credits.

**Cost savings:**
- Results cached for 30 days
- Re-viewing costs nothing
- Same recipe analysis reused

### Can I Analyze Offline?

**First Analysis:** Requires internet (sends to Claude AI)  
**Viewing Cached:** Works offline (stored locally)

---

## Frequently Asked Questions

### Is this feature FDA approved?
No. This is an informational tool, not a medical device. It does not require FDA approval.

### Can I use this to dose insulin?
**No.** Never use this feature for medication dosing. Always follow your healthcare provider's insulin regimen.

### Will this work for Type 1 diabetes?
This feature provides general information that may be helpful, but Type 1 management requires personalized medical guidance. Always consult your endocrinologist.

### Will this work for Type 2 diabetes?
This feature provides general information that may be helpful, but dietary management should be personalized. Work with your healthcare team and registered dietitian.

### Can children use this feature?
Pediatric diabetes management requires specialized medical care. Parents should consult their child's healthcare team, not rely on this informational tool.

### What about gestational diabetes?
Gestational diabetes requires close medical supervision. Consult your obstetrician and diabetes care team for specific dietary guidance.

### Are the glycemic index values accurate?
GI values are estimates based on typical food compositions. Actual values vary by:
- Food preparation method
- Ripeness (for fruits)
- Processing and cooking
- Food combinations
- Individual factors

### How often are medical guidelines updated?
Medical recommendations evolve continuously. This feature:
- Searches sources from 2023-2025
- Shows "last updated" date on every analysis
- Recommends verifying with current healthcare guidance

### Can I share analysis results with my doctor?
The analysis is for your personal information. If you want to discuss findings with your healthcare provider, take screenshots or notes. Your doctor may prefer evidence-based meal plans from registered dietitians.

---

## External Resources

For professional diabetes management guidance:

### American Diabetes Association
https://diabetes.org
- Evidence-based guidelines
- Educational resources
- Local event finder

### Mayo Clinic - Diabetes
https://www.mayoclinic.org/diseases-conditions/diabetes
- Comprehensive diabetes information
- Treatment options
- Lifestyle guidance

### CDC - Diabetes
https://www.cdc.gov/diabetes
- Prevention programs
- Statistics and research
- Public health resources

### NIH - Diabetes Information
https://www.niddk.nih.gov/health-information/diabetes
- Research-based information
- Clinical trials
- Treatment advances

---

## Getting Help

### In-App Support
- Settings → Help & Support → Browse Help Topics
- Settings → Help & Support → Diagnostic Log

### Dietary Questions
- Consult your registered dietitian
- Contact your diabetes educator
- Ask your healthcare provider

### Technical Issues
- Check Settings → API Key Status
- Verify internet connection
- Review Diagnostic Log

---

## Disclaimer

This user guide provides information about a software feature. It is not medical literature and does not provide medical, dietary, or nutritional advice. Always consult qualified healthcare professionals for medical guidance.

**Your Health, Your Responsibility:**  
You are responsible for your own diabetes management and dietary decisions. Use this feature as one informational tool among many, not as a substitute for professional healthcare.

---

**Last Updated:** December 24, 2025  
**Version:** 1.0  
**License:** See app license agreement for full terms
