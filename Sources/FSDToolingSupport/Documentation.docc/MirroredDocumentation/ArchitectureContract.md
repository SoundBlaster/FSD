# Architecture Contract

> Source: `ARCHITECTURE.md`

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
become explicit module exports. See [specs/fsd-with-spm.md](<doc:FSDWithSwiftPackageManager>).

## Legacy Adoption With Modules

For legacy applications, prefer adding new FSD code as a local Swift Package
instead of moving existing legacy files first. This creates a module island where
new code has compile-time dependency direction, while the old app can adopt it
screen by screen.

The starter package lives in [templates/fsd-ios-spm](https://github.com/SoundBlaster/FSD/tree/main/templates/fsd-ios-spm):

```bash
swift tools/fsd-template-create.swift \
  --template templates/fsd-ios-spm \
  --app-name LegacyFSD \
  --output ../LegacyFSDModules
```

The legacy app should import only the public product it composes, usually a
screen or flow target. Lower targets such as domain/core stay hidden behind
SwiftPM dependency direction and Swift access control.

## Enforcement

Use `make demo` as a quick local documentation/demo check and `make ci` as the
full pre-PR gate:

```bash
make demo
make ci
```

`make ci` runs the lint targets, architecture checks, build, and tests. `lint`
checks folder shape. `lint-architecture` additionally checks local Swift symbol
references for invalid layer direction and sibling-slice dependencies.

## Harmonize

`lint` is a gate: it should pass or fail. `harmonize` is an advisor: it explains
likely refactoring moves without changing files.

The intended split:

```text
lint       -> detect and block objective violations
harmonize  -> suggest coherent FSD refactoring plans
```

Run it locally:

```bash
make harmonize
```

Harmonize suggestions are intentionally not CI blockers for the app. CI only
checks a fixture with known architecture smells so the advisor itself does not
silently regress.

Each suggestion uses a stable advisory contract:

- `ruleId` names the advisory rule, for example
  `harmonize/shared-domain-language`;
- `confidence` explains how strong the heuristic signal is;
- `impact` identifies the architectural concern, such as naming, reuse, or
  layer responsibility;
- `evidence`, `recommendation`, and `nextSteps` explain why the suggestion was
  emitted and how to evaluate it.

This keeps `harmonize` useful for refactoring discussions without turning
heuristics into hard CI failures.