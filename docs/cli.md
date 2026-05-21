# FSD iOS CLI

## TL;DR

`tools/fsd-ios.swift` is the unified local CLI for this repository. It wraps the
existing Swift tools, so the linter, advisor, template generator, and validator
keep one stable entry point:

```bash
swift tools/fsd-ios.swift --help
swift tools/fsd-ios.swift doctor
swift tools/fsd-ios.swift lint --root FSDDemoApp --strict --architecture
swift tools/fsd-ios.swift create spm --name LegacyFSD --output ../LegacyFSDModules
```

Use `make cli-smoke` to verify the CLI contract and `make cli-doctor` to check
the local toolchain.

## Why This Exists

The repository has several focused tools:

```text
tools/fsd-lint.swift
tools/fsd-harmonize.swift
tools/fsd-template-create.swift
tools/fsd-template-validate.swift
```

That is good for implementation, but less convenient for adoption. A stable
`fsd-ios` command gives users one interface while preserving the smaller
internal tools as the source of truth.

## Commands

| Command | Purpose |
|---|---|
| `lint` | Runs the FSD structure lint and optional architecture checks |
| `harmonize` | Prints read-only refactoring suggestions |
| `create app` | Generates the full SwiftUI app starter template |
| `create spm` | Generates the SwiftPM module-island template for legacy adoption |
| `validate template` | Validates a copyable template bundle |
| `doctor` | Checks local prerequisites and quick repository health |

## App Template Flow

Use this when starting a new project from the full SwiftUI template:

```bash
swift tools/fsd-ios.swift create app \
  --name MyApp \
  --output ../MyApp
```

Dry-run first when reviewing the generated file map:

```bash
swift tools/fsd-ios.swift create app \
  --name MyApp \
  --output ../MyApp \
  --dry-run
```

## Legacy Modular Adoption Flow

Use this when the existing application is too large to reorganize immediately.
The generated package becomes a local Swift Package dependency in the legacy
Xcode project.

```bash
swift tools/fsd-ios.swift create spm \
  --name LegacyFSD \
  --output ../LegacyFSDModules
```

Then add `../LegacyFSDModules` to the legacy Xcode project as a local package
and import the product needed by the old app shell:

```swift
import LegacyFSDProductListScreen

ProductListScreen()
```

For UIKit-based legacy code, compose the SwiftUI screen through
`UIHostingController`:

```swift
import LegacyFSDProductListScreen
import SwiftUI

let controller = UIHostingController(rootView: ProductListScreen())
navigationController?.pushViewController(controller, animated: true)
```

The important boundary is in `Package.swift`: lower modules cannot import higher
modules unless that dependency is declared.

## Doctor

Run `doctor` when onboarding a machine or before investigating a local failure:

```bash
swift tools/fsd-ios.swift doctor
```

It checks:

- required files and template manifests;
- Swift toolchain;
- Xcode toolchain;
- Git;
- strict FSD architecture lint;
- app template validation;
- SwiftPM template description.

`doctor` is intentionally quick. Use `make ci` for the full local gate,
including Xcode tests.

## Make Targets

The Makefile exposes the CLI through stable targets:

```bash
make cli-help
make cli-smoke
make cli-doctor
make ci
```

`make cli-smoke` verifies that the unified CLI can call lint, harmonize,
template validation, and both template creation flows.

## CI

CI runs the CLI smoke and doctor checks. That means command names, help-visible
flows, and documented usage cannot silently drift away from implementation.

## Homebrew Roadmap

Homebrew should come after the CLI interface stays stable:

```bash
brew tap SoundBlaster/fsd
brew install fsd-ios
```

Before that, the repository should keep the script entry point documented and
tested. The intended path is:

1. stabilize `tools/fsd-ios.swift`;
2. add local install/uninstall targets;
3. package the same interface for Homebrew;
4. add a reusable GitHub Action once external projects depend on the tool.
