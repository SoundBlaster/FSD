import SwiftUI

struct CreateSampleItemButton: View {
    let existingCount: Int
    let onCreate: (SampleItem) -> Void

    private let action = CreateSampleItemAction()

    var body: some View {
        Button {
            onCreate(action(existingCount: existingCount))
        } label: {
            Label("Add", systemImage: "plus")
        }
    }
}
