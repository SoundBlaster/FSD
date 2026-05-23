//
//  ItemPriority.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation

enum ItemPriority: Int, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int {
        rawValue
    }

    var title: String {
        switch self {
        case .low:
            "Low"
        case .medium:
            "Medium"
        case .high:
            "High"
        }
    }

    var systemImage: String {
        switch self {
        case .low:
            "arrow.down.circle"
        case .medium:
            "minus.circle"
        case .high:
            "exclamationmark.circle"
        }
    }

    var sortRank: Int {
        rawValue
    }
}
