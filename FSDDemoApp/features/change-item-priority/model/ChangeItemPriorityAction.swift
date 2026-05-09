//
//  ChangeItemPriorityAction.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation

struct ChangeItemPriorityAction {
    func change(
        _ item: Item,
        to priority: ItemPriority,
        at date: Date = Date()
    ) {
        item.changePriority(to: priority, at: date)
    }
}
