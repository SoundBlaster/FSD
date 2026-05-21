# FSD Demo App

Минимальное SwiftUI + SwiftData demo-приложение, разложенное по принципам
Feature-Sliced Design.

## Структура

```text
FSDDemoApp/
  app/        # entrypoint и providers
  pages/      # экраны приложения
  features/   # пользовательские действия
  entities/   # бизнес-сущности
```

Подробные рекомендации по архитектуре: [specs/fsd.md](specs/fsd.md).

Дополнительная заметка про перенос FSD-границ на Swift Package Manager:
[specs/fsd-with-spm.md](specs/fsd-with-spm.md).

## Запуск

Открой `FSDDemoApp.xcodeproj` в Xcode и запусти scheme `FSDDemoApp`.

```bash
make open
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
