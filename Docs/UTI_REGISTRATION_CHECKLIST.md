# Recipe Book UTI Registration - Quick Checklist

## ✅ Completed (Code Implementation)

- [x] Created `RecipeBookUTType.swift` with UTType definition
- [x] Created `RecipeBookDocumentHandler.swift` for file handling
- [x] Created `RecipeBookImportSheet` view
- [x] Updated `RecipeBookExportService.exportBook()` to use UTType
- [x] Updated `Reczipes2App.swift` with document handling
- [x] Added `.onOpenURL` handler
- [x] Created documentation files

## 🔲 TODO (Your Action Required)

### 1. Add Info.plist Entries ⚠️ **REQUIRED**

Choose **ONE** method:

#### Method A: Using Xcode UI (Recommended)
1. [ ] Open Xcode and select your **Reczipes2** target
2. [ ] Go to the **Info** tab
3. [ ] Under "Exported Type Identifiers", click **+** and add:
   - Identifier: `com.headydiscy.reczipes.recipebook`
   - Description: `Recipe Book Package`
   - Conforms To: `public.zip-archive`, `public.data`
   - Extensions: `recipebook`
   - MIME Types: `application/x-recipebook`

4. [ ] Under "Document Types", click **+** and add:
   - Name: `Recipe Book`
   - Types: `com.headydiscy.reczipes.recipebook`
   - Role: `Editor`
   - Handler Rank: `Owner`

#### Method B: Edit Info.plist Source
1. [ ] Right-click Info.plist → "Open As" → "Source Code"
2. [ ] Copy contents from `RecipeBook-Info.plist` 
3. [ ] Paste before the closing `</dict>` tag
4. [ ] Save the file

### 2. Clean Build
1. [ ] Product → Clean Build Folder (⇧⌘K)
2. [ ] Delete app from simulator/device
3. [ ] Build and run (⌘R)

### 3. Test the Implementation
1. [ ] Export a recipe book from the app
2. [ ] Save the `.recipebook` file to Files app
3. [ ] Tap the file - should launch Reczipes2
4. [ ] Import sheet should appear
5. [ ] Complete the import

### 4. Verify on Real Device (Optional but Recommended)
1. [ ] Test on physical iPhone/iPad
2. [ ] Try AirDrop of `.recipebook` file
3. [ ] Verify Files app integration
4. [ ] Check share sheet appearance

## 📄 Reference Files

- **RECIPEBOOK_UTI_REGISTRATION.md** - Detailed instructions
- **RECIPEBOOK_UTI_IMPLEMENTATION.md** - Technical overview
- **RecipeBook-Info.plist** - Copy/paste XML entries

## ⚠️ Important Notes

**Must Reinstall**: After adding Info.plist entries, you MUST completely delete and reinstall the app for the system to register the UTI changes.

**Simulator Caching**: If changes don't work:
- Reset simulator content and settings
- Restart Xcode
- Try on a real device

**Testing**: The simulator warning about ISSymbol will disappear once the UTI is registered and the app is reinstalled.

## 🎯 Expected Behavior After Completion

✅ Exported `.recipebook` files have proper file type  
✅ Tapping `.recipebook` file opens Reczipes2  
✅ Import sheet appears automatically  
✅ Files app shows proper icon (once custom icon added)  
✅ Share sheet works seamlessly  
✅ No more ISSymbol warnings in console  

## 🆘 If Something Goes Wrong

1. **Verify Info.plist entries** match exactly
2. **Clean build** and **delete app**
3. **Check console** for UTType errors
4. **Try on real device** if simulator acts weird
5. **Reference** RECIPEBOOK_UTI_REGISTRATION.md for troubleshooting

## 📝 Status

- **Code**: ✅ Complete
- **Info.plist**: 🔲 **Action Required**
- **Testing**: 🔲 Pending Info.plist

---

**Next Step**: Add Info.plist entries using Method A or B above, then clean build and test! 🚀
