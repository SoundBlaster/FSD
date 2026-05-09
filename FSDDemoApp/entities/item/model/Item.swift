//
//  Item.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var title: String = "Untitled"
    var notes: String = ""
    var timestamp: Date = Date()
    var updatedAt: Date = Date()
    var isCompleted: Bool = false
    var priorityValue: Int = ItemPriority.medium.rawValue

    var priority: ItemPriority {
        get {
            ItemPriority(rawValue: priorityValue) ?? .medium
        }
        set {
            priorityValue = newValue.rawValue
        }
    }

    init(
        title: String = "Untitled",
        notes: String = "",
        timestamp: Date = Date(),
        updatedAt: Date = Date(),
        isCompleted: Bool = false,
        priority: ItemPriority = .medium
    ) {
        self.title = title
        self.notes = notes
        self.timestamp = timestamp
        self.updatedAt = updatedAt
        self.isCompleted = isCompleted
        priorityValue = priority.rawValue
    }

    func toggleCompletion(at date: Date = Date()) {
        isCompleted.toggle()
        updatedAt = date
    }

    func changePriority(to priority: ItemPriority, at date: Date = Date()) {
        self.priority = priority
        updatedAt = date
    }

    func update(
        title: String,
        notes: String,
        priority: ItemPriority,
        at date: Date = Date()
    ) {
        self.title = title
        self.notes = notes
        self.priority = priority
        updatedAt = date
    }
}
