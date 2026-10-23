# Полное ревью проекта: Sol

> **Состояние на 2026-10-23:** ревью принято, ни одна находка ещё не в работе.
> Все зонды перезапущены на клоне ревьюера и воспроизвелись (раздел «Приёмка»
> в конце).
> **Что это:** независимое полное ревью scopo на `765ab0c`, сделанное
> `gpt-6.1-sol` с усилием `xhigh` через `codex exec`. В нём оценки по
> 10-балльной шкале (код 8, документация 7, общая 7,5), удобство для человека
> и для агентов, ответ на вопрос «нужен ли проект» и пять находок: P0 и P1 нет,
> все пять P2.
> **Связанные записи:** `2026-10-23[2]-astra-project-review.md` (второе ревью
> того же коммита, независимое).

Ниже отчёт ревьюера дословно, менялись только переносы строк. Ссылки
на `/Users/user/.claude/jobs/715c8327/tmp/review/out-sol/` ведут во временный
каталог сессии и долго не проживут. Исходники зондов сохранены в «Приложении»
в конце записи.

## ПРОГОН

Проверен коммит `765ab0c28e6cafd23fdaf3334713554ecccb2378`. Тулчейн подтверждён
командой `fvm flutter --version`: Flutter 3.27.0, Dart 3.6.0.

Все обязательные команды выполнены. Ниже — последние непустые строки вывода;
у обновляемого через `\r` индикатора тестов убраны только завершающие пробелы.

| Команда | Точная последняя строка |
|---|---|
| `fvm flutter test` | `00:12 +570: All tests passed!` |
| `fvm flutter analyze` | `No issues found! (ran in 3.9s)` |
| `(cd example/minimal && fvm flutter analyze)` | `No issues found! (ran in 1.3s)` |
| `(cd example/scopo_demo && fvm flutter analyze)` | `No issues found! (ran in 1.8s)` |
| `fvm dart format --set-exit-if-changed lib test` | `Formatted 118 files (0 changed) in 0.61 seconds.` |
| `fvm dart doc --dry-run` | `Found 0 warnings and 0 errors.` |
| `sh docs/ru/check.sh` | `переводы актуальны: 16` |
| `(cd example/scopo_demo && fvm flutter test)` | `00:09 +5: All tests passed!` |

Отказов песочницы не было. Журналы лежат
в `/Users/user/.claude/jobs/715c8327/tmp/review/out-sol/`: `root-test.log`,
`root-analyze.log`, `minimal-analyze.log`, `demo-analyze.log`, `format.log`,
`doc.log`, `translations.log`, `demo-test.log`.

Дополнительно выполнены шесть внешних зондов:

```sh
fvm flutter test --no-pub /Users/user/.claude/jobs/715c8327/tmp/review/out-sol/probes/test --reporter expanded
```

Последняя строка: `00:00 +6: All tests passed!`. Это диагностические зонды,
печатающие наблюдаемое поведение, а не шесть новых регрессионных тестов
проекта. Их вывод разобран ниже;
[общий журнал](/Users/user/.claude/jobs/715c8327/tmp/review/out-sol/all-probes.log).

Отдельный зонд совместимости старого примера и нового API:

```sh
fvm dart analyze /Users/user/.claude/jobs/715c8327/tmp/review/out-sol/probes/legacy_init.dart
```

Завершился с кодом 3 и строкой `1 issue found.` — ожидаемое подтверждение
несовместимости, описанной в находке 4. XML IDE-шаблонов дополнительно разобран
стандартным XML-парсером: `IDE_XML_PARSE templates=11 snippets=11`.

Исходники не изменялись. Финальные `git diff --exit-code`
и `git status --short --untracked-files=all` завершились без вывода.
`docs/handoff.md` не обновлял: прямой запрет задания имеет приоритет над
требованием AGENTS.md §2 обновлять его перед ревью и после находок. Реализацию,
коммиты и публикацию не выполнял.

Проверки относятся к закреплённому SDK и widget-тестам. Приложения
на устройствах, release-сборки, браузерное выполнение и производительность
отдельно не проверялись. `async_job` как самостоятельный проект не ревьюился.
Раздел 0.17.0 при версии 0.16.0 принят как оговорённая подготовка выпуска.

## Оценки

**Код — 8/10.** Жизненный цикл проработан значительно глубже, чем обычно
у небольшого инфраструктурного пакета: отдельные признаки принятого значения
и отображённой готовности, освобождение поздних результатов, продолжение уборки
после ошибок, разделение владельца и представления. Сьюта проверяет
существенные сценарии, включая отмену и ошибки пользовательских хуков.
До девяти подняли бы исправление повторного разбора чужих зависимостей
и проверка одинаковых жизненных сценариев через разные способы владения
контроллером.

**Документация — 7/10.** Потребитель получает объяснение владения, отмены,
уведомлений, тестирования и выбора семейства; русские зеркала включены
в проверяемый процесс. Но есть исполнимо неверный рецепт, остатки прежнего API
и серьёзное расхождение внутренней справки с текущим кодом. Ещё балл дали бы
устранение этих противоречий и небольшой полностью рабочий стартовый пример,
проверяемый непосредственно из текста документа.

**Общая — 7,5/10.** Это технически содержательный пакет с реальной
специализацией, но пока с дорогим входом и неподтверждённой пригодностью для
чужих приложений. Единственный известный пользователь — автор; объём API
и сопровождающего регламента уже существенно больше объёма внешней обратной
связи. Ещё балл принесли бы независимые внедрения, показавшие пользу именно
асинхронного владения, и сокращение числа правил, которые потребитель должен
помнить вручную.

## Удобство для человека

Первый простой экран написать можно без чтения исходников. Таблица семейств
в README полезна, колбэковые `ScopeModel`, `ScopeNotifier` и `AsyncDataScope`
достаточно прямолинейны. Аксессоры `ScopeAccess` сокращают повторение типов,
IDE-шаблоны действительно проверяются на соответствие компилируемым заготовкам.

Но основной вход перегружен. README занимает 876 строк, демонстрирует восемь
семейств, затем подробно разбирает самое большое. `example/minimal` сознательно
минимален по числу файлов, а не по числу необходимых понятий: контейнер,
состояние, ветви построения и статические аксессоры появляются сразу. Для
знакомства с ценностью пакета пример «ресурс открывается, экран исчезает
посередине, ресурс корректно закрывается» был бы убедительнее большого счётчика
с `SharedPreferences`.

Имена в целом последовательны, но ожидания от знакомых слов требуют
переучивания. `Scope.of` возвращает состояние без подписки; другие `of`
возвращают модель или контекст и принимают `listen`. `initStateAsync`
начинается уже внутри готовой ветви. `notifyDependents` не обновляет
собственный `build`. Это объяснено, однако цена ошибки велика: визуально
приложение может просто остаться на старом экране.

Диагностика неправильного использования — сильная сторона. Ошибки подписки вне
сборки, изменения `scopeKey`, повторного использования контроллера объясняют
нарушенное правило и способ исправления. Диагностика отсутствующего скоупа
заметно слабее: обычный `Exception('$W not found in the context')` даёт меньше
помощи, чем остальные тщательно оформленные ошибки.

Ещё одно обязательное знание: порядок освобождения и исключение по `scopeKey`
ограничены таймаутами. По умолчанию истечение через три секунды означает
продолжение работы. Это документированная политика, поэтому отдельным дефектом
её не считаю, но для базы, плеера или другого ресурса со строгим запретом
перекрытия потребитель должен осознанно настроить соответствующие лимиты.

## Удобство для агентов

**Агент, пишущий приложение на scopo.** Для основных сценариев README, темы
dartdoc и примеры дают достаточно информации. Особенно полезны объяснения
момента передачи владения, `disown`, частичной уборки и разницы между
`setState` и `notifyDependents`. Типизированные аксессоры и проверяемые шаблоны
уменьшают вероятность выдуманного API.

Слабое место — достоверность отдельных авторитетных фрагментов. Агент может
правильно скопировать рецепт из `doc/lite_scope.md` и получить вечный
loading-экран. Может найти через dartdoc старые `ScopeReady` и `asStream`, хотя
changelog утверждает, что они удалены. Общий зелёный анализ проекта этого
не обнаруживает. Правильный код без чтения исходников возможен, но сейчас
требует собственного маленького исполняемого стенда.

**Агент, сопровождающий репозиторий.** AGENTS.md хорошо задаёт порядок
восстановления, тулчейн, запрет смешивать чужие изменения, требования
к переводам и проверку нагруженности тестов. Исторические ревью с вердиктами
позволяют отличить исправленный дефект от принятого ограничения. Это стоит
сохранить.

Восстановление текущего состояния, напротив, требует расследования.
`handoff.md` занимает 1252 строки и одновременно содержит свежие сведения
и отменяющие их старые инструкции. `architecture.md` описывает устройство
до нескольких крупных миграций. Основная помеха здесь — противоречивость
источников, объявленных точками восстановления. Строгость регламента
не компенсирует недостоверный снимок состояния.

## Нужен ли проект

**Да, для узкой задачи: владение асинхронными ресурсами, привязанное к дереву
виджетов, с наблюдаемым завершением и упорядоченным освобождением.** Для
обычной передачи объектов и обновления интерфейса оснований выбирать его
существенно меньше.

Сравнение с альтернативами:

| Решение | Что уже закрывает | Где остаётся место для scopo |
|---|---|---|
| `provider` | Предоставление объектов, владение созданным экземпляром, уведомления и селекторы. [Документация](https://pub.dev/packages/provider) | Когда нужен общий протокол ожидания асинхронной инициализации и завершения дочерних владельцев. |
| Riverpod | Асинхронные значения, зависимости между провайдерами, автоматическое уничтожение и хуки жизненного цикла. `onDispose` принимает синхронный обработчик. [Жизненный цикл](https://riverpod.dev/docs/concepts2/auto_dispose), [сигнатура `onDispose`](https://pub.dev/documentation/riverpod/latest/riverpod/Ref/onDispose.html) | Когда завершение освобождения должно быть ожидаемым этапом, связанным именно с иерархией экранов. |
| `flutter_bloc` | Состояния и реакции интерфейса; `BlocProvider` закрывает созданный им bloc, `RepositoryProvider` поддерживает освобождение репозитория. [Документация](https://bloclibrary.dev/flutter-bloc-concepts/) | Когда порядок завершения нескольких ресурсов сложнее закрытия одного bloc или repository. |
| `get_it` | Скоупы, асинхронная инициализация, ожидаемый `popScope`, освобождение в обратном порядке регистрации. [Документация скоупов](https://flutter-it.dev/documentation/get_it/scopes) | Когда владельцем должен быть конкретный участок дерева, а загрузка, ошибки и закрытие должны иметь готовое представление в UI. |
| `injectable` | Генерация регистрации для `get_it`, включая асинхронные зависимости и освобождение. [Документация](https://pub.dev/packages/injectable) | Выбор между генерируемой регистрацией и явной моделью владельцев в виджетах. |

Самый близкий конкурент здесь — `get_it`, а не простой `provider`. Поэтому
начальное утверждение README, сводящее альтернативы к доставке значения
потребителю, слишком упрощает сравнение: асинхронное владение и ожидаемая
уборка уже существуют в других решениях.

Scopo нужен приложениям с сеансами, сокетами, базами, плеерами и дочерними
экранами, завершение которых действительно приходится согласовывать. Он может
сосуществовать с BLoC или другими моделями состояния. Для синхронных сервисов,
простого CRUD и приложений с уже достаточным управлением жизненным циклом
переход не окупается.

Главные препятствия принятию: необходимость понять собственную модель
жизненного цикла, широкий выбор похожих семейств, изменения публичного API
в истории выпусков и отсутствие подтверждённого опыта независимых
пользователей. Следующее доказательство ценности проекта должно прийти
из чужого приложения.

## Находки по убыванию практического риска

P0 и P1 в этом проходе не подтверждены. Ниже — пять P2: один дефект повторного
освобождения, одно существенное ограничение переносимости и три проблемы
документации.

### 1. P2 — повторный разбор после ошибки чужого диспозера неправильно учитывает оставшиеся ресурсы

**Координаты:**
`lib/src/scope/full_scope/scope_auto_dependency/scope_dependency/scope_dependency_group.dart`,
члены `ScopeDependencyGroup.disposalRequired` и `_disposalOrder`; соседний
`scope_dependency_mixin.dart`, члены `ScopeDependencyMixin.dispose`
и `_mayStillHold`.

Чужая реализация `ScopeDependency` может не освободить ресурс при первой ошибке
и продолжать возвращать `disposalRequired == true`. Существующий тест
`a foreign child that threw is a tree that may still be holding` признаёт такой
случай допустимым, но проверяет только первую попытку.

После ошибки группа переходит в `ScopeDependencyDisposalFailed`. Её
`disposalRequired` этого состояния не учитывает. Если группа вложена в другую,
следующий разбор родителя пропускает её и не вызывает удерживаемый диспозер
повторно. Дополнительно `_mayStillHold`, поднятый первой ошибкой,
не пересчитывается для новой попытки: даже без вложенности успешное повторное
освобождение не разрешает новую инициализацию контейнера.

[Зонд `nested_retry_test.dart`](/Users/user/.claude/jobs/715c8327/tmp/review/out-sol/probes/test/nested_retry_test.dart),
запущенный через указанную выше команду, вывел:

```text
RETRY_SECOND nested=false attempts=2 held=false rootRequired=false
RETRY_SECOND nested=true attempts=1 held=true rootRequired=false
```

В обоих случаях последующий `init` получил `has not been disposed of`. Без
вложенности ресурс уже освобождён; с вложенностью он остаётся удерживаемым
и повторный вызов до него не доходит.

Это специализированный сценарий расширения API, поэтому P2. Встроенный `dep`,
снимающий собственный диспозер до вызова, сам по себе его не воспроизводит.
Исправление должно пересматривать обе стороны учёта: необходимость повторного
обхода ошибочной группы и признак оставшихся ресурсов после очередной попытки.

**Вердикт: исправлено.** `6fb8896`, задание `retry` через Codex (Astra).
`ScopeDependencyGroup.disposalRequired` учитывает
и `ScopeDependencyDisposalFailed`, так что родитель заходит в такую группу
снова, а `ScopeDependencyMixin.dispose` сбрасывает `_walkReachedEveryChild`
и `_mayStillHold` в начале каждой попытки. Десять тестов
в `test/scope_auto_dependencies_test.dart`; откат любой из двух правок роняет
часть из них.

### 2. P2 — обещание переноса контроллера в `controllerDep` скрывает другое поведение `mounted`

**Координаты:**
`lib/src/scope/full_scope/scope_auto_dependency/scope_auto_dependency.dart`,
`ScopeAutoDependencies.controllerDep` и `init`;
`lib/src/scope/full_scope/scope_core.dart`, `ScopeElementBase.onUnmount`;
README, раздел `AsyncControllerScope`; `doc/full_scope.md`, описание
`controllerDep`.

README обещает, что тот же контроллер подходит в дерево зависимостей без
изменений. Но контроллер в `AsyncControllerScope` получает `performUnmount`
сразу при удалении скоупа. У `controllerDep` во время незавершённой
инициализации контейнер ещё не принят элементом `Scope`, поэтому немедленный
вызов до контроллера не доходит. Отмена ждёт завершения начатого
инициализатора, и только потом контейнер вызывает `onUnmount`.

[Зонд `controller_dep_test.dart`](/Users/user/.claude/jobs/715c8327/tmp/review/out-sol/probes/test/controller_dep_test.dart)
использовал обычное `await`, затем документированную проверку
`if (!mounted) return`:

```text
DEP_AFTER_REMOVE mounted=true calls=[init]
DEP_FINISHED mounted=false calls=[init, after await mounted=true, started external work, unmount, dispose]
```

Проверка `mounted` разрешила начать внешнюю работу для уже удалённого скоупа.

Окончательный `dispose` не потерян. Более того, ожидание завершения
инициализатора уже закреплено
в `test/scope_auto_dependency_controller_test.dart` и признано
в `docs/records/2026-08-24[5]-controller-dependency-design.md`. Находка —
в неназванной границе обещанной переносимости: одинаковый класс получает разные
гарантии остановки. Нужно либо обеспечить ранний сигнал остановки, либо явно
описать ограничение рядом с предложением переносить контроллер без изменений.

**Вердикт: исправлено правкой обещания, а не кода.** `5c44e81`, задание `docs`;
решение моё, принятое за владельца. Поведение `mounted` у `controllerDep`
не меняется: README и `doc/full_scope.md` больше не говорят, что контроллер
переносится «без изменений», и описывают ограничение — `mounted` остаётся
`true`, пока идёт инициализатор, а проверять отмену надо через
`ScopeInitContext` и `ctx.check()`.

### 3. P2 — рецепт ожидания `initStateAsync` оставляет собственный экран на загрузке

**Координаты:** `doc/lite_scope.md`, раздел `Two initializations`, пример
`build` с `if (!isInitialized)`; зеркало `docs/ru/doc/lite_scope.md`;
`lib/src/scope/lite_scope/lite_scope_core.dart`,
`LiteScopeCoreState._completeInit`.

Тема предлагает задержать содержимое собственного `build`, пока `isInitialized`
не станет истинным. Но завершение инициализации вызывает `onInitialized`
и `notifyDependents`, а собственного `setState` не делает. Без дополнительной
подписки или внешней пересборки показанный экран остаётся на загрузке.

[Зонд `contracts_test.dart`](/Users/user/.claude/jobs/715c8327/tmp/review/out-sol/probes/test/contracts_test.dart)
дождался завершения управляемого `Completer`, затем выполнил `pumpAndSettle`:

```text
STATE_INIT repair=false initialized=true loading=1 ready=0
STATE_INIT repair=true initialized=true loading=0 ready=1
```

Контрольный вариант отличался вызовом `setState` из `onInitialized`.

Разделение уведомлений и собственной пересборки последовательно реализовано
и отдельно объяснено. Поэтому это дефект рецепта, а не требование менять общую
семантику `notifyDependents`. Пример должен показать действие, переводящее
собственный экран из loading в ready, и проверяться целиком.

**Вердикт: исправлено.** `5c44e81`, задание `docs`; это та же находка, что
третья у Astra, и закрыта она тем же исполняемым рецептом с `setState`
из `onInitialized()`.

### 4. P2 — публичная поверхность и dartdoc сохранили API, объявленный удалённым

**Координаты:** `lib/src/scope/full_scope/scope_init_state.dart`, классы
`ScopeInitState`, `ScopeProgress`, `ScopeReady`; `scope_dependencies.dart`,
`ScopeDependenciesExtension.asStream`;
`lib/src/scope/async_data_scope/async_data_scope_init_state.dart`;
`lib/src/utils/progress_iterator/progress_iterator.dart`, dartdoc
`ProgressIterator`; CHANGELOG, описание перехода на `Future`.

Changelog говорит, что перечисленные состояния и `asStream` удалены.
В проверяемом коммите они продолжают экспортироваться через `scope.dart`, без
пометки устаревания. Dartdoc `ProgressIterator` продолжает учить инициализации
через `Stream<ScopeInitState<...>>` и `yield ScopeProgress`.

Сами старые типы компилируются, но результат такого инициализатора уже
не подходит современному `Scope.initDependencies`. Адаптация образца
к действующему хуку дала:

```text
A value of type 'Stream<ScopeInitState<Progress, Dependencies>>' can't be returned from the method 'initDependencies' because it has a return type of 'Future<Dependencies>'.
```

[Исходник зонда](/Users/user/.claude/jobs/715c8327/tmp/review/out-sol/probes/legacy_init.dart),
[вывод анализатора](/Users/user/.claude/jobs/715c8327/tmp/review/out-sol/legacy-init.log).

Это создаёт особенно неприятную ловушку для поиска по API: старый путь выглядит
действующим, но перестал соединяться с жизненным циклом пакета. Нужно
согласовать экспорт, changelog и примеры. Заодно у `ScopeObserver` dartdoc всё
ещё называет класс `base`, хотя объявление уже открыто для реализации
и мокирования.

**Вердикт: исправлено удалением.** `55c8a2a`, задание `legacy` через Codex
(Sol); решение моё, принятое за владельца: обещание 0.14.0 исполняется,
а не переписывается. `ScopeInitState`, `ScopeProgress`, `ScopeReady`, состояния
`AsyncDataScope*` и `ScopeDependenciesExtension.asStream` удалены, пример
`ProgressIterator` переписан на `ctx.progress`, в CHANGELOG 0.17.0 — пункт
**Breaking**. Замечание о dartdoc `ScopeObserver` закрыто в `5c44e81`.

### 5. P2 — документы восстановления противоречат действующему устройству и состоянию проекта

**Координаты:** `docs/handoff.md`, разделы `С чего начать после рестарта`,
`Решения владельца, которые действуют дальше`, `В рабочем дереве`;
`docs/architecture.md`, разделы 5, 7–10. **По чтению**, с проверкой
соответствующих объявлений и текущего git-состояния.

В начале handoff правильно указаны переход на `async_job 0.3.0`, 570 тестов
и подготовка 0.17.0. Ниже тот же файл утверждает, что открытого раздела
CHANGELOG нет, после 0.16.0 код не менялся, а backlog пуст. В блоке действующих
решений сохраняется инструкция использовать `finally` с флагом, потому что
отмена ничего не бросает; актуальная публичная документация и код уже опираются
на `Cancelled` и `catch`.

`architecture.md` честно датирован версией 0.10.0, однако остаётся
архитектурной справкой, на которую направляет AGENTS.md. Он описывает запуск
асинхронной инициализации из `mount`, потоковую инициализацию, старые имена
хуков, живое поддерево после неудачного screenshot и отсутствие внешних
зависимостей. В текущем коде соответствующие ответы другие.

Историческая запись имеет право устареть. Снимок текущего состояния и рабочая
справка должны позволять восстановиться без выбора между несовместимыми
инструкциями. Следует оставить в handoff действующее состояние, перенести
завершённые эпизоды в историю и обновить архитектуру до текущего механизма
задач.

## Что сделано хорошо и стоит сохранить

Пакет имеет ясное техническое ядро: дерево владельцев, передача результата
после успешного завершения и ожидаемая утилизация. Особенно стоит сохранить
различие между фактом получения ресурса и моментом показа ready-ветви — оно
закрывает реальные утечки при быстром удалении виджета.

Обработка ошибок уборки достаточно зрелая. Ошибка одного хука не должна
отменять освобождение остальных ресурсов, и код систематически проводит это
правило через слои. Поздние результаты и брошенные ожидания получили отдельные
пути освобождения и диагностики.

Тесты проверяют поведение. Сильные области — порядок освобождения, `scopeKey`,
закрытие в разных состояниях, ошибки пользовательских хуков, поздняя
инициализация, каналы ошибок ядра. В этом проходе обнаружился конкретный
пробел — повторная уборка ошибочной чужой зависимости с вложенной группой; он
не обесценивает остальную сьюту.

CI воспроизводит закреплённый минимум SDK, проверяет примеры и чистоту дерева.
Отдельный неблокирующий прогон свежего stable полезен как ранний сигнал.
Локальный результат не следует выдавать за проверку текущего удалённого CI,
но сама конфигурация выглядит осмысленной.

IDE-шаблоны, русские зеркала и вердикты внутри прежних ревью — полезная
инфраструктура. Проверка переводов подтверждает соответствие хешей оригиналов;
смысловую правильность текста всё равно приходится проверять чтением. Этот
предел уже честно описан в регламенте.

## Итог

Scopo решает реальную, достаточно узкую задачу асинхронного владения ресурсами
во Flutter. Обязательный прогон чист: 570 тестов пакета, 5 тестов демо, анализ,
форматирование и документация. Подтверждён дефект повторной утилизации чужих
зависимостей; массового отказа основных семейств не найдено. Документация
полезна, но местами даёт неверный исполнимый рецепт или противоречит текущему
API. Следующий приоритет — исправить найденный учёт уборки и согласовать
публичные и внутренние объяснения. Дальнейшую ценность проекта лучше проверять
независимым внедрением; рабочее дерево после ревью чистое.

## Приёмка

Принимал 2026-10-23 Claude. Строка
`=== sol (gpt-6.1-sol:xhigh) rc=0 за 1210 c`, в шапке лога `model: gpt-6.1-sol`
и `reasoning effort: xhigh`. После прогона `git status --short` клона пуст,
дифф пуст.

**Прогон.** Числа совпадают с гейтом §6, который я прогнал на том же коде перед
мержем `2ee070c`: 570, три чистых `analyze`, 118/0, 0/0, 16, демо 5. Отдельно
гейт на клоне ревьюера я не повторял.

**Зонды.** Перезапущены мной в клоне ревьюера:
`fvm flutter test --no-pub out-sol/probes/test --reporter expanded` даёт
`00:00 +6: All tests passed!`. Зонды печатают поведение, а не падают на нём.
Строки совпали с цитатами отчёта:

- находка 1:
  `RETRY_SECOND nested=false attempts=2 held=false rootRequired=false`
  и `RETRY_SECOND nested=true attempts=1 held=true rootRequired=false`. Оба
  `RETRY_REINIT` получают `has not been disposed of`;
- находка 2: `DEP_AFTER_REMOVE mounted=true calls=[init]`
  и `DEP_FINISHED mounted=false calls=[init, after await mounted=true,
  started external work, unmount, dispose]`;
- находка 3: `STATE_INIT repair=false initialized=true loading=1 ready=0`
  против `repair=true … loading=0 ready=1`;
- находка 4: `fvm dart analyze out-sol/probes/legacy_init.dart` даёт rc 3
  и `return_of_invalid_type`, строка совпала.

**По чтению проверено.** Находка 4: `ScopeInitState`, `ScopeProgress`,
`ScopeReady` и `ScopeDependenciesExtension.asStream` лежат в `part`-файлах
`lib/src/scope/scope.dart`: `full_scope/scope_init_state.dart`
и `full_scope/scope_dependencies.dart`. Там же
`async_data_scope/async_data_scope_init_state.dart`. Значит, они
экспортируются, а `CHANGELOG.md` говорит «are gone». `ScopeObserver` назван
`base class` в своём dartdoc, хотя объявлен как `class ScopeObserver`.

**Пересечение с Astra.** Находка 3 здесь — та же, что находка 3
в `2026-10-23[2]-astra-project-review.md`. Расхождение `base class`
и устаревшие handoff и `architecture.md` отмечены в обоих ревью. Остальные
находки у ревьюеров не пересекаются.

## Приложение: исходники зондов

Пути — относительно `/Users/user/.claude/jobs/715c8327/tmp/review/out-sol`.

### `probes/test/nested_retry_test.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

void main() {
  for (final nested in [false, true]) {
    test('retry foreign release nested=$nested', () async {
      final errors = <Object>[];
      final previous = FlutterError.onError;
      final deps = Deps(nested);
      FlutterError.onError = (details) => errors.add(details.exception);
      Object? initError;
      try {
        await (ScopeInitJob<Deps>((ctx) => deps.init(null, ctx))..start()).value;
        final old = deps.resources.single;
        await deps.dispose();
        print('RETRY_FIRST nested=$nested attempts=${old.attempts} held=${old.held} rootRequired=${deps.root.disposalRequired}');
        await deps.dispose();
        print('RETRY_SECOND nested=$nested attempts=${old.attempts} held=${old.held} rootRequired=${deps.root.disposalRequired}');
        try {
          await (ScopeInitJob<Deps>((ctx) => deps.init(null, ctx))..start()).value;
        } on Object catch (e) { initError = e; }
        print('RETRY_REINIT nested=$nested builds=${deps.resources.length} oldHeld=${old.held} error=$initError reported=${errors.length}');
      } finally {
        FlutterError.onError = previous;
      }
    });
  }
}
final class Deps extends ScopeAutoDependencies<Deps, void> {
  final bool nested;
  final resources = <RetryResource>[];
  Deps(this.nested);
  @override ScopeDependency buildDependencies(void _) {
    final resource = RetryResource();
    resources.add(resource);
    return sequential('root', [
      if (nested) sequential('inner', [resource]) else resource,
    ]);
  }
}
final class RetryResource implements ScopeDependency {
  bool held = false;
  int attempts = 0;
  ScopeDependencyState _state = const ScopeDependencyInitial();
  @override String get name => 'resource';
  @override int get count => 1;
  @override ScopeDependencyState get state => _state;
  @override bool get disposalRequired => held;
  @override Future<void> init(ScopeInitContext ctx, void Function(String) onStep) async {
    held = true;
    _state = const ScopeDependencyInitialized();
    onStep(name);
  }
  @override void onUnmount() {}
  @override Future<void> dispose(void Function(String) onStep) async {
    attempts++;
    if (attempts == 1) throw StateError('transient release failure');
    held = false;
    _state = const ScopeDependencyDisposed();
    onStep(name);
  }
  @override String get wrappedName => name;
  @override String stateToString() => '$state';
}
```

### `probes/test/controller_dep_test.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

void main() {
  testWidgets('controllerDep mounted while unfinished owner leaves', (tester) async {
    final gate = Completer<void>();
    final calls = <String>[];
    final deps = Deps(gate.future, calls);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Holder(deps: deps),
    ));
    await tester.pumpAndSettle();
    print('DEP_BEFORE_REMOVE mounted=${deps.controller.mounted} calls=$calls');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    print('DEP_AFTER_REMOVE mounted=${deps.controller.mounted} calls=$calls');
    gate.complete();
    await tester.pumpAndSettle();
    print('DEP_FINISHED mounted=${deps.controller.mounted} calls=$calls');
  });
}
final class Controller extends ScopeController {
  final Future<void> gate;
  final List<String> calls;
  Controller(this.gate, this.calls);
  @override Future<void> init() async {
    calls.add('init');
    await gate;
    calls.add('after await mounted=$mounted');
    if (!mounted) return;
    calls.add('started external work');
  }
  @override void onUnmount() => calls.add('unmount');
  @override void dispose() => calls.add('dispose');
}
final class Deps extends ScopeAutoDependencies<Deps, void> {
  final Future<void> gate;
  final List<String> calls;
  late Controller controller;
  Deps(this.gate, this.calls);
  @override ScopeDependency buildDependencies(void _) =>
    controllerDep('controller', () => controller = Controller(gate, calls));
}
final class Holder extends Scope<Holder, Deps, HolderState> {
  final Deps deps;
  const Holder({required this.deps});
  @override Future<Deps> initDependencies(BuildContext context, ScopeInitContext ctx) => deps.init(null, ctx);
  @override HolderState createState() => HolderState();
  @override Widget buildOnProgress(BuildContext context, Object? progress) => const Text('loading');
  @override Widget buildOnError(BuildContext context, Object error, StackTrace stack, Object? progress) => const Text('error');
}
final class HolderState extends ScopeState<Holder, Deps, HolderState> {
  @override Widget build(BuildContext context) => const Text('ready');
}
```

### `probes/test/contracts_test.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

void main() {
  tearDown(ScopeConfig.reset);
  testWidgets('late progress from a retained context', (tester) async {
    late ScopeInitContext retained;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: AsyncScope(
        initScope: (_, ctx) async { retained = ctx; },
        disposeScope: () {},
        progressBuilder: (_, __) => const Text('loading'),
        errorBuilder: (_, e, s, p) => const Text('error'),
        builder: (_) => const Text('ready'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('ready'), findsOneWidget);
    Object? caught;
    try { retained.progress('late'); } on Object catch (e) { caught = e; }
    print('LATE_PROGRESS ready=true exception=$caught type=${caught.runtimeType}');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  for (final repair in [false, true]) {
    testWidgets('state own loading branch setState=$repair', (tester) async {
      final gate = Completer<void>();
      late LoadingState state;
      await tester.pumpWidget(MaterialApp(home: LoadingScope(
        gate: gate.future,
        repair: repair,
        capture: (s) => state = s,
      )));
      await tester.pumpAndSettle();
      expect(find.text('loading state'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      print('STATE_INIT repair=$repair initialized=${state.isInitialized} loading=${find.text('loading state').evaluate().length} ready=${find.text('ready state').evaluate().length}');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
final class LoadingScope extends LiteScope<LoadingScope, LoadingState> {
  final Future<void> gate;
  final bool repair;
  final void Function(LoadingState) capture;
  const LoadingScope({required this.gate, required this.repair, required this.capture});
  @override Widget buildOnWaiting(BuildContext context) => const SizedBox.shrink();
  @override LoadingState createState() {
    final state = LoadingState();
    capture(state);
    return state;
  }
}
final class LoadingState extends LiteScopeState<LoadingScope, LoadingState> {
  @override Future<void> initStateAsync() => params.gate;
  @override void onInitialized() { if (params.repair) setState(() {}); }
  @override Widget build(BuildContext context) {
    if (!isInitialized) return const Text('loading state');
    return const Text('ready state');
  }
}
```

### `probes/legacy_init.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:scopo/scopo.dart';
final class Dependencies implements ScopeDependencies {
  @override void onUnmount() {}
  @override void dispose() {}
}
Stream<ScopeInitState<Progress, Dependencies>> initialize() async* {
  final progressIterator = ProgressIterator(3);
  yield ScopeProgress(progressIterator.nextStep());
  yield ScopeProgress(progressIterator.nextStep());
  yield ScopeProgress(progressIterator.nextStep());
  yield ScopeReady(Dependencies());
}
final class LegacyScope extends Scope<LegacyScope, Dependencies, LegacyState> {
  @override Future<Dependencies> initDependencies(BuildContext context, ScopeInitContext ctx) => initialize();
  @override LegacyState createState() => LegacyState();
  @override Widget buildOnProgress(BuildContext context, Object? p) => const SizedBox();
  @override Widget buildOnError(BuildContext c, Object e, StackTrace s, Object? p) => const SizedBox();
}
final class LegacyState extends ScopeState<LegacyScope, Dependencies, LegacyState> {
  @override Widget build(BuildContext context) => const SizedBox();
}
```
