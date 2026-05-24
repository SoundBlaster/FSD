# SwiftUI FSD Rules

> Source: `docs/rules/fsd-swiftui.md`

SwiftUI encourages small views, but FSD boundaries should still be business-first.
Do not create a new slice for every view.

## Pages

Pages own screen-level composition:

```swift
struct ItemsPage: View {
    var body: some View {
        ItemDashboardWidget(...)
        ItemFilterPicker(...)
        ItemListWidget(...)
    }
}
```

Navigation belongs in pages unless it is fully local to a reusable widget.

## Widgets

Widgets are reusable composition blocks:

```swift
struct ItemListWidget<Destination: View>: View {
    let items: [Item]
    let destination: (Item) -> Destination
}
```

Prefer injecting navigation destinations or callbacks instead of importing a
specific page into a widget.

## Features

Features represent user actions:

```swift
struct ToggleItemCompletionButton: View {
    let item: Item
}
```

The feature UI may call its own `model` action and may use `entities`.

## Entities

Entity UI should render domain objects:

```swift
struct ItemRow: View {
    let item: Item
}
```

Entity UI should not own workflows such as editing, deleting, or filtering.

## Shared

Shared UI must be generic:

```swift
EmptyStateView(title: ..., message: ..., systemImage: ...)
MetricTile(title: ..., value: ..., systemImage: ...)
```

If a shared view needs `Item`, it is not shared.