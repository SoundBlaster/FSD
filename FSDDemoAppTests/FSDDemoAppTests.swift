//
//  FSDDemoAppTests.swift
//  FSDDemoAppTests
//
//  Created by Egor Merkushev on 5/9/26.
//

import Foundation
import SwiftData
import Testing
@testable import FSDDemoApp

@MainActor
struct FSDDemoAppTests {
    @Test func addItemActionInsertsItem() throws {
        let modelContainer = try makeModelContainer()
        let modelContext = modelContainer.mainContext
        let timestamp = Date(timeIntervalSince1970: 1)

        AddItemAction(modelContext: modelContext).add(timestamp: timestamp)

        let items = try fetchItems(from: modelContext)
        #expect(items.map(\.timestamp) == [timestamp])
    }

    @Test func deleteItemsActionDeletesSelectedItems() throws {
        let modelContainer = try makeModelContainer()
        let modelContext = modelContainer.mainContext
        let first = AddItemAction(modelContext: modelContext)
            .add(timestamp: Date(timeIntervalSince1970: 1))
        let second = AddItemAction(modelContext: modelContext)
            .add(timestamp: Date(timeIntervalSince1970: 2))

        DeleteItemsAction(modelContext: modelContext).delete([first, second], at: IndexSet(integer: 0))

        let items = try fetchItems(from: modelContext)
        #expect(items.map(\.timestamp) == [second.timestamp])
    }

    private func makeModelContainer() throws -> ModelContainer {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }

    private func fetchItems(from modelContext: ModelContext) throws -> [Item] {
        var descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor)
    }
}
