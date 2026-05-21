# FSD iOS CLI

## TL;DR

`tools/fsd-ios.swift` is the unified local CLI for this repository. It wraps the
existing Swift tools, so the linter, advisor, template generator, and validator
keep one stable entry point:

```bash
swift tools/fsd-ios.swift --help
swift tools/fsd-ios.swift version
swift tools/fsd-ios.swift doctor
swift tools/fsd-ios.swift doctor --json
swift tools/fsd-ios.swift lint --root FSDDemoApp --strict --architecture
swift tools/fsd-ios.swift create spm --name LegacyFSD --output ../LegacyFSDModules
```

Use `make cli-smoke` to verify the CLI contract and `make cli-doctor` to check
the local toolchain.

For daily use inside this checkout, install the local wrapper:

```bash
make install
fsd-ios doctor
```

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
| `version` | Prints the current `fsd-ios` CLI version |
| `lint` | Runs the FSD structure lint and optional architecture checks |
| `harmonize` | Prints read-only refactoring suggestions |
| `create app` | Generates the full SwiftUI app starter template |
| `create spm` | Generates the SwiftPM module-island template for legacy adoption |
| `validate template` | Validates a copyable template bundle |
| `doctor` | Checks local prerequisites and quick repository health |

Default repository paths are resolved from the CLI script location, so the
command can be invoked from another working directory with an absolute script
path. Explicit user paths such as `--root`, `--template`, and `--output` are
resolved relative to the caller's current directory.

## Local Install

Use local installation when you want `fsd-ios` on `PATH` without typing
`swift tools/fsd-ios.swift` every time:

```bash
make install
```

By default, this writes a small wrapper to:

```text
~/.local/bin/fsd-ios
```

Make sure `~/.local/bin` is on `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then run:

```bash
fsd-ios --help
fsd-ios doctor
fsd-ios lint --root FSDDemoApp --strict --architecture
```

To install somewhere else:

```bash
make install INSTALL_PREFIX=/usr/local
```

To remove the wrapper:

```bash
make uninstall
```

The wrapper points back to this checkout's `tools/fsd-ios.swift`, so update the
repository to update the local command. Run `make install-smoke` to verify the
wrapper behavior without touching your real `~/.local/bin`.

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

Use JSON output when another script or CI job needs to parse the result:

```bash
swift tools/fsd-ios.swift doctor --json
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
including Xcode tests. `make cli-doctor` verifies both human-readable and JSON
doctor output.

## Make Targets

The Makefile exposes the CLI through stable targets:

```bash
make cli-help
make cli-smoke
make cli-doctor
make install-smoke
make ci
```

`make cli-smoke` verifies command dispatch, subcommand help, and both template
creation dry-runs without repeating the heavier lint/template checks that
already run elsewhere in `make ci`.

`make install-smoke` installs the wrapper into `DerivedData/LocalInstall`, checks
that it can run, and uninstalls it again.

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
