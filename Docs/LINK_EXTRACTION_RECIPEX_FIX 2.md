# Link Extraction RecipeX Migration Fix

> **⚠️ Superseded** — see [LINK_AND_URL_EXTRACTION.md](LINK_AND_URL_EXTRACTION.md) for the current, consolidated guide.  
> This file is kept for change-history reference only.

---

## Summary (historical)

Fixed `LinkExtractionView.swift` to use `RecipeX` instead of the deprecated `Recipe` model.
This ensures that link extraction creates CloudKit-compatible recipes using the unified recipe model.

All details, including the Jan 2026 migration and the Feb 2026 follow-ups (JSON sanitisation,
`BatchRecipeExtractorViewModel` migration, import-button additions), are documented in
[LINK_AND_URL_EXTRACTION.md](LINK_AND_URL_EXTRACTION.md) under *Recent Changes*.

**Date:** January 29, 2026  
**Migration:** Recipe → RecipeX for Link Extraction
