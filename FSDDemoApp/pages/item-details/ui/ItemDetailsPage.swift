//
//  ItemDetailsPage.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ItemDetailsPage: View {
    let item: Item

    var body: some View {
        ItemDetailWidget(item: item)
            .navigationTitle(item.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        ItemEditPage(item: item)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        ItemDetailsPage(
            item: Item(
                title: "Buy milk",
                notes: "Two bottles",
                priority: .medium
            )
        )
    }
}
