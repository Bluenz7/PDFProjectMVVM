
//
//  CreatePDFViewModel.swift
//  PDFRedactor
//
//  Created by Владислав Скриганюк on 21.10.2025.
//

import Combine
import PDFKit
import CoreData


final class CreatePDFViewModel: ObservableObject {

    struct PageItem: Identifiable, Equatable {
        let id: UUID
        var image: UIImage
    }

    private let manager = CoreDataManager.shared

    @Published var pages: [PageItem] = []
    @Published var generatedPDFData: Data?
    @Published var name = ""

    var canGenerate: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !pages.isEmpty
    }

    // MARK: - Mutations.

    func append(images: [UIImage]) {
        let items = images.map { PageItem(id: UUID(), image: $0) }
        pages.append(contentsOf: items)
        if generatedPDFData != nil { generatePDF() }
    }

    func remove(id: UUID) {
        pages.removeAll { $0.id == id }   /// удаление по стабильному ID
        if generatedPDFData != nil { generatePDF() }
    }

    // MARK: - PDF.

    func generatePDF() {
        guard canGenerate else {
            generatedPDFData = nil
            return
        }
        let imgs = pages.map { $0.image }
        generatedPDFData = PDFUtilities.imagesToPDFData(images: imgs)
    }

    func saveGeneratedPDF() throws {
        guard let data = generatedPDFData else { return }
        let thumb = PDFUtilities.thumbnail(from: PDFDocument(data: data))
        try manager.saveDocument(
            PDFDocumentModel(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                fileType: "pdf",
                data: data,
                thumbnail: thumb?.pngData(),
                timestamp: Date()
            )
        )
    }
}
