# FSD iOS Template

This directory is a copyable starter package for a SwiftUI project that wants
to adopt Feature-Sliced Design from the first commit.

It is intentionally small:

- it shows the expected layer and slice shape;
- it includes one sample page, widget, feature, entity, and shared UI element;
- it keeps app setup separate from business slices;
- it provides CI and PR checklist templates;
- it leaves project generation to Xcode or Swift Package Manager.

## How To Use

1. Create a new iOS app in Xcode.
2. Copy the contents of `AppName/` into your app source root.
3. Rename `AppName` to your product module name.
4. Copy `Makefile`, `.github/`, and `docs/` if you want the same local and PR
   workflow.
5. Copy or vendor `tools/fsd-lint.swift` from the repository root into
   `tools/fsd-lint.swift`.
6. Update `PROJECT`, `SCHEME`, and `APP_ROOT` in `Makefile`.
7. Run:

   ```bash
   make demo
   make ci
   ```

From this repository, the same skeleton can be materialized with:

```bash
swift tools/fsd-template-create.swift --app-name MyApp --output ../MyApp --dry-run
swift tools/fsd-template-create.swift --app-name MyApp --output ../MyApp
```

## Layout

```text
AppName/
  app/
    entrypoint/
    providers/
  pages/
    home/
      ui/
  widgets/
    sample-list/
      ui/
  features/
    create-sample-item/
      model/
      ui/
  entities/
    sample-item/
      model/
      ui/
  shared/
    ui/
```

## Extraction Rule

Start inside `pages` while behavior is route-specific. Extract only when there
is a real boundary:

- reusable user action -> `features`;
- reusable business concept -> `entities`;
- reusable composition block -> `widgets`;
- generic infrastructure -> `shared`;
- app-wide setup -> `app`.

## Template Contract

The skeleton is not a full generated Xcode project. It is a reference package
for structure, naming, checks, and review expectations.

`template.yaml` records the template compatibility contract:

```yaml
schemaVersion: 1
version: 0.1.0
minimumToolVersion: 0.4.0
```

- `schemaVersion` is the manifest schema understood by `fsd-ios`.
- `version` is the template contract version.
- `minimumToolVersion` is the oldest `fsd-ios` release expected to validate and
  materialize this template.
