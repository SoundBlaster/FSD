# FSD Import Rules

> Source: `docs/rules/fsd-imports.md`

In Swift single-module projects, dependencies often appear as type references
rather than explicit imports. The rule is still the same: dependencies point
downward.

```text
app -> pages -> widgets -> features -> entities -> shared
```

## Allowed

```swift
// pages can compose lower layers
ItemDashboardWidget(summary: ItemSummary(items: items))
ItemFilterPicker(selection: $selectedFilter)
EmptyStateView(title: "Select an item", message: "...", systemImage: "sidebar.right")
```

```swift
// features can use entities
ChangeItemPriorityAction().change(item, to: .high)
```

```swift
// entities can use shared/generic platform APIs
import Foundation
import SwiftUI
```

## Forbidden

```swift
// shared must not know product domain types
struct GenericTile {
    let item: Item
}
```

```swift
// features should not depend on sibling features
struct AddItemForm {
    let editor: EditItemForm
}
```

```swift
// entities should not depend on user actions
struct ItemRow {
    let action = ToggleItemCompletionAction()
}
```

## Same-Layer Isolation

Slices on `widgets`, `features`, and `entities` should not depend on sibling
slices directly. Compose sibling slices above them:

- compose feature + feature in `pages` or `widgets`;
- compose entity + entity in `widgets` or `pages`;
- move truly shared domain language into a lower shared abstraction only if it
  has no product-specific behavior.

## Tooling

`make lint-architecture` checks local Swift type references for:

- upward layer dependencies;
- sibling-slice dependencies in `widgets`, `features`, and `entities`.

The check is intentionally conservative. Duplicate local type names are skipped
to avoid false positives.