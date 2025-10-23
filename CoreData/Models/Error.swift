//
//  Error.swift
//  SwiftUIPDFProject
//
//  Created by Владислав Скриганюк on 21.10.2025.
//

import Foundation

// MARK: - Error.

public enum PDFStorageError: Error {
    case modelNotFound
    case notFound
    case coreData(Error)
}
