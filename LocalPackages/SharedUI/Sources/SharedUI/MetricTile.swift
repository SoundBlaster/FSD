//
//  MetricTile.swift
//  SharedUI
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftUI

public struct MetricTile: View {
    public let title: String
    public let value: String
    public let systemImage: String
    public let tint: Color

    public init(title: String, value: String, systemImage: String, tint: Color) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(tint)
        }
        .frame(minWidth: 96, alignment: .leading)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
