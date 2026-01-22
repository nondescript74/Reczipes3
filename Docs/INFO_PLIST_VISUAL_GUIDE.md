# Visual Guide: Adding UTI to Info.plist in Xcode

## Step-by-Step with Screenshots Guide

### Option 1: Using Xcode's Info Tab (Easiest)

#### Step 1: Select Your Target
```
1. Open your Reczipes2.xcodeproj in Xcode
2. In the project navigator (left sidebar), click on the blue "Reczipes2" project file
3. In the main editor, select the "Reczipes2" target (under TARGETS)
4. Click the "Info" tab at the top
```

#### Step 2: Add Exported Type Identifier

```
5. Scroll down to find "Exported Type Identifiers" section
6. Click the small "+" button to add a new type
7. You'll see a new row appear - click on it to expand

Fill in these fields:
┌─────────────────────────────────────────────────────────────┐
│ Identifier: com.headydiscy.reczipes.recipebook             │
│ Description: Recipe Book Package                            │
│ Conforms To: [Click + to add multiple]                     │
│   - public.zip-archive                                      │
│   - public.data                                             │
│ Extensions: [Click + to add]                               │
│   - recipebook                                              │
│ MIME Types: [Click + to add]                               │
│   - application/x-recipebook                                │
└─────────────────────────────────────────────────────────────┘
```

**Visual representation:**
```
Exported Type Identifiers
  ▼ Item 0
    Identifier              com.headydiscy.reczipes.recipebook
    Description             Recipe Book Package
    ▼ Conforms To
      Item 0                public.zip-archive
      Item 1                public.data
    ▼ Extensions
      Item 0                recipebook
    ▼ MIME Types
      Item 0                application/x-recipebook
```

#### Step 3: Add Document Type

```
8. Scroll down to find "Document Types" section
9. Click the small "+" button to add a new document type
10. You'll see a new row appear - click on it to expand

Fill in these fields:
┌─────────────────────────────────────────────────────────────┐
│ Name: Recipe Book                                           │
│ Types: [Click + to add]                                     │
│   - com.headydiscy.reczipes.recipebook                      │
│ Role: Editor                                                │
│ Handler rank: Owner                                         │
└─────────────────────────────────────────────────────────────┘
```

**Visual representation:**
```
Document Types
  ▼ Item 0
    Name                    Recipe Book
    ▼ Types
      Item 0                com.headydiscy.reczipes.recipebook
    Role                    Editor
    Handler rank            Owner
```

#### Step 4: Save and Clean Build

```
11. Press ⌘S to save
12. Press ⇧⌘K to clean build folder
13. Delete the app from your simulator/device
14. Press ⌘R to build and run
```

---

### Option 2: Editing Info.plist as Source Code

#### Step 1: Find Info.plist
```
1. In Xcode's project navigator (left sidebar)
2. Expand the "Reczipes2" folder
3. Find "Info.plist" file
4. Right-click on it
5. Select "Open As" → "Source Code"
```

#### Step 2: Add the XML Entries

```
6. Scroll to find the closing </dict> tag (near the bottom)
7. Place your cursor BEFORE the </dict> tag
8. Paste the XML from RecipeBook-Info.plist file
```

**Before:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"...>
<plist version="1.0">
<dict>
    <!-- Your existing keys -->
    <key>CFBundleVersion</key>
    <string>1</string>
    <!-- More existing keys -->
    
</dict>  ← CURSOR GOES BEFORE THIS LINE
</plist>
```

**After:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"...>
<plist version="1.0">
<dict>
    <!-- Your existing keys -->
    <key>CFBundleVersion</key>
    <string>1</string>
    
    <!-- NEW: Exported Type Declarations -->
    <key>UTExportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>com.headydiscy.reczipes.recipebook</string>
            ...
        </dict>
    </array>
    
    <!-- NEW: Document Types -->
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Recipe Book</string>
            ...
        </dict>
    </array>
    
</dict>
</plist>
```

#### Step 3: Verify and Save

```
9. Look for any XML syntax errors (Xcode will highlight them)
10. Press ⌘S to save
11. Right-click Info.plist again
12. Select "Open As" → "Property List" to view in table format
13. Verify your entries appear correctly
```

---

### Option 3: Command Line (Advanced)

If you prefer command line:

```bash
# Navigate to your project directory
cd /path/to/Reczipes2

# Add exported type declaration
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:0:UTTypeIdentifier string com.headydiscy.reczipes.recipebook" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:0:UTTypeDescription string 'Recipe Book Package'" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:0:UTTypeConformsTo array" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:0:UTTypeConformsTo:0 string public.zip-archive" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:0:UTTypeConformsTo:1 string public.data" Info.plist

# Add document type
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeName string 'Recipe Book'" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string com.headydiscy.reczipes.recipebook" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Editor" Info.plist
```

---

## Common Mistakes to Avoid

### ❌ Wrong: Adding to wrong target
Make sure you're editing the **app target's** Info.plist, not a test target or extension target.

### ❌ Wrong: Typos in identifier
```
com.headydiscy.reczipes.recipebook  ✅ Correct
com.headydiscy.Reczipes.recipebook  ❌ Wrong (capital R)
com.headydiscy.reczipes.recipeBook  ❌ Wrong (capital B)
```

### ❌ Wrong: Missing UTType prefix
```
UTExportedTypeDeclarations  ✅ Correct
ExportedTypeDeclarations    ❌ Wrong (missing UT)
```

### ❌ Wrong: Not cleaning build
After adding entries, you MUST:
1. Clean build (⇧⌘K)
2. Delete app from simulator
3. Build and install fresh

The system caches UTI info, so just rebuilding won't work!

---

## Verification Checklist

After adding entries, verify in Xcode:

```
Info Tab → Exported Type Identifiers
  ✓ Shows: com.headydiscy.reczipes.recipebook
  ✓ Description: Recipe Book Package
  ✓ Conforms To: public.zip-archive, public.data
  ✓ Extensions: recipebook

Info Tab → Document Types
  ✓ Name: Recipe Book
  ✓ Types: com.headydiscy.reczipes.recipebook
  ✓ Role: Editor
```

---

## Testing After Setup

### Quick Test:
1. Run the app
2. Export a recipe book
3. Use the Share Sheet to save to Files
4. Navigate to Files app
5. Tap the .recipebook file
6. Should see: "Open in Reczipes2"
7. Tap to open → Import sheet appears

### Full Test:
1. AirDrop a .recipebook file between devices
2. Verify custom icon appears (once icon is added)
3. Long-press file in Files app → Quick Look
4. Share sheet shows proper file type
5. Console shows no ISSymbol errors

---

## Troubleshooting

### "File won't open in app"
1. Check Info.plist entries exactly match
2. Verify CFBundleDocumentTypes is present
3. Check LSItemContentTypes array has correct identifier

### "Still seeing ISSymbol errors"
1. Completely delete app from simulator
2. Reset simulator: Device → Erase All Content and Settings
3. Clean build folder (⇧⌘K)
4. Rebuild and run

### "Changes don't appear"
1. Close Xcode completely
2. Reopen project
3. Verify Info.plist still has your changes
4. Clean build and reinstall

---

## Visual Reference Summary

```
Xcode Project Navigator
│
├─ 📘 Reczipes2 (Project)
│   │
│   └─ 🎯 Reczipes2 (Target) ← SELECT THIS
│       │
│       ├─ General
│       ├─ Signing & Capabilities
│       ├─ Resource Tags
│       ├─ ⚙️ Info ← CLICK THIS TAB
│       │   │
│       │   ├─ ... (other settings)
│       │   │
│       │   ├─ 📤 Exported Type Identifiers
│       │   │   └─ [+] ← ADD HERE
│       │   │       ├─ Identifier
│       │   │       ├─ Description
│       │   │       ├─ Conforms To
│       │   │       ├─ Extensions
│       │   │       └─ MIME Types
│       │   │
│       │   └─ 📄 Document Types
│       │       └─ [+] ← ADD HERE
│       │           ├─ Name
│       │           ├─ Types
│       │           ├─ Role
│       │           └─ Handler rank
│       │
│       ├─ Build Settings
│       └─ Build Phases
│
└─ 📄 Info.plist (Alternative: Edit as source)
```

---

**You're all set!** Follow either Option 1 (GUI) or Option 2 (Source Code) above, then clean build and test. The UTI registration will make your .recipebook files work seamlessly with iOS! 🎉
