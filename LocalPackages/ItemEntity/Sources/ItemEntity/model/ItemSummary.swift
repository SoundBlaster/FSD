//
//  ItemSummary.swift
//  ItemEntity
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation

public struct ItemSummary {
    public let total: Int
    public let active: Int
    public let completed: Int
    public let highPriority: Int

    public var completionRatio: Double {
        guard total > 0 else {
            return 0
        }

        return Double(completed) / Double(total)
    }

    public init(items: [Item]) {
        total = items.count
        active = items.filter { !$0.isCompleted }.count
        completed = items.filter(\.isCompleted).count
        highPriority = items.filter { $0.priority == .high }.count
    }
}
