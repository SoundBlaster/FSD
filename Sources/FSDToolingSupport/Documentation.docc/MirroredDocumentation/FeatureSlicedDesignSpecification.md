# Feature-Sliced Design Specification

> Source: `specs/fsd.md`

`Feature-Sliced Design`, or `FSD`, is an architectural methodology for
organizing frontend and UI application code. The official FSD documentation
describes it as a set of rules and conventions for code structure whose goal is
to make a project easier to understand and more resilient to changing business
requirements.

The methodology is not tied to `React`, `Vue`, a specific `state manager`, or a
specific programming language. It can be applied to `web`, `mobile`, and
`desktop UI` applications when the project is an application rather than a
library.

The main idea is simple: structure the project by meaning, responsibility, and
business domain instead of by technical file type.

A common technical structure often looks like this:

```text
src/
  components/
  hooks/
  services/
  store/
  utils/
  types/
```

That layout is convenient at the beginning. As the project grows, the logic of a
single user story becomes spread across the whole codebase: a component in
`components`, a request in `services`, types in `types`, state in `store`, and a
helper in `utils`. Changing one feature then requires jumping through many
unrelated folders.

FSD proposes a different structure:

```text
src/
  app/
  pages/
  widgets/
  features/
  entities/
  shared/
```

The project is organized around pages, large composition blocks, user actions,
business entities, and shared infrastructure.

---

## Three Core Concepts: `layers`, `slices`, `segments`

FSD has three organization levels:

```text
Layer -> Slice -> Segment
```

Example:

```text
features/
  add-to-cart/
    ui/
    model/
    api/
    index.ts
```

In this example:

- `features` is the `layer`;
- `add-to-cart` is the `slice`, meaning an independent unit of business functionality;
- `ui`, `model`, and `api` are `segments`, meaning responsibility groups inside the slice.

The official documentation describes this hierarchy directly: layers are
standardized, slices divide a layer by business domains, and segments group code
by responsibility.

---

## FSD Layers

The current `FSD v2.1` structure usually looks like this:

```text
src/
  app/
  pages/
  widgets/
  features/
  entities/
  shared/
```

The documentation also mentions a `processes` layer, but it is considered
`deprecated` and should not be used in new projects. Its responsibilities should
usually move into `features` and `app`.

### `app` - application initialization

The `app` layer owns everything that starts the application and connects it into
one whole:

```text
app/
  providers/
  router/
  store/
  styles/
  entrypoint/
```

Typical contents:

```text
app/
  providers/        # ThemeProvider, QueryClientProvider, Redux Provider
  router/           # routing setup
  store/            # global store configuration
  styles/           # global styles
  analytics/        # global analytics
```

`app` is the highest layer. It may import everything below it: `pages`,
`widgets`, `features`, `entities`, and `shared`.

---

### `pages` - pages or screens

`pages` is the application screen layer:

```text
pages/
  home/
  product-details/
  cart/
  checkout/
  profile/
```

One slice in `pages` usually corresponds to one page, screen, or `route`:

```text
pages/product-details/
  ui/
    product-details-page.tsx
  api/
    get-product-details.ts
  model/
    use-product-details.ts
  index.ts
```

A key idea in `FSD v2.1` is `pages first`. Start by keeping most UI and logic
inside the page. Extract to `features`, `entities`, and `widgets` only when
there is a real reason: reuse, independent business meaning, or a need to
separate a large composition block.

This is an important shift. Teams used to split everything into `entities` and
`features` too early, creating dozens of tiny slices. The current approach is
simpler: do not extract code prematurely.

---

### `widgets` - large standalone interface blocks

`widgets` are large UI blocks that may be composed from entities, features, and
shared components:

```text
widgets/
  header/
  sidebar/
  product-card/
  cart-summary/
  user-profile-card/
```

Example:

```text
widgets/product-card/
  ui/
    product-card.tsx
  model/
    use-product-card.ts
  index.ts
```

A widget can compose lower layers:

```ts
import { ProductPrice, ProductImage } from '@/entities/product';
import { AddToCartButton } from '@/features/add-to-cart';
import { Card } from '@/shared/ui/card';
```

A `widget` is a composition block. It does not have to be a "dumb" UI component.
In the current approach, a widget may own local logic if that logic is not needed
outside the widget.

---

### `features` - user actions

`features` are not "any functionality". They are user actions that provide
business value:

```text
features/
  add-to-cart/
  remove-from-cart/
  login/
  logout/
  like-post/
  change-email/
  apply-promo-code/
```

A good way to recognize a `feature`: its name can often be expressed as a verb.

Examples:

- `add-to-cart`
- `like-post`
- `send-comment`
- `change-password`
- `upload-avatar`

A `feature` may contain UI, state, requests, and validation:

```text
features/add-to-cart/
  ui/
    add-to-cart-button.tsx
  model/
    use-add-to-cart.ts
  api/
    add-to-cart.ts
  index.ts
```

A feature may import `entities` and `shared` because they are lower layers:

```ts
import type { Product } from '@/entities/product';
import { Button } from '@/shared/ui/button';
```

But a feature must not import another feature directly:

```ts
// Bad
import { ApplyDiscount } from '@/features/apply-discount';
```

If two features must be used together, compose them above, usually in a `widget`
or `page`.

---

### `entities` - business entities

`entities` are key objects of the product domain:

```text
entities/
  user/
  product/
  order/
  cart/
  comment/
  invoice/
```

If a `feature` is an action, an `entity` is a noun.

Examples:

- `user`
- `product`
- `order`
- `invoice`
- `task`

An `entity` can contain:

```text
entities/product/
  model/
    product.ts
    product-schema.ts
  ui/
    product-price.tsx
    product-image.tsx
  api/
    get-product.ts
  index.ts
```

An entity can contain UI that represents the entity, but it must not know about
higher-level user actions.

This is fine:

```ts
import { ProductPrice } from '@/entities/product';
```

This is not fine:

```ts
// Bad: entity imports a feature
import { AddToCartButton } from '@/features/add-to-cart';
```

Compose that higher:

```tsx
import type { Product } from '@/entities/product';
import { ProductPrice } from '@/entities/product';
import { AddToCartButton } from '@/features/add-to-cart';

export function ProductCard({ product }: { product: Product }) {
  return (
    <>
      <ProductPrice price={product.price} />
      <AddToCartButton productId={product.id} />
    </>
  );
}
```

The official FAQ frames the difference this way: an `entity` is a real concept
the application works with; a `feature` is an interaction that gives the user
value and usually works with entities.

---

### `shared` - shared infrastructure

`shared` is the lowest layer. It must not contain product-specific business
logic.

Typical contents:

```text
shared/
  ui/
  api/
  config/
  lib/
  assets/
  i18n/
```

Examples:

```text
shared/ui/button
shared/ui/modal
shared/api/client
shared/config/env
shared/lib/date
shared/lib/currency
shared/assets/icons
```

`shared/ui/Button` should not know that it is used in a cart. `shared/lib/date`
should not know that it formats an order date. `shared/api/client` should not
know which product, user, or comment is being loaded.

The documentation describes `shared` as the foundation of the app: the place for
external world integration, backend transport, third-party libraries,
environment, UI kit, internal libraries, and configuration. `shared` and `app`
are not split into slices: `shared` has no business domains, and `app` connects
the whole application.

---

## Main Import Rule

The most important FSD rule:

```text
dependencies go only from higher layers to lower layers
```

Imports go only downward:

- `pages` may import `widgets`, `features`, `entities`, `shared`;
- `widgets` may import `features`, `entities`, `shared`;
- `features` may import `entities`, `shared`;
- `entities` may import `shared`;
- `shared` must not import any FSD layer.

Do not import upward:

```ts
// Bad: entity imports feature
import { AddToCartButton } from '@/features/add-to-cart';
```

Do not import sibling slices on the same layer directly:

```ts
// Bad: features/add-to-cart imports features/apply-discount
import { ApplyDiscount } from '@/features/apply-discount';
```

The official rule is: a module inside a slice may import other slices only when
those slices are on strictly lower layers. This protects the project from
cyclic dependencies and accidental coupling between features.

---

## Public API: Enter a Slice Only Through `index.ts`

Every slice should expose a public API. In TypeScript projects this is usually
`index.ts`.

Example:

```text
entities/product/
  model/
    product.ts
  ui/
    product-price.tsx
  index.ts
```

Correct external import:

```ts
import { ProductPrice, type Product } from '@/entities/product';
```

Incorrect external import:

```ts
// Bad: external code reaches into slice internals
import { ProductPrice } from '@/entities/product/ui/product-price';
```

Why it matters: the internal slice structure can change without causing a
cascading refactor across the whole project.

Today:

```text
entities/product/ui/product-price.tsx
```

Tomorrow:

```text
entities/product/ui/price/product-price.tsx
```

If external code imports through `@/entities/product`, only `index.ts` needs to
change.

The documentation describes the `public API` as a contract between a group of
modules and the code that uses it. It works like a gate that exposes only the
objects intended for external use.

---

## Do Not Use `export *` Blindly

Bad example:

```ts
export * from './model/product-store';
export * from './api/internal-product-api';
export * from './lib/normalize-product';
```

This API hides nothing. It simply dumps the slice internals outside. That breaks
encapsulation: external code starts depending on implementation details.

Prefer explicit exports:

```ts
export { ProductPrice } from './ui/product-price';
export type { Product } from './model/product';
```

The official documentation also warns that `wildcard re-export` makes the API
harder to discover and can accidentally expose module internals, making
refactoring harder.

---

## Segments Inside a Slice

Common segments:

```text
ui/
model/
api/
lib/
config/
```

### `ui`

Everything related to rendering:

```text
ui/
  add-to-cart-button.tsx
  product-card.tsx
  product-price.tsx
```

### `model`

State, business logic, schemas, `selectors`, `stores`:

```text
model/
  product.ts
  product-schema.ts
  use-product.ts
  selectors.ts
```

### `api`

Requests, `DTO`, mappers:

```text
api/
  get-product.ts
  update-product.ts
  product-dto.ts
```

### `lib`

Helper functions local to this slice:

```text
lib/
  normalize-product.ts
  calculate-discount.ts
```

### `config`

Flags and configuration:

```text
config/
  product-status.ts
  product-limits.ts
```

Important nuance: FSD recommends naming segments by purpose, not by the technical
nature of files. `ui`, `model`, `api`, `lib`, and `config` are better than
`components`, `hooks`, `types`, and `utils`. The documentation explicitly calls
`components`, `hooks`, and `types` poor segment names because they communicate
less about why the code exists.

---

## Online Store Structure Example

Imagine a store application:

```text
src/
  app/
    providers/
    router/
    entrypoint/

  pages/
    catalog/
      ui/
        catalog-page.tsx
      model/
        use-catalog.ts
      index.ts

    product-details/
      ui/
        product-details-page.tsx
      index.ts

    cart/
      ui/
        cart-page.tsx
      index.ts

  widgets/
    product-card/
      ui/
        product-card.tsx
      index.ts

    cart-summary/
      ui/
        cart-summary.tsx
      index.ts

  features/
    add-to-cart/
      ui/
        add-to-cart-button.tsx
      model/
        add-to-cart.ts
      api/
        add-to-cart.ts
      index.ts

    remove-from-cart/
      ui/
        remove-from-cart-button.tsx
      index.ts

    apply-promo-code/
      ui/
        promo-code-form.tsx
      model/
        apply-promo-code.ts
      index.ts

  entities/
    product/
      model/
        product.ts
      ui/
        product-price.tsx
        product-image.tsx
      api/
        get-product.ts
      index.ts

    cart/
      model/
        cart.ts
      ui/
        cart-item-row.tsx
      index.ts

  shared/
    ui/
      button/
      input/
      modal/
    api/
      client.ts
    lib/
      date.ts
      money.ts
```

Composition example:

```tsx
import type { Product } from '@/entities/product';
import { ProductImage, ProductPrice } from '@/entities/product';
import { AddToCartButton } from '@/features/add-to-cart';
import { Card } from '@/shared/ui/card';

export function ProductCard({ product }: { product: Product }) {
  return (
    <Card>
      <ProductImage src={product.imageUrl} alt={product.title} />
      <ProductPrice price={product.price} />
      <AddToCartButton productId={product.id} />
    </Card>
  );
}
```

This is good FSD code because the widget composes lower layers:

```text
widgets -> entities
widgets -> features
widgets -> shared
```

Do not do this:

```ts
// Bad: entity imports feature, meaning lower layer imports higher layer
import { AddToCartButton } from '@/features/add-to-cart';
```

---

## How To Decide Where Code Belongs

Use this checklist:

1. Is the code used only by one route or screen? Keep it in `pages`.
2. Is it a large reusable UI composition? Use `widgets`.
3. Is it a user action with business value? Use `features`.
4. Is it a business domain object? Use `entities`.
5. Is it generic infrastructure without business meaning? Use `shared`.
6. Are imports going only downward through the layer hierarchy?
7. Are external imports going through slice public APIs?

Do not extract by default. Extract when the boundary solves a real problem:
reuse, ownership, independent business meaning, or a large composition boundary.

---

## How To Develop New Functionality In FSD Style

### 1. Start From The Page

If a feature exists only on one screen, keep it inside that page first:

```text
pages/product-details/
  ui/
  model/
  api/
```

This keeps related code close while the boundary is still uncertain.

### 2. Reuse Appears: Extract To `feature`

If the same user action appears in multiple places, extract it:

```text
features/add-to-favorites/
  ui/
  model/
  api/
  index.ts
```

Example trigger: the same "Add to favorites" action is used on product details,
catalog cards, and recommendation lists.

### 3. Domain Reuse Appears: Consider `entity`

If the same business concept is needed in multiple features/pages, move the
shared domain model to `entities`:

```text
entities/favorite/
  model/
  ui/
  api/
  index.ts
```

### 4. Compose Above

Pages and widgets compose lower layers:

```text
pages/product-details -> widgets/product-card
widgets/product-card -> entities/product
widgets/product-card -> features/add-to-cart
```

---

## Where To Store API Requests

Place API calls near the behavior owner:

```text
shared/api/client.ts                     # base HTTP client, interceptors, request factory
pages/catalog/api/get-catalog.ts         # request used only by the catalog page
features/add-to-cart/api/add-to-cart.ts  # request for the add-to-cart action
entities/product/api/get-product.ts      # reusable product-related request
```

Do not put every request into `shared/api`. That folder is for transport-level
infrastructure, not product-specific business operations.

Good:

```text
shared/api/client.ts
features/login/api/login.ts
entities/user/api/get-current-user.ts
pages/dashboard/api/get-dashboard.ts
```

Bad:

```text
shared/api/login.ts
shared/api/get-product.ts
shared/api/update-cart.ts
```

If a request knows about a product, order, user, or cart, it usually belongs to
the layer that owns that behavior or domain concept.

---

## `Cross-imports` And `@x`

FSD discourages direct imports between sibling slices on the same layer. Some
FSD material mentions special cross-import public APIs such as `@x`, but this is
an advanced exception rather than the default.

Prefer composition above:

```text
features/add-to-cart
features/apply-promo-code
widgets/cart-actions        # composes both
```

Only introduce a cross-import contract when:

- the dependency is stable;
- composition above would create worse coupling;
- the public contract is intentionally designed and documented;
- reviewers understand the architectural tradeoff.

For most teams, the safer rule is: sibling slices do not import each other.

---

## FSD And Application State

FSD does not prescribe a state manager. `Redux`, `Zustand`, `Effector`, `MobX`,
`TanStack Query`, `Apollo`, local framework state, and Swift/SwiftUI state can
all be compatible with FSD.

Place state by ownership:

```text
app/store/                              # global store configuration
pages/catalog/model/use-catalog-query   # state/query needed only by catalog page
features/add-to-cart/model/             # state for the add-to-cart action
entities/cart/model/                    # state of cart as a business entity
shared/lib/storage/                     # generic persistence helpers
```

The question is not "where does state live technically?" but "who owns this
state semantically?"

Examples:

- Authentication session shared by the whole app may be initialized in `app` and
  exposed through an `entity` or `shared` contract depending on product meaning.
- Cart contents usually belong to `entities/cart`.
- A promo-code form state belongs to `features/apply-promo-code`.
- A local filter selected only on a catalog page may remain in `pages/catalog`.

---

## FSD And `React Query` / `TanStack Query`

Query libraries do not replace architecture. They solve data fetching and cache
management; FSD still decides ownership.

Good:

```text
entities/product/api/get-product.ts
entities/product/model/use-product-query.ts
features/add-to-cart/api/add-to-cart.ts
features/add-to-cart/model/use-add-to-cart-mutation.ts
```

Page-only query:

```text
pages/catalog/model/use-catalog-query.ts
```

Shared transport:

```text
shared/api/client.ts
shared/api/query-client.ts
```

Bad:

```text
shared/api/product-queries.ts
shared/api/cart-mutations.ts
```

Again: if code knows about product behavior, it is not generic shared
infrastructure.

---

## Good FSD Code Looks Like This

Good imports:

```ts
import { ProductCard } from '@/widgets/product-card';
import { AddToCartButton } from '@/features/add-to-cart';
import { ProductPrice } from '@/entities/product';
import { Button } from '@/shared/ui/button';
```

Good slice API:

```ts
// entities/product/index.ts
export type { Product } from './model/product';
export { ProductPrice } from './ui/product-price';
export { getProduct } from './api/get-product';
```

Good dependency direction:

```text
pages -> widgets -> features -> entities -> shared
```

Good extraction rule:

```text
start in pages -> extract only when reuse or a clear boundary appears
```

---

## Typical Mistakes

### Mistake 1. Creating A `feature` For Every Small Component

Bad:

```text
features/open-modal/
features/toggle-dropdown/
features/click-button/
```

These are UI mechanics, not business actions.

Better:

```text
pages/product-details/ui/
widgets/product-card/ui/
shared/ui/dropdown/
```

Create a `feature` when the action has business meaning, such as
`add-to-cart`, `login`, or `apply-promo-code`.

### Mistake 2. Putting Everything Into `shared`

Bad:

```text
shared/product-utils
shared/order-hooks
shared/user-services
```

These names contain product business concepts. They likely belong in
`entities`, `features`, `widgets`, or `pages`.

Good:

```text
shared/ui/button
shared/lib/date
shared/api/client
shared/config/env
```

### Mistake 3. Importing Slice Internals

Bad:

```ts
import { ProductPrice } from '@/entities/product/ui/product-price';
```

Good:

```ts
import { ProductPrice } from '@/entities/product';
```

### Mistake 4. A Lower Layer Knows About A Higher Layer

Bad:

```text
entities/product -> features/add-to-cart
shared/ui -> entities/user
features/login -> widgets/header
```

Good:

```text
widgets/product-card -> entities/product
widgets/product-card -> features/add-to-cart
pages/home -> widgets/header
```

### Mistake 5. Decomposing Too Early

Bad early structure:

```text
features/show-product-title
features/show-product-image
features/show-product-price
entities/product-title
entities/product-image
```

Better start:

```text
pages/product-details/
  ui/
  model/
  api/
```

Extract later when reuse and ownership become real.

---

## How To Introduce FSD Into An Existing Project

Do not rewrite the whole project at once. Introduce FSD gradually:

1. Add the FSD layers at the source root.
2. Start new screens in `pages`.
3. Move obvious domain models into `entities`.
4. Extract reusable business actions into `features`.
5. Keep generic infrastructure in `shared`.
6. Add lint rules for dependency direction.
7. Avoid moving old code unless a real change requires touching it.

This makes migration incremental and reviewable.

---

## FSD In Two Sentences

FSD is a way to organize application code by business meaning and dependency
direction instead of technical file type.

Start in `pages`, extract only when there is a real boundary, and keep imports
moving downward through `app -> pages -> widgets -> features -> entities -> shared`.