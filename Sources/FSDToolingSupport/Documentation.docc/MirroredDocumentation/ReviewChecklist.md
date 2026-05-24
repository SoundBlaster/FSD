# Review Checklist

> Source: `docs/checklist.md`

Use this checklist before opening a PR.

## Placement

- Start route-specific UI and logic in `pages`.
- Extract to `widgets` only for large reusable composition blocks.
- Extract to `features` only for reusable user actions with business value.
- Extract to `entities` only for reusable domain concepts.
- Put code in `shared` only when it has no product/domain meaning.

## Dependencies

- `app` may compose all lower layers.
- `pages` may compose `widgets`, `features`, `entities`, and `shared`.
- `widgets` may compose `features`, `entities`, and `shared`.
- `features` may use `entities` and `shared`.
- `entities` may use `shared`.
- `shared` must not depend on product layers.
- Sibling slices on `widgets`, `features`, and `entities` must not depend on each other directly.

## SwiftUI

- Keep screen navigation in `pages`.
- Keep reusable controls near the behavior they trigger.
- Pass dependencies through values, bindings, environment, or closures.
- Avoid putting domain-specific SwiftUI views in `shared`.

## Testing

- Test pure user actions in `features/*/model`.
- Test domain calculations in `entities/*/model`.
- Test cross-slice behavior at the page or widget boundary.
- Add targeted linter fixtures when changing architecture tooling.

## Verification

```bash
make demo
make ci
```