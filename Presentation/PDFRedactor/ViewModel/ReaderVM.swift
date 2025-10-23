//
//  ReaderVM.swift
//  SwiftUIPDFProject
//
//  Created by Владислав Скриганюк on 21.10.2025.
//

import Foundation
import SwiftUI
import PDFKit

final class PDFReaderVM: ObservableObject {

    // MARK: - Where the data comes from.
    
    enum Source {
        case saved(model: PDFDocumentModel)          /// документ из Core Data (есть id)
        case ephemeral(onUpdate: ((Data) -> Void)?)  /// Core daty не трогаем при этом используем временный - из конструктора
    }

    // MARK: - Published state for the View.
    
    @Published private(set) var source: Source
    @Published var data: Data
    @Published var pageImages: [UIImage] = []
    @Published var selectedIndex: Int? = nil

    // MARK: - Private Properties.
    
    private let core = CoreDataManager.shared
    private var lastWidth: CGFloat = 0

    // MARK: - Inits.
    
    init(savedModel: PDFDocumentModel) {
        self.source = .saved(model: savedModel)
        self.data = savedModel.data
    }

    init(ephemeralData: Data, onUpdate: ((Data) -> Void)? = nil) {
        self.source = .ephemeral(onUpdate: onUpdate)
        self.data = ephemeralData
    }

    // MARK: - Rendering.
    
    /// Производим полный рендер страниц под необходимую  ширину. Если force == false, не перерендерит при той же ширине
    func render(width: CGFloat, force: Bool = false) {
        if !force {
            guard width > 0, abs(width - lastWidth) > 0.5 else { return }
        }
        lastWidth = width

        guard let doc = PDFDocument(data: data) else {
            DispatchQueue.main.async {
                self.pageImages = []
                self.selectedIndex = nil
            }
            return
        }

        var imgs: [UIImage] = []
        let targetW = width

        for i in 0..<doc.pageCount {
            guard let p = doc.page(at: i) else { continue }
            let media = p.bounds(for: .mediaBox)
            let targetH = media.height * (targetW / media.width)

            // Стабильный рендер: без drawingTransform, через thumbnail
            let img = p.thumbnail(of: CGSize(width: targetW, height: targetH), for: .mediaBox)
            imgs.append(img)
        }

        DispatchQueue.main.async {
            self.pageImages = imgs
            if let sel = self.selectedIndex, sel >= imgs.count { self.selectedIndex = nil }
        }
    }

    /// Совместимостный хелпер
    func renderIfNeeded(width: CGFloat) { render(width: width, force: false) }

    // MARK: - Selection.
    
    func select(_ index: Int) {
        guard index >= 0 && index < pageImages.count else { return }
        selectedIndex = index
    }

    // MARK: - Delete.
    /// Удаляет выбранную страницу, мгновенно обновляет UI, перегенерит превью и,
    /// если документ сохранённый — обновляет запись в Core Data (без создания дубликата).
    /// Реализация и пояснения из 5 шагов
    @discardableResult
    func deleteSelectedPage() -> Bool {
        guard let idx = selectedIndex,
              let doc = PDFDocument(data: data),
              idx < doc.pageCount else { return false }

        /// 1) Удаляем страницу из PDF
        doc.removePage(at: idx)
        guard let newData = doc.dataRepresentation() else { return false }

        /// 2) Мгновенно обновляем UI (без ожидания рендера)
        DispatchQueue.main.async {
            if idx < self.pageImages.count {
                self.pageImages.remove(at: idx)
            }
            self.selectedIndex = nil
        }

        /// 3) Обновляем внутренние данные
        data = newData

        /// 4) Принудительно перерендерим превью (та же ширина)
        render(width: lastWidth, force: true)

        /// 5) Сообщаем наружу / Core Data при необходимости
        switch source {
        case .ephemeral(let onUpdate):
            /// временный документ — только пробрасываем новые данные наружу
            onUpdate?(newData)

        case .saved(let old):
            /// готовим обновлённую доменную модель
            var updated = old
            updated.data = newData
            if let pdf = PDFDocument(data: newData) {
                updated.thumbnail = PDFUtilities.thumbnail(from: pdf)?.pngData()
            }
            updated.timestamp = Date()

            do {
                /// Обновляем только если запись реально существует (иначе не создаём новую)
                _ = try core.fetchDocument(by: updated.id)
                try core.updateDocument(updated)
                DispatchQueue.main.async { self.source = .saved(model: updated) }
            } catch PDFStorageError.notFound {
                /// записи нет, тогда переключаемся на ephemeral и не лезем в базу
                DispatchQueue.main.async { self.source = .ephemeral(onUpdate: nil) }
            } catch {
                print("CoreData update error:", error)
            }
        }

        return true
    }
}
