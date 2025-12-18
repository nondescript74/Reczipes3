# 🎯 Quick Reference: All Help Topics

## Visual Overview of Available Help

---

## 🚀 Getting Started

### 1. Launch Screen ✨
**What:** First-run experience  
**When to use:** Understanding app launch behavior  
**Key tips:** Only shows once per session, won't reappear from background

### 2. License Agreement 📄
**What:** Terms of use and acceptance  
**When to use:** Understanding app terms, viewing acceptance date  
**Key tips:** Can be viewed anytime from Settings

### 3. API Key Setup 🔑
**What:** Claude API configuration  
**When to use:** First setup, changing API keys, troubleshooting extraction  
**Key tips:** Keys start with 'sk-ant-api03-', stored in encrypted Keychain

---

## ⭐ Main Features

### 4. Recipes Tab 📚
**What:** Your recipe collection  
**When to use:** Browsing, organizing, filtering recipes  
**Key tips:**
- Swipe left to delete
- Tap for details
- Use filter bar for allergen safety
- Thumbnails show when images assigned

### 5. Extract Tab 📸
**What:** AI-powered recipe extraction  
**When to use:** Converting photos to digital recipes  
**Key tips:**
- Takes 15-30 seconds
- Enable preprocessing for old cards
- Images auto-saved with recipes
- Review before saving

### 6. Recipe Detail 📖
**What:** Complete recipe view  
**When to use:** Viewing ingredients, instructions, allergen info  
**Key tips:**
- Tap Edit to modify
- Export to Reminders for shopping
- View allergen analysis if profile active
- Share or print recipes

### 7. Recipe Editing ✏️
**What:** Modify saved recipes  
**When to use:** Fixing extraction errors, adding notes, updating recipes  
**Key tips:**
- Title required, rest optional
- Swipe to delete items
- Tap Edit to reorder sections
- Unsaved changes warning protects data

---

## 🖼️ Images

### 8. Image Assignment 📷
**What:** Manage recipe photos  
**When to use:** Adding/changing recipe images  
**Key tips:**
- Extraction auto-assigns source image
- Green checkmarks show assigned images
- Change anytime via pencil icon
- Stored as compressed JPEG (80%)

### 9. Image Preprocessing 🪄
**What:** Enhance photos for better extraction  
**When to use:** Old/faded recipe cards, handwritten recipes  
**Key tips:**
- Compare before/after to decide
- Converts to grayscale, boosts contrast
- May not help already-clear photos
- Try both ways to see which works best

---

## 🛡️ Allergen & Dietary

### 10. Allergen Profiles 💉
**What:** Track food allergies and sensitivities  
**When to use:** Setting up dietary needs, managing restrictions  
**Key tips:**
- Create multiple profiles (personal, family, guests)
- Only one active at a time
- Set severity: Mild, Moderate, Severe
- Add notes about reactions

### 11. Allergen Analysis 🔍
**What:** Recipe safety scoring  
**When to use:** Finding safe recipes, understanding risks  
**Key tips:**
- ✅ Green = safe, ⚠️ Yellow/Orange/Red = allergens detected
- View detailed analysis for ingredients breakdown
- Higher severity increases risk score
- Checks 16 different allergens/intolerances

### 12. FODMAP Analysis 🧅
**What:** Low FODMAP diet support  
**When to use:** Managing IBS, following Monash guidelines  
**Key tips:**
- Based on Monash University research
- 4 categories: Oligosaccharides, Disaccharides, Monosaccharides, Polyols
- Many foods safe in small portions
- Get low FODMAP alternatives
- Garlic-infused oil OK (strain solids!)

### 13. Allergen Filtering 🔍
**What:** Find safe recipes quickly  
**When to use:** Meal planning, recipe selection  
**Key tips:**
- Enable filter toggle to activate
- Tap "Safe Only" for zero allergens
- Recipes sorted by safety score
- Tap profile to manage settings

---

## 🔧 Advanced

### 14. Claude API 🤖
**What:** AI integration details  
**When to use:** Understanding extraction, troubleshooting, costs  
**Key tips:**
- Uses Claude Sonnet 4
- ~$0.02 per recipe
- Extracts comprehensive data
- Processes in 15-30 seconds
- Can detect hidden allergens

### 15. API Key Setup (Detailed) 🔐
**What:** Complete configuration guide  
**When to use:** Initial setup, troubleshooting API errors  
**Key tips:**
- Get key at console.anthropic.com
- Stored securely in iOS Keychain
- Can view/edit/remove anytime
- Check status shows green/red

### 16. Data Storage 💾
**What:** Privacy and local storage  
**When to use:** Understanding data location, privacy concerns  
**Key tips:**
- All data stored locally
- No cloud sync (can be added)
- Recipes in SwiftData
- Images in Documents folder
- API key in Keychain (encrypted)

### 17. Export to Reminders ✅
**What:** Create shopping lists  
**When to use:** Grocery shopping, meal prep  
**Key tips:**
- One-tap export from recipe detail
- Creates checklist in Reminders app
- Organized by ingredient sections
- Check off items while shopping

### 18. Settings Tab ⚙️
**What:** App configuration  
**When to use:** Managing preferences, viewing info  
**Key tips:**
- API key status indicator
- Toggle auto-extract
- Default preprocessing setting
- View license agreement
- Browse help topics

---

## 📊 Help Topic Organization

### By Category

```
Getting Started (3 topics)
├── Launch Screen
├── License Agreement
└── API Key Setup

Main Features (4 topics)
├── Recipes Tab
├── Extract Tab
├── Recipe Detail
└── Recipe Editing

Images (2 topics)
├── Image Assignment
└── Image Preprocessing

Allergen & Dietary (4 topics)
├── Allergen Profiles
├── Allergen Analysis
├── FODMAP Analysis
└── Allergen Filtering

Advanced (5 topics)
├── Claude API
├── API Key Setup (Detailed)
├── Data Storage
├── Export to Reminders
└── Settings Tab
```

---

## 🎨 Icon Reference

| Icon | Feature | Quick Access |
|------|---------|-------------|
| 📚 | Recipes Collection | Main tab |
| 📸 | Recipe Extraction | Main tab |
| ⚙️ | Settings | Main tab |
| ✏️ | Edit Recipe | Recipe detail toolbar |
| 📷 | Image Assignment | Recipes toolbar |
| 🛡️ | Allergen Profiles | Filter bar or Settings |
| 🔍 | Search/Filter | Filter bar |
| ❓ | Help Button | Various toolbars |
| 🔑 | API Key | Settings |
| ✅ | Export Reminders | Recipe detail |

---

## 🔍 When to Use Which Help Topic

### "I want to get started with the app"
→ **Getting Started** category  
→ Start with **API Key Setup**  
→ Then **Extract Tab**

### "I need to digitize my recipe cards"
→ **Extract Tab**  
→ **Image Preprocessing** (if old cards)  
→ **Image Assignment** (if needed)

### "I have food allergies"
→ **Allergen Profiles**  
→ **Allergen Analysis**  
→ **Allergen Filtering**

### "I follow a Low FODMAP diet"
→ **FODMAP Analysis**  
→ **Allergen Profiles** (add FODMAP)

### "I want to edit a recipe"
→ **Recipe Editing**  
→ **Recipe Detail**

### "Something's not working"
→ **COMPLETE_APP_HELP_GUIDE.md** - Troubleshooting section  
→ Check relevant feature help topic  
→ Verify **API Key Setup** if extraction issues

### "I want to understand costs"
→ **Claude API**  
→ **API Key Setup**

### "I'm concerned about privacy"
→ **Data Storage**  
→ **License Agreement**

### "I want to go grocery shopping"
→ **Export to Reminders**

---

## 📱 How to Access Help

### Method 1: Settings Tab
```
Settings → Help & Support → Browse Help Topics
```
- Browse all 18 topics
- Organized by 5 categories
- Search functionality

### Method 2: Toolbar Buttons
```
Look for (?) icon in navigation bars
```
- Context-specific help
- Opens relevant topic directly

### Method 3: Search
```
Help Browser → Search bar → Type feature name
```
- Searches titles and descriptions
- Instant filtering

### Method 4: Documentation Files
```
Project files → .md files
```
- `COMPLETE_APP_HELP_GUIDE.md` - Full manual
- `ALLERGEN_DETECTION_GUIDE.md` - Allergen details
- `FODMAP_IMPLEMENTATION_GUIDE.md` - FODMAP details
- `RECIPE_EDITING_QUICKSTART.md` - Editing guide

---

## 💡 Pro Tips

### For New Users
1. Start with **API Key Setup**
2. Try **Extract Tab** with a test recipe
3. Set up **Allergen Profiles** if needed
4. Explore **Recipe Detail** features

### For Regular Users
1. Use **Allergen Filtering** for meal planning
2. Try **Image Preprocessing** for better results
3. Use **Export to Reminders** for shopping
4. Explore **Recipe Editing** for customization

### For Power Users
1. Study **Claude API** for optimization
2. Understand **Data Storage** for backups
3. Create multiple **Allergen Profiles** for scenarios
4. Master **FODMAP Analysis** for dietary control

---

## 🎯 Coverage Summary

✅ **All 3 main tabs documented**  
✅ **All recipe features covered**  
✅ **Complete allergen system explained**  
✅ **FODMAP analysis detailed**  
✅ **Image management documented**  
✅ **API setup fully covered**  
✅ **Advanced features explained**  
✅ **Troubleshooting included**  
✅ **Tips and best practices provided**  
✅ **Privacy and security addressed**

---

## 📚 Related Documentation

- **COMPLETE_APP_HELP_GUIDE.md** - Full 400+ line user manual
- **CONTEXTUAL_HELP_IMPLEMENTATION.md** - Developer guide
- **ALLERGEN_DETECTION_GUIDE.md** - Allergen system details
- **FODMAP_IMPLEMENTATION_GUIDE.md** - FODMAP features
- **RECIPE_EDITING_QUICKSTART.md** - Editing guide
- **AUTOMATIC_IMAGE_ASSIGNMENT.md** - Image system
- **README.md** - Project overview

---

## 🔄 Keep This Updated

When adding new features:
1. Create help topic in `ContextualHelp.swift`
2. Update this quick reference
3. Add to `COMPLETE_APP_HELP_GUIDE.md`
4. Add help button to feature UI

---

**Last Updated:** December 18, 2025  
**Total Topics:** 18  
**Categories:** 5  
**Documentation Files:** 8

**Status:** ✅ Complete Coverage of All App Features
