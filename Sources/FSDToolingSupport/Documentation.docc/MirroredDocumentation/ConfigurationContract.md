# Configuration Contract

> Source: `docs/configuration.md`

## TL;DR

Use `.fsd-ios.yml` to make FSD lint behavior explicit for a repository:

```yaml
version: 1
root: Sources/App
strict: true
architecture: true
ignoredPaths:
  - Generated
layers:
  app: app
  pages: pages
  widgets: widgets
  features: features
  entities: entities
  shared: shared
rules:
  rootStructure: true
  layerSegments: true
  sliceSegments: true
  dependencyDirection: true
  sameLayerSliceIsolation: true
```

Then run:

```bash
swift tools/fsd-ios.swift lint --config .fsd-ios.yml
```

When `.fsd-ios.yml` is present in the current directory, `fsd-ios lint`
discovers it automatically.

## Resolution Rules

`fsd-ios lint` resolves configuration in this order:

1. `--config <path>`, when provided;
2. `.fsd-ios.yml` in the caller's current directory;
3. `.fsd-ios.yaml` in the caller's current directory;
4. built-in defaults when no config file exists.

Command-line options override config values:

```bash
swift tools/fsd-ios.swift lint --config .fsd-ios.yml --root FSDDemoApp
swift tools/fsd-ios.swift lint --config .fsd-ios.yml --strict --architecture
swift tools/fsd-ios.swift lint --config .fsd-ios.yml --no-strict --no-architecture
```

Config `root` is resolved relative to the config file. Command-line `--root` is
resolved relative to the caller's current directory.

## Supported Keys

| Key | Type | Purpose |
|---|---|---|
| `version` | integer | Config schema version. Only `1` is supported. |
| `root` | string | Source root containing FSD layers. |
| `strict` | boolean | Treat warnings as errors. |
| `architecture` | boolean | Enable Swift symbol dependency checks. |
| `ignoredPaths` | list of strings | Paths under `root` excluded from lint traversal. |
| `layers` | mapping | Folder names for canonical FSD layers. |
| `rules` | mapping | Rule toggles for incremental adoption. |

`ignoredPaths` entries are relative to `root`:

```yaml
ignoredPaths:
  - Generated
  - shared/assets/vendor
```

## Layers

Layer keys are canonical FSD responsibilities. Values are folder names in the
project:

```yaml
layers:
  app: app
  pages: pages
  widgets: widgets
  features: features
  entities: entities
  shared: shared
```

The default names are recommended. Custom values exist mostly for legacy
adoption, where a team may need to introduce FSD rules before all folders can be
renamed.

## Rules

All rule toggles default to `true`:

```yaml
rules:
  rootStructure: true
  layerSegments: true
  sliceSegments: true
  dependencyDirection: true
  sameLayerSliceIsolation: true
```

Use toggles to adopt the linter incrementally in legacy code. Prefer enabling
all rules for new code and generated templates.

## YAML Subset

The current parser intentionally supports a small YAML subset:

- top-level scalar values;
- one-level mappings for `layers` and `rules`;
- block lists or inline lists for `ignoredPaths`;
- `true` and `false` booleans;
- comments starting with `#`.

It does not aim to be a general YAML parser. Keeping the format small makes the
Swift script portable and avoids extra runtime dependencies.