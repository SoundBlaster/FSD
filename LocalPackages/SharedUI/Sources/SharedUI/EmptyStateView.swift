//
//  EmptyStateView.swift
//  SharedUI
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

public struct EmptyStateView<Action: View>: View {
    public let title: String
    public let message: String
    public let systemImage: String
    private let action: Action

    public init(
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

    public init(
        title: String,
        message: String,
        systemImage: String
    ) where Action == EmptyView {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        action = EmptyView()
    }

    public var body: some View {
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
