//
//  EditItemAction.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation

struct EditItemDraft {
    var title: String
    var notes: String
    var priority: ItemPriority

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedTitle.isEmpty
    }

    init(item: Item) {
        title = item.title
        notes = item.notes
        priority = item.priority
    }
}

struct EditItemAction {
    func edit(
        _ item: Item,
        draft: EditItemDraft,
        at date: Date = Date()
    ) {
        item.update(
            title: draft.trimmedTitle,
            notes: draft.trimmedNotes,
            priority: draft.priority,
            at: date
        )
    }
}
