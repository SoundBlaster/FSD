# Architecture

This repository is an FSD iOS reference template. It contains a small SwiftUI
application, written rules, local tooling, and CI checks that other projects can
copy or adapt.

## Architectural Goal

The codebase should make business boundaries visible:

- screens live in `pages`;
- reusable user actions live in `features`;
- domain concepts live in `entities`;
- large reusable compositions live in `widgets`;
- app startup and global providers live in `app`;
- generic infrastructure lives in `shared`.

The template favors boring, explicit structure over clever abstractions.

## Layer Contract

| Layer | Responsibility |
|---|---|
| `app` | App entrypoint, providers, global composition, app-wide setup |
| `pages` | Screen-level composition and route-owned state |
| `widgets` | Large reusable UI composition blocks |
| `features` | User actions with business value |
| `entities` | Domain model, domain state, entity-specific UI |
| `shared` | Generic UI and infrastructure without product business logic |

Allowed dependency direction:

```text
app -> pages -> widgets -> features -> entities -> shared
```

Lower layers must not depend on higher layers. Slices on the same layer should
not depend on each other directly; compose them above, usually in `pages` or
`widgets`.

## Pages First

Start route-specific behavior in `pages`. Extract only when there is a concrete
reason:

- reusable screen composition -> `widgets`;
- reusable user action -> `features`;
- reusable domain concept -> `entities`;
- generic infrastructure -> `shared`.

Premature extraction is an architecture smell in this template.

## Swift Module Reality

This demo is one Swift module, so Swift does not enforce FSD boundaries through
imports. Boundaries are enforced by:

- folder structure;
- naming conventions;
- review checklist;
- `tools/fsd-lint.swift`;
- CI.

The architecture linter uses local Swift type references as a practical signal
for layer and slice dependencies.

## Public API Policy

For this single-module demo, public API means "intended slice boundary", not
Swift `public` access control. Keep cross-slice usage narrow:

- expose small, stable views/actions/models;
- avoid reaching into another slice's implementation details;
- prefer dependency injection through values, closures, or bindings;
- move shared domain language into `entities`;
- keep generic infrastructure free from domain names.

If the project moves to Swift Package Manager boundaries, public API should
become explicit module exports. See [specs/fsd-with-spm.md](specs/fsd-with-spm.md).

## Enforcement

Use these commands before opening a PR:

```bash
make lint
make lint-strict
make lint-architecture
make ci
```

`lint` checks folder shape. `lint-architecture` additionally checks local Swift
symbol references for invalid layer direction and sibling-slice dependencies.

## Harmonize

`lint` is a gate: it should pass or fail. `harmonize` is planned as an advisor:
it should explain likely refactoring moves without changing files by default.

The intended split:

```text
lint       -> detect and block objective violations
harmonize  -> suggest coherent FSD refactoring plans
```
