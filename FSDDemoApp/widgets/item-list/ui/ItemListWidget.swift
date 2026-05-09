//
//  ItemListWidget.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ItemListWidget<Destination: View>: View {
    let items: [Item]
    let emptyTitle: String
    let emptyMessage: String
    let onDeleteItems: ([Item]) -> Void
    @ViewBuilder let destination: (Item) -> Destination

    var body: some View {
        ZStack {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        destination(item)
                    } label: {
                        HStack(spacing: 10) {
                            ToggleItemCompletionButton(item: item)

                            ItemRow(item: item)
                        }
                        .frame(height: 52)
                        .contentShape(Rectangle())
                    }
                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 12))
                }
                .onDelete(perform: deleteItems)
            }
            .environment(\.defaultMinListRowHeight, 56)
            .opacity(items.isEmpty ? 0 : 1)

            if items.isEmpty {
                EmptyStateView(
                    title: emptyTitle,
                    message: emptyMessage,
                    systemImage: "tray"
                ) {
                    AddItemButton()
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        let selectedItems = offsets.map { items[$0] }
        onDeleteItems(selectedItems)
    }
}
