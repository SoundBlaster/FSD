# SPM как основа FSD-like архитектуры в iOS

Эта заметка фиксирует концепты использования Swift Package Manager для архитектуры в стиле Feature-Sliced Design, адаптированной под iOS/Swift.

Главная идея: в iOS роль архитектурных границ лучше всего играют не папки, а **Swift-модули**. SPM target даёт compile-time изоляцию, а `public`/`internal`/`package` access control задаёт публичный API модуля.

В этом репозитории есть практический starter для такого подхода:
[templates/fsd-ios-spm](../templates/fsd-ios-spm). Его можно материализовать
через `tools/fsd-template-create.swift` и подключить к legacy Xcode project как
local Swift Package.

```txt
SPM target              = архитектурный модуль / slice
Swift module boundary   = граница видимости
public API              = аналог index.ts
Package.swift deps      = правила направленных зависимостей
traits                  = compile-time опции, но не основа архитектуры
```

---

## 1. Как FSD переносится на iOS

В web FSD часто используется структура:

```txt
app
pages
widgets
features
entities
shared
```

Для iOS удобнее адаптировать названия под платформу:

```txt
App target
Screens / Flows
Components / Compositions
Features
Domain / Entities
Core / Shared
```

Пример направленности зависимостей:

```txt
App
  ↓
Screens / Flows
  ↓
Components / Compositions
  ↓
Features
  ↓
Domain / Entities
  ↓
Core / Shared
```

Пример конкретных модулей:

```txt
App
  ↓
ProductDetailsScreen
CatalogScreen
CheckoutFlow
  ↓
ProductCardComponent
CartSummaryComponent
  ↓
AddToCartFeature
ApplyPromoCodeFeature
LoginFeature
  ↓
ProductDomain
CartDomain
UserDomain
OrderDomain
  ↓
CoreNetworking
CoreUI
CoreDesignSystem
CoreStorage
CoreAnalytics
```

В iOS слово `widgets` лучше использовать осторожно, потому что оно может путаться с WidgetKit. Часто понятнее: `Components`, `Compositions`, `Blocks`, `FeatureUI`, `Screens`, `Flows`.

---

## 2. SPM target как архитектурная граница

Папка сама по себе не запрещает неправильные импорты. SPM target — запрещает.

Если `ProductDomain` не зависит от `AddToCartFeature` в `Package.swift`, то код внутри `ProductDomain` не сможет сделать:

```swift
import AddToCartFeature
```

Это превращает правило FSD “зависимости идут только сверху вниз” в compile-time ограничение.

Пример структуры:

```txt
Packages/
  AppModules/
    Package.swift
    Sources/
      CoreUI/
      CoreNetworking/
      CoreAnalytics/
      ProductDomain/
      CartDomain/
      AddToCartFeature/
      ProductCardComponent/
      ProductDetailsScreen/
      CatalogScreen/
```

Пример `Package.swift`:

> Версии в примере (`swift-tools-version` и минимальная iOS) условные. В реальном проекте их нужно выбрать под текущий Xcode, Swift toolchain и deployment target приложения.

```swift
// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "AppModules",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "ProductDetailsScreen", targets: ["ProductDetailsScreen"]),
        .library(name: "CatalogScreen", targets: ["CatalogScreen"]),
        .library(name: "CartScreen", targets: ["CartScreen"])
    ],
    targets: [
        // Core / Shared
        .target(name: "CoreUI"),
        .target(name: "CoreNetworking"),
        .target(name: "CoreAnalytics"),

        // Domain / Entities
        .target(
            name: "ProductDomain",
            dependencies: [
                "CoreNetworking"
            ]
        ),
        .target(
            name: "CartDomain",
            dependencies: [
                "ProductDomain",
                "CoreNetworking"
            ]
        ),

        // Features
        .target(
            name: "AddToCartFeature",
            dependencies: [
                "ProductDomain",
                "CartDomain",
                "CoreUI",
                "CoreAnalytics"
            ]
        ),

        // Components / Compositions
        .target(
            name: "ProductCardComponent",
            dependencies: [
                "ProductDomain",
                "AddToCartFeature",
                "CoreUI"
            ]
        ),

        // Screens / Flows
        .target(
            name: "ProductDetailsScreen",
            dependencies: [
                "ProductDomain",
                "ProductCardComponent",
                "AddToCartFeature",
                "CoreUI"
            ]
        )
    ]
)
```

---

## 3. Аналог `index.ts` в Swift

В TypeScript public API слайса часто задаётся через `index.ts`:

```ts
export { AddToCartButton } from './ui/add-to-cart-button';
export { useAddToCart } from './model/use-add-to-cart';
```

В Swift прямого аналога `index.ts` нет. Его роль выполняет **публичный API Swift-модуля**:

```txt
public / open     — видно другим модулям
package           — видно target'ам внутри одного package
internal          — видно только внутри target/module
fileprivate       — видно в пределах одного Swift-файла
private           — видно только в ближайшей lexical scope
```

То есть внешний код делает:

```swift
import AddToCartFeature
```

И видит только то, что в target `AddToCartFeature` объявлено как `public` или `open`.

Практическое правило:

```txt
public — только facade и необходимые контракты
internal — реализация по умолчанию
package — внутренний API между target'ами одного package
fileprivate — детали, общие для нескольких типов в одном файле
private — детали конкретной lexical scope
```

Пример структуры target:

```txt
Sources/
  AddToCartFeature/
    AddToCartFeature.swift               # public facade
    AddToCartFeature+Dependencies.swift  # public dependencies contract
    Internal/
      AddToCartButton.swift              # internal
      AddToCartViewModel.swift           # internal
      AddToCartRepository.swift          # internal
      AddToCartMapper.swift              # internal
```

Пример facade:

```swift
import SwiftUI
import ProductDomain

public enum AddToCartFeature {
    public struct Dependencies: Sendable {
        public let addToCart: @Sendable (Product.ID) async throws -> Void

        public init(
            addToCart: @escaping @Sendable (Product.ID) async throws -> Void
        ) {
            self.addToCart = addToCart
        }
    }

    @MainActor
    public static func makeButton(
        productID: Product.ID,
        dependencies: Dependencies
    ) -> some View {
        AddToCartButton(
            productID: productID,
            viewModel: AddToCartViewModel(dependencies: dependencies)
        )
    }
}
```

Внутренние типы остаются `internal`:

```swift
@MainActor
final class AddToCartViewModel: ObservableObject {
    private let dependencies: AddToCartFeature.Dependencies

    init(dependencies: AddToCartFeature.Dependencies) {
        self.dependencies = dependencies
    }

    func add(_ productID: Product.ID) async {
        try? await dependencies.addToCart(productID)
    }
}
```

Такой facade и есть Swift-аналог `index.ts`: наружу выходит только то, что явно нужно потребителям.

---

## 4. App target как composition root

Основной app target должен быть тонким. Его задача — собрать приложение:

```txt
App target
  App.swift / SceneDelegate / AppDelegate
  RootCoordinator
  DI container
  navigation setup
  app-level configuration
```

`App` может импортировать верхнеуровневые screens/flows:

```swift
import ProductDetailsScreen
import CatalogScreen
import CartScreen
import CheckoutFlow
```

И связывать зависимости:

```swift
let productDetails = ProductDetailsScreenFactory(
    dependencies: .init(
        loadProduct: productService.loadProduct,
        addToCart: cartService.addToCart
    )
)
```

`App` — верхний слой. Ему нормально знать обо многих модулях. Нижним слоям знать про `App` нельзя.

---

## 5. Screens / Flows

`Screens` и `Flows` — аналог `pages` в web FSD.

Примеры:

```txt
ProductDetailsScreen
CatalogScreen
ProfileScreen
CheckoutFlow
OnboardingFlow
```

Screen/Flow может импортировать:

```txt
Components
Features
Domain
Core
```

Но не должен импортироваться нижними слоями.

Пример public API screen-модуля:

```swift
import UIKit
import ProductDomain

public enum ProductDetailsScreen {
    public struct Dependencies: Sendable {
        public let loadProduct: @Sendable (Product.ID) async throws -> Product
        public let addToCart: @Sendable (Product.ID) async throws -> Void

        public init(
            loadProduct: @escaping @Sendable (Product.ID) async throws -> Product,
            addToCart: @escaping @Sendable (Product.ID) async throws -> Void
        ) {
            self.loadProduct = loadProduct
            self.addToCart = addToCart
        }
    }

    @MainActor
    public static func makeViewController(
        productID: Product.ID,
        dependencies: Dependencies
    ) -> UIViewController {
        ProductDetailsViewController(
            productID: productID,
            viewModel: ProductDetailsViewModel(dependencies: dependencies)
        )
    }
}
```

---

## 6. Features

Feature — это пользовательское действие с бизнес-смыслом.

Хорошие названия:

```txt
AddToCartFeature
RemoveFromCartFeature
ApplyPromoCodeFeature
LoginFeature
LogoutFeature
UploadAvatarFeature
SendCommentFeature
```

Плохие названия:

```txt
OpenModalFeature
CloseModalFeature
ButtonTapFeature
TextFieldChangeFeature
```

Feature может зависеть от `Domain` и `Core`:

```txt
AddToCartFeature
  → CartDomain
  → ProductDomain
  → CoreUI
  → CoreAnalytics
```

Но feature не должна зависеть от screen:

```txt
AddToCartFeature
  ✗ ProductDetailsScreen
```

Если две feature должны взаимодействовать, лучше связывать их через контракт или через `App`/Coordinator, а не прямым импортом реализации.

---

## 7. Domain / Entities

Domain-модули описывают бизнес-сущности и доменную логику.

Примеры:

```txt
ProductDomain
CartDomain
UserDomain
OrderDomain
PaymentDomain
```

Пример:

```swift
public struct Product: Identifiable, Equatable, Sendable {
    public struct ID: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let id: ID
    public let title: String
    public let price: Money

    public init(id: ID, title: String, price: Money) {
        self.id = id
        self.title = title
        self.price = price
    }
}
```

`ProductDomain` не должен знать о:

```txt
ProductDetailsScreen
AddToCartFeature
ProductCardComponent
```

Domain — нижний слой. Он должен быть максимально стабильным.

---

## 8. Core / Shared

Core-модули — это инфраструктура без продуктовой бизнес-логики.

Примеры:

```txt
CoreUI
CoreDesignSystem
CoreNetworking
CoreStorage
CoreAnalytics
CoreLocalization
CoreLogging
CoreConcurrency
```

`CoreUI` может содержать:

```swift
public struct PrimaryButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(title, action: action)
    }
}
```

`CoreUI` не должен содержать:

```swift
public struct ProductCard: View { ... }
```

Потому что `ProductCard` знает про бизнес-сущность `Product`. Ему место в `ProductCardComponent`, `ProductUI` или другом модуле выше `Domain`.

---

## 9. Interface target + Implementation target

Иногда feature должна зависеть от контракта другой feature, но не от её реализации.

Тогда можно разделить target на interface и implementation:

```txt
Sources/
  AuthFeatureInterface/
    AuthRouting.swift
    AuthSessionProviding.swift

  AuthFeature/
    LiveAuthFeature.swift
    LoginView.swift
    LoginViewModel.swift

  CheckoutFlow/
    CheckoutFlow.swift
    CheckoutViewModel.swift
```

`CheckoutFlow` зависит от `AuthFeatureInterface`, но не от `AuthFeature`:

```swift
.target(
    name: "CheckoutFlow",
    dependencies: [
        "AuthFeatureInterface",
        "CartDomain",
        "CoreUI"
    ]
)
```

Контракт:

```swift
public protocol AuthRequiredRouting: Sendable {
    @MainActor
    func requestLogin() async -> Bool
}
```

Checkout использует только контракт:

```swift
public struct CheckoutDependencies: Sendable {
    public let authRequiredRouting: AuthRequiredRouting

    public init(authRequiredRouting: AuthRequiredRouting) {
        self.authRequiredRouting = authRequiredRouting
    }
}
```

`App` связывает конкретную реализацию:

```swift
let checkout = CheckoutFlow.make(
    dependencies: .init(
        authRequiredRouting: appAuthRouter
    )
)
```

Это помогает не нарушать правило “feature не импортирует соседнюю feature напрямую”.

---

## 10. `package` access modifier

`package` access modifier полезен, когда один package содержит много targets.

```txt
public   — внешний API package/module
package  — видно только внутри одного Swift package
internal — видно только внутри target/module
fileprivate — видно в пределах одного Swift-файла
private  — локальная деталь ближайшей lexical scope
```

Пример:

```swift
package enum ProductDetailsAnalytics {
    package static func trackOpened(productID: Product.ID) {
        // ...
    }
}
```

Это могут использовать target'ы внутри `AppModules`, но внешний потребитель package не увидит этот API как публичный.

Практический смысл:

```txt
public делаем маленьким и стабильным
package используем для внутренней интеграции target'ов
internal держим для реализации конкретного target
```

---

## 11. Ресурсы внутри SPM-модулей

SPM target может владеть своими ресурсами:

```txt
Sources/
  CoreDesignSystem/
    Resources/
      Colors.xcassets
      Typography.json

  ProductDetailsScreen/
    Resources/
      Localizable.strings
      EmptyState.imageset
```

Использование:

```swift
Image("empty_state", bundle: .module)
```

или:

```swift
String(
    localized: "product_details.title",
    bundle: .module
)
```

Это позволяет держать ассеты и локализацию рядом с модулем, которому они принадлежат.

---

## 12. Traits в SwiftPM

Traits — это compile-time опции Swift package.

Их не стоит использовать как основу архитектуры. Основа архитектуры — targets.

```txt
SPM target  = архитектурная граница
trait       = опциональная capability внутри package
```

Хорошие применения traits:

```txt
DebugMenu
PreviewFixtures
AnalyticsIntegration
ExperimentalCheckout
StrictLegacyDeprecations
LottieSupport
NukeImageLoadingAdapter
```

Плохие применения traits:

```txt
ProductDomain
CartDomain
AddToCartFeature
ProductDetailsScreen
```

Это должны быть targets, а не traits.

---

## 13. Пример traits в Package.swift

Синтаксис может немного отличаться в зависимости от версии SwiftPM, но концептуально выглядит так:

> Значения `swift-tools-version` и `.iOS(...)` ниже приведены только для иллюстрации. Для конкретного репозитория их нужно синхронизировать с настройками проекта и CI.

```swift
// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "AppModules",
    platforms: [
        .iOS(.v17)
    ],
    traits: [
        .default(enabledTraits: []),
        .trait(
            name: "DebugMenu",
            description: "Enables internal debug menu and diagnostic tools"
        ),
        .trait(
            name: "PreviewFixtures",
            description: "Exposes mock data for SwiftUI previews"
        ),
        .trait(
            name: "AnalyticsIntegration",
            description: "Enables analytics SDK adapter"
        ),
        .trait(
            name: "ExperimentalCheckout",
            description: "Exposes experimental checkout APIs"
        ),
        .trait(
            name: "StrictLegacyDeprecations",
            description: "Turns selected deprecated APIs into unavailable APIs"
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/example/analytics-sdk",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "CoreAnalytics",
            dependencies: [
                .product(
                    name: "AnalyticsSDK",
                    package: "analytics-sdk",
                    condition: .when(traits: ["AnalyticsIntegration"])
                )
            ]
        )
    ]
)
```

В коде:

```swift
#if AnalyticsIntegration
import AnalyticsSDK
#endif

public enum AnalyticsClient {
    public static func track(_ event: AnalyticsEvent) {
        #if AnalyticsIntegration
        AnalyticsSDK.track(event.name, parameters: event.parameters)
        #else
        // no-op
        #endif
    }
}
```

Главное правило: не размазывать `#if` по app-коду. Условная компиляция должна быть спрятана внутри facade конкретного модуля.

Хорошо:

```swift
// App target
DebugMenuFeature.install(on: window)
```

```swift
// DebugTools target
public enum DebugMenuFeature {
    public static func install(on window: UIWindow?) {
        #if DebugMenu
        DebugOverlay.install(on: window)
        #else
        // no-op
        #endif
    }
}
```

Плохо:

```swift
// App target
#if DebugMenu
import DebugOverlay
DebugOverlay.install(on: window)
#endif
```

---

## 14. Traits должны быть additive

Trait должен добавлять возможности, а не менять смысл уже существующего API.

Хорошо:

```txt
FirebaseAnalyticsAdapter
AmplitudeAnalyticsAdapter
PreviewFixtures
DebugMenu
```

Плохо:

```txt
UseFirebaseAnalytics
UseAmplitudeAnalytics
```

если эти traits взаимоисключающие.

Почему: traits объединяются по dependency graph. Если один потребитель включает `TraitA`, а другой включает `TraitB`, package может собраться с обоими traits одновременно. Поэтому package должен оставаться валидным при разных комбинациях traits.

Для взаимоисключающих вариантов лучше использовать отдельные targets и DI:

```txt
CoreDataStorageAdapter
RealmStorageAdapter
```

А выбор реализации делать в composition root:

```swift
let storage: StorageClient = CoreDataStorageClient(...)
```

---

## 15. Traits — не runtime feature flags

Trait — это compile-time switch.

Он подходит для:

```txt
optional SDK adapters
preview fixtures
debug tooling
experimental APIs
strict migration modes
conditional dependencies
```

Он не подходит для:

```txt
A/B tests
remote config
rollout на 5% пользователей
персонализация под пользователя
фичи, которые надо включать без пересборки приложения
```

Для runtime-флагов нужны отдельные механизмы:

```txt
Remote Config
LaunchDarkly
Firebase Remote Config
собственная FeatureFlags-система
server-side flags
```

---

## 16. PreviewFixtures trait

Пример полезного trait для SwiftUI previews:

```swift
#if PreviewFixtures
public extension Product {
    static let previewPhone = Product(
        id: .init(rawValue: "preview-phone"),
        title: "iPhone Preview",
        price: .init(amount: 999, currency: "EUR")
    )
}
#endif
```

Это позволяет не засорять production API моками, но удобно использовать данные в previews.

Если test helpers нужны постоянно и много где, иногда лучше отдельный target:

```txt
ProductDomain
ProductDomainTestSupport
```

Trait хорош, если helpers должны быть опциональным API того же package.

---

## 17. StrictLegacyDeprecations trait

Trait можно использовать для “жёстких” миграций.

В обычной сборке API deprecated:

```swift
@available(*, deprecated, message: "Use NewCheckoutFlow instead.")
public enum OldCheckoutFlow {}
```

В строгом режиме — unavailable:

```swift
#if StrictLegacyDeprecations
@available(*, unavailable, message: "Use NewCheckoutFlow instead.")
#else
@available(*, deprecated, message: "Use NewCheckoutFlow instead.")
#endif
public enum OldCheckoutFlow {}
```

В CI можно включить strict trait и заранее увидеть места, которые надо мигрировать.

---

## 18. CI для traits

Код под `#if SomeTrait` легко забыть протестировать.

Минимальная матрица:

```bash
# обычная конфигурация
swift test

# проверка, что default traits не обязательны
swift test --disable-default-traits

# проверка всех optional API
swift test --enable-all-traits

# production/internal комбинация
swift test --traits defaults,DebugMenu,AnalyticsIntegration
```

Если trait добавляет optional dependency, CI должен хотя бы один раз собирать package с этим trait.

---

## 19. Когда использовать SPM, а когда достаточно папок

SPM хорошо использовать для:

```txt
Core / Shared modules
Domain modules
крупных features
крупных screens / flows
Design System
Networking
Storage
Analytics
Authorization
Payment
Onboarding
```

Особенно если:

```txt
много разработчиков
много экранов
есть несколько app targets
есть white-label
есть переиспользуемые модули
нужно изолированное тестирование
нужно разграничивать ownership
```

Не стоит делать отдельный SPM target для каждой кнопки.

Плохо:

```txt
LikeButtonFeature
OpenModalFeature
CloseModalFeature
ProductTitleComponent
ProductImageComponent
```

Лучше:

```txt
ProductDetailsScreen
CatalogScreen
CartFeature
CheckoutFlow
ProductDomain
CoreUI
```

Для маленького проекта можно начать с папок:

```txt
App/
Screens/
Features/
Domain/
Core/
```

И постепенно выносить в SPM:

```txt
CoreUI
CoreNetworking
ProductDomain
CartDomain
крупные Features
крупные Flows
```

---

## 20. Практические правила

1. **SPM targets — для настоящих архитектурных границ.**
   Если нарушение зависимости должно быть невозможно на уровне компилятора, делай target.

2. **Public API должен быть маленьким.**
   Не делай `public` всё подряд. В Swift это аналог бездумного `export *`.

3. **Facade лучше случайных public-типов.**
   Предпочтительно иметь `FeatureName.make...`, `ScreenName.make...`, `Factory`, `Builder` или явный public view.

4. **App target — composition root.**
   Он собирает зависимости, навигацию и конкретные реализации.

5. **Domain не знает о UI/features/screens.**
   `ProductDomain` не должен импортировать `AddToCartFeature` или `ProductDetailsScreen`.

6. **Features не должны импортировать sibling features без необходимости.**
   Для взаимодействия используй interface targets, протоколы, DI, coordinator или app composition.

7. **Core не должен содержать бизнес.**
   `CoreUI.PrimaryButton` — хорошо. `CoreUI.ProductCard` — плохо.

8. **Traits — только для compile-time capabilities.**
   Не используй traits как замену targets, runtime feature flags или DI.

9. **Traits должны быть additive.**
   Не проектируй traits как взаимоисключающие режимы.

10. **`#if` держи внутри модуля.**
    App-код должен работать через стабильный facade.

---

## 21. Рекомендуемая стартовая структура

Для среднего iOS-приложения хороший старт:

```txt
App/
  FSDDemoApp.swift
  AppCoordinator.swift
  AppContainer.swift

Packages/
  AppModules/
    Package.swift
    Sources/
      CoreUI/
      CoreDesignSystem/
      CoreNetworking/
      CoreStorage/
      CoreAnalytics/

      ProductDomain/
      CartDomain/
      UserDomain/
      OrderDomain/

      AddToCartFeature/
      ApplyPromoCodeFeature/
      LoginFeature/

      ProductCardComponent/
      CartSummaryComponent/

      CatalogScreen/
      ProductDetailsScreen/
      CartScreen/
      CheckoutFlow/
```

Если проект растёт, можно разделить на несколько packages:

```txt
Packages/
  CorePackage/
  DomainPackage/
  FeaturesPackage/
  ScreensPackage/
```

Но часто один package с большим количеством targets удобнее: проще управлять `package` access modifier и внутренними зависимостями.

---

## 22. Короткая формула

```txt
Папки — для локальной организации.
SPM targets — для compile-time архитектурных границ.
Swift public API — аналог index.ts.
package access — внутренний API большого package.
traits — опциональные compile-time возможности.
App target — место, где всё собирается вместе.
```

Главная цель — не “сделать много модулей”, а добиться того, чтобы изменение одной feature не расползалось по проекту, а неправильные зависимости ловились компилятором.
