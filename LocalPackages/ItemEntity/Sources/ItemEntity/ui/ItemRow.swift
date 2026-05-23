//
//  ItemRow.swift
//  ItemEntity
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

public struct ItemRow: View {
    public let item: Item

    public init(item: Item) {
        self.item = item
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                HStack(spacing: 6) {
                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .lineLimit(1)
                    }

                    Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))
                        .lineLimit(1)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 6)

            ItemPriorityBadge(priority: item.priority)
                .fixedSize()
        }
    }
}
