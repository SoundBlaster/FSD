//
//  ItemSummary.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation

struct ItemSummary {
    let total: Int
    let active: Int
    let completed: Int
    let highPriority: Int

    var completionRatio: Double {
        guard total > 0 else {
            return 0
        }

        return Double(completed) / Double(total)
    }

    init(items: [Item]) {
        total = items.count
        active = items.filter { !$0.isCompleted }.count
        completed = items.filter(\.isCompleted).count
        highPriority = items.filter { $0.priority == .high }.count
    }
}
