# Полное ревью проекта: Astra

> **Состояние на 2026-10-23:** ревью принято, ни одна находка ещё не в работе.
> Все зонды перезапущены на клоне ревьюера и воспроизвелись (раздел «Приёмка»
> в конце). Находка 6 задевает поверхность 0.17.0, которая подготовлена,
> но не выпущена.
> **Что это:** независимое полное ревью scopo на `765ab0c`, сделанное
> `gpt-6-astra` с усилием `xhigh` через `codex exec`. В нём оценки по
> 10-балльной шкале (код 7,5, документация 6,5, общая 7), удобство для
> человека и для агентов, ответ на вопрос «нужен ли проект» и десять находок:
> P0 нет, P1 три, P2 семь.
> **Связанные записи:** `2026-10-23[3]-sol-project-review.md` (второе ревью
> того же коммита, независимое), `2026-10-23[1]-async-job-0.3-surface-design.md`
> (работа, которую задевает находка 6).

Ниже отчёт ревьюера дословно, менялись только переносы строк. Ссылки
на `/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/` ведут во временный
каталог сессии и долго не проживут. Исходники зондов сохранены в «Приложении»
в конце записи.

## ПРОГОН

Проверен именно `765ab0c`. Тулчейн подтверждён командой
`fvm flutter --version`: Flutter **3.27.0**, Dart **3.6.0**.

Все обязательные команды выполнены. Ниже последние строки вывода; удалены
только пробелы, которыми Flutter дополняет строку терминала.

| Команда | Код выхода | Последняя строка |
|---|---:|---|
| `fvm flutter test` | 0 | `00:12 +570: All tests passed!` |
| `fvm flutter analyze` | 0 | `No issues found! (ran in 4.3s)` |
| `(cd example/minimal && fvm flutter analyze)` | 0 | `No issues found! (ran in 1.3s)` |
| `(cd example/scopo_demo && fvm flutter analyze)` | 0 | `No issues found! (ran in 2.1s)` |
| `fvm dart format --set-exit-if-changed lib test` | 0 | `Formatted 118 files (0 changed) in 0.69 seconds.` |
| `fvm dart doc --dry-run` | 0 | `Found 0 warnings and 0 errors.` |
| `sh docs/ru/check.sh` | 0 | `переводы актуальны: 16` |
| `(cd example/scopo_demo && fvm flutter test)` | 0 | `00:09 +5: All tests passed!` |

Полные журналы находятся в
[out-astra/logs](/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/logs).
Отказов песочницы не было.

Дополнительные зонды запускались последовательно, через `fvm`, с файлами
и `TMPDIR` в `out-astra`. Их результаты приведены при находках. Красные зонды
ниже воспроизводят сценарии, отсутствующие в штатных 570 тестах. Нативные
сборки, браузерный запуск и release без assertions не выполнял; исторические
записи читал выборочно, сверяя прежние вердикты. Сам `async_job` отдельно
не аудировал.

**Дерево не редактировалось.** Начальный и заключительный `git status --short`
пусты; заключительный `git diff --stat` также пуст. Требование `AGENTS.md`
обновлять `docs/handoff.md` перед ревью и по результатам противоречит этому
заданию: handoff и записи в репозитории намеренно не менял. Разницу версий
`pubspec.yaml` и CHANGELOG учитывал как подготовку выпуска.

## Оценки

**Код — 7,5/10.** Здесь серьёзно проработаны владение, частичная инициализация,
отмена, повторные вызовы и продолжение разбора после ошибки. Тесты
действительно проверяют поведение, включая неприятные последовательности
событий. Однако обнаружены потери подписок и уведомлений, а интеграция
наблюдателя с вложенными задачами ещё неполна. На балл оценку подняли бы
исправления этих дефектов и проверки сочетаний уже поддержанных сценариев:
замена модели во время сборки, восстановление после ошибки селектора, несколько
уровней задач.

**Документация — 6,5/10.** Публичные темы содержательны: объясняют порядок
действий, владение и причины ограничений. Но один непосредственно предлагаемый
рецепт зависает, некоторые страницы противоречат текущему коду, а внутренняя
архитектурная справка описывает прежний механизм асинхронности. На балл
помогли бы актуализация этих контрактов, короткий запускаемый первый пример
и поведенческие проверки ключевых рецептов.

**Общая — 7/10.** У проекта есть полезная специализация и инженерная основа,
достаточная для дальнейшего использования. Главные препятствия для принятия —
цена изучения, несколько ошибок на границах механизмов и отсутствие
подтверждённого опыта пользователей помимо автора. На балл оценку подняли бы
исправление найденного и проверка API на самостоятельном приложении другого
разработчика, особенно на экране с ресурсами, отменой и повторным открытием.

## Удобство для человека

Таблица выбора семейств помогает понять, что брать. `.value`, разделение
создания и освобождения, `select`, именованные аксессоры достаточно
предсказуемы. Диагностика неправильного использования заметно лучше среднего:
сообщения про повторное использование контроллера, смену `scopeKey` и подписку
из неподходящего места объясняют причину и дают выход.

Цена первого осмысленного экрана всё же высокая. README занимает 876 строк,
минимальный пример — 250 строк. Начинающему предлагают выбрать между восемью
семействами, затем понять различия `Core`/`Base`, параметров и состояния,
`setState` и `notifyDependents`, двух инициализаций и двух стадий освобождения.
Читать всё необязательно, но понять, какую часть можно пропустить, тоже требует
опыта.

Самая непривычная часть — состояние, похожее на Flutter `State`, но с другим
контрактом: параметры читаются через `params`, собственный экран и подписанные
потомки обновляются разными вызовами. Это можно освоить; рецепт
с `isInitialized`, описанный ниже, показывает, насколько легко ошибиться даже
внутри документации самого проекта.

Также вступительные гарантии звучат сильнее фактических. Ожидание детей
и сериализация по `scopeKey` по умолчанию ограничены тремя секундами; после
истечения пакет продолжает работу. Такое решение подробно объяснено дальше,
но оговорка нужна рядом с первым обещанием порядка освобождения. Для
пользователя базы или проигрывателя это часть контракта владения,
а не второстепенная настройка.

## Удобство для агентов

**Агент, пишущий приложение на scopo.** Обычный сценарий можно реализовать
по README, темам и шаблонам без чтения исходников. Помогают конкретные
сигнатуры, примеры правильного и неправильного приобретения ресурсов, аксессоры
и возможность подставлять контроллеры для тестирования.

Сложные сценарии пока требуют перепроверки исходников. Документы дают
несовместимые ответы про позднее освобождение, модификатор `ScopeObserver`
и переход собственного состояния в готовность. Агент может добросовестно
скопировать официальный рецепт и получить зависший экран. Проверка переводов
этого не обнаруживает: русское зеркало аккуратно повторяет ошибку оригинала.

**Агент, работающий в репозитории.** `AGENTS.md` хорошо определяет SDK,
проверки, владение изменениями, язык и выпуск. Короткий backlog удобен,
а вердикты непосредственно в прежних ревью позволяют отличать открытое от уже
разобранного.

Восстановление контекста перегружено. Обязательный handoff содержит 1252 строки
и одновременно актуальные и устаревшие утверждения о текущем состоянии.
Архитектурная справка отправляет к механизму `Stream`, которого в основной
инициализации уже нет. Агенту приходится сначала строить модель
по документации, затем опровергать её по коду.

Правила публикации строгие, но однозначные. Большую помеху работе создаёт
не строгость регламента, а несоответствие поддерживаемых документов его
собственному требованию хранить только актуальное состояние.

## Нужен ли проект

**Да, как специализированный инструмент для ресурсов с асинхронным жизненным
циклом в дереве виджетов.** Наиболее убедительный сценарий — экран или сессия,
которые открывают несколько ресурсов, показывают прогресс, могут исчезнуть
во время открытия и должны освободиться в определённом порядке перед повторным
созданием.

Сравнение во вступлении README чрезмерно упрощает альтернативы:

| Инструмент | Что уже закрывает | Где остаётся смысл scopo |
|---|---|---|
| `provider` | Создание, предоставление, подписку и освобождение объектов в дереве. [Документация](https://pub.dev/packages/provider). | Общий асинхронный протокол инициализации, отмены и ожидания разбора. |
| `riverpod` | Реактивные зависимости, автоматическое уничтожение состояния, освобождение и отмену прикладных операций через `ref.onDispose`. Сам callback имеет тип `void Function()`. [Automatic disposal](https://riverpod.dev/docs/concepts2/auto_dispose), [onDispose](https://pub.dev/documentation/riverpod/latest/riverpod/Ref/onDispose.html). | Явное ожидание асинхронного освобождения дочерних скоупов, связанное с деревом экранов. |
| `flutter_bloc` | Управление состоянием, подписку UI и автоматическое закрытие BLoC, созданного `BlocProvider`. [Документация](https://pub.dev/packages/flutter_bloc). | Управление совокупностью разнородных ресурсов вокруг BLoC и других объектов. |
| `get_it` / `injectable` | Асинхронную инициализацию зависимостей, ожидание готовности, скоупы, асинхронное освобождение в обратном порядке; `injectable` генерирует регистрацию. [Async objects](https://flutter-it.dev/documentation/get_it/async_objects), [Scopes](https://flutter-it.dev/documentation/get_it/scopes), [injectable](https://pub.dev/packages/injectable). | Готовая связь этих действий с ветками UI, деревом дочерних скоупов, `close()` и координацией по ключу. |

Особенно важно честно учитывать `get_it`: он занимается владением во времени,
а не только доставкой значения потребителю. Его документация также предлагает
`watch_it.pushScope` для времени жизни виджета. Поэтому преимущество scopo —
конкретная организация жизненного цикла и её интеграция с UI, а не отсутствие
такого управления у конкурентов.

Для обычного счётчика, CRUD-экрана или синхронно создаваемых сервисов
приобретение scopo трудно оправдать. Для приложения, уже построенного
на Riverpod или BLoC, разумнее сначала использовать scopo на одном ресурсоёмком
участке.

На заданных вводных спрос за пределами автора ещё не доказан. Это не делает
пакет бесполезным, но означает, что расширять число абстракций сейчас менее
ценно, чем проверить существующие на внешнем пользователе.

## Находки по убыванию тяжести

P0 не обнаружил. Ниже отделяю дефекты библиотеки от ошибок рецептов и примеров.

### 1. P1 — обработанная ошибка селектора лишает потребителя дальнейших обновлений

**Координаты:** `lib/src/scope/base/base.dart`, `ScopeContext._find`;
`lib/src/scope/scope_widget/scope_widget_core.dart`, `_notifyDependent`.

При изменении выбранного значения `_notifyDependent` очищает регистрацию перед
перестроением потребителя. В следующем build `_find` сначала выполняет селектор
и только затем вызывает `dependOnInheritedElement`. Если селектор бросил,
подписка не восстанавливается.

Достижимый сценарий использует собственный `ScopeStateWithErrorNotifier`:
потребитель выбирает `state`, модель вызывает `setError`, затем
восстанавливается через `update`. Даже если потребитель ловит исключение
и нормально строит свой экран ошибки, последующее обновление до него
не доходит.

Зонд проверил обе формы — с `ErrorWidget` и с обработанным исключением. Вторая
сначала успешно показала `failed`, затем после `update(1)` упала на:

```text
Found 0 widgets with text "state: 1"
handling the selected getter failure must not unsubscribe
```

Запуск: `fvm flutter test
/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/sync/selector_recovery_probe_test.dart
--reporter expanded`.
[Зонд](/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/sync/selector_recovery_probe_test.dart),
[журнал](/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/logs/selector_recovery.log).

Защита `_selectorSaysChanged` сохраняет обход остальных потребителей,
но не подписку упавшего. Нужно сохранять возможность последующего уведомления
при неудачном чтении селектора. Тест восстановления notifier отдельно этого
не проверяет.

**Вердикт: исправлено.** `43dc61d`, задание `notify` через Codex (Astra).
`ScopeContext._find` выполняет селектор в `try`/`finally` и подписывается
в любом случае; на сбое — без аспекта, то есть на любое изменение, так что
следующая сборка спросит селектор снова. Тесты —
`test/selector_recovery_test.dart`; откат правки их роняет.

### 2. P1 — замена `ScopeNotifier.value` теряет уведомление новой модели внутри builder

**Координаты:** `lib/src/scope/scope_notifier/scope_notifier_base.dart`,
`_ScopeNotifierElement.update`.

Listener переносится на новую модель после `super.update(newWidget)`. Между тем
`super.update` уже уведомляет зависимости и выполняет сборку. Если старая
и новая модели имеют одинаковое выбранное значение, а builder затем меняет
новую модель, изменение проходит без listener.

В зонде обе модели начинались с `0`. Builder при замене устанавливал новой
модели `1` и возвращал прежнего `const`-потребителя. Проверка
`second.value == 1` прошла, проверка текста `value: 1` — нет.

Это поддерживаемый проектом сценарий: `test/scope_notifier_test.dart`, тест
`a model notified from inside the builder does not lose the notification`, уже
требует сохранять уведомления из builder. Он проверяет одну модель; тесты
замены не покрывают это окно.

Запуск: `fvm flutter test
/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/sync/sync_probe_test.dart
--reporter expanded`, первый тест.
[Зонд](/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/sync/sync_probe_test.dart),
[журнал](/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/logs/sync_probes.log).

Перенос подписки должен завершаться до сборки, способной уведомить новую
модель, с сохранением проверки допустимости смены режима владения.

**Вердикт: исправлено.** `43dc61d`, задание `notify`. Listener переносится
на новую модель до `super.update`, если прежний был подписан и режим
конструктора не менялся; сравнение моделей — по идентичности. Тест —
в `test/scope_notifier_test.dart`; откат правки его роняет.

### 3. P1 — документированный рецепт ожидания `initStateAsync` оставляет экран на загрузке

**Координаты:** `doc/lite_scope.md`, раздел «Two initializations»;
`docs/ru/doc/lite_scope.md`; `lib/src/scope/lite_scope/lite_scope_core.dart`,
`LiteScopeCoreState._completeInit`.

Тема предлагает в собственном `State.build` показывать индикатор, пока
`!isInitialized`. Но завершение инициализации вызывает `onInitialized()`
и `notifyDependents()`, не собственный `setState`. По умолчанию `onInitialized`
пуст, а `notifyDependents` намеренно не перестраивает собственный экран.

Зонд с управляемым `Completer` после его завершения и `pumpAndSettle` вывел:

```text
guard: isInitialized=true, loading=1, ready=0
```

Запуск: `fvm flutter test
/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/async_probe_test.dart
--reporter expanded`, тест
`LiteScope documented initialized guard reaches ready screen`.
[Зонд](/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/async_probe_test.dart),
[журнал](/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/logs/async_probes_final.log).

Это ошибка рецепта. Разделение двух способов уведомления в библиотеке
последовательно. Рецепту нужен `setState` из `onInitialized` либо отображение
готовности через подписанного потомка.

**Вердикт: исправлено.** `5c44e81`, задание `docs` через Codex (Sol). Рецепт
в `doc/lite_scope.md` и dartdoc `LiteScopeCoreState` вызывают `setState`
из `onInitialized()`. Пример теперь полный и исполняемый:
`test/lite_scope_initialization_recipe_test.dart` гоняет его и сверяет с блоком
документа побайтно; второй тест показывает, что без `setState` экран остаётся
на загрузке.

### 4. P2 — шаблон ручных зависимостей пропускает освобождение базы при ошибке закрытия сессии

**Координаты:** `ide/scopo.code-snippets`, шаблон `scopo-deps`,
`AppDependencies.dispose`; соответствующая развёртка
`test/ide/scopo_deps.dart`.

Шаблон выполняет последовательно:

```dart
await session.close();
await database.close();
```

Если первый вызов бросает, второй не выполняется. Перед передачей контейнера
обе регистрации уже сняты с задачи через `disown`. Скоуп вызывает контейнер как
один шаг и самостоятельно освободить пропущенную базу не может.

Зонд использует развёртку текущего шаблона с ресурсами, у которых закрытие
сессии бросает, а закрытие базы записывает факт вызова:

```text
OBSERVED scopo-deps: failed session.close; database.closed = false
```

Запуск из `example/scopo_demo`: `fvm flutter test --no-pub
/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/examples/examples_probe_test.dart
--reporter expanded`.
[Зонд](/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/examples/examples_probe_test.dart),
[журнал](/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/logs/example_probes.log).

P2 относится к копируемому шаблону. Нужна попытка освободить каждый ресурс
независимо от сбоя предыдущего, с сохранением порядка и ошибок.

**Вердикт: исправлено.** `c15e4b5`, задание `examples` через Codex (Sol),
доведено мной. `dispose` шаблона закрывает базу в `finally` после сессии —
в `ide/scopo.code-snippets`, `.vscode/scopo.code-snippets`,
`ide/scopo-live-templates.xml` и в развёртке `test/ide/scopo_deps.dart`. Codex
предлагал сбор ошибок через `AsyncError?`; я выбрал `finally` как короче для
шаблона: при отказе обоих наружу уходит ошибка базы. Тесты —
`test/ide_dependencies_disposal_test.dart`; откат к последовательному закрытию
роняет два.

### 5. P2 — после ошибки повторной сборки уведомления сохраняют `ErrorWidget`

**Координаты:** `lib/src/scope/scope_widget/scope_widget_core.dart`,
`ScopeWidgetElementBase.build`, `performRebuild`, `_builtChild`.

Если одна сборка прошла успешно, а следующая бросила, `_builtChild` сохраняет
результат первой. Реальное поддерево Flutter уже заменил на `ErrorWidget`.
Следующее уведомление видит непустой кеш, выбирает сокращённую сборку
и оставляет ошибку на месте.

Второй тест `sync_probe_test.dart` воспроизвёл последовательность «успех →
временная ошибка builder → уведомление модели»: текст `value: 1` не появился.
Команда и журнал приведены в находке 2.

Предыдущее исправление из `docs/records/2026-08-20[1]-project-review.md`
и нынешний тест ошибки первой сборки закрывают случай пустого кеша. Здесь кеш
уже заполнен. Его нужно инвалидировать после неудачной настоящей сборки.
Внешнее полное перестроение может восстановить экран, поэтому тяжесть P2.

**Вердикт: исправлено.** `43dc61d`, задание `notify`. На броске сборки
`_builtChild` сбрасывается, и следующее уведомление строит поддерево заново.
Тест — в `test/scope_widget_test.dart`; откат правки его роняет.

### 6. P2 — наблюдатель пропускает или дублирует ошибки вложенных задач

**Координаты:** `lib/src/scope/async_scope/scope_init_context.dart`,
`_ScopeInitObserver.onError`, `_announce`; `AsyncScopeElementBase._settleInit`.

Адаптер предполагает, что ошибку любого `ScopeInitJob` позже объявит settlement
элемента. Это верно для корневой задачи скоупа, но не для дочернего
`ScopeInitJob`, ошибку которого тело обработало. Такая ошибка не объявляется
вообще.

Обратная проблема возникает на двух уровнях обычных дочерних `Job`: один объект
ошибки проходит через оба уровня, а `_announce` добавляет его в набор без
проверки предыдущего объявления. Settlement корня убирает собственный дубль,
но два объявления детей остаются.

Два зонда дали:

```text
nested failure: shownSame=true, count=2, phases=[ScopePhase.initialization, ScopePhase.initialization]
handled child init job: caught=true, ready=1, observerCount=0
```

Команда, файл и журнал — те же, что в находке 3; соответствующие тесты первый
и третий.

Экран получает правильный исход, поэтому P2. Однако обещание наблюдателя
слышать ошибки независимо от их обработки и без повторов нарушено. Нужно
различать корневую задачу и дочерние задачи, а также первичный сбой и его
распространение вверх.

### 7. P2 — подписка инициализации `HomeDependencies` ломает повторную загрузку BLoC

**Координаты:** `example/scopo_demo/lib/home/home_dependencies.dart`,
`HomeDependencies.buildDependencies`, обработчик `bloc.stream.listen`.

Первый `FakeBlocSuccess` завершает `Completer`, но подписка продолжает жить.
Повторный `bloc.add(FakeBlocLoad())` после готовности снова вызывает
`completer.complete()`.

Зонд на настоящем дереве `App → Home` завершился ошибкой:

```text
Bad state: Future already completed
HomeDependencies.buildDependencies.<anonymous closure>.<anonymous closure>
(package:scopo_demo/home/home_dependencies.dart:43:29)
```

Запуск из `example/scopo_demo`: `fvm flutter test --no-pub
/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/examples/reload_probe_test.dart
--reporter expanded`.
[Зонд](/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/examples/reload_probe_test.dart),
[журнал](/Users/user/.claude/jobs/715c8327/tmp/review/out-astra/logs/reload_probe_final.log).

Штатный интерфейс не отправляет вторую загрузку, поэтому P2: ловушка расширения
и копирования примера. Временная подписка должна завершаться после первого
терминального результата, включая ошибку.

**Вердикт: исправлено.** `c15e4b5`, задание `examples`. `HomeDependencies` ждёт
первое конечное состояние BLoC через `bloc.stream.firstWhere` и на ошибке
бросает её с исходным стеком; подписка после этого не живёт. Тест —
`example/scopo_demo/test/home_dependencies_reload_test.dart`.

### 8. P2 — `countOf` в примере `AsyncScope` не отслеживает счётчик

**Координаты:**
`example/scopo_demo/lib/home/demos/async_scope/counter_scope.dart`,
`CounterScope.countOf`, `CounterModel.increment`, `CounterScopeElement`.

Аксессор подписывается через `AsyncScopeCore.select`, но изменение счётчика
уведомляет только `CounterModel`. Элемент эти уведомления не пересылает.
Встроенный экран использует отдельный `ListenableSelector`, поэтому работает
и скрывает дефект аксессора.

Зонд вывел:

```text
OBSERVED AsyncScope countOf: model = 1, builtin listener = 1, countOf text = 0
```

Команда и журнал — из находки 4, второй тест. P2: нынешняя встроенная кнопка
работает, но готовый аксессор учит неправильному способу подписки. Его следует
убрать либо связать уведомления модели со скоупом.

**Вердикт: исправлено.** `c15e4b5`, задание `examples`. `CounterScopeElement`
пересылает уведомления модели своим зависимым (`addListener(notifyDependents)`,
снимается в `onUnmount`), а экран читает счётчик через `CounterScope.countOf`,
так что аксессор больше не прячется за отдельным `ListenableSelector`. Тест —
`example/scopo_demo/test/async_scope_counter_test.dart`.

### 9. P2 — публичные темы сохраняют несовместимые контракты прежних версий

**По чтению. Координаты:** `doc/async_scope.md`, «Disposal, in order»;
`doc/debug.md`, пояснение после примера `CrashReporter`; соответствующие файлы
`docs/ru/`.

В `doc/async_scope.md` сначала написано, что поздний результат освобождается,
кроме случая уже завершённого разбора. Ниже та же страница обещает освобождение
независимо от опоздания. Второе соответствует текущему коду
и `test/late_release_test.dart`. Устаревшее исключение мешает читателю
определить, кто владеет поздним результатом, и может подтолкнуть к лишнему
освобождению.

Там же первая ошибка разбора при удалении скоупа обещана зоне, хотя текущий
`AsyncScopeElementBase.dispose` направляет её в `FlutterError.reportError`.

В `doc/debug.md` `ScopeObserver` всё ещё назван `base class`, а наследнику
предписано быть `base` или `final`. Сейчас это обычный класс; снятие
ограничения специально описано в README и CHANGELOG ради возможности
мокирования.

Это рассинхронизация документации, а не повторное обнаружение исправленных
runtime-дефектов. Зелёный dartdoc и актуальные хеши переводов семантических
противоречий не проверяют.

**Вердикт: исправлено.** `5c44e81`, задание `docs`. `doc/async_scope.md`
обещает отдать поздний результат в `disposeScope` и после конца разбора,
а первую ошибку разбора снятого с дерева скоупа — `FlutterError.reportError`;
то же уточнено в `doc/full_scope.md`, где нашлось такое же обещание.
`doc/debug.md` и dartdoc `ScopeObserver` называют его обычным классом. Зеркала
в `docs/ru/` правлены вместе с оригиналами.

### 10. P2 — документы восстановления контекста дают противоречивую картину проекта

**По чтению. Координаты:** `docs/handoff.md`, «С чего начать после рестарта»;
`docs/architecture.md`, разделы асинхронности, закрытия и зависимостей; ссылка
на справку в `AGENTS.md` §1.

Вверху handoff правильно названы переход на `async_job ^0.3.0`, 570 тестов
и подготовка 0.17.0. Ниже в том же текущем состоянии утверждается, что после
выпуска `lib/` и `test/` не менялись, открытого раздела CHANGELOG нет,
а верхний — 0.16.0.

Архитектурная справка честно датирована версией 0.10.0, но продолжает служить
входной картой. Она описывает `Stream`-инициализацию, `_subscription`,
удалённые вспомогательные механизмы, встроенный `NavigationNode` и отсутствие
внешних зависимостей. Некоторые описания поведения, включая исчерпание попыток
screenshot, противоположны текущим.

Для агента это конкретная потеря времени и риск неверного изменения:
обязательный контекст нужно сначала разобрать на действующее и историческое.
Нужны короткий актуальный handoff и текущая архитектурная карта; прежняя версия
справки принадлежит истории.

## Что сделано хорошо и стоит сохранить

Основа управления ресурсами заслуживает сохранения: регистрация освобождения
сразу после приобретения, разбор частично созданного дерева, продолжение
очистки после сбоя отдельного шага, ожидание уже начатого разбора
и освобождение позднего результата. Это содержательная работа, которая
и оправдывает существование пакета.

Штатные тесты покрывают существенно больше обычного успешного пути. Особенно
полезны проверки порядка жизненного цикла, таймаутов, `GlobalKey`, ошибок
пользовательских хуков и утечек. Обнаруженные пробелы чаще находятся
на пересечении уже проверенных механизмов: две поддержки по отдельности есть,
их сочетание ещё не проверено.

CI закрепляет нижнюю границу SDK, запускает тесты демо и проверяет отсутствие
изменений дерева. Отдельный необязательный прогон на stable даёт ранний сигнал
совместимости. Существенного дефекта конфигурации CI в этом ревью
не установлено.

Проверки IDE-шаблонов сверяют форматы и анализируемые развёртки — это полезная
основа. Следующий шаг здесь поведенческий: компилируемый disposer ещё может
пропустить освобождение. Аналогично `test/published_docs_test.dart` защищает
конкретные строки и регрессии документации, но пока не проверяет результат
выполнения рецептов.

Стоит сохранить точные сообщения неправильного использования, явное различие
владения у обычного и `.value`-конструкторов, разделение `setState`
и `notifyDependents`, русские зеркала и вердикты непосредственно в исторических
ревью. Эти вещи делают сложный пакет объяснимым; им нужна согласованность,
а не новая система поверх существующей.

## Итог

scopo имеет оправданную нишу: асинхронное владение ресурсами, связанное
с деревом экранов. Обязательные проверки зелёные: 570 корневых тестов и 5
тестов демо. Зонды обнаружили две потери обновлений в библиотеке и неработающий
рецепт ожидания готовности. Дополнительно подтверждены ошибки наблюдения,
восстановления после build error и несколько ловушек примеров. Главная
документационная проблема — несовместимые актуальные и исторические контракты.
Ближайшая полезная работа — исправить эти границы и проверить API на внешнем
приложении. Репозиторий оставлен чистым; все зонды и журналы находятся вне
дерева.

## Приёмка

Принимал 2026-10-23 Claude. Строка
`=== astra (gpt-6-astra:xhigh) rc=0 за 1167 c`, в шапке лога
`model: gpt-6-astra` и `reasoning effort: xhigh`. После прогона
`git status --short` клона пуст, дифф пуст.

**Прогон.** Числа совпадают с гейтом §6, который я прогнал на том же коде перед
мержем `2ee070c`: 570 тестов, три `analyze` без замечаний, format 118/0, doc
0/0, переводы 16, сьюта демо 5. Отдельно гейт на клоне ревьюера я не повторял:
его журналы лежат в `out-astra/logs`, а код тот же.

**Зонды.** Все перезапущены мной в клоне ревьюера
(`fvm flutter test --no-pub <зонд> --reporter expanded`). Строки совпали
с цитатами отчёта:

- находка 1: `selector_recovery_probe_test.dart` даёт `-2`, обе формы
  `Found 0 widgets with text "state: 1"`;
- находки 2 и 5: `sync_probe_test.dart`, первые два теста падают
  с `Found 0 widgets with text "value: 1"`;
- находки 3 и 6: `async_probe_test.dart`, `-3`. Там
  `guard: isInitialized=true, loading=1, ready=0`,
  `nested failure: shownSame=true, count=2`
  и `handled child init job: caught=true, ready=1, observerCount=0`;
- находки 4 и 8: `examples_probe_test.dart` из `example/scopo_demo`, строки
  `OBSERVED scopo-deps: failed session.close; database.closed = false`
  и `OBSERVED AsyncScope countOf: model = 1, builtin listener = 1,
  countOf text = 0`;
- находка 7: `reload_probe_test.dart` даёт
  `Bad state: Future already completed`.

Третий тест `sync_probe_test.dart`, «stopping all selections removes the old
selector», тоже падает (`Expected: <2>`, `Actual: <3>`), но находкой в отчёте
он не стал. Зонд проверяет, что подписка из прошлой сборки снимается, если
в следующей сборке ничего не выбрано. Сам Flutter ведёт себя так же:
зависимость элемента от `InheritedElement` живёт до деактивации,
а не до следующей сборки. Ревьюер, похоже, рассудил так же. Я с ним согласен
и находкой это не считаю.

**По чтению проверено.** Находка 9: `doc/async_scope.md` в шаге 3 порядка
разрушения говорит «unless the teardown has by then run to its end», а ниже,
в абзаце «A bare call is still right…», — «However late it comes back».
В абзаце «Every step is guarded on its own» первую ошибку снятия с дерева
отдают зоне, а `AsyncScopeElementBase.dispose` направляет её
в `_reportFailure`. `doc/debug.md` и dartdoc `ScopeObserver` всё ещё называют
класс `base class`, а объявлен он как `class ScopeObserver`.

**Что задевает невыпущенное.** Находка 6 бьёт прямо в поверхность 0.17.0.
Обещание «`ScopeObserver` слышит сбои детей, которые тело обработало, один раз»
из `2026-10-23[1]-async-job-0.3-surface-design.md` не держится в двух случаях.
Обработанный сбой вложенного `ScopeInitJob` наблюдатель не слышит вовсе:
`_ScopeInitObserver.onError` уступает любому `ScopeInitJob`, а не только
корневому. Сбой, прошедший через два уровня обычных `Job`, он слышит дважды.

## Приложение: исходники зондов

Пути — относительно `/Users/user/.claude/jobs/715c8327/tmp/review/out-astra`.

### `sync/selector_recovery_probe_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

void main() {
  testWidgets('a selector rebuilds again after its model recovers', (tester) async {
    final model = ScopeStateWithErrorNotifier<int>(0);
    final reported = <Object>[];
    final original = FlutterError.onError;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ScopeNotifier<ScopeStateWithErrorNotifier<int>>.value(
        value: model,
        builder: (_) => const SelectedStateText(),
      ),
    ));
    expect(find.text('state: 0'), findsOneWidget);
    FlutterError.onError = (details) => reported.add(details.exception);
    try {
      model.setError(StateError('temporary failure'), StackTrace.current);
      await tester.pump();
    } finally {
      FlutterError.onError = original;
    }
    expect(reported, isNotEmpty);
    expect(find.byType(ErrorWidget), findsOneWidget);
    model.update(1);
    await tester.pumpAndSettle();
    expect(find.text('state: 1'), findsOneWidget,
      reason: 'recovery is a documented transition of ScopeStateWithErrorNotifier');
    await tester.pumpWidget(const SizedBox.shrink());
    model.dispose();
  });
  testWidgets('a caught selector error still permits recovery', (tester) async {
    final model = ScopeStateWithErrorNotifier<int>(0);
    final reported = <Object>[];
    final original = FlutterError.onError;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ScopeNotifier<ScopeStateWithErrorNotifier<int>>.value(
        value: model,
        builder: (_) => const CaughtSelectedStateText(),
      ),
    ));
    expect(find.text('state: 0'), findsOneWidget);
    FlutterError.onError = (details) => reported.add(details.exception);
    try {
      model.setError(StateError('temporary failure'), StackTrace.current);
      await tester.pump();
    } finally {
      FlutterError.onError = original;
    }
    expect(find.text('failed'), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
    model.update(1);
    await tester.pumpAndSettle();
    expect(find.text('state: 1'), findsOneWidget,
      reason: 'handling the selected getter failure must not unsubscribe');
    await tester.pumpWidget(const SizedBox.shrink());
    model.dispose();
  });

}

final class SelectedStateText extends StatelessWidget {
  const SelectedStateText();
  @override
  Widget build(BuildContext context) {
    final state = ScopeNotifier.select<ScopeStateWithErrorNotifier<int>, int>(
      context, (m) => m.state);
    return Text('state: $state');
  }
}

final class CaughtSelectedStateText extends StatelessWidget {
  const CaughtSelectedStateText();
  @override
  Widget build(BuildContext context) {
    try {
      final state = ScopeNotifier.select<ScopeStateWithErrorNotifier<int>, int>(
        context, (m) => m.state);
      return Text('state: $state');
    } on Object {
      return const Text('failed');
    }
  }
}
```

### `sync/sync_probe_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

void main() {
  testWidgets('swap notification while building reaches selected descendant', (tester) async {
    final first = ValueNotifier<int>(0);
    final second = ValueNotifier<int>(0);
    Widget app(ValueNotifier<int> model, {bool mutate = false}) => Directionality(
      textDirection: TextDirection.ltr,
      child: ScopeNotifier<ValueNotifier<int>>.value(
        value: model,
        builder: (context) {
          if (mutate) model.value = 1;
          return const SelectedText();
        },
      ),
    );
    await tester.pumpWidget(app(first));
    expect(find.text('value: 0'), findsOneWidget);
    await tester.pumpWidget(app(second, mutate: true));
    await tester.pumpAndSettle();
    expect(second.value, 1);
    expect(find.text('value: 1'), findsOneWidget,
      reason: 'the notification during the swap must reach the descendant');
    await tester.pumpWidget(const SizedBox.shrink());
    first.dispose();
    second.dispose();
  });

  testWidgets('notification recovers after a later build failure', (tester) async {
    final model = ValueNotifier<int>(0);
    var failOnce = false;
    Widget app() => Directionality(
      textDirection: TextDirection.ltr,
      child: ScopeNotifier<ValueNotifier<int>>.value(
        value: model,
        builder: (context) {
          if (failOnce) {
            failOnce = false;
            throw StateError('transient later build');
          }
          return const SelectedText();
        },
      ),
    );
    await tester.pumpWidget(app());
    expect(find.text('value: 0'), findsOneWidget);
    failOnce = true;
    await tester.pumpWidget(app());
    expect(tester.takeException(), isA<StateError>());
    expect(find.byType(ErrorWidget), findsOneWidget);
    model.value = 1;
    await tester.pumpAndSettle();
    expect(find.text('value: 1'), findsOneWidget,
      reason: 'a transient build failure must not freeze the subtree');
    await tester.pumpWidget(const SizedBox.shrink());
    model.dispose();
  });

  testWidgets('stopping all selections removes the old selector', (tester) async {
    final model = ValueNotifier<int>(0);
    var read = true;
    var builds = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ScopeNotifier<ValueNotifier<int>>.value(
        value: model,
        builder: (_) => StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          builds++;
          final value = read
            ? ScopeNotifier.select<ValueNotifier<int>, int>(context, (m) => m.value)
            : null;
          return Text('value: $value');
        }),
      ),
    ));
    read = false;
    rebuild(() {});
    await tester.pump();
    final before = builds;
    model.value = 1;
    await tester.pump();
    expect(builds, before, reason: 'no value was selected in the latest build');
    await tester.pumpWidget(const SizedBox.shrink());
    model.dispose();
  });
}

final class SelectedText extends StatelessWidget {
  const SelectedText();
  @override
  Widget build(BuildContext context) {
    final value = ScopeNotifier.select<ValueNotifier<int>, int>(context, (m) => m.value);
    return Text('value: $value');
  }
}
```

### `async_probe_test.dart`

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

void main() {
  tearDown(() {
    ScopeConfig.observer = null;
    ScopeConfig.reset();
  });

  testWidgets('one nested job failure yields one scope error', (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final failure = StateError('nested failure');
    Object? shown;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: AsyncScope(
        initScope: (context, ctx) async {
          await ctx.run(Job.deferred<void>((middle) async {
            await middle.run(Job.deferred<void>((inner) async {
              throw failure;
            }));
          }));
        },
        disposeScope: () {},
        progressBuilder: (context, progress) => const Text('loading'),
        errorBuilder: (context, error, stackTrace, progress) {
          shown = error;
          return const Text('failed');
        },
        builder: (context) => const Text('ready'),
      ),
    ));
    await tester.pumpAndSettle();
    final errors = List<Object>.of(observer.errors);
    final phases = List<ScopePhase>.of(observer.phases);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    print('nested failure: shownSame=${identical(shown, failure)}, '
        'count=${errors.length}, phases=$phases');
    expect(shown, same(failure));
    expect(errors, [failure]);
  });

  testWidgets('LiteScope documented initialized guard reaches ready screen',
      (tester) async {
    final initialized = Completer<void>();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: _GuardScope(initialized: initialized),
    ));
    await tester.pumpAndSettle();
    expect(find.text('loading state'), findsOneWidget);
    initialized.complete();
    await tester.pumpAndSettle();
    final state = LiteScope.of<_GuardScope, _GuardState>(
      tester.element(find.byType(Text).first),
    );
    print('guard: isInitialized=${state.isInitialized}, '
        'loading=${find.text('loading state').evaluate().length}, '
        'ready=${find.text('ready state').evaluate().length}');
    expect(find.text('ready state'), findsOneWidget);
  });

  testWidgets('handled child ScopeInitJob failure is visible to scope observer',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final failure = StateError('handled child init job');
    var caught = false;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: AsyncScope(
        initScope: (context, ctx) async {
          try {
            await ctx.run(ScopeInitJob<void>((inner) async => throw failure));
          } on StateError {
            caught = true;
          }
        },
        disposeScope: () {},
        progressBuilder: (context, progress) => const Text('loading'),
        errorBuilder: (context, error, stackTrace, progress) =>
            const Text('failed'),
        builder: (context) => const Text('ready'),
      ),
    ));
    await tester.pumpAndSettle();
    final errors = List<Object>.of(observer.errors);
    final ready = find.text('ready').evaluate().length;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    print('handled child init job: caught=$caught, ready=$ready, '
        'observerCount=${errors.length}');
    expect(caught, isTrue);
    expect(ready, 1);
    expect(errors, [failure]);
  });
}

class _Errors extends ScopeObserver {
  final errors = <Object>[];
  final phases = <ScopePhase>[];

  @override
  void onError(ScopeObservable scope, ScopePhase phase, Object error,
      StackTrace? stackTrace) {
    errors.add(error);
    phases.add(phase);
  }
}

final class _GuardScope extends LiteScope<_GuardScope, _GuardState> {
  final Completer<void> initialized;

  const _GuardScope({required this.initialized});

  @override
  _GuardState createState() => _GuardState();

  @override
  Widget buildOnWaiting(BuildContext context) => const Text('scope waiting');
}

final class _GuardState extends LiteScopeState<_GuardScope, _GuardState> {
  @override
  Future<void> initStateAsync() => params.initialized.future;

  @override
  Widget build(BuildContext context) =>
      Text(isInitialized ? 'ready state' : 'loading state');
}
```

### `examples/examples_probe_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';
import 'package:scopo_demo/app/app.dart';
import 'package:scopo_demo/app/app_dependencies.dart';
import 'package:scopo_demo/home/home.dart';
import 'package:scopo_demo/home/home_dependencies.dart';
import 'package:scopo_demo/home/demos/async_scope/counter_scope.dart' as counter;
import 'package:scopo_demo/utils/app_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'scopo_deps_expanded.dart' as snippet;

Future<void> tickReal(WidgetTester tester, int iterations) async {
  for (var i = 0; i < iterations; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  test('scopo-deps skips database.close if session.close fails', () async {
    final database = snippet.Database();
    final dependencies = snippet.AppDependencies(
      database: database,
      session: snippet.Session(),
    );
    await expectLater(dependencies.dispose(), throwsStateError);
    expect(database.closed, isFalse);
    print('OBSERVED scopo-deps: failed session.close; database.closed = ${database.closed}');
  });

  testWidgets('AsyncScope example countOf does not follow increments', (tester) async {
    final oldPause = ScopeConfig.pauseAfterInitializationEnabled;
    ScopeConfig.pauseAfterInitializationEnabled = false;
    addTearDown(() => ScopeConfig.pauseAfterInitializationEnabled = oldPause);
    BuildContext? readContext;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: counter.CounterScope(
      debugSource: 'countOf probe',
      debugName: 'probe',
      childScope: Builder(builder: (context) {
        readContext = context;
        return Text('watched: ${counter.CounterScope.countOf(context)}');
      }),
    ))));
    await tickReal(tester, 30);
    expect(find.text('watched: 0'), findsOneWidget);
    counter.CounterScope.of(readContext!).increment();
    await tester.pump();
    expect(counter.CounterScope.of(readContext!).count, 1);
    expect(find.text('watched: 0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    print('OBSERVED AsyncScope countOf: model = 1, builtin listener = 1, countOf text = 0');
    await tester.pumpWidget(const SizedBox.shrink());
    await tickReal(tester, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('root App updates the theme icon on system brightness change', (tester) async {
    final oldPause = ScopeConfig.pauseAfterInitializationEnabled;
    final oldInit = AppEnvironment.defaultInitPause;
    final oldDispose = AppEnvironment.defaultDisposePause;
    ScopeConfig.pauseAfterInitializationEnabled = false;
    AppEnvironment.defaultInitPause = Duration.zero;
    AppEnvironment.defaultDisposePause = Duration.zero;
    addTearDown(() {
      ScopeConfig.pauseAfterInitializationEnabled = oldPause;
      AppEnvironment.defaultInitPause = oldInit;
      AppEnvironment.defaultDisposePause = oldDispose;
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(App(
      init: AppDependencies.init,
      progressBuilder: (_, progress) => Text(progress ?? ''),
      builder: (_) => Home(init: HomeDependencies().init),
    ));
    await tickReal(tester, 20);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.light_mode), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tickReal(tester, 30);
    expect(tester.takeException(), isNull);
  });
}
```

### `examples/reload_probe_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';
import 'package:scopo_demo/app/app.dart';
import 'package:scopo_demo/app/app_dependencies.dart';
import 'package:scopo_demo/common/data/fake_services/fake_bloc.dart';
import 'package:scopo_demo/home/home.dart';
import 'package:scopo_demo/home/home_dependencies.dart';
import 'package:scopo_demo/utils/app_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> tickReal(WidgetTester tester, int iterations) async {
  for (var i = 0; i < iterations; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('ready Home bloc accepts another load without repeating initialization completion', (tester) async {
    final oldPause = ScopeConfig.pauseAfterInitializationEnabled;
    final oldInit = AppEnvironment.defaultInitPause;
    final oldDispose = AppEnvironment.defaultDisposePause;
    ScopeConfig.pauseAfterInitializationEnabled = false;
    AppEnvironment.defaultInitPause = Duration.zero;
    AppEnvironment.defaultDisposePause = Duration.zero;
    addTearDown(() {
      ScopeConfig.pauseAfterInitializationEnabled = oldPause;
      AppEnvironment.defaultInitPause = oldInit;
      AppEnvironment.defaultDisposePause = oldDispose;
    });
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(App(
      init: AppDependencies.init,
      progressBuilder: (_, progress) => Text(progress ?? ''),
      builder: (_) => Home(init: HomeDependencies().init),
    ));
    await tickReal(tester, 20);
    final context = tester.element(find.text('ScopeWidgetExample'));
    final bloc = Home.of(context).dependencies.bloc;
    expect(bloc.state, isA<FakeBlocSuccess>());
    bloc.add(FakeBlocLoad());
    await tickReal(tester, 5);
    // The test framework receives any asynchronous listener failure directly.
    // No takeException: that only reads build/layout failures, and would
    // add an unrelated null assertion after the actual listener error.
    expect(bloc.state, isA<FakeBlocSuccess>());
    await tester.pumpWidget(const SizedBox.shrink());
    await tickReal(tester, 30);
    expect(tester.takeException(), isNull);
  });
}
```

### `examples/scopo_deps_expanded.dart`

```dart
import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

final class Database {
  bool closed = false;
  static Future<Database> open() async => Database();
  Future<void> close() async { closed = true; }
}
final class Session {
  static Future<Session> connect() async => Session();
  Future<void> close() async { throw StateError('session.close failed'); }
}

final class AppDependencies implements ScopeDependencies {
  // Final, and that is the reason to write a container by hand at all:
  // `ScopeAutoDependencies` fills its fields as it walks the tree, so they
  // cannot be. Here everything that changes lives inside [init], and what
  // leaves it is assembled once and never edited again.
  final Database database;
  final Session session;

  const AppDependencies({
    required this.database,
    required this.session,
  });

  static Future<AppDependencies> init(
    BuildContext context,
    ScopeInitContext ctx,
  ) async {
    // Until the container is handed over, the job owns the cleanup.
    // `discard` also closes a value that arrives after `abandonable` was
    // cancelled, and releases received values in reverse order if a later
    // step fails.
    ctx.progress('opening the database');
    final database = await ctx.abandonable(
      Database.open,
      discard: (value) => value.close(),
    );

    ctx.progress('connecting');
    final session = await ctx.abandonable(
      Session.connect,
      discard: (value) => value.close(),
    );
    
    final dependencies = AppDependencies(
      database: database,
      session: session,
    );
    // The scope releases the container, including a late return. Remove the
    // job's registrations here so cancellation cannot release it twice.
    // No await or checkpoint between this handover and the return.
    ctx
      ..disown(session)
      ..disown(database);
    return dependencies;
  }

  /// Drops what must stop reaching the dependencies at once. Runs once,
  /// always before [dispose].
  @override
  void onUnmount() {}

  /// Reached only for a container the scope took over, so both fields are
  /// there — no question of whether a step ran.
  @override
  Future<void> dispose() async {
    await session.close();
    await database.close();
  }
}

// `ScopeAutoDependencies` does the unwinding for you: register
// `dep.dispose` as each step succeeds and the tree comes apart in reverse,
// cancelled or not. Write the container by hand for an immutable one, or
// when the order or the conditions are yours rather than the tree's — see
// `scopo-autodeps`.
```
