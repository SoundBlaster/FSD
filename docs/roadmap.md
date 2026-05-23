# FSD iOS Roadmap

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

Status: in progress in the first implementation PR after this roadmap.

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

Scope:

- add `--format text|json` to lint output;
- stabilize finding fields: rule id, severity, path, line, message, and
  suggested fix when available;
- preserve human-readable output as the default;
- document JSON examples for external projects.

Success metrics:

- CI can parse lint findings without scraping text;
- future GitHub annotation or SARIF output can reuse the same finding model.

### 3. Slice And Module Generators

Goal: make correct structure easier than manual folder creation.

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

### 4. Distribution And Release DX

Goal: make the toolkit easy to install and update outside the repository.

Scope:

- stabilize `fsd-ios --version`;
- document release process and compatibility expectations;
- prepare GitHub Release artifacts;
- add Homebrew tap instructions after the CLI contract is stable;
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

## Review Strategy

Each PR in the stack should explain:

- the user-facing workflow it unlocks;
- how it preserves existing demo behavior;
- which commands were run;
- which follow-up PR depends on it.

For implementation PRs, prefer targeted fixture tests over broad rewrites.
Documentation should be updated in the same PR when a command, rule, or workflow
changes.
