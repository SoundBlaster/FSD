//
//  DeleteItemsAction.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation
import ItemEntity
import SwiftData

struct DeleteItemsAction {
    let modelContext: ModelContext

    func delete(_ items: [Item], at offsets: IndexSet) {
        let selectedItems = offsets.compactMap { index in
            items.indices.contains(index) ? items[index] : nil
        }

        delete(selectedItems)
    }

    func delete(_ items: [Item]) {
        for item in items {
            modelContext.delete(item)
        }
    }
}
