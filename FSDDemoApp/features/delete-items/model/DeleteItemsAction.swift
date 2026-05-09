//
//  DeleteItemsAction.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation
import SwiftData

struct DeleteItemsAction {
    let modelContext: ModelContext

    func delete(_ items: [Item], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}
