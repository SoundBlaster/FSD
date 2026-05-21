import Foundation

struct SampleItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var subtitle: String?

    init(id: UUID = UUID(), title: String, subtitle: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}
