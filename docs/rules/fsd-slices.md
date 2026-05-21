# FSD Slices

A slice is a business boundary inside a layer.

```text
Layer -> Slice -> Segment
```

Example:

```text
features/add-item/
  model/
  ui/
```

## Naming

Use business language:

```text
features/add-item
features/edit-item
entities/item
widgets/item-list
pages/item-details
```

Avoid vague technical names:

```text
features/form
widgets/components
entities/models
shared/helpers
```

## Segments

Allowed common segments:

```text
ui/
model/
api/
lib/
config/
testing/
assets/
```

Use a segment only when it describes responsibility. Do not create empty segment
folders just to satisfy a pattern.

## Extraction Rules

Keep code in `pages` when it is used by only one screen. Extract when one of
these is true:

- it is reused by multiple screens;
- it represents a user action with business value;
- it represents a domain concept;
- it is a large composition block with a stable boundary.

## Review Questions

- Can the slice be named in business language?
- Would another screen reasonably reuse it?
- Does it introduce a dependency upward?
- Could this stay in `pages` until reuse appears?
