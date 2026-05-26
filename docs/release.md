# Release Process

## TL;DR

Release work makes `fsd-ios` installable, pin-compatible, and predictable for
projects that use this repository as an external FSD toolkit.

The current baseline includes a self-contained tarball artifact, checksum
generation, local smoke validation, and a tag-triggered GitHub Actions release
workflow. Homebrew automation remains a follow-up after the artifact contract is
stable.

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

   `make ci` includes `make release-docs` and `make release-artifact-smoke`, so
   the release documentation and artifact contracts run as part of the full
   gate.

4. Build the release artifact locally when you need to inspect it before
   tagging:

   ```bash
   make release-artifact-smoke
   cd DerivedData/Release
   shasum -a 256 -c fsd-ios-0.4.0.tar.gz.sha256
   ```

5. Create and push a signed or annotated tag:

   ```bash
   git tag -a v0.4.0 -m "FSD iOS v0.4.0"
   git push origin v0.4.0
   ```

6. Let the `Release Artifacts` GitHub Actions workflow build and smoke-test the
   tarball.
7. Verify the GitHub Release contains:

   ```text
   fsd-ios-0.4.0.tar.gz
   fsd-ios-0.4.0.tar.gz.sha256
   ```

8. Copy or compare the matching `CHANGELOG.md` section against generated release
   notes.
9. Verify external-project instructions still work from a clean checkout.

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

## Release Artifact

Build the local artifact:

```bash
make release-artifact
```

This writes:

```text
DerivedData/Release/fsd-ios-0.4.0.tar.gz
DerivedData/Release/fsd-ios-0.4.0.tar.gz.sha256
```

Smoke-test the packaged workflow:

```bash
make release-artifact-smoke
```

The smoke target verifies the checksum, extracts the tarball, runs
`bin/fsd-ios --version`, runs `bin/fsd-ios doctor --json`, and checks app/SPM
template dry-runs from the extracted artifact.

The artifact layout is:

```text
fsd-ios-0.4.0/
  bin/fsd-ios
  libexec/fsd-ios/
    tools/
    templates/
    docs/
    examples/
    FSDDemoApp/
```

The tarball is built from a sorted file list, normalized timestamps, normalized
archive owners, and `gzip -n`. The `RELEASE_TIMESTAMP` Make variable can be
overridden for a release rebuild if needed.

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
