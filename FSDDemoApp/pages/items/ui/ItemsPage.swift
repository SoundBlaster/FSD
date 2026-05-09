//
//  ItemsPage.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftData
import SwiftUI

struct ItemsPage: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @State private var selectedFilter: ItemFilter = .all

    private var sortedItems: [Item] {
        items.sorted { left, right in
            if left.isCompleted != right.isCompleted {
                return !left.isCompleted
            }

            if left.priority.sortRank != right.priority.sortRank {
                return left.priority.sortRank > right.priority.sortRank
            }

            return left.timestamp > right.timestamp
        }
    }

    private var visibleItems: [Item] {
        sortedItems.filter(selectedFilter.includes)
    }

    private var emptyTitle: String {
        switch selectedFilter {
        case .all:
            "No items"
        case .active:
            "No active items"
        case .completed:
            "No completed items"
        case .highPriority:
            "No high-priority items"
        }
    }

    private var emptyMessage: String {
        switch selectedFilter {
        case .all:
            "Create the first item to populate the page."
        case .active:
            "Everything visible here has already been completed."
        case .completed:
            "Mark items done and they will appear in this filter."
        case .highPriority:
            "Raise priority on important items to see them here."
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                ItemDashboardWidget(summary: ItemSummary(items: sortedItems))

                ItemFilterPicker(selection: $selectedFilter)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                ItemListWidget(
                    items: visibleItems,
                    emptyTitle: emptyTitle,
                    emptyMessage: emptyMessage,
                    onDeleteItems: deleteItems
                ) { item in
                    ItemDetailsPage(item: item)
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    AddItemButton()
                }

                ToolbarItem {
                    ClearCompletedButton(items: sortedItems)
                }
            }
        } detail: {
            EmptyStateView(
                title: "Select an item",
                message: "Choose an item from the list to review and edit it.",
                systemImage: "sidebar.right"
            )
        }
    }

    private func deleteItems(_ items: [Item]) {
        withAnimation {
            DeleteItemsAction(modelContext: modelContext).delete(items)
        }
    }
}

#Preview {
    ItemsPage()
        .modelContainer(for: Item.self, inMemory: true)
}
