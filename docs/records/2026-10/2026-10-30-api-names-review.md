# Проход по именам перед 1.0

> **Состояние на 2026-10-31:** волны 1–4 «Предлагаемого порядка» сделаны
> и влиты в `main`: `3b0b890`, `b1e3cd1`, `97ba21e`, `309e05a`, выходят
> в 0.22.0. Вердикты — в конце каждой сделанной находки. Пятая волна
> открыта: Б5–Б9, В1–В4, Г3, Г5–Г7 владелец не одобрил, они ждут решения.
> **Что это:** второй сплошной проход по публичным именам пакета — перед
> заморозкой API в 1.0.0: что врёт, что спорит с соседним, что публично зря.
> **Связанные записи:** `2026-08-18-naming-review.md` (первый проход, его
> решения здесь не переоткрываются без нового довода),
> `2026-10-23-async-job-0.3-surface-design.md` (правило списка реэкспорта
> `async_job`), `2026-10-30-fable-market-review.md` и
> `2026-10-30-opus-market-review.md` («перегруженная кабина»).

Окно то же, что в августе, только шире: после 1.0.0 каждое переименование стоит
мажорной версии, сейчас — ничего, единственный пользователь пакета — владелец.
Проход шёл в четыре стороны параллельно: согласованность восьми семейств слой
за слоем, соглашения об именах (Effective Dart, словарь Flutter, правило
«присваиваемый колбэк — короткий глагол, переопределяемый хук — `onX`»), лишняя
публичная поверхность и словарь событий, фаз и состояний. Опись — 113
верхнеуровневых элементов из dartdoc и 16 имён реэкспорта `async_job`. Каждое
утверждение, на котором стоит предложение, сверено с кодом; одно, которое
не сошлось, исправлено в находке Б5.

Не переоткрываются решения владельца: восемь семейств в главном импорте, только
дерево виджетов, `listen`/`select` во втором импорте; из августовского
прохода — N9 (`paramsOf`/`selectParam`), N10 (`initScope`/`disposeScope`/
`initStateAsync`/`disposeStateAsync`), N12 (тройка хуков `ScopeController`),
N13 (строители контроллера без `progress`). Префикс `Any` у групп состояний
зависимости (N2) переоткрыт в А7 — с доводом, которого в августе не было.

Цена — число вхождений имени целым словом: `lib` / `doc` / `README.md` / `test`
/ `example`. Сверх того каждое публичное переименование — строка
в `CHANGELOG.md` и правка зеркала в `docs/ru/` тем же коммитом.

## А. Имя врёт или спорит с соседним

**А1. `isInitialized` у одного скоупа значит два разных момента.**
`AsyncScopeContext.isInitialized` (`async_scope_context.dart:21`) — «фаза дошла
до `AsyncScopeReady`». `LiteScopeCoreState.isInitialized`
(`lite_scope_core.dart:554`, то же у `ScopeCoreState`) — «собственный
`initStateAsync` этого состояния кончился», то есть позже, когда ветка
готовности уже на экране. У элемента `LiteScope` и `Scope` есть оба. Путаница
уже в тексте: `_stateOrThrow` (`lite_scope_core.dart:206`) советует «check
`isInitialized` first», а единственный `isInitialized`, до которого дотянется
пользователь `LiteScope` снизу, лежит на том самом состоянии, которого нет;
тот же совет повторён в четырёх дартдоках (`lite_scope_base.dart:230`,
`lite_scope_core.dart:81`, `scope_base.dart:224`, `scope_core.dart:74`).
Словарь фазы везде, кроме этого геттера, — «ready»: `AsyncScopeReady`,
`buildOnReady`. Предлагаю `AsyncScopeContext.isInitialized` → `isReady`;
`isInitialized` остаётся на состоянии, в паре с `initStateAsync`; пять
подсказок переписать. Цена (только смысл контекста): около 11 / 4 / 0 / 13 / 0
и 6 в `ide/`.

**Вердикт: исправлено, с уточнением к находке.** Волна 2, `b1e3cd1`.
`AsyncScopeContext.isInitialized` стал `isReady`; `isInitialized` состояния
`LiteScope` и `Scope` и геттер `ScopeDependencyExtension.isInitialized`
остались. Пять подсказок и сообщение `_stateOrThrow` советуют теперь
не переименованный геттер, а `maybeOf`: над скоупом без состояния он отвечает
`null`, а `isInitialized` состояния, которого ещё нет, читающему снизу
не достать — о том и была находка. Шаблоны `ide/` и их копия в `.vscode/`
поправлены тем же коммитом.

**А2. Хуки наблюдателя: `onReady` приходит до готовности, `onDispose`
и `onDisposed` различает одна буква.** `scope_observer.dart`. `onReady` зовётся
сразу (`async_scope_core.dart:334`), а `AsyncScopeReady` доходит до модели
позже — после кадра или после `pauseAfterInitialization`; пока идёт `onReady`,
`isInitialized` ещё `false`. `ScopePrintObserver` сам печатает это событие как
`initialized`, и контейнер зависимостей шлёт тот же `onReady`, хотя слова
«ready» в его состояниях нет. На стороне разбора `onDispose` (начало)
и `onDisposed` (конец) различает буква `d`: переопределение не того
компилируется молча. А `onDispose` в том же экспортированном API уже значит
другое — регистрацию уборки, `ctx.onDispose(temporary.close)`
(`doc/async_scope.md:416`), и так же у Riverpod в README. Выход шага разбора
`onDisposalProgress(target, path)` никакого прогресса не несёт — только путь;
дартдок сам называет его второй половиной `onDisposalStepStarted`. Предлагаю
пары с одной грамматикой: `onInit` → `onInitStarted`, `onReady` →
`onInitialized`, `onDispose` → `onDisposalStarted`, `onDisposed` остаётся,
`onDisposalProgress` → `onDisposalStepFinished`. `onProgress` остаётся:
у скоупа он несёт значение из `ctx.progress`. Цена: `onReady` 6 / 5 / 1 / 9 /
0, `onDisposalProgress` 9 / 9 / 2 / 4 / 1; у `onInit` и `onDispose` счёт смешан
со словом ядра, хуков самих по себе около 12 / 9 / 1 / 20 / 0 и 3 / 2 / 1 / 5 /
0.

**Вердикт: исправлено.** Волна 3, `97ba21e`. Имена как предложено:
`onInitStarted`, `onInitialized`, `onDisposalStarted`,
`onDisposalStepFinished`; `onDisposed` и `onProgress` остались. Строки
`ScopePrintObserver` не менялись — они и раньше говорили `initialize…`,
`initialized`, `dispose…`. Дартдок `onInitialized` теперь говорит, что для
скоупа событие приходит до готовности. `onInitialized` совпал по имени с хуком
состояний `LiteScope` и `Scope`; классы разные, и одно имя у обоих называет
одно событие — конец инициализации. В `doc/debug.md` и зеркале — раздел «Coming
from 0.21.x» с таблицей старых и новых имён, в том числе для А8.
`ctx.onDispose` и `ref.onDispose` не тронуты.

**А3. `compare:` у `select` и `ListenableSelector` возвращает `bool`, и `true`
значит «другое».** `select.dart:41`, `listenable_selector.dart:33`. В Dart
`compare` — это `Comparator`, отдающий `int` (`List.sort`); здесь два дартдока
тратят абзац на то, в какую сторону ответ. Та же сигнатура с тем же смыслом
в пакете уже есть и называется `ScopeStateNotifier.shouldNotify` — её
переименовали из `equals` в августе (N8) ровно по этой причине. Предлагаю
`compare:` → `shouldNotify:`. Цена: 4 / 2 / 0 / 4 / 0.

**Вердикт: исправлено.** Волна 2, `b1e3cd1`. `compare:` стал `shouldNotify:`
у `select` и `ListenableSelector`, с тем же знаком.

**А4. `ScopeDependencyException.name` хранит путь.**
`scope_dependency_exception.dart:9`; дартдок поля: «The path of the
dependency». У `ScopeAutoDependenciesProgress` есть и `path`, и `name`, и там
`name` — последний сегмент пути. Выходит, `exception.name` и `progress.path` —
одно, а `progress.name` — другое; `doc/full_scope.md:413` вынужден пояснять
«the `name` (the path above)». Предлагаю `path`. Цена: доступов к полю —
несколько в `lib` и `test` (сам тип 23 / 4 / 0 / 28 / 2).

**Вердикт: исправлено.** Волна 2, `b1e3cd1`. Поле стало `path`.
Деструктуризация `(:final name)` в `scope_dependency_group.dart` после
механической замены отдавала бы не то поле; поправлена руками.

**А5. `runOutsideFrame` откладывает не до конца кадра, а до конца сборки.**
`is_building.dart:56`. Откладывает только когда `isBuilding` — фаза
`persistentCallbacks`, перестройка скоупа или сборка `runApp`;
из `transientCallbacks` и `postFrameCallbacks` действие идёт сразу, то есть
внутри кадра. Предлагаю `runOutsideBuild`. Цена: 7 / 1 / 0 / 2 / 1.

**Вердикт: исправлено.** Волна 2, `b1e3cd1`. `runOutsideBuild`.

**А6. `ScopeDependencyFailed` — только сбой инициализации, а `isFailed` —
любой.** `scope_dependency_state.dart:85`. Рядом есть
`ScopeDependencyDisposalFailed`, и `isFailed` истинен для обоих: `dep.isFailed`
бывает `true`, когда `dep.state is ScopeDependencyFailed` — `false`. В `switch`
лист `ScopeDependencyFailed()` читается как «любой сбой» и пропускает сбой
разбора. Предлагаю `ScopeDependencyInitFailed`; по желанию
и `ScopeDependencyCancelled` → `ScopeDependencyInitCancelled` — отменённым
бывает только `init` (`scope_dependency_mixin.dart:328`). Цена: 14 / 2 / 0 / 34
/ 0 и 11 / 1 / 0 / 0 / 0.

**Вердикт: исправлено частично.** Волна 4, `309e05a`. `ScopeDependencyFailed`
стал `ScopeDependencyInitFailed`. Необязательная часть,
`ScopeDependencyCancelled` → `ScopeDependencyInitCancelled`, не взята: владелец
одобрил только первую.

**А7. `ScopeDependencyAnySuccess` включает «ещё не начиналось».**
`scope_dependency_state.dart:18`. Его листья — `Initial`, `Initialized`,
`Disposed`, `NoDisposalRequired`; в `isInitialized`
(`scope_dependency.dart:77`) строка `ScopeDependencyAnySuccess() … => false`
читается как «успех — значит не инициализирован». Иерархия на деле делится
по «несёт ошибки или нет». В августе (N2) выбирали между числом и префиксом,
`Initial` в группе успеха тогда не обсуждали. `ScopeDependencyAnyCancelled`
держит ровно один лист и ничего не добавляет. Вне `lib` ни одна из трёх групп
не названа: 11, 0 и 9 вхождений, все в `lib`. Предлагаю не переименовывать,
а убрать из публичного: три группы приватные, API ошибок (`errors()`, `error`,
`count`, `hasErrors`) — на `ScopeDependencyState`, пустой у состояний без
ошибок; вопросы групп и так задают геттеры `isFailed`, `isCancelled`,
`isInitialized`. Цена: исчерпывающий `switch` по иерархии снаружи пишет семь
листьев вместо трёх групп — таких `switch` вне `lib` нет. Семь листьев остаются
публичными: свою `ScopeDependency` снаружи строить можно (в тестах шесть таких
классов), и им нужны конструкторы листьев.

**Вердикт: исправлено, с уточнением к находке.** Волна 4, `309e05a`. Три группы
стали приватными, но не исчезли: внутри на них стоят исчерпывающие `switch`
состояний. API ошибок переехал на `ScopeDependencyState` — к четырём членам
находки добавился `stackTrace`, а `count` стал `errorCount` (Г4). Состояние без
ошибок отвечает пустым `errors()`, нулём и `false`; `error` и `stackTrace`
бросают `StateError`, как и раньше у пустой отмены. Геттеры расширения больше
не называют групп: `isFailed` — исчерпывающий `switch` по листьям, остальные —
проверка `is`. Новый тест `test/scope_dependency_state_test.dart`.

**А8. `ScopeErrorRoute.observer` значит «только наблюдатель».**
`scope_observer.dart:79`. Наблюдатель получает любой маршрут, а этот значит,
что больше никто. Каноническая строка
`if (route != ScopeErrorRoute.observer) return;` (`doc/debug.md:38`,
README:904) читается как «если не направлено наблюдателю». Предлагаю
`observerOnly`. `cancellation` — тоже не маршрут, а «не сбой», но и он доходит
только до наблюдателя; оставить с его дартдоком. Цена `observer`: 7 / 2 / 1 /
17 / 0.

**Вердикт: исправлено.** Волна 3, `97ba21e`. `observerOnly`. Кроме полного
имени поправлено и голое `observer`, которым маршрут назван в прозе и таблице
`doc/debug.md`, в README и в зеркалах.

## Б. Публично зря

**Б1. `AsyncScopeInitState` — пустой тип, которым никто не пользуется.**
`async_scope_state.dart:18`. `sealed` прослойка над `AsyncScopeProgress`
и `AsyncScopeReady`, единственный член — `toString`; «ready» — не «init state»,
а `Waiting` в неё не входит. Похоже на остаток времени, когда `init()` отдавал
`Stream<AsyncScopeInitState>`. Предлагаю удалить; `switch` по четырём листьям
остаётся исчерпывающим. Цена: 5 / 0 / 0 / 0 / 0.

**Вердикт: исправлено.** Волна 1, `3b0b890`. Тип удалён, `AsyncScopeProgress`
и `AsyncScopeReady` наследуют `AsyncScopeState` напрямую.

**Б2. `ScopeModelInheritedElement` — сирота.** `scope_model/base.dart:17`.
Повторяет то, что `ScopeModelElementBase` и так получает
от `ScopeInheritedElement` и `ScopeModelContext`; у других семейств
`XInheritedElement` нет. Предлагаю удалить. Цена: 2 / 0 / 0 / 0 / 0.

**Вердикт: исправлено.** Волна 1, `3b0b890`. `ScopeModelElementBase` реализует
`ScopeModelContext` сам.

**Б3. `ScopeDependencyMixin` снаружи не подмешать.**
`scope_dependency_mixin.dart:48`. Объявляет приватные абстрактные `_runInit`
и `_runDispose` — вне библиотеки их не реализовать. Свои зависимости снаружи
реализуют `ScopeDependency`, а не миксин. Предлагаю `_ScopeDependencyMixin`;
его публичные члены видны унаследованными на `ScopeDependencyGroup`. Цена: 23 /
0 / 0 / 2 (комментарии) / 0. Туда же — публичный статический
`ScopeDependencyState.throwNoErrors`, нужный только внутри: приватным.

**Вердикт: исправлено.** Волна 1, `3b0b890`. `_ScopeDependencyMixin` без
`{@category}`; `throwNoErrors` стал `_throwNoErrors`.

**Б4. `AsyncScopeModel` — пустой интерфейс.** `async_scope_model.dart:14`,
`implements ScopeStateModel<AsyncScopeState> {}`. Его цель «чтобы снаружи
нельзя было писать» уже выполнена: `ScopeStateModel` только для чтения.
Предлагаю влить в `ScopeStateModel<AsyncScopeState>` в двух сигнатурах
(`AsyncScopeCore`, `AsyncScopeElementBase.model`). Цена: 7 / 0 / 0 / 0 / 0.

**Вердикт: исправлено.** Волна 1, `3b0b890`. Интерфейс удалён вместе
с `_AsyncScopeModelView`; в файле остался приватный нотифаер, а модель
асинхронного скоупа — `ScopeStateModel<AsyncScopeState>`.

**Б5. Typedef'ы `Scope`: три строителя не совпадают ни с одним параметром.**
`full_scope/scope_base.dart:9, 17, 25, 32`. `ScopeWaitingBuilder`,
`ScopeProgressBuilder<P>`, `ScopeErrorBuilder<P>` и `ScopeInitCallback<D>`;
ни одна сигнатура пакета их не использует — асинхронные семейства пишут типы
строителей на месте. `ScopeWaitingBuilder` отдаёт `Widget?`, чего в пакете нет
нигде; параметр `P` спорит с каждым `buildOnProgress(…, Object? progress)`,
и демо обходит это `covariant String? progress`
(`example/scopo_demo/lib/app/app.dart:75`). Мёртвыми они при этом не являются:
`example/scopo_demo` держит `ScopeInitCallback` и `ScopeProgressBuilder`
в полях своих виджетов (`app.dart:18–19`, `home.dart:41`) — ровно для такой
передачи их и заводили (`doc/full_scope.md:95`). Предлагаю удалить
`ScopeWaitingBuilder` и `ScopeErrorBuilder`, а `ScopeProgressBuilder` привести
к `Object?` без параметра типа или удалить вместе с ними; `ScopeInitCallback`
оставить. Цена: по 1 в `lib`, одна фраза в `doc`, 3 места в демо.

**Б6. Представления `ScopeStateModelView` и `ScopeStateWithErrorModelView`.**
`scope_state_model.dart:55`, `scope_state_with_error_model.dart:95`. Наружу их
выводит только тип возврата `asUnmodifiable()`. Прецедент в самом пакете:
`_AsyncScopeModelView` приватный. Предлагаю приватные представления
и `asUnmodifiable()`, отдающий интерфейс. Минус два имени. Цена: 6 / 3 / 0 / 2
/ 0 и 4 / 1 / 0 / 2 / 0, плюс абзац о моках в README:951. Шире: тройку
`ScopeStateWithError*` `doc/scope_notifier.md:132` сам называет неиспользуемой
и советует держать сбой внутри состояния; её можно убрать целиком или
превратить в рецепт в документе. Это вопрос к владельцу, не находка.

**Б7. Верх двух веток лестницы: `ScopeCore`/`ScopeElementBase`/
`ScopeCoreState` и `AsyncControllerScopeCore`/`…ElementBase`.**
`scope_core.dart:7, 108, 371`, `async_controller_scope_core.dart:4, 52`. Слои
публичны, чтобы на них строили свои семейства, но эти — вершины своих веток,
на них не построено ничего ни в пакете, ни в примерах; `ScopeCore*` вне `lib`
не названы вовсе (14 / 0 / 0 / 0 / 0, 11 / 0 / 0 / 0 / 0, 11 / 0 / 0 / 2 / 0),
`AsyncControllerScopeCore*` — один тест и одна строка
в `doc/async_controller_scope.md:43`. Довод против: ломается правило «у каждого
семейства есть слой Core», и пропадает путь «свой элемент для полного `Scope`».
Уверенность средняя, решение владельца.

**Б8. `CompareUtils` и `ListenableView`.** `compare_utils.dart:11`,
`listenable_view.dart:4`. Оба внутри пакета не используются; `CompareUtils` —
четыре однострочных лямбды, которые дартдок `select` и так показывает в строку;
`ListenableView` — десять строк, пересекается с `ScopeStateModelView`. Цена: 3
/ 2 / 0 / 13 / 0 и 2 / 2 / 0 / 4 / 0. Уверенность низкая: обе вещи
документированы как утилиты, и удалять их — решение о составе пакета,
а не об именах.

**Б9. Реэкспорт `async_job`: пять самых слабых имён.** Правило списка
из `2026-10-23-async-job-0.3-surface-design.md` — имя в списке, только если оно
нужно тому, кто пишет `initScope`; там же — добавить имя потом ничего
не ломает, убрать ломает. Нужны сигнатурами или пользователями: `Cancelled`,
`JobContext`, `Job`, `DeferredJob`, `JobObserver`; для чтения исхода
`ScopeInitJob` — `Outcome`, `Done`, `Failed` (набором). Только тесты, ни одного
документа: `ManualCancelReason`, `HandlerCancelReason`, `SiblingCancelReason`
(та запись сама зовёт его «weaker»), `JobAnswerer`, `JobErrorAnswer`.
По тому же правилу эти пять можно убрать к 1.0, а редкий пользователь
импортирует `async_job` сам. Это частичный разворот решения 2026-10-23,
поэтому — вопрос.

**Проверено и оставлено публичным:** `ScopeInheritedWidget` (граница каждого
`ScopeContext<W>`), `ScopeContext` и пять контекстов семейств (их отдаёт `of`),
`ScopeObservable` (тип параметра каждого хука наблюдателя), все `*ElementBase`,
кроме названных в Б7 (каждый `XCore` называет свой в границе типа),
`ScopeDependencyGroup`, `ScopeDependencyHandle`, `ScopeDependencyException`,
`ScopeDependencyInfo`, `ScopeDependencyExtension`, `ProgressIterator`
и `Progress` (пример и шаблоны `ide/`), `ScopeAutoDependenciesProgress`,
`ListenableSelector`, `StateAsNotifier` (рецепт в примере), `ScopeStateModel`,
`ScopeStateNotifier`, `AsyncScopeParent` (примешан и к элементу,
и к `AsyncScopeCoordinator`, называет роль), `ScreenshotReplacer`
(документирован как самостоятельный виджет, на его `maxRetries` ссылаются два
документа), `IsBuildingExtension` (имя типа почти не пишут; спорно только имя
члена, см. А5).

## В. Согласованность семейств

**В1. Четыре смысла слова «state», и два сталкиваются на одном элементе.** (а)
объект вроде `State` Flutter: `LiteScopeState`, `ScopeState`, `*CoreState`; (б)
фаза жизненного цикла: `AsyncScopeState`, `AsyncScopeContext.state`,
`buildOnState`; (в) значение нотифаера: `ScopeStateModel`; (г) статус узла
зависимости: `ScopeDependencyState`. (в) и (г) в порядке, а (а) и (б) живут
на одном элементе `LiteScope`, и текст уже путает их: исключение
в `lite_scope_core.dart:204` — «it has no state: the state is created in the
ready branch, and this scope is ${model.state}» — оба смысла в одной фразе.
Предлагаю `AsyncScopeState` → `AsyncScopeStatus`, `.state` → `.status`,
`buildOnState` → `buildOnStatus`; `Phase` занято `ScopePhase`. Цена:
`AsyncScopeState` 18 / 1 / 1 / 16 / 1, `buildOnState` 8 / 0 / 0 / 17 / 1, плюс
часть обращений `.state`. Минимум, если дорого, — переписать то исключение
и подсказку в `ide/scopo.code-snippets:483`.

**В2. `XElementBase` против `XCoreState` в паре с одним `XCore`.** В семействе
`LiteScope` — `LiteScopeCore`, `LiteScopeElementBase`, `LiteScopeCoreState`;
так же у `Scope`. При этом `Base` значит два уровня: `AsyncScopeBase` — слой
подклассов над Core, а `AsyncScopeElementBase` — элемент уровня Core (элемент
самого `AsyncScopeBase` приватный). Читатель естественно примет
`AsyncScopeElementBase` за элемент `AsyncScopeBase`. Предлагаю все восемь
`XElementBase` → `XCoreElement`: тогда у `Base` один смысл, а Core приходит
тройкой `XCore`/`XCoreElement`/`XCoreState`. Цена всех восьми: около 95 / 4 / 0
/ 45 / 4; пишут эти имена только авторы своих Core.

**В3. `ScopeContext` выглядит контекстом семейства `Scope`.** `base.dart:137`.
`ScopeModelContext`, `AsyncScopeContext`, `AsyncDataScopeContext`,
`AsyncControllerScopeContext` — интерфейс чтения своего семейства,
а `ScopeContext` — корень пакета; у семейства `Scope` своего контекста нет.
Соседи по корню — `ScopeInheritedWidget` и `ScopeInheritedElement`. Предлагаю
`ScopeInheritedContext`. Цена: 87 / 7 / 0 / 1 / 0, почти всё — механические
`ScopeContext.of<…>` в фасадах. Уверенность ниже средней.

**В4. `ScopeModelBase` и `ScopeNotifierBase` — единственные `XBase` без
переопределяемых хуков.** `create` и `dispose` у них — поля конструктора,
и подкласс передаёт замыкание в `super`
(`example/scopo_demo/lib/app/theme_manager/theme_manager.dart:21`). У всех
остальных `XBase` — хуки (`initScope`, `initData`, `createController`). Можно
`createModel`/`disposeModel` хуками; это смена формы, а не имени, и нынешнюю
форму защищает правило «присваиваемый колбэк — короткий глагол». Уверенность
низкая.

**Проверено и ровно:** голые `LiteScope` и `Scope` против `ScopeWidgetBase`
(голый `ScopeWidget` спорил бы с общим термином «scope widget» и корнем
`ScopeWidgetCore`); `of` без `listen` у `LiteScope` и `Scope` (для вызова
методов, подписка — `select`); разное, что отдаёт `X.of` (модель, виджет,
состояние или контекст — асинхронным нужен контекст, потому что груза может ещё
не быть); `builder` против `buildOnReady` (паритет с `ScopeModel.builder`
и `FutureBuilder`); `.value` только у двух синхронных семейств; `onMount`
только там, где нет синхронного хука монтирования; `close`, `of`/`maybeOf`/
`select`, таймауты, `buildOn*` — ровно; отсутствие `ScopeNotifierContext`
(семейство не добавляет ничего для чтения).

## Г. Соглашения

**Г1. `autoSelfDependence` — существительное у булева.**
`scope_widget_core.dart:346`; дартдок переводит его: «Whether the subtree must
be rebuilt on every notification». Предлагаю `rebuildsOnNotify`. Цена: 5 / 1 /
0 / 0 / 0.

**Вердикт: исправлено.** Волна 2, `b1e3cd1`. `rebuildsOnNotify`.

**Г2. `autoDisposeOnError` читается приказом.**
`scope_auto_dependency.dart:28`. Effective Dart: булево свойство —
неповелительный глагольный оборот. Предлагаю `disposesOnError`. Цена: 8 / 4 / 0
/ 20 / 0.

**Вердикт: исправлено.** Волна 2, `b1e3cd1`. `disposesOnError`, вместе
с текстами сообщений.

**Г3. `AsyncScopeError` — состояние, названное как `Error`.**
`async_scope_state.dart:48`. В Dart тип `…Error` — подкласс `Error`, ошибка
программиста; дартдок конструктора сам говорит «Creates the failed state»,
соседи — `ScopeDependencyFailed` и `Failed` ядра; рядом в тех же файлах
`AsyncError` из `dart:async`. Довод против: в паре с `buildOnError`,
`errorBuilder`, `hasError`. Предлагаю `AsyncScopeFailed`, строители не трогать
(у Flutter тоже `Image.errorBuilder`). Цена: 14 / 3 / 0 / 14 / 1. Уверенность
средняя: из двух ревьюеров один за, другой оставил бы.

**Г4. `count` значит две вещи.** У `ScopeDependency` — число шагов
(`scope_dependency.dart:29`), у групп с ошибками — число ошибок
(`scope_dependency_state.dart:36`). Предлагаю `stepCount` и `errorCount`;
вторая половина уходит сама, если принять А7. Цена: около 5 в `lib`.

**Вердикт: исправлено.** Волна 4, `309e05a`. `ScopeDependency.count` стал
`stepCount`, число ошибок — `errorCount` на `ScopeDependencyState`.

**Г5. `ctx.progress(x)` — существительное у метода с побочным действием.**
`scope_init_context.dart:21`; вызов может бросить `Cancelled`, и аргумент тоже
зовётся `progress`. Предлагаю `reportProgress`. Цена высокая: около 4 / 16 / 3
/ 23 / 9. Уверенность низкая — имя короткое и привычное.

**Г6. `ProgressIterator` — не `Iterator`.** `progress_iterator.dart:26`;
ни `moveNext`, ни `current` — счётчик шагов. В августе (N19) правили его члены,
имя типа не обсуждали. Возможное имя — `ProgressCounter` (`Stepper` занят
виджетом Material). Цена: 5 / 7 / 1 / 10 / 1. Уверенность низкая.

**Г7. Правило колбэков в тексте уже, чем на деле.** Нарушений правила
«присваиваемый колбэк — глагол, хук — `onX`» нет, если «присваиваемый» значит
поле, которое пишет пользователь: `dep.unmount`, `dep.dispose`,
`ScopeModel(create:, dispose:)`, `ScopePrintObserver.output`. Но колбэки
конструкторов виджетов идут по стилю Flutter: `onScopeKeyTimeout` и три соседа,
`AsyncScope(onMount:, onUnmount:)`, `ScreenshotReplacer.onCompleted`. Предлагаю
дописать в правило, что событийный параметр конструктора — `onX`. Имена
не меняются.

**Проверено и оправдано:** `ScopeTimeout.none` (как `Timeout.none`
в `package:test`), `maxRetries` (дартдок совпадает с именем),
`ScreenshotReplacer` («snapshot» у Flutter занят `SnapshotWidget`),
`IsBuildingExtension`, `boundsDisposeScopeItself` и `reportsOwnLifecycle`
(неповелительные обороты, `@protected`), `params` (`State.widget` у состояния
скоупа бросает намеренно), `initStateAsync`/`disposeStateAsync` (суффикс уводит
от `initState` и запечатанного `dispose`), `ScopeController.mounted` (смысл как
у `State.mounted`), `setError` (два аргумента), `asUnmodifiable`,
`StateAsNotifier`, `ScopeAutoDependencies` («Auto» размыто, но цена 15 / 14 / 2
/ 99 / 3 несоразмерна), `AsyncScopeWaiting`/`Progress`/`Ready` (один к одному
с `buildOnWaiting`/`Progress`/`Ready`), три слова `Ready`, `Initialized`,
`Done` (ветка интерфейса, жизненный цикл с разбором, исход задачи — префиксы их
разводят), `ScopeDependencyInitial` (соглашение BLoC),
`ScopeDependencyNoDisposalRequired` (в паре с `disposalRequired`), значения
`ScopePhase`, кроме Д1, `ScopeErrorRoute.flutterError`/`zone`/`caller`,
`ScopeCompositeObserver`, `ScopePrintObserver`. `JobObserver` и `ScopeObserver`
говорят разными глаголами о похожем и оба несут `onError` с несовместимыми
сигнатурами — это разные слои, и разделение оправдано.
`ScopeConfig.default…Timeout` мешают существительные и глагольные обороты,
но цена (`disposeScopeTimeout` один — 33 / 9 / 0 / 45 / 2) несоразмерна.

## Д. Неверные тексты, найденные по пути

Не имена, но публичные дартдоки, которые расходятся с кодом. Чинятся без
вопроса, той же волной.

**Д1. `ScopePhase.preparationForDisposal` описан как «the synchronous half of a
teardown».** `scope_observer.dart:41`, `doc/debug.md:267`. Код ждёт его:
`await _prepareForDisposal()` (`async_scope_core.dart:1316`); шаг снимает
ожидание ключа, отменяет инициализацию под пределом времени и зовёт колбэки
таймаута. Описать, что он делает и какой пользовательский код падает под этой
фазой.

**Вердикт: исправлено.** Волна 1, `3b0b890`. Дартдок и строка таблицы
в `doc/debug.md` и зеркале называют, что шаг делает.

**Д2. Дартдок `ScopeDependencyExtension.isCancelled`: «initialization or the
disposal was cancelled».** `scope_dependency.dart:84`. Отменённым бывает только
`init` (`scope_dependency_mixin.dart:328`).

**Вердикт: исправлено.** Волна 1, `3b0b890`. «Whether the initialization was
cancelled. A disposal is never cancelled…».

**Д3. Сообщение `ScopeDependencyHandle`: `'helper already disposed'`.**
`scope_dependency_handle.dart:11` — слово от `DepHelper`, переименованного
в августе (N4).

**Вердикт: исправлено.** Волна 1, `3b0b890`. `'dependency already disposed'`.

## Предлагаемый порядок

1. Удаления без потерь: Б1, Б2, Б3, Б4, `throwNoErrors`, и Д1–Д3.
2. Дешёвые переименования с высокой уверенностью: А1, А3, А4, А5, Г1, Г2.
3. Словарь наблюдателя целиком: А2 и А8 — одним заходом, это одна страница
   `doc/debug.md`.
4. Состояния зависимости: А6 и А7 (с Г4) — тоже одним заходом.
5. Что решит владелец: Б5, Б6, Б7, Б8, Б9, В1, В2, В3, В4, Г3, Г5, Г6, Г7.
