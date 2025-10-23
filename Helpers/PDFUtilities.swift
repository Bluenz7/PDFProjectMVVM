
//
//  PDFUtilities.swift
//  PDFRedactor
//
//  Created by Владислав Скриганюк on 21.10.2025.
//


import UIKit
import PDFKit

struct PDFUtilities {
    
    // MARK: - Static Methods.
    
    static func imagesToPDFData(images: [UIImage], pageSize: CGSize = .zero) -> Data {
        let firstSize = images.first?.size ?? CGSize(width: 612, height: 792)
        let bounds = CGRect(origin: .zero, size: pageSize == .zero ? firstSize : pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        return renderer.pdfData { ctx in
            for img in images {
                ctx.beginPage()
                img.draw(in: bounds)
            }
        }
    }
    
    static func thumbnail(from pdf: PDFDocument?) -> UIImage? {
        guard let pdf = pdf, let page = pdf.page(at: 0) else { return nil }
        let box = page.bounds(for: .mediaBox)
        let size = CGSize(width: box.width * 0.25, height: box.height * 0.25)
        return page.thumbnail(of: size, for: .mediaBox)
    }
    
    static func rotate(page: PDFPage, by degrees: Int) {
        page.rotation = (page.rotation + degrees) % 360
    }
    
    static func removePage(at index: Int, from data: Data) -> Data? {
        guard let pdf = PDFDocument(data: data) else { return nil }
        pdf.removePage(at: index)
        return pdf.dataRepresentation()
    }
    
    static func extractPages(indices: [Int], from data: Data) -> Data? {
        guard let pdf = PDFDocument(data: data) else { return nil }
        let newPDF = PDFDocument()
        var idx = 0
        for i in indices.sorted() {
            if let p = pdf.page(at: i)?.copy() as? PDFPage {
                newPDF.insert(p, at: idx)
                idx += 1
            }
        }
        return newPDF.dataRepresentation()
    }
}
