# FSD iOS Checklist

Use this checklist before opening a PR.

## Placement

- Start route-specific code in `pages`.
- Move reusable user actions to `features`.
- Move reusable business concepts to `entities`.
- Move reusable composition blocks to `widgets`.
- Keep generic infrastructure in `shared`.
- Keep app startup and global providers in `app`.

## Dependencies

- Higher layers may depend on lower layers.
- Lower layers must not depend on higher layers.
- Slices on the same layer should not depend on each other directly.
- Compose sibling slices above them, usually in `pages` or `widgets`.

## SwiftUI

- Keep page views focused on screen composition.
- Put reusable controls for user actions in `features/*/ui`.
- Put domain rendering in `entities/*/ui`.
- Keep generic visual primitives in `shared/ui`.

## Validation

```bash
make demo
make ci
```
