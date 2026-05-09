//
//  EditItemButton.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct EditItemButton: View {
    let item: Item
    private let title: String
    private let systemImage: String

    @State private var isPresentingForm = false

    init(
        item: Item,
        title: String = "Edit",
        systemImage: String = "pencil"
    ) {
        self.item = item
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        Button(action: presentForm) {
            Label(title, systemImage: systemImage)
        }
        .sheet(isPresented: $isPresentingForm) {
            NavigationStack {
                EditItemForm(item: item)
            }
        }
    }

    private func presentForm() {
        isPresentingForm = true
    }
}
