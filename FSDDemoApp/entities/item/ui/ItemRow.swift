//
//  ItemRow.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .lineLimit(1)
                    }

                    Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            ItemPriorityBadge(priority: item.priority)
                .fixedSize()
        }
    }
}
