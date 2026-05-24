# ``FSDToolingSupport``

Support module for the FSD iOS toolkit package.

## Overview

`FSDToolingSupport` is a small marker library that makes the repository's
SwiftPM tooling package visible to Xcode, Swift Package Manager, and DocC.

The implementation-heavy tooling currently lives in script entry points under
`tools/` and in the SwiftPM command plugin:

- `fsd-ios` CLI for linting, diagnostics, and template generation.
- `fsd-generate` SwiftPM command plugin for slice and module generation.
- FSD templates for app-first and SwiftPM module-island adoption.

## Topics

### Package Metadata

- ``FSDToolingSupport/packageName``
- ``FSDToolingSupport/generatorPluginVerb``
