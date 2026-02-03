# Quick Setup: Saved Recipe Links

> **⚠️ Superseded** — see [LINK_AND_URL_EXTRACTION.md](LINK_AND_URL_EXTRACTION.md) for the current, consolidated guide.  
> This file is kept for change-history reference only.

---

## What This Was

The original setup guide written when `SavedLink`, `LinkImportService`, `SavedLinksView`,
and `LinkExtractionView` were first created.

Everything it described is still in place, but the system has since been updated:

* `links_from_notes.json` is now sanitised automatically before import (trailing commas are stripped).
* Import buttons are available directly on the Extract tab and inside the Batch Extract sheet — no need to hunt for a menu item.
* All extraction paths now save recipes as `RecipeX` with full CloudKit sync properties.

See [LINK_AND_URL_EXTRACTION.md](LINK_AND_URL_EXTRACTION.md) for the full current guide,
including architecture, data flow, troubleshooting, and known data issues.
