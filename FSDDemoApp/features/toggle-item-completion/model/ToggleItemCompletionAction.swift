//
//  ToggleItemCompletionAction.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation

struct ToggleItemCompletionAction {
    func toggle(_ item: Item, at date: Date = Date()) {
        item.toggleCompletion(at: date)
    }
}
