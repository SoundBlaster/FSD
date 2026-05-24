//
//  ItemExportTextBuilderTests.swift
//  ItemExportFeatureTests
//
//  Created by Egor Merkushev on 5/24/26.
//

import Foundation
import ItemExportFeature
import XCTest

final class ItemExportTextBuilderTests: XCTestCase {
    func testMakeTextIncludesItemFields() {
        let builder = ItemExportTextBuilder { _ in "2026-05-24 00:00" }
        let items = [
            ExportItem(
                id: "1",
                title: "Ship package",
                notes: "Release through CI",
                priority: "High",
                isCompleted: false,
                createdAt: Date(timeIntervalSince1970: 0)
            ),
            ExportItem(
                id: "2",
                title: "Write docs",
                notes: "",
                priority: "Medium",
                isCompleted: true,
                createdAt: Date(timeIntervalSince1970: 1)
            ),
        ]

        let text = builder.makeText(for: items)

        XCTAssertTrue(text.contains("Items export"))
        XCTAssertTrue(text.contains("Total: 2"))
        XCTAssertTrue(text.contains("1. Ship package"))
        XCTAssertTrue(text.contains("Status: Active"))
        XCTAssertTrue(text.contains("Priority: High"))
        XCTAssertTrue(text.contains("Notes: Release through CI"))
        XCTAssertTrue(text.contains("2. Write docs"))
        XCTAssertTrue(text.contains("Status: Done"))
    }

    func testMakeTextHandlesEmptyInput() {
        let text = ItemExportTextBuilder().makeText(for: [])

        XCTAssertEqual(text, "No items to export.")
    }
}
