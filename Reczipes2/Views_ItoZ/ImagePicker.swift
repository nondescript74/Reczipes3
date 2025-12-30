//
//  ImagePicker.swift
//  Reczipes2
//
//  Created for image selection
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Dismiss immediately
            parent.dismiss()
            
            // Then handle the image after dismiss completes
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.parent.onImageSelected(image)
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.parent.onCancel()
            }
        }
    }
}
