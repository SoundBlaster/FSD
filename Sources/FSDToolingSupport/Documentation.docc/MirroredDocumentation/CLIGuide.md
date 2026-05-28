# CLI Guide

> Source: `docs/cli.md`

## TL;DR

`tools/fsd-ios.swift` is the unified local CLI for this repository. It wraps the
existing Swift tools, so the linter, advisor, template generator, and validator
keep one stable entry point:

```bash
swift tools/fsd-ios.swift --help
swift tools/fsd-ios.swift version
swift tools/fsd-ios.swift --version
swift tools/fsd-ios.swift doctor
swift tools/fsd-ios.swift doctor --json
swift tools/fsd-ios.swift lint --config .fsd-ios.yml
swift tools/fsd-ios.swift lint --root FSDDemoApp --strict --architecture
swift tools/fsd-ios.swift lint --config .fsd-ios.yml --format xcode
swift tools/fsd-ios.swift create spm --name LegacyFSD --output ../LegacyFSDModules
swift tools/fsd-ios.swift create slice feature export-report --root Sources/App
swift tools/fsd-ios.swift create module Reporting --output ../ReportingModule
```

Use `make cli-smoke` to verify the CLI contract and `make cli-doctor` to check
the local toolchain.

For daily use inside this checkout, install the local wrapper:

```bash
make install
fsd-ios doctor
```

For an existing app repository, keep this repository as an external tooling
checkout and pass the app source root explicitly:

```bash
swift .fsd-ios-tooling/tools/fsd-ios.swift lint --root Sources/App --strict --architecture
```

See [External Project Adoption](<doc:ExternalProjectAdoption>) for the full CI
baseline.

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
| `version`, `--version` | Prints the current `fsd-ios` CLI version |
| `lint` | Runs the FSD structure lint and optional architecture checks |
| `harmonize` | Prints read-only refactoring suggestions |
| `create app` | Generates the full SwiftUI app starter template |
| `create spm` | Generates the SwiftPM module-island template for legacy adoption |
| `create slice` | Generates page, feature, or entity slice files in an app source root |
| `create module` | Generates a standalone SwiftPM module island |
| `validate template` | Validates a copyable template bundle |
| `doctor` | Checks local prerequisites and quick repository health |

Default repository paths are resolved from the CLI script location, so the
command can be invoked from another working directory with an absolute script
path. Explicit user paths such as `--root`, `--template`, and `--output` are
resolved relative to the caller's current directory.

## Configuration

`lint` can read `.fsd-ios.yml` automatically from the caller's current
directory:

```bash
swift tools/fsd-ios.swift lint
```

Use `--config` when the file lives elsewhere:

```bash
swift tools/fsd-ios.swift lint --config .fsd-ios.yml
swift tools/fsd-ios.swift lint --config .fsd-ios.yml --strict --architecture
```

Command-line values override config values:

```bash
swift tools/fsd-ios.swift lint --config .fsd-ios.yml --root Sources/App
swift tools/fsd-ios.swift lint --config .fsd-ios.yml --no-strict --no-architecture
```

See [FSD iOS Configuration](<doc:ConfigurationContract>) for the full config contract.

## Lint Report Formats

Human-readable text remains the default:

```bash
swift tools/fsd-ios.swift lint --config .fsd-ios.yml
```

Use JSON when CI, bots, or dashboards need stable fields instead of scraping
text:

```bash
swift tools/fsd-ios.swift lint --config .fsd-ios.yml --format json
```

JSON reports use this shape:

```json
{
  "tool": "fsd-lint",
  "schemaVersion": 1,
  "format": "json",
  "root": "/absolute/source/root",
  "summary": {
    "errors": 1,
    "warnings": 0
  },
  "findings": [
    {
      "ruleId": "fsd/root-swift-file",
      "severity": "error",
      "path": "Loose.swift",
      "absolutePath": "/absolute/source/root/Loose.swift",
      "message": "Swift files should live inside an FSD layer",
      "suggestion": "Move the file under app, pages, widgets, features, entities, or shared."
    }
  ]
}
```

Use Xcode format from a Run Script Build Phase so diagnostics become clickable
in the build log and issue navigator:

```bash
swift .fsd-ios-tooling/tools/fsd-ios.swift lint \
  --config "$SRCROOT/.fsd-ios.yml" \
  --format xcode
```

The emitted lines follow Xcode's parser convention:

```text
/absolute/source/root/Loose.swift:1: error: [fsd/root-swift-file] Swift files should live inside an FSD layer
```

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
fsd-ios --version
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

## Release Artifact Install

Use the release artifact when you want a pinned, self-contained toolkit without
depending on a mutable checkout path:

```bash
make release-artifact-smoke
tar -xzf DerivedData/Release/fsd-ios-0.4.0.tar.gz -C /tmp
/tmp/fsd-ios-0.4.0/bin/fsd-ios doctor
```

The artifact wrapper resolves its embedded `libexec/fsd-ios` directory, so
commands such as `doctor`, `lint`, `create app`, and `create spm` keep working
after the archive is moved or unpacked in CI.

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

## Slice Generator Flow

Use slice generation when an existing FSD app already has a source root and you
want a predictable page, feature, or entity boundary:

```bash
swift tools/fsd-ios.swift create slice page order-details --root Sources/App
swift tools/fsd-ios.swift create slice feature export-report --root Sources/App
swift tools/fsd-ios.swift create slice entity customer-account --root Sources/App
```

The slice name must be kebab-case business language. The generator refuses to
overwrite existing files and creates only allowed FSD segments such as `ui` and
`model`, so the generated structure can be linted immediately:

```bash
swift tools/fsd-ios.swift lint --root Sources/App --strict --architecture
```

Omit `--root` inside this repository to target `FSDDemoApp`. Use `--dry-run` to
review the planned file map without writing files.

## Standalone Module Generator Flow

Use module generation when a legacy codebase needs a small SwiftPM island before
adopting the larger module template:

```bash
swift tools/fsd-ios.swift create module Reporting --output ../ReportingModule
swift test --package-path ../ReportingModule
```

The module name must be a valid Swift identifier. The generator creates a
minimal package manifest, public API placeholder, test target, and README, and
refuses to overwrite existing files.

## Xcode File Templates

For developers who prefer adding files through Xcode after a slice already
exists, the repository ships file templates that mirror the CLI generator
layouts.

```bash
make install-xcode-templates
```

This copies the bundled templates into
`~/Library/Developer/Xcode/Templates/File Templates/FSD iOS/`. Restart Xcode
and the **FSD iOS** group appears in `File > New > File…` with these entries:

- **FSD Page** — SwiftUI page view for `pages/<slice>/ui/<Name>Page.swift`;
- **FSD Feature Action** — callable action struct for
  `features/<slice>/model/<Name>Action.swift`;
- **FSD Entity Model** — `Identifiable` value type for
  `entities/<slice>/model/<Name>.swift`;
- **FSD Widget** — SwiftUI composition view for
  `widgets/<slice>/ui/<Name>Widget.swift`.

The CLI generator remains canonical: use `fsd-ios create slice` for new
slices, and the Xcode templates for additional files within an existing
slice folder. Generated files pass the same `fsd-lint` checks when placed
in the appropriate FSD layer.

Each stub also includes Xcode code-completion placeholders (`<#hint#>`) so
the editor shows editable tokens for the model field, dependencies, body,
and other slots the developer needs to fill in. Use Tab to jump between
placeholders.

To remove the templates:

```bash
make uninstall-xcode-templates
```

Override the install location for sandboxes or per-user destinations:

```bash
make install-xcode-templates XCODE_TEMPLATES_DIR="$PWD/.xcode-templates/FSD iOS"
```

## SwiftPM Generator Plugin

The repository root also exposes a SwiftPM command plugin for Xcode/SwiftPM
workflows that need to generate a whole slice directory, not just a single file
template. The plugin is named `fsd-generate` and delegates to
`tools/fsd-ios.swift`.

Opening the root `Package.swift` in Xcode shows the `FSDTools` package with a
small `FSDToolingSupport` marker target so the tooling package is visible in the
project navigator. The generator itself remains a script, not an Xcode-built
SwiftPM target, so Xcode does not try to compile the CLI for iOS destinations.

```bash
swift package plugin --list
swift package --allow-writing-to-package-directory fsd-generate --help
swift package --allow-writing-to-package-directory fsd-generate \
  slice feature export-report \
  --root Sources/App
swift package --allow-writing-to-package-directory fsd-generate \
  module Reporting \
  --output Packages/ReportingModule
```

`--allow-writing-to-package-directory` is required by SwiftPM because the plugin
creates or previews files in the package directory. Arguments after
`fsd-generate` match `fsd-ios create`, so validation, dry-run output, duplicate
destination checks, and overwrite protection stay identical to the CLI.
When intentionally writing generated output outside the package directory, pass
SwiftPM's additional `--allow-writing-to-directory <path>` permission before
`fsd-generate`.

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
make config-smoke
make report-smoke
make slice-create-fixture
make module-create-fixture
make install-smoke
make install-xcode-templates
make uninstall-xcode-templates
make xcode-templates-smoke
make spm-plugin-smoke
make action-smoke
make ci
```

`make cli-smoke` verifies command dispatch, subcommand help, and both template
creation dry-runs without repeating the heavier lint/template checks that
already run elsewhere in `make ci`.

`make install-smoke` installs the wrapper into `DerivedData/LocalInstall`, checks
that it can run, and uninstalls it again.

`make xcode-templates-smoke` installs the Xcode File Templates into
`DerivedData/XcodeTemplatesSmoke`, verifies each `.xctemplate` bundle's
`TemplateInfo.plist` parses and that the template Swift file references the
expected Xcode substitution macros, then removes the directory.

`make spm-plugin-smoke` verifies SwiftPM command plugin discovery, plugin help,
slice dry-run/materialization, module dry-run/materialization, and `swift test`
for the generated module island.

`make config-smoke` verifies explicit config loading, default config discovery,
direct linter config support, and invalid config diagnostics.

`make report-smoke` verifies `text`, `json`, and `xcode` lint output contracts
on a targeted violation fixture.

`make action-smoke` verifies the reusable GitHub Action metadata and runs the
same strict architecture lint path that the Action dispatches.

## CI

CI runs the CLI smoke and doctor checks. That means command names, help-visible
flows, and documented usage cannot silently drift away from implementation.

## Homebrew Install

Homebrew should package the same versioned artifact that GitHub Releases publish:

```bash
brew tap SoundBlaster/tap
brew install fsd-ios
fsd-ios doctor
```

The reference formula contract is documented in [Release Process](<doc:ReleaseProcess>).
It must pin a GitHub Release tarball and checksum instead of using `main`.
The public tap lives in
[`SoundBlaster/homebrew-tap`](https://github.com/SoundBlaster/homebrew-tap),
and this repository keeps a synchronized reference formula at
`Formula/fsd-ios.rb`:

```bash
make homebrew-formula-smoke
```

Treat the checked-in formula as tap-ready source for
`SoundBlaster/homebrew-tap`. The smoke target creates a temporary local tap,
installs the formula, runs `brew test`, and verifies the installed wrapper.

The intended path is:

1. stabilize `tools/fsd-ios.swift`;
2. add local install/uninstall targets;
3. publish versioned release artifacts;
4. package the same artifact contract in `SoundBlaster/homebrew-tap`.