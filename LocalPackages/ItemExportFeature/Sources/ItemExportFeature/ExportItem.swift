//
//  ExportItem.swift
//  ItemExportFeature
//
//  Created by Egor Merkushev on 5/24/26.
//

import Foundation

public struct ExportItem: Equatable, Identifiable {
    public let id: String
    public let title: String
    public let notes: String
    public let priority: String
    public let isCompleted: Bool
    public let createdAt: Date

    public init(
        id: String,
        title: String,
        notes: String,
        priority: String,
        isCompleted: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.priority = priority
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
