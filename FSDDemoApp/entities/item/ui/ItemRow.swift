//
//  ItemRow.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ItemRow: View {
    let item: Item

    var body: some View {
        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
    }
}
