# Roadmap

> Source: `docs/roadmap.md`

## TL;DR

The repository is moving from a demo app with rules into a practical reference
toolkit for new and legacy iOS projects. The next work should land as small,
reviewable stacked PRs and should not be merged until reviewers have time to
inspect each layer of the stack.

## Product Goal

Make this repository a reusable baseline for teams that want:

- a clear FSD architecture contract for SwiftUI and SwiftData projects;
- a lintable rule set that can be adopted incrementally;
- copyable app and SwiftPM module templates;
- local and CI workflows that are stable enough for real project onboarding;
- documentation that explains both the "what" and the "why".

## Working Principles

- Keep modular legacy adoption first-class.
- Prefer explicit configuration over hardcoded project assumptions.
- Make every tool useful from another repository, not only from this checkout.
- Keep generated structure boring and predictable.
- Treat docs, templates, CLI behavior, and CI examples as one product surface.
- Use stacked PRs for larger feature work, but merge only after review.

## Near-Term Stack

### 1. Config Foundation

Goal: introduce `.fsd-ios.yml` as the stable project-level configuration
contract.

Status: merged in [#20](https://github.com/SoundBlaster/FSD/pull/20).

Scope:

- document the config file format;
- add `--config` support to the unified CLI;
- define defaults for layers, strict mode, architecture checks, ignored paths,
  and future rule toggles;
- keep current behavior unchanged when no config file exists;
- add fixture coverage for default config, explicit config, and invalid config.

Success metrics:

- an external project can configure linting without editing CLI source code;
- CI can run with either command-line flags or `.fsd-ios.yml`;
- invalid config fails with actionable diagnostics.

### 2. Machine-Readable Reports

Goal: make lint output consumable by CI, GitHub annotations, and future editor
integrations.

Status: implemented for the baseline linter with `text`, `json`, and `xcode`
report formats. Future annotation formats can build on the same finding model.

Scope:

- add `--format text|json|xcode` to lint output;
- stabilize finding fields: rule id, severity, path, line, message, and
  suggested fix when available;
- preserve human-readable output as the default;
- document JSON examples for external projects;
- document Xcode Run Script Build Phase usage for `--format xcode`.

Success metrics:

- CI can parse lint findings without scraping text;
- Xcode can display FSD diagnostics in the build log and issue navigator;
- future GitHub annotation or SARIF output can reuse the same finding model.

### 3. Slice And Module Generators

Goal: make correct structure easier than manual folder creation.

Status: initial CLI support added for page, feature, entity, and standalone
SwiftPM module generation.

Scope:

- add `fsd-ios create slice page <name>`;
- add `fsd-ios create slice feature <name>`;
- add `fsd-ios create slice entity <name>`;
- add `fsd-ios create module <name>` for SwiftPM module-island adoption;
- generate minimal README/tests/public API placeholders where useful;
- validate names and prevent overwriting existing slices.

Success metrics:

- a developer can add new FSD-style code to a legacy app with one command;
- generated files pass the linter immediately;
- generator output follows the same rules documented in `docs/rules`.

### 4. Xcode Developer Experience

Goal: expose the generator and diagnostics through familiar Xcode entry points
without making Xcode the source of truth for the core tooling.

Status: Xcode File Templates for FSD page, feature action, entity model, and
widget shipped together with `make install-xcode-templates` /
`make uninstall-xcode-templates`. A SwiftPM command plugin wrapper is available
as `swift package --allow-writing-to-package-directory fsd-generate`.

Scope:

- add installable Xcode File Templates for common FSD files and small slice
  entry points
- add install and uninstall targets: `make install-xcode-templates` and
  `make uninstall-xcode-templates`
- document the Xcode template install path:
  `~/Library/Developer/Xcode/Templates/File Templates/FSD iOS`
- evaluate a SwiftPM command plugin wrapper for `fsd-ios create slice`
  and `fsd-ios create module`
- keep the CLI generator as the canonical implementation used by templates and
  plugins

Success metrics:

- a developer can start an FSD page, feature, entity, or widget from
  `File > New > File…` in Xcode;
- generated files still pass the same CLI linter checks;
- SwiftPM module-island projects can expose generation through an Xcode package
  plugin command.

### 5. Distribution And Release DX

Goal: make the toolkit easy to install and update outside the repository.

Status: release process and compatibility policy are documented in
[`docs/release.md`](<doc:ReleaseProcess>). Artifact packaging, checksum generation, smoke
validation, and tag-triggered GitHub Release publishing are implemented.
The Homebrew artifact contract is documented, and a reference formula is kept in
`Formula/fsd-ios.rb`.

Scope:

- stabilize `fsd-ios --version`;
- document release process and compatibility expectations;
- prepare GitHub Release artifacts;
- document Homebrew formula requirements after the artifact contract is stable;
- keep the reference formula smoke-tested before copying it into a tap;
- keep local wrapper installation as the lowest-friction development path.

Success metrics:

- users can install `fsd-ios` without cloning the repository;
- CI examples can pin a tool version;
- release notes explain breaking changes and migration steps.

## Later Work

- GitHub annotation output or SARIF export.
- Richer `harmonize` suggestions with rule ids and confidence levels.
- Template version metadata and compatibility checks.
- More fixture apps that model UIKit legacy shells and mixed SwiftUI/UIKit
  adoption.
- Optional Swift Package boundary validator for generated module islands.
- Optional Xcode Source Editor Extension for current-file refactors and
  boilerplate insertion after the CLI generator and file templates are stable.

## Review Strategy

Each PR in the stack should explain:

- the user-facing workflow it unlocks;
- how it preserves existing demo behavior;
- which commands were run;
- which follow-up PR depends on it.

For implementation PRs, prefer targeted fixture tests over broad rewrites.
Documentation should be updated in the same PR when a command, rule, or workflow
changes.