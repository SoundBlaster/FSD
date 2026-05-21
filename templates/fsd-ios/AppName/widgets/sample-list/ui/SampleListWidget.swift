import SwiftUI

struct SampleListWidget: View {
    let items: [SampleItem]

    var body: some View {
        List(items) { item in
            SampleItemRow(item: item)
        }
    }
}
