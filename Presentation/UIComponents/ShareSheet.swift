
//  ShareSheet.swift
//  PDFRedactor
//
//  Created by Владислав Скриганюк on 21.10.2025.
//


import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let validItems = activityItems.compactMap { $0 as AnyObject? }
              let controller = UIActivityViewController(activityItems: validItems, applicationActivities: nil)
              controller.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
              return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
