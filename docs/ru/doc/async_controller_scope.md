# AsyncControllerScope

> Перевод `doc/async_controller_scope.md` (blob `7c0e3e8852a044027326c0fe64d887f71fd08873`).
> Правится в том же коммите, что и оригинал; проверка — `sh docs/ru/check.sh`.

Скоуп, всё содержимое которого — контроллер: объект со своим жизненным циклом,
который создаётся при монтировании скоупа, асинхронно инициализируется,
получает команду остановиться, когда скоуп уходит, и освобождается после этого.
Берите его, когда скоуп существует потому, что что-то должно **работать**, пока
кусок дерева на экране, — оверлей карты, который ведут блоки, опросник,
сессия, — а не потому, что что-то должно показываться.

```dart
AsyncControllerScope<PlayerController>(
  createController: (context) => PlayerController(api: ScopeModel.of<Api>(context, listen: false)),
  progressBuilder: (context) => const SizedBox.shrink(),
  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
  builder: (context, controller) => const PlayerView(),
);
```

`AsyncControllerScopeBase` — форма для наследования, и именно в ней оказывается
большинство контроллеров: им обычно что-то нужно из дерева.

```dart
final class Player extends AsyncControllerScopeBase<Player, PlayerController> {
  const Player({super.key, required super.child}) : super(scopeKey: Player);

  @override
  PlayerController createController(BuildContext context) =>
      PlayerController(api: ScopeModel.of<Api>(context, listen: false));

  @override
  Widget buildOnProgress(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildOnError(BuildContext context, Object error, StackTrace stack) =>
      const SizedBox.shrink();

  @override
  Widget buildOnReady(BuildContext context, PlayerController controller) =>
      child;
}
```

Под обоими лежит `AsyncControllerScopeCore` — для скоупа, которому нужен свой
элемент. Семейство построено на машинерии `AsyncDataScope`, поэтому всё, что
описано в той теме, — четыре состояния, порядок разбора, `scopeKey`, ожидание
дочерних скоупов, четыре таймаута — действует здесь без изменений, а значением
выступает контроллер.

## Контроллер

```dart
final class PlayerController extends ScopeController {
  final Api api;

  StreamSubscription<Track>? _subscription;

  PlayerController({required this.api});

  @override
  Future<void> init() async {
    final session = await api.openSession();
    if (!mounted) return;

    _subscription = session.tracks.listen(_onTrack);
  }

  @override
  void onUnmount() => unawaited(_subscription?.cancel());

  @override
  Future<void> dispose() async => api.closeSession();
}
```

Писать нужно три метода, и ни одному из них не требуется звать `super`:

| метод | когда |
| --- | --- |
| `init()` | один раз, асинхронно, до того как построится готовая ветка |
| `onUnmount()` | синхронно, в момент ухода скоупа с дерева |
| `dispose()` | с ожиданием, после `onUnmount`, когда скоуп разбирают |

`mounted` — это то, что проверяют после каждого `await` внутри `init()`: скоуп
мог уйти, пока инициализация была приостановлена, и тогда `onUnmount()` уже
отработал.

Три метода, которые зовёт скоуп, — `performInit`, `performUnmount`,
`performDispose` — закрыты от переопределения. Они держат `mounted`, держат
порядок и следят, чтобы каждый хук выполнился не больше одного раза, так что
ничего из этого не опирается на соглашение, о котором контроллер обязан
помнить. Они публичные, а не спрятанные, поэтому контроллер можно вести руками
в тесте:

```dart
final controller = PlayerController(api: FakeApi());
await controller.performInit();
// …
await controller.performDispose();
```

Последовательность односторонняя. Второй `performInit` ничего не делает, как
и вызов после `performDispose`: иначе `init()` работал бы с тем, что
`dispose()` уже освободил. Разбор у контроллера тоже один, и его исход видят
все, кто звал `performDispose`: второй вызов присоединяется к уже идущему
разбору, а не возвращается немедленно, и падение, которое увидел первый
вызвавший, увидит и второй.

## Что гарантирует скоуп

То, ради чего семейство и заведено. Контроллер, созданный скоупом, скоупом же
и освобождается — на любом пути, включая те два, которые легко упустить, когда
то же самое пишут руками поверх `AsyncDataScope`: там скоуп узнаёт
о контроллере только если инициализация дошла до передачи.

| что случилось | `onUnmount()` | `dispose()` |
| --- | --- | --- |
| скоуп ушёл до начала асинхронной фазы | контроллер не создавался | — |
| `init()` бросил | да | да |
| скоуп ушёл, пока `init()` ещё шёл | да | да |
| скоуп ушёл, и готовое состояние не доехало | да | да |
| обычный путь: готов, потом ушёл | да | да |

`onUnmount()` — синхронная половина, и она всегда первая: в момент ухода скоупа
с дерева, а не когда до неё доберётся асинхронный разбор. Для контроллера,
который ведёт что-то вовне себя, разница существенная: он перестаёт доставать
до внешнего мира сразу, чего бы ни ждал остальной разбор.

Зависший контроллер не может ничего запереть: ожидание отменённой инициализации
ограничено `initCancellationTimeout`, ожидание `dispose()` —
`disposeScopeTimeout`, см. тему `debug`.

## Чтение контроллера из поддерева

```dart
final controller = AsyncControllerScope.of<PlayerController>(
  context,
  listen: false,
).controller;
```

`of`, `maybeOf` и `select` возвращают `AsyncControllerScopeContext`:
`controller` бросает, пока контроллер не готов, `controllerOrNull` возвращает
`null`, а `hasController` спрашивает о том же отдельно. Виджеты внутри
`builder` находятся под готовым скоупом и могут пользоваться `controller`. Три
ответа `AsyncDataScopeContext` — `data`, `dataOrNull`, `hasData` — унаследованы
и по-прежнему работают: это тот же объект под именем, которое было у значения
до того, как у семейства появилось своё.

У формы для наследования те же три метода статическими, первым идёт тип
виджета:

```dart
final position = AsyncControllerScopeBase.select<Player, PlayerController, int>(
  context,
  (scope) => scope.controller.position,
);
```

## Как следить за тем, что слышит контроллер

Скоуп уведомляет зависимых, когда меняется его собственное состояние —
ожидание, готовность, ошибка, — и у большинства скоупов это случается один раз.
Работающему контроллеру есть что сказать и дальше: трек, который прислала
сессия, позиция, до которой он дошёл. Донести это до виджетов — дело поддерева,
а не скоупа, и очевидная дорога — поток, который контроллер открыл. Пусть
`PlayerController` отдаёт поток сессии наружу как `tracks`:

```dart
@override
Widget buildOnReady(BuildContext context, PlayerController controller) =>
    StreamBuilder<Track>(
      stream: controller.tracks,
      builder: (context, snapshot) => TrackTitle(title: snapshot.data?.title),
    );
```

Вместе с этим приходит три вещи.

**Каждое событие пересобирает всю ветку.** Два трека с одинаковым названием
и разной позицией пересоберут `TrackTitle` дважды, а название — это всё, что он
читает.

**Ошибка опустошает снимок.** Билдеру отдают `AsyncSnapshot`, построенный
через `withError`, а он не несёт данных: виджет, показывавший название,
с первой же жалобы сессии показывает `null` — хотя трек, который он показывал,
всё ещё играет.

**У потока один слушатель.** Второй виджет, которому нужен тот же трек,
получит `Bad state: Stream has already been listened to`, так что либо поток
становится широковещательным, либо значение несут вниз руками.

Значение и так живёт в контроллере — подписка его собственная. Пусть он хранит
то, что услышал, и говорит, когда это изменилось:

```dart
final class PlayerController extends ScopeController with ChangeNotifier {
  final Api api;

  StreamSubscription<Track>? _subscription;
  Track? _track;

  PlayerController({required this.api});

  String get title => _track?.title ?? '';

  int get position => _track?.position ?? 0;

  @override
  Future<void> init() async {
    final session = await api.openSession();
    if (!mounted) return;

    _subscription = session.tracks.listen((track) {
      _track = track;
      notifyListeners();
    });
  }

  @override
  void onUnmount() => unawaited(_subscription?.cancel());

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await api.closeSession();
    super.dispose();
  }
}
```

`ScopeNotifier.value` ставит этот контроллер перед поддеревом — и это весь
мост:

```dart
@override
Widget buildOnReady(BuildContext context, PlayerController controller) =>
    ScopeNotifier<PlayerController>.value(
      value: controller,
      builder: (context) => const PlayerView(),
    );
```

Виджет ниже называет то единственное значение, которое показывает:

```dart
final title = ScopeNotifier.select<PlayerController, String>(
  context,
  (controller) => controller.title,
);
```

— и пересобирается, когда меняется название, а не когда меняется позиция.
`of` и `maybeOf` с `listen: true` — другой конец той же шкалы: они
пересобирают на каждый `notifyListeners`, то есть ровно то, что делал
`StreamBuilder` выше.

Две вещи про разбор стоит прочитать дважды.

`dispose()` — это и хук контроллера, и метод `ChangeNotifier`: примесь лежит
поверх `ScopeController`, так что член здесь один. Поэтому переопределение
кончается на `super.dispose()`: без него слушателей никто не отпускает,
и трекер утечек Flutter скажет об этом в первом же тесте, который смотрит.

Подписку отменяют в обеих половинах намеренно. `onUnmount()` не пускает
события в скоуп, который уходит, — в тот самый момент, когда он уходит;
`dispose()` дожидается отмены, прежде чем закрыть за собой сессию. Второго
у `StreamBuilder` попросить нечем: он отменяет из `State.dispose` и отпускает
возвращённый future.

## Чего это семейство не делает

**Не делает контроллер наблюдаемым.** Скоуп уведомляет зависимых при изменении
своего **состояния** — ожидание, готовность, ошибка — а не когда что-то
изменилось внутри контроллера. Как это делается — в разделе выше: контроллер,
который сам `Listenable`, и `ScopeNotifier.value` под этим скоупом.

**Не сообщает прогресс.** `init()` — это `Future<void>`, между
«инициализируется» и «готов» показывать нечего. Инициализация, у которой есть
этапы, достойные подписи, — это `AsyncDataScope`, её контекст эти этапы
и сообщает.

**Ничего не делает с провалом инициализации** сверх того, что делает любое
семейство: ошибка приезжает в `buildOnError`, который обязателен именно затем,
чтобы решение принимали, а не получали по умолчанию. Оттуда её и направляют
дальше — или ставят `ScopeObserver`, тема `debug` описывает и то и другое.

## Куда дальше

| тема | о чём |
| --- | --- |
| `AsyncDataScope` | машинерия под низом: состояния, порядок разбора, `scopeKey` |
| `AsyncScope` | тот же жизненный цикл вовсе без значения |
| `ScopeNotifier` | как сделать наблюдаемым сам контроллер |
| `debug` | четыре таймаута и наблюдатель |
