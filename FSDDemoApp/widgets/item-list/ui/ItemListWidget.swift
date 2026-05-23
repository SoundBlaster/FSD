//
//  ItemListWidget.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import ItemEntity
import SwiftUI

struct ItemListWidget<Destination: View>: View {
    let items: [Item]
    let emptyTitle: String
    let emptyMessage: String
    let onDeleteItems: ([Item]) -> Void
    @ViewBuilder let destination: (Item) -> Destination

    var body: some View {
        if items.isEmpty {
            EmptyStateView(
                title: emptyTitle,
                message: emptyMessage,
                systemImage: "tray"
            ) {
                AddItemButton()
                    .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        destination(item)
                    } label: {
                        ItemListRow(item: item)
                    }
                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 12))
                }
                .onDelete(perform: deleteItems)
            }
            .environment(\.defaultMinListRowHeight, 56)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        let selectedItems = offsets.compactMap { index in
            items.indices.contains(index) ? items[index] : nil
        }

        onDeleteItems(selectedItems)
    }
}

private struct ItemListRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 10) {
            ToggleItemCompletionButton(item: item)

            ItemRow(item: item)
        }
        .frame(height: 52)
        .contentShape(Rectangle())
    }
}
