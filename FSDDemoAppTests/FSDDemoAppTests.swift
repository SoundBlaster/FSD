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
        let draft = AddItemDraft(
            title: "  Ship demo  ",
            notes: "  Add meaningful FSD slices  ",
            priority: .high
        )

        AddItemAction(modelContext: modelContext).add(draft: draft, timestamp: timestamp)

        let items = try fetchItems(from: modelContext)
        #expect(items.map(\.timestamp) == [timestamp])
        #expect(items.map(\.title) == ["Ship demo"])
        #expect(items.map(\.notes) == ["Add meaningful FSD slices"])
        #expect(items.map(\.priority) == [.high])
    }

    @Test func deleteItemsActionDeletesSelectedItems() throws {
        let modelContainer = try makeModelContainer()
        let modelContext = modelContainer.mainContext
        let first = makeItem(
            modelContext: modelContext,
            title: "First",
            timestamp: Date(timeIntervalSince1970: 1)
        )
        let second = makeItem(
            modelContext: modelContext,
            title: "Second",
            timestamp: Date(timeIntervalSince1970: 2)
        )

        DeleteItemsAction(modelContext: modelContext).delete([first, second], at: IndexSet(integer: 0))

        let items = try fetchItems(from: modelContext)
        #expect(items.map(\.timestamp) == [second.timestamp])
    }

    @Test func toggleItemCompletionActionUpdatesItem() throws {
        let modelContainer = try makeModelContainer()
        let modelContext = modelContainer.mainContext
        let item = makeItem(modelContext: modelContext, title: "Toggle")
        let updateDate = Date(timeIntervalSince1970: 10)

        ToggleItemCompletionAction().toggle(item, at: updateDate)

        #expect(item.isCompleted)
        #expect(item.updatedAt == updateDate)
    }

    @Test func changeItemPriorityActionUpdatesItem() throws {
        let modelContainer = try makeModelContainer()
        let modelContext = modelContainer.mainContext
        let item = makeItem(modelContext: modelContext, title: "Priority", priority: .low)
        let updateDate = Date(timeIntervalSince1970: 12)

        ChangeItemPriorityAction().change(item, to: .high, at: updateDate)

        #expect(item.priority == .high)
        #expect(item.updatedAt == updateDate)
    }

    @Test func editItemActionUpdatesEditableFields() throws {
        let modelContainer = try makeModelContainer()
        let modelContext = modelContainer.mainContext
        let item = makeItem(
            modelContext: modelContext,
            title: "Draft",
            notes: "Before",
            priority: .low
        )
        let updateDate = Date(timeIntervalSince1970: 20)
        var draft = EditItemDraft(item: item)
        draft.title = "  Edited title  "
        draft.notes = "  Edited notes  "
        draft.priority = .high

        EditItemAction().edit(item, draft: draft, at: updateDate)

        #expect(item.title == "Edited title")
        #expect(item.notes == "Edited notes")
        #expect(item.priority == .high)
        #expect(item.updatedAt == updateDate)
    }

    @Test func itemFilterMatchesExpectedItems() throws {
        let modelContainer = try makeModelContainer()
        let modelContext = modelContainer.mainContext
        let active = makeItem(modelContext: modelContext, title: "Active")
        let done = makeItem(modelContext: modelContext, title: "Done", isCompleted: true)
        let urgent = makeItem(modelContext: modelContext, title: "Urgent", priority: .high)
        let items = [active, done, urgent]

        #expect(items.filter(ItemFilter.all.includes).map(\.title) == ["Active", "Done", "Urgent"])
        #expect(items.filter(ItemFilter.active.includes).map(\.title) == ["Active", "Urgent"])
        #expect(items.filter(ItemFilter.completed.includes).map(\.title) == ["Done"])
        #expect(items.filter(ItemFilter.highPriority.includes).map(\.title) == ["Urgent"])
    }

    @Test func itemSummaryCountsItemsByState() throws {
        let modelContainer = try makeModelContainer()
        let modelContext = modelContainer.mainContext
        let items = [
            makeItem(modelContext: modelContext, title: "Active"),
            makeItem(modelContext: modelContext, title: "Done", isCompleted: true),
            makeItem(modelContext: modelContext, title: "Urgent", priority: .high),
        ]

        let summary = ItemSummary(items: items)

        #expect(summary.total == 3)
        #expect(summary.active == 2)
        #expect(summary.completed == 1)
        #expect(summary.highPriority == 1)
        #expect(summary.completionRatio == 1.0 / 3.0)
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

    @discardableResult
    private func makeItem(
        modelContext: ModelContext,
        title: String,
        notes: String = "",
        timestamp: Date = Date(timeIntervalSince1970: 1),
        isCompleted: Bool = false,
        priority: ItemPriority = .medium
    ) -> Item {
        AddItemAction(modelContext: modelContext).add(
            draft: AddItemDraft(
                title: title,
                notes: notes,
                priority: priority
            ),
            timestamp: timestamp
        ).then {
            $0.isCompleted = isCompleted
        }
    }
}

private extension Item {
    func then(_ update: (Item) -> Void) -> Item {
        update(self)
        return self
    }
}
