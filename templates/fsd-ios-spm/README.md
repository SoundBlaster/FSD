# FSD iOS SPM Template

This template is for adding new FSD-style code to an existing iOS application
without restructuring the legacy app first.

It creates a local Swift Package that the legacy Xcode project can add as a
package dependency. FSD boundaries are represented by SwiftPM targets and
`Package.swift` dependencies.

## When To Use

Use this template when:

- the existing app is too large to reorganize immediately;
- new screens or flows should be written with explicit module boundaries;
- compile-time dependency direction is more valuable than folder-only guidance;
- the legacy app can import a new local package.

## Layout

```text
Package.swift
Sources/
  AppNameCoreUI/
  AppNameProductDomain/
  AppNameCreateSampleFeature/
  AppNameProductListScreen/
Tests/
  AppNameCreateSampleFeatureTests/
```

## Dependency Direction

```text
AppNameProductListScreen -> AppNameCreateSampleFeature
AppNameProductListScreen -> AppNameProductDomain
AppNameProductListScreen -> AppNameCoreUI
AppNameCreateSampleFeature -> AppNameProductDomain
```

`Package.swift` enforces that lower modules cannot import higher modules.
Only `AppNameProductListScreen` is exposed as a package product, so the legacy
app links the screen-level entrypoint instead of lower-layer implementation
modules.

## Legacy Adoption Flow

1. Generate the package:

   ```bash
   swift tools/fsd-template-create.swift \
     --template templates/fsd-ios-spm \
     --app-name LegacyFSD \
     --output ../LegacyFSDModules
   ```

2. In the legacy Xcode project, add `../LegacyFSDModules` as a local package.
3. Link the needed product, usually `LegacyFSDProductListScreen`.
4. Import from legacy code:

   ```swift
   import LegacyFSDProductListScreen
   ```

5. Compose the new screen from the legacy app's existing router or navigation.

## Checks

From this repository:

```bash
make spm-template-test
make spm-template-create-fixture
```

Inside a generated package:

```bash
swift test
```
