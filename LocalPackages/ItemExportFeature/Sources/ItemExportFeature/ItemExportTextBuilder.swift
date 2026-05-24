//
//  ItemExportTextBuilder.swift
//  ItemExportFeature
//
//  Created by Egor Merkushev on 5/24/26.
//

import Foundation

public struct ItemExportTextBuilder {
    private static let iso8601DateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private let formatDate: (Date) -> String

    public init(formatDate: @escaping (Date) -> String = Self.defaultDateFormatter) {
        self.formatDate = formatDate
    }

    public func makeText(for items: [ExportItem]) -> String {
        guard !items.isEmpty else {
            return "No items to export."
        }

        let lines = items.enumerated().flatMap { index, item in
            exportLines(for: item, index: index + 1)
        }

        return ([
            "Items export",
            "Total: \(items.count)",
            "",
        ] + lines).joined(separator: "\n")
    }

    private func exportLines(for item: ExportItem, index: Int) -> [String] {
        var lines = [
            "\(index). \(item.title)",
            "   Status: \(item.isCompleted ? "Done" : "Active")",
            "   Priority: \(item.priority)",
            "   Created: \(formatDate(item.createdAt))",
        ]

        let notes = item.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if !notes.isEmpty {
            lines.append("   Notes: \(notes)")
        }

        lines.append("")
        return lines
    }

    public static func defaultDateFormatter(_ date: Date) -> String {
        iso8601DateFormatter.string(from: date)
    }
}
