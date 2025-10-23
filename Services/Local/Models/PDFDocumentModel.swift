//
//  PDFDocumentModel.swift
//  SwiftUIPDFProject
//
//  Created by Владислав Скриганюк on 21.10.2025.
//

import Foundation
import Combine

public final class PDFDocumentModel: ObservableObject, Identifiable, Hashable {
    
    public let id: UUID

    @Published public var name: String
    @Published public var fileType: String
    @Published public var timestamp: Date

    /// Тяжёлые — без Published, чтобы не дёргать UI на каждое изменение байтов
    public var data: Data
    public var thumbnail: Data?

    public init(
        id: UUID = UUID(),
        name: String,
        fileType: String,
        data: Data,
        thumbnail: Data? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.fileType = fileType
        self.data = data
        self.thumbnail = thumbnail
        self.timestamp = timestamp
    }

    // MARK: - Hashable/Equatable.
    
    public static func == (lhs: PDFDocumentModel, rhs: PDFDocumentModel) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    public var fileExtension: String? { fileType.split(separator: "/").last.map(String.init) }
    public var createdAt: Date { timestamp }
}
