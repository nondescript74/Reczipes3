# Recipe Book UTI Registration

## Overview
This document explains how to register the `.recipebook` custom file type (UTI) in your Xcode project.

## What You Need to Do

Add the following entries to your app's `Info.plist` file to properly register the `.recipebook` file type.

### Method 1: Using Xcode's Info Tab (Recommended)

1. **Open your project in Xcode**
2. **Select your app target** (Reczipes2)
3. **Go to the Info tab**
4. **Add Exported Type Identifier:**
   - Click the `+` button under "Exported Type Identifiers"
   - Add the following values:
     - **Identifier:** `com.headydiscy.reczipes.recipebook`
     - **Description:** `Recipe Book Package`
     - **Conforms To:** `public.zip-archive` (or `public.data`)
     - **Extensions:** `recipebook`
     - **MIME Types:** `application/x-recipebook`

5. **Add Document Type:**
   - Click the `+` button under "Document Types"
   - Add the following values:
     - **Name:** `Recipe Book`
     - **Types:** `com.headydiscy.reczipes.recipebook`
     - **Role:** `Editor`
     - **Icon Files:** (optional - you can add custom icon later)

### Method 2: Editing Info.plist Directly

If you prefer to edit the raw plist file, add these entries:

```xml
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
        <key>UTTypeIconFiles</key>
        <array/>
    </dict>
</array>

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
</array>
```

## What This Does

### UTExportedTypeDeclarations
- **Registers** the `.recipebook` file type with the system
- **Associates** it with your app's bundle identifier
- **Declares** that it's a ZIP archive (which it is internally)
- **Sets** the file extension and MIME type

### CFBundleDocumentTypes
- **Tells iOS/iPadOS** that your app can open `.recipebook` files
- **Makes** your app appear in the "Open With" menu for these files
- **Sets** your app as the default handler (Owner rank)

## Benefits

Once registered, you'll get:

1. ✅ **Custom file icon** (you can add one later in Assets.xcassets)
2. ✅ **System recognition** - iOS knows what a `.recipebook` file is
3. ✅ **File handling** - Tapping a `.recipebook` file will open your app
4. ✅ **Share Sheet integration** - Better export/import flow
5. ✅ **Reduced simulator warnings** - No more ISSymbol errors

## Testing

After adding these entries:

1. **Clean build folder** (Product > Clean Build Folder)
2. **Rebuild** your app
3. **Export a recipe book** 
4. **Share/AirDrop it** - you should see a proper icon
5. **Tap the file** - it should offer to open in Reczipes2

## Custom Icon (Optional)

To add a custom icon for `.recipebook` files:

1. Create icon images at these sizes:
   - 16x16, 32x32, 64x64, 128x128, 256x256, 512x512 (for macOS if needed)
   - Or use PDF vector graphics

2. Add them to your asset catalog or add to project

3. Update the `UTTypeIconFiles` array with the icon file names

## Notes

- The UTI format `com.headydiscy.reczipes.recipebook` follows Apple's reverse-DNS convention
- Conforming to `public.zip-archive` tells the system it's a compressed archive
- The `Editor` role means your app can both read and write these files
- `LSHandlerRank: Owner` makes your app the primary handler for this file type

## Troubleshooting

If the file type doesn't register:
1. Clean build folder
2. Delete the app from simulator/device
3. Rebuild and reinstall
4. Restart Xcode (in extreme cases)

The system caches UTI information, so you may need to fully reinstall the app to see changes.
