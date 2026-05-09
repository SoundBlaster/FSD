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

## Запуск

Открой `FSDDemoApp.xcodeproj` в Xcode и запусти scheme `FSDDemoApp`.

Для проверки из терминала:

```bash
xcodebuild \
  -project FSDDemoApp.xcodeproj \
  -scheme FSDDemoApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```
