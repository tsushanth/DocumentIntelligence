import Foundation

/// Represents a folder for organizing documents
public struct Folder: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var color: FolderColor
    public var icon: String
    public var createdAt: Date
    public var parentId: UUID?

    public init(
        id: UUID = UUID(),
        name: String,
        color: FolderColor = .blue,
        icon: String = "folder.fill",
        createdAt: Date = Date(),
        parentId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = createdAt
        self.parentId = parentId
    }
}

/// Available folder colors
public enum FolderColor: String, Codable, CaseIterable {
    case blue
    case green
    case orange
    case purple
    case red
    case yellow
    case gray
    case teal

    public var hexColor: String {
        switch self {
        case .blue: return "#007AFF"
        case .green: return "#34C759"
        case .orange: return "#FF9500"
        case .purple: return "#AF52DE"
        case .red: return "#FF3B30"
        case .yellow: return "#FFCC00"
        case .gray: return "#8E8E93"
        case .teal: return "#5AC8FA"
        }
    }
}
