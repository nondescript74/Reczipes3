//
//  AppClipContentView.swift
//  Reczipes2Clip
//
//  Main view for the App Clip experience
//  Created by Zahirudeen Premji on 12/30/25.
//

import SwiftUI

struct AppClipContentView: View {
    @Binding var extractURL: String?
    @State private var showExtractor = false
    @State private var showSuccess = false
    @State private var extractedRecipe: AppClipExtractedRecipeData?
    @State private var isExtracting = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.1),
                        Color.accentColor.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Hero Section
                        VStack(spacing: 16) {
                            // App Clip Badge
                            HStack(spacing: 8) {
                                Image(systemName: "app.badge.checkmark")
                                    .font(.caption)
                                Text("App Clip")
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(20)
                            
                            // App Icon and Title
                            Image(systemName: "book.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.accentColor)
                                .padding()
                                .background(Circle().fill(Color.white))
                                .shadow(radius: 10)
                            
                            VStack(spacing: 8) {
                                Text("Extract Recipe")
                                    .font(.title.bold())
                                
                                Text("Capture recipes from images or websites instantly")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Quick Actions
                        VStack(spacing: 16) {
                            AppClipActionButton(
                                title: "Take Photo",
                                subtitle: "Snap a recipe card or cookbook page",
                                icon: "camera.fill",
                                color: .blue
                            ) {
                                showExtractor = true
                            }
                            
                            AppClipActionButton(
                                title: "From Photos",
                                subtitle: "Choose an existing photo",
                                icon: "photo.on.rectangle",
                                color: .green
                            ) {
                                showExtractor = true
                            }
                            
                            AppClipActionButton(
                                title: "From URL",
                                subtitle: "Extract from a website",
                                icon: "link",
                                color: .orange
                            ) {
                                showExtractor = true
                            }
                        }
                        .padding(.horizontal)
                        
                        // Features List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What You Get")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            AppClipFeatureRow(
                                icon: "wand.and.stars",
                                title: "AI-Powered Extraction",
                                description: "Advanced Claude AI extracts recipe details accurately"
                            )
                            
                            AppClipFeatureRow(
                                icon: "list.bullet.rectangle",
                                title: "Complete Details",
                                description: "Get ingredients, instructions, and nutrition info"
                            )
                            
                            AppClipFeatureRow(
                                icon: "square.and.arrow.down",
                                title: "Save to Full App",
                                description: "Keep your recipes forever with the full app"
                            )
                        }
                        .padding(.vertical)
                        
                        Spacer(minLength: 20)
                        
                        // Get Full App CTA
                        VStack(spacing: 12) {
                            Text("Want More Features?")
                                .font(.headline)
                            
                            Button {
                                openFullApp()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Get Reczipes")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            Text("Recipe collections • CloudKit sync • Diabetic analysis")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
                
                // Extraction overlay
                if isExtracting {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Extracting Recipe...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color.primary.colorInvert().opacity(0.9))
                    .cornerRadius(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showExtractor) {
                if let apiKey = AppClipAPIKeyHelper.getAPIKey() {
                    AppClipRecipeExtractorView(apiKey: apiKey) { recipe in
                        extractedRecipe = recipe
                        showExtractor = false
                        showSuccess = true
                    }
                } else {
                    AppClipAPIKeyPromptView()
                }
            }
            .sheet(isPresented: $showSuccess) {
                if let recipe = extractedRecipe {
                    AppClipSuccessView(recipe: recipe)
                }
            }
            .onAppear {
                // If launched with URL, start extraction
                if let url = extractURL {
                    startURLExtraction(url)
                }
            }
        }
    }
    
    private func startURLExtraction(_ urlString: String) {
        // Implement URL-based extraction
        isExtracting = true
        // Your extraction logic here
        
        // For now, just open the extractor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isExtracting = false
            showExtractor = true
        }
    }
    
    private func openFullApp() {
        // This will prompt the user to download the full app
        // The URL should match your universal link
        if let url = URL(string: "https://yourdomain.com/app") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

struct AppClipActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.15))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct AppClipFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Recipe Extractor View (Simplified)

struct AppClipRecipeExtractorView: View {
    let apiKey: String
    let onExtracted: (AppClipExtractedRecipeData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var isExtracting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let image = selectedImage {
                    // Show selected image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    
                    if isExtracting {
                        ProgressView("Extracting recipe...")
                            .padding()
                    } else {
                        Button {
                            extractRecipe(from: image)
                        } label: {
                            Text("Extract Recipe")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Show image selection options
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Choose a Photo")
                            .font(.title3.bold())
                        
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            Label("Choose from Photos", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Extract Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                AppClipImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                AppClipImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
        }
    }
    
    private func extractRecipe(from image: UIImage) {
        isExtracting = true
        
        // TODO: Integrate with your actual Claude API extraction logic
        // For now, simulate extraction
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExtracting = false
            
            // Mock extracted recipe
            let mockRecipe = AppClipExtractedRecipeData(
                title: "Extracted Recipe",
                servings: 4,
                prepTime: "15 min",
                cookTime: "30 min",
                ingredients: [
                    "2 cups flour",
                    "1 cup sugar",
                    "2 eggs"
                ],
                instructions: [
                    "Mix dry ingredients",
                    "Add wet ingredients",
                    "Bake at 350°F for 30 minutes"
                ],
                notes: "Extracted from App Clip"
            )
            
            onExtracted(mockRecipe)
        }
    }
}

// MARK: - Success View

struct AppClipSuccessView: View {
    let recipe: AppClipExtractedRecipeData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Success Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Recipe Extracted!")
                            .font(.title2.bold())
                        
                        Text(recipe.title)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    // Recipe Details
                    VStack(alignment: .leading, spacing: 16) {
                        // Meta Info
                        HStack(spacing: 20) {
                            MetaBadge(icon: "person.2", text: "\(recipe.servings) servings")
                            if let prepTime = recipe.prepTime {
                                MetaBadge(icon: "clock", text: prepTime)
                            }
                        }
                        
                        // Ingredients
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients")
                                .font(.headline)
                            
                            ForEach(recipe.ingredients, id: \.self) { ingredient in
                                HStack(alignment: .top) {
                                    Text("•")
                                    Text(ingredient)
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instructions")
                                .font(.headline)
                            
                            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.accentColor)
                                    Text(instruction)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    // CTA Section
                    VStack(spacing: 12) {
                        Text("Save this recipe forever")
                            .font(.headline)
                        
                        Button {
                            saveToFullApp()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Get Reczipes & Save")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Text("Plus: sync across devices, organize collections, and more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveToFullApp() {
        // Save recipe to shared App Group
        let sharedDefaults = UserDefaults(suiteName: "group.com.headydiscy.reczipes")
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(recipe) {
            sharedDefaults?.set(encoded, forKey: "appClipPendingRecipe")
        }
        
        // Open full app (triggers installation if needed)
        if let url = URL(string: "https://yourdomain.com/app") {
            UIApplication.shared.open(url)
        }
    }
}

struct MetaBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Image Picker

struct AppClipImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: AppClipImagePicker
        
        init(_ parent: AppClipImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

