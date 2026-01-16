# CloudKit Community Sharing Onboarding Integration Guide

## What This Solves

You discovered that community sharing fails on devices until they're connected to Xcode, which triggers CloudKit initialization. This onboarding system:

1. **Detects CloudKit provisioning issues** before users try to share
2. **Guides users through fixes** with friendly UI
3. **Runs automatic diagnostics** to identify exactly what's wrong
4. **Provides repair functions** to fix common issues without Xcode

## Files Created

1. **CloudKitOnboardingService.swift** - Diagnostic and repair service
2. **CloudKitOnboardingView.swift** - User-facing onboarding UI
3. **This integration guide**

---

## Integration Steps

### Step 1: Add Onboarding to Your Settings

In your `SharingSettingsView.swift` or main settings view, add a button to trigger onboarding:

```swift
import SwiftUI

struct SharingSettingsView: View {
    @StateObject private var onboarding = CloudKitOnboardingService.shared
    @State private var showOnboarding = false
    
    var body: some View {
        List {
            // Your existing settings...
            
            Section("Community Sharing") {
                // Status indicator
                HStack {
                    Text("Status")
                    Spacer()
                    statusIndicator
                }
                
                // Onboarding button
                Button(action: {
                    showOnboarding = true
                }) {
                    Label("Setup & Diagnostics", systemImage: "gear.circle")
                }
                
                // Quick status
                if let diagnostics = onboarding.diagnostics {
                    if diagnostics.isFullyFunctional {
                        Label("Ready to share", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Setup required", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            CloudKitOnboardingView()
        }
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch onboarding.onboardingState {
        case .ready:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .checking:
            ProgressView()
        default:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
    }
}
```

### Step 2: Add First-Launch Check

In your main app file, add an automatic check for new users:

```swift
import SwiftUI

@main
struct Reczipes2App: App {
    @StateObject private var modelContainerManager = ModelContainerManager.shared
    @StateObject private var onboarding = CloudKitOnboardingService.shared
    
    @AppStorage("hasCompletedCloudKitOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboardingSheet = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainerManager.container)
                .task {
                    // Run diagnostics on first launch
                    if !hasCompletedOnboarding {
                        await onboarding.runComprehensiveDiagnostics()
                        
                        // Show onboarding if not ready
                        if case .ready = onboarding.onboardingState {
                            hasCompletedOnboarding = true
                        } else {
                            showOnboardingSheet = true
                        }
                    }
                }
                .sheet(isPresented: $showOnboardingSheet) {
                    CloudKitOnboardingView()
                        .onDisappear {
                            // Mark as completed when they dismiss
                            // (even if not fully set up, don't nag them)
                            hasCompletedOnboarding = true
                        }
                }
        }
    }
}
```

### Step 3: Add Pre-Share Validation

Before allowing users to share, check CloudKit status:

```swift
struct RecipeDetailView: View {
    @StateObject private var onboarding = CloudKitOnboardingService.shared
    @State private var showCloudKitWarning = false
    @State private var showOnboarding = false
    
    var body: some View {
        // Your existing view...
        
        Button(action: {
            // Check CloudKit before sharing
            if case .ready = onboarding.onboardingState {
                shareRecipe()
            } else {
                showCloudKitWarning = true
            }
        }) {
            Label("Share to Community", systemImage: "square.and.arrow.up")
        }
        .alert("Community Sharing Not Available", isPresented: $showCloudKitWarning) {
            Button("Set Up Now") {
                showOnboarding = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("CloudKit needs to be set up before you can share to the community.")
        }
        .sheet(isPresented: $showOnboarding) {
            CloudKitOnboardingView()
        }
    }
    
    private func shareRecipe() {
        // Your existing sharing code...
    }
}
```

### Step 4: Add to TestFlight Release Notes

When sending TestFlight builds, include this in your release notes:

```
NEW: Community Sharing Setup

If you're new to community sharing, the app will guide you through 
a quick setup the first time you try to share. This ensures CloudKit 
is properly configured on your device.

Existing users: Your sharing should continue to work normally.

If you experience issues:
1. Go to Settings → Community Sharing
2. Tap "Setup & Diagnostics"
3. Follow the on-screen instructions
```

### Step 5: Add Manual Trigger to Share Failure Handler

Update your `CloudKitSharingService.swift` to suggest onboarding on failures:

```swift
func shareRecipe(_ recipe: RecipeModel, modelContext: ModelContext) async throws -> String {
    guard isCloudKitAvailable else {
        // Instead of just throwing an error, suggest onboarding
        throw SharingError.cloudKitUnavailable(
            message: "CloudKit is not available. Please run Setup & Diagnostics in Settings."
        )
    }
    
    // Rest of your sharing code...
}
```

Then in your UI where you handle the error:

```swift
.alert("Sharing Failed", isPresented: $showSharingError) {
    Button("Open Setup & Diagnostics") {
        showOnboarding = true
    }
    Button("OK", role: .cancel) {}
} message: {
    Text(sharingErrorMessage)
}
```

---

## How It Works

### Automatic Detection

The `CloudKitOnboardingService` runs comprehensive checks:

1. ✅ **iCloud Account Status** - Is user signed in?
2. ✅ **Container Access** - Can app access `iCloud.com.headydiscy.reczipes`?
3. ✅ **Public DB Read** - Can browse community recipes?
4. ✅ **Public DB Write** - Can share recipes?
5. ✅ **Private DB Access** - Can sync personal data?
6. ✅ **User Identity** - Is user record created?
7. ✅ **User Discoverability** - Can display user's name on shares?

### Automatic Repairs

The service includes repair functions:

- **`attemptRepair()`** - Re-requests container permissions
- **`initializePublicDatabaseSchema()`** - Creates schema in public database
- **Manual steps guide** - Shows users how to fix account issues

### User-Friendly Guidance

The UI shows:

- ✅ **Current status** with visual indicators
- ✅ **Step-by-step fixes** for each issue
- ✅ **Deep links to Settings** when needed
- ✅ **Technical diagnostics** for support tickets
- ✅ **Export diagnostics** to share with support

---

## Testing the Onboarding

### Test Scenario 1: New TestFlight User

1. Install app via TestFlight on a fresh device (or after deleting app)
2. Launch app
3. Onboarding should automatically run and show status
4. If any issues, user sees guided fix

### Test Scenario 2: Existing User with Issues

1. User reports "sharing doesn't work"
2. They go to Settings → Community Sharing
3. Tap "Setup & Diagnostics"
4. See exactly what's wrong and how to fix it

### Test Scenario 3: Export Diagnostics for Support

1. User has persistent issues
2. Open Setup & Diagnostics
3. Tap "View Full Report"
4. Tap Share button
5. Send diagnostics JSON to support team

---

## Diagnostics JSON Format

Users can export this for support tickets:

```json
{
  "timestamp": "2026-01-16T10:30:00Z",
  "accountStatus": "available",
  "containerAccessible": true,
  "publicDatabaseAccessible": false,
  "privateDatabaseAccessible": true,
  "userRecordID": "CKUserId_12345",
  "userDiscoverable": false,
  "canShareToPublic": false,
  "canReadFromPublic": false,
  "isProductionEnvironment": true,
  "errorMessages": [
    "Cannot write to public database"
  ]
}
```

This tells you exactly what's wrong without needing device access.

---

## CloudKit Dashboard Setup (Important!)

For community sharing to work in **Production** (TestFlight/App Store), you MUST:

### 1. Go to CloudKit Dashboard
https://icloud.developer.apple.com/dashboard/

### 2. Select your container
`iCloud.com.headydiscy.reczipes`

### 3. Create record types in Production

You need to manually create these record types in the **Production** environment:

#### SharedRecipe Record Type:
- `recipeData` - String
- `title` - String
- `sharedBy` - String
- `sharedByName` - String
- `sharedDate` - Date/Time
- `mainImage` - Asset (optional)

#### SharedRecipeBook Record Type:
- `bookData` - String
- `name` - String
- `sharedBy` - String
- `sharedByName` - String
- `sharedDate` - Date/Time
- `coverImage` - Asset (optional)

#### OnboardingTest Record Type (for diagnostics):
- `testField` - String
- `timestamp` - Date/Time

### 4. Set Permissions

For both record types, set:
- **World Readable**: Yes (anyone can read)
- **Authenticated Users Can Write**: Yes (signed-in users can write)

### 5. Deploy Schema

After creating record types in Development:
1. Go to "Schema" section
2. Click "Deploy Schema Changes"
3. Select "To Production"
4. Confirm deployment

**This is critical!** TestFlight uses Production environment, not Development.

---

## Monitoring Community Sharing

Add analytics to track success/failure:

```swift
// When sharing succeeds
logInfo("Community share successful", category: "analytics")

// When sharing fails
logError("Community share failed: \(error)", category: "analytics")

// Track onboarding completion
logInfo("Onboarding completed: \(state)", category: "analytics")
```

---

## Support Workflow

When users report "sharing doesn't work":

1. **Ask them to:**
   - Open Settings → Community Sharing
   - Tap "Setup & Diagnostics"
   - Screenshot the checklist
   - OR export diagnostics JSON

2. **Common fixes:**
   - Not signed into iCloud → Guide to Settings
   - Container not accessible → Run "Request Access"
   - Public DB not initialized → Run "Initialize Database"
   - Restricted → Check Screen Time settings

3. **If diagnostics show "ready" but still failing:**
   - Check CloudKit Dashboard for schema deployment
   - Verify Production environment has record types
   - Check for quota limits (rare)

---

## Future Enhancements

Consider adding:

1. **Automatic retry logic** - Retry failed shares automatically
2. **Background diagnostics** - Run checks periodically
3. **Push notification prompt** - Alert when CloudKit becomes available
4. **Community health dashboard** - Show stats on shared recipes
5. **Offline queue** - Queue shares when offline, sync later

---

## Summary

This onboarding system solves the "works with Xcode, fails without" problem by:

✅ **Detecting issues** before users try to share
✅ **Providing guided fixes** for common problems
✅ **Running automatic repairs** when possible
✅ **Generating diagnostics** for support
✅ **Preventing frustration** with clear messaging

Users will now get a **clear, actionable path** to fix CloudKit issues instead of mysterious failures.

The "connect to Xcode" workaround is no longer needed because the app proactively initializes CloudKit and guides users through any permission issues.
