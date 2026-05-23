//
//  Item.swift
//  ItemEntity
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation
import SwiftData

@Model
public final class Item {
    public var title: String = "Untitled"
    public var notes: String = ""
    public var timestamp: Date = Date()
    public var updatedAt: Date = Date()
    public var isCompleted: Bool = false
    public var priorityValue: Int = ItemPriority.medium.rawValue

    public var priority: ItemPriority {
        get {
            ItemPriority(rawValue: priorityValue) ?? .medium
        }
        set {
            priorityValue = newValue.rawValue
        }
    }

    public init(
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

    public func toggleCompletion(at date: Date = Date()) {
        isCompleted.toggle()
        updatedAt = date
    }

    public func changePriority(to priority: ItemPriority, at date: Date = Date()) {
        self.priority = priority
        updatedAt = date
    }

    public func update(
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
