# Что такое Feature-Sliced Design

`Feature-Sliced Design`, или `FSD`, — это архитектурная методология для организации кода frontend/UI-приложений. В официальной документации `FSD` описывается как набор правил и соглашений о структуре кода, цель которого — сделать проект понятнее и устойчивее к меняющимся бизнес-требованиям.

Методология не привязана к `React`, `Vue`, конкретному `state manager`’у или языку: её можно применять к `web`, `mobile` и `desktop UI`-приложениям, если это именно приложение, а не библиотека.

Главная идея `FSD`: структурировать проект не по техническим типам файлов, а по смыслу, ответственности и бизнес-доменам.

Обычная структура часто выглядит так:

```text
src/
components/
hooks/
services/
store/
utils/
types/
```

На старте это удобно. Но когда проект растёт, логика одной пользовательской истории оказывается размазанной по всему проекту: компонент в `components`, запрос в `services`, типы в `types`, состояние в `store`, хелпер в `utils`. В итоге, чтобы изменить одну фичу, приходится прыгать по десяткам папок.

`FSD` предлагает другой подход:

```text
src/
app/
pages/
widgets/
features/
entities/
shared/
```

То есть проект организуется вокруг страниц, крупных блоков, пользовательских действий, бизнес-сущностей и общей инфраструктуры.

---

## Три базовых понятия FSD: `layers`, `slices`, `segments`

В `FSD` есть три уровня организации:

```text
Layer -> Slice -> Segment
```

Например:

```text
features/
add-to-cart/
ui/
model/
api/
index.ts
```

Здесь:

- `features` — `layer`, слой
- `add-to-cart` — `slice`, слайс, то есть самостоятельная часть бизнес-функциональности
- `ui`, `model`, `api` — `segments`, сегменты, то есть техническое разделение внутри слайса

Официальная документация описывает именно эту иерархию: слои стандартизированы, слайсы делят слой по доменам, а сегменты группируют код по техническому назначению.

---

## Слои FSD

Актуальная структура `FSD v2.1` обычно выглядит так:

```text
src/
app/
pages/
widgets/
features/
entities/
shared/
```

В документации также упоминается слой `processes`, но он считается `deprecated`, то есть его лучше не использовать в новых проектах. Текущая рекомендация — переносить его ответственность в `features` и `app`.

### `app` — инициализация приложения

Слой `app` отвечает за всё, что запускает приложение и связывает его в единое целое:

```text
app/
providers/
router/
store/
styles/
entrypoint/
```

Сюда обычно кладут:

```text
app/
providers/        # ThemeProvider, QueryClientProvider, Redux Provider
router/           # настройка роутинга
store/            # конфигурация глобального стора
styles/           # глобальные стили
analytics/        # глобальная аналитика
```

`app` — верхний слой. Он может импортировать всё, что ниже: `pages`, `widgets`, `features`, `entities`, `shared`.

---

### `pages` — страницы или экраны

`pages` — это слой экранов приложения:

```text
pages/
home/
product-details/
cart/
checkout/
profile/
```

Один слайс в `pages` обычно соответствует одной странице, экрану или `route`. Например:

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

В `FSD v2.1` важная идея — `pages first`. Это значит: сначала держи большую часть `UI` и логики внутри страницы, а в `features`, `entities` и `widgets` выноси только тогда, когда появилась реальная причина: переиспользование, самостоятельный бизнес-смысл или необходимость отделить крупный блок.

Это очень важный сдвиг. Раньше разработчики часто пытались сразу разложить всё по `entities` и `features`, из-за чего появлялись десятки микрослайсов. Сейчас подход проще: не выноси раньше времени.

---

### `widgets` — крупные самостоятельные блоки интерфейса

`widgets` — это большие `UI`-блоки, которые могут состоять из сущностей, фич и `shared`-компонентов:

```text
widgets/
header/
sidebar/
product-card/
cart-summary/
user-profile-card/
```

Примеры:

```text
widgets/product-card/
ui/
product-card.tsx
model/
use-product-card.ts
index.ts
```

Виджет может собирать внутри себя:

```ts
import { ProductPrice, ProductImage } from '@/entities/product';
import { AddToCartButton } from '@/features/add-to-cart';
import { Card } from '@/shared/ui/card';
```

То есть `widget` — это композиционный блок. Он не обязан быть «глупым» `UI`-компонентом. В актуальном подходе виджет может хранить собственную локальную логику, если эта логика не нужна за пределами виджета.

---

### `features` — пользовательские действия

`features` — это не «любая функциональность». Это действия пользователя, которые приносят бизнес-ценность:

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

Хороший способ отличить `feature`: её название часто можно выразить глаголом.

Например:

- `add-to-cart`
- `like-post`
- `send-comment`
- `change-password`
- `upload-avatar`

Внутри `feature` может быть `UI`, состояние, запросы, валидация:

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

`Feature` может импортировать `entities` и `shared`, потому что они ниже:

```ts
import { Button } from '@/shared/ui/button';
import type { ProductId } from '@/entities/product';
```

Но `feature` не должна импортировать другую `feature`:

```ts
// Плохо
import { ApplyPromoCode } from '@/features/apply-promo-code';
```

Если две `features` нужно использовать вместе, их нужно собрать выше — например, в `widget` или `page`.

---

### `entities` — бизнес-сущности

`entities` — это ключевые объекты предметной области:

```text
entities/
user/
product/
cart/
order/
article/
comment/
```

Если `feature` — это действие, то `entity` — это существительное.

Примеры:

- `user`
- `product`
- `order`
- `invoice`
- `playlist`
- `message`

Внутри `entity` можно хранить:

```text
entities/product/
model/
types.ts
selectors.ts
product-store.ts
api/
get-product.ts
ui/
product-price.tsx
product-image.tsx
lib/
format-product-title.ts
index.ts
```

`Entity` может содержать `UI`-представление сущности, но не должна знать о более высокоуровневых действиях.

Например, это нормально:

```tsx
// entities/product/ui/product-price.tsx
export function ProductPrice({ price }: Props) {
    return <span>{formatPrice(price)}</span>;
}
```

А вот это плохо:

```tsx
// entities/product/ui/product-card.tsx
import { AddToCartButton } from '@/features/add-to-cart';
// ❌ Entity не должна импортировать feature
```

Правильнее собрать это выше:

```tsx
// widgets/product-card/ui/product-card.tsx
import { ProductPrice } from '@/entities/product';
import { AddToCartButton } from '@/features/add-to-cart';

export function ProductCard({ product }) {
    return (
        <article>
            <ProductPrice price={product.price} />
            <AddToCartButton productId={product.id} />
        </article>
    );
}
```

Официальный `FAQ` формулирует разницу так: `entity` — это реальная концепция, с которой работает приложение; `feature` — это взаимодействие, которое даёт пользователю ценность и обычно работает с `entities`.

---

### `shared` — общая инфраструктура

`shared` — самый нижний слой. Он не должен содержать бизнес-логику конкретного продукта.

Туда кладут:

```text
shared/
api/
ui/
lib/
config/
routes/
i18n/
```

Примеры:

```text
shared/api/
client.ts
create-request.ts

shared/ui/
button/
modal/
input/
spinner/

shared/lib/
date/
currency/
validation/

shared/config/
env.ts
feature-flags.ts
```

`shared/ui/Button` не должен знать, что он используется в корзине. `shared/lib/date` не должен знать, что он форматирует дату заказа. `shared/api/client` не должен знать, что именно ты загружаешь — товар, пользователя или комментарий.

Документация описывает `shared` как фундамент приложения: место для соединения с внешним миром, `backend`, `third-party libraries`, `environment`, `UI kit`, внутренних библиотек и конфигурации. При этом `shared` и `app` не делятся на слайсы, потому что `shared` не содержит бизнес-доменов, а `app` объединяет всё приложение.

---

## Главное правило импортов

Самое важное правило `FSD`:

```text
app -> pages -> widgets -> features -> entities -> shared
```

Импорты идут только сверху вниз.

То есть:

- `pages` может импортировать `widgets`, `features`, `entities`, `shared`
- `widgets` может импортировать `features`, `entities`, `shared`
- `features` может импортировать `entities`, `shared`
- `entities` может импортировать `shared`
- `shared` никого из `FSD`-слоёв не импортирует

Но нельзя:

- `entities -> features`
- `features -> widgets`
- `widgets -> pages`
- `shared -> entities`

Также нельзя импортировать соседний слайс на том же слое:

```ts
// ❌ features/add-to-cart не должен импортировать features/apply-discount
import { ApplyDiscount } from '@/features/apply-discount';
```

Официальное правило звучит так: модуль внутри слайса может импортировать другие слайсы только тогда, когда они находятся на слоях строго ниже. Это защищает проект от циклических зависимостей и случайного сцепления фич между собой.

---

## Public API: вход в слайс только через `index.ts`

Каждый слайс должен иметь публичный `API`. Обычно это `index.ts`.

Например:

```text
entities/product/
model/
types.ts
ui/
product-price.tsx
index.ts
```

```ts
// entities/product/index.ts
export type { Product, ProductId } from './model/types';
export { ProductPrice } from './ui/product-price';
```

Снаружи правильно импортировать так:

```ts
import { ProductPrice, type Product } from '@/entities/product';
```

А не так:

```ts
// ❌ Плохо: внешний код залезает внутрь слайса
import { ProductPrice } from '@/entities/product/ui/product-price';
```

Зачем это нужно? Чтобы внутренняя структура слайса могла меняться без каскадного рефакторинга всего проекта.

Сегодня у тебя:

```text
entities/product/ui/product-price.tsx
```

Завтра ты перенёс компонент:

```text
entities/product/ui/price/product-price.tsx
```

Если внешний код импортирует через `@/entities/product`, ему всё равно. Нужно поправить только `index.ts`.

Документация описывает `public API` как контракт между группой модулей и кодом, который её использует; он работает как «ворота», через которые наружу выпускаются только нужные объекты.

---

## Не делай `export *` бездумно

Плохой пример:

```ts
// ❌ features/comments/index.ts
export * from './ui/comment-form';
export * from './model/store';
export * from './api/comments-api';
export * from './lib/internal-normalize-comment';
```

Такой `API` ничего не скрывает. Он просто вываливает наружу всё содержимое слайса. Это ломает инкапсуляцию: внешний код начинает зависеть от внутренних деталей.

Лучше так:

```ts
// ✅ features/comments/index.ts
export { CommentForm } from './ui/comment-form';
export { useCreateComment } from './model/use-create-comment';
```

Официальная документация также предупреждает, что `wildcard re-export` ухудшает `discoverability API` и может случайно раскрыть внутренности модуля, из-за чего рефакторинг становится сложнее.

---

## Сегменты внутри слайса

Чаще всего используются такие сегменты:

```text
ui/
model/
api/
lib/
config/
```

### `ui`

Всё, что связано с отображением:

```text
ui/
add-to-cart-button.tsx
product-card.tsx
product-price.tsx
```

### `model`

Состояние, бизнес-логика, схемы, `selectors`, `stores`:

```text
model/
types.ts
selectors.ts
use-add-to-cart.ts
cart-store.ts
validation-schema.ts
```

### `api`

Запросы, `DTO`, мапперы:

```text
api/
add-to-cart.ts
get-product.ts
map-product-dto.ts
```

### `lib`

Вспомогательные функции, локальные для этого слайса:

```text
lib/
calculate-discount.ts
normalize-product.ts
```

### `config`

Флаги и конфигурация:

```text
config/
feature-flags.ts
```

Важный нюанс: `FSD` рекомендует называть сегменты по назначению, а не по технической природе файла. Поэтому `ui`, `model`, `api`, `lib`, `config` лучше, чем `components`, `hooks`, `types`, `utils`. В документации прямо указано, что `components`, `hooks` и `types` — плохие названия сегментов, потому что они хуже помогают понять, зачем существует код.

---

## Пример структуры интернет-магазина

Представим приложение магазина.

```text
src/
app/
providers/
app-providers.tsx
router/
router.tsx
styles/
globals.css
pages/
catalog/
ui/
catalog-page.tsx
api/
get-catalog.ts
index.ts
product-details/
ui/
product-details-page.tsx
api/
get-product-details.ts
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
use-add-to-cart.ts
api/
add-to-cart.ts
index.ts
remove-from-cart/
ui/
remove-from-cart-button.tsx
model/
use-remove-from-cart.ts
api/
remove-from-cart.ts
index.ts
entities/
product/
model/
types.ts
ui/
product-price.tsx
product-image.tsx
index.ts
cart/
model/
types.ts
selectors.ts
index.ts
shared/
api/
client.ts
ui/
button/
button.tsx
index.ts
modal/
modal.tsx
index.ts
lib/
currency/
format-price.ts
index.ts
config/
env.ts
```

Теперь посмотрим на композицию:

```tsx
// widgets/product-card/ui/product-card.tsx
import { ProductImage, ProductPrice, type Product } from '@/entities/product';
import { AddToCartButton } from '@/features/add-to-cart';
import { Card } from '@/shared/ui/card';

type Props = {
    product: Product;
};

export function ProductCard({ product }: Props) {
    return (
        <Card>
            <ProductImage src={product.imageUrl} />
            <h3>{product.title}</h3>
            <ProductPrice price={product.price} />
            <AddToCartButton productId={product.id} />
        </Card>
    );
}
```

Это хороший `FSD`-код, потому что `widget` собирает более низкие слои:

- `widget -> feature`
- `widget -> entity`
- `widget -> shared`

А вот так делать не стоит:

```ts
// entities/product/ui/product-card.tsx
import { AddToCartButton } from '@/features/add-to-cart';
// ❌ Entity импортирует feature, то есть нижний слой зависит от верхнего
```

---

## Как понять, куда класть код

Практическая шпаргалка:

| Вопрос | Куда класть |
|---|---|
| Это глобальная инициализация приложения? | `app` |
| Это экран или `route`? | `pages` |
| Это крупный самостоятельный блок страницы? | `widgets` |
| Это пользовательское действие с бизнес-ценностью? | `features` |
| Это бизнес-сущность: `user`, `product`, `order`? | `entities` |
| Это `UI kit`, `API client`, `config`, `generic lib`? | `shared` |
| Это используется только на одной странице? | Оставь в `pages` |
| Это используется только внутри одного виджета? | Оставь в `widgets` |
| Это переиспользуемая бизнес-логика? | Подумай про `features` или `entities` |
| Это переиспользуемая техническая логика без бизнеса? | `shared` |

Самый частый правильный ответ в `FSD v2.1`: оставь код там, где он используется, пока не появилась причина вынести.

---

## Как разрабатывать новую функциональность в FSD-стиле

Допустим, нужно добавить возможность «добавить товар в избранное».

### 1. Начни со страницы

Если действие нужно только на странице товара:

```text
pages/product-details/
ui/
product-details-page.tsx
add-to-favorites-button.tsx
api/
add-to-favorites.ts
```

На этом этапе не обязательно создавать `features/add-to-favorites`.

### 2. Появилось переиспользование — выноси в `feature`

Если кнопка нужна в каталоге, карточке товара, странице товара и рекомендациях:

```text
features/add-to-favorites/
ui/
add-to-favorites-button.tsx
model/
use-add-to-favorites.ts
api/
add-to-favorites.ts
index.ts
```

### 3. Сущность `favorite` нужна в разных местах — подумай про `entity`

Если избранное становится самостоятельной бизнес-сущностью:

```text
entities/favorite/
model/
types.ts
selectors.ts
api/
get-favorites.ts
index.ts
```

### 4. Собери всё выше

```tsx
// widgets/product-card/ui/product-card.tsx
import { ProductPrice } from '@/entities/product';
import { AddToFavoritesButton } from '@/features/add-to-favorites';
import { AddToCartButton } from '@/features/add-to-cart';
```

То есть нижние слои не знают о верхних, а верхние собирают сценарий из нижних.

---

## Где хранить API-запросы

Здесь часто возникает путаница.

Плохое правило:

- Все запросы класть в `shared/api`

Лучшее правило:

- Клади запрос рядом с тем, кто им владеет

Примеры:

- `shared/api/client.ts`  
  Базовый `HTTP client`, `interceptors`, `request factory`

- `pages/product-details/api/get-product-details.ts`  
  Запрос нужен только странице товара

- `features/add-to-cart/api/add-to-cart.ts`  
  Запрос является частью пользовательского действия «добавить в корзину»

- `entities/product/api/get-product.ts`  
  Запрос относится к бизнес-сущности `product` и переиспользуется в разных местах

В документации для слоёв указано, что `features` могут содержать `API`-вызовы для выполнения действия, `entities` — `entity-related API request functions`, а `pages` — `data fetching` и `mutating requests`, если они относятся к странице.

---

## `Cross-imports` и `@x`

По умолчанию слайсы одного слоя не должны импортировать друг друга.

Например, это плохо:

```ts
// entities/order/model/order.ts
import type { User } from '@/entities/user';
// ❌ entities/order импортирует entities/user напрямую
```

Но в реальной предметной области сущности часто связаны. Например, `Order` содержит `User`, `Artist` содержит `Song`, `Comment` содержит `Author`.

Для таких случаев в `FSD` есть специальная нотация `@x`:

```text
entities/
user/
@x/
order.ts
model/
types.ts
index.ts
order/
model/
types.ts
```

```ts
// entities/user/@x/order.ts
export type { User } from '../model/types';

// entities/order/model/types.ts
import type { User } from '@/entities/user/@x/order';

export type Order = {
    id: string;
    user: User;
};
```

`@x` читается как `cross API`: специальный публичный `API` одной `entity` для другой `entity`. Документация рекомендует держать такие `cross-imports` в минимуме и использовать их в основном на слое `entities`, где полностью избежать связей между сущностями часто нереалистично.

---

## FSD и состояние приложения

`FSD` не говорит, какой `state manager` использовать. Можно использовать:

- `Redux`
- `Zustand`
- `Effector`
- `MobX`
- `React Query`
- `TanStack Query`
- `Apollo`
- обычный `React state`

Важно не то, чем ты управляешь состоянием, а где живёт ответственность.

Примеры:

- `features/add-to-cart/model/use-add-to-cart.ts`  
  Логика действия «добавить в корзину»

- `entities/cart/model/cart-store.ts`  
  Состояние корзины как бизнес-сущности

- `pages/catalog/model/use-catalog-filters.ts`  
  Фильтры, которые нужны только странице каталога

- `app/store/store.ts`  
  Конфигурация глобального стора

- `shared/lib/storage/create-persisted-store.ts`  
  Общая техническая утилита для `persistence`

---

## FSD и `React Query` / `TanStack Query`

Частый хороший подход:

```text
shared/api/
client.ts

entities/product/api/
get-product.ts

pages/catalog/api/
get-catalog.ts

features/add-to-cart/api/
add-to-cart.ts
```

А `query hooks` можно держать там, где они имеют смысл:

```text
pages/catalog/model/use-catalog-query.ts
entities/product/model/use-product-query.ts
features/add-to-cart/model/use-add-to-cart-mutation.ts
```

Например:

```ts
// features/add-to-cart/model/use-add-to-cart.ts
import { useMutation } from '@tanstack/react-query';
import { addToCart } from '../api/add-to-cart';

export function useAddToCart() {
    return useMutation({
        mutationFn: addToCart,
    });
}
```

И наружу:

```ts
// features/add-to-cart/index.ts
export { AddToCartButton } from './ui/add-to-cart-button';
export { useAddToCart } from './model/use-add-to-cart';
```

---

## Хороший FSD-код выглядит так

Он локален:

- Если код нужен только странице — он лежит в странице

Он инкапсулирован:

- Снаружи импортируем только через `public API`

Он направлен вниз:

- `features` импортируют `entities`, но `entities` не импортируют `features`

Он называется бизнес-языком:

- `add-to-cart`, `product`, `order`, `checkout`

А не абстрактно:

- `components`, `modules`, `blocks`, `helpers`, `stuff`

Он не дробится раньше времени:

- Не надо создавать `feature` для каждой кнопки

---

## Типичные ошибки

### Ошибка 1. Делать `feature` из каждого маленького компонента

Плохо:

```text
features/
open-modal/
close-modal/
input-change/
submit-button-click/
```

Лучше:

```text
features/
login/
add-to-cart/
apply-promo-code/
```

`Feature` — это бизнес-действие, а не любой обработчик клика.

---

### Ошибка 2. Всё складывать в `shared`

Плохо:

```text
shared/
utils/
hooks/
components/
services/
types/
```

Так `shared` превращается в свалку.

Лучше:

```text
shared/
ui/
api/
lib/
date/
currency/
validation/
config/
```

И важно: если код содержит бизнес-смысл, ему обычно не место в `shared`.

---

### Ошибка 3. Импортировать внутренности слайса

Плохо:

```ts
import { useAddToCart } from '@/features/add-to-cart/model/use-add-to-cart';
```

Хорошо:

```ts
import { useAddToCart } from '@/features/add-to-cart';
```

---

### Ошибка 4. Нижний слой знает о верхнем

Плохо:

```ts
// entities/product
import { AddToCartButton } from '@/features/add-to-cart';
```

Хорошо:

```ts
// widgets/product-card
import { ProductPrice } from '@/entities/product';
import { AddToCartButton } from '@/features/add-to-cart';
```

---

### Ошибка 5. Слишком ранняя декомпозиция

Плохо:

Ты только начал делать страницу, но уже создал:

```text
entities/product
entities/price
entities/image
features/select-product
features/show-product
widgets/product-layout
```

Лучше:

```text
pages/product-details/
ui/
api/
model/
```

А потом выносить по мере появления повторного использования.

---

## Как внедрять FSD в существующий проект

Хорошая стратегия:

1. Сначала выделить `pages`.
2. Затем отделить `app` и `shared`.
3. Убрать импорты между страницами.
4. Разобрать `shared`, чтобы он не был свалкой.
5. Организовать код внутри слайсов по сегментам `ui`, `model`, `api`, `lib`, `config`.
6. Только потом выделять `features`, `entities`, `widgets`.

Официальная `migration guide` для `custom architecture` предлагает похожий путь: сначала разделить код по страницам, затем вынести всё остальное в `shared` и `app`, разобраться с `cross-imports` между страницами и потом организовать код по техническим сегментам.

Для автоматической проверки архитектурных правил у `FSD` есть `toolchain`: `linter` и генераторы папок. В документации упоминается `Steiger` как инструмент для проверки архитектуры проекта.

---

## FSD в двух фразах

`Feature-Sliced Design` — это способ держать frontend-проект в состоянии, где код организован по бизнес-смыслу, а зависимости контролируются слоями.

Практическое правило:

- Сначала держи код ближе к месту использования
- Выноси ниже только то, что действительно переиспользуется или имеет самостоятельный бизнес-смысл

Для маленького проекта хватит:

```text
app/
pages/
shared/
```

Для растущего продукта постепенно добавятся:

```text
widgets/
features/
entities/
```

И тогда структура начнёт выглядеть не как набор технических папок, а как карта продукта.
