//
//  ImagePicker.swift
//  Reczipes2
//
//  Created for image selection
//

import SwiftUI
import PhotosUI
#if os(iOS)
import UIKit

// MARK: - Camera Picker

private struct CameraPickerView: UIViewControllerRepresentable {
    let onImageSelected: (PlatformImage) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.dismiss()
            if let image = info[.originalImage] as? PlatformImage {
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

// MARK: - Photo Library Picker (PHPickerViewController)

private struct PHLibraryPickerView: UIViewControllerRepresentable {
    let onImageSelected: (PlatformImage) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHLibraryPickerView
        init(_ parent: PHLibraryPickerView) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let result = results.first else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.parent.onCancel()
                }
                return
            }
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                if let image = object as? UIImage {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.parent.onImageSelected(image)
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.parent.onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Unified ImagePicker

struct ImagePicker: View {
    let sourceType: ImagePickerSourceType
    let onImageSelected: (PlatformImage) -> Void
    let onCancel: () -> Void

    var body: some View {
        if sourceType == .camera {
            CameraPickerView(onImageSelected: onImageSelected, onCancel: onCancel)
        } else {
            PHLibraryPickerView(onImageSelected: onImageSelected, onCancel: onCancel)
        }
    }
}

#else
import AppKit

/// macOS fallback: presents an `NSOpenPanel` to choose an image file.
struct ImagePicker: View {
    let sourceType: ImagePickerSourceType
    let onImageSelected: (PlatformImage) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                let images = MacFilePicker.pickImages(allowsMultiple: false)
                if let first = images.first {
                    onImageSelected(first)
                } else {
                    onCancel()
                }
                dismiss()
            }
    }
}
#endif
