# Маршрут ошибки в `ScopeObserver.onError` — план работ

> **Состояние на 2026-10-25:** задачи 1–6 и шаги 1–2 задачи 7 исполнены
> субагентами в ветке `worktree-observer-route-request` (ядро — в ветке
> `observer-answer` solo); шаги 3–4 ждут выпуска `async_job` 0.4.0. Итог —
> `2026-10-25-observer-error-route-report.md`. Задача 4 переписана по вопросу владельца «сейчас можно легко
> перевыпустить. я единственный пользователь. нужно ли тогда новое имя?»:
> признак ответа — параметр самого `JobObserver.onError`, а не новый хук.
> **Что это:** задачи по дизайну `2026-10-24-observer-error-route-design.md`
> для scopo и для ядра `async_job` (репозиторий `solo`), с тестами и порядком.
> **Связанные записи:** `2026-10-24-observer-error-route-request.md`,
> `2026-10-24-observer-error-route-design.md`.

> **Для агентов-исполнителей:** обязательный подскилл —
> superpowers:subagent-driven-development (рекомендуется) или
> superpowers:executing-plans. Шаги размечены чекбоксами `- [ ]`.

**Цель:** `ScopeObserver.onError` получает окончательный маршрут ошибки,
и маршрут совпадает с тем, куда ошибка уходит на самом деле.

**Устройство:** новый enum `ScopeErrorRoute` и параметр `route` в `onError`.
Каждое место вызова передаёт маршрут, известный в момент вызова. Три места,
где он сегодня неизвестен, перестраиваются: стадии разборки `AsyncScope`
(трудность 2), обход разборки контейнера (5a) и наблюдатель задачи
инициализации (трудность 1, с новым параметром `onError` ядра).

**Стек:** Dart 3.6 / Flutter 3.27.0 через fvm; `async_job` 0.3.0 → 0.4.0.

**Спека:** `docs/records/2026-10/2026-10-24-observer-error-route-design.md`.

## Общие ограничения

- Новое публичное имя `ScopeErrorRoute`, значения ровно `observer`,
  `flutterError`, `zone`, `caller`, `cancellation`.
- Сигнатура: `void onError(ScopeObservable target, ScopePhase phase,
  ScopeErrorRoute route, Object error, StackTrace? stackTrace)`.
- Выпуск scopo 0.19.0, в `CHANGELOG.md` — **Breaking** о сигнатуре и по строке
  о каждом пути, где маршрут или второй канал меняется.
- Ядро меняется **с ломкой**: `JobObserver.onError` получает параметр.
  Выпуски снизу вверх: `async_job` 0.4.0, `solo`, `flutter_solo`, затем
  scopo 0.19.0. Каждый — отдельная связка по отдельному слову владельца
  (`AGENTS.md` §5 обоих репозиториев).
- Работа идёт в ветке `worktree-observer-route-request`. В `main` она
  вливается только после выпуска `async_job` 0.4.0: CI scopo берёт ядро
  с pub.dev.
- `AGENTS.md` §8: сначала падающий тест; правки `lib/` — со строкой
  в `CHANGELOG.md`; публичный документ — с зеркалом в `docs/ru/` в том же
  коммите.

## На что смотреть ревьюеру

Пять случаев, которые спека подразумевает, а тесты отдельных задач легко
пропускают. Каждый закреплён тестом в своей задаче.

1. Ошибка, обёрнутая в `ScopeDependencyException`, во втором канале —
   маршрут сверяется по вложенной ошибке, а не по идентичности обёртки
   (задачи 1 и 3).
2. Без наблюдателя (`ScopeConfig.observer == null`) 1a не прячет ошибку:
   неотвеченный сбой дочерней задачи по-прежнему уходит во `FlutterError`
   (задача 5).
3. `ScopeCompositeObserver` передаёт `route` каждому наблюдателю без
   изменений (задача 1).
4. `close()`, присоединившийся к разборке, которую начал уход с дерева:
   маршрут `flutterError`, `Future` от `close()` несёт ту же ошибку — это
   описано, а не исправлено (задача 2, тест закрепляет описанное).
5. `ParallelWaitError` из стека очистки: каждая ошибка внутри получает свой
   маршрут, отмены внутри — `cancellation` (задачи 4 и 5).

## Сверка маршрута с фактом

Общий помощник тестов, на нём стоят все задачи.

`test/utils/observer.dart`, `RecordingObserver`: строка в `events`
**не меняется** (на ней сотни ожиданий), рядом новый список
`final routes = <(String label, ScopePhase phase, ScopeErrorRoute route, Object error)>[]`.

`test/utils/error_route_audit.dart`:

```dart
/// Which second channel an error reached, beside the observer.
enum SeenIn { flutterError, zone }

/// Records FlutterError reports and uncaught zone errors while a test runs,
/// and checks every announced route against them.
final class RouteAudit {
  void install();             // swaps FlutterError.onError, keeps the old one
  void uninstall();
  void zoneError(Object error, StackTrace stackTrace); // feed from the test's zone guard
  /// Fails the test unless every entry of [routes] matches what was seen.
  void verify(List<(String, ScopePhase, ScopeErrorRoute, Object)> routes);
}
```

Правило `verify`, по ошибке (сравнение — `identical` с самой ошибкой или
с вложенной `ScopeDependencyException.error`):

| маршрут | что должно быть увидено |
| --- | --- |
| `observer`, `cancellation`, `caller` | ничего |
| `flutterError` | ровно один отчёт `FlutterError` |
| `zone` | ровно одна ошибка зоны |

Как в тестах scopo ловят ошибку зоны — смотреть в `test/lite_scope_test.dart`
(сбой `initStateAsync`) и повторять тот же способ.

---

### Задача 1: enum, сигнатура и маршруты, известные на месте

**Файлы:**
- Изменить: `lib/src/environment/scope_observer.dart` (enum, `onError`,
  `ScopeCompositeObserver`, `ScopePrintObserver`), все места вызова
  `observer.onError` в `lib/` (около тридцати, список — `git grep -n
  "observer.onError" lib`).
- Изменить: `test/utils/observer.dart`; наблюдатели в
  `test/async_job_migration_test.dart`, `test/scope_auto_dependency_close_test.dart`,
  `test/scope_observer_test.dart`.
- Изменить: примеры с `onError` в `doc/debug.md`, `README.md` и их зеркалах
  `docs/ru/` — только сигнатура, чтобы стенд собирал их; текст — в задаче 6.
- Создать: `test/utils/error_route_audit.dart`, `test/error_route_test.dart`.

**Интерфейсы:**
- Производит: `ScopeErrorRoute`, новую сигнатуру `onError`, `RouteAudit`,
  `RecordingObserver.routes`.

- [ ] **Шаг 1: падающие тесты** в `test/error_route_test.dart`, по одному
  на строку карты дизайна, кроме трёх перестраиваемых мест: `build`
  (`flutterError`), синхронный `init()` (`flutterError`), `initStateAsync`
  и `onInitialized` у `LiteScopeState` (`zone`; `onInitialized` из колбэка
  после кадра — `flutterError`), сбой `AsyncScope` до задачи (`zone`),
  разборка `ScopeWidgetElementBase` (`flutterError`), чтение `debugLabel`
  в `AsyncScopeElementBase.dispose` (`flutterError`), вторая ошибка
  `Scope.onUnmount`/`Scope.disposeScope`/`ScopeDependencyGroup.onUnmount`
  (`flutterError`), поздние освобождения и брошенные ожидания
  (`flutterError`), сбой тела и `initDependencies` (`observer`), сбой соседней
  ветки `concurrent` (`flutterError`), чужой корень контейнера
  (`flutterError`, его `Cancelled` — `cancellation`). Каждый тест:
  `expect(routes.single.$3, ScopeErrorRoute.X)` и `audit.verify(routes)`.
  Плюс тест на `ScopeCompositeObserver`: два наблюдателя получают один
  и тот же `route`.
- [ ] **Шаг 2:** `fvm flutter test test/error_route_test.dart` — не
  компилируется (нет `ScopeErrorRoute`).
- [ ] **Шаг 3:** ввести enum с дартдоком у каждого значения (смысл — из
  таблицы дизайна) и советом про `default` в `switch`, как у `ScopePhase`;
  параметр `route` после `phase`. Каждое место вызова передаёт
  маршрут по карте дизайна. Три перестраиваемых места пока передают
  `ScopeErrorRoute.observer` с комментарием-ссылкой на задачу, которая их
  перестроит: стадии разборки `AsyncScope` (задача 2), `onDisposalStepFailed`
  контейнера (задача 3), `_ScopeInitObserver._announce` (задача 5).
- [ ] **Шаг 4:** тесты шага 1 зелёные; весь `fvm flutter test` зелёный;
  `fvm dart run tool/check_doc_examples.dart` — 0 FAIL.
- [ ] **Шаг 5:** коммит `feat: tell ScopeObserver.onError where an error goes`.

### Задача 2: маршрут первой ошибки разборки `AsyncScope`

**Файлы:** `lib/src/scope/async_scope/async_scope_core.dart`
(`_performAsyncDispose`, `take`, вызовы `onError` в стадиях),
`test/error_route_test.dart`.

**Интерфейсы:** потребляет `ScopeErrorRoute`, `RouteAudit` задачи 1.

- [ ] **Шаг 1: падающие тесты:**
  - две упавшие стадии при уходе с дерева — оба маршрута `flutterError`,
    `verify` проходит;
  - две упавшие стадии по `close()` — первая `caller` (тест ловит её
    из `Future` `close()`), вторая `flutterError`;
  - `close()` присоединился к разборке, начатой уходом с дерева — маршрут
    `flutterError`, `Future` `close()` несёт ту же ошибку (`identical`).
- [ ] **Шаг 2:** прогон — падают первые два.
- [ ] **Шаг 3:** `onError` стадии зовётся после решения `take`; маршрут:
  не первая — `flutterError`; первая — `flutterError`, если разборку начал
  уход с дерева (значение `_startsTheTeardown`, снятое в `dispose()` до запуска
  разборки, хранится в поле), иначе `caller`. Порядок событий наблюдателя
  (`onError` до `onDisposed`) не меняется.
- [ ] **Шаг 4:** тесты зелёные, весь набор зелёный.
- [ ] **Шаг 5:** коммит `feat: route the first teardown failure of AsyncScope`.

### Задача 3: разборка контейнера — каждый шаг во `FlutterError` (5a)

**Файлы:** `lib/src/scope/full_scope/scope_auto_dependency/scope_auto_dependency.dart`
(`onDisposalStepFailed`, `reportFailure` в `dispose`),
`.../scope_dependency/scope_dependency_group.dart` (`_runDispose` обеих
групп), тесты контейнера, где сегодня ожидается один отчёт на дерево
(`git grep -n "one report" test`, `test/scope_auto_dependencies_test.dart`,
`test/scope_auto_dependency_close_test.dart`).

**Интерфейсы:** потребляет задачу 1.

- [ ] **Шаг 1: падающие тесты:** два упавших листа в `sequential`, два
  в `concurrent`, по одному во вложенной и внешней группе — у каждого шага
  `flutterError`, ровно один отчёт `FlutterError` на шаг (не два у вышедшей
  из обхода), `verify` проходит. Лист с `Cancelled` — `cancellation`,
  во `FlutterError` ничего. Это зонд tez-taxi из заявки: два dispose-шага,
  оба во `FlutterError`.
- [ ] **Шаг 2:** прогон — падают.
- [ ] **Шаг 3:** отчёт во `FlutterError` идёт там же, где объявление шага
  (`onDisposalStepFailed`), один раз на лист; `reportFailure` больше
  не отчитывает ошибку, которая уже прошла через шаг, — сверка по вложенной
  ошибке `ScopeDependencyException`, а не по обёртке. Чужой корень
  отчитывается в `reportFailure`, как сейчас.
- [ ] **Шаг 4:** обновить старые ожидания «один отчёт на дерево»; весь
  набор зелёный.
- [ ] **Шаг 5:** коммит `fix: report every failed disposal step of a container`.

### Задача 4: ядро — признак ответа в `onError` (`solo`, `async_job`)

Работа в репозитории `~/development/my/solo` по его `AGENTS.md`: своя
рабочая копия, свои записи (`docs/records/2026-10/`, имя без `[N]`), свой
гейт, свой handoff, свои оверрайды между выпусками. Публикации нет.

**Форма:** признак — параметр самого хука, нового имени нет:

```dart
/// ... [answered] is `true` when the job asks for an answer to this error
/// right after this call: [JobAnswerer.onUnanswered], or the zone.
void onError(
  Job<Object?> job,
  Object error,
  StackTrace stackTrace, {
  required bool answered,
}) {}
```

`answered: true` — на пути `notifyError` у ошибки, которую
`_handleUnanswered` сейчас отдаст в ответ (не отмена, не названная
`Job.isCancellationError` у отменённой задачи); `false` — у отмен и на пути
`notifyObserver` (исход задачи; ответ, если будет, придёт позже через
`_reportUnobserved`). Фильтр `Job.isCancellationError` спрашивается
по-прежнему один раз на ошибку: решение считается один раз и отдаётся
и хуку, и ответу. `JobObserver.all` пересылает признак.

**Файлы:** `packages/async_job/lib/src/observer.dart`,
`packages/async_job/lib/src/job_base.dart` (`notifyObserver`, `notifyError`,
`_handleUnanswered`), все переопределения `onError(Job…)` в `packages/`
(два в `solo/lib/src/solo.dart`, остальные в тестах и в `doc/errors.md`
обоих пакетов с зеркалами; всего 69), `CHANGELOG.md` `async_job` (0.4.0,
**Breaking**), `solo` и `flutter_solo` (подъём ядра), страница
`doc/error-rules.md` («Where each error goes») и её русское зеркало, запись
дизайна в `docs/records/2026-10/`.

- [ ] **Шаг 1:** запись дизайна в `solo` со ссылкой на эту запись scopo.
- [ ] **Шаг 2: падающие тесты:** ошибка `ctx.onDispose` — `answered: true`;
  сбой тела дочерней задачи — `false`; `Cancelled` из колбэка — `false`;
  ошибка отменённой задачи, которую называет `isCancellationError`, —
  `false`, и фильтр спрошен ровно один раз; `ParallelWaitError` из очистки —
  по вызову на ошибку со своим признаком; `JobObserver.all` пересылает
  признак.
- [ ] **Шаг 3:** реализация и правка всех переопределений.
- [ ] **Шаг 4:** гейт `solo` по его `AGENTS.md` для `async_job`, `solo`
  и `flutter_solo` против дерева (оверрайды на месте) — зелёный.
- [ ] **Шаг 5:** коммит в `solo`, handoff `solo`. Публикацию не запускать;
  сказать владельцу, что готова цепочка `async_job` → `solo` →
  `flutter_solo`.

### Задача 5: scopo — маршрут в наблюдателе задачи инициализации (1a)

**Файлы:** `lib/src/scope/async_scope/scope_init_context.dart`
(`_ScopeInitObserver`), `pubspec.yaml` (`async_job: ^0.4.0`),
`pubspec_overrides.yaml` в корне (путь на `../solo/packages/async_job`,
только на время работы, в `.gitignore`; снимается перед мержем),
`test/error_route_test.dart`, `test/async_job_migration_test.dart`.

**Интерфейсы:** потребляет `JobObserver.onError(..., {required bool answered})` задачи 4.

- [ ] **Шаг 1: падающие тесты:**
  - ошибка `ctx.onDispose` / стека очистки — `flutterError`, `verify`
    проходит;
  - `Cancelled` из колбэка — `cancellation`;
  - сбой дочерней задачи, которую тело поймало, — `observer`, во
    `FlutterError` ничего;
  - сбой дочерней задачи, исход которой никто не прочёл, при наблюдателе —
    `observer`, во `FlutterError` **ничего** (1a);
  - то же без наблюдателя — во `FlutterError` ровно один отчёт;
  - сбой тела, чей исход отобрала отмена (`onUnanswered` объявляет сам) —
    `flutterError`.
- [ ] **Шаг 2:** прогон — падают.
- [ ] **Шаг 3:** `_ScopeInitObserver.onError` читает `answered`:
  отмены — `cancellation`; `answered` — `flutterError`; иначе `observer`.
  `_announce` получает маршрут и помнит, объявлена ли ошибка наблюдателю
  с `observer` при живом наблюдателе (`ScopeConfig.observer != null`);
  `onUnanswered` такую ошибку во `FlutterError` не отдаёт. `_settleFailure`
  объявляет с `observer`.
- [ ] **Шаг 4:** весь набор зелёный; старые тесты, ждавшие красной строки
  у неотвеченного сбоя дочерней задачи при наблюдателе, обновлены со ссылкой
  на 1a.
- [ ] **Шаг 5:** коммит `feat: route the errors of the initialization job`.

### Задача 6: документация

**Файлы:** `doc/debug.md`, `README.md`, `CHANGELOG.md`, зеркала
`docs/ru/doc/debug.md`, `docs/ru/README.md`, манифесты
`tool/doc_examples/debug.dart`, `tool/doc_examples/readme.dart`.

- [ ] **Шаг 1:** `doc/debug.md`: `CrashReporter` шлёт в трекер только
  `route == ScopeErrorRoute.observer`; абзац «An error reaching `onError` is
  never the only way it is reported» заменить таблицей маршрутов (значение →
  кто ещё видит ошибку); абзац «one report for the failed tree» — на 5a;
  описать остаток трудности 2 (`close()`, присоединившийся к разборке).
- [ ] **Шаг 2:** `README.md`: раздел «зачем» для `ScopeErrorRoute` —
  начинается с ошибки читателя (двойной отчёт в трекере), по скиллу
  doc-reader.
- [ ] **Шаг 3:** `CHANGELOG.md`, раздел `## 0.19.0`: **Breaking** — сигнатура
  `onError`; **Behaviour change** — каждый шаг разборки контейнера
  во `FlutterError`; **Behaviour change** — неотвеченный сбой дочерней задачи
  при наблюдателе больше не во `FlutterError`; строка о `cancellation`.
- [ ] **Шаг 4:** зеркала, `sh docs/ru/stamp.sh` после сверки `git status`;
  `humanizer--ru` по изменённым абзацам зеркал.
- [ ] **Шаг 5:** `fvm dart run tool/check_doc_examples.dart` — 0 FAIL;
  `sh docs/ru/check.sh` — чисто. Коммит `docs: explain error routes`.

### Задача 7: гейт, мерж, ответ потребителю

- [ ] **Шаг 1:** гейт `AGENTS.md` §6 целиком, все одиннадцать, плюс
  `fvm flutter test` из `example/scopo_demo`; числа — в `docs/handoff.md`.
- [ ] **Шаг 2:** предмержевое ревью ветки свежим ревьюером; отчёт —
  запись `docs/records/` (`report`).
- [ ] **Шаг 3:** после выпуска `async_job` 0.4.0 (по слову владельца): снять
  `pubspec_overrides.yaml`, `pub get`, гейт ещё раз, влить ветку в `main`.
- [ ] **Шаг 4:** сообщить `sprint_57`: имена, правило «слать при `observer`»,
  пути, где поведение поменялось. Шапки трёх записей — на «сделано».
