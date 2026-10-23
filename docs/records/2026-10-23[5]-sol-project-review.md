# Полное ревью проекта: Sol, повторное

> **Состояние на 2026-10-23:** ревью принято, все зонды перезапущены
> и воспроизвелись (раздел «Приёмка» в конце). Все пять находок исправлены,
> правки R1–R6 сделаны Codex (`gpt-6.1-sol:high`, R5 — `gpt-6-astra:xhigh`)
> и приняты с поправками: R4 — `ee0c9b5`, `c7602d8`, `3fa21eb`; R2 —
> `2f31b62`; R3 — `9019a4a`; R5 — `47e72a4`; R1 и R6 — `aa9044e`. Вердикты —
> в конце каждой находки. Не сделан только последний балл общей оценки:
> независимая проверка потребления из конца «Пути до 10».
> **Что это:** повторное независимое полное ревью scopo на `21a791f`, после
> того как закрыты оба прежних. Сделано `gpt-6.1-sol` с усилием `xhigh` через
> `codex exec` по слову владельца: «повтори полное ревью только одним: Sol
> xhigh. обязательно пусть предложит правки, чтобы поднять оценку до 10».
> Оценки: код 9, документация 8, общая 8. Раздел «Путь до 10» — шесть правок
> R1–R6, после которых ревьюер обещает 10, 10 и 9. Пять находок: P0 и P1 нет,
> все пять P2.
> **Связанные записи:** `2026-10-23[2]-astra-project-review.md`
> и `2026-10-23[3]-sol-project-review.md` (прежние полные ревью, на `765ab0c`).

Ниже отчёт ревьюера дословно, менялись только переносы строк и заголовок H1
(у ревьюера — «Полное независимое ревью scopo — `21a791f`»). Ссылки
на `/Users/user/.claude/jobs/715c8327/tmp/review2/out-sol/` ведут во временный
каталог сессии и долго не проживут. Исходники зондов сохранены в «Приложении»
в конце записи. Имена `2026-10-23[5]-handoff-residue-log.md`
и `2026-10-23[6]-consumer-validation-plan.md` в R4 и после R6 — предложения
ревьюера; номер `[5]` занят этой записью.

## ПРОГОН

Все обязательные команды выполнены через `fvm`. После восстановления сессии
прогоны не повторял: результаты сверены с сохранёнными журналами. В таблице
приведены последние строки без терминальных управляющих символов и завершающих
пробелов.

| Команда | Последняя строка вывода |
| --- | --- |
| `fvm flutter test` | `00:11 +595: All tests passed!` |
| `fvm flutter analyze` | `No issues found! (ran in 4.1s)` |
| `(cd example/minimal && fvm flutter analyze)` | `No issues found! (ran in 1.1s)` |
| `(cd example/scopo_demo && fvm flutter analyze)` | `No issues found! (ran in 1.8s)` |
| `fvm dart format --set-exit-if-changed lib test` | `Formatted 119 files (0 changed) in 0.60 seconds.` |
| `fvm dart doc --dry-run` | `Found 0 warnings and 0 errors.` |
| `sh docs/ru/check.sh` | `переводы актуальны: 16` |
| `(cd example/scopo_demo && fvm flutter test)` | `00:15 +9: All tests passed!` |

Все восемь команд завершились с кодом `0`. Дополнительно выполнен
`fvm dart pub publish --dry-run`: последняя строка — `Package has 0 warnings.`,
код `0`. Размер сжатого архива — 290 КБ. Отказов песочницы не было.

Внешние проверки:

- Четыре характеризующих теста: три пропуска ошибок состояния наблюдателем
  и перекрытие владельцев после таймаута `scopeKey`. Последняя строка —
  `00:00 +4: All tests passed!`. Здесь успешный тест означает воспроизведение
  описанного поведения.
- `create: null` принят анализатором обоих владеющих конструкторов:
  `No issues found!`; виджет-тест воспроизвёл внутренний ассерт.
- Анализ фрагментов документации завершился с кодом `3`, последняя строка —
  `9 issues found.`: ошибки описаны ниже.
- Настоящим XML-парсером разобраны 11 IntelliJ-шаблонов; JSON содержит 11 VS
  Code-шаблонов.
- У всех 112 документов `docs/records/` обнаружена шапка текущего состояния.
  Это структурная проверка, не подтверждение содержания каждой записи.

[Сводка прогонов](/Users/user/.claude/jobs/715c8327/tmp/review2/out-sol/runs.jsonl),
[журнал основных зондов](/Users/user/.claude/jobs/715c8327/tmp/review2/out-sol/review-probe.log),
[зонд документации](/Users/user/.claude/jobs/715c8327/tmp/review2/out-sol/doc-contract-probe.log).

Финальный `git status --short` пуст; `git diff --exit-code` вернул `0`. HEAD
остался `21a791f14acbbee06066e1573b92008330a13673`. Файлы дерева не менял.

Прямое задание имело приоритет над требованием `AGENTS.md` поддерживать
`docs/handoff.md`: handoff и вердикты прежних ревью не обновлял. Все
исправления ниже — предложения. Разницу между версией `0.16.0` в `pubspec.yaml`
и разделом `0.17.0` считаю подготовкой выпуска согласно условию.

Проверены код, тесты, примеры, IDE-шаблоны, CI и публичная документация.
Историю использовал выборочно, включая оба сегодняшних ревью и их вердикты.
Нативные приложения и release-сборки не запускал, производительность
не измерял, серверные задания CI не перезапускал. Отдельного ревью
внутренностей `async_job` не проводил.

## Оценки

**Код — 9/10.** Механизм владения проработан существенно глубже обычной обёртки
над `InheritedWidget`: поздние результаты освобождаются, разбор продолжается
после ошибок, повторные вызовы объединяются, уведомления отделены
от перестройки собственного поддерева. Тесты проверяют наблюдаемое поведение
и трудные пути жизненного цикла. Подтверждённых P0/P1 не нашёл; оставшиеся
замечания к коду касаются наблюдаемости состояния и допуска заведомо неверного
`create`.

**Документация — 8/10.** Темы подробно объясняют порядок работы, передачу
владения и ловушки; русские зеркала поддерживаются вместе с оригиналами. Однако
сильные обещания README требуют оговорок о таймаутах, один опубликованный
Dart-фрагмент синтаксически неверен, а обязательный документ восстановления всё
ещё смешивает действующее устройство с историей. Путь к первому самостоятельно
работающему приложению также длиннее необходимого.

**Общая — 8/10.** Проект решает настоящую, достаточно узкую задачу и имеет
убедительную инженерную основу. Его преимущество проявляется при асинхронном
владении ресурсами, а стоимость освоения платится уже при простых сценариях.
Единственный известный пользователь — автор: пока недостаточно свидетельств,
что другой разработчик сможет получить ту же пользу без его сопровождения.

## ПУТЬ ДО 10

Пункты расположены по ожидаемой отдаче на единицу работы. Баллы относятся
к указанной шкале: код и документация между собой не складываются.

### R1. Исправить конкретные ошибки темы `AsyncDataScope`

**Что поменять.** В `doc/async_data_scope.md`, разделе
`The value in each place`, заменить содержимое блока Dart на настоящее
выражение возврата:

```dart
return await Database.open();
```

В следующем объяснении прогресса написать, что `ctx.progress` принимает
`Object`, а билдеры получают `Object?`: отсутствие первого сообщения относится
к состоянию скоупа. Исправить соответствующие места
`docs/ru/doc/async_data_scope.md`.

**Баллы:** +0,5 к документации. Устраняет опубликованный нерабочий фрагмент
и неверное описание сигнатуры.

**Цена:** до часа, без изменения API.

**Проверка:** извлечённый исправленный фрагмент с минимальным определением
`Database` должен анализироваться без ошибок; `ctx.progress(null)` должен
по-прежнему давать `argument_type_not_assignable`. После содержательной правки
перевода — `stamp.sh` и `check.sh`.

### R2. Закрыть nullable-фабрику типом конструктора

**Что поменять.** У владеющих конструкторов `ScopeModelBase`
в `lib/src/scope/scope_model/scope_model_base.dart` и `ScopeNotifierBase`
в `lib/src/scope/scope_notifier/scope_notifier_base.dart` сделать параметр
`create` обязательной **ненулевой** функцией `M Function(BuildContext)`. Само
поле может оставаться nullable для конструктора `.value`. Проверить наследующие
конструкторы `ScopeModel` и `ScopeNotifier`.

**Баллы:** +0,5 к коду. Ошибка, которую компилятор способен запретить,
перестанет доходить до построения дерева.

**Цена:** небольшая правка, менее часа. Формально сужает публичный API; ломает
вызовы, передающие nullable-фабрику, включая уже неработающий `create: null`.

**Проверка:** нынешний внешний зонд должен перестать компилироваться
с `argument_type_not_assignable`; обычный и `.value`-конструкторы должны
сохранить поведение. Затем корневые тесты и анализатор.

### R3. Ограничить обещания о порядке освобождения тем, что пакет обеспечивает

**Что поменять.** В README, разделах `Why another one`, `Features`
и `scopeKey`, рядом с обещанием сериализации прямо написать:

> Ожидания по умолчанию ограничены тремя секундами. По истечении лимита скоуп продолжает работу; старый владелец или ребёнок может ещё освобождать ресурсы.

Добавить ссылку на политику таймаутов и рецепт ожидания без лимитов через
четыре `ScopeConfig.default… = null`. Объяснить цену такого режима: зависшая
операция может остановить дальнейший разбор. Аналогичную оговорку поставить
в разделе `scopeKey` темы `doc/async_scope.md` и обновить зеркала.

**Баллы:** +0,5 к документации и +0,5 к общей оценке. Это уточняет центральное
обещание пакета в месте, где принимают решение о его использовании.

**Цена:** несколько часов, без изменения API и нынешней политики таймаутов.

**Проверка:** в `test/async_scope_coordinator_test.dart` закрепить пару
сценариев: ограниченное ожидание допускает нового владельца до окончания
старого разбора; ожидание без лимита удерживает его до завершения. Внешний зонд
уже воспроизводит первый сценарий.

### R4. Завершить отделение текущего состояния от истории

**Что поменять.** Сократить `docs/handoff.md` примерно до 150–200 строк:
текущая версия, незавершённая работа, действующие ограничения, последний
прогон, ссылки. Остаточные разборы перенести в новую запись
`docs/records/2026-10-23[5]-handoff-residue-log.md`.

Из живого текста убрать утверждения о существующих `_mergeStreams`,
`_ScopeDependencyConcurrent._guarded`, `asStream` и чтении `_initSucceeded`
контроллерным элементом. Уточнить остаток прежних находок в вердиктах:

- `docs/records/2026-10-23[2]-astra-project-review.md`, находка 10;
- `docs/records/2026-10-23[3]-sol-project-review.md`, находка 5.

В `AGENTS.md` достаточно короткой оговорки о режиме ревью без изменения дерева:
обязательное поддержание состояния к нему не относится.

**Баллы:** +0,5 к документации. Убирает необходимость заново устанавливать,
какие обязательные инструкции ещё соответствуют коду.

**Цена:** около половины рабочего дня, без изменения API.

**Проверка:** поиск удалённых идентификаторов в текущем handoff не должен
давать результатов; каждый оставленный механизм должен находиться в коде. Новая
архивная запись должна сохранить перенесённый текст и иметь требуемую шапку.

### R5. Довести наблюдение до собственных хуков состояния

**Что поменять.** В `LiteScopeCoreState._performAsyncInit` и `_completeInit`
файла `lib/src/scope/lite_scope/lite_scope_core.dart` отправлять ошибки
`initStateAsync` и `onInitialized` в `ScopeObserver.onError`, сохраняя нынешний
путь исключения в зону или Flutter.

Для `ScopeState.build` и `LiteScopeState.build` можно добавить внутренний
`StatefulElement`, оборачивающий `super.build()` отчётом и повторным броском.
Публичное переименование `build` для этого не требуется. Отдельно обозначить
границы наблюдения за обычными Flutter-хуками.

**Баллы:** +0,5 к коду. Устраняет подтверждённый пробел в едином канале
диагностики.

**Цена:** примерно рабочий день с тестами, без обязательного изменения
публичного API.

**Проверка:** в `test/scope_observer_test.dart` добавить синхронный
и асинхронный отказ инициализации состояния, отказ `onInitialized` и отказ
`build` для обеих семей. Ожидать ровно одно событие с исходным объектом ошибки;
сохранить прежний Flutter/zone-канал и выполнение утилизации. Текущий внешний
зонд показывает ноль таких событий.

### R6. Дать короткий исполняемый вход в основную ценность пакета

**Что поменять.** Добавить `example/quickstart/lib/main.dart`: один экран
на `AsyncDataScope`, локальный ресурс без плагинов, загрузка, готовность,
повторное создание и наблюдаемое освобождение. Цель — примерно 60–90 строк
вместе с `main()`, определением ресурса и `MaterialApp`. Ссылку поставить
до каталога восьми семейств README. Нынешний `example/minimal` сохранить как
разбор полного `Scope`.

Добавить `example/quickstart/test/lifecycle_test.dart`, русское зеркало README
примера и его прогон в `.github/workflows/ci.yml`. Для копируемых фрагментов
завести `tool/check_doc_examples.dart`, извлекающий код непосредственно
из документации и проверяющий его с явно заданным окружением. Отрицательные
примеры должны проверяться на ожидаемый отказ.

**Баллы:** +0,5 к документации и +0,5 к общей оценке. Сокращает путь до первого
результата и проверяет примеры сильнее поиска отдельных старых имён.

**Цена:** один-два рабочих дня, без изменения API.

**Проверка:** тест примера должен показывать загрузку, готовность
и освобождение старого ресурса перед новым захватом. Проверка документации
должна обнаруживать нынешний дефект R1 при его возвращении.

**После R1–R6 получаются код 10, документация 10 и общая 9.** Последний балл
общей оценки сейчас нельзя обосновать одними локальными правками.

Для него нужна независимая проверка потребления: хотя бы две интеграции без
участия автора в написании каждого скоупа — например, ресурс с медленным
освобождением и авторизованная сессия с дочерними экранами. В плане
`docs/records/2026-10-23[6]-consumer-validation-plan.md` следует задать
сценарии, а в README затем привести проверенные результаты. Цена — недели
и участие других разработчиков; необходимость изменений API заранее неизвестна.
Проверка — воспроизводимые проекты, их тесты, снятие экрана во время
инициализации и повторный вход во время разбора. Число звёзд или скачиваний
этого свидетельства не заменяет.

## Удобство для человека

Таблица выбора семейства полезна: она начинает с того, чем владеет приложение.
Имена `ScopeModel`, `ScopeNotifier` и `AsyncDataScope` достаточно предсказуемы.
Хорошо объяснено различие между `notifyDependents()` и `setState()`: это важная
особенность, которую нельзя оставлять на догадку.

Первый рабочий экран всё же требует самостоятельной сборки контекста вокруг
фрагментов. README занимает 889 строк; пример `minimal` — 245 строк
и показывает самое крупное семейство с контейнером, состоянием и несколькими
ветками `MaterialApp`. Автор честно объясняет такое значение слова «minimal»,
но человеку, выбирающему пакет, нужен более короткий исполняемый вход — R6.

Сложность восьми семейств дополнительно умножается уровнями готового виджета,
`Base`, `Core`, контекстами, статическими аксессорами и объектами `Access`. Для
обычного приложения большую часть этого можно не знать, однако документация
показывает устройство довольно рано. Я бы сохранил все возможности, но развёл
маршруты «использовать семейство» и «написать собственный элемент».

Диагностика большинства ошибок хорошая: запрет подписки вне сборки объясняет
причину и следующий шаг, ошибки `scopeKey` называют нарушенное владение,
отсутствие состояния отличается от отсутствия скоупа. Nullable-фабрика
из находки ниже остаётся заметным исключением.

## Удобство для агентов

**Агент, пишущий приложение на scopo.** Для типовых случаев README, темы
и примеры уже позволяют писать код без чтения исходников. Особенно полезны
объяснения частичной инициализации, `abandonable(discard:)`, передачи владения
через `disown` и различия `controllerDep` с самостоятельным контроллерным
скоупом.

Главные риски — механическое копирование непроверенного фрагмента и перенос
привычек Flutter на другой контракт. Подписка только из сборки, `params` вместо
`widget`, две разные инициализации и два способа уведомления требуют явного
внимания. Сейчас нужные объяснения существуют, но распределены по нескольким
длинным страницам. R1, R3 и R6 уменьшают вероятность правдоподобного,
но неверного кода.

**Агент, работающий в репозитории.** `AGENTS.md` задаёт полезные границы:
закреплённый SDK, запрет смешивать чужие изменения, конкретный гейт, синхронное
обновление переводов и вердикты непосредственно у находок. Свежая архитектурная
карта помогает проследить путь от публичного семейства к элементу.

Восстановление контекста пока слишком дорого: обязательный `docs/handoff.md`
содержит 1126 строк, включая устаревшие сведения о коде. Наличие вердиктов
не помогает, когда текущий снимок продолжает утверждать прежнее. Это остаток
прежней проблемы, а не причина отменять сам подход с handoff; исправление — R4.

Исторические записи организованы последовательно: полные имена, жанр, шапки
состояния и вердикты делают их пригодными для выборочного чтения. Сохранять
этот порядок стоит; читать всю историю при каждом старте не нужно.

## Нужен ли проект

**Да, как специализированный инструмент асинхронного владения ресурсами
в дереве Flutter.** Для простого распространения модели его цена не окупается.

| Альтернатива | Где она закрывает задачу лучше или уже достаточно |
| --- | --- |
| `provider` | Создание, предоставление и освобождение обычных объектов, наблюдение за моделями, выборочные перестройки. Для синхронного `ChangeNotifier` переход на scopo обычно не даёт соразмерной пользы. [Документация provider](https://pub.dev/packages/provider). |
| `riverpod` | Асинхронное состояние и жизненный цикл по использованию провайдера. Существенная граница сравнения: `Ref.onDispose` принимает `void`-колбэк; ожидание асинхронного освобождения перед освобождением владельца через этот хук не выражается. [API Ref.onDispose](https://pub.dev/documentation/riverpod/latest/riverpod/Ref/onDispose.html). |
| `flutter_bloc` | Организация событий и состояний, предоставление BLoC и репозиториев, их освобождение. scopo может владеть такими объектами, но не заменяет их модель бизнес-логики. [Документация flutter_bloc](https://pub.dev/packages/flutter_bloc). |
| `get_it` / `injectable` | Асинхронная регистрация, зависимости и области владения уже существуют. `get_it` ждёт `popScope` и освобождает объекты в обратном порядке регистрации; `injectable` автоматизирует регистрацию и предварительное ожидание. [Области get_it](https://flutter-it.dev/documentation/get_it/scopes), [асинхронные регистрации injectable](https://pub.dev/packages/injectable). |

Называть одной уникальной особенностью привязку области к виджету недостаточно:
документация `get_it` уже указывает на `watch_it.pushScope` для времени жизни
виджета. Преимущество scopo я вижу в сочетании механизмов: владение следует
поддереву, родитель ждёт дочерние скоупы, последовательные владельцы
координируются ключом, незавершённая инициализация освобождает приобретённое,
а `close()` предоставляет видимый процесс закрытия. Это моё сопоставление
контрактов, а не результат сравнительного нагрузочного теста.

Пакет уместен для плеера, устройства, соединения, сессии или другого ресурса,
который долго открывается и закрывается и используется вложенными экранами. Для
счётчиков, обычных форм, одного HTTP-запроса или уже работающей архитектуры
BLoC/Provider отдельный механизм scopo часто будет лишним.

Препятствия принятию — объём собственной терминологии, повторяемый код
именованных скоупов, необходимость понять передачу владения и ограниченность
гарантий таймаутами. Единственный пользователь-автор оправдывает существование
инструмента для него самого. Для рекомендации другим пока не хватает
независимого опыта применения.

## Находки по убыванию практического риска

Подтверждённых **P0 и P1 нет**. Все находки ниже — P2; это не утверждение
об отсутствии других дефектов.

### 1. P2 — обещание сериализации недостаточно явно ограничено таймаутами

**Координаты:** `README.md`, разделы `Why another one`, `Features`, `scopeKey`;
`doc/async_scope.md`, раздел `scopeKey and the coordinator`;
`KeyedAccessQueues` и `_AccessQueue.enter`
в `lib/src/scope/async_scope/scope_coordination.dart`.

README обещает, что новый скоуп ждёт окончания освобождения предыдущего, и что
родитель не освобождает зависимости, пока они используются ниже. Фактически
`_AccessQueue.enter` ловит `TimeoutException`, вызывает уведомление
и возвращается нормально. Другие этапы разбора тоже могут закончить ожидание
раньше освобождения ресурсов. Умолчания — три секунды.

Подробные параметры описывают продолжение после таймаута, поэтому я не считаю
саму политику дефектом реализации. Проблема — сила главного обещания
и отсутствие рядом прямого объяснения, что возможны два одновременно
действующих владельца.

Зонд удерживал старый `disposeData` незавершённым и давал новому владельцу 20
мс ожидания:

```text
KEY: overlaps=true expiries=1 oldStillOwns=true newReady=1
```

Новый скоуп достиг готовности, пока старый ещё владел ресурсом. **Исправление —
R3.**
[Исходник зонда](/Users/user/.claude/jobs/715c8327/tmp/review2/out-sol/probes/test/review_probe_test.dart).

**Вердикт: исправлено.** `9019a4a`, правка R3. README в разделах
`Why another one`, `Features` и `scopeKey` и тема `doc/async_scope.md`
в разделе `scopeKey` теперь говорят, что ожидания по умолчанию ограничены тремя
секундами и после лимита старый владелец ещё может освобождать ресурсы;
в README — рецепт из четырёх `ScopeConfig.default… = null` и его цена. Политика
таймаутов не менялась. В `test/async_scope_coordinator_test.dart` два теста
закрепляют оба сценария; мутация `_AccessQueue.enter`, отключающая лимит, валит
ограниченный. Поверх версии Codex поправлено: относительные ссылки заменены
ссылкой на тему `debug` на pub.dev и названиями разделов, в зеркалах «3 с»
стало словами, одна фраза перевода переписана по `ERROR` линтера.

### 2. P2 — наблюдатель не охватывает собственный слой состояния

**Координаты:** `LiteScopeCoreState._performAsyncInit`, `_completeInit`
и `_LiteScopeCoreWidget` в `lib/src/scope/lite_scope/lite_scope_core.dart`;
наследующие `ScopeState` и `LiteScopeState`; `doc/debug.md`, раздел
`onError and ScopePhase`.

Ошибки `initStateAsync` и `onInitialized` повторно бросаются без
`notifyObserver`. `build` состояния вызывается обычным `StatefulElement`, вне
охраны `ScopeWidgetElementBase.build`. Поэтому наблюдатель, подключённый
по примеру `CrashReporter`, не слышит эти ошибки, хотя README обещает
наблюдаемый жизненный цикл с ошибками, а тема debug говорит о единой точке
построения семейств.

Зонд отдельно вызвал три отказа:

```text
STATE init: observer=[], zone=[Bad state: state-init], flutter=null, disposed=true
STATE build: observer=[], zone=[], flutter=Bad state: state-build, disposed=true
STATE initialized: observer=[], zone=[Bad state: state-initialized], flutter=null, disposed=true
```

Исключения не исчезают вообще: их получает зона или Flutter. Утилизация
в проверенных сценариях выполняется. Пропуск относится именно к каналу
`ScopeObserver`; он не затрагивает уже охваченные `initScope` и `buildOn*`.
**Исправление — R5.**

**Вердикт: исправлено.** `47e72a4`, правка R5. Новый приватный
`_LiteScopeCoreElement` сообщает об отказе `build` состояния
с `ScopePhase.build` и бросает ошибку дальше; `_performAsyncInit` сообщает
об отказе `initStateAsync`, `_completeInit` — об отказе `onInitialized`, оба
с `ScopePhase.initialization`. Зона и Flutter получают ошибки как прежде,
утилизация идёт. Двенадцать тестов в `test/scope_observer_test.dart` ждут ровно
одно событие с исходной ошибкой для обеих семей; мутация, глушащая отчёт
`build`, даёт два падения. `doc/debug.md` и зеркало называют хуки Flutter,
которых наблюдатель не слышит. Попутно Codex нашёл дефект вне находки:
диагностическая печать отжившего элемента бросает `TypeError`; он записан
в `docs/handoff.md` открытым, не исправлен.

### 3. P2 — восстановление контекста всё ещё содержит инструкции о прежнем коде

**По чтению. Координаты:** `docs/handoff.md`, разделы
`Грабли, на которые не стоит наступать второй раз`,
`Решения, которые стоит помнить`, `Открыто, вне списка ревью`,
`Тулчейн и окружение`.

В текущем снимке остаются утверждения:

- обход конкурентной группы исправляется через
  `_ScopeDependencyConcurrent._guarded` и `_mergeStreams`;
- `asStream` принимает один аргумент типа;
- `AsyncControllerScopeElementBase` читает `_initSucceeded` соседнего слоя;
- зависимость наследуется под диапазоном `^0.1.0`.

Первые три идентификатора отсутствуют в исполняемом коде; `_initSucceeded`
в контроллерном файле встречается только в историческом комментарии «used to be
asked». В `pubspec.yaml` стоит `async_job: ^0.3.0`.

Самостоятельная историческая запись вправе описывать прежнее устройство. Здесь
сведения находятся в обязательном текущем контексте и частично оформлены как
действующие границы или решения. Агент должен опровергать их исходниками перед
работой.

Это остаток проблемы из **`docs/records/2026-10-23[2]-astra-project-review.md`,
находка 10, вердикт**, и **`docs/records/2026-10-23[3]-sol-project-review.md`,
находка 5, вердикт**. Названные там конкретные противоречия исправлены,
архитектурная карта переписана; считать очистку всего текущего контекста
завершённой пока рано. **Исправление — R4.**

**Вердикт: исправлено, с уточнением к находке.** `ee0c9b5`, `c7602d8`,
`3fa21eb`, правка R4. `docs/handoff.md` сокращён до двухсот строк, законченное
вынесено дословно — `check_move.py` без проблем. Запись названа
`2026-10-23[6]-handoff-archive.md`, а не предложенным
`2026-10-23[5]-handoff-residue-log.md`: номер `[5]` в тот день уже занят этим
ревью, а вид `archive` — тот, которым проект называет такие выносы. Поиск
`_mergeStreams`, `_guarded`, `asStream`, `^0.1.0` и `_initSucceeded` в handoff
пуст. В `2026-10-23[2]-astra-project-review.md`, находка 10,
и в `2026-10-23[3]-sol-project-review.md`, находка 5, вердикты дополнены
уточнением, в `AGENTS.md` §2 — оговорка о сессии ревью без правок.

### 4. P2 — опубликованная тема содержит не-Dart внутри блока Dart и неверную nullable-сигнатуру

**Координаты:** `doc/async_data_scope.md`, раздел `The value in each place`;
`docs/ru/doc/async_data_scope.md`, соответствующий раздел;
`ScopeInitContext.progress`
в `lib/src/scope/async_scope/scope_init_context.dart`.

В блоке с языком `dart` записано:

```text
returning `await Database.open()`
```

Это проза с Markdown-разметкой. Русское зеркало воспроизводит её как
`возврат ...`. Там же утверждается, что `ctx.progress` принимает `Object?`,
хотя сигнатура — `void progress(Object progress)`.

Внешний анализаторный зонд показал `Undefined name 'returning'`, синтаксические
ошибки и отдельно:

```text
The argument type 'Null' can't be assigned to the parameter type 'Object'.
```

Последняя строка — `9 issues found.`, код `3`. `dart doc --dry-run` и проверка
blob-хешей этого не обнаруживают: они не проверяют исполнимость примеров
и истинность описания сигнатуры. **Исправление содержания — R1; защита
от повторения — R6.**
[Зонд](/Users/user/.claude/jobs/715c8327/tmp/review2/out-sol/probes/doc_contract_probe.dart).

**Вердикт: исправлено.** `aa9044e`, правки R1 и R6. Блок в теме и в зеркале —
`return await Database.open();`, текст говорит, что `ctx.progress` принимает
`Object`, а билдеры получают `Object?`. Защита от повторения —
`tool/check_doc_examples.dart` в CI и в гейте §6: он вырезает блоки Dart
из документа, собирает их против дерева и ждёт `argument_type_not_assignable`
у отрицательного примера `ctx.progress(null)`; мутация в блоке валит его. Охват
пока одна тема, `doc/async_data_scope.md`: остальные `doc/` и README стендом
не покрыты. В версии Codex стенд на macOS не работал вовсе — анализатор
называет файлы по пути без симлинков, и диагностика `/private/tmp/…`
не находила свой блок; исправлено разрешением пути временного каталога. Вход
R6 — `example/quickstart`, 77 строк `main.dart`, тест порядка освобождения
и захвата, зеркало README; README ведёт к нему до раздела о семьях. В его
README `flutter create` получил `--empty`: без него команда добавляет
образцовый тест, который с примером не собирается.

### 5. P2 — владеющие конструкторы принимают `create: null`

**Координаты:** `ScopeModelBase.ScopeModelBase`,
`ScopeNotifierBase.ScopeNotifierBase`; `_ScopeModelElementMixin.init`
в `lib/src/scope/scope_model/base.dart`.

Nullable-поле фабрики нужно для `.value`, но его nullable-тип перенесён
и в параметр владеющего конструктора. Поэтому оба вызова с `create: null`
проходят анализатор. При построении они падают на внутреннем ассерте:

```text
'widget.create != null': is not true.
```

Это неправильное использование со стороны потребителя, поэтому тяжесть P2.
Однако публичная сигнатура разрешает его, хотя компилятор способен сразу
запретить такую комбинацию. Для `.value` аналогичная проблема уже решена
сужением параметра `value`.

`fvm dart analyze test/misuse_probe_test.dart` вывел `No issues found!`;
внешний виджет-тест воспроизвёл ассерт для обеих семей. Release-путь
не запускал. **Исправление — R2.**
[Зонд](/Users/user/.claude/jobs/715c8327/tmp/review2/out-sol/probes/test/misuse_probe_test.dart).

**Вердикт: исправлено.** `2f31b62`, правка R2. Владеющие конструкторы
`ScopeModelBase` и `ScopeNotifierBase` принимают
`required M Function(BuildContext context) this.create`, поле осталось nullable
для `.value`. Зонд находки на прежнем коде даёт `No issues found!`, на новом —
два `argument_type_not_assignable`. В `test/scope_notifier_test.dart` два
теста, в CHANGELOG — строка **Breaking:**.

## Что в проекте сделано хорошо и что стоит сохранить

Модель владения последовательна: успешно переданный ресурс, частично
приобретённый ресурс и поздний результат отменённой инициализации имеют разные,
явно описанные пути освобождения. Это основная ценность проекта; её не стоит
размывать новыми семействами без потребительского сценария.

Разбор защищает следующие обязательные этапы от отказа предыдущего. Объединение
повторных вызовов, отдельное ожидание состояния и зависимостей, сохранение
виджета для позднего освобождения и защита наблюдателя показывают внимание
к реальным последствиям ошибок.

Тесты сильны проверками порядка, отмены, позднего освобождения, уведомлений
и частичной утилизации. Они используют `Completer` и наблюдаемые события;
leak-трекер включён для сьюты. Это полезнее самого числа 595. Найденные пробелы
не обесценивают существующее покрытие.

CI проверяет заявленный нижний SDK, примеры, документацию, переводы и чистоту
дерева. Отдельная допускающая отказ проверка свежего stable разумно отделяет
обещанную совместимость от раннего сигнала.

Публичные темы объясняют причины ограничений, а не только перечисляют методы.
Зеркала сохраняют структуру и код оригиналов; выборочная сверка Dart-блоков
не выявила самостоятельного расхождения API между языками. Ошибки темы
`AsyncDataScope` повторены в обоих языках, что как раз отличает синхронность
перевода от правильности содержания.

IDE-шаблоны действительно сопровождаются проверяемыми развёртками. Исторические
записи с состоянием и вердиктом у самой находки также стоит сохранить;
сократить нужно обязательный текущий контекст.

## Итог

scopo нужен для асинхронного владения ресурсами, следующего за поддеревом
Flutter. На `21a791f` обязательные проверки проходят: 595 тестов пакета и 9
тестов демо. Подтверждённых P0/P1 нет; найдены пять P2 в наблюдаемости,
сигнатурах и документации. Главное уточнение перед рекомендацией другим —
границы гарантий при таймаутах. Код оцениваю на 9/10, документацию на 8/10,
проект в целом на 8/10. Дерево осталось чистым; все предложенные изменения
требуют отдельной реализации.

## Приёмка

Прогон шёл в два хода. Первый, `run.sh` под `SCHEMA=-`, оборвался через 488
с на стороне сервера — `ERROR: Selected model is at capacity` — с пустым
отчётом. Второй продолжил ту же сессию (`01a16788-127a-71c0-980d-d6bff2c17760`)
через `codex exec … resume` с теми же моделью и усилием и сдал отчёт за 1060 с.
Шапки обоих `.err` — `model: gpt-6.1-sol`, `reasoning effort: xhigh`.

Клон после ревью: `git log --oneline -1` — `21a791f`, `git status --short`
пуст. Прогоны гейта ревьюер вёл сам; их числа совпадают с моим гейтом на том же
коде (595 тестов, демо 9).

Зонды перезапущены мной на его стенде, `out-sol/probes`:

- `fvm flutter test test/review_probe_test.dart` — `+4: All tests passed!`,
  и строки зонда те же, что в отчёте: три `STATE … observer=[]`
  и `KEY: overlaps=true expiries=1 oldStillOwns=true newReady=1`. Находки 1 и 2
  подтверждены.
- `fvm flutter test test/misuse_probe_test.dart` — `+1: All tests passed!`, обе
  строки `'widget.create != null': is not true.`;
  `fvm dart analyze test/misuse_probe_test.dart` — `No issues found!`. Находка
  5 подтверждена.
- `fvm dart analyze doc_contract_probe.dart` — `9 issues found.`, среди них
  `Undefined name 'returning'` и
  `The argument type 'Null' can't be assigned to the parameter type 'Object'.`.
  Находка 4 подтверждена и по тексту: `doc/async_data_scope.md`, раздел
  `The value in each place`, — в блоке `dart` стоит ``returning `await
  Database.open()` ``, а абзац ниже говорит, что `ctx.progress` принимает `Object?`.
- Находка 3, по чтению, подтверждена поиском по `docs/handoff.md`: живой текст
  называет `_mergeStreams`, `_ScopeDependencyConcurrent._guarded`, `asStream`
  и диапазон `^0.1.0`, а в «Открыто, вне списка ревью» и в пункте 5 «С чего
  начать» стоит граница «`AsyncControllerScopeElementBase` читает приватное
  `_initSucceeded`», хотя в `lib/src/scope/async_controller_scope/` это имя
  осталось только в историческом комментарии («used to be asked»).

## Приложение: исходники зондов

### `probes/test/review_probe_test.dart`

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

final class Recorder extends ScopeObserver {
  final errors = <Object>[];
  final phases = <ScopePhase>[];

  @override
  void onError(ScopeObservable target, ScopePhase phase, Object error,
      StackTrace? stackTrace) {
    errors.add(error);
    phases.add(phase);
  }
}

final class StateProbe extends LiteScope<StateProbe, ProbeState> {
  final String failure;
  final void Function(ProbeState) capture;

  const StateProbe({required this.failure, required this.capture});

  @override
  Widget? buildOnWaiting(BuildContext context) => const SizedBox.shrink();

  @override
  ProbeState createState() {
    final state = ProbeState();
    capture(state);
    return state;
  }
}

final class ProbeState extends LiteScopeState<StateProbe, ProbeState> {
  bool disposed = false;

  @override
  Future<void> initStateAsync() async {
    if (params.failure == 'init') throw StateError('state-init');
  }

  @override
  void onInitialized() {
    if (params.failure == 'initialized') throw StateError('state-initialized');
  }

  @override
  Future<void> disposeStateAsync() async => disposed = true;

  @override
  Widget build(BuildContext context) {
    if (params.failure == 'build') throw StateError('state-build');
    return const SizedBox.shrink();
  }
}

Widget wrap(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );

Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
}

void main() {
  tearDown(() {
    ScopeConfig.reset();
    ScopeConfig.observer = null;
  });

  for (final failure in ['init', 'build', 'initialized']) {
    testWidgets('observer coverage: state $failure', (tester) async {
      final recorder = Recorder();
      ScopeConfig.observer = recorder;
      final zoneErrors = <Object>[];
      final finished = Completer<void>();
      ProbeState? state;
      Object? flutterError;
      unawaited(runZonedGuarded(() async {
        try {
          await tester.pumpWidget(wrap(StateProbe(
            failure: failure,
            capture: (value) => state = value,
          )));
          await frames(tester);
          flutterError = tester.takeException();
          await tester.pumpWidget(wrap(const SizedBox.shrink()));
          await frames(tester);
        } finally {
          finished.complete();
        }
      }, (error, stack) => zoneErrors.add(error)));
      await finished.future;
      print('STATE $failure: observer=${recorder.errors}, '
          'zone=$zoneErrors, flutter=$flutterError, disposed=${state?.disposed}');
      expect(state?.disposed, isTrue);
      expect(recorder.errors, isEmpty);
      expect([...zoneErrors, if (flutterError != null) flutterError], hasLength(1));
    });
  }

  testWidgets('scopeKey timeout admits a new live resource owner', (tester) async {
    ScopeConfig.timeoutReportsEnabled = false;
    ScopeConfig.defaultDisposeScopeTimeout = null;
    final released = Completer<void>();
    var oldStillOwns = true;
    var overlapped = false;
    var expiries = 0;

    Widget holder(bool old) => wrap(AsyncScopeCoordinator(
          child: AsyncDataScope<int>(
            key: ValueKey(old),
            scopeKey: 'resource',
            scopeKeyTimeout: const Duration(milliseconds: 20),
            onScopeKeyTimeout: () => expiries++,
            initData: (context, ctx) async {
              if (!old) overlapped = oldStillOwns;
              return old ? 1 : 2;
            },
            disposeData: (data) async {
              if (data == 1) {
                await released.future;
                oldStillOwns = false;
              }
            },
            progressBuilder: (context, progress) => const SizedBox.shrink(),
            errorBuilder: (context, error, stack, progress) => const SizedBox.shrink(),
            builder: (context, data) => Text('owner=$data'),
          ),
        ));

    await tester.pumpWidget(holder(true));
    await frames(tester);
    await tester.pumpWidget(holder(false));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await frames(tester);
    print('KEY: overlaps=$overlapped expiries=$expiries '
        'oldStillOwns=$oldStillOwns newReady=${find.text('owner=2').evaluate().length}');
    expect(overlapped, isTrue);
    expect(expiries, 1);
    released.complete();
    await frames(tester);
    await tester.pumpWidget(wrap(const SizedBox.shrink()));
    await frames(tester);
  });
}
```

### `probes/test/misuse_probe_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

void main() {
  testWidgets('null factory is accepted by both owning constructors', (tester) async {
    for (final widget in <Widget>[
      ScopeModel<Object>(
        create: null,
        dispose: null,
        builder: (context) => const SizedBox.shrink(),
      ),
      ScopeNotifier<ValueNotifier<int>>(
        create: null,
        dispose: (model) => model.dispose(),
        builder: (context) => const SizedBox.shrink(),
      ),
    ]) {
      await tester.pumpWidget(widget);
      final error = tester.takeException();
      print('NULL CREATE ${widget.runtimeType}: $error');
      expect(error, isA<AssertionError>());
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
```

### `probes/doc_contract_probe.dart`

```dart
import 'package:scopo/scopo.dart';

void nullableProgress(ScopeInitContext ctx) {
  ctx.progress(null);
}

Future<Object> valueExcerpt() async {
  returning `await Database.open()`
}

abstract final class Database {
  static Future<Object> open() async => Object();
}
```
