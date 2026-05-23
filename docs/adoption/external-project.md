# External Project Adoption

## TL;DR

Use this repository as an external FSD iOS toolset when a project is not ready to
copy the full template yet:

```bash
git clone https://github.com/SoundBlaster/FSD.git .fsd-ios-tooling
swift .fsd-ios-tooling/tools/fsd-ios.swift version
swift .fsd-ios-tooling/tools/fsd-ios.swift lint --root Sources/App --strict --architecture
```

For CI, pin the tooling checkout to a tag or commit instead of tracking `main`.

## When To Use This Mode

External adoption is the safest first step for legacy iOS projects:

- the production repository keeps its current Xcode project layout;
- new code can still follow FSD boundaries;
- CI gets a repeatable architecture gate;
- teams can migrate feature-by-feature instead of doing a large rewrite.

Use the full app template only for greenfield projects. Use the SwiftPM
module-island template when compile-time module boundaries are more important
than a single application source tree.

## Repository Layout

A typical external project keeps the FSD source root inside the app repository
and checks out this repository only as tooling:

```text
MyLegacyApp/
  Sources/
    App/
      app/
      pages/
      widgets/
      features/
      entities/
      shared/
  .fsd-ios-tooling/
    tools/
      fsd-ios.swift
      fsd-lint.swift
      fsd-harmonize.swift
      fsd-template-create.swift
      fsd-template-validate.swift
```

`fsd-ios` resolves its own helper tools from `.fsd-ios-tooling/tools`, but
explicit paths such as `--root` are resolved relative to the caller's current
directory. That means the command below checks `MyLegacyApp/Sources/App`, not the
demo app inside `.fsd-ios-tooling`:

```bash
swift .fsd-ios-tooling/tools/fsd-ios.swift lint \
  --root Sources/App \
  --strict \
  --architecture
```

For repeatable local and CI usage, commit `.fsd-ios.yml` to the host project:

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

Then `fsd-ios lint` discovers the config from the caller's current directory:

```bash
swift .fsd-ios-tooling/tools/fsd-ios.swift lint
```

## Local Developer Workflow

Clone or update the tooling checkout:

```bash
git clone https://github.com/SoundBlaster/FSD.git .fsd-ios-tooling
git -C .fsd-ios-tooling fetch --tags
git -C .fsd-ios-tooling checkout <pinned-tag-or-commit>
```

Unless the tooling checkout is intentionally tracked as a Git submodule, add it
to the host app repository's `.gitignore`:

```gitignore
.fsd-ios-tooling/
```

Check the tool version and local environment:

```bash
swift .fsd-ios-tooling/tools/fsd-ios.swift version
swift .fsd-ios-tooling/tools/fsd-ios.swift doctor
```

Run the architecture gate against the app's FSD root:

```bash
swift .fsd-ios-tooling/tools/fsd-ios.swift lint \
  --root Sources/App \
  --strict \
  --architecture
```

Or use the committed config:

```bash
swift .fsd-ios-tooling/tools/fsd-ios.swift lint --config .fsd-ios.yml
```

For refactoring planning, use the read-only advisor:

```bash
swift .fsd-ios-tooling/tools/fsd-ios.swift harmonize --root Sources/App
```

## GitHub Actions Baseline

Copy [examples/github-actions/external-project-fsd-ios.yml](../../examples/github-actions/external-project-fsd-ios.yml)
into the external project and adjust:

- `ref` to the pinned FSD tooling version;
- `.fsd-ios.yml` to the source root and lint policy for the host project;
- simulator/build steps for the host application, if needed.

The baseline workflow intentionally uses the Swift script directly. The reusable
GitHub Action can be added later as a thinner wrapper once the CLI contract is
accepted by reviewers.

## Reusable GitHub Action

After the direct-script baseline is accepted, the external project can switch to
the reusable Action wrapper:

```yaml
- name: Run FSD architecture lint
  uses: SoundBlaster/FSD@main
  with:
    config: .fsd-ios.yml
    strict: "true"
    architecture: "true"
    doctor: "true"
```

Copy [examples/github-actions/external-project-fsd-ios-action.yml](../../examples/github-actions/external-project-fsd-ios-action.yml)
for a complete workflow. In production, replace `@main` with a pinned tag or
commit.

## SwiftPM Module-Island Option

When a legacy app needs stronger boundaries, generate a local Swift Package and
add it to the existing Xcode project:

```bash
swift .fsd-ios-tooling/tools/fsd-ios.swift create spm \
  --name LegacyFSD \
  --output Packages/LegacyFSD
```

Then import the generated screen module from the old app shell:

```swift
import LegacyFSDProductListScreen

ProductListScreen()
```

This approach makes FSD layer direction visible in `Package.swift` dependencies
and lets the old app compose the new module at the edge.

## Stability Rules

For production CI:

1. Pin the tooling checkout to a tag or commit.
2. Run `version` before lint so logs show the exact contract.
3. Run `doctor --json` when machine-readable environment diagnostics are useful.
4. Pass `--root` explicitly; do not rely on the demo app default.
5. Keep host-project build/test steps separate from FSD lint checks.

Success means the external project can add new FSD-compliant code without
renaming its existing folders first, and CI can reject upward or sideways
dependencies before they reach review.
