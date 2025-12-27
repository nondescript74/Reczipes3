# File Organization Note

> **Important:** This file and all other `.md` documentation files should be moved to the `docs/` folder.

## Documentation Files to Organize

The following `.md` files should be located in the `docs/` folder:

### Recently Created (HTML Tags Fix)
- `QUICK_FIX_HTML_TAGS.md` → `docs/QUICK_FIX_HTML_TAGS.md`
- `HTML_TAG_URL_FIX.md` → `docs/HTML_TAG_URL_FIX.md`

### Existing Documentation Files
- `ARCHITECTURE_RECIPE_EXTRACTION.md` → `docs/ARCHITECTURE_RECIPE_EXTRACTION.md`
- `JSONLINKVALIDATOR_TIPS_FIX.md` → `docs/JSONLINKVALIDATOR_TIPS_FIX.md`
- `SAVED_LINKS_FEATURE.md` → `docs/SAVED_LINKS_FEATURE.md`
- `TIPS_INTEGRATION.md` → `docs/TIPS_INTEGRATION.md`
- `WEB_IMAGE_EXTRACTION_FEATURE.md` → `docs/WEB_IMAGE_EXTRACTION_FEATURE.md`
- `DOCUMENTATION_UPDATE_SUMMARY.md` → `docs/DOCUMENTATION_UPDATE_SUMMARY.md`
- `DIABETIC_FEATURE_COMPLIANCE_SUMMARY.md` → `docs/DIABETIC_FEATURE_COMPLIANCE_SUMMARY.md`
- `HELP_SYSTEM_PACKAGE.md` → `docs/HELP_SYSTEM_PACKAGE.md`
- `COMPLETE_APP_HELP_GUIDE.md` → `docs/COMPLETE_APP_HELP_GUIDE.md`
- `CONTEXTUAL_HELP_IMPLEMENTATION.md` → `docs/CONTEXTUAL_HELP_IMPLEMENTATION.md`

## Recommended docs/ Structure

```
docs/
├── README.md                                   # Overview of documentation
├── features/                                   # Feature documentation
│   ├── SAVED_LINKS_FEATURE.md
│   ├── TIPS_INTEGRATION.md
│   ├── WEB_IMAGE_EXTRACTION_FEATURE.md
│   └── DIABETIC_FEATURE_COMPLIANCE_SUMMARY.md
├── architecture/                               # Architecture docs
│   └── ARCHITECTURE_RECIPE_EXTRACTION.md
├── fixes/                                      # Bug fixes and solutions
│   ├── JSONLINKVALIDATOR_TIPS_FIX.md
│   ├── HTML_TAG_URL_FIX.md
│   └── QUICK_FIX_HTML_TAGS.md
├── help/                                       # Help system documentation
│   ├── HELP_SYSTEM_PACKAGE.md
│   ├── COMPLETE_APP_HELP_GUIDE.md
│   └── CONTEXTUAL_HELP_IMPLEMENTATION.md
└── updates/                                    # Update summaries
    └── DOCUMENTATION_UPDATE_SUMMARY.md
```

## How to Organize in Xcode

1. In Xcode, create a new group called `docs`
2. Create subgroups: `features`, `architecture`, `fixes`, `help`, `updates`
3. Move (or recreate) the `.md` files into their appropriate subgroups
4. Ensure the files are added to the project but not included in targets (documentation only)

## Future Documentation

All new `.md` files created should be placed directly in the appropriate `docs/` subfolder based on their purpose:

- **Feature documentation** → `docs/features/`
- **Architecture/design docs** → `docs/architecture/`
- **Bug fixes and solutions** → `docs/fixes/`
- **Help system docs** → `docs/help/`
- **Update summaries** → `docs/updates/`

## Note for AI Assistant

When creating new documentation files:
1. Always place them in the appropriate `docs/` subfolder
2. Use the path format: `/repo/docs/category/FILENAME.md`
3. Reference other docs using relative paths from the docs folder
4. Add a header note indicating the proper file location if unclear

Example:
```markdown
# Feature Name

> **Location:** `docs/features/FEATURE_NAME.md`

[rest of documentation]
```
