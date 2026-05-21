//
//  EmptyStateView.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

struct EmptyStateView<Action: View>: View {
    let title: String
    let message: String
    let systemImage: String
    private let action: Action

    init(
        title: String,
        message: String,
        systemImage: String,
        @ViewBuilder action: () -> Action
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.action = action()
    }

    init(
        title: String,
        message: String,
        systemImage: String
    ) where Action == EmptyView {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        action = EmptyView()
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            action
        }
        .padding(24)
        .frame(maxWidth: 360)
    }
}
