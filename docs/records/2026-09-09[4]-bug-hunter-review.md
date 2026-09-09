# Ревью на дефекты — второй проход, `codex`

> **Состояние на 2026-09-09:** все три находки закрыты, у каждой вердикт в
> конце неё (вердикт M3 дописан позже, ревью волны). Волну этих правок
> отревьюировали отдельно тем же днём —
> `2026-09-09[5]-post-wave-review.md` и
> `2026-09-09[6]-post-wave-review.md`; M2 там оспорена по полноте.
> **Что это:** независимый проход `bug-hunter` по диапазону
> `706b837..97086de`, исполнитель — `codex` в изолированном клоне. Три находки
> Medium, все с зондами; я воспроизвёл все три своим прогоном. Текст ниже —
> его, как отдан, правок в нём нет.
> **Связанные записи:** `2026-09-09[3]-bug-hunter-review.md` (мой проход, там
> же сведение и сходимость), `2026-09-09[1]-async-job-migration-design.md`,
> `2026-09-09[2]-async-job-fixes-report.md`,
> `2026-09-09[5]-post-wave-review.md`,
> `2026-09-09[6]-post-wave-review.md`.

## ПРОГОН

Проверял диапазон `706b837..97086de` (`HEAD` клона), изменения в `lib/` и необходимые для их понимания соседние участки. Начал с `git diff --stat 706b837..HEAD -- lib/` и `git log --oneline 706b837..HEAD`: 28 файлов в `lib/`, 950 добавленных и 887 удалённых строк. Прочитал контекст проекта, спецификацию `docs/records/2026-09-09[1]-async-job-migration-design.md` и отчёт `docs/records/2026-09-09[2]-async-job-fixes-report.md`. Реализацию `async_job` 0.1.0 читал из `/Users/user/.pub-cache/hosted/pub.dev/async_job-0.1.0`. Два независимых агента помогали только чтением: ядра и зависимостей. Все описанные ниже зонды запускал основной агент.

Команды ниже действительно выполнены из корня клона через `fvm`. Вывод перенаправлялся в файлы рядом с этим отчётом; команды проверок запускались без фильтрации RTK. В таблице точные последние непустые строки вывода, без правых пробелов, которыми Flutter перерисовывает строку прогресса.

| Команда и состояние дерева | Код выхода | Последняя строка | Полный вывод |
| --- | --- | --- | --- |
| `fvm flutter test`, исходное дерево | 0 | `00:11 +513: All tests passed!` | `baseline-test.log` |
| `fvm flutter analyze`, исходное дерево | 0 | `No issues found! (ran in 4.3s)` | `baseline-analyze.log` |
| `fvm dart format --output=none --set-exit-if-changed lib test`, исходное дерево | 0 | `Formatted 115 files (0 changed) in 0.62 seconds.` | `baseline-format.log` |
| `fvm flutter test`, добавлены два зонда потери ошибок | 1 | `00:10 +513 -3: Some tests failed.` | `probe-errors-test.log` |
| `fvm flutter test`, добавлен также зонд повторного `init()` | 1 | `00:08 +513 -4: Some tests failed.` | `probe-rerun-test.log` |
| `fvm flutter test`, все зонды удалены | 0 | `00:09 +513: All tests passed!` | `final-test.log` |

Ожидаемые исходные результаты подтвердились: 513 зелёных тестов, анализатор без замечаний, форматирование без изменений. Финальная сьюта после удаления зондов также дала 513 зелёных тестов. Анализатор и форматирование повторно после удаления зондов не запускал; исходные файлы не менял.

Написал **три зонда — три тестовых случая в двух файлах**. Все три запущены и упали на проверке своего свойства. Два зонда потери ошибок запускались дважды; зонд повторной инициализации — один раз. В отрицательных прогонах дополнительно упал `(tearDownAll)` проверки утечек файла `probe_error_loss_test.dart`, поэтому счётчики содержат соответственно три и четыре отказа. Находки основаны на приведённых ниже отказах `expect`, а не на этом дополнительном падении. Его причину отдельно не исследовал и самостоятельную утечку по нему не заявляю.

**Обратных мутаций: 0. Подмен существующих файлов: 0. Отказов песочницы не было.** Один запрос чтения использовал неполный путь из постановки: `sed: lib/src/scope/scope_dependency/scope_dependency_mixin.dart: No such file or directory`. Путь найден через `rg --files`; это ошибка пути, а не отказ песочницы.

Исходный и финальный `git status --short` дали пустой вывод. Оба временных файла удалены из `test/`; их точные тексты сохранены рядом с отчётом и приведены ниже. Существующие тесты, зависимости и исходники не менялись. Запрещённые команды Git не выполнялись.

## Medium — M1. Отмена во время уборки полностью скрывает предшествующую ошибку тела

**Координаты:** `lib/src/scope/async_scope/scope_init_context.dart`, `ScopeInitJob.execute` (строка 68), `_ScopeInitObserver.onError` (строки 97–102); `lib/src/scope/async_scope/async_scope_core.dart`, `AsyncScopeElementBase._settleInit` (строки 148–165). На стороне ядра: `/Users/user/.pub-cache/hosted/pub.dev/async_job-0.1.0/lib/src/job_base.dart`, `JobBase.done` (строка 371), `_execute` (выбор исхода, строка 846), `_reportCovered` (строка 871). Введено переходом на ядро, `bc914c8`.

**Механика.** Инициализатор регистрирует асинхронный `ctx.onDispose`, затем бросает ошибку. `ScopeInitJob.execute` сохраняет её в `_bodyError`. Ядро сразу уведомляет наблюдателя, но адаптер scopo подавляет сообщение: ошибка совпадает с `_bodyError`, отмены ещё нет. Он рассчитывает, что `_settleInit` получит `Failed` и сообщит ошибку через `_settleFailure`.

Затем ядро начинает уборку и ждёт диспозер. Если в этот момент скоуп удалить из дерева, `_prepareForDisposal` отменяет задачу. После окончания диспозера ядро выбирает окончательный исход `Cancelled`, а соответствующая ветка `_settleInit` ничего не делает. Запасной путь ядра `_reportCovered` также молчит: чтение `job.done` внутри `_settleInit` заранее установило `_observed = true`. Ошибка не дошла ни до `ScopeObserver.onError`, ни до `FlutterError`, ни до модели.

Это ошибка адаптации scopo. Поведение ядра согласуется с его реализацией и контрактом наблюдения исхода. Спецификация перехода в разделе «Форма шва» рассчитывает на сообщение ошибки, которую позднее накрыла отмена, но сочетание фильтра адаптера с чтением `done` это сообщение исключает.

**Подтверждение: зонд.** Тест `probe: failure before cleanup survives cancellation` в файле ниже детерминированно удерживает уборку через `Completer`. Перед отменой проверяет вход в диспозер, после — завершение разбора скоупа. Проверка уведомления упала:

```text
Expected: contains same instance as StateError:<Bad state: body failed before cancellation>
  Actual: []
FlutterError received: null
```

**Вердикт: исправлено.** Та же находка, что `H1` в `2026-09-09[3]-bug-hunter-review.md`: её нашли трое независимо. Разбор правки, тест и проверка нагруженности — там же, в вердикте к `H1`. Коротко: доклад укрытой ошибки взял на себя элемент, потому что страховка ядра `_reportCovered` для `scopo` не срабатывает никогда — он наблюдает исход раньше, чем задача стартует.

**Последствие для потребителя:** при уходе с экрана во время асинхронной уборки после неудачной инициализации причина отказа пропадает из штатной диагностики. Уверенность высокая: свойство воспроизведено дважды. Проявляется при сочетании ошибки тела, незавершённой уборки и последующей отмены; частоту в приложении не измерял.

Полный фактически запущенный `test/probe_error_loss_test.dart`. Первый тест подтверждает M1, второй — M3:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

void main() {
  tearDown(ScopeConfig.reset);

  testWidgets('probe: failure before cleanup survives cancellation',
      (tester) async {
    final failure = StateError('body failed before cancellation');
    final gate = Completer<void>();
    final observer = _Errors();
    ScopeConfig.observer = observer;
    var cleanupStarted = false;
    await tester.pumpWidget(_host((context, ctx) async {
      ctx.onDispose(() async {
        cleanupStarted = true;
        await gate.future;
      });
      throw failure;
    }));
    await tester.pumpAndSettle();
    expect(cleanupStarted, isTrue);
    expect(observer.disposed, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    gate.complete();
    await tester.pumpAndSettle();
    final reported = tester.takeException();
    expect(observer.disposed, 1);
    expect(observer.errors, contains(same(failure)),
        reason: 'FlutterError received: $reported');
  });

  testWidgets('probe: dependency failure after cancellation is reported',
      (tester) async {
    final failure = StateError('dependency failed after cancellation');
    final gate = Completer<void>();
    final deps = _Dependencies(gate, failure);
    final observer = _Errors();
    ScopeConfig.observer = observer;
    await tester.pumpWidget(_host((context, ctx) async {
      await deps.init(null, ctx);
    }));
    await tester.pumpAndSettle();
    expect(deps.started, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    gate.complete();
    await tester.pumpAndSettle();
    final reported = tester.takeException();
    expect(observer.disposed, greaterThanOrEqualTo(1));
    expect(observer.errors.any((error) => '$error'.contains('$failure')), isTrue,
        reason: 'FlutterError received: $reported; root: ${deps.root.state}');
  });
}

Widget _host(
  Future<void> Function(BuildContext, ScopeInitContext) init,
) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: AsyncScope(
        initScope: init,
        disposeScope: () {},
        progressBuilder: (context, progress) => const Text('loading'),
        errorBuilder: (context, error, stack, progress) => Text('$error'),
        builder: (context) => const Text('ready'),
      ),
    );

final class _Errors extends ScopeObserver {
  final errors = <Object>[];
  var disposed = 0;

  @override
  void onError(ScopeObservable target, ScopePhase phase, Object error,
      StackTrace? stackTrace) {
    errors.add(error);
  }

  @override
  void onDisposed(ScopeObservable target) {
    disposed++;
  }
}

final class _Dependencies extends ScopeAutoDependencies<_Dependencies, void> {
  final Completer<void> gate;
  final Object failure;
  var started = false;

  _Dependencies(this.gate, this.failure);

  @override
  ScopeDependency buildDependencies(void context) => dep('resource', (_) async {
        started = true;
        await gate.future;
        throw failure;
      });
}
```

## Medium — M2. Завершённый разбор с ошибкой блокирует повторный init контейнера

**Координаты:** `lib/src/scope/full_scope/scope_auto_dependency/scope_dependency/scope_dependency_mixin.dart`, `ScopeDependencyMixin.dispose` (строки 352–389), `_handleDisposalError`; `lib/src/scope/full_scope/scope_auto_dependency/scope_auto_dependency.dart`, `ScopeAutoDependencies._prepareDependencies` (строка 50), `_disposalIsOver` (строка 117). Регрессия перевода обхода со Stream на Future, `ce0e7ca`.

**Механика.** Группа при разборе обходит все зависимости, даже если один диспозер бросает ошибку. Хуки освобождения снимаются до вызова, а `_ScopeDependencyImpl._runDispose` очищает helper в `finally`. После обхода группа передаёт первую ошибку наверх. `ScopeDependencyMixin.dispose` ловит её и вызывает `_handleDisposalError`, который снова бросает исключение. Поэтому следующая строка `walkEnded = true` недостижима, и в `finally` флаг `_isDisposalDone` остаётся ложным.

Контейнер `ScopeAutoDependencies._runDispose` сообщает ошибку, нормально завершает свой Future и вызывает `onDisposed`. Однако следующий `init()` проверяет `_isDisposalDone` через `_disposalIsOver` и отказывает с `has not been disposed of`. Это происходит даже когда все ресурсы действительно освобождены, а исключение возникло уже после освобождения. Дополнительный `dispose()` ничего больше не освобождает, но устанавливает недостающий флаг — после него `init()` проходит.

Контракт повторного использования контейнера разрешает новый `init()` после завершения `dispose()`; это также описано в `doc/full_scope.md`, строка 143. До `ce0e7ca` ошибку передавала подписчику конструкция `yield* ...handleError(...)`, после чего выполнение доходило до `walkEnded = true`. Сейчас `await` с повторным броском изменил этот путь. Сравнение со старым кодом выполнено чтением diff; старую ревизию не запускал.

**Подтверждение: зонд.** `probe: completed disposal permits a new initialization after error` сначала проверяет вызов обоих диспозеров и `disposalRequired == false`. Затем сохраняет отказ второго запуска, выполняет пустой повторный разбор и подтверждает успех третьего запуска. Ошибка проверки относится ко второму запуску:

```text
Expected: <Instance of 'Done<_Dependencies>'>
  Actual: Failed:<Failed(Bad state: _Dependencies has already been initialized (disposal failed: second) and has not been disposed of. Dispose of it before initializing it again: a second `init()` builds the tree afresh and runs every initializer over the same container, whose fields the first run has already assigned — and where that run is still holding something, nothing would ever release it.)>
```

**Вердикт: исправлено.** Та же находка, что `M1` в `2026-09-09[3]-bug-hunter-review.md`, — её нашли двое независимо; разбор правки, тест и проверка нагруженности там же. Коротко: `walkEnded` теперь ставится и на ветке отказа, потому что все реализации `_runDispose` доходят до конца и лишь затем поднимают собранное.

**Последствие для потребителя:** повторно используемый контейнер после завершённого разбора не запускается, хотя потребитель уже дождался его `dispose()`. Восстановление требует дополнительного вызова, выполняющего лишь учёт состояния. Обычный `Scope`, создающий новый контейнер для каждого экземпляра, этот сценарий не затрагивает. Уверенность высокая; в проверенном сценарии отказ детерминированный, частоту повторного использования контейнеров в приложениях не оценивал.

Полный фактически запущенный `test/probe_disposal_rerun_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

void main() {
  test('probe: completed disposal permits a new initialization after error',
      () async {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
    addTearDown(ScopeConfig.reset);

    final deps = _Dependencies();
    final first = ScopeInitJob((ctx) => deps.init(null, ctx))..start();
    expect(await first.done, isA<Done<_Dependencies>>());
    deps.onUnmount();
    await deps.dispose();
    expect(deps.released, ['second', 'first']);
    expect(reported, hasLength(1));
    expect(deps.root.disposalRequired, isFalse);

    final second = ScopeInitJob((ctx) => deps.init(null, ctx))..start();
    final secondOutcome = await second.done;

    // A second empty disposal changes only bookkeeping; no disposer runs.
    await deps.dispose();
    expect(deps.released, ['second', 'first']);
    final third = ScopeInitJob((ctx) => deps.init(null, ctx))..start();
    final thirdOutcome = await third.done;
    deps.onUnmount();
    await deps.dispose();
    expect(thirdOutcome, isA<Done<_Dependencies>>());
    expect(secondOutcome, isA<Done<_Dependencies>>(),
        reason: 'the first disposal already visited and released both nodes');
  });
}

final class _Dependencies extends ScopeAutoDependencies<_Dependencies, void> {
  final released = <String>[];

  @override
  ScopeDependency buildDependencies(void context) => sequential('', [
        dep('first', (handle) {
          handle.dispose = () => released.add('first');
        }),
        dep('second', (handle) {
          handle.dispose = () {
            released.add('second');
            throw StateError('error after resource was released');
          };
        }),
      ]);
}
```

## Medium — M3. Ошибка зависимости после отмены остаётся только в состоянии дерева и trace

**Координаты:** `lib/src/scope/full_scope/scope_auto_dependency/scope_dependency/scope_dependency_mixin.dart`, `ScopeDependencyMixin.init` (строки 212–221), `_handleInitializationPostCancelError` и `_handlePostCancelError` (строки 480–515). **Дефект старше диапазона:** на базе `706b837` аналогичный путь `runStreamGuarded` также передавал ошибку обработчику, который записывал состояние и вызывал только `onTrace`. Нынешняя замена ошибки на `Cancelled` введена при переходе на Future, но отсутствие штатного уведомления существовало раньше. Историческое сравнение — чтением, без запуска базы.

**Механика.** Зависимость ждёт обычный Future. Пока она ждёт, скоуп снимают и задача получает метку отмены. Когда ожидание заканчивается и зависимость бросает реальную ошибку, `ScopeDependencyMixin.init` попадает в ветку `ctx.job.isCancelled`. Обработчик записывает исходную ошибку в `ScopeDependencyCancelled`, сообщает строку `onTrace`, затем наружу бросается новый `Cancelled`. Ядро получает только исключение отмены; исходная ошибка до `_ScopeInitObserver.onError` не доходит. Контейнер завершает автоматический разбор, а скоуп завершает отмену без уведомления об этой ошибке.

Объект ошибки остаётся доступен через состояние зависимости и `flattenDependenciesWithErrors()`. Чтобы узнать о нём, потребителю нужно отдельно сохранить контейнер и обследовать дерево либо разбирать trace. Наблюдатель ошибок и стандартный обработчик `FlutterError` его не получают. Комментарий самой ветки говорит «recorded and reported here», а при переходе на ядро ошибки разматывания должны были проходить через адаптер наблюдателя.

**Подтверждение: зонд.** Это второй тест `probe: dependency failure after cancellation is reported` в полном файле `test/probe_error_loss_test.dart`, приведённом в M1. Его тело и все вспомогательные определения приведены там без сокращений. Тест удерживает зависимость на `Completer`, удаляет скоуп, разрешает ожидание и проверяет оба канала. Два запуска дали:

```text
Expected: true
  Actual: <false>
FlutterError received: null; root: cancelled with error: Bad state: dependency failed after
cancellation
```

**Последствие для потребителя:** сбой продолжившейся после ухода с экрана инициализации отсутствует в crash reporting, подключённом к `FlutterError` или `ScopeObserver.onError`. Диагностика дерева сохраняется, пока сам контейнер доступен. Уверенность высокая для текущей головы: воспроизведено дважды. Условие проявления — ошибка зависимости после метки отмены, до завершения её обычного ожидания; частоту не измерял.

**Вердикт: исправлено; вердикт дописан позже, послеволновым ревью.** `46e5fa3`,
той же правкой, что закрыла M6 в `2026-09-09[3]-bug-hunter-review.md` — это
одна находка, увиденная с двух сторон. `_handlePostCancelError` после записи в
состояние доносит ошибку до наблюдателя (фаза `initializationCancellation`) и
до `FlutterError`; `Cancelled` в этот канал не идёт. Тест — `a dependency that
fails after the cancellation is reported`. Волна вердикта здесь не поставила,
хотя у M1 и M2 поставила; пропуск найден и закрыт ревью волны,
`2026-09-09[5]-post-wave-review.md`. Закрытие проверено там же независимым
зондом (F): один отчёт наблюдателю и один в `FlutterError`, дубля нет.

## Чего я не проверил

Специальных зондов на утечки памяти, двойное освобождение, реэнтерабельность всех колбэков наблюдателя, все варианты переноса с `GlobalKey` и все порядки событий таймеров не писал. Подтверждённых новых дефектов владения ресурсами в этом проходе не получил. Дополнительное падение проверки утечек отрицательного прогона не исследовал отдельно.

`AsyncControllerScope`, позднюю передачу контейнера в `Scope`, координацию ключей и ожидание детей проверял чтением и существующей сьютой. Новыми зондами каждый из этих путей не нагружал. Существующий тест `a concurrent branch failure reaches the scope error state` входит в прошедшую сьюту; отдельного нового зонда или мутации превращения ошибки параллельной группы в отмену не делал. Произвольные пользовательские реализации `ScopeDependency` и `Job`, ошибки их геттеров и диагностических методов всеми возможными входами не проверены.

В ядре прочитаны реализация исходов, отмены, ожидания детей, стека уборки и каналов ошибок, а также выборочные тесты. Собственную сьюту пакета `async_job` не запускал. `JobStream` подробно не исследовал: инициализация scopo им не пользуется. Случай позднего значения после истечения `initCancellationTimeout` оценивал в рамках существующего ограничения `canReleaseAfterCancellation`; альтернативную политику освобождения не проверял.

Старые ревизии не запускал. Нет обратных мутаций, прогонов на устройстве, release-режима и иных SDK. Анализаторы примеров, их тесты, dartdoc и pub dry-run не запускал: выполнял три команды проверок, заданные в постановке. Переводы, CHANGELOG, README, стиль и архитектура не были предметом ревью.
