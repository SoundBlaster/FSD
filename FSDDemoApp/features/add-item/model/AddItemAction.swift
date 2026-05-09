//
//  AddItemAction.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation
import SwiftData

struct AddItemAction {
    let modelContext: ModelContext

    @discardableResult
    func add(timestamp: Date) -> Item {
        let newItem = Item(timestamp: timestamp)
        modelContext.insert(newItem)
        return newItem
    }
}
