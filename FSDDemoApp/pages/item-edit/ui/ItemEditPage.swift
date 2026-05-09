//
//  ItemEditPage.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ItemEditPage: View {
    let item: Item

    var body: some View {
        EditItemForm(item: item, showsCancelButton: false)
    }
}

#Preview {
    NavigationStack {
        ItemEditPage(
            item: Item(
                title: "Buy milk",
                notes: "Two bottles",
                priority: .medium
            )
        )
    }
}
