# Снятие `final`/`base` с точек расширения

> **Состояние на 2026-09-21:** сделано и смержено в `main`, `ae9cc79`;
> гейт §6 пройден целиком, тестов 535 → 536. Одно уточнение к спеке —
> в §8.
> **Что это:** какие модификаторы класса снимаются, чтобы потребитель мог
> мокать свои классы и наши, и почему остальные остаются на месте.
> **Связанные записи:** `2026-08-19[1]-scope-observer-design.md` (там
> `ScopeObserver` объявлен `base` осознанно — этот довод здесь
> и пересматривается), `2026-09-21[1]-async-job-0.2.0-design.md` (первая
> работа этого дня).

## 1. Зачем

Просьба владельца 2026-09-21: «убрать final/base и т.п., чтобы можно было
делать моки для тестирования».

`mocktail` и `mockito` делают мок одним способом —
`class MockX extends Mock implements X`. Три модификатора это запрещают:
`final`, `base` и `sealed`. Зонд (временный файл в `test/`,
`fvm flutter analyze`, файл удалён) показал, что дороже всего обходится **не
запрет на наши типы, а заражение**:

```
error • The class 'ScopeController' can't be implemented outside of its
        library because it's a base class
error • The type 'MockMyController' must be 'base', 'final' or 'sealed'
        because the supertype 'MyController' is 'final'
error • The type 'MockMyBaseController' must be 'base', 'final' or 'sealed'
        because the supertype 'MyBaseController' is 'base'
error • The class 'ScopeStateNotifier' can't be implemented outside of its
        library because it's a base class
error • The class 'ScopeDependencyHandle' can't be implemented outside of
        its library because it's a final class
```

Читается так: `base` на нашем классе обязывает наследника потребителя быть
`base` или `final`, а оба запрещают `implements` **его собственному классу**.
То есть модификатор на `ScopeController` отнимает у приложения возможность
мокать не `ScopeController`, а свой `AppController`, который на нём стоит. Это
и есть цена, и платит её тот, кто пакет просто использует.

Ручной фейк наследованием при этом работал и работает:
`final class FakeObserver extends ScopeObserver` компилируется, `base` его
не запрещает. Ломается ровно связка `extends Mock implements X`.

## 2. Что меняется

| было | станет | зачем |
|---|---|---|
| `abstract base class ScopeController` | `abstract class` | `AppController` потребителя перестаёт быть заражённым |
| `abstract base class ScopeAutoDependencies<T, C>` | `abstract class` | то же для его контейнера зависимостей |
| `base class ScopeObserver` | `class` | `verify()` вместо ручного фейка |
| `base class ScopeStateNotifier<S>` | `class` | модель экрана — самый частый мок в виджет-тесте |
| `base class ScopeStateModelView<S>` | `class` | то же |
| `base class ScopeStateWithErrorNotifier<S>` | `class` | то же |
| `base class ScopeStateWithErrorModelView<S>` | `class` | то же |
| `base class ListenableView<T>` | `class` | экспортируется и наследуется |
| `final class ScopeDependencyHandle` | `interface class` | единственный публичный тип с приватным конструктором |

`ScopeDependencyHandle` — отдельный случай, и он единственный `final` в этом
списке. Его конструктор приватный: построить его снаружи нельзя, замокать
нельзя, а получает его тело каждой зависимости. Значит юнит-тест на тело
зависимости сегодня не пишется вовсе. `interface class` — точный инструмент:
реализовать можно, наследовать снаружи по-прежнему нельзя, да и не на чем —
конструктора нет.

## 3. Что остаётся как было

**Иерархия виджетов, элементов и состояний** (`Scope`, `LiteScope`,
`AsyncScope*`, `ScopeModel*`, `ScopeNotifier*`, `ScopeWidget*`, все `*Core`,
`*ElementBase`, `*State`). Мок виджета бесполезен по построению: `of` ищет
элемент через `getElementForInheritedWidgetOfExactType<W>`, то есть по точному
типу, и объект, который только `implements W`, туда не попадёт никогда.
А `base` там ловит компилятором ровно ту ошибку, после которой элемент упал бы
на `widget as W` в рантайме. Заражение потребителя здесь безвредно: его
`AppScope` обязан быть `final` — он и так `final`.

**`sealed`-состояния** (`ScopeInitState`, `AsyncScopeState`,
`ScopeDependencyState` и их листья). Проверено: у всех листьев конструкторы
публичные — `AsyncScopeReady()`, `ScopeProgress(x)`, `AsyncScopeError(e, s)`.
Их не мокают, их строят. `sealed` при этом покупает исчерпывающий `switch`,
обещанный в `README.md` и в `doc/`; открыть их — значит заплатить
`default`-ветками ни за что.

**Значения с публичным конструктором**: `ScopeDependencyException`,
`ScopeAutoDependenciesProgress`, `ScopeDependencyInfo`, `ScopeAccess` и его
родня, `Progress`, `ProgressIterator`. Строятся напрямую, мок не нужен.

**`ScopeDependencyGroup`** (`abstract base`, конструктор приватный). Снаружи он
и так не наследуется, а мокают в этом месте `ScopeDependency`, который уже
`abstract interface`.

## 4. Цена

Снятие `base` не ломает ничей код: запрет сужается, а не расширяется.
Существующие наследники, помеченные `final` или `base`, компилируются как
прежде.

Платится другим: **добавление метода в открытый класс становится ломающим для
того, кто его `implements`**. Самое чувствительное место здесь —
`ScopeObserver` с его девятью пустыми телами: сегодня новый хук стоит ничего,
после правки он стоит мажорной строки в `CHANGELOG.md`.

Этим же пересматривается довод
из `docs/records/2026-08-19[1]-scope-observer-design.md`: там `base` выбран,
«чтобы потомок был обязан быть `final`/`base`, что отвечает стилю пакета».
Стиль остаётся стилем, но он оказался дороже, чем предполагалось: он платится
тестами потребителя. Пустые тела — вторая половина того довода — никуда
не деваются.

## 5. Страж

`test/mockability_test.dart`, без новых зависимостей. Он объявляет моки тем же
способом, каким их делает `mocktail`, — `implements` плюс `noSuchMethod`, —
и **не компилируется**, если модификатор вернётся на место. Заодно повторяет
историю потребителя целиком: сперва его собственный `final` класс поверх
нашего, потом мок этого класса.

## 6. Порядок работы

1. Написать `test/mockability_test.dart` — он не компилируется, это и есть
   падающий тест.
2. Снять модификаторы по таблице §2.
3. Прогнать: страж зелёный, сьюта без изменений.
4. Проверка нагруженности: вернуть `base` на `ScopeController` — страж обязан
   перестать компилироваться, затем вернуть правку.
5. `CHANGELOG.md` — строка в раздел 0.15.0.
6. `README.md` про «зачем»: новое публичное обещание («эти типы можно мокать»)
   требует раздела, а не только дартдока. Правка оригинала — вместе с зеркалом
   `docs/ru/README.md` и `stamp.sh` в том же коммите.
7. Гейт `AGENTS.md` §6 целиком.

## 8. Уточнение к спеке

**Открытый класс пакета — половина дела; вторую половину пишет сам
потребитель.** Первая редакция стража объявляла классы приложения `final`, как
они обычно и пишутся, — и после снятия всех девяти модификаторов две ошибки
остались:

```
error • The type '_MockAppController' must be 'base', 'final' or 'sealed'
        because the supertype '_AppController' is 'final'
```

Это правило языка, а не наш модификатор: `final` на своём классе запрещает
`implements` ему самому, и никакая правка пакета этого не изменит. Свобода,
которую покупает эта работа, в другом: пока наши классы были `base`, наследник
обязан был быть `base` или `final` — **выбора не было вовсе**, и оба варианта
мок запрещали. Теперь потребитель пишет обычный класс, и вот он мокается.

Страж переписан на этот сценарий: `_AppController` и `_AppDependencies`
в `test/mockability_test.dart` — обычные классы. До правки они
не компилировались бы вовсе («must be `base`, `final` or `sealed`»), после —
компилируются и мокаются. В `README.md` объяснение дано тем же порядком.
