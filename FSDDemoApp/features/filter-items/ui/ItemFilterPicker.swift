//
//  ItemFilterPicker.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ItemFilterPicker: View {
    @Binding var selection: ItemFilter

    var body: some View {
        Picker("Filter", selection: $selection) {
            ForEach(ItemFilter.allCases) { filter in
                Label(filter.title, systemImage: filter.systemImage)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
}
