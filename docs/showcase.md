# FSD Demo Showcase

Эта страница фиксирует, как стабильно демонстрировать возможности репозитория без
привязки к рабочим `codex/*` веткам.

## Main Demo Path

1. Открой README и покажи CI badge как сигнал, что demo проверяется автоматически.
2. Запусти быстрый локальный сценарий:

   ```bash
   make demo
   ```

3. Покажи полный локальный gate:

   ```bash
   make ci
   ```

4. Перейди от структуры к коду:
   - `FSDDemoApp/pages` показывает screen-level composition;
   - `FSDDemoApp/widgets` показывает крупные reusable UI blocks;
   - `FSDDemoApp/features` показывает user actions with business value;
   - `FSDDemoApp/entities` показывает domain model and entity UI;
   - `FSDDemoApp/shared` показывает generic reusable UI.

## Capability Map

| Capability | Where to look | Stable reference |
|---|---|---|
| FSD layers for SwiftUI | `FSDDemoApp/app`, `pages`, `widgets`, `features`, `entities`, `shared` | `demo/fsd-showcase` |
| Page-level composition | `FSDDemoApp/pages/items`, `pages/item-details`, `pages/item-edit` | `demo/fsd-showcase` |
| Reusable feature actions | `FSDDemoApp/features/add-item`, `edit-item`, `delete-items`, `toggle-item-completion`, `change-item-priority`, `filter-items` | `demo/fsd-showcase` |
| Domain entity reuse | `FSDDemoApp/entities/item` | `demo/fsd-showcase` |
| Shared generic UI | `FSDDemoApp/shared/ui` | `demo/fsd-showcase` |
| Reference template rules | `ARCHITECTURE.md`, `CONTRIBUTING.md`, `docs/rules`, `docs/checklist.md` | `main` |
| Copyable template package | `templates/fsd-ios` | `main` |
| Template package validation | `tools/fsd-template-validate.swift`, `make template-validate` | `main` |
| Strict FSD structure lint | `tools/fsd-lint.swift` | `make lint-strict` |
| Swift symbol dependency lint | `tools/fsd-lint.swift --architecture` | `make lint-architecture` |
| Local developer UX | `Makefile` | `demo/makefile` |
| Repository showcase entry points | `README.md`, `docs/showcase.md`, `make demo` | `demo/repository-showcase` |
| CI validation | `.github/workflows/ios-ci.yml` | `demo/ci-node24` |
| Swift Package Manager boundary notes | `specs/fsd-with-spm.md` | `demo/spm-doc` |

## Stable Snapshots

Use tags for stable demonstration points. Branches keep the working history, while
tags are the intended public anchors.

```bash
git checkout demo/fsd-showcase
git checkout demo/spm-doc
git checkout demo/ci-node24
git checkout demo/makefile
git checkout demo/repository-showcase
```

| Tag | Purpose |
|---|---|
| `demo/fsd-showcase` | Full FSD feature showcase with pages, widgets, features, entities, and shared UI |
| `demo/spm-doc` | Documentation for mapping FSD boundaries to Swift Package Manager |
| `demo/ci-node24` | CI workflow migrated to current GitHub Actions runtime expectations |
| `demo/makefile` | Local Makefile entry points for linting and testing |
| `demo/repository-showcase` | README badge, showcase map, and quick `make demo` entry point |

## Review Trail

The implementation history is still useful for reviewers:

| Area | Pull request |
|---|---|
| FSD showcase app structure and validation baseline | [#1](https://github.com/SoundBlaster/FSD/pull/1) |
| Swift Package Manager architecture notes | [#2](https://github.com/SoundBlaster/FSD/pull/2) |
| Node 24 GitHub Actions migration | [#3](https://github.com/SoundBlaster/FSD/pull/3) |
| Makefile command shortcuts | [#4](https://github.com/SoundBlaster/FSD/pull/4) |
| Repository showcase docs and tags | [#5](https://github.com/SoundBlaster/FSD/pull/5) |
| Advanced FSD architecture lint | [#6](https://github.com/SoundBlaster/FSD/pull/6) |
| Reference template foundation docs | [#7](https://github.com/SoundBlaster/FSD/pull/7) |

For presentations and docs, prefer tags and `main`. For archaeology, use the PRs.
