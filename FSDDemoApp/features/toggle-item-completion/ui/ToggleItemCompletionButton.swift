//
//  ToggleItemCompletionButton.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ToggleItemCompletionButton: View {
    let item: Item
    private let showsTitle: Bool

    init(
        item: Item,
        showsTitle: Bool = false
    ) {
        self.item = item
        self.showsTitle = showsTitle
    }

    var body: some View {
        Button(action: toggleCompletion) {
            if showsTitle {
                Label(title, systemImage: systemImage)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 21))
                    .frame(width: 24, height: 24)
            }
        }
        .foregroundStyle(item.isCompleted ? .green : .secondary)
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var title: String {
        item.isCompleted ? "Mark Active" : "Mark Done"
    }

    private var systemImage: String {
        item.isCompleted ? "checkmark.circle.fill" : "circle"
    }

    private func toggleCompletion() {
        withAnimation {
            ToggleItemCompletionAction().toggle(item)
        }
    }
}
