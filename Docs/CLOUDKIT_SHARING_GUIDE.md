# CloudKit Community Sharing Implementation Guide

## Overview

This implementation enables all users of Reczipes2 to share their recipes, recipe books, images, tips, and notes with each other through CloudKit's **Public Database**. Unlike CloudKit's private database (which syncs a user's personal data across their devices), the public database allows all users to read and write shared content that's visible to everyone.

## Architecture

### CloudKit Database Zones

1. **Private Database** (Existing)
   - Stores user's personal recipes
   - Syncs across user's devices
   - Only accessible by the user who created the data

2. **Public Database** (New)
   - Stores shared community recipes
   - Readable by all app users
   - Each user can write their own shared content
   - Users can import others' shared recipes to their private collection

### Data Models

#### SwiftData Models (Local Tracking)

- **`SharedRecipe`**: Tracks which of the user's recipes are shared
- **`SharedRecipeBook`**: Tracks which of the user's books are shared
- **`SharingPreferences`**: User's sharing settings and preferences

#### CloudKit Models (Public Database)

- **`CloudKitRecipe`**: Codable representation of a recipe for CloudKit
- **`CloudKitRecipeBook`**: Codable representation of a recipe book
- **Record Types**: `SharedRecipe`, `SharedRecipeBook`, `SharedImage`

### Service Layer

**`CloudKitSharingService`**: Singleton service that handles:
- Uploading recipes/books to public database
- Downloading shared content from other users
- Image uploads as CloudKit assets
- User identity management
- CloudKit availability checking

## Key Features

### 1. Share All or Select Specific Items

Users can:
- Enable "Share All Recipes" - automatically shares all current and future recipes
- Enable "Share All Books" - automatically shares all current and future books
- Manually select specific recipes or books to share
- Unshare individual items at any time

### 2. Community Browser

- Browse all recipes shared by other users
- Search by recipe name or author name
- View full recipe details before importing
- One-tap import to personal collection

### 3. Privacy Controls

- Users can choose whether to display their name or remain anonymous
- All sharing is explicit - nothing is shared without user action
- Users can unshare content at any time

### 4. Image Sharing

- Recipe images are automatically uploaded with shared recipes
- Images are stored as CloudKit CKAsset types
- Downloaded and cached when importing shared recipes

## Implementation Steps

### Step 1: Update Schema with Migration

You need to add the new SwiftData models to your schema:

```swift
// Add to your ModelContainer configuration in Reczipes2App.swift
let container = try ModelContainer(
    for: Recipe.self,
        RecipeImageAssignment.self,
        UserAllergenProfile.self,
        CachedDiabeticAnalysis.self,
        SavedLink.self,
        RecipeBook.self,
        CookingSession.self,
        SharedRecipe.self,          // NEW
        SharedRecipeBook.self,      // NEW
        SharingPreferences.self,    // NEW
    migrationPlan: Reczipes2MigrationPlan.self,
    configurations: cloudKitConfiguration
)
```

### Step 2: Configure CloudKit Dashboard

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your container: `iCloud.com.headydiscy.reczipes`
3. Go to **Schema** → **Record Types**
4. Create new record types:

#### SharedRecipe Record Type

Fields:
- `recipeData` (String) - JSON-encoded recipe data
- `title` (String, indexed) - Recipe title for searching
- `sharedBy` (String, indexed) - User ID who shared
- `sharedByName` (String) - User's display name
- `sharedDate` (Date/Time, indexed) - When shared
- `mainImage` (Asset) - Recipe's main image

#### SharedRecipeBook Record Type

Fields:
- `bookData` (String) - JSON-encoded book data
- `name` (String, indexed) - Book name
- `sharedBy` (String, indexed) - User ID who shared
- `sharedByName` (String) - User's display name
- `sharedDate` (Date/Time, indexed) - When shared
- `coverImage` (Asset) - Book's cover image

### Step 3: Update Entitlements

Your `Reczipes2.entitlements` should already have CloudKit enabled. Verify it includes:

```xml
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

No additional entitlements are needed for public database access.

### Step 4: Add Navigation to Settings

Add the sharing settings to your Settings view:

```swift
// In SettingsView.swift
Section("Community") {
    NavigationLink {
        SharingSettingsView()
    } label: {
        Label("Sharing & Community", systemImage: "person.3.fill")
    }
}
```

### Step 5: Handle Recipe Entity Conversion

You need to implement conversion between your SwiftData `Recipe` entity and `RecipeModel`:

```swift
// Add this extension to convert Recipe (SwiftData) to RecipeModel (Codable)
extension Recipe {
    func toRecipeModel() -> RecipeModel {
        // Implement based on your Recipe entity structure
        // This depends on how you've defined your Recipe @Model class
        return RecipeModel(
            id: self.id,
            title: self.title,
            // ... map all properties
        )
    }
}
```

## Usage Flow

### Sharing a Recipe

1. User goes to Settings → Sharing & Community
2. Enables "Share All Recipes" OR selects "Share Specific Recipes"
3. System uploads recipe data to CloudKit Public Database
4. Local `SharedRecipe` entity tracks the share status
5. Other users can now see this recipe in Community Browser

### Importing a Shared Recipe

1. User goes to Settings → Sharing & Community → Browse Shared Recipes
2. System queries CloudKit Public Database for all shared recipes
3. User taps a recipe to view details
4. User taps "Import" to add to personal collection
5. Recipe is copied to user's private database
6. Recipe now appears in user's personal recipes list

### Unsharing Content

1. User goes to Settings → Sharing & Community → Manage Shared Content
2. User selects a shared recipe or book
3. User taps "Unshare"
4. System deletes record from CloudKit Public Database
5. Local tracking entity is updated
6. Content is no longer visible to other users

## Security & Privacy

### Data Visibility

- **Public Database**: All shared content is readable by anyone with the app
- **No sensitive data**: Don't share recipes with personal/sensitive information
- **User attribution**: Shared content includes the user ID (CKRecord.ID) of who shared it

### CloudKit Permissions

- **Reading**: Anyone can read from public database (no authentication required)
- **Writing**: Users must be authenticated with iCloud to write
- **Deleting**: Users can only delete their own shared records

### Privacy Best Practices

1. **Warn users**: Shared content is public to all app users
2. **Anonymous option**: Users can disable name display
3. **Review before share**: Show preview of what will be shared
4. **Easy unshare**: Provide simple way to unshare content

## Testing

### Local Testing

1. Use two different iCloud accounts in Simulator
2. Share a recipe from Account A
3. Switch to Account B
4. Verify recipe appears in community browser
5. Import recipe to Account B
6. Verify it appears in Account B's private collection

### Production Testing

1. TestFlight beta testers can share real content
2. Monitor CloudKit Dashboard for usage metrics
3. Check error logs for upload/download failures

## Performance Considerations

### Batch Operations

```swift
// When sharing multiple recipes, use batch operations
let result = await sharingService.shareMultipleRecipes(
    recipes,
    modelContext: modelContext
)
```

### Caching

- Shared recipe metadata is cached locally in `SharedRecipe` entities
- Full recipe data is fetched on-demand when viewing details
- Images are downloaded lazily and cached

### Rate Limiting

CloudKit has rate limits:
- **Requests per second**: ~40 per user
- **Asset uploads**: ~20 MB/s per user
- **Public database**: Shared quota across all users

Implement retry logic for:
- `CKError.requestRateLimited`
- `CKError.zoneBusy`
- `CKError.serviceUnavailable`

## Error Handling

### Common Errors

1. **Not authenticated**
   - User not signed in to iCloud
   - Show alert: "Sign in to iCloud to share content"

2. **CloudKit unavailable**
   - No internet connection
   - CloudKit service down
   - Show: "Try again later"

3. **Upload failed**
   - Network timeout
   - File too large
   - Retry with exponential backoff

4. **Invalid data**
   - Recipe data corrupt
   - Missing required fields
   - Show: "This recipe can't be shared"

### Error Recovery

```swift
do {
    let recordID = try await sharingService.shareRecipe(recipe, modelContext: modelContext)
    // Success
} catch SharingError.notAuthenticated {
    // Prompt to sign in
} catch SharingError.cloudKitUnavailable {
    // Show offline message
} catch {
    // Generic error handling
}
```

## CloudKit Dashboard Monitoring

Monitor these metrics:
1. **Public database size**: Should stay within limits
2. **Request rates**: Watch for throttling
3. **Error rates**: High errors indicate issues
4. **Active users**: How many people are sharing

## Future Enhancements

### Phase 2 Features

1. **Comments & Ratings**: Users can comment on shared recipes
2. **Collections**: Featured/popular recipe collections
3. **User Profiles**: See all recipes from a specific user
4. **Categories**: Tag shared recipes by cuisine/type
5. **Moderation**: Report inappropriate content

### Phase 3 Features

1. **Shared Zones**: Private sharing between specific users
2. **Collaborative Books**: Multiple users edit same book
3. **Recipe Variations**: Fork and modify shared recipes
4. **Social Features**: Follow users, like recipes

## Troubleshooting

### "No shared recipes appearing"

1. Check CloudKit status in Settings
2. Verify record type exists in CloudKit Dashboard
3. Check console for fetch errors
4. Ensure public database permissions are correct

### "Can't upload images"

1. Check image file size (<50 MB for CloudKit assets)
2. Verify image file exists at expected path
3. Check network connection
3. Review CloudKit asset quota

### "Sharing disabled"

1. Verify user is signed in to iCloud
2. Check device restrictions (parental controls)
3. Ensure app has iCloud permissions
4. Test CloudKit availability

## Code Files Reference

### New Files Created

1. **`SharedContentModels.swift`**: SwiftData models for tracking shared content
2. **`CloudKitSharingService.swift`**: Service layer for CloudKit operations
3. **`SharingSettingsView.swift`**: UI for managing sharing preferences
4. **`SharedRecipesBrowserView.swift`**: UI for browsing community recipes

### Files to Modify

1. **`Reczipes2App.swift`**: Add new models to ModelContainer
2. **`SettingsView.swift`**: Add navigation to sharing settings
3. **Migration plan**: Add schema version for new models

## Summary

This implementation provides a complete community sharing system using CloudKit's Public Database. Users can share recipes and books with the entire community, browse others' shared content, and import recipes to their personal collection. The system includes privacy controls, image sharing, and comprehensive error handling.

The key advantage over export/import is that all shared content is automatically available to all users without manual file transfers. Updates to shared recipes can be re-synced, and popular recipes can be discovered by the community.
