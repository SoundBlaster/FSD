import SwiftUI

struct HomePage: View {
    @State private var items: [SampleItem]

    init(initialSampleItems: [SampleItem]) {
        _items = State(initialValue: initialSampleItems)
    }

    var body: some View {
        NavigationStack {
            SampleListWidget(items: items)
                .overlay {
                    if items.isEmpty {
                        EmptyStateView(title: "No items", systemImage: "tray")
                    }
                }
                .navigationTitle("FSD iOS")
                .toolbar {
                    CreateSampleItemButton(existingCount: items.count) { item in
                        items.append(item)
                    }
                }
        }
    }
}
