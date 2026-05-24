# FSD iOS Reference Template

[![iOS CI](https://github.com/SoundBlaster/FSD/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/SoundBlaster/FSD/actions/workflows/ios-ci.yml)

Reference template for SwiftUI + SwiftData projects that want to apply
Feature-Sliced Design as a clear set of rules, checks, and good practices.

## What It Demonstrates

- FSD layers for SwiftUI: `app`, `pages`, `widgets`, `features`, `entities`, `shared`.
- Separation between screen-level composition and reusable user actions.
- Reusable feature actions: add, edit, delete, toggle completion, change priority.
- Architecture lint implemented as Swift CLI tooling and GitHub Actions validation.
- SwiftLint baseline for Swift style checks in the demo app and local packages.
- Local developer workflow through `make`.
- Copyable template bundle for starting a new FSD iOS project.

Detailed capability map: [docs/showcase.md](docs/showcase.md).

## Template Rules

- [ARCHITECTURE.md](ARCHITECTURE.md) - the main architecture contract.
- [CONTRIBUTING.md](CONTRIBUTING.md) - workflow for changes and review.
- [docs/checklist.md](docs/checklist.md) - practical checklist for new PRs.
- [docs/cli.md](docs/cli.md) - unified CLI, doctor, and template generation workflow.
- [docs/configuration.md](docs/configuration.md) - `.fsd-ios.yml` configuration contract.
- [docs/roadmap.md](docs/roadmap.md) - planned CLI, lint, generator, and release DX work.
- [docs/adoption/external-project.md](docs/adoption/external-project.md) - using FSD tooling in an external iOS project.
- [docs/rules/fsd-layers.md](docs/rules/fsd-layers.md) - FSD layer responsibilities.
- [docs/rules/fsd-imports.md](docs/rules/fsd-imports.md) - dependency direction and slice isolation.
- [docs/rules/fsd-slices.md](docs/rules/fsd-slices.md) - slice extraction rules.
- [docs/rules/fsd-swiftui.md](docs/rules/fsd-swiftui.md) - SwiftUI-specific conventions.
- [docs/rules/fsd-testing.md](docs/rules/fsd-testing.md) - testing expectations.

## Structure

```text
FSDDemoApp/
  app/        # entrypoint and providers
  pages/      # application screens
  widgets/    # large reusable UI blocks
  features/   # user actions
  entities/   # business entities
LocalPackages/
  SharedUI/          # generic reusable UI package
  ItemExportFeature/ # feature-level SwiftPM package used by the app
```

Detailed architecture recommendations: [specs/fsd.md](specs/fsd.md).

Additional notes on mapping FSD boundaries to Swift Package Manager:
[specs/fsd-with-spm.md](specs/fsd-with-spm.md).

## Template Bundle

The copyable starter package lives in [templates/fsd-ios](templates/fsd-ios).
It contains a minimal SwiftUI/FSD skeleton, `Makefile`, CI workflow, PR template,
and checklist for a new project.

```bash
make template-demo
swift tools/fsd-ios.swift create app --name MyApp --output ../MyApp --dry-run
swift tools/fsd-ios.swift create app --name MyApp --output ../MyApp
```

## Legacy / Modular Adoption

For legacy projects, a local Swift Package with compile-time module boundaries is
usually more important than a new app skeleton. That template lives in
[templates/fsd-ios-spm](templates/fsd-ios-spm).

```bash
swift tools/fsd-ios.swift create spm \
  --name LegacyFSD \
  --output ../LegacyFSDModules
```

After generation, add the package to the existing Xcode project as a local
package dependency and import the new screen/feature module from legacy code.

```bash
make spm-template-test
make spm-template-create-fixture
```

The demo app also includes real local package dependencies under
`LocalPackages/`: `SharedUI` for generic UI primitives and `ItemExportFeature`
for the export-items user action. `ItemExportFeature` receives an `ExportItem`
DTO from the page layer, so the package stays independent from the app's
SwiftData model while the app still demonstrates feature-level modularity.

```bash
make item-export-feature-test
```

## External Project Adoption

If an existing project cannot be moved into the template yet, use this repository
as an external FSD toolset and run lint against the selected source root:

```bash
git clone https://github.com/SoundBlaster/FSD.git .fsd-ios-tooling
swift .fsd-ios-tooling/tools/fsd-ios.swift lint \
  --root Sources/App \
  --strict \
  --architecture
```

CI baseline: [examples/github-actions/external-project-fsd-ios.yml](examples/github-actions/external-project-fsd-ios.yml).
Reusable Action baseline:
[examples/github-actions/external-project-fsd-ios-action.yml](examples/github-actions/external-project-fsd-ios-action.yml).
Details: [docs/adoption/external-project.md](docs/adoption/external-project.md).

## Unified CLI

Daily work uses a single Swift CLI on top of the local tools:

```bash
swift tools/fsd-ios.swift --help
swift tools/fsd-ios.swift version
swift tools/fsd-ios.swift --version
swift tools/fsd-ios.swift doctor
swift tools/fsd-ios.swift doctor --json
swift tools/fsd-ios.swift lint --config .fsd-ios.yml
swift tools/fsd-ios.swift lint --root FSDDemoApp --strict --architecture
swift tools/fsd-ios.swift create slice feature export-report --root FSDDemoApp
swift tools/fsd-ios.swift create module Reporting --output ../ReportingModule
swift package --allow-writing-to-package-directory fsd-generate slice feature export-report --root FSDDemoApp
```

Make targets for CLI validation:

```bash
make install-smoke
make cli-smoke
make cli-doctor
make config-smoke
make spm-plugin-smoke
make action-smoke
```

Local wrapper installation into `~/.local/bin`:

```bash
make install
fsd-ios doctor
```

Install Xcode File Templates (Page, Feature Action, Entity Model, Widget)
under `~/Library/Developer/Xcode/Templates/File Templates/FSD iOS/`:

```bash
make install-xcode-templates
make uninstall-xcode-templates
```

Details: [docs/cli.md](docs/cli.md).

## Running

Open `FSDDemoApp.xcodeproj` in Xcode and run the `FSDDemoApp` scheme.

```bash
make open
```

Quickly show the structure and architecture check:

```bash
make demo
```

## Architecture Lint

Baseline FSD structure checks are implemented as a Swift CLI:

```bash
make lint
```

Strict mode turns warnings into errors:

```bash
make lint-strict
```

Architecture mode additionally builds a graph of local Swift symbols and checks
FSD dependency direction between layers and slices:

```bash
make lint-architecture
```

Swift style checks use [SwiftLint](https://github.com/realm/SwiftLint). Install
it locally with Homebrew before running the target:

```bash
brew install swiftlint
make swiftlint
```

Repository-level lint defaults live in [.fsd-ios.yml](.fsd-ios.yml). The config
contract is documented in [docs/configuration.md](docs/configuration.md).
Lint reports can also be emitted as JSON for CI tooling or as Xcode diagnostics:

```bash
swift tools/fsd-ios.swift lint --config .fsd-ios.yml --format json
swift tools/fsd-ios.swift lint --config .fsd-ios.yml --format xcode
```

The template bundle is checked by a dedicated contract validator:

```bash
make template-validate
make template-validate-negative
```

Read-only advisor for refactoring suggestions:

```bash
make harmonize
make harmonize-fixture
```

Generator smoke checks:

```bash
make template-create-dry-run
make template-create-fixture
make spm-template-create-fixture
```

Terminal test run:

```bash
make test
```

Full local validation:

```bash
make ci
```
