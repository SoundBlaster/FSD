# SPM As The Foundation For FSD-Like Architecture In iOS

Feature-Sliced Design was created in the frontend ecosystem, but the same core
ideas map well to iOS:

- organize code by product meaning, not technical file type;
- keep dependency direction explicit;
- expose small public APIs;
- compose higher-level flows from lower-level domain and infrastructure modules;
- avoid direct coupling between sibling features.

In iOS, Swift Package Manager can make these rules stronger than folder
conventions alone. A folder can suggest a boundary. An `SPM target` can enforce
one at compile time.

This document describes how to map FSD concepts to Swift, SwiftUI, and Swift
Package Manager.

---

## 1. How FSD Maps To iOS

Classic web FSD layers:

```text
app
pages
widgets
features
entities
shared
```

One practical iOS mapping:

```text
App
Screens / Flows
Compositions / Components
Features
Domain / Entities
Core / Shared
```

Dependency direction:

```text
App
  -> Screens / Flows
      -> Features
      -> Domain / Entities
      -> Core / Shared
```

Example modules:

```text
App
ProductListScreen
ProductDetailsScreen
AddToCartFeature
ApplyPromoCodeFeature
ProductDomain
CartDomain
CoreUI
CoreNetworking
CorePersistence
```

The exact names can differ. The important part is the direction:

```text
screen -> feature -> domain -> core
```

Lower layers must not know about higher layers.

In iOS, the word `widgets` should be used carefully because it can be confused
with WidgetKit. Often clearer names are `Components`, `Compositions`, `Blocks`,
`FeatureUI`, `Screens`, or `Flows`.

---

## 2. SPM Target As An Architecture Boundary

A folder does not prevent wrong imports. An SPM target does.

If `ProductDomain` does not depend on `AddToCartFeature` in `Package.swift`, code
inside `ProductDomain` cannot do this:

```swift
import AddToCartFeature
```

This turns the FSD rule "dependencies go only downward" into a compile-time
constraint.

Example structure:

```text
AppModules/
  Package.swift
  Sources/
    ProductListScreen/
    ProductDetailsScreen/
    AddToCartFeature/
    ProductDomain/
    CartDomain/
    CoreUI/
    CoreNetworking/
  Tests/
    AddToCartFeatureTests/
    ProductDomainTests/
```

Example `Package.swift`:

> The example versions (`swift-tools-version` and minimum iOS version) are
> illustrative. Real projects should align them with the current Xcode, Swift
> toolchain, and app deployment target.

```swift
// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "AppModules",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "ProductListScreen", targets: ["ProductListScreen"]),
        .library(name: "ProductDetailsScreen", targets: ["ProductDetailsScreen"]),
        .library(name: "AddToCartFeature", targets: ["AddToCartFeature"]),
        .library(name: "ProductDomain", targets: ["ProductDomain"]),
        .library(name: "CartDomain", targets: ["CartDomain"]),
        .library(name: "CoreUI", targets: ["CoreUI"]),
        .library(name: "CoreNetworking", targets: ["CoreNetworking"])
    ],
    targets: [
        .target(
            name: "ProductListScreen",
            dependencies: [
                "ProductDomain",
                "AddToCartFeature",
                "CoreUI"
            ]
        ),
        .target(
            name: "ProductDetailsScreen",
            dependencies: [
                "ProductDomain",
                "AddToCartFeature",
                "CoreUI"
            ]
        ),
        .target(
            name: "AddToCartFeature",
            dependencies: [
                "ProductDomain",
                "CartDomain",
                "CoreNetworking",
                "CoreUI"
            ]
        ),
        .target(
            name: "ProductDomain",
            dependencies: []
        ),
        .target(
            name: "CartDomain",
            dependencies: []
        ),
        .target(
            name: "CoreUI",
            dependencies: []
        ),
        .target(
            name: "CoreNetworking",
            dependencies: []
        ),
        .testTarget(
            name: "AddToCartFeatureTests",
            dependencies: ["AddToCartFeature"]
        ),
        .testTarget(
            name: "ProductDomainTests",
            dependencies: ["ProductDomain"]
        )
    ]
)
```

With this setup:

- `ProductListScreen` can import `AddToCartFeature` and `ProductDomain`;
- `AddToCartFeature` can import `ProductDomain`, `CartDomain`, `CoreNetworking`, and `CoreUI`;
- `ProductDomain` cannot import `AddToCartFeature`;
- `CoreUI` cannot import product features or domains.

---

## 3. Swift Equivalent Of `index.ts`

In TypeScript, a slice public API is often defined through `index.ts`:

```ts
export { AddToCartButton } from './ui/add-to-cart-button';
export { useAddToCart } from './model/use-add-to-cart';
```

Swift has no direct `index.ts` equivalent. The equivalent is the **public API of
a Swift module**:

```text
public / open     visible to other modules
package           visible to targets inside the same package
internal          visible only inside the current target/module
fileprivate       visible inside one Swift file
private           visible only in the nearest lexical scope
```

External code imports a module:

```swift
import AddToCartFeature
```

It can see only the declarations that `AddToCartFeature` marks as `public` or
`open`.

Practical rule:

```text
public      only facade and required contracts
internal    default implementation
package     internal API between targets in the same package
fileprivate details shared by several types in one file
private     details of one lexical scope
```

Example target structure:

```text
Sources/
  AddToCartFeature/
    AddToCartFeature.swift       # public facade
    AddToCartButton.swift        # public or internal UI
    AddToCartAction.swift        # internal implementation
    AddToCartRequest.swift       # internal API adapter
```

Example facade:

```swift
import SwiftUI
import ProductDomain

public enum AddToCartFeature {
    public static func makeButton(product: Product) -> some View {
        AddToCartButton(product: product)
    }
}
```

Internal types remain `internal`:

```swift
struct AddToCartButton: View {
    let product: Product

    var body: some View {
        Button("Add to cart") {
            AddToCartAction(product: product).run()
        }
    }
}

struct AddToCartAction {
    let product: Product

    func run() {
        // implementation detail
    }
}
```

This facade is the Swift analogue of `index.ts`: only the intentionally public
surface is exposed.

---

## 4. App Target As Composition Root

The main app target should be thin. Its job is to assemble the application:

- dependency injection;
- navigation graph;
- app lifecycle;
- global providers;
- concrete implementations of protocols.

`App` may import high-level screens and flows:

```swift
import SwiftUI
import ProductListScreen
import ProductDetailsScreen

@main
struct ShopApp: App {
    var body: some Scene {
        WindowGroup {
            ProductListScreen()
        }
    }
}
```

It may also connect dependencies:

```swift
let client = LiveNetworkingClient()
let repository = LiveProductRepository(client: client)

ProductListScreen(repository: repository)
```

`App` is the highest layer. It is fine for it to know about many modules. Lower
layers must not know about `App`.

---

## 5. Screens / Flows

`Screens` and `Flows` are the iOS analogue of FSD `pages`.

Examples:

```text
ProductListScreen
ProductDetailsScreen
CheckoutFlow
ProfileScreen
SettingsScreen
```

A screen/flow can import:

```text
Features
Domain / Entities
Core / Shared
```

It must not be imported by lower layers.

Example public API for a screen module:

```swift
import SwiftUI
import ProductDomain
import AddToCartFeature
import CoreUI

public struct ProductListScreen: View {
    @State private var products: [Product]

    public init(products: [Product] = []) {
        _products = State(initialValue: products)
    }

    public var body: some View {
        List(products) { product in
            ProductRow(product: product) {
                AddToCartFeature.makeButton(product: product)
            }
        }
    }
}
```

For complex navigation, use `Flow` naming:

```text
CheckoutFlow
OnboardingFlow
AuthenticationFlow
```

A flow can coordinate several screens and features while keeping lower modules
independent.

---

## 6. Features

A feature is a user action with business meaning.

Good names:

```text
AddToCartFeature
ApplyPromoCodeFeature
ChangeEmailFeature
ToggleFavoriteFeature
SubmitReviewFeature
```

Bad names:

```text
ButtonFeature
ModalFeature
TapHandlerFeature
HelperFeature
```

A feature may depend on `Domain` and `Core`:

```swift
import ProductDomain
import CartDomain
import CoreNetworking
import CoreUI
```

But a feature should not depend on a screen:

```swift
// Bad
import ProductDetailsScreen
```

If two features must interact, prefer connecting them through a contract or
through `App`/Coordinator composition rather than importing one implementation
directly into the other.

---

## 7. Domain / Entities

Domain modules describe business entities and domain logic.

Examples:

```text
ProductDomain
CartDomain
UserDomain
OrderDomain
InvoiceDomain
```

Example:

```swift
public struct Product: Identifiable, Equatable, Sendable {
    public let id: ProductID
    public let title: String
    public let price: Money

    public init(id: ProductID, title: String, price: Money) {
        self.id = id
        self.title = title
        self.price = price
    }
}

public struct ProductID: Hashable, Sendable {
    public let rawValue: UUID

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}
```

`ProductDomain` should not know about:

```text
AddToCartFeature
ProductDetailsScreen
CoreUI.ProductCard
App
```

Domain is a lower layer. It should be as stable as possible.

---

## 8. Core / Shared

Core modules are infrastructure without product business logic.

Examples:

```text
CoreUI
CoreNetworking
CorePersistence
CoreAnalytics
CoreLogging
CoreLocalization
CoreDesignSystem
```

`CoreUI` may contain:

```text
PrimaryButton
TextFieldStyle
LoadingView
EmptyStateView
DesignTokens
```

`CoreUI` should not contain:

```text
ProductCard
CartSummary
OrderStatusBadge
```

`ProductCard` knows about the business entity `Product`, so it belongs in
`ProductUI`, `ProductCardComponent`, a screen module, or another module above
`Domain`.

---

## 9. Interface Target + Implementation Target

Sometimes a feature needs to depend on another feature's contract, but not on
its implementation.

Split the target into interface and implementation:

```text
AuthFeatureInterface
AuthFeature
CheckoutFlow
```

Dependency direction:

```text
CheckoutFlow -> AuthFeatureInterface
AuthFeature  -> AuthFeatureInterface
App          -> AuthFeature + CheckoutFlow
```

`CheckoutFlow` depends on `AuthFeatureInterface`, not on `AuthFeature`:

```swift
import AuthFeatureInterface

public struct CheckoutFlow: View {
    private let sessionProvider: AuthSessionProviding

    public init(sessionProvider: AuthSessionProviding) {
        self.sessionProvider = sessionProvider
    }

    public var body: some View {
        // uses only the contract
    }
}
```

Contract:

```swift
public protocol AuthSessionProviding {
    var currentSession: AuthSession? { get }
}

public struct AuthSession: Sendable {
    public let userID: String
}
```

`App` connects the concrete implementation:

```swift
import AuthFeature
import CheckoutFlow

let authService = LiveAuthService()
CheckoutFlow(sessionProvider: authService)
```

This helps preserve the rule: a feature should not directly import a sibling
feature implementation.

---

## 10. `package` Access Modifier

The `package` access modifier is useful when one Swift package contains many
targets.

```text
public      external package/module API
package     visible only inside one Swift package
internal    visible only inside one target/module
fileprivate visible inside one Swift file
private     local detail of the nearest lexical scope
```

Example:

```swift
package struct ProductMapper {
    package func map(_ dto: ProductDTO) -> Product {
        Product(
            id: ProductID(rawValue: dto.id),
            title: dto.title,
            price: Money(cents: dto.priceCents)
        )
    }
}
```

Targets inside `AppModules` can use this, but external package consumers cannot
see it as public API.

Practical meaning:

- keep `public` small and stable;
- use `package` for internal integration between targets;
- keep `internal` for implementation inside one target.

---

## 11. Resources Inside SPM Modules

An SPM target can own its resources:

```swift
.target(
    name: "ProductDetailsScreen",
    dependencies: ["ProductDomain", "CoreUI"],
    resources: [
        .process("Resources")
    ]
)
```

Example layout:

```text
Sources/
  ProductDetailsScreen/
    ProductDetailsScreen.swift
    Resources/
      product-placeholder.imageset/
      Localizable.xcstrings
```

Usage:

```swift
Image("product-placeholder", bundle: .module)
```

or:

```swift
Text("product.details.title", bundle: .module)
```

This keeps assets and localization near the module that owns them.

---

## 12. Traits In SwiftPM

Traits are compile-time options for Swift packages.

Do not use traits as the foundation of the architecture. The architecture
foundation is targets.

```text
SPM target = architecture boundary
trait      = optional capability inside a package
```

Good uses for traits:

```text
PreviewFixtures
StrictLegacyDeprecations
InternalDiagnostics
ExperimentalSearch
```

Bad uses:

```text
ProductFeatureTrait
CartFeatureTrait
CheckoutFlowTrait
```

Those should be targets, not traits.

---

## 13. Traits Example In Package.swift

The syntax can differ slightly by SwiftPM version, but conceptually it looks
like this:

> The `swift-tools-version` and `.iOS(...)` values below are illustrative. Align
> them with the repository's project and CI settings.

```swift
// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "AppModules",
    platforms: [
        .iOS(.v17)
    ],
    traits: [
        "PreviewFixtures",
        "StrictLegacyDeprecations",
        "InternalDiagnostics"
    ],
    products: [
        .library(name: "ProductDomain", targets: ["ProductDomain"]),
        .library(name: "ProductListScreen", targets: ["ProductListScreen"])
    ],
    targets: [
        .target(
            name: "ProductDomain",
            dependencies: []
        ),
        .target(
            name: "ProductListScreen",
            dependencies: ["ProductDomain", "CoreUI"]
        ),
        .target(
            name: "CoreUI",
            dependencies: []
        )
    ]
)
```

In code:

```swift
#if PreviewFixtures
public extension Product {
    static let preview = Product(
        id: ProductID(rawValue: UUID()),
        title: "Preview product",
        price: Money(cents: 1999)
    )
}
#endif
```

Main rule: do not spread `#if` across app code. Conditional compilation should
be hidden inside a module facade.

Good:

```swift
public enum ProductFixtures {
    public static var preview: Product {
        #if PreviewFixtures
        Product.preview
        #else
        Product(id: ProductID(rawValue: UUID()), title: "", price: .zero)
        #endif
    }
}
```

Bad:

```swift
// Bad: app code knows about trait details
#if PreviewFixtures
Product.preview
#else
Product(...)
#endif
```

---

## 14. Traits Must Be Additive

A trait should add capability, not change the meaning of an existing API.

Good:

```text
PreviewFixtures adds preview data
InternalDiagnostics adds diagnostics API
StrictLegacyDeprecations makes deprecated API unavailable
```

Bad:

```text
TraitA changes Product.price from cents to dollars
TraitB changes Product.price from dollars to cents
```

This is especially dangerous if traits are mutually exclusive in your mental
model.

Why: traits are merged through the dependency graph. If one consumer enables
`TraitA` and another enables `TraitB`, the package may be built with both traits
at the same time. The package must remain valid under different trait
combinations.

For mutually exclusive variants, prefer separate targets and dependency
injection:

```text
LivePricingService
MockPricingService
ExperimentalPricingService
```

Choose the implementation in the composition root:

```swift
let pricing: PricingService = LivePricingService()
```

---

## 15. Traits Are Not Runtime Feature Flags

A trait is a compile-time switch.

It is suitable for:

```text
preview helpers
test fixtures
internal diagnostics
compile-time strictness
optional package capabilities
```

It is not suitable for:

```text
remote config
5% rollout
per-user personalization
features that must be enabled without rebuilding the app
```

Runtime flags need separate mechanisms:

```text
Remote Config
LaunchDarkly
Firebase Remote Config
custom FeatureFlags system
server-driven configuration
```

---

## 16. `PreviewFixtures` Trait

Useful trait for SwiftUI previews:

```swift
#if PreviewFixtures
public enum ProductPreviewFixtures {
    public static let sample = Product(
        id: ProductID(rawValue: UUID()),
        title: "Sample product",
        price: Money(cents: 1299)
    )
}
#endif
```

This avoids polluting production API with mocks while keeping preview data easy
to use.

If test helpers are permanent and widely used, a separate target can be better:

```text
ProductDomain
ProductDomainTestSupport
```

A trait is good when helpers should be optional API of the same package.

---

## 17. `StrictLegacyDeprecations` Trait

A trait can help with strict migrations.

In normal builds, an API can be deprecated:

```swift
@available(*, deprecated, message: "Use ProductID instead.")
public typealias LegacyProductID = String
```

In strict mode, it can become unavailable:

```swift
#if StrictLegacyDeprecations
@available(*, unavailable, message: "Use ProductID instead.")
#else
@available(*, deprecated, message: "Use ProductID instead.")
#endif
public typealias LegacyProductID = String
```

CI can enable the strict trait and find migration points early.

---

## 18. CI For Traits

Code under `#if SomeTrait` is easy to forget to test.

Minimal matrix:

```bash
# normal configuration
swift test --package-path AppModules

# verify default traits are not required
swift test --package-path AppModules --disable-default-traits

# verify optional API
swift test --package-path AppModules --traits PreviewFixtures

# production/internal combination
swift test --package-path AppModules --traits StrictLegacyDeprecations
```

If a trait adds an optional dependency, CI should build the package with that
trait at least once.

---

## 19. When To Use SPM And When Folders Are Enough

SPM is useful for:

- large features;
- large screens / flows;
- domain modules reused by several apps;
- shared infrastructure;
- code with independent tests;
- boundaries that must be impossible to violate at compile time.

Especially when:

- many developers work in the project;
- the app has many screens;
- there are several app targets;
- there is white-labeling;
- there are reusable modules;
- isolated testing is important;
- ownership boundaries must be explicit.

Do not create a separate SPM target for every button.

Bad:

```text
PrimaryButtonTarget
ProductTitleTarget
ProductImageTarget
```

Better:

```text
CoreUI
ProductDomain
ProductCardComponent
```

For a small project, start with folders:

```text
App/
  app/
  pages/
  widgets/
  features/
  entities/
  shared/
```

Then gradually extract to SPM:

```text
large Features
large Flows
reused Domain modules
shared Core infrastructure
```

---

## 20. Practical Rules

1. **Use SPM targets for real architecture boundaries.**
   If dependency violations should be impossible at compiler level, make a target.

2. **Keep public API small.**
   Do not make everything `public`. In Swift, that is the equivalent of careless
   `export *`.

3. **Prefer facades over random public types.**
   Prefer `FeatureName.make...`, `ScreenName.make...`, `Factory`, `Builder`, or
   an explicit public view.

4. **Keep the app target as the composition root.**
   It assembles dependencies, navigation, and concrete implementations.

5. **Domain does not know about UI, features, or screens.**
   `ProductDomain` must not import `AddToCartFeature` or `ProductDetailsScreen`.

6. **Features should not import sibling features unless there is a deliberate contract.**
   Use interface targets, protocols, DI, coordinators, or app composition.

7. **Core must not contain business logic.**
   `CoreUI.PrimaryButton` is good. `CoreUI.ProductCard` is bad.

8. **Traits are only for compile-time capabilities.**
   Do not use traits as a replacement for targets, runtime feature flags, or DI.

9. **Traits must be additive.**
   Do not design traits as mutually exclusive modes.

10. **Keep `#if` inside modules.**
    App code should work through a stable facade.

---

## 21. Recommended Starting Structure

Good starting point for a medium iOS app:

```text
App/
  ShopApp.swift

Packages/
  AppModules/
    Package.swift
    Sources/
      ProductListScreen/
      ProductDetailsScreen/
      CheckoutFlow/

      AddToCartFeature/
      ApplyPromoCodeFeature/
      ToggleFavoriteFeature/

      ProductDomain/
      CartDomain/
      UserDomain/

      CoreUI/
      CoreNetworking/
      CorePersistence/
      CoreAnalytics/

    Tests/
      ProductDomainTests/
      AddToCartFeatureTests/
```

If the project grows, split it into several packages:

```text
Packages/
  DomainModules/
  FeatureModules/
  ScreenModules/
  CoreModules/
```

Often one package with many targets is more convenient: it makes `package`
access easier to use and internal dependencies easier to manage.

---

## 22. Short Formula

Folders are for local organization.

SPM targets are for compile-time architecture boundaries.

Swift public API is the analogue of `index.ts`.

`package` access is internal API for a large package.

Traits are optional compile-time capabilities.

The app target is where everything is assembled.

The main goal is not to "create many modules". The goal is to make sure a change
to one feature does not spread through the project and incorrect dependencies
are caught by the compiler.
