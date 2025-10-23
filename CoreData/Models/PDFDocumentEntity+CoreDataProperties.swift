//
//  PDFDocumentEntity+CoreDataProperties.swift
//  SwiftUIPDFProject
//
//  Created by Владислав Скриганюк on 21.10.2025.
//
//

public import Foundation
public import CoreData


public typealias PDFDocumentEntityCoreDataPropertiesSet = NSSet

extension PDFDocumentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PDFDocumentEntity> {
        return NSFetchRequest<PDFDocumentEntity>(entityName: "PDFDocumentEntity")
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var data: Data?
    @NSManaged public var fileType: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var thumbnail: Data?

}

extension PDFDocumentEntity : Identifiable {

}
