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
    private let title: String
    private let systemImage: String

    @State private var isPresentingForm = false

    init(
        title: String = "Add Item",
        systemImage: String = "plus"
    ) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        Button(action: presentForm) {
            Label(title, systemImage: systemImage)
        }
        .sheet(isPresented: $isPresentingForm) {
            AddItemForm(modelContext: modelContext)
        }
    }

    private func presentForm() {
        isPresentingForm = true
    }
}
