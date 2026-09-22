# Форма отказа для «подписка берётся только из сборки»: структурный `FlutterError`

> **Состояние на 2026-09-22:** сделано и смержено. **Что это:** решение о том,
> чем отвечать на подписку, взятую не там, — и правка формы текста обоих
> ассертов `ScopeContext._find`. **Связанные записи:**
> `2026-09-22[1]-subscription-boundary-report.md` (сам ассерт и его граница),
> `2026-08-16[12]-project-review.md` (находка P2-15, откуда ассерт).

## Повод

Прямо после того, как граница подписки была перерисована по зависимому
(`2026-09-22[1]-subscription-boundary-report.md`), владелец спросил: стоит ли
сделать ошибку громкой, например через `FlutterError`. Вопрос распадается
на два, и ответы у них разные: **чем** отказ кончается — броском или
отчётом, — и **как** он выглядит.

## Чем кончается: бросок остаётся

Рассматривался перевод на `FlutterError.reportError` внутри `assert(() {…}())`:
приложение в debug продолжает жить, ошибка уходит в консоль и в
`FlutterError.onError`. Отвергнуто по трём причинам.

**Так отвечает сам Flutter.** Ближайший сосед нашей ошибки — поиск inherited
не вовремя — разобран в `StatefulElement.dependOnInheritedElement`
(`framework.dart:5860-5865` в 3.27.0): там `assert(() {…}())`, внутри которого
летит `FlutterError.fromParts` с «`dependOnInheritedWidgetOfExactType<…>()` or
`dependOnInheritedElement()` was called before `…initState()` completed».
То есть на ту же операцию в неподходящий момент фреймворк бросает, а не
отчитывается.

**Адресат есть.** Правило пакета «отказ, у которого не осталось адресата,
отчитывается и не бросается» (оно и стоит за `_reportFailure` в том же файле)
написано про разрушение: теардаун идёт половинами, вызвать наверх можно только
первый отказ. Здесь не так — `select` зовут синхронно из пользовательского
кода, и бросок приходит ровно тому, кто нарушил контракт, с его стеком.

**Отчёт оставляет жить с дефектом.** Подписка, взятая вне сборки, всё равно
умрёт на первой же пересборке от родителя; отчёт превращает её в красную
строку в шумной консоли — ровно в ту тишину, ради которой проверка и написана.
В тестах разницы нет вовсе: `reportError` тоже валит прогон.

Цена броска названа честно и в прошлой записи, и здесь: ассерт может сработать
только вне `build` зависимого, то есть кадр рвётся и поддерево остаётся
неразмонтированным (отсюда `experimentalLeakTesting: unmountableTree` на тестах
отказа). Это свойство места, где делают ошибку, а не формы отказа.

## Как выглядит: `FlutterError.fromParts` вместо одной строки

Оба ассерта `ScopeContext._find` были `assert(условие, 'длинный абзац')`.
Абзац печатался одним куском, и первое, что видел читатель, — стену текста.
Теперь оба записаны так же, как это делает фреймворк:

```dart
assert(() {
  if (listen && !_debugRegistrationBelongsToABuild(context)) {
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('A scope can only be subscribed to from a build.'),
      ErrorDescription(…),   // почему так устроено
      ErrorDescription(…),   // откуда сюда обычно попадают
      ErrorHint(…),          // что делать вместо
      ErrorHint(…),          // и что делать, если нужна реакция, а не показ
      context.describeElement('The dependent that tried to subscribe was'),
    ]);
  }

  return true;
}());
```

Что это даёт, замерено на тесте (`print` пойманного исключения):

```
A scope can only be subscribed to from a build.
What a dependent asked for is remembered per build, …
`didChangeDependencies` is the usual way to get here: …
Subscribe from `build` and read the value there -- …
To react to a change rather than to show it, …
The dependent that tried to subscribe was:
  _SubscribesTooEarly
```

Первая строка — правило, которое нарушили; последняя называет **сам виджет**,
который это сделал, чего в прежнем тексте не было вовсе. В консоли всё это
приходит внутри обычного блока `══╡ EXCEPTION CAUGHT BY …`.

Второй ассерт — подписка из хука инициализации — переписан так же:
`ErrorSummary('A scope cannot be subscribed to from the initialization
hook.')`, объяснение, совет, `describeElement` самого скоупа.

## Совместимость

`FlutterError extends Error … implements AssertionError`
(`foundation/assertions.dart:762`), а `FlutterError.message` — это его
`toString()` целиком (`:905`). Значит, чужой тест, ловивший
`isA<AssertionError>()` и смотревший в `message`, продолжает работать: тип
подходит, текст на месте. `fromParts` сам проверяет ассертом, что первая часть
— единственный `ErrorSummary`, так что структура держится не только уговором.

## Тесты

Четыре ожидания переписаны с «`AssertionError`, в `message` есть подстрока» на
«`FlutterError`, у которого `diagnostics.first` — ровно эта строка-заголовок»:
три в `test/base_test.dart` (отказ из `didChangeDependencies`, он же под
layout-колбэком, подписка между кадрами) и одно в
`test/scope_widget_test.dart` (подписка из `init`), где вдобавок проверяется,
что совет про `listen: false` в частях остался.

Проверка нагруженности вышла сама собой: тесты переписаны **до** правки кода
и упали все четыре — `which is not an instance of 'FlutterError'`. После
правки прогон зелёный, 541 тест.

Такая форма ожидания строже прежней: она ловит не только возврат к простому
ассерту (по типу), но и размывание заголовка в общий текст (по точному
совпадению первой части).

## Не тронуто

Тем же способом просятся ассерты про `Widget.key` в `scope_model` и
`scope_notifier` (переход между владеющим конструктором и `.value`) — у них
такой же длинный текст одной строкой. Объём не расширялся: владелец просил
форму текста для ассертов про место подписки, остальное записано сюда
и в `docs/handoff.md`.
