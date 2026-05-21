//
//  AddItemAction.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation
import SwiftData

struct AddItemDraft {
    var title = ""
    var notes = ""
    var priority: ItemPriority = .medium

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedTitle.isEmpty
    }
}

struct AddItemAction {
    let modelContext: ModelContext

    @discardableResult
    func add(
        draft: AddItemDraft,
        timestamp: Date = Date()
    ) -> Item {
        let newItem = Item(
            title: draft.trimmedTitle,
            notes: draft.trimmedNotes,
            timestamp: timestamp,
            updatedAt: timestamp,
            priority: draft.priority
        )
        modelContext.insert(newItem)
        return newItem
    }
}
