//
//  ItemPriority.swift
//  ItemEntity
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation

public enum ItemPriority: Int, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2

    public var id: Int {
        rawValue
    }

    public var title: String {
        switch self {
        case .low:
            "Low"
        case .medium:
            "Medium"
        case .high:
            "High"
        }
    }

    public var systemImage: String {
        switch self {
        case .low:
            "arrow.down.circle"
        case .medium:
            "minus.circle"
        case .high:
            "exclamationmark.circle"
        }
    }

    public var sortRank: Int {
        rawValue
    }
}
