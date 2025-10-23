
//
//  DocumentListViewModel.swift
//  PDFRedactor
//
//  Created by Владислав Скриганюк on 21.10.2025.
//


import SwiftUI
import CoreData
import PDFKit

final class DocumentListViewModel: ObservableObject {

    private let manager = CoreDataManager.shared

    @Published var documents: [PDFDocumentModel] = []

    // MARK: - Merge State.
    
    @Published var isMergingMode = false
    @Published var mergingSource: PDFDocumentModel?
    @Published var mergeTarget: PDFDocumentModel?
    @Published var newName: String = ""

    init() { fetch() }

    // MARK: - Load / Save / Delete.

    func fetch() {
        do {
            let items = try manager.fetchAllDocuments()
            documents = sortNewestFirst(items)
        } catch {
            print("Fetch error:", error)
        }
    }

    func delete(_ doc: PDFDocumentModel) {
        do {
            try manager.deleteDocument(by: doc.id)
            fetch()
        } catch {
            print("Delete error:", error)
        }
    }

    func save(_ model: PDFDocumentModel) {
        do {
            try manager.saveDocument(model)
            fetch()
        } catch {
            print("Save error:", error)
        }
    }

    func shareURL(for doc: PDFDocumentModel) -> URL? {
        let ext = doc.fileExtension ?? "pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(doc.name).\(ext)")
        try? doc.data.write(to: url)
        return url
    }

    // MARK: - Merge logic.

    func startMerge(source: PDFDocumentModel) {
        guard documents.count > 1 else { return }
        mergingSource = source
        isMergingMode = true
    }

    func selectTarget(_ doc: PDFDocumentModel) {
        guard let src = mergingSource, src.id != doc.id else { return }
        mergeTarget = doc
        newName = defaultMergeName()
    }

    func cancelMerge() {
        isMergingMode = false
        mergingSource = nil
        mergeTarget = nil
        newName = ""
    }

    /// Выполняет merge. Создаёт новый документ, исходные НЕ удаляются.
    @discardableResult
    func performMerge() -> Bool {
        guard let a = mergingSource, let b = mergeTarget else { return false }
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultMergeName()
            : newName

        guard let merged = merge(docA: a, docB: b, newName: name) else { return false }

        /// 1) сохраняем новый документ
        save(merged)

        /// 2) очищаем состояние мерджа (исходные остаются в базе)
        cancelMerge()
        return true
    }

    private func merge(docA: PDFDocumentModel, docB: PDFDocumentModel, newName: String) -> PDFDocumentModel? {
        guard let pdfA = PDFDocument(data: docA.data),
              let pdfB = PDFDocument(data: docB.data) else { return nil }

        let merged = PDFDocument()
        var idx = 0
        for i in 0..<pdfA.pageCount { if let p = pdfA.page(at: i) { merged.insert(p, at: idx); idx += 1 } }
        for i in 0..<pdfB.pageCount { if let p = pdfB.page(at: i) { merged.insert(p, at: idx); idx += 1 } }

        guard let newData = merged.dataRepresentation() else { return nil }
        let thumb = PDFUtilities.thumbnail(from: merged)
        return PDFDocumentModel(
            name: newName,
            fileType: "pdf",
            data: newData,
            thumbnail: thumb?.pngData(),
            timestamp: Date() 
        )
    }

    // MARK: - Formatting

    func formattedDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    // MARK: - Helpers

    /// Сортируем: самые свежие сверху
    private func sortNewestFirst(_ items: [PDFDocumentModel]) -> [PDFDocumentModel] {
        items.sorted { $0.timestamp > $1.timestamp }
    }

    private func defaultMergeName() -> String {
        if let a = mergingSource, let b = mergeTarget {
            return "\(a.name) + \(b.name)"
        }
        if let a = mergingSource {
            return "\(a.name) + ..."
        }
        return "Новый документ"
    }
}
