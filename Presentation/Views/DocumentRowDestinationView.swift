
//
//  DocumentRowDestinationView.swift
//  PDFRedactor
//
//  Created by Владислав Скриганюк on 21.10.2025.
//


import SwiftUI
import PDFKit

struct DocumentRowDestinationView: View {

    let model: PDFDocumentModel
    var body: some View {
        PDFReaderView(data: model.data) { _ in }.navigationTitle(model.name)

    }
}
