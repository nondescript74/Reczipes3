# Link & URL Extraction — System Guide

**Last updated:** February 3, 2026  
**Status:** ✅ Current  

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture & Data Flow](#architecture--data-flow)
3. [Entry Points](#entry-points)
4. [The Import Pipeline](#the-import-pipeline)
5. [Single-URL Extraction](#single-url-extraction)
6. [Batch URL Extraction](#batch-url-extraction)
7. [Image Handling](#image-handling)
8. [Tips / Notes Carry-Over](#tips--notes-carry-over)
9. [Key Files](#key-files)
10. [Known Data Issues in links_from_notes.json](#known-data-issues)
11. [Troubleshooting](#troubleshooting)
12. [Recent Changes (Feb 2026)](#recent-changes-feb-2026)

---

## Overview

The link-extraction system lets users import a batch of recipe URLs from a bundled JSON file, then extract full `RecipeX` objects from those URLs using the Claude API.  The extracted recipes land in the same SwiftData store as camera/photo extractions and participate in CloudKit sync automatically.

There are **two distinct phases**:

| Phase | What happens | Where |
|---|---|---|
| **Import** | `links_from_notes.json` → `SavedLink` objects in SwiftData | `LinkImportService` |
| **Extraction** | `SavedLink.url` → HTTP fetch → Claude API → `RecipeX` | `RecipeExtractorViewModel` / `BatchRecipeExtractorViewModel` |

Links must be imported before they can be extracted.  The import button is available on both the Extract tab and inside the Batch Extract sheet.

---

## Architecture & Data Flow

```
┌──────────────────────────────┐
│  links_from_notes.json       │  ← bundled in app target
│  (array of JSONLink)         │
└────────────┬─────────────────┘
             │  LinkImportService.importLinksFromBundle()
             │  • sanitizeJSON()   — strips trailing commas
             │  • JSONDecoder      — decodes [JSONLink]
             │  • dedup by URL     — skips already-imported
             ▼
┌──────────────────────────────┐
│  SavedLink  (@Model)         │  ← SwiftData, per-link status
│  • isProcessed               │
│  • extractedRecipeID         │
│  • processingError           │
│  • tips: [String]?           │
└────────────┬─────────────────┘
             │  (user taps Extract or starts batch)
             ▼
┌──────────────────────────────┐
│  WebRecipeExtractor          │
│  • fetchWebContent(url)      │  ← HTTP GET, retry ×3
│  • cleanHTML()               │  ← preserves JSON-LD
│  • extractImageURLs()        │
└────────────┬─────────────────┘
             │  cleaned HTML → Claude API prompt
             ▼
┌──────────────────────────────┐
│  ClaudeAPIClient             │
│  • sends HTML to Claude      │
│  • parses JSON response      │
│  • returns RecipeX           │
└────────────┬─────────────────┘
             │
             ▼
┌──────────────────────────────┐
│  RecipeX  (@Model)           │  ← final persisted recipe
│  • extractionSource = "web"  │
│  • reference = original URL  │
│  • needsCloudSync = true     │
│  • images via setImage()     │
│  • notes include tips        │
└──────────────────────────────┘
```

---

## Entry Points

There are three ways a user reaches link extraction, all converging on the same underlying pipeline:

### 1. Extract Tab → Import Recipe Links
A green **"Import Recipe Links"** card on the Extract tab opens `ImportLinksSheet`.  This is the recommended first step before using Batch Extract.

### 2. Extract Tab → Batch Extract URLs
The purple **"Batch Extract URLs"** card opens `BatchRecipeExtractorView`.  If no `SavedLink` objects exist yet, the sheet shows an **"Import Links from JSON"** button that opens `ImportLinksSheet` inline — no need to go back.  An **Import Links** toolbar button is always visible for importing more links mid-session.

### 3. Saved Links View (Settings menu path)
`SavedLinksView` provides full management: filter by status, search, swipe-to-delete, single-link extraction, and its own batch extraction entry.  Reach it via Settings or any navigation point that presents it as a sheet.

---

## The Import Pipeline

### Source file

`links_from_notes.json` — bundled in the app target under the `JSON` folder.  Must be added to the target in Xcode ("Copy items if needed", target membership checked).

Expected format:
```json
[
  {
    "title": "Recipe Title",
    "url": "https://www.example.com/recipe",
    "tips": ["optional", "user", "notes"]
  }
]
```

`tips` is optional.  An empty array `[]` is valid and equivalent to omitting the key.

### Sanitization (`LinkImportService.sanitizeJSON`)

Swift's `JSONDecoder` is strict and rejects trailing commas (`[…,]`).  Hand-edited or app-exported JSON files commonly contain them.  `sanitizeJSON` runs a single regex pass that strips all trailing commas before `]` or `}` **before** any validation or decode attempt.  This runs unconditionally — there is no performance cost on a file this size.

### Validation (`JSONLinkValidator.validate(data:)`)

After sanitization, the data is validated:
- Must decode as `[JSONLink]`
- Each entry checked for: empty URL, empty title, invalid URL format, HTML tags in URL, non-HTTP(S) scheme
- Duplicate URLs within the file are flagged as warnings (the second occurrence is kept in the file but will be skipped at import time)

### Deduplication

`LinkImportService` fetches all existing `SavedLink` URLs from SwiftData and compares.  Any `JSONLink` whose URL already exists is silently skipped.  The returned count reflects only *newly imported* links.

### Result

Each new `JSONLink` becomes a `SavedLink` with `isProcessed = false`.  The `@Query` in every view that lists links updates automatically.

---

## Single-URL Extraction

When a user taps a single `SavedLink` in `SavedLinksView`, `LinkExtractionView` opens as a sheet:

1. On appear, calls `RecipeExtractorViewModel.extractRecipe(from: url)`
2. `WebRecipeExtractor.fetchWebContent` GETs the page (3 retries, exponential backoff)
3. HTML is cleaned — JSON-LD `<script>` blocks are preserved and promoted to the top of the content for Claude
4. Image URLs are extracted (JSON-LD → og:image → img tags, in priority order)
5. Claude returns a `RecipeX`
6. User optionally selects images from the extracted URLs
7. **Save** downloads selected images, calls `recipe.setImage()`, inserts into SwiftData

On save:
- `extractionSource` is set to `"web"`
- `reference` is set to the original URL
- CloudKit sync properties are initialised (`needsCloudSync = true`, version = 1, timestamps)
- Tips from the `SavedLink` are appended to `recipe.notes` as `RecipeNote(type: .tip, …)`
- The `SavedLink` is marked `isProcessed = true` with `extractedRecipeID` set

---

## Batch URL Extraction

`BatchRecipeExtractorView` drives `BatchRecipeExtractorViewModel`, which processes links sequentially with a **5-second pause** between each to avoid rate-limiting the Claude API.

### Flow

1. User taps **Start Batch Extraction**
2. Up to 50 unprocessed links are queued (hard cap)
3. For each link:
   - Status updated in UI (current link title, step indicator, progress bar)
   - `RecipeExtractorViewModel` extracts the recipe
   - Images are downloaded (each image retried once on failure)
   - Recipe is saved with the same CloudKit-ready properties as single extraction
   - Link is marked processed (success or failure with error string)
4. 5-second wait before next link (checks for pause/cancel every 0.5 s)
5. Completion alert summarises successes and failures

### Pause / Resume / Stop

- **Pause** sets a flag; the extraction loop sleeps in 0.5 s increments until resumed
- **Stop** cancels the underlying `Task`; already-extracted recipes are persisted
- The sheet can be dismissed while extraction is running — it continues in the background via `BatchExtractionManager.shared`

### Keep Awake

Screen sleep is suppressed automatically while batch extraction is active.  It is re-enabled on completion, stop, or sheet dismiss.

---

## Image Handling

All extraction paths use `RecipeX.setImage(_:isMainImage:)`:

| Index | Stored as |
|---|---|
| 0 (first) | `imageData` — main thumbnail, `@Attribute(.externalStorage)` |
| 1+ | appended to `additionalImagesData` |

No files are written to the Documents directory.  Everything is in SwiftData and syncs via CloudKit.

Image URLs are extracted from HTML in this priority order:

1. **JSON-LD** `image` field inside `<script type="application/ld+json">` — most reliable
2. **og:image** `<meta>` tag
3. First ≤ 10 `<img src>` tags, filtered to exclude icons/logos/SVGs/tracking pixels

The URLs are surfaced to the user in a multi-select picker before download.  In batch mode they are downloaded automatically (no picker).

---

## Tips / Notes Carry-Over

Each `JSONLink` may include a `tips` array.  These are stored on the `SavedLink` and, when the recipe is extracted and saved, converted to `RecipeNote` objects with `type: .tip` and appended to `recipe.notesData`.

This means personal cooking notes survive the extraction and appear alongside the recipe in `RecipeDetailView`.

---

## Key Files

| File | Responsibility |
|---|---|
| `SavedLink.swift` | `@Model` for a single link; `JSONLink` Codable struct; convenience init from `JSONLink` |
| `LinkImportService.swift` | `sanitizeJSON`, file-based import, data-based import, dedup, clear-all |
| `JSONLinkValidator.swift` | Validation, URL fixing, HTML cleaning, file cleaning utilities |
| `SavedLinksView.swift` | Full link-management UI: list, filter, search, single extraction, batch entry |
| `LinkExtractionView.swift` | Single-link extraction sheet: fetch → extract → image picker → save |
| `BatchRecipeExtractorView.swift` | Batch extraction UI: status card, progress, pause/resume/stop, import entry |
| `BatchRecipeExtractorViewModel.swift` | Sequential extraction loop with retry, image download, recipe save |
| `BatchExtractionManager.swift` | Singleton manager variant used by `SavedLinksView`'s batch path |
| `BatchExtractionView.swift` | UI wrapper for `BatchExtractionManager` (the SavedLinksView batch sheet) |
| `WebRecipeExtractor.swift` | HTTP fetch with retry, HTML cleaning, JSON-LD preservation, image-URL extraction |
| `RecipeExtractorView.swift` | Extract tab root: source picker, single-URL input, batch entry, import entry |
| `links_from_notes.json` | Bundled data file — 150+ recipe URLs with optional tips |

---

## Known Data Issues

These exist in `links_from_notes.json` and do **not** block import (the sanitiser handles them), but are worth knowing:

| Entry | Issue | Impact |
|---|---|---|
| **Broccoli cheese soup** | Trailing comma after last tip (curly-quote apostrophe in "Haven't") | Fixed at runtime by `sanitizeJSON` |
| **Chowders** | URL ends with `%3C/div%3E` (URL-encoded `</div>`) — copy-paste artifact | Extraction will likely fail or return wrong page; link will be marked Failed |
| **iCloud photo link** | Both title and URL are an iCloud Photos share link, not a recipe page | Extraction will fail; link will be marked Failed |
| **Chicken spanakopita** (×2) | Duplicate URL shared with "Creamy Garlic Chicken Spanakopita" | Second entry is silently skipped at import time |

---

## Troubleshooting

### "No Saved Links" on Batch Extract

Links must be imported first.  Tap the **"Import Links from JSON"** button that appears in the empty state, or use the **Import Links** toolbar button.

### Import says "File not found"

`links_from_notes.json` is not in the app bundle.  In Xcode:
1. Select the file in the Project Navigator
2. Open the File Inspector (right panel)
3. Confirm your app target is checked under **Target Membership**
4. If missing, drag the file back in with "Copy items if needed" checked

### Import says "Invalid JSON format"

The sanitiser should handle trailing commas automatically.  If this still fires, the JSON has a deeper structural issue.  Run the `#if DEBUG` validation tools in `SavedLinksView` (tap the ellipsis menu → Validation Tools) to see the exact error and line.

### Extraction fails for a specific link

Check the error string on the `SavedLink` (visible in `SavedLinksView` under the Failed filter).  Common causes:
- **403 Forbidden** — the site blocks automated access (nothing we can do)
- **404 Not Found** — URL is stale
- **No recipe found** — the page loaded but Claude couldn't identify a recipe (possible with gallery/list pages)

### Extracted recipes don't appear in the Recipes tab

Verify the recipe was inserted into the model context and saved.  Check the Xcode console for `"Recipe saved successfully"` log lines.  If the save threw, the error will be logged with category `"storage"`.

---

## Recent Changes (Feb 2026)

### JSON Sanitisation (LinkImportService)
- Added `sanitizeJSON(_:)` — regex pass stripping trailing commas before `]` or `}`
- Both the validation step (`ImportLinksSheet.performValidation`) and the import step (`importLinks(from:)`) now sanitise before touching the data
- This fixed a silent total-import failure caused by a trailing comma in the "Broccoli cheese soup" tips array

### Import Buttons Added to Extract Tab & Batch Sheet
- `RecipeExtractorView` — new green **"Import Recipe Links"** card in the source-selection grid
- `BatchRecipeExtractorView` — empty state replaced with an **"Import Links from JSON"** button; toolbar **Import Links** button added for importing more links at any time
- Both open the same `ImportLinksSheet` used by `SavedLinksView`

### BatchRecipeExtractorViewModel.saveRecipe() Migrated to RecipeX
- Removed manual `imageData`/`imageName` assignment and `RecipeImageAssignment` creation
- Now uses `recipe.setImage()` consistently with all other extraction paths
- Sets `extractionSource`, `needsCloudSync`, timestamps, and version — matching `LinkExtractionView` and `BatchExtractionManager`

### RecipeX Migration (Jan 2026)
- `LinkExtractionView` switched from deprecated `Recipe` model to `RecipeX`
- `RecipeImageAssignment` no longer created during link extraction
- `RecipeDetailView` now accepts only `RecipeX`
- Preview model containers updated to `[SavedLink.self, RecipeX.self]`
