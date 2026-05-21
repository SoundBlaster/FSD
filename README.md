# FSD iOS Reference Template

[![iOS CI](https://github.com/SoundBlaster/FSD/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/SoundBlaster/FSD/actions/workflows/ios-ci.yml)

Reference template для SwiftUI + SwiftData проектов, которые хотят применять
Feature-Sliced Design как набор понятных правил, проверок и good practices.

## Что демонстрирует

- FSD-слои для SwiftUI: `app`, `pages`, `widgets`, `features`, `entities`, `shared`.
- Разделение screen-level composition и reusable user actions.
- Переиспользуемые feature actions: add, edit, delete, toggle completion, change priority.
- Архитектурный lint на Swift CLI и GitHub Actions validation.
- Локальный developer workflow через `make`.
- Copyable template bundle для старта нового FSD iOS проекта.

Подробная карта возможностей: [docs/showcase.md](docs/showcase.md).

## Правила шаблона

- [ARCHITECTURE.md](ARCHITECTURE.md) - основной архитектурный контракт.
- [CONTRIBUTING.md](CONTRIBUTING.md) - workflow для изменений и review.
- [docs/checklist.md](docs/checklist.md) - practical checklist для новых PR.
- [docs/cli.md](docs/cli.md) - unified CLI, doctor и template generation workflow.
- [docs/rules/fsd-layers.md](docs/rules/fsd-layers.md) - назначение FSD layers.
- [docs/rules/fsd-imports.md](docs/rules/fsd-imports.md) - dependency direction и slice isolation.
- [docs/rules/fsd-slices.md](docs/rules/fsd-slices.md) - правила выделения slices.
- [docs/rules/fsd-swiftui.md](docs/rules/fsd-swiftui.md) - SwiftUI-specific conventions.
- [docs/rules/fsd-testing.md](docs/rules/fsd-testing.md) - testing expectations.

## Структура

```text
FSDDemoApp/
  app/        # entrypoint и providers
  pages/      # экраны приложения
  widgets/    # крупные reusable UI blocks
  features/   # пользовательские действия
  entities/   # бизнес-сущности
  shared/     # generic reusable UI
```

Подробные рекомендации по архитектуре: [specs/fsd.md](specs/fsd.md).

Дополнительная заметка про перенос FSD-границ на Swift Package Manager:
[specs/fsd-with-spm.md](specs/fsd-with-spm.md).

## Template Bundle

Копируемый starter package лежит в [templates/fsd-ios](templates/fsd-ios).
Он содержит минимальный SwiftUI/FSD skeleton, `Makefile`, CI workflow,
PR template и checklist для нового проекта.

```bash
make template-demo
swift tools/fsd-ios.swift create app --name MyApp --output ../MyApp --dry-run
swift tools/fsd-ios.swift create app --name MyApp --output ../MyApp
```

## Legacy / Modular Adoption

Для legacy-проектов приоритетнее не новый app skeleton, а локальный Swift Package
с compile-time границами модулей. Такой template лежит в
[templates/fsd-ios-spm](templates/fsd-ios-spm).

```bash
swift tools/fsd-ios.swift create spm \
  --name LegacyFSD \
  --output ../LegacyFSDModules
```

После генерации package можно добавить в существующий Xcode project как local
package dependency и импортировать новый screen/feature module из legacy code.

```bash
make spm-template-test
make spm-template-create-fixture
```

## Unified CLI

Для ежедневной работы есть единый Swift CLI поверх локальных tools:

```bash
swift tools/fsd-ios.swift --help
swift tools/fsd-ios.swift version
swift tools/fsd-ios.swift doctor
swift tools/fsd-ios.swift doctor --json
swift tools/fsd-ios.swift lint --root FSDDemoApp --strict --architecture
```

Make targets для проверки CLI:

```bash
make install-smoke
make cli-smoke
make cli-doctor
```

Локальная установка wrapper в `~/.local/bin`:

```bash
make install
fsd-ios doctor
```

Подробности: [docs/cli.md](docs/cli.md).

## Запуск

Открой `FSDDemoApp.xcodeproj` в Xcode и запусти scheme `FSDDemoApp`.

```bash
make open
```

Быстро показать структуру и архитектурную проверку:

```bash
make demo
```

## Архитектурный lint

Baseline-проверка FSD-структуры реализована как Swift CLI:

```bash
make lint
```

Строгий режим превращает предупреждения в ошибки:

```bash
make lint-strict
```

Архитектурный режим дополнительно строит graph локальных Swift symbols и проверяет
направление FSD-зависимостей между слоями и слайсами:

```bash
make lint-architecture
```

Template bundle проверяется отдельным контрактным валидатором:

```bash
make template-validate
make template-validate-negative
```

Read-only advisor для refactoring suggestions:

```bash
make harmonize
make harmonize-fixture
```

Generator smoke checks:

```bash
make template-create-dry-run
make template-create-fixture
make spm-template-create-fixture
```

Для проверки из терминала:

```bash
make test
```

Полная локальная проверка:

```bash
make ci
```
