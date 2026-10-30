# Полное ревью scopo против pub.dev: Fable

> **Состояние на 2026-10-30:** ревью принято с поправками: оба зонда
> перезапущены и воспроизвелись; «нет пути без виджетов» верно наполовину
> (`ScopeInitJob` описан в `README.md:459`), pub points у scopo — 160/160,
> а не «не посчитаны». Разбор и сравнение с ревью Opus — в
> `2026-10-30[3]-market-reviews-report.md`. Рекомендация 3
> (позиционирование) сделана в `4d70653`, 10 — частично; рекомендация 4
> (дыры маршрута ошибки) сделана в `553e381` и выпущена в 0.21.2;
> рекомендации 2 и 6 и находка «нет пути без виджетов» отвергнуты
> владельцем — вердикты на местах.
> Зонд и данные, на которые ссылается текст, лежали в каталоге задачи вне
> репозитория и в git не сохранены.
> **Что это:** независимое сравнение scopo 0.21.0 с пакетами pub.dev той же
> и соседних ниш — факты, зонд на одной задаче, оценки, вывод и рекомендации.
> **Связанные записи:** `2026-10-30[2]-opus-market-review.md`,
> `2026-10-30[3]-market-reviews-report.md`.

Предмет — scopo 0.21.0, коммит `2ec8211`, прочитано в копии
`.claude/worktrees/market-review`: `README.md`, `doc/*.md`, `lib/`,
`CHANGELOG.md`, `example/`, `docs/architecture.md`, шапка `docs/handoff.md`.
Все цифры pub.dev и GitHub сняты 2026-10-30 через `pub.dev/api/packages/<p>`,
`/api/packages/<p>/score` и `gh api repos/<owner>/<repo>`. Что не проверено —
так и написано. Мнения помечены словом «мнение».

Зонд (раздел 2.3) собран вне репозитория,
в `/Users/user/.claude/jobs/715c8327/tmp/fable/probe/`, глобальным Flutter
3.47.0; в репозитории ничего не запускалось и не менялось.

Размеры scopo, снятые скриптом: `lib/` — 13 338 строк, 117 публичных типов
верхнего уровня в `lib/src`; тесты — 52 файла, 35 476 строк, 677 вызовов
`test()`/`testWidgets()`; `README.md` — 1006 строк; `doc/` — 11 файлов, 4188
строк; примеры — quickstart 77, minimal 240, scopo_demo 4749 строк; 11 шаблонов
IDE; 46 версий на pub.dev с 2025-11-18; 906 коммитов.

## 1. Ландшафт pub.dev

### 1.1. Как искал

Двадцать запросов к поисковому API pub.dev (`scope`, `scoped di`,
`dependency injection flutter`, `service locator`, `async initialization`,
`dispose scope`, `lifecycle`, `splash initialization`,
`inherited widget provider`, `scoped provider` и варианты) плюс пакеты,
известные по имени, — 104 кандидата. Оставлены те, у кого есть хотя бы одно из:
привязка объекта к поддереву виджетов, асинхронная инициализация с экраном
ожидания, управление порядком освобождения, скоупы в DI-контейнере. Остальные —
в соседние группы ниже или отброшены (поисковый шум: `scope` в смысле OAuth,
`lifecycle` в смысле `AppLifecycleState`).

Пояснения к колонкам: «dl30» — загрузки за 30 дней из API; метрику «popularity»
pub.dev больше не публикует, её нет. «pts» — pub points; у пакетов с релизом
за последние дни стоит `0/0`: анализ ещё не прошёл (так у scopo 0.21.0, refena,
df_cleanup, async_job). «Dart 3» — флаг `dart3` в API для последней версии;
`0/0` там же даёт `no`, это артефакт ожидания анализа, а не отсутствие
поддержки.

### 1.2. Группа A — реальное пересечение: скоупы в дереве, асинхронный старт

| Пакет | Версия | Релиз | Likes | pts | dl30 | Dart 3 | Publisher | GitHub ★ / issues / последний push |
|---|---|---|---|---|---|---|---|---|
| **scopo** | 0.21.0 | 2026-10-28 | 3 | 0/0 (ожидает; за 0.20.x страница показывала 160) | 852 | ожидает | yet-another.dev | 2 / 0 / 2026-10-28 |
| yx_scope | 1.2.2 | 2026-10-09 | 72 | 160 | 8 166 | да | dev.go.yandex | 64 / 7 / 2026-10-09 (монорепо yandex/city-services-pub) |
| yx_scope_flutter | 1.2.0 | 2025-12-24 | 34 | 160 | 6 240 | да | dev.go.yandex | то же |
| yx_scope_linter | 0.2.0 | 2025-12-24 | 19 | 130 | 34 | да | dev.go.yandex | то же |
| cobalt | 1.9.2 | 2026-10-25 (первая 2026-09-05, 23 версии) | 5 | 160 | 1 739 | да | — | 0 / 0 / 2026-10-25 |
| cobalt_flutter | 1.9.2 | 2026-10-25 | 0 | 160 | 1 748 | да | — | то же |
| get_it | 9.3.0 | 2026-09-19 (первая 2018-05-22, 90 версий) | 4 731 | 160 | 2 454 457 | да | flutter-it.dev | 1 476 / 7 / 2026-09-29 |
| watch_it | 2.5.0 | 2026-09-19 | 213 | 160 | 13 446 | да | flutter-it.dev | 188 / 0 / 2026-09-19 |
| flutter_riverpod | 3.4.3 | 2026-09-03 (первая 2020-05-16, 130 версий) | 2 916 | 140 | 4 153 688 | да | dash-overflow.net | 7 412 / 172 / 2026-10-25 |
| riverpod | 3.4.3 | 2026-09-03 | 4 043 | 160 | 4 257 758 | да | dash-overflow.net | то же; Flutter Favorite |
| provider | 6.1.5+1 | 2025-08-19 (первая 2018-10-19) | 11 012 | 150 | 1 174 048 | да | dash-overflow.net | 5 251 / 38 / 2026-09-29; Flutter Favorite |
| flutter_bloc | 9.1.1 | 2025-05-02 (первая 2018-10-23) | 8 085 | 160 | 2 283 936 | да | bloclibrary.dev | 12 487 / 89 / 2026-10-25; Flutter Favorite |
| flutter_modular | 7.1.1 | 2026-09-19 (первая 2019-12-09, 262 версии) | 1 330 | 160 | 60 048 | да | flutterando.com.br | 1 386 / 19 / 2026-10-20 |
| get (GetX) | 4.7.3 | 2025-11-24 (332 версии) | 15 605 | 140 | 764 151 | да | getx.site | 11 197 / 1 185 / 2026-06-12 |
| take_it | 1.0.4 | 2026-07-20 (первая 2024-09-18, 5 версий) | 3 | 160 | 558 | да | tekmates.pro | 0 / 1 / 2026-07-20 |
| depend | 5.1.5 | 2026-09-05 (первая 2024-09-08, 25 версий) | 10 | 160 | 556 | да | bangertstudio.kz | 7 / 0 / 2026-09-05 |
| flutter_sputnik_di | 0.2.1 | 2025-02-14 | 6 | 160 | 50 | да | — | 4 / 0 / 2025-08-31 |
| flutter_lean_di | 0.1.1 | 2026-10-20 (первая 2026-10-02) | 10 | 160 | 448 | да | leancode.co | 1 / 0 / 2026-10-20 |
| disco | 2.0.0 | 2026-01-07 (первая 2025-01-25) | 25 | 150 | 1 787 | да | mariuti.com | 27 / 3 / 2026-10-23 |
| context_plus | 6.0.7 | 2026-04-09 | 23 | 160 | 8 776 | да | sonerik.dev | 38 / 3 / 2026-03-08 |
| lite_ref | 0.8.1 | 2024-04-20 | 30 | 160 | 7 477 | да | nosy.dev | 19 / 4 / 2024-11-15 |
| cherrypick | 3.0.2 | 2025-10-20 | 17 | 150 | 907 | да | — | 12 / 1 / 2026-10-01 |
| dart_ddi / flutter_ddi | 0.15.0 / 0.12.0 | 2026-07-18 | 2 / 2 | 140 / 160 | 79 / 105 | да | — | 3 / 0 / 2026-07-18 |
| zenify | 2.3.1 | 2026-09-01 (62 версии за год) | 17 | 160 | 242 | да | pixel-innovations.com | 40 / 1 / 2026-09-01 |
| flutter_koin | 1.1.0 | 2026-10-24 (первая 2026-10-09) | 10 | 160 | 192 | да | — | 1 / 0 / 2026-10-24 |
| scope_provider | 0.1.8 | 2025-03-01 (1 версия) | 1 | 130 | 9 | да | — | не проверял |

Что у них общего со scopo и чего нет — в разделе 2.1.

### 1.3. Соседние группы (пересечение по одной оси)

**B. Только асинхронный UI (загрузка/ошибка), без владения ресурсом:**

| Пакет | Версия | Релиз | Likes | pts | dl30 |
|---|---|---|---|---|---|
| states_rebuilder | 6.4.0 | 2024-02-20 | 409 | 150 | 18 665 |
| stacked (`FutureViewModel`) | 3.5.0 | 2025-08-19 | 1 487 | 120 | 69 821 |
| flutter_solidart (`Resource`) | 2.7.4 | 2026-05-21 | 82 | 160 | 5 018 |
| async_builder | 1.3.1+1 | 2023-03-05 | 68 | 160 | 42 |
| async_listenable | 1.2.0 | 2024-09-03 | 13 | 150 | 494 |
| listenable_future_builder | 1.0.0-beta | 2023-05-24 | 17 | 80 | 22 |

**C. Только освобождение (сборщики `dispose`):**

| Пакет | Версия | Релиз | Likes | pts | dl30 |
|---|---|---|---|---|---|
| dispose_scope | 2.1.0 | 2023-06-20 | 17 | 160 | 717 152 |
| flutter_dispose_scope | 2.0.0 | 2022-09-09 | 5 | 160 | 181 |
| raii | 0.3.5 | 2026-04-07 | 12 | 160 | 37 |
| autoclose | 1.0.5 | 2026-01-14 | 20 | 140 | 159 |
| disposable_container | 0.1.0 | 2024-03-05 | 4 | 160 | 1 530 |
| df_cleanup | 1.1.1 | 2026-10-28 | 4 | 0/0 | 83 |
| lifecycle_capsules | 2.0.0 | 2026-01-28 | 2 | 155 | 27 |

**D. Инициализация приложения и сплэш:**

| Пакет | Версия | Релиз | Likes | pts | dl30 |
|---|---|---|---|---|---|
| flutter_native_splash | 2.4.8 | 2026-05-29 | 9 811 | 150 | 1 958 804 |
| app_initializer | 1.0.0 | 2024-06-29 | 6 | 160 | 54 |
| init_tasks | 0.1.0 | 2026-09-29 | 1 | 140 | 353 |
| flutter_app_gate | 0.1.0 | 2026-08-28 | 0 | 160 | 107 |
| initializable | 1.0.1 | 2026-07-24 | 2 | 160 | 19 |
| ensure_initialized | 0.1.0 | 2022-01-15 | 9 | 160 | 690 |
| dependency_initializer | 3.0.0 | 2025-05-13 | 1 | 160 | 93 |

**E. DI без дерева: зоны, кодогенерация, маршруты, мёртвые:**

| Пакет | Версия | Релиз | Likes | pts | dl30 | Заметка |
|---|---|---|---|---|---|---|
| scope (onepub) | 5.1.0 | 2024-08-13 | 14 | 150 | 254 058 | DI через `Zone` |
| scoped_deps | 0.2.1 | 2026-07-28 | 9 | 160 | 61 596 | DI через `Zone` |
| injectable | 3.0.0 | 2026-04-20 | 1 458 | 160 | 414 931 | кодоген для get_it |
| kiwi | 5.0.1 | 2024-07-22 | 173 | 160 | 12 649 | контейнер + кодоген |
| auto_injector | 2.2.0 | 2026-06-24 | 119 | 160 | 49 192 | ядро flutter_modular |
| jugger | 3.0.0 | 2022-08-27 | 4 | 140 | 100 | кодоген, Dagger-стиль |
| go_provider | 2.0.2 | 2026-08-29 | 25 | 160 | 536 | провайдеры на маршрутах go_router |
| flutter_getit | 3.0.1 | 2024-09-27 | 91 | 140 | 1 260 | get_it на страницах и маршрутах |
| scoped_model | 2.0.0 | 2022-08-24 | 285 | 150 | 581 539 | исторический |
| koin / koin_flutter | 0.14.2 / 0.10.0 | 2020 | 59 / 1 | 40 / 30 | 52 / 44 | без Dart 3, брошен |
| ioc_container | 1.0.12 | 2023-04-03 | 89 | 90 | 1 912 | без Dart 3 |
| providerscope, scoper, inject | — | 2019–2021 | 0–4 | ≤130 | ≤17 | мёртвые |

Что не проверял: поведение пакетов групп B–E в коде — только описания
на pub.dev и README; статистику GitHub у пакетов без репозитория в API.

## 2. Сравнение

### 2.1. Оси и матрица

Оси выбраны по заявленной задаче scopo (`README.md:11-56`, «Why another one»):
экран владеет ресурсом, ресурс открывается асинхронно, закрывается асинхронно,
виджет может уйти в любой момент, а следующий владелец того же ресурса
не должен начать раньше, чем предыдущий закончит.

Обозначения: «+» есть в пакете, «±» частично или руками, «−» нет. У scopo
каждая ячейка подтверждена `file:line`; у остальных — документацией или
исходником из `~/.pub-cache` (версии из таблицы 1.2).

| Ось | scopo | yx_scope | cobalt | get_it + watch_it | riverpod 3 | provider | flutter_bloc | flutter_modular | take_it | depend | lean_di | disco |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Владение привязано к виджету: создан с ним, умирает с ним | + ¹ | ± ² | + | ± ³ | ± ⁴ | + | + | ± (к маршруту) | + | + | + | + |
| Асинхронный старт с экраном ожидания в самом пакете | + `buildOnProgress` | + `withPlaceholder` | + `loading` | ± `allReady` | + `AsyncLoading` | ± `FutureProvider`+`initialData` | − (событие блока) | − ⁵ | + `initializationPlaceholder` | + `placeholder` | не проверял | − |
| Экран ошибки в пакете | + `buildOnError` | − (руками) | + `errorBuilder` | ± `onError` | + `AsyncError` | − | − | − | не проверял | + `errorBuilder` | не проверял | − |
| Прогресс шагов (значение, путь) | + ⁶ | − | − | − | − | − | − | − | − | − | − | − |
| Порядок старта зависимостей | + `sequential`/`concurrent` ⁷ | + `initializeQueue` ⁸ | + уровни `dependsOn` | + `dependsOn` ⁹ | ± через `ref.watch(...future)` | − | − | − | не проверял | ± руками в `factory` | не проверял | − |
| Освобождение в обратном порядке и **с ожиданием** | + ¹⁰ | + ¹¹ (но `State.dispose` не ждёт) | + (из описания) | ± `popScope` ждёт, виджет — нет | − `onDispose` синхронный ¹² | − | − `close()` не ждут | − | не проверял | не проверял | не проверял | − |
| Ожидание дочерних скоупов перед своим `dispose` | + ¹³ | + (дети закрываются с родителем) | + «children-first» | − | − | − | − | − | − | − | − | − |
| Отмена незавершённого старта при уходе виджета | + ¹⁴ | − (`drop` ждёт `init`) ¹⁵ | − (не нашёл) | − | − ¹⁶ | − | − | − | − | − | − | − |
| Сериализация владельцев одного ресурса | + `scopeKey` ¹⁷ | − | − | − | − | − | − | − | − | − | − | − |
| Таймауты на каждую стадию разборки | + четыре ¹⁸ | − | ± один дедлайн 30 с | ± `allReady(timeout)` только на старт | − | − | − | − | − | − | − | − |
| Закрытие «на месте» с экраном закрытия | + `close()` ¹⁹ | − | − | − | − | − | − | − | − | − | − | − |
| Типизированный наблюдатель жизненного цикла | + 12 хуков ²⁰ | + `ScopeObserver`, `AsyncDepObserver` | не проверял | − | + `ProviderObserver` | − | + `BlocObserver` | − | − | − | − | − |
| Контейнер тестируется без виджетов (чистый Dart) | − ²¹ | + | + | + | + `ProviderContainer` | − | + | ± | + | − | + | − |
| Линтер / кодоген | − | + yx_scope_linter | − | + injectable | + riverpod_lint, generator | − | − | − | − | − | − | − |
| Публичных типов (порядок) | ~117 | ~30 (не считал точно) | не считал | ~20 | много, но входных ~10 | ~10 | ~10 | ~40 | ~10 | ~5 | ~15 | ~5 |

Ссылки на scopo:

1. `lib/src/scope/async_scope/async_scope_core.dart:886`
   (`_registerWithParent`), `:1117` (`_performAsyncDispose`), `:1313`
   (`_prepareForDisposal`); `docs/architecture.md`, раздел о жизненном цикле.
2. yx_scope: холдер живёт в `State` руками (`yx_scope/docs/complete_guide.md`,
   пример с `initState`/`dispose`); виджет только читает его. Философия
   пакета — «UI не создаёт скоупы, скоупы создают UI» (там же).
3. get_it: `pushScope` в `build` виджета watch_it
   (`flutter-it.dev/documentation/watch_it/...`), сам скоуп — запись
   в глобальном стеке `GetIt.I`.
4. Riverpod: провайдер по умолчанию глобален; владение «на экземпляр экрана» —
   только через scoping с `dependencies` и `overrides` вложенного
   `ProviderScope`, что документация не рекомендует
   (`riverpod.dev/docs/concepts2/auto_dispose`, раздел о scoping в 3.0).
   Проверено зондом: без `overrides` вложенный `ProviderScope` ничего
   не меняет.
5. flutter_modular 7: `binds` синхронные (`auto_injector`), `dispose` только
   для `ChangeNotifier`/`Disposable`; асинхронного старта модуля нет
   (`modular.flutterando.com.br`, Dependency Injection).
6. `lib/src/scope/full_scope/scope_auto_dependency/scope_auto_dependencies_progress.dart:4,10,34`
   (`path`, `value`).
7. `lib/src/scope/full_scope/scope_auto_dependency/scope_auto_dependency.dart:669`
   (`dep`), `:703` (`sequential`), `:714` (`concurrent`), `:28`
   (`autoDisposeOnError`), `:748` (`flattenDependenciesWithErrors`).
8. yx_scope: `lib/src/base_scope_container.dart:107`
   (`List<Set<AsyncDep>> get initializeQueue`), множество — параллельно,
   список — по очереди; забытая зависимость — исключение в рантайме
   (`lib/src/dep.dart:189-191`).
9. get_it: `registerSingletonAsync(dependsOn:)`, `allReady({timeout})` →
   `WaitingTimeOutException`
   (`flutter-it.dev/documentation/get_it/async_objects`).
10. `async_scope_core.dart:1341` (вызов `disposeScope`), `:1460`
    (`_awaitBounded`); семь шагов разборки — `docs/architecture.md`.
11. yx_scope: `lib/src/core_scope_holder.dart:310` —
    `(initializedDeps ?? scope.initializeQueue).reversed`; при падении `init`
    освобождаются только уже поднятые (`:174-175`); упавший `dispose`
    логируется и пропускается (`:322-335`).
12. riverpod 3.4.3: `Ref.onDispose(void Function())` — синхронный;
    `Ref.mounted` только для проверки после `await`. Подтверждено зондом:
    `db closing` начинается до `session closed`.
13. `lib/src/scope/async_scope/scope_coordination.dart:170` (`ChildRegistry`),
    `:199` (`waitForChildren`); `async_scope_core.dart:1649`.
14. `lib/src/scope/async_scope/scope_init_context.dart:39` (`ScopeInitJob`),
    `async_scope_core.dart:211,220` (ветки `Cancelled`), `:1591`
    (`initCancellationTimeout`); `pubspec.yaml` — `async_job: ^0.6.0`.
15. yx_scope `core_scope_holder.dart:228-262`: `drop()` во время `initializing`
    ждёт `available`, потом разбирает. Подтверждено зондом.
16. riverpod: тело `FutureProvider` не получает сигнала отмены; документация
    предлагает `ref.onDispose` до `await` или проверку `ref.mounted`.
    Подтверждено зондом: база, открытая после ухода скоупа, не закрыта.
17. `scope_coordination.dart:9` (`KeyedAccessQueues`), `:40` (`AccessEntry`);
    `lib/src/scope/async_scope/async_scope_coordinator.dart:15,71`;
    `README.md:694-748`.
18. `lib/src/environment/scope_config.dart:58,68,83,101` — четыре
    `default*Timeout`, все `Duration(seconds: 3)` (`:104`); `:48`
    `timeoutReportsEnabled`. После истечения владельцы могут перекрыться —
    README сам это говорит (`README.md:30-32,66-68`).
19. `async_scope_core.dart:1240` (`close()`);
    `lib/src/utils/screenshot_replacer.dart:11`; `README.md:749-786`.
20. `lib/src/environment/scope_observer.dart:138-277` — 12 хуков;
    `ScopeErrorRoute` появился в 0.19.0 (`CHANGELOG.md:24`).
21. Инициализация начинается из `State` (`async_scope_core.dart:886` и далее);
    раздел «Testing» в `README.md:868-929` — только `testWidgets`.
    `ScopeAutoDependencies` можно поднять без виджета через `ScopeInitJob`,
    но это не оформлено как путь.

### 2.2. Что это даёт в сумме

Пересечение scopo с другими — реальное, но на разных осях:

- с **yx_scope** и **cobalt** — порядок старта, обратный порядок и ожидание
  освобождения, дочерние скоупы;
- с **get_it** — скоупы, `dependsOn`, ожидание готовности с таймаутом;
- с **Riverpod** — экраны загрузки и ошибки из коробки, `autoDispose`;
- с **take_it**, **depend**, **sputnik**, **lean_di** — «скоуп как виджет
  с плейсхолдером».

Ни у одного из них нет сразу: отмены незавершённого старта по уходу виджета,
ожидания детей перед собственным `dispose`, очереди владельцев по ключу,
`close()` с экраном закрытия и таймаутов по стадиям. Это и есть ниша scopo,
и она подтверждается зондом ниже, а не только README.

### 2.3. Одна задача в четырёх пакетах

Задача из брифа: экран, которому нужны база и сессия поверх базы; показать
загрузку и ошибку; при уходе экрана — отменить старт, закрыть в обратном
порядке; пересозданный экран не должен открыть вторую базу, пока первая
не закрыта.

Зонд: общие заглушки `Db` (открытие 300 мс, закрытие 300 мс) и `Session`
(открытие 300 мс, закрытие 100 мс) пишут в один журнал событий. Сценарий
одинаков для всех: показать экран, через 150 мс (база ещё открывается) нажать
«обновить» — экран пересоздаётся с новым ключом, подождать, убрать экран,
подождать. Файлы: `probe/lib/common.dart`, `probe_scopo.dart`,
`probe_riverpod.dart`, `probe_get_it.dart`, `probe_yx_scope.dart`,
`probe/test/probe_test.dart`; полный вывод прогона — `probe_test.log` (тест
get_it формально падает: пойманная `FlutterError` и есть находка).
`flutter analyze` чистый на всех четырёх; журналы ниже — вывод `flutter test`.
Версии: scopo 0.21.0, flutter_riverpod 3.4.3, get_it 9.3.0 + watch_it 2.5.0,
yx_scope 1.2.2 + yx_scope_flutter 1.2.0.

Оговорка: `Db.open()` в заглушке не умеет отменяться, поэтому ни один пакет
не может прервать само открытие; разница — в том, что происходит сразу после.

**scopo** (сокращено, полный файл компилируется):

```dart
final class ScreenDeps extends ScopeAutoDependencies<ScreenDeps, void> {
  late final Db db;
  late final Session session;

  @override
  ScopeDependency buildDependencies(void _) => sequential('', [
        dep('db', (dep) async {
          db = await Db.open();
          dep.dispose = db.close;
        }),
        dep('session', (dep) async {
          session = await Session.open(db);
          dep.dispose = session.close;
        }),
      ]);
}

final class ScreenScope extends Scope<ScreenScope, ScreenDeps, ScreenState> {
  const ScreenScope({super.key}) : super(scopeKey: Db);

  @override
  Future<ScreenDeps> initDependencies(BuildContext context, ScopeInitContext ctx) =>
      ScreenDeps().init(null, ctx);

  @override
  ScreenState createState() => ScreenState();

  @override
  Widget buildOnProgress(BuildContext context,
          covariant ScopeAutoDependenciesProgress? progress) =>
      Column(children: [
        LinearProgressIndicator(value: progress?.value ?? 0),
        Text(progress?.path ?? 'waiting for the previous owner'),
      ]);

  @override
  Widget buildOnError(BuildContext context, Object error, StackTrace stackTrace,
          covariant ScopeAutoDependenciesProgress? progress) =>
      Text('failed at ${progress?.path}: $error');
}

final class ScreenState extends ScopeState<ScreenScope, ScreenDeps, ScreenState> {
  @override
  Widget build(BuildContext context) =>
      Text('session on db closed=${dependencies.db.closed}');
}

// корень: AsyncScopeCoordinator(child: MaterialApp(... ScreenScope(key: ValueKey(gen))))
```

**Riverpod 3** — провайдеры пришлось сделать scoped (`dependencies`
+ `overrides`), иначе пересозданный экран получает ту же базу:

```dart
final dbProvider = FutureProvider.autoDispose<Db>((ref) async {
  final db = await Db.open();
  ref.onDispose(() { db.close(); });   // void Function(): Future теряется
  return db;
}, dependencies: const []);

final sessionProvider = FutureProvider.autoDispose<Session>((ref) async {
  final db = await ref.watch(dbProvider.future);
  final session = await Session.open(db);
  ref.onDispose(() { session.close(); });
  return session;
}, dependencies: [dbProvider]);

class RiverpodScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(sessionProvider)) {
        AsyncLoading() => const CircularProgressIndicator(),
        AsyncError(:final error) => Text('$error'),
        AsyncData(:final value) => Text('closed=${value.db.closed}'),
      };
}

// ProviderScope(key: ValueKey(gen), overrides: [dbProvider, sessionProvider], child: RiverpodScreen())
```

**get_it + watch_it:**

```dart
class GetItScreen extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    pushScope(init: (getIt) {
      getIt.registerSingletonAsync<Db>(Db.open, dispose: (db) => db.close());
      getIt.registerSingletonAsync<Session>(
        () => Session.open(getIt<Db>()),
        dependsOn: [Db],
        dispose: (session) => session.close(),
      );
    });
    final ready = allReady(onError: (context, error) => debugPrint('$error'));
    if (!ready) return const CircularProgressIndicator();
    return Text('closed=${di<Session>().db.closed}');
  }
}
```

**yx_scope + yx_scope_flutter:**

```dart
class DbHandle implements AsyncLifecycle {           // init/dispose на объекте
  late Db db;
  @override Future<void> init() async => db = await Db.open();
  @override Future<void> dispose() => db.close();
}
class SessionHandle implements AsyncLifecycle { /* аналогично, через dbHandle.db */ }

class ScreenScopeContainer extends ScopeContainer implements ScreenScope {
  late final dbDep = asyncDep(() => DbHandle());
  late final sessionDep = asyncDep(() => SessionHandle(dbDep.get));
  @override
  List<Set<AsyncDep>> get initializeQueue => [{dbDep}, {sessionDep}];
  @override
  Session get session => sessionDep.get.session;
}
class ScreenScopeHolder extends ScopeHolder<ScreenScopeContainer> {
  @override ScreenScopeContainer createContainer() => ScreenScopeContainer();
}

class _YxScreenState extends State<YxScreen> {
  final _holder = ScreenScopeHolder();
  Object? _error;
  @override void initState() { super.initState();
    _holder.create().catchError((Object e) { if (mounted) setState(() => _error = e); }); }
  @override void dispose() { _holder.drop(); super.dispose(); }   // Future не ждут
  @override
  Widget build(BuildContext context) => _error != null
      ? Text('$_error')
      : ScopeProvider<ScreenScopeContainer>(holder: _holder,
          child: ScopeBuilder<ScreenScopeContainer>.withPlaceholder(
            placeholder: const CircularProgressIndicator(),
            builder: (context, scope) => Text('closed=${scope.session.db.closed}')));
}
```

Журналы (вывод `flutter test`, 2026-10-30):

| Шаг | scopo | Riverpod 3 (scoped) | get_it + watch_it | yx_scope |
|---|---|---|---|---|
| до нажатия | db opening | db opening | db opening | db opening |
| **нажали «обновить»** | | | | |
| | db opened | **db opening** (второй) | **db opening** (второй) | **db opening** (второй) |
| | db closing | db opened | db opened | db opened |
| | db closed | db opened | db opened | session opening |
| | db opening (второй — после закрытия первого) | session opening | session opening | db opened |
| | db opened | session opened | session opened | session opening |
| | session opening | | | session opened |
| | session opened | | | session closing (первый владелец) |
| | | | | session closed |
| | | | | db closing |
| | | | | session opened (второй) |
| | | | | db closed |
| **убрали экран** | | | | |
| | session closing | session closing | session closing | session closing |
| | session closed | **db closing** (до session closed) | session closed | session closed |
| | db closing | session closed | db closing | db closing |
| | db closed | db closed | db closed | db closed |
| Итог по базам | открыто 2, закрыто 2 | открыто 2, **закрыто 1** | открыто 2, **закрыто 1** | открыто 2, закрыто 2 |
| Ошибки | нет | нет | `Bad state: You tried to access an instance of Db that is not ready yet` в `FlutterError` | нет |

Чтение журналов:

- **scopo.** Первый владелец отменён сразу после шага `db` (сам `Db.open`
  неотменяем), его база закрыта, и только после `db closed` второй владелец
  начал `db opening` — очередь `scopeKey` работает. Разборка в обратном порядке
  с ожиданием: `session closed` строго до `db closing`. Прогресс (`path`,
  `value`) показывался на экране ожидания — единственный из четырёх.
- **Riverpod.** Второй владелец стартовал немедленно — две базы открывались
  одновременно. Первая база открылась уже после ухода скоупа; `ref.onDispose`
  зарегистрироваться не успел — **утечка**, базу никто не закрыл. При разборке
  `db closing` начался до `session closed`: `onDispose` синхронный, порядок
  не гарантируется. Без `dependencies`/`overrides` вложенный `ProviderScope`
  вообще не создаёт новый экземпляр — проверено.
- **get_it + watch_it.** Два владельца параллельно; `popScope` старого скоупа
  прошёл, когда его `Db` ещё не был готов — незавершённый async-синглтон
  не получает `dispose`, вторая база утекла. Плюс ошибка «not ready yet»: два
  живых скоупа с одним типом `Db`, `getIt<Db>()` в фабрике `Session` разрешился
  в чужой экземпляр. Это следствие паттерна «тип на экран», который get_it
  не запрещает, но и не защищает.
- **yx_scope.** Два владельца параллельно (`drop()` ждёт окончания `init`,
  а не отменяет его): первый владелец дооткрыл сессию, которую никто не увидит,
  и только потом разобрался. Разборка корректна и полна — утечек нет, порядок
  обратный. Прогресса нет, ветка ошибки — своя, холдер — в `State` руками.

Что зонд не измерял: поведение cobalt, take_it, depend, lean_di (не было
времени поднять ещё четыре интеграции — только документация); поведение при
падении `init` (ветки ошибок написаны, но сценарий не прогонялся); таймауты
scopo (3 с по умолчанию в зонде не истекали).

## 3. Оценки

Шкала 1–10 по восьми осям. **Ось «Задача» измеряет решение именно задачи
из 2.3**, а не полезность пакета вообще — поэтому у Riverpod и get_it она ниже
их реальной ценности; оси «Зрелость» и «Экосистема» компенсируют это в обратную
сторону. Дан и частичный итог «Задача + ЖЦ», чтобы разделить «что умеет»
и «кому верят».

| Пакет | Задача | Корректность ЖЦ | Эргономика API | Документация | Тестируемость | Зрелость и сопровождение | Экосистема | Порог входа | **Итого /80** | Задача+ЖЦ /20 |
|---|---|---|---|---|---|---|---|---|---|---|
| flutter_riverpod 3.4.3 | 5 | 6 | 8 | 9 | 9 | 9 | 9 | 6 | **61** | 11 |
| get_it 9.3 + watch_it 2.5 | 5 | 5 | 7 | 8 | 8 | 10 | 9 | 8 | **60** | 10 |
| flutter_bloc 9.1 | 4 | 6 | 7 | 9 | 9 | 10 | 9 | 6 | **60** | 10 |
| provider 6.1 | 4 | 5 | 8 | 7 | 7 | 9 | 8 | 9 | **57** | 9 |
| yx_scope 1.2 (+flutter, +linter) | 7 | 7 | 7 | 7 | 7 | 7 | 6 | 6 | **54** | 14 |
| flutter_modular 7.1 | 4 | 5 | 6 | 6 | 6 | 8 | 6 | 5 | **46** | 9 |
| **scopo 0.21.0** | **9** | **8** | 5 | 7 | 8 | 3 | 2 | 3 | **45** | **17** |
| disco 2.0 | 3 | 5 | 7 | 6 | 6 | 4 | 3 | 8 | **42** | 8 |
| cobalt 1.9 (+flutter) | 7 | 6 | 6 | 5 | 6 | 2 | 2 | 6 | **40** | 13 |
| depend 5.1 | 5 | 4 | 7 | 5 | 5 | 3 | 1 | 8 | **38** | 9 |
| flutter_lean_di 0.1 | 4 | 4 | 6 | 5 | 6 | 2 | 2 | 7 | **36** | 8 |
| take_it 1.0 | 5 | 4 | 6 | 5 | 5 | 2 | 1 | 7 | **35** | 9 |

Оценки cobalt, depend, take_it, lean_di по осям «Задача» и «ЖЦ» —
по документации, зондом не проверены; поэтому не выше 7 и 6.

**scopo.** По задаче — лучший из двенадцати, и зонд это показал: это
единственный пакет, где два владельца одной базы не перекрылись и ничего
не утекло. «ЖЦ» не 10: таймауты по 3 с, после которых README честно обещает
перекрытие владельцев (`README.md:30-32`); в `docs/handoff.md` висят известные
дыры (падение корневого тела до отмены — наблюдатель молчит; пустой
`ScopeCompositeObserver` прячет падение ребёнка от `FlutterError`; падение
группы вне шага не объявляется). Эргономика — 5: восемь семейств, 117 публичных
типов, три типовых параметра на `Scope<W, D, S>` и слой аксессоров, чтобы их
не писать, плюс 11 шаблонов IDE — симптом, а не лечение. Документация хорошая
по содержанию, но README в 1006 строк и `doc/` в 4188 — это цена, которую
читатель платит до первой строки кода. Тесты — 677, раздел «Testing» есть,
но путь только через `testWidgets`. Зрелость — 3: 0.x, 46 версий за одиннадцать
месяцев, 70 упоминаний «breaking» в CHANGELOG из 43 разделов, один автор, 2
звезды, 3 лайка, pub points ещё не посчитаны, зависимость от собственного
`async_job` 0.6.0 (0 лайков). Экосистема — 2: `navigation_node` и `async_job`
того же автора, ничего внешнего.

**yx_scope.** Ближайший по духу: контейнер объявляет `asyncDep`
и `initializeQueue`, холдер поднимает и роняет в обратном порядке, дети умирают
с родителем, есть линтер и наблюдатели. Чего нет: отмены (`drop` ждёт `init`),
прогресса, очереди владельцев, ветки ошибки в виджете; холдер живёт в `State`
руками, `dispose` виджета его `Future` не ждёт. Издатель Яндекс, 1.x, тесты без
виджетов. Документация в монорепо переезжала — ссылки из README ведут не туда.
Самый сильный конкурент на той же полке.

**cobalt.** Появился 2026-09-05 и за семь недель набрал 23 версии: скоупы,
`init()` по уровням `dependsOn`, `dispose()` «дети первыми, в обратном порядке
создания» под дедлайном 30 с,
`CobaltScopeWidget(builder, loading, errorBuilder)`. По описанию — почти список
фич scopo без отмены, прогресса и ключей. Ноль звёзд, пять лайков, один автор;
оценивать корректность рано, но направление показательно: ниша осознана
не только автором scopo.

**get_it + watch_it.** Де-факто стандарт локатора: скоупы, `pushScope`,
`registerSingletonAsync(dependsOn:)`, `allReady(timeout:)`, `popScope`
с обратным порядком. Но локатор не владеет виджетом: зонд дал утечку
незавершённого синглтона и ошибку разрешения типа между двумя скоупами. Для
задачи 2.3 нужен дисциплинированный код поверх, которого в пакете нет.

**Riverpod 3.** Лучшие в экосистеме экраны загрузки/ошибки и тестируемость,
но модель — глобальный кэш, а не владение: scoping на экран не рекомендуется,
`onDispose` синхронный, отмены тела нет. Зонд показал утечку и неупорядоченное
закрытие. Решает соседнюю задачу (данные и кэш), а не эту (ресурс и его время
жизни).

**provider.** `Provider(create, dispose)` — минимальная привязка объекта
к поддереву, синхронная. Асинхронного старта с ошибкой нет, порядка нет. Автор
сам направляет в Riverpod; последний релиз 2025-08. Остаётся эталоном порога
входа.

**flutter_bloc.** `BlocProvider` создаёт лениво и закрывает при удалении,
`RepositoryProvider` — то же для репозиториев. Асинхронный старт — это событие
и состояние блока; ожидания закрытия и порядка нет. Задача 2.3 решается кодом
приложения, пакет даёт только контейнер.

**flutter_modular.** DI привязан к маршруту, а не к виджету; `binds`
синхронные, асинхронного старта модуля нет, `dispose` только для
`ChangeNotifier`/`Disposable`. Это фреймворк маршрутизации с DI, и брать его
ради жизненного цикла ресурсов — не по адресу.

**disco.** Чистая и маленькая модель «провайдер со `create`/`dispose`
в `ProviderScope`», независимая от стейт-менеджмента. Асинхронности нет вовсе.
Хороший ответ на вопрос «как заменить provider», не на вопрос 2.3.

**depend.** `DependencyScope(factory, builder, placeholder, errorBuilder)` —
асинхронный старт и ошибка в одном виджете, пять типов, низкий порог. Порядок —
руками внутри `factory`, отмены и очереди нет, семантику `dispose` не проверял.
Для простых случаев достаточно.

**flutter_lean_di.** LeanCode, октябрь 2026, 0.1.1: скоупы, привязанные
к дереву, но доступные снаружи, модули, реактивность. Асинхронный старт
и порядок освобождения не проверял. Слишком молод для выводов, но издатель —
компания, а не один человек.

**take_it.** `DiModuleAsync`, `DiScopeBuilder(initializationPlaceholder)`,
конструкторные инъекции. Пять версий, ноль звёзд, одна issue. Та же идея, что
у depend, с другой раскладкой.

## 4. Вывод

**scopo — ниша, не дубликат.** На pub.dev нет пакета, который делает то же:
отмена незавершённого старта по уходу виджета, ожидание детей, обратная
разборка с таймаутами по стадиям, очередь владельцев по ключу, `close()`
с экраном закрытия, наблюдатель с маршрутами ошибок. Зонд на одной задаче дал
scopo единственный журнал без перекрытия владельцев и без утечки; Riverpod
и get_it утекли по базе каждый, yx_scope перекрыл владельцев. Ближайшие
соседи — yx_scope (Яндекс, зрелый, без отмены и очереди) и cobalt (два месяца,
та же идея, без отмены и очереди).

**Кому нужен.** Приложениям, где экран владеет тяжёлым ресурсом с асинхронным
закрытием — БД, камера, плеер, сокет, изолят, Bluetooth-сессия — и где
пересоздание экрана уже приводило к «двум владельцам». Это узкая, но реальная
аудитория. Кому не нужен: типичным REST-приложениям (Riverpod достаточно),
командам на get_it/injectable (переезд ради жизненного цикла не окупится), тем,
кому нужны объекты вне дерева виджетов — scopo их не даёт, доступ только через
`BuildContext`.

**Что мешает принятию** (по убыванию веса):

1. **Нестабильность.** 0.x, 46 версий за 11 месяцев, 70 упоминаний «breaking»
   в CHANGELOG. Никто не строит экран с БД на API, который за год менялся
   десятки раз. Это блокер номер один, и он не технический.
2. **Поверхность.** Восемь семейств, 117 публичных типов, три типовых
   параметра, аксессоры, чтобы их спрятать, одиннадцать шаблонов IDE, README
   в тысячу строк. Читается как фреймворк, а решает одну задачу. Мнение:
   сильный движок с перегруженной кабиной.
3. **Доверие.** 3 лайка, 2 звезды, pub points не посчитаны, один автор,
   единственный пользователь — он же; зависимость `async_job` 0.6.0 с нулём
   лайков — вторая движущаяся деталь под ногами.
4. **Позиционирование.** `pubspec.yaml` описывает пакет как «managing scopes
   and dependency injection» — это полка get_it и Riverpod, где scopo
   проигрывает по всем осям, кроме двух. «Why another one» спорит
   с Provider/Riverpod, но не с yx_scope, get_it-скоупами и cobalt — реальными
   соседями.
5. **Нет пути без виджетов.** Контейнер нельзя поднять и проверить без
   `testWidgets`; yx_scope, cobalt, lean_di это умеют.

   **Вердикт: отвергнуто владельцем как сознательное решение.** «Этот пакет —
   это сознательное решение делать именно Flutter-way». Владелец ресурсов
   скоупа — элемент дерева: ожидание дочерних скоупов, `scopeKey` и `close()`
   держит дерево, и контейнера без виджетов не будет. Инициализацию вне дерева
   по-прежнему проводит `ScopeInitJob`. README говорит об этом прямо — абзац
   «Only in the widget tree, by design» в «Why another one», в той же правке,
   что порядок семейств асинхронными вперёд.

## 5. Рекомендации

По убыванию приоритета. Стоимость и отдача — мнение, в масштабе «низкая /
средняя / высокая».

1. **Заморозить API и выпустить 1.0 с обещанием стабильности.** Стоимость:
   высокая (решить, что остаётся, и перестать трогать). Отдача: самая большая —
   снимает блокер номер один. Всё остальное в этом списке имеет смысл только
   после этого или вместе с ним.

2. **Сократить семейства с восьми до трёх.** Мнение: синхронное
   (`ScopeModel`/`ScopeNotifier` → одно), асинхронное с состоянием (`Scope`),
   асинхронное с контроллером (`AsyncControllerScope`); `LiteScope`,
   `AsyncDataScope`, `ScopeWidgetBase` — либо внутрь, либо в отдельный пакет
   `scopo_extra`. Одиннадцать шаблонов IDE тогда станут тремя. Стоимость:
   высокая (ломающая, переписывание `doc/`). Отдача: высокая — понятность
   и порог входа.

   **Вердикт: отвергнуто владельцем.** «Это лестница. Все семейства построены
   друг на друге. Оставлять только три — это просто прятать остальные, хотя они
   уже есть». Все восемь остаются в главном импорте. Порог входа снижается
   порядком, а не сокращением: README, темы и `dartdoc_options.yaml` ведут
   сначала пять асинхронных семейств от `AsyncScope` до `Scope`, потом три
   синхронных отдельным разделом «Without an asynchronous phase».

3. **Переписать позиционирование.** Описание в `pubspec.yaml`: не «DI»,
   а «lifecycle of resources owned by a screen: ordered async init with
   progress, cancellation on removal, awaited teardown, one owner at a time».
   README — задача 2.3 в первых 60 строках, журнал зонда как аргумент,
   сравнение с yx_scope/get_it-скоупами/cobalt вместо Provider; остальное —
   в `doc/`. Стоимость: низкая–средняя. Отдача: высокая — это то, что читают
   первым.

   **Вердикт: исправлено частично.** `4d70653`: описание и `topics`
   в `pubspec.yaml`, комментарий библиотеки, начало README — сценарий из 2.3
   и таблица против riverpod, get_it, yx_scope и cobalt по зондам
   из `tool/comparison/`. Справочные разделы README в `doc/` не переезжали —
   эта часть в работу не бралась.

4. **Закрыть известные дыры из `docs/handoff.md` до 1.0:** падение корневого
   тела до отмены без сигнала наблюдателю; пустой `ScopeCompositeObserver`,
   глушащий `FlutterError`; падение группы вне шага; непротестированная ветка
   `runsNow == true` в `lite_scope_core.dart`. Стоимость: низкая. Отдача:
   средняя — в пакете, продающем корректность, известные дыры стоят дороже, чем
   где-либо.

   **Вердикт: исправлено, с уточнением к находке.** `553e381`, выпущено
   в 0.21.2 (`4b86155`). Три дыры закрыты, каждую держит тест
   в `test/error_route_test.dart`, падавший до правки. Падение корневого тела
   молчало не всегда, а только когда `Job.isCancellationError` называл его
   отменой: остальные и раньше приходили с `flutterError`; теперь и названное
   доходит до `onError` маршрутом `cancellation`
   с `ScopePhase.initializationCancellation`. Пустой `ScopeCompositeObserver`,
   как и композит из одних пустых композитов, считается отсутствием
   наблюдателя, и непрочитанный сбой ребёнка снова идёт во `FlutterError`.
   Группа, упавшая до первого ребёнка, объявляет сбой своим упавшим шагом:
   наблюдатель слышит его, `FlutterError` получает один отчёт, и за другим
   сбоем тоже. Четвёртая дырой не оказалась: ветка `runsNow == true`
   в `lite_scope_core.dart` недостижима ни в debug, ни в release — состояние
   строится внутри `performRebuild` элемента скоупа, где `isBuilding` всегда
   истинно. Тест на неё не написать; флаг оставлен, причина записана
   комментарием рядом с ним.

5. **Стабилизировать `async_job` первым** (1.0 раньше scopo 1.0) либо свернуть
   его внутрь scopo как `src/`. Стоимость: низкая–средняя. Отдача: средняя —
   одна движущаяся деталь вместо двух.

6. **Чистое Dart-ядро без виджетов** — `ScopeInitJob` + разборка + координатор
   как самостоятельный объект, который можно поднять в `test()` и в сервисе без
   дерева. Стоимость: высокая. Отдача: средняя — открывает лагерь
   yx_scope/lean_di и даёт тестирование без `pumpWidget`. Делать после 1–3,
   не до.

   **Вердикт: отвергнуто владельцем.** По той же причине, что пункт 5 раздела
   4: пакет нарочно сделан по-флаттеровски, и разборка с координатором живут
   в дереве. README говорит об этом прямо — абзац «Only in the widget tree, by
   design» в «Why another one», в той же правке, что порядок семейств
   асинхронными вперёд.

7. **Мост к get_it** — пример или мини-пакет: зависимости скоупа регистрируются
   в `pushScope` при старте и снимаются при разборке, scopo даёт только
   жизненный цикл. Стоимость: средняя. Отдача: средняя — самая большая
   аудитория получает scopo, не бросая локатор.

8. **Линтер** на три ошибки, которые видны в коде зонда: `dep` без
   `dep.dispose`; пересоздаваемый ресурс без `scopeKey`; `setState` там, где
   нужен `notifyDependents`. Стоимость: средняя. Отдача: средняя (у yx_scope
   линтер — заметная часть ценности).

9. **Упростить конфигурацию таймаутов** (мнение): четыре `default*Timeout`
   с одинаковыми 3 с → один бюджет разборки с опциональным переопределением
   по стадии. Стоимость: низкая. Отдача: низкая–средняя.

10. **Статья с зондом** («две базы у одного экрана: Riverpod, get_it, yx_scope,
    scopo») и публикация зонда как `example/comparison`. Стоимость: низкая.
    Отдача: средняя — лайки и звёзды приходят оттуда, а не из README.

    **Вердикт: сделано частично.** `64a4a1c`: оба зонда лежат
    в `tool/comparison/`, а не в `example/`, и таблица в начале README
    ссылается на них (`4d70653`). Статьи нет.

Что убрать или вынести: экран закрытия через `ScreenshotReplacer` — редкая
потребность, кандидат в `scopo_extra` (мнение);
`pauseAfterInitializationEnabled` оставить, но только в `doc/debug.md`.

Сужать или расширять: **сужать.** scopo выигрывает на двух осях из восьми,
и обе про жизненный цикл ресурса, которым владеет экран. Расширение в сторону
«DI-фреймворк» выводит на полку, где у соперников на два порядка больше
пользователей и десятилетие истории.

## Источники

Проверено 2026-10-30, если не указано иное.

- pub.dev API: `https://pub.dev/api/packages/<p>`
  и `https://pub.dev/api/packages/<p>/score` для всех пакетов из таблиц
  (сохранено в `facts.json`, `facts.tsv`, `extra/facts.tsv`);
  `https://pub.dev/api/search?q=…` — 20 запросов.
- GitHub API через `gh api repos/<owner>/<repo>` — `github.json`.
- scopo: `README.md`, `doc/*.md`, `docs/architecture.md`, `docs/handoff.md`,
  `CHANGELOG.md`, `pubspec.yaml`, `lib/` в копии коммита `2ec8211`; строки
  указаны по этому коммиту.
- yx_scope 1.2.2 и yx_scope_flutter 1.2.0: исходники
  из `~/.pub-cache/hosted/pub.dev/` (`lib/src/core_scope_holder.dart`,
  `base_scope_container.dart`, `dep.dart`, `scope_builder.dart`,
  `scope_provider.dart`); документация —
  `https://github.com/yandex/city-services-pub/tree/main/yx_scope`
  (`docs/complete_guide.md`, `packages/yx_scope/README.md`).
- riverpod 3.4.3: исходники (`lib/src/core/override.dart`, `core/ref.dart`,
  `providers/future_provider.dart`);
  `https://riverpod.dev/docs/concepts2/auto_dispose`.
- get_it 9.3.0 / watch_it 2.5.0:
  `https://flutter-it.dev/documentation/get_it/scopes`,
  `https://flutter-it.dev/documentation/get_it/async_objects`, документация
  watch_it на том же сайте.
- provider 6.1.5+1: `https://pub.dev/packages/provider`.
- flutter_bloc 9.1.1: `https://bloclibrary.dev/flutter-bloc-concepts/`.
- flutter_modular 7.1.1: `http://modular.flutterando.com.br/docs/` (раздел
  Dependency Injection).
- cobalt 1.9.2: `https://pub.dev/packages/cobalt`,
  `https://pub.dev/packages/cobalt_flutter`,
  `https://github.com/rutikeyone/cobalt` — только README.
- take_it 1.0.4, depend 5.1.5, flutter_sputnik_di 0.2.1, flutter_lean_di 0.1.1,
  disco 2.0.0, context_plus 6.0.7, lite_ref 0.8.1, zenify 2.3.1 и пакеты групп
  B–E: страницы pub.dev и README — поведение в коде не проверялось.
- Зонд: `/Users/user/.claude/jobs/715c8327/tmp/fable/probe/` —
  `flutter analyze` и `flutter test test/probe_test.dart`, Flutter 3.47.0
  (глобальный), 2026-10-30.
