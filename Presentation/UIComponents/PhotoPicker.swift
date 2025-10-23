
//
//  PhotoPicker.swift
//  PDFRedactor
//
//  Created by Владислав Скриганюк on 21.10.2025.
//


import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    
    var configuration: PHPickerConfiguration
    var onComplete: ([PHPickerResult]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) { self.parent = parent }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            parent.onComplete(results)
        }
    }
}
