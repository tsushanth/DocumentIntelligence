import Foundation
import CoreData

/// Core Data entity representing a document
@objc(DocumentEntity)
public class DocumentEntity: NSManagedObject, Identifiable {

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var type: String
    @NSManaged public var fileURL: URL?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var ocrText: String?
    @NSManaged public var aiSummary: String?
    @NSManaged public var aiTitle: String?
    @NSManaged public var tags: [String]?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var pageCount: Int
    @NSManaged public var fileSize: Int64
    @NSManaged public var folder: FolderEntity?

    /// Fetch request for DocumentEntity entities
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DocumentEntity> {
        return NSFetchRequest<DocumentEntity>(entityName: "DocumentEntity")
    }

    /// Document type enum
    public var documentType: DocumentType {
        get { DocumentType(rawValue: type) ?? .other }
        set { type = newValue.rawValue }
    }

    /// Formatted file size
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    /// Formatted dates
    public var formattedCreatedDate: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    public var formattedUpdatedDate: String {
        updatedAt.formatted(date: .abbreviated, time: .shortened)
    }

    /// Display title (AI title if available, otherwise original title)
    public var displayTitle: String {
        aiTitle ?? title
    }
}

// MARK: - Core Data Entity Description

extension DocumentEntity {
    /// Creates the Core Data entity description programmatically
    static func createEntityDescription(in model: NSManagedObjectModel) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DocumentEntity"
        entity.managedObjectClassName = NSStringFromClass(DocumentEntity.self)

        // Attributes
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = false

        let typeAttribute = NSAttributeDescription()
        typeAttribute.name = "type"
        typeAttribute.attributeType = .stringAttributeType
        typeAttribute.isOptional = false

        let fileURLAttribute = NSAttributeDescription()
        fileURLAttribute.name = "fileURL"
        fileURLAttribute.attributeType = .URIAttributeType
        fileURLAttribute.isOptional = true

        let thumbnailDataAttribute = NSAttributeDescription()
        thumbnailDataAttribute.name = "thumbnailData"
        thumbnailDataAttribute.attributeType = .binaryDataAttributeType
        thumbnailDataAttribute.isOptional = true

        let ocrTextAttribute = NSAttributeDescription()
        ocrTextAttribute.name = "ocrText"
        ocrTextAttribute.attributeType = .stringAttributeType
        ocrTextAttribute.isOptional = true

        let aiSummaryAttribute = NSAttributeDescription()
        aiSummaryAttribute.name = "aiSummary"
        aiSummaryAttribute.attributeType = .stringAttributeType
        aiSummaryAttribute.isOptional = true

        let aiTitleAttribute = NSAttributeDescription()
        aiTitleAttribute.name = "aiTitle"
        aiTitleAttribute.attributeType = .stringAttributeType
        aiTitleAttribute.isOptional = true

        let tagsAttribute = NSAttributeDescription()
        tagsAttribute.name = "tags"
        tagsAttribute.attributeType = .transformableAttributeType
        tagsAttribute.valueTransformerName = "NSSecureUnarchiveFromData"
        tagsAttribute.isOptional = true

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = false

        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = false

        let pageCountAttribute = NSAttributeDescription()
        pageCountAttribute.name = "pageCount"
        pageCountAttribute.attributeType = .integer32AttributeType
        pageCountAttribute.defaultValue = 0

        let fileSizeAttribute = NSAttributeDescription()
        fileSizeAttribute.name = "fileSize"
        fileSizeAttribute.attributeType = .integer64AttributeType
        fileSizeAttribute.defaultValue = 0

        // Relationships
        let folderRelationship = NSRelationshipDescription()
        folderRelationship.name = "folder"
        folderRelationship.isOptional = true
        folderRelationship.minCount = 0
        folderRelationship.maxCount = 1
        folderRelationship.deleteRule = .nullifyDeleteRule

        entity.properties = [
            idAttribute,
            titleAttribute,
            typeAttribute,
            fileURLAttribute,
            thumbnailDataAttribute,
            ocrTextAttribute,
            aiSummaryAttribute,
            aiTitleAttribute,
            tagsAttribute,
            createdAtAttribute,
            updatedAtAttribute,
            pageCountAttribute,
            fileSizeAttribute,
            folderRelationship
        ]

        return entity
    }
}
