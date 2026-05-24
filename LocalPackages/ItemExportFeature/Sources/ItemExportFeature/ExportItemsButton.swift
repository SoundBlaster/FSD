//
//  ExportItemsButton.swift
//  ItemExportFeature
//
//  Created by Egor Merkushev on 5/24/26.
//

#if canImport(SwiftUI)
import SwiftUI

public struct ExportItemsButton: View {
    private let items: [ExportItem]
    private let title: String
    private let builder: ItemExportTextBuilder

    public init(
        items: [ExportItem],
        title: String = "Export",
        builder: ItemExportTextBuilder = ItemExportTextBuilder()
    ) {
        self.items = items
        self.title = title
        self.builder = builder
    }

    public var body: some View {
        ShareLink(
            item: builder.makeText(for: items),
            subject: Text("Items export")
        ) {
            Label(title, systemImage: "square.and.arrow.up")
        }
        .disabled(items.isEmpty)
    }
}
#endif
