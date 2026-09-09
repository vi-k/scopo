# Ревью волны правок — второй проход, `codex`

> **Состояние на 2026-09-09:** проведено, находки не закрыты — ни одна.
> **Что это:** независимый проход по диапазону `97086de..def3901` — волне
> правок по находкам ревью того же дня. Исполнитель — `codex` в изолированном
> клоне, с прогонами: база 525 тестов, `analyze` в трёх точках, форматтер,
> 14 обратных мутаций по всем 12 новым тестам и собственная матрица на 45
> проверок. Три находки Medium, одна Low, одна Info; M2 я воспроизвёл своим
> зондом и мутацией, M1 — своим зондом на другой форме входа.
> **Связанные записи:** `2026-09-09[5]-post-wave-review.md` (мой проход, там
> же сведение, сходимость и вердикты), `2026-09-09[3]-bug-hunter-review.md` и
> `2026-09-09[4]-bug-hunter-review.md` (ревью, чью волну здесь проверяют).

> **Логи, на которые ссылается текст, не сохранились:** они лежали в песочнице
> сессии (`baseline.log`, `mut01`–`mut14`, `probe_failures_test.dart`,
> `mutation-manifest.json` и прочие) и с её концом исчезли. Ссылки оставлены
> как отданы. Числа из них перепроверены моим прогоном — см. `[5]`.

Текст ниже — его, как отдан, правок в нём нет.

---

## ПРОГОН

**Выполнял ли команды: да.** Проверен диапазон `97086de..def3901`; `HEAD` остался `def3901`. Работал один, без субагентов. Отчёт — независимая проверка правок и тестов, а не повторное полное ревью пакета.

Исходный и финальный `git status --short` пусты. Клон не изменял. Исходники для мутаций, копии тестов и package_config размещены в `codex-out/stand`; `scopo` в этом package_config указывает на копию. Зависимости остаются теми же, из уже подготовленного кеша. `pub get` повторно не запускал. После каждого опыта копия изменённого файла возвращалась из сохранённого HEAD; после всех мутаций восстановлены также исходные тесты.

Начал с двух заданных команд:

| Команда | Точная последняя строка |
| --- | --- |
| `git log --oneline 97086de..HEAD` | `e9405a3 docs: the review says the kernel migration brought back a defect that was closed` |
| `git diff --stat 97086de..HEAD` | ` 26 files changed, 2171 insertions(+), 118 deletions(-)` |

Прочитал обе исходные записи ревью с вердиктами, `docs/architecture.md`, контекст и регламент проекта, полный diff `lib/` и `test/`, связанные реализации и локальный код `async_job` 0.1.0. Ниже перечислены все исполненные команды проверок, зондов и подмен, включая неуспешные попытки. Навигационные чтения файлов не выдаются за прогон.

Команды выполнялись через `rtk proxy`, без фильтрации вывода Flutter/Dart. Рабочий каталог — корень клона, кроме явно указанных каталогов примеров. В строках прогресса Flutter последней считается последняя непустая отрисованная строка после `\r`; исходный вывод, включая пробелы, сохранён в логах. В журнале [runs.jsonl](runs.jsonl) сохранены также аргументы, каталог, код выхода и длительность.

### Основные проверки

| Команда | Каталог | Выход | Точная последняя строка | Вывод |
| --- | --- | --- | --- | --- |
| `rtk proxy fvm flutter test` | `.` | 0 | `00:11 +525: All tests passed!                                                                                                                                                                          ` | [baseline.log](baseline.log) |
| `rtk proxy fvm flutter analyze` | `.` | 0 | `No issues found! (ran in 4.3s)` | [analyze-root.log](analyze-root.log) |
| `rtk proxy fvm flutter analyze` | `example/minimal` | 0 | `No issues found! (ran in 1.2s)` | [analyze-minimal.log](analyze-minimal.log) |
| `rtk proxy fvm flutter analyze` | `example/scopo_demo` | 0 | `No issues found! (ran in 2.4s)` | [analyze-demo.log](analyze-demo.log) |
| `rtk proxy fvm dart format --output=none --set-exit-if-changed lib test` | `.` | 0 | `Formatted 115 files (0 changed) in 0.64 seconds.` | [format.log](format.log) |
| `rtk proxy fvm flutter --version` | `.` | 0 | `Tools • Dart 3.6.0 • DevTools 2.40.2` | [sdk.log](sdk.log) |
| `rtk proxy git rev-parse --short HEAD` | `.` | 0 | `def3901` | [final-head.log](final-head.log) |
| `rtk proxy git status --short` | `.` | 0 | вывод пуст, последней строки нет | [final-status.log](final-status.log) |

База: **525 тестов прошли**. Тулчейн подтверждён исполнением: Flutter 3.27.0, Dart 3.6.0. Анализаторы корня и обоих примеров завершились без замечаний. Форматтер ничего не изменял и использовал `--output=none`.

### Обратные мутации каждого нового теста

**14 завершённых обратных мутационных прогонов → 14 отказов; охвачены все 12 новых тестов.** Здесь 13 различных подмен исходника: одну и ту же отмену M6 проверял отдельно каждым из двух новых тестов. Для `mut12` и `mut13` отказ — assert тестового binding и последующий таймаут, а не нормально выведенный `expect`; это отдельная находка L1. Тестов, переживших снятие своей основной правки, не обнаружено.

Дополнительно выполнены два дифференциальных контроля собственных зондов: снятие соответствующей правки делает зелёными два случая M1 и один случай M2. Эти проходы подтверждают регрессию и не добавлены к числу «убитых» тестов волны. Ещё одна подмена удаляла новую директиву `ignore`: анализатор остался зелёным. Таким образом, всего завершено 17 запусков на изменённой копии (14 отрицательных тестовых, 2 положительных контрольных, 1 анализатор). Две прерванные попытки `mut12` в эти 17 не входят.

Сценарии и точные замены сохранены в [mutation-manifest.json](mutation-manifest.json), исполнитель — [mutations.py](mutations.py). Полный исходный тест в стенде совпадает с клоном, кроме временного ограничения времени отрицательных запусков `mut12`/`mut13`, описанного ниже.

| Опыт | Какая правка снята | Тест / фрагмент имени | Последняя строка |
| --- | --- | --- | --- |
| [mut01](mut01.log) | Обработка самоотмены тела | `async_job_migration_test.dart`: a body that cancels itself does not stay on the loading branch | `00:00 +0 -2: Some tests failed.` |
| [mut02](mut02.log) | Вызов доклада укрытой ошибки | `async_job_migration_test.dart`: a body failure covered by a later cancellation is still reported | `00:00 +0 -2: Some tests failed.` |
| [mut03](mut03.log) | Запись флага подавленного доклада | `async_job_migration_test.dart`: a body failure covered by a later cancellation is still reported | `00:00 +0 -2: Some tests failed.` |
| [mut04](mut04.log) | Фильтр Cancelled перед FlutterError | `async_job_migration_test.dart`: a Cancelled from a disposer is heard but not reported | `00:00 +0 -2: Some tests failed.` |
| [mut05](mut05.log) | Фаза abandonedWait после окончания job | `async_job_migration_test.dart`: a failure of work nobody waits for is not called an initialization | `00:00 +0 -2: Some tests failed.` |
| [mut06](mut06.log) | Оба канала ошибки зависимости после отмены | `async_job_migration_test.dart`: a dependency that fails after the cancellation is reported | `00:00 +0 -2: Some tests failed.` |
| [mut07](mut07.log) | Та же подмена, тест двух ветвей | `async_job_migration_test.dart`: both arms of a group that fail at once are reported | `00:00 +0 -2: Some tests failed.` |
| [mut08](mut08.log) | Имя корневого job | `async_job_migration_test.dart`: an error the kernel raises about the job names the scope | `00:00 +0 -2: Some tests failed.` |
| [mut09](mut09.log) | Ранний флаг перенесён обратно к onReady | `async_data_scope_test.dart`: a value survives a readiness that failed on its way in | `00:00 +0 -2: Some tests failed.` |
| [mut10](mut10.log) | walkEnded в catch | `scope_auto_dependencies_test.dart`: a disposal that raised still counts as one, and a later init runs | `00:00 +0 -1: Some tests failed.` |
| [mut11](mut11.log) | Кеш debugLabel координатора | `async_scope_coordinator_test.dart`: an expiry on a coordinator that left the tree still reaches the observer | `00:00 +0 -2: Some tests failed.` |
| [mut12](mut12.log) | Текст таймаута снова читает widget | `async_controller_scope_test.dart`: an expiry that outlives the teardown still names itself | `00:05 +0 -2: Some tests failed.` |
| [mut13](mut13.log) | Снятие кеша колбеков | `async_controller_scope_test.dart`: an expiry that outlives the teardown still names itself | `00:05 +0 -2: Some tests failed.` |
| [mut14](mut14.log) | Защита describeExpiry и finally | `scope_coordination_test.dart`: a key that cannot name itself still lets the wait expire | `00:00 +0 -1: Some tests failed.` |

`mut01`–`mut11` падают на поведении, которое проверяет выбранный тест; дополнительные отказы `(tearDownAll)` от leak_tracker самостоятельными находками не считаются. `mut14` заканчивается падением тестового изолята от root-zone исключения `Bad state: this key cannot name itself`, что соответствует снимаемой защите. Он компилируется: сообщение `Failed to load` здесь относится к runtime-ошибке из таймера.

**Две незавершённые попытки:** первый `mut12` запускался без ограничения времени, второй — с CLI `--timeout 10s`. Оба зависли после срабатывания отрицательной проверки и были остановлены через прерывание своего exec-сеанса; выход оболочки 130. Вывода этих двух дочерних запусков обёртка до прерывания не вернула, последней строки нет; результат теста им не приписан. Для завершённых `mut12` и `mut13` во внешней копии того же `testWidgets` добавлен `timeout: const Timeout(Duration(seconds: 5))`. Утверждения и порядок операций не менялись. После проверки этот параметр убран восстановлением копии из клона. Все шесть затронутых тестовых файлов затем прошли на восстановленных исходниках: **139 тестов**, `stand-restored-tests.log`.

### Все команды дополнительных прогонов

Для мутационных прогонов таблица выше связывает отказ с конкретной правкой. Ниже — полные фактические команды и последние строки всех дополнительных прогонов, чтобы их можно было повторить без восстановления аргументов по пересказу. Одинаковое имя лога в отрицательном и повторном случае не использовалось; две прерванные попытки описаны отдельно.

**stand-baseline**, выход 0; [полный вывод](stand-baseline.log).

```sh
rtk proxy fvm flutter test --no-pub --packages ../codex-out/stand/.dart_tool/package_config.json ../codex-out/stand/test/async_job_migration_test.dart
```

Последняя строка:

```text
00:03 +13: All tests passed!                                                                                                                                                                           
```

**mut01**, выход 1; [полный вывод](mut01.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_job_migration_test.dart --plain-name 'a body that cancels itself does not stay on the loading branch' --reporter expanded
```

Последняя строка:

```text
00:00 +0 -2: Some tests failed.
```

**mut02**, выход 1; [полный вывод](mut02.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_job_migration_test.dart --plain-name 'a body failure covered by a later cancellation is still reported' --reporter expanded
```

Последняя строка:

```text
00:00 +0 -2: Some tests failed.
```

**mut03**, выход 1; [полный вывод](mut03.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_job_migration_test.dart --plain-name 'a body failure covered by a later cancellation is still reported' --reporter expanded
```

Последняя строка:

```text
00:00 +0 -2: Some tests failed.
```

**mut04**, выход 1; [полный вывод](mut04.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_job_migration_test.dart --plain-name 'a Cancelled from a disposer is heard but not reported' --reporter expanded
```

Последняя строка:

```text
00:00 +0 -2: Some tests failed.
```

**mut05**, выход 1; [полный вывод](mut05.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_job_migration_test.dart --plain-name 'a failure of work nobody waits for is not called an initialization' --reporter expanded
```

Последняя строка:

```text
00:00 +0 -2: Some tests failed.
```

**mut06**, выход 1; [полный вывод](mut06.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_job_migration_test.dart --plain-name 'a dependency that fails after the cancellation is reported' --reporter expanded
```

Последняя строка:

```text
00:00 +0 -2: Some tests failed.
```

**mut07**, выход 1; [полный вывод](mut07.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_job_migration_test.dart --plain-name 'both arms of a group that fail at once are reported' --reporter expanded
```

Последняя строка:

```text
00:00 +0 -2: Some tests failed.
```

**mut08**, выход 1; [полный вывод](mut08.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_job_migration_test.dart --plain-name 'an error the kernel raises about the job names the scope' --reporter expanded
```

Последняя строка:

```text
00:00 +0 -2: Some tests failed.
```

**mut09**, выход 1; [полный вывод](mut09.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_data_scope_test.dart --plain-name 'a value survives a readiness that failed on its way in' --reporter expanded
```

Последняя строка:

```text
00:00 +0 -2: Some tests failed.
```

**mut10**, выход 1; [полный вывод](mut10.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/scope_auto_dependencies_test.dart --plain-name 'a disposal that raised still counts as one, and a later init runs' --reporter expanded
```

Последняя строка:

```text
00:00 +0 -1: Some tests failed.
```

**mut11**, выход 1; [полный вывод](mut11.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_scope_coordinator_test.dart --plain-name 'an expiry on a coordinator that left the tree still reaches the observer' --reporter expanded
```

Последняя строка:

```text
00:00 +0 -2: Some tests failed.
```

**probes-failures**, выход 1; [полный вывод](probes-failures.log).

```sh
rtk proxy fvm flutter test --no-pub ../codex-out/probe_failures_test.dart --reporter expanded --timeout 15s
```

Последняя строка:

```text
00:00 +0 -1: Some tests failed.
```

**probes-matrix**, выход 0; [полный вывод](probes-matrix.log).

```sh
rtk proxy fvm flutter test --no-pub ../codex-out/probe_matrix_test.dart --reporter expanded --timeout 15s
```

Последняя строка:

```text
00:04 +29: All tests passed!
```

**probes-failures-v2**, выход 1; [полный вывод](probes-failures-v2.log).

```sh
rtk proxy fvm flutter test --no-pub ../codex-out/probe_failures_test.dart --reporter expanded --timeout 15s
```

Последняя строка:

```text
00:00 +0 -4: Some tests failed.
```

**mut12**, выход 1; [полный вывод](mut12.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_controller_scope_test.dart --plain-name 'an expiry that outlives the teardown still names itself' --reporter expanded --timeout 10s
```

Последняя строка:

```text
00:05 +0 -2: Some tests failed.
```

**mut13**, выход 1; [полный вывод](mut13.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/async_controller_scope_test.dart --plain-name 'an expiry that outlives the teardown still names itself' --reporter expanded --timeout 10s
```

Последняя строка:

```text
00:05 +0 -2: Some tests failed.
```

**mut14**, выход 1; [полный вывод](mut14.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/test/scope_coordination_test.dart --plain-name 'a key that cannot name itself still lets the wait expire' --reporter expanded --timeout 10s
```

Последняя строка:

```text
00:00 +0 -1: Some tests failed.
```

**control-sticky**, выход 0; [полный вывод](control-sticky.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/probe_failures_test.dart --plain-name 'custom dependency retained' --reporter expanded
```

Последняя строка:

```text
00:00 +2: All tests passed!
```

**control-duplicate**, выход 0; [полный вывод](control-duplicate.log).

```sh
rtk proxy fvm flutter test --no-pub --packages /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/.dart_tool/package_config.json /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/probe_failures_test.dart --plain-name 'covered ordinary Job failure' --reporter expanded
```

Последняя строка:

```text
00:00 +1: All tests passed!
```

**probe-repeat-head**, выход 1; [полный вывод](probe-repeat-head.log).

```sh
rtk proxy fvm flutter test --no-pub ../codex-out/probe_failures_test.dart --reporter expanded
```

Последняя строка:

```text
00:00 +0 -4: Some tests failed.
```

**probes-matrix-all-cores**, выход 0; [полный вывод](probes-matrix-all-cores.log).

```sh
rtk proxy fvm flutter test --no-pub ../codex-out/probe_matrix_test.dart --reporter expanded --timeout 15s
```

Последняя строка:

```text
00:07 +45: All tests passed!
```

**control-lint**, выход 0; [полный вывод](control-lint.log).

```sh
rtk proxy fvm dart analyze /private/tmp/claude-502/-Users-user-development-my-scopo/aeb6599a-d083-477a-a237-13db6d9f6d17/scratchpad/codex-out/stand/lib/src/scope/async_scope/scope_coordination.dart
```

Последняя строка:

```text
No issues found!
```

**stand-restored-tests**, выход 0; [полный вывод](stand-restored-tests.log).

```sh
rtk proxy fvm flutter test --no-pub --packages ../codex-out/stand/.dart_tool/package_config.json ../codex-out/stand/test/async_controller_scope_test.dart ../codex-out/stand/test/async_data_scope_test.dart ../codex-out/stand/test/async_job_migration_test.dart ../codex-out/stand/test/async_scope_coordinator_test.dart ../codex-out/stand/test/scope_auto_dependencies_test.dart ../codex-out/stand/test/scope_coordination_test.dart --reporter expanded
```

Последняя строка:

```text
00:03 +139: All tests passed!
```

Первый `probes-failures` не скомпилировался из-за двух ошибок в моём стенде: `Failed<StickyDeps>` вместо непараметризованного `Failed` и синтаксиса `Job<void>.deferred` вместо статического `Job.deferred<void>`. Они исправлены только в зонде; вывод о дефектах основан на последующих двух исполнившихся прогонах. Обе версии матрицы, на 29 и затем на 45 случаев, прошли. Расширение второй версии добавляет реальные вызовы переопределённых хуков остальных четырёх Core-семейств.

### Отказы песочницы

Дважды выполнена команда чтения списка процессов, когда отрицательный прогон `mut12` завис:

```sh
rtk proxy ps -Ao pid,ppid,etime,command | rg 'mutations.py|run.py mut12|flutter_tools.snapshot test|flutter_tester'
```

Первый отказ, дословно:

```text
rtk: Failed to execute command: ps: Operation not permitted (os error 1)
```

Повторный отказ, дословно:

```text
rtk: Failed to execute command: ps: Operation not permitted (os error 1)
```

Оба раза это последняя строка вывода, выход pipeline 1. После предписанного одного повтора чтение списка процессов прекратил; других способов получить его не применял. Других отказов песочницы не было. Прерывал только собственный выполнявшийся exec-сеанс штатным `write_stdin`.

Одна навигационная команда `rg` первоначально указала несуществующий `async_job-0.1.0/lib/src/job.dart` и получила `No such file or directory (os error 2)`; это ошибка пути, не песочницы. Полезные реализации ядра прочитаны из существующих файлов, прежде всего `job_base.dart`.

## НАХОДКИ

### M1 — Medium. Неудачный разбор группы разрешает заменить дерево с ещё живой пользовательской зависимостью

**Координаты:** `lib/src/scope/full_scope/scope_auto_dependency/scope_dependency/scope_dependency_mixin.dart`, `ScopeDependencyMixin.dispose`, новая установка `walkEnded = true` в `catch`; `scope_dependency_group.dart`, `ScopeDependencyGroup.disposalRequired`; `lib/src/scope/full_scope/scope_auto_dependency/scope_auto_dependency.dart`, `_disposalIsOver` и `_prepareDependencies`.

**Механика.** Пользовательская реализация `ScopeDependency` входит ребёнком в `sequential` или `concurrent`. Она захватывает ресурс в `init`. Первый `dispose` не может его освободить, записывает `ScopeDependencyDisposalFailed`, бросает исключение и сохраняет `disposalRequired == true`. Такой исход интерфейс допускает: требования непременно снять владение перед броском в нём нет, а `disposalRequired` прямо отвечает, осталось ли что освобождать.

Группа действительно посетила всех детей и в конце передала ошибку вверх. Новая строка считает это достаточным для `_isDisposalDone = true`. Контейнер читает этот флаг в `_disposalIsOver` и допускает повторный `init`: строит новую группу и запускает второй экземпляр зависимости. Старый ресурс остаётся у потерянного дерева. Обычный `await deps.dispose()` до повторного запуска не защищает: контейнер сообщает ошибку через FlutterError и завершает Future.

При этом группа отвечает `disposalRequired == false`, а ребёнок — `true`. **Само это расхождение старше правки**: на ветке `ScopeDependencyDisposalFailed` геттер группы уже возвращал false. Контроль со снятым новым флагом это подтвердил. Регрессия волны — разрешение заменить такое дерево: раньше отдельный `_isDisposalDone == false` удерживал охрану повторного `init`, теперь снимается и она.

**Спорю с полнотой вердикта M1** в `docs/records/2026-09-09[3]-bug-hunter-review.md` и соответствующего M2 в `docs/records/2026-09-09[4]-bug-hunter-review.md`. Доказательство для трёх внутренних `_runDispose` не доказывает, что вызванный ими чужой `ScopeDependency.dispose` освободил ресурс. «Посетили всех» и «никто ничего не удерживает» здесь разные факты. Исправление штатного листа, который сначала освобождает, а потом бросает, подтверждается; распространение этого вывода на группу с чужим ребёнком неверно.

**Как проверено:** два независимых тестовых случая в [probe_failures_test.dart](probe_failures_test.dart), `custom dependency retained after failed disposal sequential` и `... concurrent`. Оба дважды воспроизведены на HEAD. Точная диагностическая строка последовательного случая:

```text
STICKY concurrent=false childHeld=true rootNeedsDisposal=false newTree=true outcome=Done(Instance of 'StickyDeps') live=2
```

Проверка ожидает отказ нового запуска и получает `Done`. При снятии только новой установки флага оба зонда проходят: новый `init` отвергается, дерево не заменяется. Вывод: [probes-failures-v2.log](probes-failures-v2.log), [probe-repeat-head.log](probe-repeat-head.log), [control-sticky.log](control-sticky.log). Фикстура освобождает сохранённые ресурсы вручную после наблюдения, чтобы сам отрицательный тест не оставлял их.

**Последствие для потребителя:** потеря владельца ресурса и повторный захват поверх неосвобождённого — например, второй клиент или регистрация при всё ещё живом первом экземпляре. Исправление должно различать завершение обхода и незавершённое освобождение чужого ребёнка, сохраняя возможность повторного разбора такого дерева.

### M2 — Medium. Новый доклад укрытой ошибки повторяет уже отправленный доклад дочернего Job

**Координаты:** `lib/src/scope/async_scope/async_scope_core.dart`, `_settleInit` → `_reportCoveredBodyFailure`; `lib/src/scope/async_scope/scope_init_context.dart`, `_ScopeInitObserver.onError`.

**Механика.** В `AsyncScope.initScope` запускается обычный публичный `Job.deferred<void>` через `ctx.run`, затем ожидается `child.value`. Ребёнок бросает объект ошибки `failure`. Он наследует наблюдатель скоупа, но не является `ScopeInitJob`, поэтому фильтр адаптера его не подавляет: сразу отправляются `ScopeObserver.onError` и `FlutterError.reportError`.

Та же ошибка выходит из `await child.value` в тело родительского `ScopeInitJob`. Для родителя адаптер уже подавляет её и ставит `_bodyErrorCovered = true`. Пока зарегистрированный родителем `ctx.onDispose` удерживается на `Completer`, скоуп снимается с дерева. Отмена накрывает результат родителя. Новый `_reportCoveredBodyFailure` видит его флаг и отправляет **тот же объект второй раз в оба канала**. Флаг означает только «подавлен доклад этого job», а код трактует его как «об этой причине ещё никто не сообщал».

Минимальная форма инициализатора:

```dart
ctx.onDispose(() => cleanupGate.future);
final child = Job.deferred<void>((_) async => throw failure);
ctx.run(child);
await child.value;
```

Дождаться входа в уборку, удалить скоуп, затем завершить `cleanupGate`.

**Как проверено:** тест `covered ordinary Job failure is not reported twice` в [probe_failures_test.dart](probe_failures_test.dart). Перед отменой уже один доклад. После неё:

```text
DUPLICATE before=1 observers=[Bad state: ordinary child failure, Bad state: ordinary child failure] phases=[ScopePhase.initialization, ScopePhase.initializationCancellation] flutter=[Bad state: ordinary child failure, Bad state: ordinary child failure]
```

Проверки считают сообщения по `identical(e, failure)`, а не по похожему тексту. На HEAD получено 2 вместо 1, повторный запуск дал то же самое. Снятие только вызова `_reportCoveredBodyFailure(job)` возвращает по одному сообщению и зелёный зонд: [control-duplicate.log](control-duplicate.log). Это регресс именно нового пути отчётности. Обычный успешный выход в `Failed` без этой гонки здесь не переоцениваю.

**Последствие для потребителя:** удвоенные записи crash reporting и метрик ошибок, две разные фазы для одной причины. Учёт уже отправленной причины должен учитывать передачу ошибки между дочерней и родительской задачами.

### M3 — Medium. Укрытая ошибка дочернего ScopeInitJob по-прежнему исчезает целиком

**Координаты:** `lib/src/scope/async_scope/scope_init_context.dart`, `_ScopeInitObserver.onError`, поле `ScopeInitJob._bodyErrorCovered`; `lib/src/scope/async_scope/async_scope_core.dart`, `_settleInit` и `_reportCoveredBodyFailure`.

**Механика.** Инициализатор создаёт дочерний `ScopeInitJob`, запускает его через `ctx.run` и ожидает `child.value`. Дочернее тело регистрирует асинхронную уборку, затем бросает ошибку. Уборка удерживает его завершение.

Унаследованный адаптер получает ошибку ребёнка и ставит **на ребёнке** `_bodyErrorCovered = true`. Затем удаление скоупа отменяет обе задачи. После завершения уборки ребёнок отдаёт `Cancelled`, а не `Failed`; родительское тело получает именно `Cancelled`. Поэтому оригинальной ошибки в `_bodyError` родителя нет. Новая страховка вызывается только для `_initJob` элемента — корня. Для дочерней задачи `_settleInit` никто не запускает, и установленный на ней флаг никто не читает. Страховка самого ядра тоже молчит: `child.value` уже пометил исход наблюдаемым.

```dart
final child = ScopeInitJob<void>((inner) async {
  inner.onDispose(() => cleanupGate.future);
  throw failure;
});
ctx.run(child);
await child.value;
```

**Спорю с полнотой вердикта H1** в `docs/records/2026-09-09[3]-bug-hunter-review.md` и M1 в `docs/records/2026-09-09[4]-bug-hunter-review.md`: механизм исправлен для корневой задачи скоупа, но тот же фильтр применяется и к дочерним `ScopeInitJob`. Это незакрытый путь исходной потери ошибки, а не заявленная новая регрессия.

**Как проверено:** тест `a covered ScopeInitJob child failure is heard once` в [probe_failures_test.dart](probe_failures_test.dart), два прогона на HEAD:

```text
CHILD_COVERED observers=[] flutter=[]
```

Проверка одного сообщения об исходном объекте получает ноль. Проверено, что до удаления дерева дочернее тело уже упало и вошло в уборку: гонка детерминирована `Completer`, а не задержкой. Вывод сохранён в [probes-failures-v2.log](probes-failures-v2.log) и [probe-repeat-head.log](probe-repeat-head.log). Старую ревизию ради этого сценария не запускал: новизну не приписываю, вывод о неполном закрытии основан на текущем коде и зондаже.

**Последствие для потребителя:** потеря причины отказа дочерней инициализации при уходе со страницы; нет ни сообщения наблюдателю, ни FlutterError. Страховка должна иметь владельца для каждого job, чей доклад адаптер оставляет исходу.

### L1 — Low. Новый тест позднего таймаута ломает обработчик ошибок раннера при первой неудачной проверке

**Координаты:** `test/async_controller_scope_test.dart`, `an expiry that outlives the teardown still names itself` — установка `FlutterError.onError` и последующие `expect` до его восстановления.

**Механика.** Тест ставит `FlutterError.onError = (details) => reported.add(details.exception)` и откладывает восстановление до `addTearDown`. Если любая проверка после ожидания истечения падает, Flutter test binding пытается передать `TestFailure` своему обработчику. Вместо него работает сборщик теста: исключение попадает в `reported`, но `_pendingExceptionDetails` раннера остаётся пустым. Следующий assert самого binding падает; штатное завершение теста не происходит, и прогон ждёт таймаута. Уведомление о реальной регрессии заменяется ошибкой тестовой инфраструктуры.

**Как проверено:** две обратные мутации — возврат обращения к `widget` при построении текста (`mut12`) и снятие кеширования колбеков (`mut13`). Два первых запуска `mut12` пришлось прервать. Для завершённого отрицательного прогона добавлен **только во внешнюю копию теста** параметр `timeout: const Timeout(Duration(seconds: 5))`; проверки и порядок тела не менялись. CLI `--timeout 10s` сам по себе не ограничил этот `testWidgets`. Оба завершённых прогона показали:

```text
'package:flutter_test/src/binding.dart': Failed assertion: line 995 pos 14: '_pendingExceptionDetails != null': A test overrode FlutterError.onError but either failed to return it to its original state, or had unexpected additional errors that it could not handle. Typically, this is caused by using expect() before restoring FlutterError.onError.
```

Затем `TimeoutException after 0:00:05.000000: Test timed out after 5 seconds.` Полные логи: [mut12.log](mut12.log), [mut13.log](mut13.log). После опытов внешняя копия теста восстановлена из клона.

**Последствие для потребителя:** регрессия вызывает зависание проверки и неинформативный отказ вместо быстрого указания на нарушенное свойство; задерживается выявление дефекта до релиза. Это **не пустой тест**: он чувствителен к обеим правкам и падает, но его отрицательный путь неисправен. Обработчик binding нужно восстановить до `expect`.

### Info1 — Info. В диапазоне добавлена одна директива подавления lint

**Координаты:** `lib/src/scope/async_scope/scope_coordination.dart`, `_boundedByRootZone`, `// ignore: avoid_catching_errors` перед `on Object catch (error)`.

**Как проверено:** просмотр полного diff `lib/` и `test/` с нулевым контекстом. Новых `ignore_for_file` нет; новая точечная директива ровно одна. В тестовых файлах вообще нет удалённых строк — существующие утверждения не ослаблены заменой или удалением.

Отдельно удалил только эту директиву во внешнем стенде и выполнил `fvm dart analyze` для файла. Результат — `No issues found!`, выход 0: [control-lint.log](control-lint.log). Поэтому утверждать, что она скрывает предупреждение закреплённого анализатора, **оснований нет**. Факт её добавления фиксирую по прямому требованию задания. Дефект поведения и ущерб потребителю из неё не следуют.

## ЧТО ДОПОЛНИТЕЛЬНО ПРОВЕРЕНО

[probe_matrix_test.dart](probe_matrix_test.dart) содержит **45 прошедших проверок**:

- 20 реальных истечений: все четыре вида таймаута у `Scope`, `LiteScope`, `AsyncScope`, `AsyncDataScope`, `AsyncControllerScope`. Проверяется ровно один колбек, одно сообщение наблюдателю, один FlutterError и порядок `observer → flutter → callback`.
- 20 реальных истечений с прямым переопределением четырёх `onXTimeout` на элементах каждого из пяти `…Core`-семейств. Динамический вызов хуков сохранился.
- 5 проверок обновления колбеков виджета и их вызова после завершившегося разбора. Старые колбеки не зовутся, каждый новый вызывается один раз; `element.mounted == false`.

Для ожидания ключа истечение наступает у смонтированного ожидающего скоупа; снятие этого скоупа с дерева отменяет ожидание. Остальные обычные истечения матрицы происходят после снятия с дерева, пока идёт асинхронный разбор. Проверки кеша после **завершённого** разбора вызывают публичные хуки напрямую — это не подмена утверждением, будто во всех семействах есть живой таймер за концом разбора. Реальный поздний релиз контроллера проверяет отдельный исходный тест волны, также прошедший в базовом и восстановленном прогонах.

Перенос `_initSucceeded` проверен по всем обращениям в элементе: `_onInitStep`, охрана `_settleReady`, третья стадия `_performAsyncDispose`. Между новым и старым положением нет `await`; более ранний флаг закрывает прогресс и разрешает освобождение уже принятого значения при отказе настройки готовности. Обычные состояния готовности и отмены проходят существующие тесты, тест освобождения при отрицательной паузе поймал обратную мутацию. Отдельного подтверждённого дефекта этого переноса не нашёл. Одноимённый флаг в `LiteScopeCoreState` относится к другому объекту и переносом не менялся.

В новых тестах базовых каналов проверяются точные списки ошибок и фаз, а не только факт прихода. Счётчики выявили дублирование на **передаче ошибки между задачами**, описанное в M2; для обычных истечений дубликатов в матрице не обнаружено.

## ЧЕГО НЕ ПРОВЕРИЛ

- Не выполнял `dart doc --dry-run`, `dart pub publish --dry-run`, проверку переводов, тесты примеров и сьюту `async_job`: они не входят в заданные пять команд и область этой проверки правок. Анализаторы обоих примеров выполнены.
- Не запускал приложение на устройстве, web, в release-режиме или на другом SDK. Все исполнения — Flutter 3.27.0 / Dart 3.6.0.
- Не перебирал все пользовательские реализации `ScopeDependency`, все комбинации `GlobalKey`/`close`, реэнтерабельные геттеры параметров и наблюдатели, повторно бросающие либо отменяющие задачу. Для M1 проверены обе формы группы и реализация, которая честно сообщает о сохранённом ресурсе; универсальность не утверждаю.
- Не писал отдельного зонда на исключение из `toString()` самого объекта ошибки при построении запасного текста истечения. Мутация исходного теста ключа проверяет снятие его исправления, но не все возможные диагностические объекты.
- Обратные мутации проверяют все 12 новых тестов на снятие охраняемой ими правки. Это не полный мутационный анализ всех новых строк: например, отдельную потерю сохранённого stack trace и имя внутренней задачи каждой параллельной ветви не мутировал.
- Для L1 не ждал штатный длительный таймаут исходного `testWidgets`: два первых запуска прерваны, завершённый отрицательный опыт проведён с явными пятью секундами во внешней копии. Это ограничение отражено и в ПРОГОНЕ; обычный отрицательный `expect` вместо сбоя binding этим двум запускам не приписываю.
- Дополнительные сообщения `leak_tracker` в отрицательных прогонах не считаю отдельными утечками пакета: они сопровождали оборванные тестовые тела. M1 подтверждён собственным учётом удерживаемых ресурсов и замены дерева.
- Список процессов прочитать не удалось: после двух одинаковых отказов песочницы эту проверку прекратил, обходов не предпринимал.

Код пакета не исправлял. Исходный клон не мутировал; все подмены сделаны в соседнем `codex-out/stand`. Никакие запрещённые команды Git не выполнялись, зависимости не добавлялись.
