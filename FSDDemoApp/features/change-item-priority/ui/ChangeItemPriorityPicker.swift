//
//  ChangeItemPriorityPicker.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ChangeItemPriorityPicker: View {
    let item: Item

    private var priority: Binding<ItemPriority> {
        Binding(
            get: {
                item.priority
            },
            set: { newPriority in
                ChangeItemPriorityAction().change(item, to: newPriority)
            }
        )
    }

    var body: some View {
        Picker("Priority", selection: priority) {
            ForEach(ItemPriority.allCases) { priority in
                Label(priority.title, systemImage: priority.systemImage)
                    .tag(priority)
            }
        }
        .pickerStyle(.segmented)
    }
}
