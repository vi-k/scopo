# Повторная приёмка перехода на async_job: исправления A–E

> **Состояние на 2026-09-09:** сделанное здесь вошло в `bc914c8` вместе с
> остальным переходом; примеры и документы доделаны там же. Три итоговые
> проверки зелёные, обе обязательные мутации пойманы.
> **Что это:** исправление оседания готовности, двух замечаний анализатора
> и комментария о разборе; результаты прогонов и проверки тестов мутациями.
> **Связанные записи:** `2026-09-09[1]-async-job-migration-design.md`.

## Воспроизведение и исправления

В исправленном окружении разрешён `async_job` 0.1.0 из pub-cache;
`.fvmrc` закрепляет Flutter 3.27.0. Отказов песочницы не было.
Команды запускались через `rtk proxy`, сохраняющий исходный вывод.

Исходный полный прогон закончился строкой
`00:09 +512 -2: Some tests failed.` Падали
`ScopeTimeout.none is refused by pauseAfterInitialization` и `(tearDownAll)`
в `test/scope_timeout_test.dart`. `_settleReady()` выбрасывал `AssertionError`
мимо `_settleFailure`; наблюдатель не получал событие инициализации.

В ветке `Done` продвижение значения и `_settleReady()` теперь находятся в
одном `try`; `on Object catch` передаёт ошибку и стек в `_settleFailure`.
Тест и весь `test/scope_timeout_test.dart` не менялись, что проверено
`git diff --exit-code -- test/scope_timeout_test.dart`.

Исходный анализатор завершился строкой `2 issues found.` Оба замечания
подтвердились: `library_private_types_in_public_api` и `cascade_invocations`.
`execute` теперь принимает публичный `JobContextBase`, как базовый класс;
внутри приводит его к `ScopeInitContext`, который реализует создаваемый
`createContext()` объект. Приватного типа в сигнатуре и новых `ignore` нет.
Два соседних вызова `ctx` в тесте оформлены каскадом.

В комментарии шага отмены (`_prepareForDisposal`, вызываемый разбором)
восстановлены причины продолжать разбор после ошибки и ограничивать ожидание:
иначе останутся регистрация у родителя и занятый `scopeKey`, за которым
следующий скоуп будет ждать запись, которую некому завершить. Отмена не
разбудит тело на чужом `future`; истечение позволяет завершить разбор,
но не обещает завершить чужую работу или освободить то, что держит её тело.
Явный выбор ожидания без лимита сохранён.

## Мутации

Перед мутациями исправленные файлы скопированы в `../out/backup/`, вне
дерева. После каждой мутации файл возвращён через `cp`, затем тот же тест
повторён. В конце все три файла побайтно сверены с исправленными копиями.

1. **Откат исправления A.** Тест
   `ScopeTimeout.none is refused by pauseAfterInitialization` упал:
   `Actual: WhereIterable<String>:[]` вместо события с
   `not accepted by pauseAfterInitialization`.
   Последняя строка: `00:01 +0 -2: Some tests failed.`
   После восстановления: `00:01 +1: All tests passed!`.
2. **C(1): удалён фильтр ошибки тела в `_ScopeInitObserver.onError`.**
   Тест `a body failure is reported to the scope observer exactly once`
   из `test/async_job_migration_test.dart` упал: ожидалась одна ошибка
   `StateError:Bad state: body failed`, фактически пришли две одинаковые.
   Последняя строка: `00:02 +0 -2: Some tests failed.`
   После восстановления: `00:02 +1: All tests passed!`.
3. **C(2): ветви помещены в общую задачу, отказ ветви отменяет её.**
   Тест `a concurrent branch failure reaches the scope error state`
   из `test/async_job_migration_test.dart` упал:
   `Expected: <Instance of 'AsyncScopeError'>`,
   `Actual: AsyncScopeProgress:<AsyncScopeProgress(first (1/2))>`.
   Последняя строка: `00:01 +0 -2: Some tests failed.`
   После восстановления: `00:01 +1: All tests passed!`.

Во всех трёх отрицательных прогонах вслед за проверкой свойства падал
`(tearDownAll)` на утечках. Основание засчитать мутации — указанное выше
падение проверки свойства, а не сопровождающий отказ проверки утечек.
Выживших мутаций нет. Оба теста миграции уже были в дереве на входе в эту
итерацию; их не пришлось менять.

## Итоговые команды и точные последние строки

Все три команды завершились с кодом 0:

```text
fvm flutter test
00:09 +513: All tests passed!

fvm dart analyze lib test
No issues found!

fvm dart format --set-exit-if-changed lib test
Formatted 115 files (0 changed) in 0.75 seconds.
```

Также прошёл `git diff --check`. Полные исходные выводы находятся вне дерева
в `../out/`: `baseline-test.log`, `mutation-a-test.log`,
`restored-a-test.log`, `mutation-c1-test.log`, `restored-c1-test.log`,
`mutation-c2-test.log`, `restored-c2-test.log`, `final-test.log`,
`final-analyze.log`, `final-format.log`.

Корневой `fvm flutter analyze`, проверки примеров и остальной гейт §6 в эту
приёмку не входят по уточнению постановщика задачи. Коммиты и запись в `.git`
не
выполнялись. Прежние незакоммиченные изменения миграции сохранены.
