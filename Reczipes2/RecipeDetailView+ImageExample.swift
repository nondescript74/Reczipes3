//
//  RecipeDetailView+ImageExample.swift
//  Reczipes2
//
//  Example: How to add recipe images to RecipeDetailView
//

/*
 
 To add images to your RecipeDetailView, update the header section like this:
 
 Before the title, add:
 
 ```swift
 // Recipe Image (if available)
 if let imageName = recipe.imageName {
     RecipeImageView(
         imageName: imageName,
         size: CGSize(width: UIScreen.main.bounds.width - 32, height: 250),
         cornerRadius: 16
     )
     .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
     .padding(.bottom, 8)
 }
 ```
 
 Or for a more compact inline version with the title:
 
 ```swift
 HStack(alignment: .top, spacing: 16) {
     // Thumbnail
     if let imageName = recipe.imageName {
         RecipeImageView(
             imageName: imageName,
             size: CGSize(width: 120, height: 120),
             cornerRadius: 12
         )
         .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
     }
     
     // Title and details
     VStack(alignment: .leading, spacing: 8) {
         Text(recipe.title)
             .font(.largeTitle)
             .fontWeight(.bold)
         
         if let headerNotes = recipe.headerNotes {
             Text(headerNotes)
                 .font(.body)
                 .foregroundStyle(.secondary)
                 .italic()
         }
     }
 }
 ```
 
 Or for a full-width hero image with overlay:
 
 ```swift
 ZStack(alignment: .bottomLeading) {
     if let imageName = recipe.imageName {
         Image(imageName)
             .resizable()
             .scaledToFill()
             .frame(height: 300)
             .clipped()
             .overlay(
                 LinearGradient(
                     colors: [.clear, .black.opacity(0.7)],
                     startPoint: .top,
                     endPoint: .bottom
                 )
             )
         
         VStack(alignment: .leading, spacing: 8) {
             Text(recipe.title)
                 .font(.largeTitle)
                 .fontWeight(.bold)
                 .foregroundStyle(.white)
             
             if let headerNotes = recipe.headerNotes {
                 Text(headerNotes)
                     .font(.body)
                     .foregroundStyle(.white.opacity(0.9))
                     .italic()
             }
         }
         .padding(24)
     } else {
         // Fallback to text-only header if no image
         VStack(alignment: .leading, spacing: 8) {
             Text(recipe.title)
                 .font(.largeTitle)
                 .fontWeight(.bold)
             
             if let headerNotes = recipe.headerNotes {
                 Text(headerNotes)
                     .font(.body)
                     .foregroundStyle(.secondary)
                     .italic()
             }
         }
     }
 }
 ```
 
 Choose the style that fits your app's design best!
 
 */

// This file is for reference only and should not be added to your target.
// Copy the code snippets above into RecipeDetailView.swift where appropriate.
