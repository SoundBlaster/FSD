//
//  EditItemForm.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct EditItemForm: View {
    @Environment(\.dismiss) private var dismiss
    private let item: Item
    private let showsCancelButton: Bool

    @State private var draft: EditItemDraft

    init(
        item: Item,
        showsCancelButton: Bool = true
    ) {
        self.item = item
        self.showsCancelButton = showsCancelButton
        _draft = State(initialValue: EditItemDraft(item: item))
    }

    var body: some View {
        Form {
            Section("Item") {
                TextField("Title", text: $draft.title)

                TextField("Notes", text: $draft.notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section("Priority") {
                Picker("Priority", selection: $draft.priority) {
                    ForEach(ItemPriority.allCases) { priority in
                        Label(priority.title, systemImage: priority.systemImage)
                            .tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("Edit Item")
        .toolbar {
            if showsCancelButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: dismiss.callAsFunction)
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!draft.canSubmit)
            }
        }
    }

    private func save() {
        withAnimation {
            EditItemAction().edit(item, draft: draft)
        }
        dismiss()
    }
}
