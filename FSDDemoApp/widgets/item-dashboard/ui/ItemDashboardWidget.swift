//
//  ItemDashboardWidget.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct ItemDashboardWidget: View {
    let summary: ItemSummary

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                MetricTile(
                    title: "Total",
                    value: "\(summary.total)",
                    systemImage: "tray.full",
                    tint: .primary
                )

                MetricTile(
                    title: "Active",
                    value: "\(summary.active)",
                    systemImage: "circle",
                    tint: .blue
                )

                MetricTile(
                    title: "Done",
                    value: "\(summary.completed)",
                    systemImage: "checkmark.circle",
                    tint: .green
                )

                MetricTile(
                    title: "High",
                    value: "\(summary.highPriority)",
                    systemImage: "exclamationmark.circle",
                    tint: .red
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}
