# FSD Demo App

[![iOS CI](https://github.com/SoundBlaster/FSD/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/SoundBlaster/FSD/actions/workflows/ios-ci.yml)

Минимальное SwiftUI + SwiftData demo-приложение, разложенное по принципам
Feature-Sliced Design.

## Что демонстрирует

- FSD-слои для SwiftUI: `app`, `pages`, `widgets`, `features`, `entities`, `shared`.
- Разделение screen-level composition и reusable user actions.
- Переиспользуемые feature actions: add, edit, delete, toggle completion, change priority.
- Архитектурный lint на Swift CLI и GitHub Actions validation.
- Локальный developer workflow через `make`.

Подробная карта возможностей: [docs/showcase.md](docs/showcase.md).

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

Для проверки из терминала:

```bash
make test
```

Полная локальная проверка:

```bash
make ci
```
