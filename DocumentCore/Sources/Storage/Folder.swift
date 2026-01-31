import Foundation
import CoreData

/// Core Data entity representing a folder
@objc(Folder)
public class Folder: NSManagedObject, Identifiable {

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var color: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var documents: Set<Document>?

    /// Fetch request for Folder entities
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }

    /// Number of documents in folder
    public var documentCount: Int {
        documents?.count ?? 0
    }

    /// Formatted creation date
    public var formattedCreatedDate: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    /// Sorted documents by updated date
    public var sortedDocuments: [Document] {
        guard let documents = documents else { return [] }
        return documents.sorted { $0.updatedAt > $1.updatedAt }
    }
}

// MARK: - Core Data Entity Description

extension Folder {
    /// Creates the Core Data entity description programmatically
    static func createEntityDescription(in model: NSManagedObjectModel) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Folder"
        entity.managedObjectClassName = NSStringFromClass(Folder.self)

        // Attributes
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = false

        let colorAttribute = NSAttributeDescription()
        colorAttribute.name = "color"
        colorAttribute.attributeType = .stringAttributeType
        colorAttribute.isOptional = true

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = false

        // Relationships
        let documentsRelationship = NSRelationshipDescription()
        documentsRelationship.name = "documents"
        documentsRelationship.isOptional = true
        documentsRelationship.minCount = 0
        documentsRelationship.maxCount = 0  // 0 means to-many
        documentsRelationship.deleteRule = .cascadeDeleteRule

        entity.properties = [
            idAttribute,
            nameAttribute,
            colorAttribute,
            createdAtAttribute,
            documentsRelationship
        ]

        return entity
    }
}

// MARK: - Convenience Methods

extension Folder {
    /// Add a document to this folder
    public func addDocument(_ document: Document) {
        var docs = documents ?? Set<Document>()
        docs.insert(document)
        documents = docs
        document.folder = self
    }

    /// Remove a document from this folder
    public func removeDocument(_ document: Document) {
        var docs = documents ?? Set<Document>()
        docs.remove(document)
        documents = docs
        document.folder = nil
    }
}
