import Foundation

struct CreateSampleItemAction {
    func callAsFunction(existingCount: Int) -> SampleItem {
        SampleItem(
            title: "Sample item \(existingCount + 1)",
            subtitle: "Created by a feature action"
        )
    }
}
