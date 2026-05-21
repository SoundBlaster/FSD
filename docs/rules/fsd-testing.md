# FSD Testing

Tests should follow ownership.

## Features

Test user actions in `features/*/model`:

```swift
@Test func addItemActionInsertsItem() throws {
    AddItemAction(modelContext: modelContext).add(draft: draft)
}
```

Feature tests should prove the business action, not SwiftUI rendering details.

## Entities

Test domain calculations in `entities/*/model`:

```swift
@Test func itemSummaryCountsItemsByState() throws {
    let summary = ItemSummary(items: items)
}
```

## Pages And Widgets

Use integration or UI tests when behavior crosses multiple slices:

- navigation;
- filtering plus list rendering;
- dashboard summaries;
- edit flows.

## Tooling

When changing `tools/fsd-lint.swift`, add targeted validation that proves both:

- valid code still passes;
- invalid architecture is detected.

For now, targeted fixtures can be shell-created temporary Swift files. If the
linter grows further, promote those fixtures into permanent test data.
