//
//  ItemPriorityBadge.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ItemPriorityBadge: View {
    let priority: ItemPriority

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

    var body: some View {
        Label(priority.title, systemImage: priority.systemImage)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(tint)
    }
}
