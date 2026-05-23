//
//  ItemFilter.swift
//  ItemEntity
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation

public enum ItemFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case completed
    case highPriority

    public var id: String {
        rawValue
    }

    public var title: String {
        switch self {
        case .all:
            "All"
        case .active:
            "Active"
        case .completed:
            "Done"
        case .highPriority:
            "High"
        }
    }

    public var systemImage: String {
        switch self {
        case .all:
            "tray.full"
        case .active:
            "circle"
        case .completed:
            "checkmark.circle"
        case .highPriority:
            "exclamationmark.circle"
        }
    }

    public func includes(_ item: Item) -> Bool {
        switch self {
        case .all:
            true
        case .active:
            !item.isCompleted
        case .completed:
            item.isCompleted
        case .highPriority:
            item.priority == .high
        }
    }
}
