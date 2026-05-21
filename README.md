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

## Архитектурный lint

Baseline-проверка FSD-структуры реализована как Swift CLI:

```bash
tools/fsd-lint.swift FSDDemoApp
```

Строгий режим превращает предупреждения в ошибки:

```bash
tools/fsd-lint.swift --root FSDDemoApp --strict
```

Для проверки из терминала:

```bash
xcodebuild \
  -project FSDDemoApp.xcodeproj \
  -scheme FSDDemoApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```
