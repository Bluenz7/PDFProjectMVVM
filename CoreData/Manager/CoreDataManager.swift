//
//  CoreDataManager.swift
//  SwiftUIPDFProject
//
//  Created by Владислав Скриганюк on 21.10.2025.
//
import CoreData
import Foundation

// MARK: - CoreDataManager.

public final class CoreDataManager {

    // MARK: Singleton.
    
    public static let shared = CoreDataManager()

    // MARK: Private Properties.
    
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    // MARK: - Init.
    
    private init() {
        /// 1. Ищем CoreData модель через .momd или .mom
        guard let modelURL = Bundle.main.urls(forResourcesWithExtension: "momd", subdirectory: nil)?.first
                ?? Bundle.main.urls(forResourcesWithExtension: "mom", subdirectory: nil)?.first,
              let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            fatalError("❌ Core Data модель не найдена в бандле")
        }

        /// 2. Создаём контейнер
        let modelName = modelURL.deletingPathExtension().lastPathComponent
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)

        /// 3. Загружаем persistent store
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ Ошибка загрузки хранилища: \(error)")
            }
        }

        /// 4. Настраиваем контекст
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        self.container = container
        self.context = container.viewContext
    }

    // MARK: - CRUD.

    /// Сохранение нового документа
    public func saveDocument(_ model: PDFDocumentModel) throws {
        try context.performAndWait {
            let e = PDFDocumentEntity(context: context)
            e.update(from: model)
            try context.save()
        }
    }

    /// Обновление существующего документа
    public func updateDocument(_ model: PDFDocumentModel) throws {
        try context.performAndWait {
            let req: NSFetchRequest<PDFDocumentEntity> = PDFDocumentEntity.fetchRequest()
            req.fetchLimit = 1
            req.predicate = NSPredicate(format: "id == %@", model.id as CVarArg)

            guard let e = try context.fetch(req).first else {
                throw PDFStorageError.notFound
            }

            e.update(from: model)
            try context.save()
        }
    }

    /// Получение всех документов
    public func fetchAllDocuments() throws -> [PDFDocumentModel] {
        try context.performAndWait {
            let req: NSFetchRequest<PDFDocumentEntity> = PDFDocumentEntity.fetchRequest()
            let entities = try context.fetch(req)
            return entities.compactMap { try? $0.toModel() }
        }
    }

    /// Получение документа по ID
    public func fetchDocument(by id: UUID) throws -> PDFDocumentModel {
        try context.performAndWait {
            let req: NSFetchRequest<PDFDocumentEntity> = PDFDocumentEntity.fetchRequest()
            req.fetchLimit = 1
            req.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            guard let e = try context.fetch(req).first else {
                throw PDFStorageError.notFound
            }

            return try e.toModel()
        }
    }

    /// Удаление документа по ID
    public func deleteDocument(by id: UUID) throws {
        try context.performAndWait {
            let req: NSFetchRequest<PDFDocumentEntity> = PDFDocumentEntity.fetchRequest()
            req.fetchLimit = 1
            req.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            guard let e = try context.fetch(req).first else {
                throw PDFStorageError.notFound
            }

            context.delete(e)
            try context.save()
        }
    }

    /// Очистка всей таблицы PDFDocumentEntity
    public func deleteAllDocuments() throws {
        try context.performAndWait {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PDFDocumentEntity")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try context.execute(deleteRequest)
            try context.save()
        }
    }
}

// MARK: - Mapping between Entity and Model.

private extension PDFDocumentEntity {

    func update(from m: PDFDocumentModel) {
        id = m.id
        name = m.name
        fileType = m.fileType
        data = m.data
        thumbnail = m.thumbnail
        timestamp = m.timestamp
    }

    func toModel() throws -> PDFDocumentModel {
        guard let name,
              let fileType,
              let data,
              let timestamp
        else {
            throw PDFStorageError.coreData(NSError(domain: "MappingError", code: -1))
        }

        return PDFDocumentModel(
            id: id ?? UUID(),
            name: name,
            fileType: fileType,
            data: data,
            thumbnail: thumbnail,
            timestamp: timestamp
        )
    }
}
