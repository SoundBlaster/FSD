//
//  ItemPriorityBadge.swift
//  ItemEntity
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

public struct ItemPriorityBadge: View {
    public let priority: ItemPriority

    public init(priority: ItemPriority) {
        self.priority = priority
    }

    private var tint: Color {
        switch priority {
        case .low:
            .secondary
        case .medium:
            .blue
        case .high:
            .red
        }
    }

    public var body: some View {
        Label(priority.title, systemImage: priority.systemImage)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(tint)
    }
}
