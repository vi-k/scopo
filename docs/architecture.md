# Архитектура scopo

> Обновлено: 2026-10-23, по коду версии 0.17.0 (`main`, `f8ca4b7`).
> Документ описывает устройство пакета изнутри: слои, жизненный цикл,
> координацию и инварианты. Публичный API и примеры использования — в
> `README.md`, `doc/` и dartdoc; текущее состояние работ — в `docs/handoff.md`.
> Расходится с кодом — верен код, документ надо поправить.

## 1. Опорные идеи

scopo связывает ресурсы с деревом виджетов через `ScopeInheritedWidget`
и `ScopeInheritedElement` (`lib/src/scope/base/base.dart`). Три опорных
решения:

- Циклом владеет элемент: `ScopeWidgetElementBase.build` однократно вызывает
  `init`, а `unmount` разбирает и частично упавшую инициализацию.
- Уведомление отделено от сборки: `notifyDependents` будит подписчиков,
  `_builtChild` сохраняет поддерево
  (`lib/src/scope/scope_widget/scope_widget_core.dart`).
- Инициализация — `ScopeInitJob` с прогрессом через `ScopeInitContext.progress`
  (`lib/src/scope/async_scope/scope_init_context.dart`). Внешнее ядро
  `async_job: ^0.3.0` объявлено в `pubspec.yaml`.

## 2. Карта исходников и библиотек

`lib/scopo.dart` — точка публичных экспортов. Она реэкспортирует библиотеку
`lib/src/scope/scope.dart`, выбранные имена ядра задач, конфигурацию и утилиты.
`JobBase` и `JobContextBase` берутся внутренним импортом `engine.dart` ядра;
через публичный список ядра в `lib/scopo.dart` они не выдаются.

Файлы подкаталогов скоупов — `part of` библиотеки `lib/src/scope/scope.dart`,
кроме импортируемой `lib/src/scope/async_scope/scope_coordination.dart`.
Приватные члены частей видны всем слоям.

| Каталог | Где искать реализацию |
| --- | --- |
| `lib/src/scope/base/` | `base.dart`: поиск, контексты, интерфейс элемента, отчёт о вторичных ошибках |
| `lib/src/scope/scope_widget/` | `scope_widget_core.dart`: элемент, аспекты, кэш сборки; `scope_widget_base.dart`: именованный фасад |
| `lib/src/scope/scope_model/` | `base.dart`: владение моделью; `scope_model_core.dart`: основа; `scope_model_base.dart` и `scope_model.dart`: фасады |
| `lib/src/scope/scope_notifier/` | `scope_notifier_core.dart`: подписка на модель; `scope_notifier_base.dart`: её замена; `scope_notifier.dart`: колбэки; `scope_state_model/`: модели состояния |
| `lib/src/scope/async_scope/` | `async_scope_core.dart`: жизненный цикл; `scope_init_context.dart`: задача и адаптер ошибок; `async_scope_state.dart` и `async_scope_model.dart`: фазы и модель; `async_scope_context.dart`: интерфейс чтения |
| `lib/src/scope/async_scope/` | `async_scope_base.dart` и `async_scope.dart`: фасады; `async_scope_parent.dart`, `async_scope_coordinator.dart`, `scope_coordination.dart`: ожидание детей и ключей |
| `lib/src/scope/async_data_scope/` | `async_data_scope_core.dart`: принятие данных; файлы `async_data_scope_base.dart`, `async_data_scope.dart`, `async_data_scope_context.dart`: фасады и контекст |
| `lib/src/scope/async_controller_scope/` | `scope_controller.dart`: контроллер; `async_controller_scope_core.dart`: владение; `async_controller_scope_base.dart`, `async_controller_scope.dart`, `async_controller_scope_context.dart`: фасады и контекст |
| `lib/src/scope/lite_scope/` | `lite_scope_core.dart`: состояние и закрытие; `lite_scope_base.dart`: `LiteScope`, `LiteScopeState`, аксессор |
| `lib/src/scope/full_scope/` | `scope_core.dart`: контейнер и состояние; `scope_base.dart`: `Scope`, `ScopeState`, типы колбэков; `scope_dependencies.dart`: интерфейс контейнера |
| `lib/src/scope/full_scope/scope_auto_dependency/` | `scope_auto_dependency.dart`: автоматический контейнер; `scope_auto_dependencies_progress.dart`: прогресс; `scope_dependency/`: узлы, группы, состояния, ошибки |

`lib/src/environment/scope_config.dart` — отдельная библиотека; файлы
`lib/src/environment/scope_observer.dart`
и `lib/src/environment/scope_timeout.dart` — её части. В `lib/src/utils/` файлы
самостоятельны, кроме `lib/src/utils/listenable/select.dart`: это часть
`lib/src/utils/listenable/listen.dart`.

| Путь | Назначение |
| --- | --- |
| `test/` | Тесты слоёв и сквозных контрактов; `test/utils/` — общие помощники, `test/ide/` — развёрнутые шаблоны |
| `example/minimal/` | Минимальное приложение с отдельным `pubspec.yaml` |
| `example/scopo_demo/` | Демо семейств, прикладные зависимости и свои виджет-тесты |
| `doc/` | Публичные темы dartdoc; настройки включения — `dartdoc_options.yaml` |
| `docs/` | Внутренние архитектура, состояние и бэклог; `docs/records/` — исторические записи |
| `docs/ru/` | Русские зеркала публичных страниц с сохранением путей оригиналов |
| `ide/` | `ide/scopo.code-snippets` для VS Code, `ide/scopo-live-templates.xml` для IntelliJ и инструкция `ide/README.md` |

`docs/ru/stamp.sh` записывает blob-хеш оригинала в перевод; `docs/ru/check.sh`
проверяет хеши и наличие зеркал, но не смысл перевода. По `.pubignore` `docs/`
исключён из пакета, `doc/` входит. `NavigationNode` принадлежит отдельному
пакету `navigation_node`, от которого зависит демо
(`example/scopo_demo/pubspec.yaml`).

## 3. Слои и публичные семейства

Ниже стрелка означает наследование от левого класса к правому. Координаты
классов — соответствующие файлы основы из карты §2.

- Виджеты: `ScopeInheritedWidget` → `ScopeWidgetCore` → `ScopeModelCore`.
  От последнего независимо наследуются `ScopeNotifierCore` и `AsyncScopeCore`.
- Асинхронные ветки: `AsyncScopeCore` → `AsyncDataScopeCore` →
  `AsyncControllerScopeCore`; другая ветка — `AsyncScopeCore` → `LiteScopeCore`
  → `ScopeCore`.
- Элементы: `ScopeWidgetElementBase` → `ScopeModelElementBase` →
  `ScopeNotifierElementBase` → `AsyncScopeElementBase`. Далее —
  `AsyncDataScopeElementBase` → `AsyncControllerScopeElementBase` либо
  `LiteScopeElementBase` → `ScopeElementBase`.

Асимметрия намеренная: виджет `AsyncScopeCore` наследует модельную основу,
а элемент использует подписку `ScopeNotifierElementBase.init`, поскольку
`AsyncScopeModel` реализует `ScopeStateModel` с интерфейсом `Listenable`.
Модель создаётся как `_AsyncScopeNotifier`, наружу отдаётся представление
`asUnmodifiable` (`lib/src/scope/async_scope/async_scope_model.dart`).

| Именованный слой | Готовый виджет с колбэками | Что хранит |
| --- | --- | --- |
| `ScopeWidgetBase` | — | Параметры виджета; свой `build` |
| `ScopeModelBase` | `ScopeModel` | Произвольную модель |
| `ScopeNotifierBase` | `ScopeNotifier` | Модель `Listenable` с подпиской элемента |
| `AsyncScopeBase` | `AsyncScope` | Модель фазы и пользовательскую инициализацию |
| `AsyncDataScopeBase` | `AsyncDataScope` | Данные, доступные после успеха |
| `AsyncControllerScopeBase` | `AsyncControllerScope` | `ScopeController` как данные |
| `LiteScope` | — | `LiteScopeState`, создаваемый в готовой ветке |
| `Scope` | — | `ScopeDependencies` и `ScopeState` |

Основы с окончанием Core допускают собственный элемент. Интерфейсы чтения —
`ScopeContext`, `ScopeModelContext` и контексты асинхронных семейств. Аксессоры
`ScopeWidgetAccess`, `ScopeModelAccess`, `ScopeNotifierAccess`,
`AsyncScopeAccess`, `AsyncDataScopeAccess`, `AsyncControllerScopeAccess`,
`LiteScopeAccess`, `ScopeAccess` в файлах фасадов связывают типы поиска.
У `LiteScope` и `Scope` поиск возвращает состояние.

В `lib/src/scope/scope_model/base.dart` миксин `_ScopeModelElementMixin`
создаёт и освобождает собственную модель; конструктор `.value` передаёт модель
без владения. Смена режима на том же элементе запрещена ассертом. Подписка
`ScopeNotifier.value` переносится в `_ScopeNotifierElement.update` до вызова
родительского обновления и его сборки.

В `lib/src/scope/scope_notifier/scope_state_model/` находятся модели
`ScopeStateModel`, `ScopeStateWithErrorModel`, их изменяемые реализации
`ScopeStateNotifier`, `ScopeStateWithErrorNotifier` и представления для чтения.
`update` сохраняет значение независимо от `shouldNotify`; после `setError`
обновление снимает ошибку и уведомляет.

## 4. Подписки, аспекты и сборка

Координаты: `ScopeContext._find` в `lib/src/scope/base/base.dart`;
`_ScopeDependencies`, `_notifyDependent`, `notifyDependents`, `build`
в `lib/src/scope/scope_widget/scope_widget_core.dart`.

Поиск по точному типу — `getElementForInheritedWidgetOfExactType`. `select`
передаёт в `dependOnInheritedElement` аспект из значения и селектора; подписка
без селектора перекрывает точечные. Прослушиваемый неудачный поиск тоже
регистрируется, чтобы перенос под подходящий скоуп разбудил потребителя.
Регистрации прохода `_currentBuildPass` заменяются следующим проходом. В debug
допустима своя сборка или поддержанный целиком повторяемый построитель
разметки; подписка из `init`, между кадрами и из построителя элементов ленивого
списка запрещена. Самозависимости хранятся отдельно в `_selfDependencies`.

`_notifyDependent` сравнивает значение через неравенство, сбрасывает изменённую
регистрацию и вызывает `didChangeDependencies`. Ошибка повторного вычисления
селектора репортится и считается изменением. Ошибка исходного `select`
оставляет через `finally` подписку на любое изменение для восстановления.

`notifyDependents` ставит `_notifyPending`, при сборке откладывая уведомление
до конца кадра. `performRebuild` забирает флаг в `_rebuildIsNotifyOnly`: новое
уведомление не меняет режим уже идущего прохода. В этом режиме `build`
возвращает `_builtChild`, `updateChild` сохраняет элемент ребёнка.
`_forceRebuild` и `autoSelfDependence` требуют настоящей сборки. Кэш должен
быть непустым; сбой `buildChild` обнуляет его для восстановления.

## 5. Задача и асинхронный жизненный цикл

Координаты: `ScopeInitJob`, `_ScopeInitContext`
в `lib/src/scope/async_scope/scope_init_context.dart`; `performRebuild`,
`_performAsyncInit`, `_settleInit`, `_prepareForDisposal`,
`_performAsyncDispose` в `lib/src/scope/async_scope/async_scope_core.dart`.

`ScopeInitJob` наследует `JobBase` и реализует `DeferredJob`: тело получает
`ScopeInitContext`, дополняющий `JobContext` методом `progress`: тот вызывает
`check` до публикации. Контрольные точки, дети и очистка — механизмы ядра;
`cancel` ждёт их вместе с телом.

После сборки с успешным `init` метод `performRebuild` запускает
`_performAsyncInit` один раз по `_didStartAsyncInit`. Регистрация у родителя —
в конце кадра. После доступа по ключу назначаются задача, `_rootJob`,
`_settleInit`, вызывается `start`. Тело `runInitBody` делегирует
`initScopeAsync`; фасад вызывает `initScope`, у данных — `initData` через
`initDataAsync`, у полного скоупа — `initDependencies`.

`_settleInit` читает `done` после завершения тела, детей и очистки задачи:

| Исход | Действие |
| --- | --- |
| `Done` | `_acceptInitValue`, затем `_settleReady`: сразу `_initSucceeded`, `_initCompleter`, событие готовности; `AsyncScopeReady` — в конце кадра или по таймеру `pauseAfterInitialization` |
| `Failed` | `_settleFailure` объявляет сбой, живому не разбираемому элементу ставит `AsyncScopeError` с последним прогрессом |
| `Cancelled` | Причина `_ScopeDisposalCancelReason` ожидаема; другая отмена попадает в `_settleFailure` |

Фазы модели — `AsyncScopeWaiting`, `AsyncScopeProgress`, `AsyncScopeReady`,
`AsyncScopeError` (`lib/src/scope/async_scope/async_scope_state.dart`);
`buildOnState` выбирает экран. `_onInitStep` отклоняет прогресс после успеха,
ошибки, удаления или начала разбора.

`_prepareForDisposal` отменяет ожидание ключа и запрашивает отмену задачи.
`initCancellationTimeout` ограничивает ожидание: обычный `await` продолжает
работу. После истечения лимита разбор идёт дальше; поздний ресурс освобождает
`onDiscard`. В `runInitBody` это `disposeScope` после возврата
`initScopeAsync`; у данных — `releaseLateData`
из `lib/src/scope/async_data_scope/async_data_scope_core.dart`, у контейнера —
`releaseLateDependencies` из `lib/src/scope/full_scope/scope_core.dart`.
Значения принимаются через `_acceptInitValue` только при `Done`. Частично
упавшее тело освобождает своё само; автоматический контейнер — внутри `init`.

Разбор ядра: синхронный `unmountScope` → подготовка и отмена инициализации →
ожидание зарегистрированных детей → `disposeScope` при `_initSucceeded` →
снятие регистрации у родителя, выход из очереди и разбор модели в `finally`.
Этапы ограждены отдельно: первый сбой передаётся вызывающему, дополнительные
репортятся. `_awaitBounded` ограничивает ожидание, оставляет работу идти
и отдельно принимает её позднюю ошибку.

| Поле элемента | Назначение |
| --- | --- |
| `_initSucceeded` | Ресурс принят, даже если готовая ветка ещё не показана |
| `_isDisposing` | Ядро уже приступило к разбору; одного `mounted` недостаточно |
| `_initJobRunning`, `_disposalFinished` | Удерживать сохранённый `_widget` для позднего завершения задачи, затем отпустить |
| `_scopeKeyObserved`, `_scopeKeySettled` | Ключ зафиксирован для работы; обязательства по нему закончены |
| `_acquiredScopeKey`, `_acquiredCoordinator` | Реальные ключ и очередь, с которыми сверяется диагностика |

В `lib/src/scope/async_controller_scope/scope_controller.dart` обёртки
`performInit`, `performUnmount`, `performDispose` обеспечивают один цикл
контроллера и общий результат его разбора. `AsyncControllerScopeElementBase`
в `lib/src/scope/async_controller_scope/async_controller_scope_core.dart`
освобождает контроллер также после неудачной инициализации и позднего возврата.

## 6. Два канала ошибок

Координаты: `_ScopeInitObserver.onError`, `onUnanswered`, `_announce`
в `lib/src/scope/async_scope/scope_init_context.dart`; `_settleFailure`
в `lib/src/scope/async_scope/async_scope_core.dart`.

`ScopeObserver.onError` — журнал сбоев с фазой. `_announce` использует набор
по идентичности: ошибка, прошедшая через несколько задач и settlement корня,
объявляется один раз с первой фазой. `onError` уступает объявление владельцу,
только когда задача — `_rootJob` либо помеченная `_failureCarriedByOwner` ветка
группы, ошибка совпадает с `_bodyError` и задача ещё не отменена. Произвольный
дочерний `ScopeInitJob` такого исключения не получает.

У остальных ошибок `onError` выбирает фазу: завершённая задача —
`abandonedWait`, отменённая — `initializationCancellation`, прочая —
`initialization`. Ошибки очистки или оставленной работы сами по себе не меняют
готовый экран на ошибку: это делает settlement исхода инициализации.

Адаптер смешивает `JobAnswerer`: `onUnanswered` вызывает `_announce` с фазой
отмены и `FlutterError.reportError` вместо выхода в зону. Ядро исключает
прочитанные исходы и пойманные телом сбои детей. `Job.isCancellationError`
подавляет этот канал для признанных приложением ошибок отменяемой задачи;
журнал остаётся. Если отмена перекрыла ошибочный исход тела, `onUnanswered`
объявляет отложенный сбой. Собственный наблюдатель ребёнка может заменить
унаследованный адаптер scopo.

Ветки `concurrent` помечает `_ScopeDependencyConcurrent._runInit`
в `lib/src/scope/full_scope/scope_auto_dependency/scope_dependency/scope_dependency_group.dart`.
Группа передаёт первый сбой наверх, остальные объявляет через
`_announceCoveredBySibling`. Если тело само поймало сбой группы
и восстановилось, первый сбой ветки в журнал скоупа не приходит; это относится
и к пойманному сбою `sequential`, чьи шаги выполняются непосредственно в теле.

Прямые отчёты Flutter: ошибки селекторов, хуков наблюдателя, дополнительные
и поздние ошибки разбора; таймауты при `timeoutReportsEnabled`. Сбой
`ScopeWidgetElementBase.build` слышит наблюдатель и граница Flutter, создающая
экран ошибки. Вторичные ошибки разбора принимает `_reportFailure`
из `lib/src/scope/base/base.dart`; общей обязательной пары каналов нет.

## 7. Координация ключей и ожидание детей

Координаты: `KeyedAccessQueues`, `AccessEntry`, `ChildRegistry`, `ChildEntry`
в `lib/src/scope/async_scope/scope_coordination.dart`; `_registerWithParent`
и `_debugCheckScopeKeyOwnership`
в `lib/src/scope/async_scope/async_scope_core.dart`.

Рабочее значение `scopeKey`, включая отсутствие, фиксируется при старте. Ключу
нужен ближайший `AsyncScopeCoordinator`, владеющий очередями поддерева. Очередь
ждёт выхода предшественников; по таймауту ожидающий проходит даже при
оставшемся владельце. `cancel` прекращает ожидание, запись снимает `exit`;
пустая очередь удаляется.

Родитель для ожидания детей выбирается иначе: ближайший асинхронный скоуп
важнее промежуточного координатора. `activate` перерегистрирует элемент, пока
разбор не начался. `_debugCheckScopeKeyOwnership` повторно сравнивает ключ
и координатор с сохранёнными: смена требует нового ключа виджета. Освобождается
сохранённая запись очереди.

`AsyncScopeParent.waitForChildren`
в `lib/src/scope/async_scope/async_scope_parent.dart` ждёт снимок детей.
Таймаут снимает незавершённых детей снимка и допускает продолжение; поздние
регистрации в ожидание не входят. `ChildEntry.unregister` идемпотентен. Тот же
механизм предоставляет `AsyncScopeCoordinator.waitForChildren`
в `lib/src/scope/async_scope/async_scope_coordinator.dart`.

## 8. Состояние, закрытие и скриншот

Координаты: `LiteScopeElementBase`, `LiteScopeCoreState`
в `lib/src/scope/lite_scope/lite_scope_core.dart`; `_capture`,
`_retryOrGiveUp`, `_reportCompleted`
в `lib/src/utils/screenshot_replacer.dart`.

Готовая ветка монтирует `_LiteScopeCoreWidget` с `GlobalKey` и ссылкой
состояния на элемент. `params` читает виджет скоупа, `widget` запрещён. Разбор
ждёт отдельный `_initCompleter`, затем вызывает `disposeStateAsync`, включая
частично упавший `initStateAsync`. После успеха вызываются `onInitialized`
и `notifyDependents`; собственный экран перестраивает `setState`.

Общий барьер закрытия живёт ниже, в `AsyncScopeElementBase`
(`lib/src/scope/async_scope/async_scope_core.dart`), и на нём стоит `close()`
трёх асинхронных семейств. `close()` смонтированного скоупа ставит
`_closingCompleter`, и `buildChild` строит вместо ветки состояния
`buildOnClosing` под своим `KeyedSubtree`, чтобы `State.dispose` прежнего
поддерева отработал при любом совпадении типов. Барьер отпускает
post-frame-колбэк этой сборки (`_completeClosingFrame`), то есть уже после
`finalizeTree`: потребители и дочерние скоупы к тому времени сняты, и только
тогда `_prepareClosing` пускает разбор. Когда кадры не идут,
`_ClosingFrameObserver` и `_ensureClosingFrame` заказывают warm-up frame. Отказ
подготовки — `close()` из сборки потомка — сбрасывает `_closingCompleter`
и `_closeCompleter` в `_runAsyncDispose`, и следующий вызов начинает разбор
заново.

`LiteScope` и полный `Scope` переопределяют `_prepareClosing` своим барьером —
скриншотным. `close` оставляет элемент в дереве. В готовом смонтированном
скоупе `_screenshotCompleter` ставит барьер; `_forceRebuild` обеспечивает кадр,
`buildOnReady` строит `ScreenshotReplacer` и `buildOnClosing` поверх. Ядро
разбора стартует после барьера. `_closeCompleter` объединяет повторные вызовы
и удаление в один результат, включая ошибку. В других фазах барьера нет. Ошибка
построения закрывающей ветки и `dispose` элемента освобождают барьер. Отказ
`close()` из сборки потомка снимает и его: `_prepareClosing` обнуляет
`_screenshotCompleter`, если `markNeedsBuild` бросил, так что обычная
пересборка снова строит готовое поддерево, а следующий `close()` ставит свежий
барьер.

`ScreenshotReplacer` ждёт до `maxRetries` дополнительных кадров. При успехе
показывает `RawImage`, при окончательной неудаче — `SizedBox.shrink`: живое
поддерево уходит в обоих случаях. `onCompleted` вызывается единожды, также при
удалении виджета; его ошибка репортится. Неудача захвата не репортится.
`dispose` освобождает дескриптор изображения; позднее изображение после
удаления освобождается сразу.

Для полного скоупа `ScopeElementBase.onUnmount` вызывает состояние, затем
контейнер. `disposeScope` ждёт состояние и затем зависимости, с отдельным
лимитом для каждого этапа и продолжением после ошибки
(`lib/src/scope/full_scope/scope_core.dart`). Обычный `State.dispose` вызывает
Flutter при удалении поддерева; это отдельный механизм.

## 9. Дерево зависимостей

`ScopeDependencies` задаёт `onUnmount` и `dispose`
(`lib/src/scope/full_scope/scope_dependencies.dart`). `ScopeAutoDependencies`
в `lib/src/scope/full_scope/scope_auto_dependency/scope_auto_dependency.dart`
строит `root` через `buildDependencies`, запускает его `init` и публикует
`ScopeAutoDependenciesProgress` с путём и шагом `ProgressIterator`.

- `dep` создаёт лист. `ScopeDependencyHandle` хранит `unmount` и `dispose`,
  которые регистрируются при захвате ресурса, до следующих ожиданий.
- `controllerDep` сразу регистрирует `performUnmount` и `performDispose`, затем
  ждёт `performInit`. Если контейнер ещё инициализируется при удалении,
  `mounted` контроллера остаётся истинным до окончания или отмены задачи
  контейнера и вызова его `onUnmount`.
- `sequential` вызывает детей по очереди в том же контексте, проверяя отмену
  между шагами; разбор идёт в обратном порядке.
- `concurrent` запускает дочерние `ScopeInitJob` через `ctx.run`, задавая ключ
  по пути ветки. Первый отказ отменяет соседей; группа ждёт окончания всех
  задач. Разбор веток параллелен, отбираются они в обратном порядке.

В `lib/src/scope/full_scope/scope_auto_dependency/scope_dependency/`
`scope_dependency_impl.dart` задаёт лист, `scope_dependency_group.dart` —
группы, `scope_dependency_mixin.dart` — цикл, `scope_dependency_state.dart` —
состояния, `scope_dependency_exception.dart` — ошибку.
`ScopeDependencyMixin.init` ассертом требует `ScopeDependencyInitial`;
одновременный запуск и разбор во время инициализации запрещены также обычными
проверками.

Состояния `ScopeDependencyState`: `ScopeDependencyInitial`,
`ScopeDependencyInitialized`, `ScopeDependencyFailed`,
`ScopeDependencyCancelled`, `ScopeDependencyDisposalFailed`,
`ScopeDependencyDisposed`, `ScopeDependencyNoDisposalRequired`. Ошибки
сохраняются при разборе. `ScopeDependencyException` несёт исходную ошибку
и стек; каждый именованный уровень добавляет сегмент пути, пустое имя группы
сегмента не добавляет.

В `ScopeDependencyMixin.dispose` `_disposalInFlight` объединяет текущий обход,
`_walkReachedEveryChild` отмечает его полноту, `_mayStillHold` — возможный
остаток ресурсов, `_isDisposalDone` — завершённый разбор независимо от ошибки.
Группы продолжают обход после отказа ребёнка. Лист снимает свой диспозер перед
вызовом и повторно его не вызывает; чужой узел с неполным разбором можно
повторить, не обходя уже освобождённые группы.

При провале `ScopeAutoDependencies.init` вызывает `onUnmount` дерева, при
`autoDisposeOnError` — ограниченный разбор. `dispose` контейнера объединяет
вызовы и репортит сбой в Flutter без проброса. `_prepareDependencies` строит
новое дерево после полного разбора; удерживающее ресурсы заменять нельзя.
Отработавшие узлы нельзя сохранять между запусками; повторное присваивание
ресурсному полю `late final` провалится. `flattenDependencies`
и `flattenDependenciesWithErrors` показывают дерево и ошибки.

## 10. Конфигурация и наблюдатель

Координаты: `ScopeConfig`, `notifyObserver`, `reportTimeout`
в `lib/src/environment/scope_config.dart`; `resolveTimeout`,
`resolveCancellationTimeout` в `lib/src/environment/scope_timeout.dart`.

Умолчания четырёх ожиданий — 3 секунды: `defaultScopeKeyTimeout`,
`defaultWaitForChildrenTimeout`, `defaultDisposeScopeTimeout`,
`defaultInitCancellationTimeout`. Локальный `null` берёт глобальное значение;
глобальный `null` снимает предел. `ScopeTimeout.none` снимает локальный предел
ключа, детей и разбора. Для `initCancellationTimeout` он запрещён в debug,
а в release берётся глобальное значение. `Duration.zero` означает истечение
сразу; отрицательная длительность, кроме самого маркера, запрещена ассертом.
`pauseAfterInitialization` не принимает маркер отсутствия лимита.

`pauseAfterInitializationEnabled` управляет искусственной задержкой готовности;
`timeoutReportsEnabled` — только отчётом о таймаутах в Flutter. Наблюдатель
и колбэки таймаута продолжают получать событие. `reset` возвращает эти
настройки и лимиты, но сохраняет `observer`.

`ScopeObserver` и `ScopePhase` определены
в `lib/src/environment/scope_observer.dart`; цель задаётся
`ScopeObservable.debugLabel`.

| Группа хуков | Имена |
| --- | --- |
| Инициализация | `onInit`, `onStepStarted`, `onProgress`, `onReady`, `onCancelled` |
| Разбор | `onDispose`, `onDisposalStepStarted`, `onDisposalProgress`, `onDisposed` |
| Диагностика | `onError`, `onTimeout`, `onTrace` |

`notifyObserver` репортит исключение хука и отказывает рекурсивному событию.
`ScopeCompositeObserver` ограждает каждого получателя; `ScopePrintObserver`
печатает события с опциональным `onTrace`. Структурные семейства сообщают цикл
из `ScopeWidgetElementBase`, асинхронные — сами по `reportsOwnLifecycle`.

## 11. Утилиты

Координаты — файлы в `lib/src/utils/`; публичность задаёт `lib/scopo.dart`.

| Файл относительно каталога утилит | Содержимое |
| --- | --- |
| `compare_utils.dart` | `CompareUtils`: равенство, неравенство и сравнение по идентичности |
| `progress_iterator/progress_iterator.dart` | `ProgressIterator`, `Progress`: число и доля выполненных шагов |
| `screenshot_replacer.dart` | `ScreenshotReplacer`, барьер окончания захвата и владение изображением |
| `is_building.dart` | Публичное `IsBuildingExtension`; `runOutsideFrame` откладывает действие при `isBuilding`; внутренний счётчик сборок работает и вне кадра |
| `listenable/listen.dart`, `listenable/select.dart` | `listen`, `select`, `ListenableSubscription`, `ListenableSelectSubscription`, `CompositeListenableSubscription` |
| `listenable/listenable_selector.dart` | `ListenableSelector`: виджет с подпиской на выбранное значение |
| `listenable/listenable_view.dart` | `ListenableView`: представление с передачей слушателей исходной модели |
| `listenable/state_as_notifier.dart` | `StateAsNotifier`: добавляет состоянию интерфейс `Listenable` |
| `check_disposed.dart` | Внутренние `throwIfDisposed`, `debugAssertNotDisposed` |

## 12. Устройство тестов

`test/flutter_test_config.dart` включает отслеживание утечек всей сьюты. Наборы
отдельных слоёв соседствуют со сквозными проверками параметров, таймаутов,
порядка разбора, ошибок хуков и поздних ресурсов (§13).

Общие помощники: `test/utils/observer.dart` — `RecordingObserver` с журналом
событий; `test/utils/settle.dart` — `settle`, чередующий реальную асинхронную
работу и кадры; `test/utils/run_scope_init.dart` — `runScopeInit` для ручного
запуска контейнера; `test/utils/my_fake_async.dart` — `MyFakeAsync` с учётом
таймеров; `test/utils/leaks.dart` — исключение для намеренно неразбираемого
после ошибки обновления дерева Flutter.

`test/published_docs_test.dart` сверяет имена параметров, сортировку версий
и наследование комментариев хуков в исходниках и публичных Markdown
с зеркалами. Это текстовые проверки. `test/ide_snippets_test.dart` сверяет
форматы шаблонов и развёртки `test/ide/`, проверяемые анализатором.
`test/ide_dependencies_disposal_test.dart` исполняет разбор шаблона;
`test/lite_scope_initialization_recipe_test.dart`
и `test/controller_notifier_recipe_test.dart` проверяют рецепты.

## 13. Инварианты для правок

| Инвариант | Где закреплён |
| --- | --- |
| `init` видит предков, выполняется один раз; после его отказа разбор всё равно нужен | `test/scope_widget_test.dart` |
| Набор аспектов заменяется новой сборкой; обработанная ошибка селектора не отписывает потребителя навсегда | `test/base_test.dart`, `test/selector_recovery_test.dart` |
| Уведомление сохраняет собственное поддерево, а ошибка сборки сбрасывает `_builtChild` для восстановления | `test/scope_widget_test.dart` |
| Слушатель новой модели подключён до `builder` при замене `ScopeNotifier.value` | `test/scope_notifier_test.dart` |
| Показ готовности отложен; успешную инициализацию при разборе определяет `_initSucceeded` | `test/async_scope_test.dart`, `test/scope_removed_while_initializing_test.dart` |
| Поздний результат отменённой задачи освобождается, даже после окончания разбора элемента | `test/late_release_test.dart` |
| Один сбой вложенных задач объявляется один раз, обработанный ребёнок не даёт лишнего Flutter-отчёта | `test/async_job_migration_test.dart` |
| Ответ `scopeKey` и координатор занятого ключа фиксированы; выход освобождает фактически занятую очередь | `test/async_scope_coordinator_test.dart` |
| Родитель ждёт детей; истечение ожидания допускает дальнейший разбор | `test/scope_coordination_test.dart`, `test/scope_lifecycle_order_test.dart` |
| `close` объединяет вызовы, барьер не переживает удаление; провал скриншота убирает живое поддерево | `test/lite_scope_test.dart` |
| Сбой хука не пропускает следующие обязательные этапы разбора | `test/cleanup_after_user_error_test.dart`, `test/scope_dependency_unmount_test.dart` |
| Ошибка дерева сохраняется; повторный разбор чужого узла не теряет ещё удерживаемые ресурсы | `test/scope_auto_dependencies_test.dart`, `test/scope_dependency_partial_test.dart` |
| Нулевой лимит и отсутствие лимита различаются; отмена не принимает локальный `ScopeTimeout.none` | `test/scope_timeout_test.dart` |
