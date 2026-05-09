//
//  AddItemButton.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftData
import SwiftUI

struct AddItemButton: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button(action: addItem) {
            Label("Add Item", systemImage: "plus")
        }
    }

    private func addItem() {
        withAnimation {
            _ = AddItemAction(modelContext: modelContext).add(timestamp: Date())
        }
    }
}
