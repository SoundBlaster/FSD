//
//  ItemDetailWidget.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ItemDetailWidget: View {
    let item: Item

    var body: some View {
        Form {
            Section("Item") {
                ItemDetailsView(item: item)
            }

            Section("Status") {
                ToggleItemCompletionButton(item: item, showsTitle: true)
            }

            Section("Priority") {
                ChangeItemPriorityPicker(item: item)
            }
        }
    }
}
