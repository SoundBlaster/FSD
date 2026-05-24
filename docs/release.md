# Release Process

## TL;DR

Release work should make `fsd-ios` installable, pin-compatible, and predictable
for projects that use this repository as an external FSD toolkit.

The current baseline is documentation-first. A future PR can add release
artifacts and Homebrew automation without changing the compatibility contract.

## Versioning Policy

Use semantic versioning for the public toolkit surface:

```text
MAJOR.MINOR.PATCH
```

Version scope includes:

- `fsd-ios` CLI commands, options, exit codes, and report formats;
- `.fsd-ios.yml` configuration keys and defaults;
- generated template structure under `templates/`;
- reusable GitHub Action inputs and outputs;
- documented Make targets used by external projects.

Use version changes as follows:

- `MAJOR`: breaking CLI/config/template behavior.
- `MINOR`: new commands, new non-breaking config keys, new templates, or new
  report formats.
- `PATCH`: bug fixes, documentation corrections, fixture updates, or compatible
  rule refinements.

Before the first stable release, keep the CLI version at `0.x.y` and treat minor
versions as potentially compatibility-affecting.

## Release Checklist

1. Update `CHANGELOG.md`.
2. Verify `swift tools/fsd-ios.swift --version` reports the intended version.
3. Run local validation:

   ```bash
   make ci
   ```

   `make ci` includes `make release-docs`, so the release documentation smoke
   check runs as part of the full gate.

4. Create and push a signed or annotated tag:

   ```bash
   git tag -a v0.4.0 -m "FSD iOS v0.4.0"
   git push origin v0.4.0
   ```

5. Create a GitHub Release from the tag.
6. Copy the matching `CHANGELOG.md` section into release notes.
7. Attach release artifacts when artifact packaging exists.
8. Verify external-project instructions still work from a clean checkout.

## Compatibility Contract

Stable behavior:

- existing documented commands should keep working within a major version;
- `text`, `json`, and `xcode` lint formats should remain parseable;
- generated templates should continue to pass repository lint checks;
- CI examples should pin a released version once binary artifacts exist.

Allowed compatible changes:

- adding new optional config keys;
- adding new report fields while preserving existing fields;
- adding new generator templates;
- adding stricter checks only when disabled by default or documented as a minor
  release migration.

Breaking changes:

- removing or renaming CLI commands/options;
- changing JSON field names or required types;
- changing template folder contracts in a way that breaks generated projects;
- changing default lint severity in a way that can fail previously passing
  external projects.

## Artifact Direction

The first artifact target should be a packaged `fsd-ios` executable or wrapper
that can be downloaded from GitHub Releases and smoke-tested in CI.

Future artifact PRs should add:

- a deterministic `make release-artifact` target;
- checksum generation;
- a GitHub Actions release job triggered by tags;
- an install smoke test against the produced artifact.

## Homebrew Direction

Homebrew should come after the release artifact contract is stable.

Expected workflow:

```bash
brew tap SoundBlaster/fsd-ios
brew install fsd-ios
fsd-ios doctor
```

The formula should pin a GitHub Release artifact and verify its checksum. Avoid
using `main` as an install source.
