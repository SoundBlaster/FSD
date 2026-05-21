import Foundation

public struct Product: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var subtitle: String?

    public init(id: UUID = UUID(), title: String, subtitle: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}
