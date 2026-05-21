//
//  ClearCompletedButton.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftData
import SwiftUI

struct ClearCompletedButton: View {
    @Environment(\.modelContext) private var modelContext
    let items: [Item]

    private var completedItems: [Item] {
        items.filter(\.isCompleted)
    }

    var body: some View {
        Button(role: .destructive, action: clearCompleted) {
            Label("Clear Done", systemImage: "trash")
        }
        .disabled(completedItems.isEmpty)
    }

    private func clearCompleted() {
        withAnimation {
            DeleteItemsAction(modelContext: modelContext).delete(completedItems)
        }
    }
}
