//
//  ContextualHelp.swift
//  Reczipes2
//
//  Contextual help system for all app features
//  Created on 12/18/25.
//

import SwiftUI

// MARK: - Help Content Model

/// Represents a help topic with title, description, and tips
struct HelpTopic: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let description: String
    let tips: [String]
    let relatedTopics: [String]
}

// MARK: - Help Content Database

struct AppHelp {
    
    // MARK: - Main Tabs
    
    static let recipesTab = HelpTopic(
        title: "Recipes Collection",
        icon: "book.fill",
        description: """
        Your personal recipe collection where you can view, organize, and filter all your saved recipes. Recipes appear with thumbnails if images have been assigned.
        """,
        tips: [
            "Tap any recipe to view its full details, ingredients, and instructions",
            "Swipe left on a recipe to delete it",
            "Use the allergen filter bar at the top to find safe recipes based on your dietary needs",
            "The recipe count shows how many recipes are in your collection",
            "Recipes with assigned images display thumbnails for easy visual identification"
        ],
        relatedTopics: ["Recipe Detail", "Allergen Filtering", "Image Assignment"]
    )
    
    static let extractTab = HelpTopic(
        title: "Recipe Extraction",
        icon: "camera.fill",
        description: """
        Extract recipes from photos using Claude AI. Take pictures of recipe cards, cookbook pages, or handwritten recipes and convert them into structured digital recipes instantly.
        """,
        tips: [
            "Tap 'Take Photo' to capture a recipe with your camera",
            "Tap 'Choose from Library' to select an existing photo",
            "Enable 'Image Preprocessing' for old or faded recipe cards",
            "Compare before/after preprocessing to see which works better",
            "Extraction typically takes 15-30 seconds",
            "The source image is automatically saved with your recipe",
            "Review the extracted recipe before saving to ensure accuracy"
        ],
        relatedTopics: ["Image Preprocessing", "Claude API", "Saving Recipes"]
    )
    
    static let settingsTab = HelpTopic(
        title: "Settings",
        icon: "gear",
        description: """
        Configure your app preferences, manage your Claude API key, and view legal information.
        """,
        tips: [
            "Set up your Claude API key to enable recipe extraction",
            "Toggle auto-extract to start extraction immediately after selecting an image",
            "Enable/disable image preprocessing as your default preference",
            "View the license agreement at any time",
            "Check your API key status (configured or not set)"
        ],
        relatedTopics: ["API Key Setup", "License Agreement"]
    )
    
    // MARK: - Recipe Features
    
    static let recipeDetail = HelpTopic(
        title: "Recipe Details",
        icon: "doc.text",
        description: """
        View complete recipe information including ingredients, instructions, notes, and allergen analysis. Edit saved recipes or save extracted recipes to your collection.
        """,
        tips: [
            "Scroll through sections: Image, Ingredients, Instructions, Notes, and Source",
            "Tap 'Edit' (pencil icon) to modify any saved recipe",
            "Tap 'Save' to add an extracted recipe to your collection",
            "Export ingredients to Apple Reminders for grocery shopping",
            "View allergen analysis if you have an active dietary profile",
            "Print or share recipes using the share button",
            "Recipe images are automatically saved from extraction"
        ],
        relatedTopics: ["Recipe Editing", "Allergen Analysis", "Export to Reminders"]
    )
    
    static let recipeEditing = HelpTopic(
        title: "Recipe Editing",
        icon: "pencil",
        description: """
        Edit all aspects of your saved recipes including title, ingredients, instructions, and notes. Add new sections or remove unwanted items.
        """,
        tips: [
            "The title is required - all other fields are optional",
            "Tap 'Add Ingredient Section' to create organized ingredient groups",
            "Tap 'Add Instruction Section' to separate cooking steps",
            "Tap 'Edit' in section headers to reorder or delete sections",
            "Changes are saved when you tap 'Save' in the toolbar",
            "You'll be warned if you try to cancel with unsaved changes",
            "All saved recipes can be edited, regardless of how they were created"
        ],
        relatedTopics: ["Recipe Detail", "Ingredient Sections", "Instruction Sections"]
    )
    
    // MARK: - Image Features
    
    static let imageAssignment = HelpTopic(
        title: "Recipe Images",
        icon: "photo.on.rectangle",
        description: """
        Manage photos for your recipes. Images extracted with recipes are automatically assigned, but you can change or add images anytime.
        """,
        tips: [
            "Green checkmarks indicate recipes that already have assigned images",
            "Tap the pencil icon to change a recipe's image",
            "Select a new photo from your photo library",
            "Images are stored in your app's Documents folder",
            "Compressed JPEG format (80% quality) balances quality and storage",
            "Thumbnails appear throughout the app for visual identification",
            "Images from recipe extraction are automatically saved and assigned"
        ],
        relatedTopics: ["Recipe Extraction", "Image Storage"]
    )
    
    static let imagePreprocessing = HelpTopic(
        title: "Image Preprocessing",
        icon: "wand.and.stars",
        description: """
        Enhance recipe photos before extraction to improve text recognition. Especially useful for old, faded, or low-contrast recipe cards.
        """,
        tips: [
            "Toggle 'Use Image Preprocessing' to enhance your photo",
            "Tap 'Compare Original vs Processed' to see the difference",
            "Preprocessing converts to grayscale and boosts contrast",
            "Text becomes clearer and easier for AI to read",
            "Best for: old recipe cards, faded text, handwritten recipes",
            "May not help for: already clear digital photos, color-dependent recipes",
            "Try extraction both with and without preprocessing to see which works better"
        ],
        relatedTopics: ["Recipe Extraction", "Claude API"]
    )
    
    // MARK: - Allergen Features
    
    static let allergenProfiles = HelpTopic(
        title: "Allergen Profiles",
        icon: "heart.text.square",
        description: """
        Create profiles to track your food allergies, sensitivities, and intolerances. The app automatically analyzes recipes to show which ones are safe for you.
        """,
        tips: [
            "Tap '+' to create a new allergen profile",
            "Add sensitivities from 'Big 9 Allergens' or 'Intolerances' tabs",
            "Set severity levels: Mild, Moderate, or Severe",
            "Only one profile can be active at a time",
            "Toggle 'Active Profile' ON to enable automatic recipe analysis",
            "Add optional notes about your reactions or restrictions",
            "Create multiple profiles for different family members or scenarios"
        ],
        relatedTopics: ["Allergen Analysis", "Food Sensitivities", "FODMAP Analysis"]
    )
    
    static let allergenAnalysis = HelpTopic(
        title: "Allergen Analysis",
        icon: "checkmark.shield",
        description: """
        Automatic safety scoring for recipes based on your allergen profile. See which ingredients contain allergens and get risk level assessments.
        """,
        tips: [
            "Enable filtering in the recipe list to see safety badges",
            "Green checkmark (✅) = Safe - no detected allergens",
            "Yellow/Orange/Red warnings (⚠️) = allergens detected",
            "Tap 'View Detailed Analysis' to see which ingredients triggered detection",
            "Higher severity levels (Severe vs Mild) increase the risk score",
            "The system checks 16 different allergens and intolerances",
            "Toggle 'Safe Only' to show only recipes without detected allergens"
        ],
        relatedTopics: ["Allergen Profiles", "Food Sensitivities", "Recipe Filtering"]
    )
    
    static let fodmapAnalysis = HelpTopic(
        title: "FODMAP Analysis",
        icon: "heart.text.square.fill",
        description: """
        Specialized analysis for Low FODMAP diets based on Monash University research. Identifies high FODMAP ingredients and suggests alternatives.
        """,
        tips: [
            "Add 'FODMAPs' to your allergen profile to enable this analysis",
            "The system checks all four FODMAP categories: Oligosaccharides, Disaccharides, Monosaccharides, and Polyols",
            "Many foods are low FODMAP in small portions but high in large amounts",
            "Look for serving size guidance in detailed analysis",
            "Get suggestions for low FODMAP alternatives (e.g., garlic-infused oil instead of garlic)",
            "Based on current Monash University FODMAP research",
            "Combine with Claude AI analysis for detecting hidden FODMAPs"
        ],
        relatedTopics: ["Allergen Analysis", "Food Intolerances", "Recipe Modifications"]
    )
    
    static let allergenFiltering = HelpTopic(
        title: "Allergen Filtering",
        icon: "line.3.horizontal.decrease.circle",
        description: """
        Filter and sort your recipe collection by allergen safety. Find recipes that are safe for your dietary needs quickly.
        """,
        tips: [
            "Tap the filter bar at the top of the recipe list to access filtering",
            "Enable the filter toggle to activate allergen-based sorting",
            "Tap 'Safe Only' to show only recipes with no detected allergens",
            "Without 'Safe Only', recipes are sorted by safety score (safest first)",
            "Tap your profile name in the filter bar to manage allergen profiles",
            "Allergen badges appear on each recipe showing its safety level",
            "An active profile is required for filtering to work"
        ],
        relatedTopics: ["Allergen Profiles", "Allergen Analysis", "Recipe Collection"]
    )
    
    // MARK: - API & Setup Features
    
    static let apiKeySetup = HelpTopic(
        title: "Claude API Key Setup",
        icon: "key.fill",
        description: """
        Configure your Anthropic Claude API key to enable recipe extraction from images. Your key is stored securely in the iOS Keychain.
        """,
        tips: [
            "Visit console.anthropic.com to create an account and get an API key",
            "Your API key starts with 'sk-ant-api03-'",
            "Keys are stored securely in the iOS Keychain, never in plain text",
            "Recipe extraction costs approximately $0.02 per recipe",
            "You can change or remove your API key anytime in Settings",
            "The app checks your key status and shows green checkmark when configured",
            "API keys are private - never share them publicly"
        ],
        relatedTopics: ["Recipe Extraction", "Settings", "Security"]
    )
    
    static let claudeAPI = HelpTopic(
        title: "Claude AI Integration",
        icon: "sparkles",
        description: """
        The app uses Claude Sonnet 4, Anthropic's advanced AI model, to extract recipes from images with high accuracy and comprehensive detail parsing.
        """,
        tips: [
            "Claude can read printed text, handwritten recipes, and even complex layouts",
            "Extraction includes: ingredients with quantities, step-by-step instructions, notes, yield, and source references",
            "The AI organizes multi-section recipes (e.g., 'For the dough', 'For the filling')",
            "Metric conversions are included when available",
            "Processing typically takes 15-30 seconds depending on image complexity",
            "Enhanced allergen detection can identify hidden allergens in ingredients",
            "Cost is approximately $0.02 per recipe extraction"
        ],
        relatedTopics: ["Recipe Extraction", "API Key Setup", "Image Preprocessing"]
    )
    
    // MARK: - Data & Storage
    
    static let dataStorage = HelpTopic(
        title: "Data Storage",
        icon: "internaldrive",
        description: """
        All your recipes, images, and preferences are stored locally on your device using SwiftData and the iOS file system.
        """,
        tips: [
            "Recipes are stored in SwiftData for fast, efficient access",
            "Recipe images are saved as JPEG files in your app's Documents folder",
            "Image assignments link recipes to their photos",
            "Allergen profiles are stored in SwiftData",
            "Your API key is stored securely in the iOS Keychain",
            "All data is private and stored only on your device",
            "No cloud sync (can be added in future versions)"
        ],
        relatedTopics: ["Recipe Collection", "Image Assignment", "Privacy"]
    )
    
    static let exportToReminders = HelpTopic(
        title: "Export to Reminders",
        icon: "checklist",
        description: """
        Export recipe ingredients directly to Apple Reminders as a shopping list. Perfect for grocery shopping with your recipes.
        """,
        tips: [
            "Tap the export button in recipe detail view",
            "Ingredients are organized by section if your recipe has multiple sections",
            "Each ingredient becomes a checkable reminder item",
            "You'll need to grant Reminders access the first time",
            "Lists are created with the recipe title as the list name",
            "Check off items as you shop",
            "You can edit the reminder list in the Reminders app"
        ],
        relatedTopics: ["Recipe Detail", "Ingredients"]
    )
    
    // MARK: - Additional Features
    
    static let licenseAgreement = HelpTopic(
        title: "License Agreement",
        icon: "doc.text",
        description: """
        The app's terms of use and license agreement. You accepted this when first launching the app.
        """,
        tips: [
            "View the full license text anytime from Settings",
            "The acceptance date is recorded and displayed in Settings",
            "The app follows standard iOS privacy practices",
            "All data is stored locally on your device",
            "No personal data is collected or transmitted",
            "The license covers app usage and Claude API integration"
        ],
        relatedTopics: ["Settings", "Privacy", "Legal"]
    )
    
    static let launchScreen = HelpTopic(
        title: "Launch Screen",
        icon: "sparkles",
        description: """
        The animated launch screen that appears when you first open the app. Shows the app logo and name with a smooth animation.
        """,
        tips: [
            "The launch screen appears only once per app session",
            "It won't show again when returning from background",
            "Provides a polished first impression",
            "Automatically dismisses after animation completes"
        ],
        relatedTopics: ["App Launch"]
    )
    
    // MARK: - CloudKit & Sync Features
    
    static let cloudKitSync = HelpTopic(
        title: "iCloud Sync",
        icon: "icloud.fill",
        description: """
        Your recipes automatically sync across all your devices using iCloud. Create a recipe on your iPhone and it appears on your iPad instantly.
        """,
        tips: [
            "Sign in with the same Apple ID on all devices to enable sync",
            "Ensure iCloud Drive is enabled in Settings → [Your Name] → iCloud",
            "Initial sync can take 5-10 minutes after first launch",
            "Sync works faster when on Wi-Fi and app is in foreground",
            "All recipe data is encrypted end-to-end for privacy",
            "Check sync status in Settings → iCloud Sync",
            "No manual sync needed - it happens automatically"
        ],
        relatedTopics: ["CloudKit Setup", "Sync Troubleshooting", "Container Details"]
    )
    
    static let cloudKitSetup = HelpTopic(
        title: "CloudKit Setup",
        icon: "gearshape.icloud",
        description: """
        CloudKit enables your recipes to sync across all your Apple devices. Setup is automatic, but you need to be signed into iCloud.
        """,
        tips: [
            "Open Settings app on your device",
            "Sign in with your Apple ID at the top",
            "Go to iCloud and enable iCloud Drive",
            "Restart the Reczipes app after enabling iCloud",
            "Check Settings → iCloud Sync in the app to verify status",
            "Green checkmark means CloudKit is working properly",
            "Orange or red warnings indicate setup issues that need attention"
        ],
        relatedTopics: ["iCloud Sync", "Sync Troubleshooting", "CloudKit Diagnostics"]
    )
    
    static let cloudKitDiagnostics = HelpTopic(
        title: "CloudKit Diagnostics",
        icon: "stethoscope",
        description: """
        Built-in diagnostic tools help you troubleshoot sync issues and verify your CloudKit configuration. Access detailed system information and test connectivity.
        """,
        tips: [
            "Go to Settings → CloudKit Diagnostics to run tests",
            "Tap 'Run Full Diagnostics' to check all sync components",
            "Green checkmarks mean everything is working",
            "Red X marks indicate problems that need fixing",
            "Compare diagnostics on both devices if sync isn't working",
            "Use 'Copy Diagnostics to Clipboard' to save results",
            "Force Sync Check can help trigger delayed sync operations"
        ],
        relatedTopics: ["iCloud Sync", "Sync Troubleshooting", "Container Details"]
    )
    
    static let syncTroubleshooting = HelpTopic(
        title: "Sync Troubleshooting",
        icon: "wrench.and.screwdriver",
        description: """
        If recipes aren't syncing between devices, this guide helps you identify and fix common issues. Most problems are quick to resolve.
        """,
        tips: [
            "Verify you're signed into the SAME Apple ID on both devices",
            "Check that iCloud Drive is enabled on both devices",
            "Wait 5-10 minutes for initial sync (it's not instant)",
            "Ensure both devices have good network connectivity",
            "Open Settings → CloudKit Diagnostics and compare results",
            "Look for 'CloudKit sync enabled' in app console logs",
            "If one device shows 'local-only', CloudKit isn't working on that device"
        ],
        relatedTopics: ["CloudKit Diagnostics", "iCloud Sync", "Container Details"]
    )
    
    static let containerDetails = HelpTopic(
        title: "Container Details",
        icon: "cylinder.split.1x2",
        description: """
        View detailed information about your app's persistent storage container and CloudKit configuration. Useful for verifying setup and debugging.
        """,
        tips: [
            "Access via Settings → Container Details",
            "Check that 'CloudKit Enabled' shows 'Yes'",
            "Verify Container ID matches: iCloud.com.headydiscy.reczipes",
            "Compare configurations on both devices - they should match",
            "Recipe count shows how many recipes are stored locally",
            "Use 'Copy Configuration' to save technical details",
            "Storage location shows where your data is physically stored"
        ],
        relatedTopics: ["CloudKit Diagnostics", "iCloud Sync", "Data Storage"]
    )
    
    // MARK: - Category Organization
    
    static let allTopics: [String: HelpTopic] = [
        // Main Tabs
        "recipesTab": recipesTab,
        "extractTab": extractTab,
        "settingsTab": settingsTab,
        
        // Recipe Features
        "recipeDetail": recipeDetail,
        "recipeEditing": recipeEditing,
        
        // Image Features
        "imageAssignment": imageAssignment,
        "imagePreprocessing": imagePreprocessing,
        
        // Allergen Features
        "allergenProfiles": allergenProfiles,
        "allergenAnalysis": allergenAnalysis,
        "fodmapAnalysis": fodmapAnalysis,
        "allergenFiltering": allergenFiltering,
        
        // API & Setup
        "apiKeySetup": apiKeySetup,
        "claudeAPI": claudeAPI,
        
        // Data & Storage
        "dataStorage": dataStorage,
        "exportToReminders": exportToReminders,
        
        // CloudKit & Sync
        "cloudKitSync": cloudKitSync,
        "cloudKitSetup": cloudKitSetup,
        "cloudKitDiagnostics": cloudKitDiagnostics,
        "syncTroubleshooting": syncTroubleshooting,
        "containerDetails": containerDetails,
        
        // Additional
        "licenseAgreement": licenseAgreement,
        "launchScreen": launchScreen
    ]
    
    static func topic(for key: String) -> HelpTopic? {
        allTopics[key]
    }
    
    // Organized by category for help browser
    static let categories: [(name: String, icon: String, topics: [HelpTopic])] = [
        ("Getting Started", "figure.walk", [
            launchScreen,
            licenseAgreement,
            apiKeySetup
        ]),
        ("Main Features", "star.fill", [
            recipesTab,
            extractTab,
            recipeDetail,
            recipeEditing
        ]),
        ("Images", "photo.fill", [
            imageAssignment,
            imagePreprocessing
        ]),
        ("Allergen & Dietary", "heart.fill", [
            allergenProfiles,
            allergenAnalysis,
            fodmapAnalysis,
            allergenFiltering
        ]),
        ("CloudKit & Sync", "icloud.fill", [
            cloudKitSync,
            cloudKitSetup,
            cloudKitDiagnostics,
            syncTroubleshooting,
            containerDetails
        ]),
        ("Advanced", "gear", [
            claudeAPI,
            exportToReminders,
            dataStorage,
            settingsTab
        ])
    ]
}

// MARK: - Help Views

/// Quick help button that can be added to any view
struct HelpButton: View {
    let topicKey: String
    @State private var showingHelp = false
    
    var body: some View {
        Button {
            showingHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.title3)
        }
        .sheet(isPresented: $showingHelp) {
            if let topic = AppHelp.topic(for: topicKey) {
                HelpDetailView(topic: topic)
            }
        }
    }
}

/// Full help detail view
struct HelpDetailView: View {
    let topic: HelpTopic
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with icon
                    HStack {
                        Image(systemName: topic.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(.tint)
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    // Description
                    Text(topic.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Divider()
                    
                    // Tips Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Tips & Tricks", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        
                        ForEach(Array(topic.tips.enumerated()), id: \.offset) { index, tip in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20, alignment: .trailing)
                                
                                Text(tip)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    
                    // Related Topics
                    if !topic.relatedTopics.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Related Topics", systemImage: "link")
                                .font(.headline)
                                .foregroundStyle(.blue)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(topic.relatedTopics, id: \.self) { related in
                                    Text(related)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(topic.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Browse all help topics
struct HelpBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredCategories: [(name: String, icon: String, topics: [HelpTopic])] {
        guard !searchText.isEmpty else {
            return AppHelp.categories
        }
        
        let lowercasedSearch = searchText.lowercased()
        return AppHelp.categories.compactMap { category in
            let filteredTopics = category.topics.filter { topic in
                topic.title.lowercased().contains(lowercasedSearch) ||
                topic.description.lowercased().contains(lowercasedSearch)
            }
            
            if filteredTopics.isEmpty {
                return nil
            } else {
                return (category.name, category.icon, filteredTopics)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCategories, id: \.name) { category in
                    Section {
                        ForEach(category.topics) { topic in
                            NavigationLink {
                                HelpDetailView(topic: topic)
                            } label: {
                                Label {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(topic.title)
                                            .font(.headline)
                                        
                                        Text(topic.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                } icon: {
                                    Image(systemName: topic.icon)
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    } header: {
                        Label(category.name, systemImage: category.icon)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search help topics")
            .navigationTitle("Help")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

/// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    // Start new line
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - View Extensions for Help

extension View {
    /// Add a help button to any view's toolbar
    func helpButton(for topicKey: String) -> some View {
        toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HelpButton(topicKey: topicKey)
            }
        }
    }
}

// MARK: - Quick Reference Card

/// Show a quick reference card for a feature
struct QuickReferenceCard: View {
    let topic: HelpTopic
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: topic.icon)
                        .font(.title2)
                        .foregroundStyle(.tint)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(topic.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(topic.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Help Detail") {
    HelpDetailView(topic: AppHelp.recipesTab)
}

#Preview("Help Browser") {
    HelpBrowserView()
}

#Preview("Help Button") {
    NavigationStack {
        Text("Sample View")
            .navigationTitle("Sample")
            .helpButton(for: "recipesTab")
    }
}
