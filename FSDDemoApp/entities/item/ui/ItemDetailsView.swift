//
//  ItemDetailsView.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ItemDetailsView: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.semibold)

                ItemPriorityBadge(priority: item.priority)
            }

            if !item.notes.isEmpty {
                Text(item.notes)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Created") {
                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
            }

            LabeledContent("Updated") {
                Text(item.updatedAt, format: Date.FormatStyle(date: .numeric, time: .standard))
            }
        }
    }
}
