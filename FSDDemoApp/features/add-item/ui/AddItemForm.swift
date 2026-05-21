//
//  AddItemForm.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftData
import SwiftUI

struct AddItemForm: View {
    @Environment(\.dismiss) private var dismiss
    private let modelContext: ModelContext

    @State private var draft = AddItemDraft()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var body: some View {
        NavigationStack {
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
            .navigationTitle("New Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: dismiss.callAsFunction)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: addItem)
                        .disabled(!draft.canSubmit)
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            _ = AddItemAction(modelContext: modelContext).add(draft: draft)
        }
        dismiss()
    }
}
