# FSD Layers

FSD layers describe responsibility, not technical file type.

## app

Use `app` for application startup and global wiring:

```text
app/
  entrypoint/
  providers/
```

`app` may depend on every lower layer because it composes the application.

## pages

Use `pages` for screens and route-level composition:

```text
pages/items/ui/ItemsPage.swift
pages/item-details/ui/ItemDetailsPage.swift
```

Start new route-specific behavior here. Extract later only when reuse or a clear
business boundary appears.

## widgets

Use `widgets` for large reusable UI blocks that compose features and entities:

```text
widgets/item-list/ui/ItemListWidget.swift
widgets/item-dashboard/ui/ItemDashboardWidget.swift
```

Widgets can contain local composition logic. They should not be a dumping ground
for every reusable view.

## features

Use `features` for user actions with business value:

```text
features/add-item/
features/edit-item/
features/toggle-item-completion/
```

Feature names should usually be verbs or verb phrases.

## entities

Use `entities` for domain concepts:

```text
entities/item/model/Item.swift
entities/item/ui/ItemRow.swift
```

Entity UI should represent the entity, not perform unrelated user workflows.

## shared

Use `shared` for generic infrastructure and UI:

```text
shared/ui/EmptyStateView.swift
shared/ui/MetricTile.swift
```

`shared` must not know about `Item`, `Order`, `User`, or other product concepts.
