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

#### Step 2: Add Exported Type Identifiers (3 types)

You need three exported type declarations. Click the "+" button in
"Exported Type Identifiers" for each one:

---

**Type 1 — Recipe Book Package**
```
┌─────────────────────────────────────────────────────────────┐
│ Description: Recipe Book Package                            │
│ Identifier:  com.headydiscy.reczipes.recipebook            │
│ Conforms To: public.zip-archive, public.data               │
│ Extensions:  recipebook                                     │
│ MIME Types:  application/x-recipebook                       │
└─────────────────────────────────────────────────────────────┘
```

**Type 2 — Recipes Backup**
```
┌─────────────────────────────────────────────────────────────┐
│ Description: Recipes Backup                                 │
│ Identifier:  com.headydiscy.reczipes.backup                │
│ Conforms To: public.zip-archive, public.data               │
│ Extensions:  backup                                         │
│ MIME Types:  application/x-backup                           │
└─────────────────────────────────────────────────────────────┘
```

**Type 3 — Recipe Books Backup**
```
┌─────────────────────────────────────────────────────────────┐
│ Description: Recipe Books Backup                            │
│ Identifier:  com.headydiscy.reczipes.bookbackup            │
│ Conforms To: public.zip-archive, public.data               │
│ Extensions:  bookbackup                                     │
│ MIME Types:  application/x-bookbackup                       │
└─────────────────────────────────────────────────────────────┘
```

---

**Visual representation:**
```
Exported Type Identifiers (3)
  ▼ Recipe Book Package
    Description             Recipe Book Package
    Identifier              com.headydiscy.reczipes.recipebook
    Conforms To             public.zip-archive, public.data
    Extensions              recipebook
    MIME Types              application/x-recipebook

  ▼ Recipes Backup
    Description             Recipes Backup
    Identifier              com.headydiscy.reczipes.backup
    Conforms To             public.zip-archive, public.data
    Extensions              backup
    MIME Types              application/x-backup

  ▼ Recipe Books Backup
    Description             Recipe Books Backup
    Identifier              com.headydiscy.reczipes.bookbackup
    Conforms To             public.zip-archive, public.data
    Extensions              bookbackup
    MIME Types              application/x-bookbackup
```

#### Step 3: Add Document Types (3 types)

```
Scroll down to find "Document Types" section.
Click the "+" button for each of the three document types:

Document Type 1 — Recipe Book
┌─────────────────────────────────────────────────────────────┐
│ Name:         Recipe Book                                   │
│ Types:        com.headydiscy.reczipes.recipebook            │
│ Role:         Editor                                        │
│ Handler rank: Owner                                         │
└─────────────────────────────────────────────────────────────┘

Document Type 2 — Recipes Backup
┌─────────────────────────────────────────────────────────────┐
│ Name:         Recipes Backup                                │
│ Types:        com.headydiscy.reczipes.backup                │
│ Role:         Editor                                        │
│ Handler rank: Owner                                         │
└─────────────────────────────────────────────────────────────┘

Document Type 3 — Recipe Books Backup
┌─────────────────────────────────────────────────────────────┐
│ Name:         Recipe Books Backup                           │
│ Types:        com.headydiscy.reczipes.bookbackup            │
│ Role:         Editor                                        │
│ Handler rank: Owner                                         │
└─────────────────────────────────────────────────────────────┘
```

**Visual representation:**
```
Document Types (3)
  ▼ Recipe Book
    Name                    Recipe Book
    ▼ Types
      Item 0                com.headydiscy.reczipes.recipebook
    Role                    Editor
    Handler rank            Owner

  ▼ Recipes Backup
    Name                    Recipes Backup
    ▼ Types
      Item 0                com.headydiscy.reczipes.backup
    Role                    Editor
    Handler rank            Owner

  ▼ Recipe Books Backup
    Name                    Recipe Books Backup
    ▼ Types
      Item 0                com.headydiscy.reczipes.bookbackup
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
    
    <!-- Exported Type Declarations (3 types) -->
    <key>UTExportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>com.headydiscy.reczipes.recipebook</string>
            <key>UTTypeDescription</key>
            <string>Recipe Book Package</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.zip-archive</string>
                <string>public.data</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>recipebook</string>
                </array>
                <key>public.mime-type</key>
                <array>
                    <string>application/x-recipebook</string>
                </array>
            </dict>
        </dict>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>com.headydiscy.reczipes.backup</string>
            <key>UTTypeDescription</key>
            <string>Recipes Backup</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.zip-archive</string>
                <string>public.data</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>backup</string>
                </array>
                <key>public.mime-type</key>
                <array>
                    <string>application/x-backup</string>
                </array>
            </dict>
        </dict>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>com.headydiscy.reczipes.bookbackup</string>
            <key>UTTypeDescription</key>
            <string>Recipe Books Backup</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.zip-archive</string>
                <string>public.data</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>bookbackup</string>
                </array>
                <key>public.mime-type</key>
                <array>
                    <string>application/x-bookbackup</string>
                </array>
            </dict>
        </dict>
    </array>
    
    <!-- Document Types (3 types) -->
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Recipe Book</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.headydiscy.reczipes.recipebook</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Recipes Backup</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.headydiscy.reczipes.backup</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Recipe Books Backup</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.headydiscy.reczipes.bookbackup</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
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

# --- Type 1: Recipe Book Package ---
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:0:UTTypeIdentifier string com.headydiscy.reczipes.recipebook" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:0:UTTypeDescription string 'Recipe Book Package'" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:0:UTTypeConformsTo array" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:0:UTTypeConformsTo:0 string public.zip-archive" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:0:UTTypeConformsTo:1 string public.data" Info.plist

# --- Type 2: Recipes Backup ---
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:1:UTTypeIdentifier string com.headydiscy.reczipes.backup" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:1:UTTypeDescription string 'Recipes Backup'" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:1:UTTypeConformsTo array" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:1:UTTypeConformsTo:0 string public.zip-archive" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:1:UTTypeConformsTo:1 string public.data" Info.plist

# --- Type 3: Recipe Books Backup ---
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:2:UTTypeIdentifier string com.headydiscy.reczipes.bookbackup" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:2:UTTypeDescription string 'Recipe Books Backup'" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:2:UTTypeConformsTo array" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:2:UTTypeConformsTo:0 string public.zip-archive" Info.plist
/usr/libexec/PlistBuddy -c "Add :UTExportedTypeDeclarations:2:UTTypeConformsTo:1 string public.data" Info.plist

# --- Document Types (3) ---
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeName string 'Recipe Book'" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string com.headydiscy.reczipes.recipebook" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Editor" Info.plist

/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:1:CFBundleTypeName string 'Recipes Backup'" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:1:LSItemContentTypes array" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:1:LSItemContentTypes:0 string com.headydiscy.reczipes.backup" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:1:CFBundleTypeRole string Editor" Info.plist

/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:2:CFBundleTypeName string 'Recipe Books Backup'" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:2:LSItemContentTypes array" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:2:LSItemContentTypes:0 string com.headydiscy.reczipes.bookbackup" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:2:CFBundleTypeRole string Editor" Info.plist
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
Info Tab → Exported Type Identifiers (3)
  ✓ Recipe Book Package
      Identifier:  com.headydiscy.reczipes.recipebook
      Conforms To: public.zip-archive, public.data
      Extensions:  recipebook
      MIME Types:  application/x-recipebook

  ✓ Recipes Backup
      Identifier:  com.headydiscy.reczipes.backup
      Conforms To: public.zip-archive, public.data
      Extensions:  backup
      MIME Types:  application/x-backup

  ✓ Recipe Books Backup
      Identifier:  com.headydiscy.reczipes.bookbackup
      Conforms To: public.zip-archive, public.data
      Extensions:  bookbackup
      MIME Types:  application/x-bookbackup

Info Tab → Document Types (3)
  ✓ Recipe Book         → com.headydiscy.reczipes.recipebook     Role: Editor
  ✓ Recipes Backup      → com.headydiscy.reczipes.backup         Role: Editor
  ✓ Recipe Books Backup → com.headydiscy.reczipes.bookbackup     Role: Editor
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
│       │   ├─ 📤 Exported Type Identifiers (3)
│       │   │   ├─ Recipe Book Package
│       │   │   │   └─ com.headydiscy.reczipes.recipebook   (.recipebook)
│       │   │   ├─ Recipes Backup
│       │   │   │   └─ com.headydiscy.reczipes.backup       (.backup)
│       │   │   └─ Recipe Books Backup
│       │   │       └─ com.headydiscy.reczipes.bookbackup   (.bookbackup)
│       │   │
│       │   └─ 📄 Document Types (3)
│       │       ├─ Recipe Book         → com.headydiscy.reczipes.recipebook
│       │       ├─ Recipes Backup      → com.headydiscy.reczipes.backup
│       │       └─ Recipe Books Backup → com.headydiscy.reczipes.bookbackup
│       │
│       ├─ Build Settings
│       └─ Build Phases
│
└─ (No standalone Info.plist — Xcode generates it from the Info tab)
```

---

**You're all set!** Follow either Option 1 (GUI) or Option 2 (Source Code) above, then clean build and test. The UTI registration will make your .recipebook files work seamlessly with iOS! 🎉
