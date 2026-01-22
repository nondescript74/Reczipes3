# Recipe Book UTI Architecture Flowchart

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         RECZIPES2 APP                                   │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                      EXPORT FLOW                                  │ │
│  │                                                                   │ │
│  │  User Action: "Export Recipe Book"                               │ │
│  │         ↓                                                         │ │
│  │  RecipeBookExportService.exportBook()                            │ │
│  │         ↓                                                         │ │
│  │  1. Create temp directory                                        │ │
│  │  2. Copy images                                                  │ │
│  │  3. Create book.json                                             │ │
│  │  4. Create ZIP archive                                           │ │
│  │  5. Rename to .recipebook                                        │ │
│  │  6. Set contentType = UTType.recipeBook                          │ │
│  │         ↓                                                         │ │
│  │  File: "MyBook_12345.recipebook"                                 │ │
│  │         ↓                                                         │ │
│  │  Share Sheet / Save to Files                                     │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│                              ↓                                          │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                         iOS SYSTEM                                      │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │ UTI Registration (from Info.plist)                                │ │
│  │                                                                   │ │
│  │ com.headydiscy.reczipes.recipebook                                │ │
│  │   • File Extension: .recipebook                                  │ │
│  │   • Conforms To: public.zip-archive                              │ │
│  │   • Handler: Reczipes2 (Owner)                                   │ │
│  │   • MIME: application/x-recipebook                               │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  System recognizes file type:                                          │
│   ✓ Files app shows proper icon                                        │
│   ✓ Share sheet knows file type                                        │
│   ✓ Tap to open routes to Reczipes2                                    │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                         RECZIPES2 APP                                   │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                      IMPORT FLOW                                  │ │
│  │                                                                   │ │
│  │  User Action: Tap .recipebook file in Files/AirDrop              │ │
│  │         ↓                                                         │ │
│  │  iOS launches/activates Reczipes2                                │ │
│  │         ↓                                                         │ │
│  │  WindowGroup.onOpenURL receives URL                              │ │
│  │         ↓                                                         │ │
│  │  Check: url.pathExtension == "recipebook"                        │ │
│  │         ↓                                                         │ │
│  │  RecipeBookDocumentHandler.handleIncomingDocument()              │ │
│  │         ↓                                                         │ │
│  │  1. Request security scoped resource access                      │ │
│  │  2. Copy file to temp location                                   │ │
│  │  3. Set pendingImportURL                                         │ │
│  │  4. Set showImportSheet = true                                   │ │
│  │         ↓                                                         │ │
│  │  RecipeBookImportSheet presented                                 │ │
│  │         ↓                                                         │ │
│  │  User confirms import                                            │ │
│  │         ↓                                                         │ │
│  │  RecipeBookExportService.importBook()                            │ │
│  │         ↓                                                         │ │
│  │  1. Extract ZIP archive                                          │ │
│  │  2. Parse book.json                                              │ │
│  │  3. Copy images to Documents                                     │ │
│  │  4. Create RecipeBook in SwiftData                               │ │
│  │  5. Import Recipe objects                                        │ │
│  │  6. Save context                                                 │ │
│  │         ↓                                                         │ │
│  │  Success! Book and recipes imported                              │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      Reczipes2App.swift                         │
│                                                                 │
│  @StateObject documentHandler                                  │
│         │                                                       │
│         ├─→ .environmentObject(documentHandler)                │
│         │                                                       │
│         └─→ .onOpenURL { url in                                │
│                 if url.pathExtension == "recipebook" {          │
│                     documentHandler.handleIncomingDocument(url) │
│                 }                                               │
│             }                                                   │
│         │                                                       │
│         └─→ .sheet(isPresented: $documentHandler.showImportSheet) │
│                 RecipeBookImportSheet(handler: documentHandler) │
│             }                                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              RecipeBookDocumentHandler.swift                    │
│                                                                 │
│  @Published var pendingImportURL: URL?                         │
│  @Published var showImportSheet: Bool                          │
│  @Published var importError: Error?                            │
│                                                                 │
│  func handleIncomingDocument(_ url: URL)                       │
│  func clearPendingImport()                                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│               RecipeBookImportSheet (SwiftUI)                   │
│                                                                 │
│  States:                                                        │
│    • Ready to import    → Show file info, Import button        │
│    • Importing          → Progress indicator                   │
│    • Success            → Checkmark, book info, Done button    │
│    • Error              → Error icon, message, Dismiss button  │
│                                                                 │
│  func performImport() async                                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│            RecipeBookExportService.swift                        │
│                                                                 │
│  static func exportBook(...) async throws -> URL               │
│    • Creates temp directory                                    │
│    • Copies images                                             │
│    • Encodes book.json                                         │
│    • Creates ZIP archive                                       │
│    • Sets UTType.recipeBook contentType                        │
│    • Returns URL with .recipebook extension                    │
│                                                                 │
│  static func importBook(...) async throws -> RecipeBook        │
│    • Extracts ZIP archive                                      │
│    • Decodes book.json                                         │
│    • Imports images                                            │
│    • Creates RecipeBook and Recipe objects                     │
│    • Saves to SwiftData                                        │
│    • Returns imported book                                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  RecipeBookUTType.swift                         │
│                                                                 │
│  extension UTType {                                            │
│      static let recipeBook = UTType(                           │
│          exportedAs: "com.headydiscy.reczipes.recipebook"      │
│      )                                                         │
│  }                                                             │
│                                                                 │
│  struct RecipeBookPackageType {                                │
│      static let fileExtension = "recipebook"                   │
│      static let mimeType = "application/x-recipebook"          │
│      static let typeDescription = "Recipe Book Package"        │
│      static let iconName = "books.vertical.fill"               │
│  }                                                             │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagram

```
EXPORT FLOW:
────────────

[User] → [RecipeBooksView] → [Export Button]
                                    ↓
                          [RecipeBookExportService]
                                    ↓
                        ┌───────────┴────────────┐
                        ↓                        ↓
                [Create Temp Dir]        [Collect Images]
                        ↓                        ↓
                [Copy Images] ←──────────────────┘
                        ↓
                [Create book.json]
                        ↓
                [Create ZIP Archive]
                        ↓
                [Rename to .recipebook]
                        ↓
                [Set contentType = UTType.recipeBook]
                        ↓
                [Return URL] → [Share Sheet / Files App]


IMPORT FLOW:
────────────

[Files App] or [AirDrop] → [User taps .recipebook file]
                                    ↓
                            [iOS System]
                                    ↓
                    [Launch/Activate Reczipes2]
                                    ↓
                    [Reczipes2App.onOpenURL]
                                    ↓
                [RecipeBookDocumentHandler]
                                    ↓
                ┌───────────────────┴──────────────────┐
                ↓                                      ↓
    [Request Security Access]          [Copy to Temp Location]
                ↓                                      ↓
                └──────────────────┬───────────────────┘
                                   ↓
                    [Set pendingImportURL]
                                   ↓
                    [Show RecipeBookImportSheet]
                                   ↓
                    [User confirms import]
                                   ↓
                    [RecipeBookExportService.importBook()]
                                   ↓
                ┌──────────────────┴──────────────────┐
                ↓                  ↓                  ↓
        [Extract ZIP]      [Parse JSON]      [Copy Images]
                ↓                  ↓                  ↓
                └──────────────────┴──────────────────┘
                                   ↓
                        [Create SwiftData Objects]
                                   ↓
                            [Save Context]
                                   ↓
                              [Success!]
```

## State Machine: RecipeBookImportSheet

```
                         ┌──────────────┐
                         │    READY     │
                         │  TO IMPORT   │
                         └──────┬───────┘
                                │
                    User taps "Import" button
                                │
                                ↓
                         ┌──────────────┐
                         │  IMPORTING   │
                         │  (Progress)  │
                         └──────┬───────┘
                                │
                    ┌───────────┴───────────┐
                    ↓                       ↓
            Import succeeds         Import fails
                    ↓                       ↓
            ┌──────────────┐        ┌──────────────┐
            │   SUCCESS    │        │    ERROR     │
            │ (Checkmark)  │        │  (Warning)   │
            └──────┬───────┘        └──────┬───────┘
                   │                       │
        User taps "Done"        User taps "Dismiss"
                   │                       │
                   └───────────┬───────────┘
                               ↓
                         [Sheet Dismissed]
                               ↓
                    [clearPendingImport()]
```

## File Structure

```
Reczipes2/
│
├── App/
│   └── Reczipes2App.swift ─────────────────┐
│                                           │ (imports)
├── Models/                                 │
│   ├── RecipeBookUTType.swift ─────────────┼──────┐
│   └── RecipeBookExportService.swift ──────┼──┐   │
│                                           │  │   │
├── Services/                               │  │   │
│   └── RecipeBookDocumentHandler.swift ────┼──┼───┼──┐
│                                           │  │   │  │
├── Views/                                  │  │   │  │
│   └── [RecipeBookImportSheet] ────────────┤  │   │  │
│       (embedded in handler file)          │  │   │  │
│                                           │  │   │  │
├── Tests/                                  │  │   │  │
│   └── RecipeBookUTITests.swift ───────────┼──┼───┼──┼─┐
│                                           │  │   │  │ │
├── Documentation/                          ↓  ↓   ↓  ↓ ↓
│   ├── RECIPEBOOK_UTI_REGISTRATION.md ─────────────────
│   ├── RECIPEBOOK_UTI_IMPLEMENTATION.md ───────────────
│   ├── INFO_PLIST_VISUAL_GUIDE.md ─────────────────────
│   ├── UTI_REGISTRATION_CHECKLIST.md ──────────────────
│   ├── UTI_COMPLETE_SUMMARY.md ────────────────────────
│   ├── UTI_QUICK_REFERENCE.txt ────────────────────────
│   ├── RecipeBook-Info.plist ──────────────────────────
│   └── UTI_ARCHITECTURE.md (this file) ────────────────
│
└── Info.plist ──────────────────────────────────────────
    (Needs UTI entries added)                ↑
                                             │
                          USER ACTION REQUIRED
```

## Security Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY CONSIDERATIONS                  │
└─────────────────────────────────────────────────────────────┘

File from outside sandbox (Files app, AirDrop, etc.)
                    ↓
    ┌───────────────────────────────────────┐
    │ url.startAccessingSecurityScopedResource() │
    └───────────────────────────────────────┘
                    ↓
        Access granted by system
                    ↓
        Copy file to app's temp directory
                    ↓
    ┌───────────────────────────────────────┐
    │  url.stopAccessingSecurityScopedResource()  │
    └───────────────────────────────────────┘
                    ↓
        Work with file in temp directory
                    ↓
        Process import
                    ↓
        Delete temp file
```

## Error Handling Flow

```
Every step has try/catch:

RecipeBookExportService.exportBook()
    ├─→ Try: Create directory
    │   └─→ Catch: Log error, throw
    ├─→ Try: Copy images
    │   └─→ Catch: Log error, continue (optional)
    ├─→ Try: Encode JSON
    │   └─→ Catch: Log error, throw
    ├─→ Try: Create ZIP
    │   └─→ Catch: Log error, throw
    └─→ Try: Set resource values
        └─→ Catch: Log warning, continue

RecipeBookExportService.importBook()
    ├─→ Try: Extract ZIP
    │   └─→ Catch: Log error, show user error
    ├─→ Try: Parse JSON
    │   └─→ Catch: Log error, show user error
    ├─→ Try: Copy images
    │   └─→ Catch: Log warning, continue
    ├─→ Try: Create SwiftData objects
    │   └─→ Catch: Log error, show user error
    └─→ Try: Save context
        └─→ Catch: Log error, show user error

RecipeBookDocumentHandler.handleIncomingDocument()
    ├─→ Try: Access security scoped resource
    │   └─→ Catch: Log error, set importError
    └─→ Try: Copy to temp
        └─→ Catch: Log error, set importError
```

---

## Summary

This architecture provides:

✅ **Clean separation** of concerns (UTType, Handler, Service, UI)  
✅ **Security** through scoped resource access  
✅ **Error handling** at every level  
✅ **User feedback** through import sheet states  
✅ **System integration** via UTI registration  
✅ **Extensibility** for future enhancements  

All components work together to provide a seamless, professional file import/export experience that feels native to iOS.
